#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  ISO DOWNLOADER - katalog OS + download manager
# ============================================================
DIR="$(cd "$(dirname "$0")" && pwd)"
ISO_DIR="$DIR/iso"
LOG="$DIR/logs/downloader.log"
mkdir -p "$ISO_DIR" "$DIR/logs"

UI="dialog"; command -v whiptail >/dev/null && UI="whiptail"

GREEN='\033[1;32m'; RED='\033[1;31m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; NC='\033[0m'

# ---- Katalog OS (NAME|VERSION|SIZE|RAM|ANDROID_SUPPORT|URL|SHA256) ----
# URL diverifikasi Mei 2026 — berasal dari Internet Archive / mirror resmi distro.
CATALOG=(
# === Windows XP ===
"Windows XP SP3|x86 Pro|0.6GB|512MB|GOOD|https://archive.org/download/WinXPProSP3x86/WinXP%20PRO%20SP3%20ENU.iso|"
# === Windows 7 (via Internet Archive) ===
"Windows 7 Home Premium|x64 SP1|3.8GB|1GB|GOOD|https://archive.org/download/win7homeproultix86x64sp1aug2018/Windows%207%20Home%20Premium%20Build%207601.24214%20x64%20English.iso|"
"Windows 7 Professional|x64 SP1|3.5GB|1GB|GOOD|https://archive.org/download/win7homeproultix86x64sp1aug2018/Windows%207%20Professional%20Build%207601.24214%20x64%20English.iso|"
"Windows 7 Ultimate|x64 SP1|3.5GB|1GB|GOOD|https://archive.org/download/win-7-ultimate-with-sp-1-x-64-dvd-u-676951/X17-59465.iso|"
# === Windows 8 (via Internet Archive) ===
"Windows 8 Pro|x64|3.3GB|1GB|FAIR|https://archive.org/download/Win8ProHPx64/Windows%208%20Pro%20HP%20OEM%20x64.iso|"
# === Windows 8.1 (via Internet Archive) ===
"Windows 8.1 Pro VL|x64 Update1|3.7GB|1GB|FAIR|https://archive.org/download/Win8.1ProUpdate1VLx86x64/en_windows_8.1_professional_vl_with_update_x64_dvd_4065194.iso|"
"Windows 8.1 Pro|x64|3.7GB|1GB|FAIR|https://archive.org/download/Windows_8.1_Pro_x64_ISO/Windows_8.1_Pro_x64.iso|"
# === Windows 10 (via Internet Archive) ===
"Windows 10 1507|x64 RTM|3.8GB|2GB|FAIR|https://archive.org/download/win-10-1507-english-x-64/Win10_1507_English_x64.iso|"
"Windows 10 LTSC 2019|x64|4.3GB|2GB|FAIR|https://archive.org/download/Win10_LTSC2019_x64/Win10_LTSC_2019_x64.iso|"
"Windows 10 LTSC 2021|x64|4.7GB|2GB|FAIR|https://archive.org/download/win-10-ltsc-2021-english-x-64/Win10_LTSC_2021_English_x64.iso|"
"Windows 10 21H2|x64|5.7GB|2GB|FAIR|https://archive.org/download/win-10-21-h-2-english-x-64/Win10_21H2_English_x64.iso|"
"Windows 10 22H2|x64|5.8GB|2GB|FAIR|https://archive.org/download/win-10-22-h2-english-x-64/Win10_22H2_English_x64.iso|"
# === Windows 11 (via Internet Archive) ===
"Windows 11 21H2|x64 RTM|5.1GB|4GB|LIMITED|https://archive.org/download/win-11-english-x-64/Win11_English_x64.iso|"
"Windows 11 22H2|x64|6.1GB|4GB|LIMITED|https://archive.org/download/win-11-22-h2-english-x-64/Win11_22H2_English_x64.iso|"
"Windows 11 23H2|x64|6.3GB|4GB|LIMITED|https://archive.org/download/win-11-23-h2-english-x-64v-2/Win11_23H2_English_x64v2.iso|"
# === Windows Tiny / Modded ===
"Tiny10 (NTDEV)|23H2 x64|3.1GB|2GB|GOOD|https://archive.org/download/tiny-10-23-h2/tiny10%20x64%2023h2.iso|"
"Tiny11 (NTDEV)|x64|3.5GB|3GB|GOOD|https://archive.org/download/tiny-11-NTDEV/tiny11%20b1%20x64.iso|"
# === Ubuntu ===
"Ubuntu 24.04.4 LTS|Desktop amd64|5.9GB|2GB|GOOD|https://releases.ubuntu.com/24.04.4/ubuntu-24.04.4-desktop-amd64.iso|"
"Ubuntu 26.04 LTS|Desktop amd64|5.5GB|2GB|GOOD|https://releases.ubuntu.com/26.04/ubuntu-26.04-desktop-amd64.iso|"
# === Linux Mint ===
"Linux Mint 22.3|Cinnamon amd64|2.8GB|2GB|GOOD|https://mirrors.edge.kernel.org/linuxmint/stable/22.3/linuxmint-22.3-cinnamon-64bit.iso|"
# === Kali Linux ===
"Kali Linux 2026.1|Installer amd64|4.0GB|2GB|GOOD|https://cdimage.kali.org/kali-2026.1/kali-linux-2026.1-installer-amd64.iso|"
# === Debian ===
"Debian 12.11|netinst amd64|0.7GB|1GB|GOOD|https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.11.0-amd64-netinst.iso|"
# === Arch Linux ===
"Arch Linux|latest x86_64|1.4GB|1GB|GOOD|https://mirrors.edge.kernel.org/archlinux/iso/latest/archlinux-x86_64.iso|"
)

show_menu() {
  local items=() i=1
  for row in "${CATALOG[@]}"; do
    IFS='|' read -r name ver size ram sup url sha <<<"$row"
    items+=("$i" "$name ($ver) - $size [RAM $ram, Android: $sup]")
    ((i++))
  done
  items+=("U" "URL ISO Custom")
  items+=("L" "Daftar ISO terdownload")
  items+=("Q" "Kembali")
  $UI --title "ISO Downloader" --menu "Pilih OS:" 25 78 16 "${items[@]}" 3>&1 1>&2 2>&3
}

check_internet() {
  echo -e "${CYAN}[*] Cek koneksi...${NC}"
  if ! curl -s --max-time 5 https://www.google.com -o /dev/null; then
    echo -e "${RED}[X] Tidak ada koneksi internet.${NC}"; return 1
  fi
  echo -e "${GREEN}[OK] Internet OK.${NC}"
}

check_storage() {
  local need_gb="$1"
  local free_mb=$(df -m "$ISO_DIR" | awk 'NR==2{print $4}')
  local need_mb=$(awk "BEGIN{print int($need_gb*1024)}")
  if [ "$free_mb" -lt "$need_mb" ]; then
    echo -e "${RED}[!] Storage kurang. Butuh ~${need_gb}GB, tersedia ${free_mb}MB.${NC}"
    return 1
  fi
}

download_file() {
  local url="$1" out="$2" sha="$3"
  echo -e "${CYAN}[*] Download:${NC} $url"
  echo -e "${CYAN}[*] Tujuan :${NC} $out"
  local tries=0 max=5
  while [ $tries -lt $max ]; do
    if wget --continue --tries=3 --timeout=30 --show-progress -O "$out" "$url"; then
      break
    fi
    tries=$((tries+1))
    echo -e "${YELLOW}[!] Retry $tries/$max dalam 5 detik...${NC}"
    sleep 5
  done
  [ $tries -ge $max ] && { echo -e "${RED}[X] Gagal download.${NC}"; return 1; }
  if [ -n "$sha" ] && command -v sha256sum >/dev/null; then
    echo -e "${CYAN}[*] Verifikasi checksum...${NC}"
    local actual=$(sha256sum "$out" | awk '{print $1}')
    if [ "$actual" = "$sha" ]; then
      echo -e "${GREEN}[OK] Checksum cocok.${NC}"
    else
      echo -e "${RED}[!] Checksum TIDAK cocok.${NC}"
    fi
  fi
  echo -e "${GREEN}[OK] Selesai: $out${NC}"
}

main() {
  local sel; sel=$(show_menu) || exit 0
  case "$sel" in
    Q|"") exit 0 ;;
    L)
      ls -lh "$ISO_DIR" 2>/dev/null | $UI --title "ISO Tersimpan" --programbox 20 70
      ;;
    U)
      URL=$($UI --inputbox "Masukkan URL ISO:" 8 70 "" 3>&1 1>&2 2>&3) || exit 0
      OUT=$($UI --inputbox "Nama file:" 8 60 "custom.iso" 3>&1 1>&2 2>&3) || exit 0
      clear; check_internet || { read -rp "Enter..."; exit 1; }
      download_file "$URL" "$ISO_DIR/$OUT" ""
      read -rp "Tekan Enter..."
      ;;
    *)
      idx=$((sel-1))
      row="${CATALOG[$idx]}"
      IFS='|' read -r name ver size ram sup url sha <<<"$row"
      need_gb=$(echo "$size" | sed 's/GB//')
      clear
      echo -e "${CYAN}== $name ($ver) ==${NC}"
      echo "Ukuran: $size | RAM rec: $ram | Android: $sup"
      check_internet || { read -rp "Enter..."; exit 1; }
      check_storage "$need_gb" || { read -rp "Enter..."; exit 1; }
      fname=$(echo "$name" | tr ' /' '__').iso
      download_file "$url" "$ISO_DIR/$fname" "$sha" | tee -a "$LOG"
      read -rp "Tekan Enter..."
      ;;
  esac
}

main
