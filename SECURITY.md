# Security policy

## Supported versions

Only the latest release receives fixes. Update by re-running the installer.

## Reporting a vulnerability

Please **don't** open a public issue for security problems. Use GitHub's private reporting instead:
[Report a vulnerability](https://github.com/Dagmawi-M/omarchy-hilm/security/advisories/new).

Useful things to include: what the problem is, how to reproduce it, and which version you're on (`omarchy-hilm --version`).

## What hilm touches

So you know where to look: hilm runs as your user (sudo is used only by the installer, for `pacman`). It writes to `~/.local/bin`, `~/.config/omarchy-hilm`, `~/.cache/omarchy-hilm`, its own `hilm` theme folder, and one marked block in your Hyprland bindings file. The only network access is the optional Wallhaven search (`w`), which sends just your search words to wallhaven.cc over HTTPS.
