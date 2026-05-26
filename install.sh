#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  ISO Launcher & Downloader for Termux X11 - INSTALLER
# ============================================================
set -e

GREEN='\033[1;32m'; RED='\033[1;31m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; NC='\033[0m'
BOLD='\033[1m'

banner() {
cat <<'EOF'
============================================================
  ISO LAUNCHER & DOWNLOADER  -  TERMUX X11 EDITION
  Modern QEMU VM Launcher for Android
============================================================
EOF
}

log()  { echo -e "${CYAN}[*]${NC} $*"; }
ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[X]${NC} $*"; }

PROJECT_DIR="$HOME/iso-launcher"

check_termux() {
  if [ ! -d "/data/data/com.termux" ]; then
    warn "Tidak terdeteksi sebagai Termux. Lanjut dengan asumsi Linux/Termux compatible."
  fi
}

setup_storage() {
  if [ ! -d "$HOME/storage" ]; then
    log "Meminta izin storage Termux..."
    termux-setup-storage || warn "termux-setup-storage gagal, lewati."
  fi
}

update_pkg() {
  log "Update repository Termux..."
  pkg update -y && pkg upgrade -y || warn "pkg update gagal sebagian."
}

install_deps() {
  log "Menginstall dependency utama..."
  local deps=(
    qemu-system-x86-64
    qemu-utils
    pulseaudio
    wget curl git
    dialog
    ncurses-utils
    termux-api
    proot
    coreutils
    util-linux
  )
  for d in "${deps[@]}"; do
    log "Install: $d"
    pkg install -y "$d" 2>/dev/null || warn "Gagal install $d (mungkin sudah ada)"
  done
}

install_x11() {
  log "Mengaktifkan repository x11..."
  pkg install -y x11-repo 2>/dev/null || true
  log "Install termux-x11 + virglrenderer + mesa..."
  pkg install -y termux-x11-nightly virglrenderer-android mesa 2>/dev/null \
    || warn "Beberapa paket X11 mungkin gagal. Install Termux:X11 APK manual jika perlu."
}

setup_project() {
  log "Membuat struktur project di $PROJECT_DIR ..."
  mkdir -p "$PROJECT_DIR"/{config,iso,vm,cache,logs,lang}
  SRC="$(cd "$(dirname "$0")" && pwd)"
  cp -f "$SRC"/*.sh "$PROJECT_DIR"/ 2>/dev/null || true
  cp -rf "$SRC"/lang/* "$PROJECT_DIR/lang/" 2>/dev/null || true
  cp -f "$SRC"/README.md "$PROJECT_DIR/" 2>/dev/null || true
  chmod +x "$PROJECT_DIR"/*.sh 2>/dev/null || true
  ok "Project tersedia di: $PROJECT_DIR"
}

ask_autostart() {
  echo
  read -rp "Aktifkan auto-start launcher saat Termux dibuka? [y/N]: " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    local rc="$HOME/.bashrc"
    touch "$rc"
    if ! grep -q "iso-launcher/launcher.sh" "$rc"; then
      echo "" >> "$rc"
      echo "# >>> ISO Launcher Autostart >>>" >> "$rc"
      echo "[ -f \"$PROJECT_DIR/launcher.sh\" ] && bash \"$PROJECT_DIR/launcher.sh\"" >> "$rc"
      echo "# <<< ISO Launcher Autostart <<<" >> "$rc"
      ok "Autostart aktif."
    else
      warn "Autostart sudah ada."
    fi
  else
    log "Lewati autostart."
  fi
}

main() {
  clear; banner
  check_termux
  setup_storage
  update_pkg
  install_deps
  install_x11
  setup_project
  ask_autostart
  echo
  ok "Instalasi selesai!"
  echo -e "${BOLD}Jalankan dengan:${NC} bash $PROJECT_DIR/launcher.sh"
}

main "$@"
