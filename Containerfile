FROM quay.io/fedora/fedora-bootc:44

# Estrutura de persistência
RUN mkdir -p /var/roothome /data /var/home /etc/bootc

# Configuração de atualização automática
RUN echo 'image = "ghcr.io/dogo7777/gearos:latest"' > /etc/bootc/config.toml

# Copia arquivos de configuração
COPY logo.png /tmp/logo.png
COPY anaconda-theme.css /tmp/anaconda-theme.css
COPY plasma-org.kde.plasma.desktop-appletsrc /tmp/plasma-appletsrc
COPY AurowaitaDark /tmp/AurowaitaDark
COPY Kvantum /tmp/Kvantum

RUN <<MAINEOF
set -ex

# Ajusta /opt e /usr/local para serem graváveis
rm -rf /opt && mkdir /var/opt && ln -s /var/opt /opt
mkdir -p /var/usrlocal
mv /usr/local /usr/local_old && ln -s /var/usrlocal /usr/local
mv /usr/local_old/* /usr/local/ && rm -rf /usr/local_old

# Instala tema AurowaitaDark globalmente
mkdir -p /usr/share/aurorae/themes
cp -r /tmp/AurowaitaDark /usr/share/aurorae/themes/
rm -rf /tmp/AurowaitaDark

# Kvantum
dnf5 install -y kvantum
mkdir -p /usr/share/Kvantum
cp -r /tmp/Kvantum/Libadwaita-KDE-Default /usr/share/Kvantum/
rm -rf /tmp/Kvantum

# 1. BASE KDE PLASMA com Plasma Login Manager
dnf5 install -y --setopt=install_weak_deps=False \
    plasma-desktop plasma-workspace-wayland \
    plasma-login-manager \
    ptyxis nautilus nautilus-extensions adwaita-icon-theme \
    plasma-nm plasma-pa powerdevil \
    gnome-software \
    xdg-desktop-portal xdg-desktop-portal-kde

# Remove apps padrão do KDE e todo GNOME/GDM
dnf5 remove -y konsole dolphin gdm gnome-shell gnome-session || true

# 2. ÁUDIO
dnf5 install -y --setopt=install_weak_deps=False \
    pipewire pipewire-pulseaudio pipewire-alsa \
    wireplumber

# 3. PACOTES GAMER & DRIVERS
dnf5 install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

dnf5 install -y --setopt=install_weak_deps=False --skip-unavailable \
    gamemode \
    mangohud \
    mesa-vulkan-drivers \
    mesa-va-drivers \
    steam-devices

# 4. UTILITÁRIOS ESSENCIAIS
dnf5 install -y --skip-unavailable \
    @networkmanager-submodules @multimedia \
    compsize usbutils distrobox micro \
    wget tree git fastfetch \
    langpacks-core-pt_BR langpacks-pt_BR papirus-icon-theme langpacks-fonts-pt \
    tuned tuned-ppd htop flatpak flatpak-selinux podman \
    plymouth plymouth-system-theme plymouth-theme-spinner \
    zram-generator \
    zsh ImageMagick procps-ng

# Configura zram
printf '[zram0]\nzram-size = ram / 2\ncompression-algorithm = zstd\n' \
    > /etc/systemd/zram-generator.conf

# 5. KERNEL CACHYOS
dnf5 install -y 'dnf5-command(copr)'
dnf5 copr enable -y bieszczaders/kernel-cachyos
export INITRD=no
dnf5 remove -y kernel kernel-core kernel-modules && dnf5 autoremove -y || true
dnf5 install -y --allowerasing --setopt=install_weak_deps=False \
    kernel-cachyos-modules \
    kernel-cachyos

# 6. OTIMIZAÇÕES DE SISTEMA
mkdir -p /etc/sysctl.d /etc/modprobe.d
printf 'vm.swappiness=10\nvm.max_map_count=2147483642\nnet.core.default_qdisc=fq_pie\n' \
    > /etc/sysctl.d/99-gamer.conf
printf 'blacklist intel_powerclamp\ninstall intel_powerclamp /bin/true\n' \
    > /etc/modprobe.d/blacklist-cpu.conf

# 7. LOGO - Plymouth, PLM, KDE
mkdir -p /usr/share/plymouth/themes/spinner
mkdir -p /usr/share/pixmaps
mkdir -p /usr/share/anaconda/themes

magick /tmp/logo.png -resize 256x256 /usr/share/plymouth/themes/spinner/watermark.png
magick /tmp/logo.png -resize 200x200 /usr/share/pixmaps/system-logo-white.png
magick /tmp/logo.png -resize 128x128 /usr/share/pixmaps/gearos.png
magick /tmp/logo.png -resize 512x512 /usr/share/pixmaps/gearos-full.png

# Tema do Anaconda
cp /tmp/anaconda-theme.css /usr/share/anaconda/themes/gearos.css

# Nome da distro — mantém ID=fedora para compatibilidade com bootc/RPM
sed -i 's|^PRETTY_NAME=.*|PRETTY_NAME="GearOS"|' /etc/os-release
sed -i 's|^NAME=.*|NAME="GearOS"|' /etc/os-release
grep -q '^VARIANT=' /etc/os-release && \
    sed -i 's|^VARIANT=.*|VARIANT="GearOS Edition"|' /etc/os-release || \
    echo 'VARIANT="GearOS Edition"' >> /etc/os-release

# Botões minimizar/maximizar nas apps GTK
mkdir -p /etc/dconf/db/local.d
printf '[org/gnome/desktop/wm/preferences]\nbutton-layout='"'"'appmenu:minimize,maximize,close'"'"'\n' \
    > /etc/dconf/db/local.d/01-gearos

# Ícone Papirus via gschema
printf '[org.gnome.desktop.interface]\nicon-theme='"'"'Papirus'"'"'\n' \
    > /usr/share/glib-2.0/schemas/99-gearos-theme.gschema.override

dconf update || true
glib-compile-schemas /usr/share/glib-2.0/schemas/

# Flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true

rm /tmp/logo.png /tmp/anaconda-theme.css
MAINEOF

# Oh My Zsh + Powerlevel10k + Plugins
RUN git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /usr/share/oh-my-zsh && \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /usr/share/oh-my-zsh/custom/themes/powerlevel10k && \
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions /usr/share/oh-my-zsh/custom/plugins/zsh-autosuggestions && \
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting /usr/share/oh-my-zsh/custom/plugins/zsh-syntax-highlighting

# 8. CONFIGURAÇÃO DE PADRÕES E SERVIÇOS
RUN <<CONFIGEOF
set -ex

# Define Nautilus e Ptyxis como padrão
mkdir -p /etc/xdg
printf '[Default Applications]\ninode/directory=nautilus.desktop\nx-scheme-handler/terminal=org.gnome.Ptyxis.desktop\n' \
    > /etc/xdg/mimeapps.list

# KDE skel
mkdir -p /etc/skel/.config/Kvantum
mkdir -p /etc/skel/.config/qt5ct
mkdir -p /etc/skel/.config/qt6ct
mkdir -p /etc/skel/.config/gtk-3.0
mkdir -p /etc/skel/.config/gtk-4.0

# Kvantum tema
cat > /etc/skel/.config/Kvantum/kvantum.kvconfig << 'KVCONFIG'
[General]
theme=Libadwaita-KDE-DefaultDark
KVCONFIG

# Qt usar Kvantum
cat > /etc/skel/.config/qt5ct/qt5ct.conf << 'QT5'
[Appearance]
style=kvantum
QT5

cat > /etc/skel/.config/qt6ct/qt6ct.conf << 'QT6'
[Appearance]
style=kvantum
QT6

# GTK tema escuro
cat > /etc/skel/.config/gtk-3.0/settings.ini << 'GTK3'
[Settings]
gtk-application-prefer-dark-theme=1
GTK3

cat > /etc/skel/.config/gtk-4.0/settings.ini << 'GTK4'
[Settings]
gtk-application-prefer-dark-theme=1
GTK4

# KDE global - tema escuro + AurowaitaDark + Ptyxis
cat > /etc/skel/.config/kdeglobals << 'KDEGLOBALS'
[General]
TerminalApplication=ptyxis

[KDE]
LookAndFeelPackage=org.kde.breezedark.desktop
ColorScheme=BreezeDark

[org.kde.kdecoration2]
library=org.kde.kwin.aurorae
theme=__aurorae__svg__AurowaitaDark
KDEGLOBALS

# KWin decoração
cat > /etc/skel/.config/kwinrc << 'KWINRC'
[org.kde.kdecoration2]
library=org.kde.kwin.aurorae
theme=__aurorae__svg__AurowaitaDark
KWINRC

# Taskbar
cp /tmp/plasma-appletsrc /etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc

# Kargs do bootc
mkdir -p /usr/lib/bootc/kargs.d
printf 'kargs = ["intel_pstate=active", "mitigations=off", "nowatchdog"]\n' \
    > /usr/lib/bootc/kargs.d/01-otimizacao.toml

# Shell padrão zsh para todos
chsh -s /usr/bin/zsh root
sed -i 's|^SHELL=.*|SHELL=/usr/bin/zsh|' /etc/default/useradd
grep -q '/usr/bin/zsh' /etc/shells || echo '/usr/bin/zsh' >> /etc/shells

# .zshrc com gear CLI + Oh My Zsh + P10k
cat > /etc/skel/.zshrc << 'ZSHRC'
# Cores
c_red='\033[0;31m'; c_green='\033[0;32m'; c_yellow='\033[0;33m'
c_blue='\033[0;34m'; c_magenta='\033[0;35m'; c_cyan='\033[0;36m'
c_text='\033[0;37m'; c_sub='\033[0;90m'; c_alert='\033[1;31m'; c_reset='\033[0m'

# Função gear CLI
gear() {
    local _criar_ecossistema() {
        local distro="$1"
        local box_name="gear-${distro}"
        if ! distrobox list 2>/dev/null | grep -q "$box_name"; then
            echo -e "${c_cyan}::${c_text} Criando ecossistema ${distro}...${c_reset}"
            distrobox create --name "$box_name" --image "${distro}:latest" -Y
        fi
    }

    case "$1" in
        install)
            local pkg="$2"
            if [[ -z "$pkg" ]]; then
                echo -e "${c_alert}Erro: informe o nome do pacote.${c_reset}"
                return 1
            fi
            if [[ -f "$pkg" && "$pkg" == *.deb ]]; then
                local deb_path=$(realpath "$pkg")
                echo -e "\n${c_cyan}::${c_text} .deb detectado! Instalando via Debian...${c_reset}"
                _criar_ecossistema "debian"
                distrobox enter "gear-debian" -- sh -c "sudo apt update && sudo apt install -y \"$deb_path\""
                echo -n -e "${c_yellow}Nome para exportar: ${c_reset}"; read app_name
                [[ -n "$app_name" ]] && distrobox enter "gear-debian" -- distrobox-export --app "$app_name" 2>/dev/null
                return 0
            fi
            echo -e "\n${c_text}Onde instalar '${c_yellow}${pkg}${c_text}'?${c_reset}"
            echo -e "  [1] ${c_cyan}Arch${c_reset} (pacman)  [2] ${c_red}Debian${c_reset} (apt)  [3] ${c_magenta}AUR${c_reset} (yay)"
            echo -n -e "Escolha [1/2/3]: "; read escolha
            if [[ "$escolha" == "1" ]]; then
                _criar_ecossistema "arch"
                distrobox enter "gear-arch" -- sh -c "sudo pacman -Syu --noconfirm $pkg"
                distrobox enter "gear-arch" -- distrobox-export --app "$pkg" 2>/dev/null
            elif [[ "$escolha" == "2" ]]; then
                _criar_ecossistema "debian"
                distrobox enter "gear-debian" -- sh -c "sudo apt update && sudo apt install -y $pkg"
                distrobox enter "gear-debian" -- distrobox-export --app "$pkg" 2>/dev/null
            elif [[ "$escolha" == "3" ]]; then
                _criar_ecossistema "arch"
                distrobox enter "gear-arch" -- sh -c "command -v yay || (git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin && cd /tmp/yay-bin && makepkg -si --noconfirm); yay -S --noconfirm $pkg"
                distrobox enter "gear-arch" -- distrobox-export --app "$pkg" 2>/dev/null
            fi
            ;;
        update)
            echo -e "\n${c_cyan}::${c_text} Atualizando sistema...${c_reset}"
            sudo bootc upgrade && echo -e "${c_green}Pronto! Reinicie para aplicar.${c_reset}"
            ;;
        rollback)
            echo -e "\n${c_cyan}::${c_text} Revertendo...${c_reset}"
            sudo bootc rollback
            ;;
        status)
            sudo bootc status
            ;;
        clean)
            echo -e "\n${c_cyan}::${c_text} Limpando sistema...${c_reset}"
            sudo podman system prune -f
            sudo journalctl --vacuum-time=3d
            echo -e "${c_green}Limpeza concluída!${c_reset}"
            ;;
        menu|"")
            clear
            local os_name=$(grep "^PRETTY_NAME=" /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo "GearOS")
            local kernel_ver=$(uname -r 2>/dev/null || echo "N/A")
            local cpu_name=$(lscpu 2>/dev/null | grep "Model name:" | sed 's/Model name:\s*//' || echo "N/A")
            local ram_total=$(awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo 2>/dev/null || echo "0")
            local ram_avail=$(awk '/MemAvailable/ {printf "%d", $2/1024}' /proc/meminfo 2>/dev/null || echo "0")
            local ram_used=$((ram_total - ram_avail))
            echo -e ""
            echo -e "${c_red}   ___ ___   _   ___ ${c_yellow}  ___  ___ ${c_reset}"
            echo -e "${c_red}  / __| __| /_\ | _ \${c_yellow} / _ \\/ __|${c_reset}"
            echo -e "${c_cyan} | (_ | _| / _ \|   /${c_green}| (_) \\__ \\${c_reset}"
            echo -e "${c_cyan}  \\___|___/_/ \\_\\_|_\\${c_green} \\___/|___/${c_reset}"
            echo -e "${c_magenta}        Immutability Engine${c_reset}"
            echo -e ""
            echo -e " ${c_sub}╭───────────────────────────────────────────╮${c_reset}"
            echo -e " ${c_sub}│${c_text}  Bem-vindo ao seu ecossistema.             ${c_sub}│${c_reset}"
            echo -e " ${c_sub}╰───────────────────────────────────────────╯${c_reset}"
            echo -e " ${c_green}◈ SO:${c_text}      ${os_name}"
            echo -e " ${c_yellow}◈ Kernel:${c_text}  ${kernel_ver}"
            echo -e " ${c_magenta}◈ CPU:${c_text}     ${cpu_name}"
            echo -e " ${c_cyan}◈ RAM:${c_text}     ${ram_used} MB / ${ram_total} MB"
            echo -e " ${c_sub}───────────────────────────────────────────${c_reset}"
            echo -e " ${c_text}Comandos disponíveis:${c_reset}"
            echo -e "  ${c_cyan}gear install ${c_yellow}<app>${c_reset}  Instala apps (Arch/AUR/Debian/.deb)"
            echo -e "  ${c_green}gear update${c_reset}         Atualiza o sistema"
            echo -e "  ${c_red}gear rollback${c_reset}       Reverte para versão anterior"
            echo -e "  ${c_magenta}gear status${c_reset}         Status do bootc"
            echo -e "  ${c_blue}gear clean${c_reset}          Limpeza do sistema"
            echo -e ""
            ;;
        *)
            echo -e "${c_alert}Subcomando desconhecido: $1${c_reset}"
            echo -e "Uso: gear {install|update|rollback|status|clean|menu}"
            ;;
    esac
}

# Histórico
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY

# Oh My Zsh
export ZSH="/usr/share/oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# PATH
export PATH="$HOME/.local/bin:$PATH"

# Powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Autocompletion
autoload -Uz compinit && compinit

# Autostart gear menu em terminais interativos
[[ $- == *i* ]] && gear menu
ZSHRC

# P10k config padrão (evita wizard no primeiro login)
cat > /etc/skel/.p10k.zsh << 'P10KCFG'
# Para reconfigurar execute: p10k configure
POWERLEVEL9K_MODE=nerdfont-v3
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status root_indicator background_jobs time)
POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
P10KCFG

# Habilita serviços
systemctl set-default graphical.target
systemctl enable --force plasmalogin.service
systemctl enable NetworkManager.service
systemctl enable tuned.service
systemctl enable fstrim.timer

rm /tmp/plasma-appletsrc
CONFIGEOF
