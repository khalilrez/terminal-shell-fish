#!/usr/bin/env bash
# terminal-shell installer: fish + starship + modern CLI tools, Catppuccin Mocha everywhere.
#
# Works on macOS (Homebrew) and Linux (apt, dnf, pacman, zypper, apk). Any tool the
# package manager can't provide (or everything, without sudo) is installed from its
# GitHub release into ~/.local/bin. Safe to re-run: it updates in place and backs up
# anything it would overwrite.
#
#   ./install.sh                  run from a clone of this repo
#   curl -fsSL <raw-url>/install.sh | TS_REPO=<git-url> bash
#
# Options:
#   --no-sudo      never use sudo; install everything into ~/.local/bin
#   --no-packages  skip installing tools, only link configs and plugins
#   --no-fonts     skip installing JetBrainsMono Nerd Font
#   --no-chsh      don't make fish the login shell
#   --no-git       don't configure git to use delta
set -euo pipefail

TS_REPO="${TS_REPO:-}"
TS_DIR="${TS_DIR:-$HOME/.local/share/terminal-shell}"
BIN_DIR="$HOME/.local/bin"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/terminal-shell"
BACKUP_DIR="$STATE_DIR/backup-$(date +%Y%m%d-%H%M%S)"

USE_SUDO=1 DO_PACKAGES=1 DO_FONTS=1 DO_CHSH=1 DO_GIT=1
for arg in "$@"; do
  case "$arg" in
    --no-sudo) USE_SUDO=0 ;;
    --no-packages) DO_PACKAGES=0 ;;
    --no-fonts) DO_FONTS=0 ;;
    --no-chsh) DO_CHSH=0 ;;
    --no-git) DO_GIT=0 ;;
    -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

# ── output ────────────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  C_B=$'\033[1m' C_M=$'\033[38;2;203;166;247m' C_G=$'\033[38;2;166;227;161m'
  C_Y=$'\033[38;2;249;226;175m' C_R=$'\033[38;2;243;139;168m' C_D=$'\033[2m' C_0=$'\033[0m'
else
  C_B='' C_M='' C_G='' C_Y='' C_R='' C_D='' C_0=''
fi
step() { printf '\n%s%s==>%s %s%s%s\n' "$C_B" "$C_M" "$C_0" "$C_B" "$*" "$C_0"; }
ok()   { printf '  %s✓%s %s\n' "$C_G" "$C_0" "$*"; }
info() { printf '  %s·%s %s\n' "$C_D" "$C_0" "$*"; }
warn() { printf '  %s!%s %s\n' "$C_Y" "$C_0" "$*" >&2; }
die()  { printf '%s✗ %s%s\n' "$C_R" "$*" "$C_0" >&2; exit 1; }
has()  { command -v "$1" >/dev/null 2>&1; }

# ── bootstrap: when piped through curl, clone the repo and re-run from it ─────
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
if [ -z "$SCRIPT_DIR" ] || [ ! -d "$SCRIPT_DIR/home" ]; then
  has git || die "git is required to bootstrap. Install git and re-run."
  if [ -d "$TS_DIR/.git" ]; then
    step "Updating $TS_DIR"
    git -C "$TS_DIR" pull --ff-only
  else
    [ -n "$TS_REPO" ] || die "Set TS_REPO to this repo's git URL, e.g. curl ... | TS_REPO=https://github.com/you/terminal-shell bash"
    step "Cloning $TS_REPO"
    git clone --depth 1 "$TS_REPO" "$TS_DIR"
  fi
  exec bash "$TS_DIR/install.sh" "$@"
fi
REPO="$SCRIPT_DIR"

# ── platform ──────────────────────────────────────────────────────────────────
OS="$(uname -s)"
case "$(uname -m)" in
  x86_64|amd64) ARCH=x86_64 GOARCH=amd64 ;;
  aarch64|arm64) ARCH=aarch64 GOARCH=arm64 ;;
  *) ARCH="$(uname -m)" GOARCH="$ARCH" ;;
esac

PM=""
if [ "$OS" = Darwin ]; then PM=brew
elif has apt-get; then PM=apt
elif has dnf; then PM=dnf
elif has pacman; then PM=pacman
elif has zypper; then PM=zypper
elif has apk; then PM=apk
fi

SUDO=""
CAN_ROOT=0
if [ "$(id -u)" -eq 0 ]; then
  CAN_ROOT=1
elif [ "$USE_SUDO" -eq 1 ] && has sudo; then
  # Prompt only when there's a terminal to prompt on
  if sudo -n true 2>/dev/null || { [ -r /dev/tty ] && [ -t 1 ]; }; then SUDO=sudo CAN_ROOT=1; fi
fi

mkdir -p "$BIN_DIR" "$STATE_DIR"
export PATH="$BIN_DIR:$PATH"

# ── tool detection ────────────────────────────────────────────────────────────
TOOLS="fish starship eza bat fd rg fzf zoxide delta atuin direnv lazygit tldr jq btop"

# Ubuntu ships some tools under other names, and /usr/sbin/bat can be Bacula's
# admin console, so check for the real thing.
real_bat() {
  if has batcat; then return 0; fi
  bat --version 2>/dev/null | grep -q '^bat '
}
fish_ok() {
  # Needs 3.6+ for regex abbreviations
  local v
  v="$(fish --version 2>/dev/null | sed -E 's/.*version ([0-9]+)\.([0-9]+).*/\1 \2/')" || return 1
  [ -n "$v" ] || return 1
  set -- $v
  [ "$1" -gt 3 ] || { [ "$1" -eq 3 ] && [ "$2" -ge 6 ]; }
}
tool_ok() {
  case "$1" in
    fish) fish_ok ;;
    bat) real_bat ;;
    fd) has fd || has fdfind ;;
    *) has "$1" ;;
  esac
}

# Package name for a tool, per package manager. Empty = not packaged there.
pkg_name() {
  case "$PM:$1" in
    *:rg) echo ripgrep ;;
    *:tldr) echo tealdeer ;;
    apt:fd|dnf:fd) echo fd-find ;;
    apk:delta) echo delta ;;
    *:delta) echo git-delta ;;
    dnf:starship|dnf:atuin) echo "" ;;
    *) echo "$1" ;;
  esac
}

pm_available() {
  case "$PM" in
    apt) apt-cache show "$1" >/dev/null 2>&1 ;;
    *) return 0 ;;
  esac
}

pm_install() {
  case "$PM" in
    brew) brew install "$@" ;;
    apt) $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$@" ;;
    dnf) $SUDO dnf install -y -q "$@" ;;
    pacman) $SUDO pacman -S --needed --noconfirm "$@" ;;
    zypper) $SUDO zypper --non-interactive install "$@" ;;
    apk) $SUDO apk add "$@" ;;
  esac
}

pm_refresh() {
  case "$PM" in
    apt) $SUDO apt-get update -qq ;;
    pacman) $SUDO pacman -Sy --noconfirm ;;
    *) : ;;
  esac
}

# Install a binary from a GitHub release into ~/.local/bin.
#   gh_install <owner/repo> <binary> <asset-filename-regex>
gh_install() {
  local repo="$1" bin="$2" pattern="$3" urls url tmp file
  urls="$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" \
    | grep -oE '"browser_download_url": *"[^"]+"' | sed -E 's/.*"(https:[^"]+)"$/\1/' \
    | grep -E "/$pattern\$" || true)"
  # Prefer statically linked musl builds when both exist
  url="$(printf '%s\n' "$urls" | grep musl | head -1)"
  [ -n "$url" ] || url="$(printf '%s\n' "$urls" | head -1)"
  [ -n "$url" ] || { warn "no $repo release asset for $OS/$ARCH"; return 1; }
  tmp="$(mktemp -d)"
  curl -fsSL "$url" -o "$tmp/asset" || { rm -rf "$tmp"; return 1; }
  mkdir "$tmp/x"
  case "$url" in
    *.tar.gz|*.tgz) tar -xzf "$tmp/asset" -C "$tmp/x" ;;
    *.tar.xz) tar -xJf "$tmp/asset" -C "$tmp/x" ;;
    *.zip) unzip -q "$tmp/asset" -d "$tmp/x" ;;
    *) cp "$tmp/asset" "$tmp/x/$bin" ;;
  esac
  file="$(find "$tmp/x" -type f -name "$bin" | head -1)"
  [ -n "$file" ] || { warn "$bin not found in $url"; rm -rf "$tmp"; return 1; }
  install -m 755 "$file" "$BIN_DIR/$bin"
  rm -rf "$tmp"
  ok "$bin $(basename "$url") → $BIN_DIR"
}

gh_fallback() {
  local L="unknown-linux-(musl|gnu)"
  case "$1" in
    fish) gh_install fish-shell/fish-shell fish "fish-[0-9.]+-linux-$ARCH\.tar\.xz" ;;
    starship) gh_install starship/starship starship "starship-$ARCH-$L\.tar\.gz" ;;
    eza) gh_install eza-community/eza eza "eza_$ARCH-$L\.tar\.gz" ;;
    bat) gh_install sharkdp/bat bat "bat-v[0-9.]+-$ARCH-$L\.tar\.gz" ;;
    fd) gh_install sharkdp/fd fd "fd-v[0-9.]+-$ARCH-$L\.tar\.gz" ;;
    rg) gh_install BurntSushi/ripgrep rg "ripgrep-[0-9.]+-$ARCH-$L\.tar\.gz" ;;
    fzf) gh_install junegunn/fzf fzf "fzf-[0-9.]+-linux_$GOARCH\.tar\.gz" ;;
    zoxide) gh_install ajeetdsouza/zoxide zoxide "zoxide-[0-9.]+-$ARCH-$L\.tar\.gz" ;;
    delta) gh_install dandavison/delta delta "delta-[0-9.]+-$ARCH-$L\.tar\.gz" ;;
    atuin) gh_install atuinsh/atuin atuin "atuin-$ARCH-$L\.tar\.gz" ;;
    direnv) gh_install direnv/direnv direnv "direnv\.linux-$GOARCH" ;;
    lazygit) gh_install jesseduffield/lazygit lazygit "lazygit_[0-9.]+_linux_$([ "$ARCH" = x86_64 ] && echo x86_64 || echo arm64)\.tar\.gz" ;;
    tldr) gh_install tealdeer-rs/tealdeer tldr "tealdeer-linux-$ARCH-musl" ;;
    btop) gh_install aristocratos/btop btop "btop-$ARCH-unknown-linux-musl\.tar\.gz" ;;
    jq) gh_install jqlang/jq jq "jq-linux-$GOARCH" ;;
    *) return 1 ;;
  esac
}

install_tools() {
  step "Installing tools"
  local missing="" t p pkgs=""
  for t in $TOOLS; do tool_ok "$t" || missing="$missing $t"; done
  if [ -z "$missing" ]; then ok "all tools already installed"; return; fi
  info "missing:$missing"

  if [ "$PM" = brew ] && ! has brew; then
    step "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"; else eval "$(/usr/local/bin/brew shellenv)"; fi
  fi

  if [ -n "$PM" ] && { [ "$PM" = brew ] || [ "$CAN_ROOT" -eq 1 ]; }; then
    pm_refresh || warn "package index refresh failed"
    for t in $missing; do
      p="$(pkg_name "$t")"
      [ -n "$p" ] && pm_available "$p" && pkgs="$pkgs $p"
    done
    # Needed for downloads, archives and font discovery
    for p in git curl unzip; do has "$p" || pkgs="$pkgs $p"; done
    [ "$OS" = Linux ] && ! has fc-cache && pkgs="$pkgs fontconfig"
    if [ -n "$pkgs" ]; then
      info "$PM install$pkgs"
      # shellcheck disable=SC2086
      pm_install $pkgs || for p in $pkgs; do pm_install "$p" || warn "$PM could not install $p"; done
    fi
  else
    info "no root access: installing into $BIN_DIR"
  fi

  # Whatever is still missing comes from GitHub releases (Linux)
  for t in $missing; do
    tool_ok "$t" && continue
    if [ "$OS" = Linux ]; then
      gh_fallback "$t" || warn "could not install $t"
    else
      warn "could not install $t"
    fi
  done
}

# Debian/Ubuntu name collisions: expose batcat/fdfind as bat/fd
make_shims() {
  if has batcat && ! [ -e "$BIN_DIR/bat" ]; then ln -s "$(command -v batcat)" "$BIN_DIR/bat"; ok "bat → batcat"; fi
  if has fdfind && ! [ -e "$BIN_DIR/fd" ]; then ln -s "$(command -v fdfind)" "$BIN_DIR/fd"; ok "fd → fdfind"; fi
}

install_fonts() {
  step "Installing JetBrainsMono Nerd Font"
  if [ "$OS" = Darwin ]; then
    if brew list --cask font-jetbrains-mono-nerd-font >/dev/null 2>&1; then ok "already installed"
    else brew install --cask font-jetbrains-mono-nerd-font; fi
    return
  fi
  # Capture first: under pipefail, `fc-list | grep -q` fails when grep exits early
  local fonts
  fonts="$(fc-list 2>/dev/null || true)"
  case "$fonts" in *"JetBrainsMono Nerd Font"*) ok "already installed"; return ;; esac
  local dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/JetBrainsMonoNerdFont" tmp
  tmp="$(mktemp -d)"
  curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz -o "$tmp/f.tar.xz" \
    || { warn "font download failed"; rm -rf "$tmp"; return; }
  mkdir -p "$dir"
  tar -xJf "$tmp/f.tar.xz" -C "$dir" --wildcards '*.ttf' 2>/dev/null || tar -xJf "$tmp/f.tar.xz" -C "$dir"
  rm -rf "$tmp"
  has fc-cache && fc-cache -f "$dir" >/dev/null
  ok "installed to $dir"
}

# Symlink everything under home/ into $HOME, backing up whatever was there.
link_configs() {
  step "Linking configs"
  local src rel dst
  while IFS= read -r src; do
    rel="${src#"$REPO/home/"}"
    dst="$HOME/$rel"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then continue; fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then
      mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
      mv "$dst" "$BACKUP_DIR/$rel"
      info "backed up ~/$rel"
    fi
    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    ok "~/$rel"
  done < <(find "$REPO/home" -type f | sort)

  local localfish="$HOME/.config/fish/local.fish"
  if [ ! -e "$localfish" ]; then
    {
      echo "# Machine-specific fish config. Not managed by terminal-shell."
      [ -f "$BACKUP_DIR/.config/fish/config.fish" ] &&
        echo "# Your previous config.fish is at $BACKUP_DIR/.config/fish/config.fish"
    } >"$localfish"
    ok "created ~/.config/fish/local.fish for per-machine settings"
  fi
  [ -d "$BACKUP_DIR" ] && info "backups in $BACKUP_DIR"
  return 0
}

FISH_BIN=""
setup_fish_plugins() {
  step "Installing fish plugins"
  FISH_BIN="$(command -v fish || true)"
  [ -n "$FISH_BIN" ] || { warn "fish not installed, skipping plugins"; return; }

  # Keep plugins the user added, drop ones this setup replaces (z → zoxide)
  local plugins="$HOME/.config/fish/fish_plugins" merged
  merged="$( { cat "$REPO/fish_plugins"; [ -f "$plugins" ] && cat "$plugins"; } \
    | grep -v -e '^jethrokuan/z$' -e '^[[:space:]]*$' | awk '!seen[$0]++')"
  printf '%s\n' "$merged" >"$plugins"

  "$FISH_BIN" -c '
    if not functions -q fisher
      curl -fsSL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    end
    fisher update' >/dev/null 2>&1 || warn "fisher update failed (re-run: fish -c \"fisher update\")"
  ok "$(grep -c . "$plugins") plugins: $(tr '\n' ' ' <"$plugins")"
}

setup_themes() {
  step "Building themes"
  if has bat || has batcat; then
    "$(command -v bat || command -v batcat)" cache --build >/dev/null && ok "bat: Catppuccin Mocha"
  fi
}

setup_git() {
  [ "$DO_GIT" -eq 1 ] && has git && has delta || return 0
  step "Configuring git to use delta"
  if [ -z "$(git config --global --get core.pager || true)" ]; then
    git config --global core.pager delta
    git config --global interactive.diffFilter 'delta --color-only'
    git config --global delta.navigate true
    git config --global delta.line-numbers true
    git config --global delta.syntax-theme 'Catppuccin Mocha'
    git config --global merge.conflictStyle zdiff3
    ok "git diff/log/show now use delta"
  else
    info "core.pager already set to '$(git config --global --get core.pager)', leaving it alone"
  fi
}

setup_atuin() {
  has atuin || return 0
  [ -f "$STATE_DIR/atuin-imported" ] && return 0
  step "Importing shell history into atuin"
  atuin import auto >/dev/null 2>&1 || true
  if [ -f "$HOME/.local/share/fish/fish_history" ]; then atuin import fish >/dev/null 2>&1 || true; fi
  touch "$STATE_DIR/atuin-imported"
  ok "history imported (sync across machines: atuin register / atuin login)"
}

login_shell() {
  if [ "$OS" = Darwin ]; then dscl . -read "$HOME" UserShell 2>/dev/null | awk '{print $2}'
  else getent passwd "$(id -un)" 2>/dev/null | cut -d: -f7; fi
}

set_login_shell() {
  [ -n "$FISH_BIN" ] || return 0
  step "Setting fish as login shell"
  if [ "$(login_shell)" = "$FISH_BIN" ]; then ok "already $FISH_BIN"; return; fi
  if ! grep -qx "$FISH_BIN" /etc/shells 2>/dev/null; then
    if [ "$CAN_ROOT" -eq 1 ]; then echo "$FISH_BIN" | $SUDO tee -a /etc/shells >/dev/null
    else
      # Can't register a user-local fish in /etc/shells; hand off from bash instead
      if ! grep -q 'terminal-shell: exec fish' "$HOME/.bashrc" 2>/dev/null; then
        printf '\n# terminal-shell: exec fish\n[[ $- == *i* ]] && [ -x "%s" ] && [ -z "$NO_FISH" ] && exec "%s"\n' "$FISH_BIN" "$FISH_BIN" >>"$HOME/.bashrc"
      fi
      ok "no root: interactive bash will exec fish (set NO_FISH=1 to skip)"
      return
    fi
  fi
  if chsh -s "$FISH_BIN" </dev/tty; then ok "login shell is now $FISH_BIN (takes effect on next login)"
  else warn "chsh failed; run: chsh -s $FISH_BIN"; fi
}

# ── main ──────────────────────────────────────────────────────────────────────
printf '%s%sterminal-shell%s  %s %s · %s · %s\n' "$C_B" "$C_M" "$C_0" "$C_D" "$OS" "$ARCH" "${PM:-no package manager}${SUDO:+ (sudo)}$C_0"

[ "$DO_PACKAGES" -eq 1 ] && install_tools
make_shims
[ "$DO_FONTS" -eq 1 ] && install_fonts
link_configs
setup_themes
setup_fish_plugins
setup_git
setup_atuin
[ "$DO_CHSH" -eq 1 ] && set_login_shell

step "Done"
missing=""
for t in $TOOLS; do tool_ok "$t" || missing="$missing $t"; done
[ -n "$missing" ] && warn "still missing:$missing"
cat <<EOF
  Set your terminal font to ${C_B}JetBrainsMono Nerd Font${C_0}, then start a new shell (or run ${C_B}exec fish${C_0}).
  Per-machine settings go in ${C_B}~/.config/fish/local.fish${C_0}. Update later with ${C_B}git -C $REPO pull && $REPO/install.sh${C_0}.
EOF
