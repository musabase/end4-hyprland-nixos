#!/usr/bin/env python3
"""Keep the repo pinned to a matching pair taken from End-4's official repo:

  dotsRev   = latest commit on end-4/dots-hyprland main   (end4-home.nix)
  quickshell = the commit End-4's own Arch package pins AT THAT dotsRev (flake.nix)

Both values are written together or not at all. Nothing is pushed here; the workflow
opens a pull request so a human tests it before readers can curl it from main.
"""
import argparse, os, re, subprocess, sys, tempfile, urllib.request
from pathlib import Path

REPO = "https://github.com/end-4/dots-hyprland.git"
PKGBUILD = ("https://raw.githubusercontent.com/end-4/dots-hyprland/{sha}/"
            "sdata/dist-arch/illogical-impulse-quickshell-git/PKGBUILD")
SHA = re.compile(r"^[0-9a-f]{40}$")
QS_RE = re.compile(r'(url = "github:quickshell-mirror/quickshell/)([0-9a-f]{40})(";)')
DOTS_RE = re.compile(r'(dotsRev = ")([0-9a-f]{40})(";)')
WATCH = ["sdata/dist-arch", "sdata/uv/requirements.in", "dots/.config/hypr/hyprland/keybinds.lua",
         "dots/.config/hypr/hyprland.lua", "dots/.config/kde-material-you-colors/config.conf"]


def run(*cmd, cwd=None):
    return subprocess.run(cmd, cwd=cwd, check=True, capture_output=True, text=True).stdout


def end4_head():
    out = run("git", "ls-remote", REPO, "refs/heads/main").split()
    if not out or not SHA.match(out[0]):
        sys.exit("could not read End-4 main HEAD")
    return out[0]


def end4_quickshell_pin(sha):
    req = urllib.request.Request(PKGBUILD.format(sha=sha), headers={"User-Agent": "end4-sync"})
    text = urllib.request.urlopen(req, timeout=60).read().decode()
    m = re.search(r"^_commit='([0-9a-f]{40})'", text, re.M)
    if not m:
        sys.exit("quickshell _commit not found in End-4 PKGBUILD (format changed?)")
    return m.group(1)


def diff_summary(old, new):
    """What changed upstream in the files that usually need a matching edit here."""
    with tempfile.TemporaryDirectory() as d:
        try:
            run("git", "clone", "--quiet", "--filter=blob:none", "--no-checkout", REPO, d)
            stat = run("git", "diff", "--stat", old, new, "--", *WATCH, cwd=d).strip() or "(no changes in watched files)"
            deps = run("git", "diff", "-U0", old, new, "--", "sdata/dist-arch/*/PKGBUILD", "sdata/uv/requirements.in", cwd=d)
            n = run("git", "rev-list", "--count", f"{old}..{new}", cwd=d).strip()
        except subprocess.CalledProcessError:
            # first run (placeholder rev) or old rev rewritten upstream: no diff available
            return "?", "(no diff: old revision not found upstream, probably the first run)", ""
    deps = "\n".join(l for l in deps.splitlines() if l[:1] in "+-" and not l.startswith(("+++", "---")))
    return n, stat, deps[:6000] or "(no dependency lines changed)"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--summary", default="bump-summary.md")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    flake, home = Path("flake.nix"), Path("end4-home.nix")
    ftxt, htxt = flake.read_text(), home.read_text()
    qm, dm = QS_RE.search(ftxt), DOTS_RE.search(htxt)
    if not qm or not dm:
        sys.exit("pin markers not found: need the quickshell url line in flake.nix and dotsRev in end4-home.nix")
    old_qs, old_dots = qm.group(2), dm.group(2)

    new_dots = end4_head()
    new_qs = end4_quickshell_pin(new_dots)
    for v in (new_dots, new_qs):
        assert SHA.match(v), v
    changed = (new_dots, new_qs) != (old_dots, old_qs)
    print(f"dotsRev    {old_dots[:8]} -> {new_dots[:8]}\nquickshell {old_qs[:8]} -> {new_qs[:8]}\nchanged: {changed}")

    if changed:
        n, stat, deps = diff_summary(old_dots, new_dots)
        body = (f"Automated sync with the official End-4 repo.\n\n"
                f"| pin | old | new |\n|---|---|---|\n"
                f"| End-4 dots (`dotsRev`) | `{old_dots[:8]}` | `{new_dots[:8]}` |\n"
                f"| quickshell (End-4's Arch pin at that commit) | `{old_qs[:8]}` | `{new_qs[:8]}` |\n\n"
                f"{n} upstream commits: https://github.com/end-4/dots-hyprland/compare/{old_dots}...{new_dots}\n\n"
                f"**Before merging:** rebuild in the VM and log in. Check the files below for new packages or renamed things.\n\n"
                f"<details><summary>Watched upstream files</summary>\n\n```\n{stat}\n```\n</details>\n\n"
                f"<details><summary>Dependency lines changed upstream</summary>\n\n```diff\n{deps}\n```\n</details>\n")
        Path(a.summary).write_text(body)
        if not a.dry_run:
            flake.write_text(QS_RE.sub(lambda m: m.group(1) + new_qs + m.group(3), ftxt, count=1))
            home.write_text(DOTS_RE.sub(lambda m: m.group(1) + new_dots + m.group(3), htxt, count=1))

    out = os.environ.get("GITHUB_OUTPUT")
    if out:
        with open(out, "a") as f:
            f.write(f"changed={'true' if changed else 'false'}\nshort={new_dots[:8]}\n")


if __name__ == "__main__":
    main()
