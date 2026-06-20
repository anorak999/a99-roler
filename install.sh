#!/usr/bin/env bash
set -Eeuo pipefail

APP_NAME="Oneline Debian Bootstrap"
LOG_FILE="${LOG_FILE:-$HOME/oneline-install.log}"
INSTALL_AI_CLIS="${INSTALL_AI_CLIS:-1}"
INSTALL_KERNEL_TOOLS="${INSTALL_KERNEL_TOOLS:-1}"
INSTALL_GUI_APPS="${INSTALL_GUI_APPS:-1}"

if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
  echo "This installer needs Bash 4 or newer."
  exit 1
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

STEPS_TOTAL=12
STEP_NO=0

header() {
  clear || true
  printf "${BOLD}${CYAN}"
  cat <<'EOF'
  ____             ___                 ____       _     _
 / __ \___  ___  / (_)__  ___        / __ )___  (_)___/ /
/ / / / _ \/ _ \/ / / _ \/ _ \______/ __  / _ \/ / __  /
/ /_/ /  __/  __/ / /  __/  _______/ /_/ /  __/ / /_/ /
\____/\___/\___/_/_/\___/\___/    /_____/\___/_/\__,_/
EOF
  printf "${RESET}"
  printf "${DIM}Debian reinstall bootstrap with shell and GNOME ricing${RESET}\n"
  printf "${DIM}Log: %s${RESET}\n\n" "$LOG_FILE"
}

progress_bar() {
  local current="$1"
  local total="$2"
  local width=28
  local filled=$(( current * width / total ))
  local empty=$(( width - filled ))
  printf "["
  printf "%${filled}s" "" | tr ' ' '#'
  printf "%${empty}s" "" | tr ' ' '-'
  printf "] %02d/%02d" "$current" "$total"
}

run_step() {
  local title="$1"
  shift
  STEP_NO=$((STEP_NO + 1))
  header
  printf "${BOLD}%s${RESET}\n" "$title"
  progress_bar "$STEP_NO" "$STEPS_TOTAL"
  printf "\n\n"

  local spin='|/-\'
  local i=0
  local status=0
  {
    printf "\n\n### %s\n" "$title"
    "$@"
  } >>"$LOG_FILE" 2>&1 &
  local pid=$!

  while kill -0 "$pid" 2>/dev/null; do
    i=$(((i + 1) % 4))
    printf "\r${MAGENTA}%s${RESET} %s" "${spin:$i:1}" "$title"
    sleep 0.12
  done

  if wait "$pid"; then
    status=0
  else
    status=$?
  fi

  if [ "$status" -ne 0 ]; then
    printf "\r${RED}x${RESET} %s\n\n" "$title"
    printf "${RED}Step failed. Check %s for details.${RESET}\n" "$LOG_FILE"
    exit "$status"
  fi

  printf "\r${GREEN}+${RESET} %s\n" "$title"
  sleep 0.35
}

need_normal_user() {
  if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    echo "Run this as your normal user, not root. The script will use sudo when needed."
    exit 1
  fi
}

require_debian() {
  . /etc/os-release
  if [ "${ID:-}" != "debian" ]; then
    echo "This installer is intended for Debian. Detected: ${PRETTY_NAME:-unknown}"
    exit 1
  fi
}

sudo_keepalive() {
  sudo -v
  while true; do
    sudo -n true
    sleep 45
    kill -0 "$$" || exit
  done 2>/dev/null &
}

apt_install() {
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
}

apt_install_best_effort() {
  local pkg
  for pkg in "$@"; do
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$pkg" || true
  done
}

ensure_line() {
  local line="$1"
  local file="$2"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  grep -Fqx "$line" "$file" || printf "%s\n" "$line" >>"$file"
}

write_zsh_block() {
  local file="$HOME/.zshrc"
  local start="# >>> oneline bootstrap >>>"
  local end="# <<< oneline bootstrap <<<"
  touch "$file"
  awk -v start="$start" -v end="$end" '
    $0 == start {skip=1; next}
    $0 == end {skip=0; next}
    skip != 1 {print}
  ' "$file" >"$file.tmp"
  mv "$file.tmp" "$file"
  cat >>"$file" <<'EOF'
# >>> oneline bootstrap >>>
export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:/usr/local/share/dotnet:$PATH"
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="macos-zsh-theme/macos-theme"

plugins=(
  git
  zoxide
  tmux
  extract
  sudo
  zsh-completions
  k
)

[ -s "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

alias ls="eza --icons --git --group-directories-first"
alias ll="eza -lah --icons --git --group-directories-first"
alias la="eza -a --icons"
alias tree="eza --tree --icons"
alias lS="eza -1 --icons"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias q="exit"
alias c="clear"
alias h="history"
alias path='echo -e ${PATH//:/\n}'
alias ports="sudo ss -tulpn"
alias df="df -h"
alias free="free -m"
alias cat="batcat --style=plain"
alias preview="batcat --style=numbers --color=always"
alias grep="rg"
alias find="fd"
alias top="htop"
alias edit="micro"
alias apt-up="sudo apt-get update && sudo apt-get dist-upgrade -y && sudo apt-get autoremove -y && sudo apt-get clean"
alias apt-in="sudo apt-get install -y"
alias apt-rm="sudo apt-get purge --autoremove -y"
alias apt-se="apt-cache search"
alias dn="dotnet"
alias dnr="dotnet run"
alias dnb="dotnet build"
alias py="python3"
alias venv="python3 -m venv .venv && source .venv/bin/activate"
alias ni="npm install"
alias ns="npm start"
alias nd="npm run dev"
alias myip="curl -s https://ifconfig.me && echo"
alias listen="lsof -i -P -n | grep LISTEN"
alias sha256="shasum -a 256"
alias gs="git status"
alias ga="git add"
alias gaa="git add --all"
alias gc="git commit -m"
alias gp="git push"
alias gl="git log --oneline --graph --decorate"
alias gd="git diff"

source "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" 2>/dev/null || true
source "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" 2>/dev/null || true
eval "$(zoxide init zsh)" 2>/dev/null || true

export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
alias pn="pnpm"
alias pni="pnpm install"
alias pna="pnpm add"
alias pnad="pnpm add -D"
alias pnx="pnpm dlx"
alias pnr="pnpm run"
alias pnb="pnpm run build"
alias pnd="pnpm run dev"
alias pnl="pnpm ls"
alias pnrm="pnpm remove"
alias pnun="pnpm uninstall"
alias pnu="pnpm update"
alias pnwh="pnpm why"
alias b="bun"
alias bi="bun install"
alias ba="bun add"
alias bad="bun add -d"
alias bx="bunx"
alias br="bun run"
alias bd="bun run dev"
alias bb="bun run build"
alias bt="bun test"
alias binit="bun init -y"
alias brm="bun remove"
alias bpm="bun pm"
alias node-clean="rm -rf node_modules pnpm-lock.yaml bun.lockb package-lock.json"
alias pnpmu="pnpm self-update"
alias bunu="bun upgrade"

if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
  alias copy="wl-copy"
  alias paste="wl-paste"
else
  alias copy="xclip -selection clipboard"
  alias paste="xclip -selection clipboard -o"
fi
alias help="tldr"
alias cm="chezmoi"
alias firewall="sudo ufw status numbered"
alias myports="sudo netstat -tulpn | grep LISTEN"
alias scan="ncat -v -z"

export CC=clang
export HOSTCC=clang
export CCACHE_DIR="$HOME/.ccache"
export PATH="/usr/lib/ccache:$PATH"
alias kmake="make -j$(nproc)"
alias kcheck="make C=2 CHECK=sparse"
alias kmenu="make menuconfig"
alias kclean="make mrproper"
alias structsize="pahole -E"
alias klog="sudo dmesg -wH"
alias kmodules="lsmod | sort"
alias kins="sudo insmod"
alias krm="sudo rmmod"
alias cscope-init="find . -name '*.[chXS]' > cscope.files && cscope -b -q -k"
# <<< oneline bootstrap <<<
EOF
}

ensure_git_clone() {
  local url="$1"
  local dest="$2"
  if [ -d "$dest/.git" ]; then
    git -C "$dest" pull --ff-only || true
  elif [ ! -e "$dest" ]; then
    git clone "$url" "$dest"
  fi
}

base_packages() {
  sudo apt-get update
  apt_install \
    apt-transport-https bat ca-certificates curl desktop-file-utils eza fd-find flatpak fzf git \
    gpg htop lsof micro mpv net-tools ripgrep sudo tldr tmux unzip ufw vlc wget wl-clipboard \
    wmctrl x11-utils xclip zoxide zsh celluloid gir1.2-gmenu-3.0 libayatana-appindicator3-1
  apt_install_best_effort ftrace-cmd ncat
}

toolchains() {
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  sudo apt-get update
  apt_install \
    build-essential cpanminus default-jdk default-jre gcc g++ golang-go make nodejs perl \
    php-cli php-pear python3 python3-full python3-pip python3-venv ruby-full rustc cargo luarocks
  sudo npm install -g npm@latest yarn pnpm
  sudo corepack enable || true

  curl -sSL https://get.pnpm.io/install.sh | SHELL="$(command -v zsh)" sh -
  curl -sSL https://bun.com/install | bash

  curl -sSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
  chmod +x /tmp/dotnet-install.sh
  sudo mkdir -p /usr/local/share/dotnet
  sudo /tmp/dotnet-install.sh --channel 8.0 --install-dir /usr/local/share/dotnet
  sudo ln -sf /usr/local/share/dotnet/dotnet /usr/local/bin/dotnet
}

kernel_tools() {
  [ "$INSTALL_KERNEL_TOOLS" = "1" ] || return 0
  sudo apt-get update
  apt_install \
    bc bison ccache cgdb clang cloc cpuid cscope flex libelf-dev libssl-dev llvm msr-tools \
    numactl pahole sparse strace time
  apt_install_best_effort ftrace-cmd
}

shell_rice() {
  mkdir -p "$HOME/.zsh/plugins" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes"

  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi

  ensure_git_clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.zsh/plugins/zsh-syntax-highlighting"
  ensure_git_clone https://github.com/zsh-users/zsh-autosuggestions.git "$HOME/.zsh/plugins/zsh-autosuggestions"
  ensure_git_clone https://github.com/zsh-users/zsh-completions.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions"
  ensure_git_clone https://github.com/supercrabtree/k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/k"
  ensure_git_clone https://github.com/alejandromume/macos-zsh-theme.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/macos-zsh-theme"

  curl -sS https://starship.rs/install.sh | sh -s -- -y || true
  write_zsh_block
  sudo chsh -s "$(command -v zsh)" "$USER" || true
}

external_repos() {
  sudo install -m 0755 -d /etc/apt/keyrings

  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg |
    sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |
    sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null

  wget -qO- https://packages.microsoft.com/keys/microsoft.asc |
    gpg --dearmor |
    sudo tee /etc/apt/keyrings/packages.microsoft.gpg >/dev/null
  echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |
    sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null

  curl -fsSL https://download.docker.com/linux/debian/gpg -o /tmp/docker.asc
  sudo install -m 0644 /tmp/docker.asc /etc/apt/keyrings/docker.asc
  . /etc/os-release
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian ${VERSION_CODENAME} stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt-get update
}

gui_apps() {
  [ "$INSTALL_GUI_APPS" = "1" ] || return 0
  apt_install gh code docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo systemctl enable --now docker.service
  sudo systemctl enable --now containerd.service
  sudo usermod -aG docker "$USER" || true

  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  flatpak install -y flathub org.telegram.desktop
  flatpak override --user --nosocket=fallback-x11 --nosocket=x11 --env=QT_XCB_GL_INTEGRATION=none org.telegram.desktop || true

  curl -f https://zed.dev/install.sh | sh
}

ai_clis() {
  [ "$INSTALL_AI_CLIS" = "1" ] || return 0
  sudo npm install -g @google/gemini-cli
  curl -fsSL https://chatgpt.com/codex/install.sh | sh
  curl -fsSL https://qoder.com/install | bash
  curl -fsSL https://antigravity.google/cli/install.sh | bash
}

gnome_rice() {
  command -v gsettings >/dev/null 2>&1 || return 0

  gsettings set org.gnome.desktop.wm.keybindings help "[]" || true
  gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "[]" || true
  gsettings set org.gnome.desktop.wm.keybindings modifier-toggle "[]" || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys volume-mute "['F1']" || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys volume-down "['F2']" || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys volume-up "['F3']" || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys play "['F4']" || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot "['Print']" || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys logout "['<Ctrl><Alt><Delete>']" || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys logout-static "[]" || true

  gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-customize-running-dots false || true
  gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-shrink true || true

  mkdir -p "$HOME/.config/d2da"
  cat >"$HOME/.config/d2da/style.css" <<'EOF'
.dash2dock-animated-container,
.d2da-icon-container,
#dash2dock-animated .dash-item-container {
  padding: 0px 0px;
  margin: 0px 1px !important;
  spacing: 0px !important;
}
EOF

  gnome-extensions disable dash-to-dock@micxgx.gmail.com 2>/dev/null || true
  gnome-extensions disable dash2dock-lite@icedman.github.com 2>/dev/null || true
  gnome-extensions disable dash2dock-animated@icedman.github.com 2>/dev/null || true
  gnome-extensions enable dash2dock-lite@icedman.github.com 2>/dev/null || true
  gnome-extensions enable dash2dock-animated@icedman.github.com 2>/dev/null || true
}

chezmoi_tldr() {
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
  tldr --update || true
}

verify_install() {
  {
    echo "zsh: $(zsh --version 2>/dev/null || true)"
    echo "node: $(node --version 2>/dev/null || true)"
    echo "npm: $(npm --version 2>/dev/null || true)"
    echo "pnpm: $(pnpm --version 2>/dev/null || true)"
    echo "bun: $(bun --version 2>/dev/null || true)"
    echo "dotnet: $(dotnet --version 2>/dev/null || true)"
    echo "python: $(python3 --version 2>/dev/null || true)"
    echo "docker: $(docker --version 2>/dev/null || true)"
    echo "gh: $(gh --version 2>/dev/null | head -n 1 || true)"
    echo "code: $(code --version 2>/dev/null | head -n 1 || true)"
  } | tee -a "$LOG_FILE"
}

main() {
  : >"$LOG_FILE"
  need_normal_user
  require_debian
  header
  printf "${YELLOW}This will install packages, add APT repos, configure zsh, and apply GNOME settings.${RESET}\n"
  printf "AI CLIs: %s | GUI apps: %s | kernel tools: %s\n\n" "$INSTALL_AI_CLIS" "$INSTALL_GUI_APPS" "$INSTALL_KERNEL_TOOLS"
  read -r -p "Continue? [y/N] " answer
  case "$answer" in
    y|Y|yes|YES) ;;
    *) echo "Cancelled."; exit 0 ;;
  esac

  sudo_keepalive
  run_step "Installing base Debian packages" base_packages
  run_step "Installing language runtimes and package managers" toolchains
  run_step "Installing kernel and tracing tools" kernel_tools
  run_step "Configuring Oh My Zsh and terminal rice" shell_rice
  run_step "Adding GitHub, VS Code, and Docker repositories" external_repos
  run_step "Installing GUI apps and Docker" gui_apps
  run_step "Installing AI coding CLIs" ai_clis
  run_step "Applying GNOME keyboard and dock settings" gnome_rice
  run_step "Installing chezmoi and updating tldr" chezmoi_tldr
  run_step "Verifying installed tools" verify_install
  run_step "Final apt cleanup" sudo apt-get autoremove -y
  run_step "Final apt cache clean" sudo apt-get clean

  header
  printf "${GREEN}${BOLD}Installation complete.${RESET}\n\n"
  printf "Restart or log out/in so zsh, Docker group membership, and GNOME changes fully apply.\n"
  printf "Full log: %s\n" "$LOG_FILE"
}

main "$@"
