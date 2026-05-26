# ISO Launcher & Downloader for Termux X11

Launcher modern untuk Android (Termux + Termux:X11) yang bisa **mendownload ISO** dan **menjalankan VM Windows/Linux** lewat QEMU dengan UI terminal interaktif (dialog/whiptail).

> ⚠️ Performa VM di Android sepenuhnya tergantung hardware HP. QEMU pada Android berjalan **tanpa KVM** (TCG), jadi gunakan distro ringan (Tiny10/Tiny11, XP, Debian minimal, Arch) untuk pengalaman terbaik.

---

## ✨ Fitur

- 📥 **ISO Downloader otomatis** untuk Windows XP / 7 / 8 / 10 / 11 / Tiny10 / Tiny11 / Ubuntu / Mint / Kali / Debian / Arch
- 📊 Download manager: progress bar, resume, retry, checksum
- 💾 Smart storage manager (cek free space, cleanup cache)
- 🛠️ Auto VM configurator (RAM/CPU otomatis sesuai device)
- 🚀 QEMU launcher (start/stop/restart)
- 📈 Realtime monitor (CPU/RAM/Storage/Temp/QEMU uptime)
- ⏯️ Autostart on Termux launch (opsional)
- 🎨 Modern terminal UI (whiptail/dialog, warna, spinner)
- 🖥️ Termux:X11 integration (mouse, keyboard, audio, OpenGL via virglrenderer)
- 🌐 Multi-language (EN/ID)
- ⚙️ Mode: lightweight / balanced / performance
- 🧪 Benchmark device + rekomendasi setting

---

## 📂 Struktur Project

```
iso-launcher/
├── install.sh        # installer dependency + setup
├── launcher.sh       # menu utama
├── downloader.sh     # katalog & download ISO
├── vm-manager.sh     # create/list/delete VM + benchmark
├── start-vm.sh       # jalankan QEMU + X11 + Pulse
├── stop-vm.sh        # hentikan VM
├── monitor.sh        # realtime monitor
├── config/           # settings.conf
├── iso/              # file ISO yang didownload
├── vm/               # disk + config VM
├── cache/            # cache download
├── logs/             # log
├── lang/             # en.lang, id.lang
└── README.md
```

---

## 🚀 Instalasi

Di **Termux** (Android):

```bash
pkg update -y && pkg install -y wget unzip
# Ekstrak zip ini ke $HOME
unzip iso-launcher.zip -d $HOME
cd $HOME/iso-launcher
bash install.sh
```

Installer akan:
1. Update Termux
2. Install `qemu-system-x86-64`, `pulseaudio`, `wget`, `curl`, `git`, `dialog`, `termux-x11-nightly`, `virglrenderer-android`, `mesa`
3. Setup struktur folder
4. Menawarkan autostart

> Pastikan aplikasi **Termux:X11** APK terinstall:
> https://github.com/termux/termux-x11

---

## ▶️ Menjalankan

```bash
bash $HOME/iso-launcher/launcher.sh
```

### Alur pemakaian:
1. **Download ISO** → pilih OS dari katalog
2. **VM Manager → Buat VM** → tentukan nama + ukuran disk + pilih ISO
3. **Start VM** → otomatis nyalakan Termux:X11 + PulseAudio + QEMU
4. Buka aplikasi **Termux:X11** untuk melihat layar VM
5. **Monitor** untuk pantau resource realtime

---

## 🧠 Tips Performa

- Pakai distro ringan: **Tiny10/Tiny11**, **Debian netinst**, **Arch**
- Mode `lightweight` untuk HP low-end
- Tutup aplikasi background, aktifkan **Termux:Wake-lock**
- Gunakan ISO < 4GB jika RAM HP < 4GB
- Aktifkan virglrenderer untuk akselerasi OpenGL

---

## 🛟 Troubleshooting

| Masalah | Solusi |
|---|---|
| `qemu-system-x86_64: command not found` | Jalankan `pkg install qemu-system-x86-64` |
| Layar Termux:X11 hitam | Pastikan APK Termux:X11 terbuka sebelum start VM |
| Audio tidak keluar | Cek `pulseaudio --check -v`; restart pulse |
| Download error | Cek koneksi, retry. Beberapa mirror perlu URL custom |
| VM sangat lambat | Wajar—Android tidak punya KVM. Gunakan ISO ringan |
| Storage kurang | Menu **Storage & Cleanup** atau hapus ISO lama |

Log tersimpan di `logs/launcher.log`, `logs/vm.log`, `logs/downloader.log`.

---

## ⚖️ Disclaimer

Project ini hanyalah **launcher**. URL ISO dalam katalog adalah placeholder umum (Internet Archive / mirror resmi distro Linux). Untuk Windows, **gunakan ISO resmi Microsoft** atau mirror sah milik Anda. Penulis tidak bertanggung jawab atas penggunaan ilegal.

---

## 📜 Lisensi

MIT
