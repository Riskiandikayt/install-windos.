#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  ISO LAUNCHER - Main Menu (whiptail/dialog UI)
# ============================================================
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/config/settings.conf" 2>/dev/null || true

UI_TOOL="dialog"
command -v whiptail >/dev/null 2>&1 && UI_TOOL="whiptail"

export LANG_FILE="$DIR/lang/${LANGUAGE:-en}.lang"
[ -f "$LANG_FILE" ] || LANG_FILE="$DIR/lang/en.lang"
source "$LANG_FILE" 2>/dev/null || true

TITLE="${T_TITLE:-ISO Launcher - Termux X11}"

menu() {
  while true; do
    CHOICE=$($UI_TOOL --title "$TITLE" --backtitle "Modern QEMU VM Launcher" \
      --menu "${T_MAIN_MENU:-Pilih menu:}" 20 70 12 \
      1 "${T_M_DOWNLOAD:-Download ISO}" \
      2 "${T_M_START:-Start VM}" \
      3 "${T_M_STOP:-Stop VM}" \
      4 "${T_M_MANAGE:-VM Manager (create/list/delete)}" \
      5 "${T_M_MONITOR:-Realtime Monitor}" \
      6 "${T_M_BENCH:-Benchmark Device}" \
      7 "${T_M_AUTOSTART:-Autostart Setting}" \
      8 "${T_M_SETTINGS:-Settings (RAM/CPU/Mode/Lang)}" \
      9 "${T_M_STORAGE:-Storage & Cleanup}" \
      10 "${T_M_LOGS:-View Logs}" \
      0 "${T_M_EXIT:-Exit}" \
      3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && exit 0
    case "$CHOICE" in
      1) bash "$DIR/downloader.sh" ;;
      2) bash "$DIR/start-vm.sh" ;;
      3) bash "$DIR/stop-vm.sh" ;;
      4) bash "$DIR/vm-manager.sh" ;;
      5) bash "$DIR/monitor.sh" ;;
      6) bash "$DIR/vm-manager.sh" benchmark ;;
      7) autostart_menu ;;
      8) settings_menu ;;
      9) storage_menu ;;
      10) less +G "$DIR/logs/launcher.log" 2>/dev/null || echo "No log." ;;
      0) clear; exit 0 ;;
    esac
  done
}

autostart_menu() {
  local rc="$HOME/.bashrc"
  if grep -q "iso-launcher/launcher.sh" "$rc" 2>/dev/null; then
    $UI_TOOL --yesno "Autostart aktif. Nonaktifkan?" 8 50 \
      && sed -i '/# >>> ISO Launcher Autostart >>>/,/# <<< ISO Launcher Autostart <<</d' "$rc"
  else
    $UI_TOOL --yesno "Aktifkan autostart saat Termux dibuka?" 8 50 \
      && { echo -e "\n# >>> ISO Launcher Autostart >>>\n[ -f \"$DIR/launcher.sh\" ] && bash \"$DIR/launcher.sh\"\n# <<< ISO Launcher Autostart <<<" >> "$rc"; }
  fi
}

settings_menu() {
  CFG="$DIR/config/settings.conf"
  mkdir -p "$DIR/config"; touch "$CFG"
  CUR_RAM=$(grep ^RAM= "$CFG" | cut -d= -f2); CUR_RAM=${CUR_RAM:-2048}
  CUR_CPU=$(grep ^CPU= "$CFG" | cut -d= -f2); CUR_CPU=${CUR_CPU:-2}
  CUR_MODE=$(grep ^MODE= "$CFG" | cut -d= -f2); CUR_MODE=${CUR_MODE:-balanced}
  CUR_LANG=$(grep ^LANGUAGE= "$CFG" | cut -d= -f2); CUR_LANG=${CUR_LANG:-en}
  RAM=$($UI_TOOL --inputbox "RAM untuk VM (MB):" 8 50 "$CUR_RAM" 3>&1 1>&2 2>&3) || return
  CPU=$($UI_TOOL --inputbox "CPU cores:" 8 50 "$CUR_CPU" 3>&1 1>&2 2>&3) || return
  MODE=$($UI_TOOL --menu "Mode performa:" 12 50 4 \
     lightweight "Hemat baterai/low-end" \
     balanced "Seimbang" \
     performance "Maksimum" 3>&1 1>&2 2>&3) || return
  LANGV=$($UI_TOOL --menu "Bahasa:" 10 40 3 en "English" id "Bahasa Indonesia" 3>&1 1>&2 2>&3) || return
  cat > "$CFG" <<EOF
RAM=$RAM
CPU=$CPU
MODE=$MODE
LANGUAGE=$LANGV
EOF
  $UI_TOOL --msgbox "Settings tersimpan." 7 40
}

storage_menu() {
  local cache="$DIR/cache" iso="$DIR/iso"
  local s_cache=$(du -sh "$cache" 2>/dev/null | awk '{print $1}')
  local s_iso=$(du -sh "$iso" 2>/dev/null | awk '{print $1}')
  local free=$(df -h "$DIR" | awk 'NR==2{print $4}')
  $UI_TOOL --yesno "Cache: $s_cache\nISO:   $s_iso\nFree:  $free\n\nBersihkan cache?" 12 50 \
    && { rm -rf "$cache"/*; $UI_TOOL --msgbox "Cache dibersihkan." 7 40; }
}

mkdir -p "$DIR/logs"
exec 2>>"$DIR/logs/launcher.log"
menu
