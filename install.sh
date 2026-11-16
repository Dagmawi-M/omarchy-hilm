#!/usr/bin/env bash
# ┌──────────────────────────────────────────────────────────────────────────┐
# │ omarchy-hilm installer                                                   │
# │                                                                          │
# │   ./install.sh                  interactive wizard                       │
# │   ./install.sh --yes            accept all defaults                      │
# │   ./install.sh --dir ~/Pics     use this wallpaper folder                │
# │   ./install.sh --no-keybind     don't add SUPER+CTRL+SPACE               │
# │                                                                          │
# │ Safe to re-run (updates in place). Never deletes or moves your files.    │
# └──────────────────────────────────────────────────────────────────────────┘
set -euo pipefail

VERSION="1.1.2"
REPO="https://github.com/Dagmawi-M/omarchy-hilm"
BIN="$HOME/.local/bin"
SHARE="$HOME/.local/share/omarchy-hilm"
CONF_DIR="$HOME/.config/omarchy-hilm"
OMARCHY_POOL="$HOME/.config/omarchy/wallpapers"
MARK="# omarchy-hilm"
SCRIPTS=(omarchy-hilm omarchy-hilm-theme omarchy-hilm-rotate)
# ── which Omarchy? ───────────────────────────────────────────────────────────
# Omarchy 4 moved state to ~/.local/state, Hyprland config to Lua, and draws the
# background with omarchy-shell (videos included). Omarchy 3 uses swaybg.
OMARCHY_DIR=""
for c in "${OMARCHY_PATH:-}" "$HOME/.local/share/omarchy" /usr/share/omarchy; do
  [[ -n $c && -d $c ]] && { OMARCHY_DIR=$c; break; }
done
if [[ -d $HOME/.local/state/omarchy/current ]] && command -v omarchy-theme-bg-set >/dev/null; then
  OMARCHY4=1; STATE="$HOME/.local/state/omarchy/current"
else
  OMARCHY4=0; STATE="$HOME/.config/omarchy/current"
fi
DEPS=(python python-gobject python-cairo gtk3 gtk-layer-shell imagemagick ffmpegthumbnailer libnotify)
((OMARCHY4)) || DEPS+=(swaybg)
LOG="$(mktemp -t omarchy-hilm-install.XXXXXX.log)"

YES=0 KEYBIND=1 DIR_ARG=""
while (($#)); do
  case $1 in
    -y|--yes) YES=1 ;;
    --no-keybind) KEYBIND=0 ;;
    --dir) DIR_ARG="${2:-}"; shift ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
  esac
  shift
done

# ── look & feel ──────────────────────────────────────────────────────────────
C=$'\033[38;5;51m' M=$'\033[38;5;177m' G=$'\033[38;5;84m' Y=$'\033[38;5;221m'
R=$'\033[38;5;203m' D=$'\033[2m' B=$'\033[1m' N=$'\033[0m'
TTY=/dev/tty; [[ -r $TTY ]] || TTY=/dev/stdin
HAS_GUM=0
if command -v gum >/dev/null && [[ -t 1 && -z ${HILM_NO_GUM:-} ]]; then
  # older gum builds lack some styling flags: use plain prompts there instead of failing
  gum choose --help 2>&1 | grep -q -- --header.foreground &&
    gum confirm --help 2>&1 | grep -q -- --selected.background && HAS_GUM=1
fi

ok()   { printf "  ${G}✔${N} %s\n" "$*"; }
info() { printf "  ${C}›${N} %s\n" "$*"; }
warn() { printf "  ${Y}!${N} %s\n" "$*"; }
die()  { printf "\n  ${R}✖ %s${N}\n  ${D}log: %s${N}\n\n" "$*" "$LOG" >&2; exit 1; }
hr()   { printf "  ${D}%s${N}\n" "────────────────────────────────────────────────────────"; }
title(){ printf "\n  ${B}${M}%s${N} ${B}%s${N}\n" "$1" "$2"; hr; }

banner() {
  clear 2>/dev/null || true
  local lines
  mapfile -t lines <<'ART'
       ▄█▄▄
        █████████                █████          ▄▄███████████████████▄
        ▀▀▀▀▀████                 █████       ▄████████████████████████
             ████               ▄██████▄      █████  █████  █████  █████
         ▄▄▄█████▄▄▄▄         ██████████▄    █████   █████  █████▄▄████▀
       ████████████████▄     ████▀  ▀████▄    █████▄▄█████  ██████████▀
     ▄█████▀▀████▀▀█████▄   █████▄▄▄ ▀████▄   ▀███████████  ▀▀▀▀▀▀▀▀▀
     █████   ████   █████   █████████ ▀████▄     ▀▀▀█████
     █████   ████   █████  █████ ████▀ ▀████       █████
     █████   ████   █████  ██████████   █████     █████
     ▀▀▀▀▀   ▀▀▀▀   ▀▀▀▀▀  ▀▀▀▀▀▀▀▀      ▀▀▀▀▀   ▀▀▀▀▀
ART
  local cols=(51 51 45 45 39 39 99 135 135 177 177 177) i=0
  echo
  for l in "${lines[@]}"; do
    printf "\033[38;5;%sm%s${N}\n" "${cols[i++]}" "$l"
    sleep 0.04
  done
  printf "\n  ${B}${C}H I L M${N}  ${D}·  ሕልም means \"dream\" in Amharic${N}\n"
  printf "  ${D}futuristic wallpaper picker for omarchy · v%s${N}\n" "$VERSION"
}

# run "title" cmd...   → animated spinner, ✔/✖ when done, output to log
SPIN=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
run() {
  local msg=$1; shift
  ("$@") >>"$LOG" 2>&1 &
  local pid=$! i=0
  tput civis 2>/dev/null || true
  while kill -0 $pid 2>/dev/null; do
    printf "\r  ${C}%s${N} %s " "${SPIN[i++ % ${#SPIN[@]}]}" "$msg"
    sleep 0.08
  done
  tput cnorm 2>/dev/null || true
  if wait $pid; then printf "\r  ${G}✔${N} %s \033[K\n" "$msg"
  else printf "\r  ${R}✖${N} %s \033[K\n" "$msg"; return 1; fi
}

progress() {  # progress <done> <total> <label>
  local w=40 f=$(($1 * 40 / $2)) bar="" i
  for ((i = 0; i < w; i++)); do ((i < f)) && bar+="█" || bar+="░"; done
  printf "\n  ${C}%s${N}  ${B}%3d%%${N}  ${D}%s${N}\n" "$bar" $(($1 * 100 / $2)) "$3"
}

ask_choose() {  # ask_choose <header> options... → prints chosen
  local header=$1; shift
  if ((HAS_GUM)); then
    gum choose --header "$header" --cursor "▸ " \
      --header.foreground 177 --cursor.foreground 51 --selected.foreground 51 "$@" <"$TTY"
  else
    printf "  %s\n" "$header" >&2
    local i=1; for o in "$@"; do printf "    ${C}%d)${N} %s\n" $i "$o" >&2; ((i++)); done
    local n; read -rp "  choose [1]: " n <"$TTY"; n=${n:-1}
    local a=("$@"); printf '%s' "${a[n - 1]:-${a[0]}}"
  fi
}

ask_input() {  # ask_input <prompt> <placeholder>
  if ((HAS_GUM)); then
    gum input --prompt "  $1 › " --placeholder "$2" --prompt.foreground 51 --width 70 <"$TTY"
  else
    local v; read -rp "  $1 › " v <"$TTY"; printf '%s' "$v"
  fi
}

ask_yes() {  # ask_yes <question>  (default yes)
  ((YES)) && return 0
  if ((HAS_GUM)); then
    gum confirm "  $1" --prompt.foreground 177 --selected.background 51 --selected.foreground 0 <"$TTY"
  else
    local a; read -rp "  $1 [Y/n] " a <"$TTY"; [[ ! $a =~ ^[Nn] ]]
  fi
}

count_images() {
  # skip hidden entries *inside* the folder (the folder itself may live under ~/.config)
  find -L "$1" -mindepth 1 -maxdepth 3 -name '.*' -prune -o -type f \( -iname '*.png' -o -iname '*.jpg' \
    -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.bmp' -o -iname '*.gif' -o -iname '*.mp4' \
    -o -iname '*.webm' \) -print 2>/dev/null | wc -l
}

# ── 0. preflight ─────────────────────────────────────────────────────────────
[[ $EUID -ne 0 ]] || die "Run as your normal user, not root (sudo is only used for packages)."
command -v pacman >/dev/null || die "pacman not found. This installer is for Omarchy (Arch Linux)."

SRC="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [[ ! -f "$SRC/bin/omarchy-hilm" ]]; then   # curl | bash
  command -v git >/dev/null || sudo pacman -S --needed --noconfirm git
  SRC="$(mktemp -d)"; trap 'rm -rf "$SRC"' EXIT
  git clone --depth 1 -q "$REPO" "$SRC" || die "Could not download $REPO"
fi

banner

# ── 1. scan ──────────────────────────────────────────────────────────────────
title "01" "SCANNING SYSTEM"
OMARCHY_VER="$(cat "$OMARCHY_DIR/version" 2>/dev/null || true)"
if [[ -d $HOME/.config/omarchy ]]; then ok "Omarchy ${OMARCHY_VER:-detected} $( ((OMARCHY4)) && echo '(4.x layout)' || echo '(3.x layout)')"
else warn "Omarchy config not found. Continuing, but this is built for Omarchy."; fi
if command -v omarchy-theme-set-templates >/dev/null; then
  FULL=1; ok "Theme engine supports auto re-theming"
else
  FULL=0; warn "Older Omarchy: wallpapers only (run 'omarchy-update' later for re-theming)"
fi
missing=(); for p in "${DEPS[@]}"; do pacman -Qi "$p" &>/dev/null || missing+=("$p"); done
((${#missing[@]})) && info "${#missing[@]} package(s) to install: ${missing[*]}" || ok "All dependencies present"
if ((OMARCHY4)); then
  ok "Video wallpapers supported natively"
else
  command -v mpvpaper >/dev/null && ok "mpvpaper found: video wallpapers enabled" \
                                 || info "mpvpaper not installed (optional, for video wallpapers)"
fi
[[ -f $BIN/omarchy-hilm ]] && info "Existing install found: will update in place"

# ── 2. wallpaper folder ──────────────────────────────────────────────────────
title "02" "WALLPAPER FOLDER"
PREV=""
[[ -f $CONF_DIR/config ]] && PREV="$(grep -oP '^WALLPAPER_DIR="?\K[^"]*' "$CONF_DIR/config" || true)"
PREV="${PREV/#\~/$HOME}"
SEED=0

if [[ -n $DIR_ARG ]]; then
  POOL="${DIR_ARG/#\~/$HOME}"
elif [[ -n $PREV && -d $PREV ]]; then
  POOL="$PREV"; ok "Using your current folder: ${POOL/#$HOME/\~} ($(count_images "$POOL") images)"
  ((YES)) || ask_yes "Keep this folder?" || POOL=""
elif [[ -d $OMARCHY_POOL ]] && (( $(count_images "$OMARCHY_POOL") > 0 )); then
  POOL="$OMARCHY_POOL"; ok "Found Omarchy wallpaper folder: ~/.config/omarchy/wallpapers ($(count_images "$POOL") images)"
else
  POOL=""
fi

if [[ -z $POOL ]]; then
  if ((YES)); then
    POOL="$OMARCHY_POOL"; SEED=1
  else
    info "Where do you keep your wallpapers? ${D}(files are only read, never moved or deleted)${N}"
    echo
    opts=(); paths=()
    for c in "$HOME/Pictures/Wallpapers" "$HOME/Pictures/wallpapers" "$HOME/Wallpapers" "$HOME/wallpapers" \
             "$HOME/.config/omarchy/backgrounds" "$HOME/Pictures"; do
      [[ -d $c ]] || continue
      n=$(count_images "$c"); ((n > 0)) || continue
      opts+=("${c/#$HOME/\~}  ($n images)"); paths+=("$c")
    done
    opts+=("✚ Create Omarchy folder ~/.config/omarchy/wallpapers (starts with copies of your theme's backgrounds)")
    paths+=("__create__")
    opts+=("✎ Type another folder path…"); paths+=("__custom__")

    pick="$(ask_choose "Choose your wallpaper folder:" "${opts[@]}")" || die "Cancelled."
    for i in "${!opts[@]}"; do [[ ${opts[i]} == "$pick" ]] && POOL="${paths[i]}"; done
    [[ -n $POOL ]] || POOL="__create__"

    if [[ $POOL == "__create__" ]]; then
      POOL="$OMARCHY_POOL"; SEED=1
    elif [[ $POOL == "__custom__" ]]; then
      while :; do
        p="$(ask_input "Folder" "~/Pictures/Wallpapers")"
        p="${p/#\~/$HOME}"; p="${p%/}"
        [[ -z $p ]] && { POOL="$OMARCHY_POOL"; SEED=1; break; }
        if [[ -d $p ]]; then POOL="$p"; break; fi
        if ask_yes "'${p/#$HOME/\~}' doesn't exist. Create it?"; then mkdir -p "$p"; POOL="$p"; break; fi
      done
    fi
  fi
fi
POOL="$(realpath -m "$POOL")"
ok "Wallpaper folder: ${B}${POOL/#$HOME/\~}${N}"

# ── 3. confirm ───────────────────────────────────────────────────────────────
title "03" "READY TO INSTALL"
printf "  ${D}scripts   ${N} ~/.local/bin/{omarchy-hilm,-theme,-rotate}\n"
printf "  ${D}wallpapers${N} %s\n" "${POOL/#$HOME/\~}"
((${#missing[@]})) && printf "  ${D}packages  ${N} %s\n" "${missing[*]}"
((KEYBIND)) && printf "  ${D}shortcut  ${N} SUPER + CTRL + SPACE ${D}(replaces Omarchy's default background shortcut)${N}\n"
printf "  ${D}theme     ${N} %s\n" "$( ((FULL)) && echo "creates its own 'hilm' theme. Your themes are untouched" || echo "wallpaper only")"
echo
if ((KEYBIND)) && ! ((YES)); then
  ask_yes "Add the SUPER + CTRL + SPACE shortcut?" || KEYBIND=0
fi
ask_yes "Install now?" || { echo; info "Nothing was changed."; exit 0; }

# ── migrate from the old name (omarchy-wallpaper-cards) ─────────────────────
OLD_CONF="$HOME/.config/omarchy-wallpaper-cards"
if [[ -d $OLD_CONF && ! -d $CONF_DIR ]]; then
  cp -r "$OLD_CONF" "$CONF_DIR"     # copy settings/favourites/hidden list, keep the original
fi

# ── 4. install ───────────────────────────────────────────────────────────────
title "04" "INSTALLING"
TOTAL=6 STEP=0
tick() { STEP=$((STEP + 1)); }

if ((${#missing[@]})); then
  info "sudo is needed to install packages"
  sudo -v <"$TTY" || die "sudo failed"
  run "Installing packages (${#missing[@]})" sudo pacman -S --needed --noconfirm "${missing[@]}" \
    || die "Package install failed. Try 'sudo pacman -Syu' (or 'omarchy-update') first, then re-run."
else
  ok "Packages already installed"
fi
tick

do_scripts() {
  mkdir -p "$BIN" "$SHARE"
  for f in "${SCRIPTS[@]}"; do
    # never clobber an unrelated script with the same name
    if [[ -e $BIN/$f ]] && ! grep -q "omarchy-wallpaper" "$BIN/$f"; then
      cp "$BIN/$f" "$BIN/$f.bak.$(date +%s)"
    fi
    install -m 755 "$SRC/bin/$f" "$BIN/$f"
  done
  install -m 755 "$SRC/uninstall.sh" "$SHARE/uninstall.sh"
  echo "$VERSION" >"$SHARE/version"
}
run "Installing picker scripts" do_scripts || die "Could not write to $BIN"; tick

do_config() {
  mkdir -p "$CONF_DIR"
  { echo "# omarchy-hilm settings"
    echo "WALLPAPER_DIR=\"$POOL\""; } >"$CONF_DIR/config"
  # carry over favourites from older versions (copy, never move)
  [[ -f $HOME/.config/omarchy/wallpaper-favorites && ! -f $CONF_DIR/favorites ]] &&
    cp "$HOME/.config/omarchy/wallpaper-favorites" "$CONF_DIR/favorites"
  true
}
run "Saving settings" do_config; tick

do_pool() {
  mkdir -p "$POOL"
  ((SEED)) || return 0
  local theme; theme="$(cat "$STATE/theme.name" 2>/dev/null || true)"
  for d in "$STATE/theme/backgrounds" "$HOME/.config/omarchy/backgrounds/$theme" \
           "$OMARCHY_DIR/themes/$theme/backgrounds"; do
    [[ -d $d ]] || continue
    for f in "$d"/*; do [[ -f $f ]] && cp -Ln "$f" "$POOL/" 2>/dev/null; done
  done
  true
}
run "Preparing wallpaper folder" do_pool; tick

do_thumbs() {  # warm the thumbnail cache so the first launch is instant
  PYTHONDONTWRITEBYTECODE=1 /usr/bin/python3 - "$BIN/omarchy-hilm" <<'PY'
import sys, importlib.util
from importlib.machinery import SourceFileLoader
spec = importlib.util.spec_from_loader("hilm", SourceFileLoader("hilm", sys.argv[1]))
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
for p in m.scan_pool()[:200]:
    try: m.build_cache(p)
    except Exception: pass
PY
}
if [[ -n ${WAYLAND_DISPLAY:-} ]]; then
  run "Generating thumbnails ($(count_images "$POOL") images)" do_thumbs || warn "Thumbnails will be generated on first launch"
else
  info "Thumbnails will be generated on first launch"
fi
tick

do_keybind() {
  # drop blocks left by older hilm installs in the other config format
  for f in "$HOME/.config/hypr/bindings.conf" "$HOME/.config/hypr/hyprland.conf"; do
    [[ -f $f ]] && sed -i '/# omarchy-wallpaper-cards/,+2d' "$f"
  done
  # Omarchy 4: Lua config. o.rebind replaces Omarchy's "Background switcher" on this key.
  local lua="$HOME/.config/hypr/bindings.lua"
  if [[ -f $lua ]] || [[ -f $HOME/.config/hypr/hyprland.lua ]]; then
    touch "$lua"
    for f in "$HOME/.config/hypr/bindings.conf" "$HOME/.config/hypr/hyprland.conf"; do
      [[ -f $f ]] && sed -i "/^$MARK\$/,+2d" "$f"        # stale 3.x-style block
    done
    grep -q "^-- omarchy-hilm" "$lua" && return 0
    cp "$lua" "$lua.bak-omarchy-hilm"
    printf '\n-- omarchy-hilm\no.rebind("SUPER + CTRL + SPACE", "Hilm wallpaper picker", "%s")\n' \
      "$BIN/omarchy-hilm" >>"$lua"
    command -v hyprctl >/dev/null && hyprctl reload >/dev/null 2>&1 || true
    return 0
  fi
  local conf="$HOME/.config/hypr/bindings.conf"
  [[ -f $conf ]] || conf="$HOME/.config/hypr/hyprland.conf"
  [[ -f $conf ]] || return 0
  # replace a binding left by the pre-rename version
  sed -i '/# omarchy-wallpaper-cards/,+2d' "$conf"
  grep -q "$MARK" "$conf" && return 0
  cp "$conf" "$conf.bak-omarchy-hilm"
  local line
  if grep -rqs '^bindd' "$HOME/.local/share/omarchy/default/hypr" "$conf"; then
    line="bindd = SUPER CTRL, SPACE, Hilm wallpaper picker, exec, $BIN/omarchy-hilm"
  else
    line="bind = SUPER CTRL, SPACE, exec, $BIN/omarchy-hilm"
  fi
  printf '\n%s\nunbind = SUPER CTRL, SPACE\n%s\n' "$MARK" "$line" >>"$conf"
  command -v hyprctl >/dev/null && hyprctl reload >/dev/null 2>&1 || true
}
if ((KEYBIND)); then run "Adding SUPER + CTRL + SPACE shortcut" do_keybind; else info "Skipped shortcut"; fi
tick

# Verify the picker can actually start with the system Python. A python3 from
# mise/pyenv/conda can't see pacman's python-gobject, so the scripts pin
# /usr/bin/python3; this catches anything else missing.
if ! /usr/bin/python3 -c 'import gi, cairo; gi.require_version("Gtk", "3.0"); gi.require_version("GtkLayerShell", "0.1"); from gi.repository import Gtk, GtkLayerShell' >>"$LOG" 2>&1; then
  die "The picker's libraries don't load with /usr/bin/python3. Try: sudo pacman -S python-gobject python-cairo gtk-layer-shell"
fi
ok "Picker libraries load correctly"

progress $STEP $TOTAL "complete"

# ── 5. done ──────────────────────────────────────────────────────────────────
echo
if ((HAS_GUM)); then
  gum style --border rounded --border-foreground 51 --padding "1 3" --margin "0 2" \
    "$(gum style --foreground 51 --bold '◢ INSTALLED')" "" \
    "Open it:      $(gum style --bold 'SUPER + CTRL + SPACE')  or  omarchy-hilm" \
    "Wallpapers:   ${POOL/#$HOME/~}" \
    "Uninstall:    ~/.local/share/omarchy-hilm/uninstall.sh" \
    "" "$(gum style --faint 'Nothing of yours was moved or deleted.')"
else
  printf "  ${C}${B}◢ INSTALLED${N}\n\n"
  printf "  Open it:     ${B}SUPER + CTRL + SPACE${N}  or  omarchy-hilm\n"
  printf "  Wallpapers:  %s\n" "${POOL/#$HOME/\~}"
  printf "  Uninstall:   ~/.local/share/omarchy-hilm/uninstall.sh\n"
fi
((OMARCHY4)) || command -v mpvpaper >/dev/null || printf "\n  ${D}Tip: 'yay -S mpvpaper' enables video/GIF wallpapers.${N}\n"
echo
