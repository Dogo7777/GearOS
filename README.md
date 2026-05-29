# ⚙️ GearOS

![GearOS Banner](https://img.shields.io/badge/OS-GearOS-FF8C00?style=for-the-badge&logo=linux&logoColor=white)
![Base](https://img.shields.io/badge/Base-Fedora_Bootc-294172?style=for-the-badge&logo=fedora&logoColor=white)
![Desktop Environment](https://img.shields.io/badge/KDE_Plasma-Wayland-1D99F3?style=for-the-badge&logo=kde&logoColor=white)

O **GearOS** é uma distribuição Linux imutável e de alto desempenho, baseada na tecnologia Fedora `bootc`. Foi desenhada para oferecer uma experiência "inquebrável" na raiz do sistema, transferindo a instalação de aplicações e ferramentas de desenvolvimento para ecossistemas de contentores isolados (Distrobox e Podman) e gestores de pacotes em espaço de utilizador.

Perfeito para *mim*.

---

## ✨ Características Principais

*  **Totalmente Limpo (Zero Bloatware):** O sistema vem apenas com o essencial. Sem pacotes inúteis, telemetria excessiva, ou softwares pré-instalados que consomem memória em segundo plano. O desempenho e o espaço em disco são totalmente seus.
*  **Raiz Imutável (OSTree/Bootc):** O sistema operativo central é atualizado de forma atómica. Se uma atualização falhar, pode simplesmente reverter (rollback) para o estado anterior.
*  **Homebrew Nativo:** Ferramentas de linha de comandos à distância de um clique. O gestor de pacotes **Homebrew** está totalmente integrado no sistema. Pode instalar milhares de pacotes utilitários nativamente, sem alterar a raiz imutável e sem precisar de permissões de administrador (`sudo`).
*  **Ecossistema de Contentores:** Não suje o seu sistema anfitrião. Instale qualquer software gráfico através do Arch Linux (AUR) ou Debian de forma transparente e invisível usando o Distrobox.
*  **Pronto para Gaming:** * Drivers Mesa, Vulkan e suporte a 32-bits (`.i686`) pré-instalados.
  * Otimizações nativas: `gamemode`, `gamescope` e `mangohud`.
  * Áudio Pipewire de baixa latência (compatível com jogos clássicos e Proton).
  * Repositórios RPM Fusion ativados de fábrica com codecs completos (H.264, HEVC, etc.).
*  **Interface de Nível Premium:** * KDE Plasma (Wayland) otimizado com o gestor de sessão SDDM.
  * Decorações de janela **[Aurowaita](https://github.com/sabaneko-run/Aurowaita)** ativadas de fábrica (cantos perfeitamente arredondados, estética macOS/GNOME moderno).
  * Tema de ícones Papirus e integração nativa do terminal Ptyxis diretamente no menu de contexto do Nautilus.
*  **Terminal com Superpoderes:** Zsh como *shell* padrão, artilhado com Oh My Zsh, Powerlevel10k (Fonte MesloLGS NF) e realce de sintaxe.

---

## 🛠️ O Gestor Nativo: `gear` CLI

O coração do sistema é o comando `gear`, uma interface de linha de comandos desenvolvida especificamente para facilitar a gestão da imutabilidade e a instalação de software sem complicações.

Ao abrir o terminal, é recebido pelo **Painel GearOS**. A partir daí, pode usar:

### `gear install <pacote>`
Instala aplicações num ecossistema isolado e exporta automaticamente os ícones e binários para o seu menu. Suporta múltiplos motores:
1. **Arch Linux:** Repositórios oficiais via `pacman`.
2. **Debian:** Estabilidade via `apt`.
3. **AUR (Arch User Repository):** Acesso a qualquer software comunitário via `yay`.
4. **Homebrew:** Ferramentas CLI nativas via `brew`.
*Bónus:* Pode simplesmente executar `gear install ./ficheiro.deb` e o sistema trata de tudo automaticamente, removendo até os sufixos de contentor dos ícones exportados!

### `gear update`
Sincroniza o sistema de forma transparente com a imagem mais recente do `bootc` no GitHub Container Registry (suporta autenticação automática via `auth.json`).

### `gear clean`
Faz a manutenção automática do sistema, removendo contentores Podman órfãos e limpando *logs* antigos para libertar espaço no disco.

### `gear status`
Inspeciona o estado da sua árvore imutável (OSTree) e verifica as implementações atuais do sistema.

---

## 🏗️ Construção e Instalação

O GearOS é construído a partir de um `Containerfile`. Para gerar a sua própria imagem ou ISO:

1. Clone o repositório:
   ```bash
   git clone [https://github.com/SEU_UTILIZADOR/GearOS.git](https://github.com/Dogo7777/GearOS.git)
   cd GearOS
   ./build.sh
  (Nota: O script utiliza o Podman e o osbuild/mkosi nos bastidores para gerar um ficheiro ISO inicializável).
