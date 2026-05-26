#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  START VM - Jalankan QEMU + Termux:X11
# ============================================================
DIR="$(cd "$(dirname "$0")" && pwd)"
VM_DIR="$DIR/vm"
CFG="$DIR/config/settings.conf"
LOG="$DIR/logs/vm.log"
mkdir -p "$DIR/logs"

source "$CFG" 2>/dev/null || true
RAM="${RAM:-2048}"; CPU="${CPU:-2}"; MODE="${MODE:-balanced}"

UI="dialog"; command -v whiptail >/dev/null && UI="whiptail"

VMS=$(ls "$VM_DIR" 2>/dev/null)
if [ -z "$VMS" ]; then
  echo "[X] Belum ada VM. Buat lewat VM Manager dulu."
  read -rp "Enter..."; exit 1
fi

items=(); i=1
while read -r v; do items+=("$i" "$v"); ((i++)); done <<<"$VMS"
sel=$($UI --menu "Pilih VM untuk dijalankan:" 18 60 10 "${items[@]}" 3>&1 1>&2 2>&3) || exit 0
name=$(echo "$VMS" | sed -n "${sel}p")
VM_PATH="$VM_DIR/$name"
source "$VM_PATH/vm.conf"

ISO_PATH="$DIR/iso/$ISO"
DISK_PATH="$VM_PATH/$DISK"

# Mode tuning
case "$MODE" in
  lightweight) EXTRA="-vga std" ;;
  performance) EXTRA="-vga virtio -device virtio-net,netdev=n0" ;;
  *)           EXTRA="-vga std" ;;
esac

# === Termux:X11 setup ===
export DISPLAY=:0
export PULSE_SERVER=127.0.0.1

echo "[*] Menjalankan Termux:X11..."
pkill -f "termux-x11 :0" 2>/dev/null
termux-x11 :0 >/dev/null 2>&1 &
sleep 2

echo "[*] Menjalankan PulseAudio..."
pulseaudio --start --exit-idle-time=-1 --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" >/dev/null 2>&1 || true

# Buka aplikasi Termux:X11 (Android)
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || true

echo "[*] Starting QEMU: $name"
echo "    RAM=$RAM MB | CPU=$CPU | MODE=$MODE"
echo "    ISO=$ISO"
echo "    DISK=$DISK_PATH"

echo "$(date) START $name" >> "$LOG"

QEMU_PIDFILE="$VM_PATH/qemu.pid"

qemu-system-x86_64 \
  -name "$name" \
  -machine pc,accel=tcg \
  -cpu qemu64 \
  -smp "$CPU" \
  -m "$RAM" \
  -hda "$DISK_PATH" \
  -cdrom "$ISO_PATH" \
  -boot menu=on \
  -netdev user,id=n0 \
  -device rtl8139,netdev=n0 \
  -audiodev pa,id=snd0,server=127.0.0.1 \
  -device AC97,audiodev=snd0 \
  -usb -device usb-tablet \
  -display sdl,gl=on \
  -pidfile "$QEMU_PIDFILE" \
  $EXTRA 2>>"$LOG"

echo "$(date) STOP $name" >> "$LOG"
echo "[*] VM dihentikan."
read -rp "Enter..."
