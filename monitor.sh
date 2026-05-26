#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  REALTIME MONITOR - CPU/RAM/Storage/QEMU
# ============================================================
DIR="$(cd "$(dirname "$0")" && pwd)"
VM_DIR="$DIR/vm"

trap 'clear; exit 0' INT

spinner=('|' '/' '-' '\')
si=0

while true; do
  clear
  echo -e "\033[1;36m=========================================================="
  echo -e "  ISO LAUNCHER MONITOR  ${spinner[$si]}"
  echo -e "==========================================================\033[0m"
  si=$(((si+1)%4))

  # CPU
  if [ -r /proc/stat ]; then
    read cpu a b c idle rest < /proc/stat
    total=$((a+b+c+idle))
    used=$((a+b+c))
    echo -e "\033[1;33mCPU usage proxy:\033[0m used=$used total=$total cores=$(nproc)"
  fi

  # RAM
  if [ -r /proc/meminfo ]; then
    total=$(awk '/MemTotal/{print $2}' /proc/meminfo)
    avail=$(awk '/MemAvailable/{print $2}' /proc/meminfo)
    used=$((total-avail))
    pct=$((used*100/total))
    echo -e "\033[1;33mRAM:\033[0m ${used}KB / ${total}KB  (${pct}%)"
  fi

  # Storage
  echo -e "\033[1;33mStorage:\033[0m"
  df -h "$DIR" | awk 'NR==2{print "  Free: "$4"  Used: "$3"  Total: "$2}'

  # Temperatur
  for z in /sys/class/thermal/thermal_zone*/temp; do
    [ -r "$z" ] || continue
    t=$(cat "$z" 2>/dev/null)
    [ -n "$t" ] && echo -e "\033[1;33mTemp:\033[0m $((t/1000))°C  ($(dirname $z | xargs basename))"
    break
  done

  # QEMU status
  echo -e "\033[1;36m----- QEMU VM -----\033[0m"
  found=0
  for d in "$VM_DIR"/*/; do
    [ -f "$d/qemu.pid" ] || continue
    pid=$(cat "$d/qemu.pid")
    if kill -0 "$pid" 2>/dev/null; then
      name=$(basename "$d")
      start=$(stat -c %Y "$d/qemu.pid")
      now=$(date +%s)
      up=$((now-start))
      echo "  [RUNNING] $name (pid=$pid, uptime=${up}s)"
      found=1
    fi
  done
  [ $found -eq 0 ] && echo "  (tidak ada VM aktif)"

  echo
  echo -e "\033[2mCtrl+C untuk keluar. Refresh tiap 2 detik.\033[0m"
  sleep 2
done
