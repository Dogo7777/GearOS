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

# Permite que AppImages rodem sem bloqueio do SELinux
setsebool -P domain_can_mmap_files on || true
setsebool -P unprivileged_user_namespace_clone on || true

# Kvantum
dnf5 install -y kvantum
mkdir -p /usr/share/Kvantum
cp -r /tmp/Kvantum/Libadwaita-KDE-Default /usr/share/Kvantum/
rm -rf /tmp/Kvantum

# 1. BASE KDE PLASMA com Plasma Login Manager
dnf5 install -y --setopt=install_weak_deps=False \
    plasma-desktop plasma-workspace-wayland \
    plasma-login-manager \
    ptyxis nautilus fontconfig gnome-software cascadia-fonts-all google-roboto-fonts nautilus-extensions adwaita-icon-theme \
    plasma-nm plasma-pa powerdevil \
    xdg-desktop-portal xdg-desktop-portal-kde

# Remove apps padrão do KDE e todo GNOME/GDM
dnf5 remove -y konsole dolphin gdm gnome-shell gnome-session || true

# 2. ÁUDIO (Completo com suporte a Proton e 32-bits)
dnf5 install -y --setopt=install_weak_deps=False --skip-unavailable \
    pipewire pipewire-pulseaudio wireplumber \
    pipewire-alsa pipewire-alsa.i686 \
    pipewire-jack-audio-connection-kit pipewire-jack-audio-connection-kit.i686 \
    pulseaudio-libs.i686 alsa-lib.i686

# 3. PACOTES GAMER & DRIVERS
dnf5 install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

# Instala CODECS de áudio e vídeo completos (Substituindo as versões limitadas do Fedora)
dnf5 install -y --setopt=install_weak_deps=False --skip-unavailable --allowerasing \
    ffmpeg ffmpeg-libs \
    gstreamer1-plugins-bad-free-extras \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-ugly \
    gstreamer1-libav

# Instala suporte Gamer e Drivers Gráficos
dnf5 install -y --setopt=install_weak_deps=False --skip-unavailable \
    gamemode \
    mangohud mangohud.i686 \
    gamescope \
    mesa-vulkan-drivers mesa-vulkan-drivers.i686 \
    mesa-libGL mesa-libGL.i686 \
    mesa-dri-drivers mesa-dri-drivers.i686 \
    mesa-va-drivers mesa-va-drivers.i686 \
    mesa-vdpau-drivers mesa-vdpau-drivers.i686 \
    vulkan-loader vulkan-loader.i686 \
    vulkan-tools \
    libva-utils \
    steam steam-devices wine

# 4. UTILITÁRIOS ESSENCIAIS
dnf5 install -y --skip-unavailable \
    @networkmanager-submodules @multimedia \
    compsize usbutils distrobox micro \
    wget curl tree git btrfs-progs dosfstools exfatprogs ntfs-3g file \
    fuse fuse-libs fuse3 nautilus-python nautilus-open-any-terminal fuse3-libs squashfs-tools \
    unzip p7zip p7zip-plugins \
    pciutils upower xdg-utils kdeconnect android-tools wine ark nano less \
    langpacks-core-pt_BR google-noto-emoji-color-fonts langpacks-pt_BR papirus-icon-theme langpacks-fonts-pt \
    tuned tuned-ppd htop flatpak flatpak-selinux podman \
    plymouth plymouth-system-theme xorg-x11-server-utils plymouth-theme-spinner \
    zram-generator \
    zsh ImageMagick procps-ng

# Instalar Homebrew (Clonando manualmente para funcionar como root no build)
mkdir -p /home/linuxbrew/.linuxbrew
git clone https://github.com/Homebrew/brew /home/linuxbrew/.linuxbrew/Homebrew
mkdir /home/linuxbrew/.linuxbrew/bin
ln -s ../Homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/
/home/linuxbrew/.linuxbrew/bin/brew update --force
chown -R 1000:1000 /home/linuxbrew
    
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

# Tema do Anaconda (Sobrescreve o tema padrão para o instalador aplicar)
mkdir -p /usr/share/anaconda/themes/default
cp /tmp/anaconda-theme.css /usr/share/anaconda/themes/default/anaconda.css

# Nome da distro — mantém ID=fedora para compatibilidade com bootc/RPM
sed -i 's|^PRETTY_NAME=.*|PRETTY_NAME="GearOS"|' /etc/os-release
sed -i 's|^NAME=.*|NAME="GearOS"|' /etc/os-release
grep -q '^VARIANT=' /etc/os-release && \
    sed -i 's|^VARIANT=.*|VARIANT="GearOS Edition"|' /etc/os-release || \
    echo 'VARIANT="GearOS Edition"' >> /etc/os-release

# ADIÇÃO 1: Aponta a logo do KDE Info Center para a nossa logo
grep -q '^LOGO=' /etc/os-release && sed -i 's|^LOGO=.*|LOGO=/usr/share/pixmaps/gearos.png|' /etc/os-release || echo 'LOGO=/usr/share/pixmaps/gearos.png' >> /etc/os-release

# ADIÇÃO 2: Muda o nome exibido no menu do GRUB de "Fedora" para "GearOS"
if [ -f /etc/default/grub ]; then
    sed -i 's|^GRUB_DISTRIBUTOR=.*|GRUB_DISTRIBUTOR="GearOS"|' /etc/default/grub
else
    echo 'GRUB_DISTRIBUTOR="GearOS"' > /etc/default/grub
fi

# Botões minimizar/maximizar nas apps GTK
mkdir -p /etc/dconf/db/local.d
printf '[org/gnome/desktop/wm/preferences]\nbutton-layout='"'"'appmenu:minimize,maximize,close'"'"'\n' \
    > /etc/dconf/db/local.d/01-gearos

# Ícone Papirus via gschema
printf '[org.gnome.desktop.interface]\nicon-theme='"'"'Papirus'"'"'\n' \
    > /usr/share/glib-2.0/schemas/99-gearos-theme.gschema.override
    
# Configura a extensão do Nautilus para usar o Ptyxis ao clicar com o botão direito
echo -e "[com.github.stunkymonkey.nautilus-open-any-terminal]\nterminal='ptyxis'" > /usr/share/glib-2.0/schemas/99-gearos-nautilus-ptyxis.gschema.override && \
    glib-compile-schemas /usr/share/glib-2.0/schemas/
    
mkdir -p /etc/skel/.config/dconf/user.d
cat > /etc/skel/.config/dconf/user.d/01-ptyxis << 'DCONF'
[org/gnome/Ptyxis]
font-name='MesloLGS NF 12'
DCONF

dconf update || true
glib-compile-schemas /usr/share/glib-2.0/schemas/

# Flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true

# Fonte MesloLGS NF para Powerlevel10k
mkdir -p /usr/share/fonts/MesloLGS
curl -fLo /usr/share/fonts/MesloLGS/MesloLGS-NF-Regular.ttf \
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
curl -fLo /usr/share/fonts/MesloLGS/MesloLGS-NF-Bold.ttf \
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf"
curl -fLo /usr/share/fonts/MesloLGS/MesloLGS-NF-Italic.ttf \
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf"
curl -fLo /usr/share/fonts/MesloLGS/MesloLGS-NF-Bold-Italic.ttf \
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf"
fc-cache -fv

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

systemctl enable bootc-update.timer || true

# ==========================================
# OTIMIZAÇÃO DE MONTAGEM (Noatime + Btrfs Tuning)
# ==========================================

# Ignora a remontagem da raiz pelo systemd (O bootc já cuida disso e monta como Read-Only)
# Isso previne o erro "overlay: No changes allowed in reconfigure" no boot
systemctl mask systemd-remount-fs.service

# Boot (/boot)
mkdir -p /etc/systemd/system/boot.mount.d
cat > /etc/systemd/system/boot.mount.d/noatime.conf << 'MOUNT2'
[Mount]
Options=noatime
MOUNT2

# Home (/home)
mkdir -p /etc/systemd/system-home.mount.d
cat > /etc/systemd/system-home.mount.d/compress.conf << 'MOUNT3'
[Mount]
Options=noatime,ssd,discard=async,space_cache=v2,compress=zstd:1
MOUNT3

# Define Nautilus e Ptyxis como padrão
mkdir -p /etc/xdg
printf '[Default Applications]\ninode/directory=nautilus.desktop\nx-scheme-handler/terminal=org.gnome.Ptyxis.desktop\n' \
    > /etc/xdg/mimeapps.list
    
cat > /etc/skel/.config/kdeglobals << 'KDEGLOBALS'
[General]
TerminalApplication=ptyxis
font=Roboto,10,-1,5,50,0,0,0,0,0
fixed=Hack,10,-1,5,50,0,0,0,0,0
smallestReadableFont=Roboto,8,-1,5,50,0,0,0,0,0
toolBarFont=Roboto,10,-1,5,50,0,0,0,0,0
menuFont=Roboto,10,-1,5,50,0,0,0,0,0

[KDE]
LookAndFeelPackage=org.kde.breezedark.desktop
ColorScheme=BreezeDark

[org.kde.kdecoration2]
library=org.kde.kwin.aurorae
theme=__aurorae__svg__AurowaitaDark
KDEGLOBALS

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
gtk-decoration-layout=menu:minimize,maximize,close
GTK3

cat > /etc/skel/.config/gtk-4.0/settings.ini << 'GTK4'
[Settings]
gtk-application-prefer-dark-theme=1
gtk-decoration-layout=menu:minimize,maximize,close
GTK4

# KWin decoração
cat > /etc/skel/.config/kwinrc << 'KWINRC'
[org.kde.kdecoration2]
library=org.kde.kwin.aurorae
theme=__aurorae__svg__AurowaitaDark

[Windows]
BorderlessMaximizedWindows=false
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

# .zshrc com gear CLI + Oh My Zsh + P10k (NAO MEXIDO, CONFORME PEDIDO)
cat > /etc/skel/.zshrc << 'ZSHRC'
# Cores
c_red='\033[0;31m'; c_green='\033[0;32m'; c_yellow='\033[0;33m'
c_blue='\033[0;34m'; c_magenta='\033[0;35m'; c_cyan='\033[0;36m'
c_text='\033[0;37m'; c_sub='\033[0;90m'; c_alert='\033[1;31m'; c_reset='\033[0m'

gear() {
    # Paleta de cores
    local c_red="\e[38;5;196m"
    local c_green="\e[38;5;82m"
    local c_yellow="\e[38;5;220m"
    local c_blue="\e[38;5;33m"
    local c_magenta="\e[38;5;198m"
    local c_cyan="\e[38;5;38m"
    local c_text="\e[1;37m"
    local c_sub="\e[38;5;245m"
    local c_alert="\e[38;5;196m"
    local c_reset="\e[0m"

    # Função interna: Criar ecossistema
    _criar_ecossistema() {
        local distro="$1"
        local box_name="gear-${distro}"
        
        if ! distrobox list 2>/dev/null | grep -q "$box_name"; then
            echo -e "${c_cyan}::${c_text} Criando ecossistema ${distro}...${c_reset}"
            distrobox create --name "$box_name" --image "${distro}:latest" -Y
            
            if [[ "$distro" == "archlinux" ]]; then
                echo -e "${c_cyan}::${c_text} Habilitando Multilib e instalando base-devel/git no Arch...${c_reset}"
                distrobox enter "$box_name" -- sh -c "sudo sed -i '/^#\[multilib\]/,/^#Include/{s/^#//}' /etc/pacman.conf && sudo pacman -Syu --noconfirm base-devel git wget curl nano unzip"
            
            elif [[ "$distro" == "debian" ]]; then
                echo -e "${c_cyan}::${c_text} Atualizando e instalando dependências no Debian...${c_reset}"
                distrobox enter "$box_name" -- sh -c "sudo apt update && sudo apt install -y build-essential git wget curl nano unzip software-properties-common apt-transport-https"
            fi
        fi
    }

    # Função interna: Exportar App e LIMPAR o sufixo chato
    _exportar_app() {
        local box_name="$1"
        local app_name="$2"
        local distro_name="$3"
        
        distrobox enter "$box_name" -- distrobox-export --app "$app_name" 2>/dev/null
        
        local desktop_file
        desktop_file=$(find ~/.local/share/applications -name "*${app_name}*" -type f 2>/dev/null | head -n 1)
        
        if [[ -n "$desktop_file" ]]; then
            sed -i "s/ (gear-${distro_name})//g" "$desktop_file"
            echo -e "${c_green}Atalho integrado ao sistema com sucesso!${c_reset}"
        fi
    }

    case "$1" in
        install)
            local pkg="$2"
            if [[ -z "$pkg" ]]; then
                echo -e "${c_alert}Erro: informe o nome do pacote ou arquivo .deb.${c_reset}"
                return 1
            fi

            if [[ -f "$pkg" && "$pkg" == *.deb ]]; then
                local deb_path=$(realpath "$pkg")
                echo -e "\n${c_cyan}::${c_text} .deb detectado! Instalando via Debian...${c_reset}"
                _criar_ecossistema "debian"
                distrobox enter "gear-debian" -- sh -c "sudo apt update && sudo apt install -y \"$deb_path\""
                
                echo -n -e "${c_yellow}Nome do aplicativo para exportar (Ex: discord): ${c_reset}"
                read app_name
                
                if [[ -n "$app_name" ]]; then
                    _exportar_app "gear-debian" "$app_name" "debian"
                fi
                return 0
            fi

            echo -e "\n${c_text}Onde instalar '${c_yellow}${pkg}${c_text}'?${c_reset}"
            echo -e "  [1] ${c_cyan}Arch Linux${c_reset} (pacman + multilib)"
            echo -e "  [2] ${c_red}Debian${c_reset}     (apt)"
            echo -e "  [3] ${c_magenta}Arch AUR${c_reset}   (yay)"
            echo -n -e "Escolha [1/2/3]: "
            read escolha

            if [[ "$escolha" == "1" ]]; then
                _criar_ecossistema "archlinux"
                distrobox enter "gear-archlinux" -- sh -c "sudo pacman -S --noconfirm $pkg"
                _exportar_app "gear-archlinux" "$pkg" "archlinux"
                
            elif [[ "$escolha" == "2" ]]; then
                _criar_ecossistema "debian"
                distrobox enter "gear-debian" -- sh -c "sudo apt update && sudo apt install -y $pkg"
                _exportar_app "gear-debian" "$pkg" "debian"
                
            elif [[ "$escolha" == "3" ]]; then
                _criar_ecossistema "archlinux"
                distrobox enter "gear-archlinux" -- sh -c "command -v yay &>/dev/null || (git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin && cd /tmp/yay-bin && makepkg -si --noconfirm && rm -rf /tmp/yay-bin); yay -S --noconfirm $pkg"
                _exportar_app "gear-archlinux" "$pkg" "archlinux"
            else
                echo -e "${c_alert}Opção inválida.${c_reset}"
            fi
            ;;
            
        update)
            echo -e "\n${c_cyan}::${c_text} Verificando atualizações do sistema (bootc)...${c_reset}"
            if sudo bootc upgrade; then
                echo -e "${c_green}Pronto! Reinicie para aplicar (ou use gear rollback para voltar).${c_reset}"
            else
                echo -e "${c_alert}Falha no upgrade. Se o repositório for privado, configure /etc/ostree/auth.json${c_reset}"
            fi
            ;;
            
        rollback)
            echo -e "\n${c_cyan}::${c_text} Revertendo para a versão anterior...${c_reset}"
            sudo bootc rollback
            ;;
            
        status)
            sudo bootc status
            ;;
            
        clean)
            echo -e "\n${c_cyan}::${c_text} Manutenção e Limpeza do Sistema...${c_reset}"
            sudo podman system prune -f
            sudo journalctl --vacuum-time=3d
            echo -e "${c_green}Limpeza concluída com sucesso!${c_reset}"
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
            echo -e " ${c_sub}╭───────────────────────────────────────────╮${c_reset}"
            echo -e " ${c_sub}│${c_text}  Bem-vindo ao seu ecossistema.             ${c_sub}│${c_reset}"
            echo -e " ${c_sub}╰───────────────────────────────────────────╯${c_reset}"
            echo -e " ${c_cyan}◈ SO:${c_text}      ${os_name}"
            echo -e " ${c_cyan}◈ Kernel:${c_text}  ${kernel_ver}"
            echo -e " ${c_cyan}◈ CPU:${c_text}     ${cpu_name}"
            echo -e " ${c_cyan}◈ RAM:${c_text}     ${ram_used} MB / ${ram_total} MB"
            echo -e " ${c_sub}───────────────────────────────────────────${c_reset}"
            echo -e " ${c_text}Gerenciador Nativo (CLI):${c_reset}"
            echo -e "  ${c_cyan}gear install ${c_yellow}<app>${c_reset}  Instala apps isolados (Arch/AUR/Debian/.deb)"
            echo -e "  ${c_cyan}gear update${c_reset}         Aplica a imagem OS mais recente"
            echo -e "  ${c_cyan}gear rollback${c_reset}       Reverte para a imagem anterior"
            echo -e "  ${c_cyan}gear status${c_reset}         Inspeciona a árvore do bootc"
            echo -e "  ${c_cyan}gear clean${c_reset}          Manutenção e otimização de disco"
            echo -e ""
            ;;
            
        *)
            echo -e "${c_alert}Erro: Subcomando desconhecido ('$1')${c_reset}"
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

# Homebrew Config
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

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

systemctl enable bootc-update.timer || true 
rm /tmp/plasma-appletsrc
CONFIGEOF
