#!/usr/bin/env bash
# Removes omarchy-hilm. Never touches your wallpapers.
set -euo pipefail
BIN="$HOME/.local/bin"
SHARE="$HOME/.local/share/omarchy-hilm"
C=$'\033[38;5;51m' G=$'\033[38;5;84m' D=$'\033[2m' N=$'\033[0m'

printf "\n  ${C}◢ omarchy-hilm: uninstall${N}\n\n"

"$BIN/omarchy-hilm-rotate" off &>/dev/null || true
rm -f "$HOME/.config/systemd/user/omarchy-hilm-rotate."{service,timer}
systemctl --user daemon-reload 2>/dev/null || true
printf "  ${G}✔${N} Auto-rotate timer removed\n"

rm -f "$BIN/omarchy-hilm" "$BIN/omarchy-hilm-theme" "$BIN/omarchy-hilm-rotate"
rm -rf "$HOME/.cache/omarchy-hilm"
printf "  ${G}✔${N} Scripts and thumbnail cache removed\n"

for CONF in "$HOME/.config/hypr/bindings.conf" "$HOME/.config/hypr/hyprland.conf"; do
  [[ -f $CONF ]] && grep -q '# omarchy-hilm' "$CONF" || continue
  sed -i '/# omarchy-hilm/,+2d' "$CONF"
  rm -f "$CONF.bak-omarchy-hilm"
  printf "  ${G}✔${N} Shortcut removed (Omarchy's default is back)\n"
done
command -v hyprctl &>/dev/null && hyprctl reload &>/dev/null || true

printf "\n  ${D}Kept: your wallpaper folder, favourites and settings (~/.config/omarchy-hilm).${N}\n"
if [[ -d $HOME/.config/omarchy/themes/hilm ]]; then
  printf "  ${D}The generated theme stays in ~/.config/omarchy/themes/hilm. Switch themes first, then delete it if you like.${N}\n"
fi
echo
rm -rf "$SHARE"
