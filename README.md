# a99-roler

Run locally:

```bash
chmod +x install.sh
./install.sh
```

Curl form:

```bash
curl -fsSL https://raw.githubusercontent.com/anorak999/a99-roler/main/install.sh | bash
```

What the installer sets up:

- Base tools: `zsh`, `git`, `curl`, `wget`, `flatpak`, `fzf`, `zoxide`, `eza`, `bat`, `ripgrep`, `fd-find`, `tmux`, `micro`, `htop`, `tldr`, clipboard tools, network tools, and media players.
- Desktop apps: Telegram Desktop through Flatpak, Visual Studio Code, Zed, GitHub CLI, Docker Engine, Docker Compose plugin, VLC, MPV, and Celluloid.
- Development runtimes: Node.js 22, npm, pnpm, Bun, Python 3, Java, Go, Rust/Cargo, PHP, Ruby, Perl, LuaRocks, and .NET 8.
- Shell setup: Oh My Zsh, macOS-style zsh theme, zsh syntax highlighting, autosuggestions, completions, modern aliases, PATH setup, and zsh as the default shell.
- GNOME ricing: media key bindings, screenshot/logout bindings, F11/help conflict cleanup, Dash-to-Dock settings when available, and Dash2Dock Animated styling.
- Optional AI CLIs: Gemini CLI, Codex CLI, Qoder, and Google Antigravity CLI.
- Optional kernel/dev tools: Clang, LLVM, ccache, sparse, pahole, cscope, strace, msr-tools, and related low-level development utilities.

Skip optional sections:

```bash
INSTALL_AI_CLIS=0 INSTALL_GUI_APPS=1 INSTALL_KERNEL_TOOLS=0 bash install.sh
```
