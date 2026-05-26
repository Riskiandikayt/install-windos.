#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  STOP VM
# ============================================================
DIR="$(cd "$(dirname "$0")" && pwd)"
VM_DIR="$DIR/vm"

UI="dialog"; command -v whiptail >/dev/null && UI="whiptail"

ACTIVE=()
for d in "$VM_DIR"/*/; do
  [ -f "$d/qemu.pid" ] || continue
  pid=$(cat "$d/qemu.pid")
  if kill -0 "$pid" 2>/dev/null; then
    ACTIVE+=("$(basename "$d")|$pid")
  fi
done

if [ "${#ACTIVE[@]}" -eq 0 ]; then
  echo "Tidak ada VM aktif."
  pkill -f qemu-system-x86_64 2>/dev/null && echo "[*] Force kill QEMU."
  read -rp "Enter..."; exit 0
fi

items=(); i=1
for a in "${ACTIVE[@]}"; do
  IFS='|' read -r n p <<<"$a"
  items+=("$i" "$n (pid $p)")
  ((i++))
done
items+=("A" "Hentikan SEMUA")
sel=$($UI --menu "Pilih VM dihentikan:" 15 50 8 "${items[@]}" 3>&1 1>&2 2>&3) || exit 0

if [ "$sel" = "A" ]; then
  pkill -f qemu-system-x86_64
  echo "[OK] Semua VM dihentikan."
else
  IFS='|' read -r n p <<<"${ACTIVE[$((sel-1))]}"
  kill "$p" 2>/dev/null && echo "[OK] VM $n dihentikan."
fi
read -rp "Enter..."
