# Oneline Debian Bootstrap

Fresh Debian reinstall bootstrap extracted from `terminal_history_backup.txt`.

Run locally:

```bash
chmod +x install.sh
./install.sh
```

Curl form:

```bash
curl -fsSL https://raw.githubusercontent.com/anorak999/oneline-debian-bootstrap/main/install.sh | bash
```

Skip optional sections:

```bash
INSTALL_AI_CLIS=0 INSTALL_GUI_APPS=1 INSTALL_KERNEL_TOOLS=0 bash install.sh
```

The installer intentionally excludes Noctalia, Snap Telegram, Snap setup, broken duplicate Microsoft .NET APT repo attempts, login/auth commands, and personal repo clones.
