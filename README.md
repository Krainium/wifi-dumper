# 📡 wifi-dumper

Scans your system for saved Wi-Fi passwords. Runs on Windows, Linux, Mac. No installs. One click.

## 🎯 What It Does

Reads every saved Wi-Fi network on your machine. Pulls the network name. Pulls the password. Writes everything to a plain text file called `saved.txt` in the same folder you run it from.

## 📁 Files

| File | System |
|------|--------|
| `wifi-passwords.bat` | Windows |
| `wifi-passwords.sh` | Linux / macOS |

## 💻 Requirements

**Windows**
- Windows 7, 8, 10 or 11
- No installs needed

**Linux**
- NetworkManager or wpa_supplicant
- bash

**macOS**
- macOS 10.12 or later
- bash

## ▶️ How to Run

**Windows** — double-click `wifi-passwords.bat`. Done.

**Linux**
```bash
bash wifi-passwords.sh
```

**macOS**
```bash
bash wifi-passwords.sh
```

## 📄 Output

Results go to `saved.txt` in the same folder. Each entry shows the network name with its password. Open it in any text editor.

## 📝 Notes

**Linux** — if nothing shows up run it with sudo:
```bash
sudo bash wifi-passwords.sh
```

**macOS** — your system may ask for keychain permission when it reads each network. That prompt is from macOS itself.

**Windows** — if some networks show no password try right-clicking the file and choosing Run as Administrator.
