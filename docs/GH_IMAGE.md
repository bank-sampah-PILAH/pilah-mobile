# Uploading PR screenshots with `gh image`

PR screenshots are hosted as GitHub `user-attachments` through the
[`drogers0/gh-image`](https://github.com/drogers0/gh-image) extension. GitHub has
no public API for this, so the extension reproduces the web upload flow. The
rules live in `AGENTS.md`; the per-PR steps live in the `ship` skill. This page
covers one-time setup and the safety notes.

## How it authenticates

- Images and video to a repository you can push to are uploaded with your `gh`
  token (`gh auth token`). No browser cookie is involved.
- Anything else (other file types, repositories you cannot push to) falls back
  to your browser's `user_session` cookie, read from the browser's encrypted
  store. That cookie is equivalent to your GitHub password and is not scoped.
  The tool prints "using browser session" before it does this.
- The upload endpoints are undocumented and may change without notice.

## Install

```bash
gh extension install drogers0/gh-image
~/.local/share/gh/extensions/gh-image/gh-image --version
```

**Check the version string.** On Linux, `gh extension install` picked the
`hbd-linux-amd64` release asset, not the default `linux-amd64` one, because both
names end in `linux-amd64`. The `-hbd` variant is built with the HackBrowserData
library, pinned to an unreleased commit; the default build uses `kooky` and is
the one the project intends for normal installs. If `--version` ends in `-hbd`,
replace the binary with the default asset for your platform (the one without
the `hbd-` prefix):

```bash
DIR="$(mktemp -d)"
gh release download <tag> --repo drogers0/gh-image --pattern 'linux-amd64' --dir "$DIR"
gh attestation verify "$DIR/linux-amd64" --repo drogers0/gh-image   # must exit 0
install -m 755 "$DIR/linux-amd64" ~/.local/share/gh/extensions/gh-image/gh-image
```

Use the asset name for your platform (`darwin-arm64`, `darwin-amd64`,
`linux-arm64`, `windows-amd64.exe`). `gh extension upgrade` may bring the `hbd`
build back, so re-check the version after upgrading.

## Use

Run it as shown in the `ship` skill, with an empty `HOME` and the `gh` token in
the environment, so the cookie fallback cannot read your browser:

```bash
EMPTY="$(mktemp -d)"
env -u GH_SESSION_TOKEN HOME="$EMPTY" XDG_CONFIG_HOME="$EMPTY/c" \
  XDG_DATA_HOME="$EMPTY/d" XDG_CACHE_HOME="$EMPTY/k" GH_TOKEN="$(gh auth token)" \
  ~/.local/share/gh/extensions/gh-image/gh-image \
  --repo bank-sampah-PILAH/pilah-mobile ./desktop.png
```

Each file prints `![name](https://github.com/user-attachments/assets/<id>)`.
Paste it into the PR description, or write the body to a file and run
`gh pr edit <pr> --repo bank-sampah-PILAH/pilah-mobile --body-file <file>`.

- Never set `GH_SESSION_TOKEN`; it forces the cookie route.
- Stop and tell a maintainer if stderr says it is using a browser session.
- The repository is public. Screenshots must show demo data only.
- Open the PR in a browser afterwards to confirm the images render.
