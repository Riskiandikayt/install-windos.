#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  VM MANAGER - create/list/delete VM + benchmark
# ============================================================
DIR="$(cd "$(dirname "$0")" && pwd)"
VM_DIR="$DIR/vm"
ISO_DIR="$DIR/iso"
CFG_DIR="$DIR/config"
mkdir -p "$VM_DIR" "$CFG_DIR"

UI="dialog"; command -v whiptail >/dev/null && UI="whiptail"

benchmark() {
  clear
  echo "=== Android Device Benchmark ==="
  local cores=$(nproc)
  local mem_total=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024)}')
  local mem_free=$(grep MemAvailable /proc/meminfo | awk '{print int($2/1024)}')
  local cpu_model=$(grep -m1 "Hardware\|model name" /proc/cpuinfo | cut -d: -f2 | xargs)
  echo "CPU      : $cpu_model"
  echo "Cores    : $cores"
  echo "RAM Tot  : ${mem_total} MB"
  echo "RAM Free : ${mem_free} MB"
  echo
  echo "[*] Quick CPU test (5s)..."
  local start=$(date +%s%N); local n=0
  end=$(( $(date +%s) + 3 ))
  while [ $(date +%s) -lt $end ]; do n=$((n+1)); done
  echo "Loop count(3s): $n"
  echo
  local rec_ram=$((mem_free/2))
  [ $rec_ram -gt 4096 ] && rec_ram=4096
  [ $rec_ram -lt 1024 ] && rec_ram=1024
  local rec_cpu=$((cores>4?4:cores))
  echo "Rekomendasi VM: RAM=${rec_ram}MB  CPU=${rec_cpu}"
  echo "Simpan ke config? [y/N]"
  read -r ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    cat > "$CFG_DIR/settings.conf" <<EOF
RAM=$rec_ram
CPU=$rec_cpu
MODE=balanced
LANGUAGE=${LANGUAGE:-en}
EOF
    echo "[OK] Tersimpan."
  fi
  read -rp "Enter..."
}

create_vm() {
  NAME=$($UI --inputbox "Nama VM (tanpa spasi):" 8 50 "myvm" 3>&1 1>&2 2>&3) || return
  SIZE=$($UI --inputbox "Ukuran virtual disk (GB):" 8 50 "20" 3>&1 1>&2 2>&3) || return
  ISO=$(ls "$ISO_DIR"/*.iso 2>/dev/null | xargs -n1 basename)
  if [ -z "$ISO" ]; then
    $UI --msgbox "Tidak ada ISO. Download dulu." 7 40; return
  fi
  local items=() i=1
  while read -r f; do items+=("$i" "$f"); ((i++)); done <<<"$ISO"
  sel=$($UI --menu "Pilih ISO:" 20 60 12 "${items[@]}" 3>&1 1>&2 2>&3) || return
  iso_name=$(echo "$ISO" | sed -n "${sel}p")
  mkdir -p "$VM_DIR/$NAME"
  qemu-img create -f qcow2 "$VM_DIR/$NAME/disk.qcow2" "${SIZE}G"
  cat > "$VM_DIR/$NAME/vm.conf" <<EOF
NAME=$NAME
ISO=$iso_name
DISK=disk.qcow2
SIZE=${SIZE}G
EOF
  $UI --msgbox "VM '$NAME' dibuat." 7 40
}

list_vm() {
  local out=""
  for d in "$VM_DIR"/*/; do
    [ -d "$d" ] || continue
    out+="$(basename "$d")\n"
  done
  [ -z "$out" ] && out="(belum ada VM)"
  $UI --msgbox "Daftar VM:\n\n$out" 15 50
}

delete_vm() {
  VMS=$(ls "$VM_DIR" 2>/dev/null)
  [ -z "$VMS" ] && { $UI --msgbox "Tidak ada VM." 7 40; return; }
  local items=() i=1
  while read -r v; do items+=("$i" "$v"); ((i++)); done <<<"$VMS"
  sel=$($UI --menu "Pilih VM dihapus:" 15 50 8 "${items[@]}" 3>&1 1>&2 2>&3) || return
  name=$(echo "$VMS" | sed -n "${sel}p")
  $UI --yesno "Hapus VM '$name' permanen?" 7 50 && rm -rf "$VM_DIR/$name"
}

if [ "$1" = "benchmark" ]; then benchmark; exit; fi

while true; do
  C=$($UI --title "VM Manager" --menu "Pilih:" 15 55 6 \
    1 "Buat VM baru" \
    2 "Daftar VM" \
    3 "Hapus VM" \
    4 "Benchmark device" \
    0 "Kembali" 3>&1 1>&2 2>&3) || exit 0
  case "$C" in
    1) create_vm ;;
    2) list_vm ;;
    3) delete_vm ;;
    4) benchmark ;;
    0) exit 0 ;;
  esac
done
