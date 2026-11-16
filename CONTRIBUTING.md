# Contributing to omarchy-hilm

Thanks for helping! Bug reports, ideas and pull requests are all welcome.

## Reporting a bug

Open an [issue](https://github.com/Dagmawi-M/omarchy-hilm/issues/new/choose) using the **Bug report** template. These details usually solve it fastest:

- `omarchy-hilm --version`
- your Omarchy version (3.x or 4.x)
- the output of running `omarchy-hilm` in a terminal while you reproduce the problem

## Project layout

| Path | What it is |
|---|---|
| `bin/omarchy-hilm` | The picker (Python, GTK3 + gtk-layer-shell, cairo) |
| `bin/omarchy-hilm-theme` | Builds an Omarchy theme from a wallpaper's colours |
| `bin/omarchy-hilm-rotate` | Auto-rotate (a systemd user timer) |
| `install.sh` / `uninstall.sh` | Installer wizard and uninstaller |

## Developing

```bash
git clone https://github.com/Dagmawi-M/omarchy-hilm
cd omarchy-hilm
./install.sh          # installs your working copy (safe to re-run)
omarchy-hilm          # run it from a terminal to see errors
```

Before opening a pull request:

```bash
bash -n install.sh uninstall.sh bin/omarchy-hilm-rotate
/usr/bin/python3 -m py_compile bin/omarchy-hilm bin/omarchy-hilm-theme
```

Ground rules:

- **Support Omarchy 3 and 4.** Paths and commands differ between them. Follow the `OMARCHY4` checks already in the code.
- **Never delete or move users' files.** "Remove" hides a wallpaper; imports never overwrite.
- **Run with `/usr/bin/python3`** (not `env python3`), so mise, pyenv or conda can't hide python-gobject.
- Keep dependencies to the official Arch repos.

## Commit messages

This project uses [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add per-monitor wallpapers
fix: keep favourites when switching sources
docs: explain transitions in the README
```

Common types: `feat`, `fix`, `docs`, `refactor`, `perf`, `chore`, `ci`.

## Releases

Versions follow [Semantic Versioning](https://semver.org/). Each release updates `CHANGELOG.md` and the `VERSION` in `bin/omarchy-hilm` and `install.sh`, then gets a `vX.Y.Z` tag and a GitHub release.

## AI-assisted contributions

hilm itself was built with an AI coding assistant (see the README). AI-assisted pull requests are welcome. Say so in the PR description, and make sure you have run and tested the change yourself.

## Code of conduct

Please follow the [Code of Conduct](CODE_OF_CONDUCT.md).
