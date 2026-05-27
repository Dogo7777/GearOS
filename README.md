**O Sistema Operacional Imutável Otimizado para Gamers e Power Users.**

[![Build Status](https://img.shields.io/github/actions/workflow/status/Dogo7777/GearOS/build.yml?style=for-the-badge&color=ff6600)](https://github.com/Dogo7777/GearOS/actions)
[![Based on](https://img.shields.io/badge/Base-Fedora%20Bootc-3b6eb4?style=for-the-badge&logo=fedora&logoColor=white)](https://bootc.org/)
[![Kernel](https://img.shields.io/badge/Kernel-CachyOS-b81010?style=for-the-badge&logo=linux&logoColor=white)](https://copr.fedorainfracloud.org/coprs/bieszczaders/kernel-cachyos/)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

</div>

---

### 🎯 O que é o GearOS?

O GearOS é uma distribuição Linux imutável baseada no **Fedora Bootc**, projetada para oferecer a estabilidade de um sistema apenas-leitura (como o Steam Deck ou o Fedora Silverblue) sem abrir mão da flexibilidade que os usuários de Arch Linux amam. 

A filosofia é simples: **O sistema base é sagrado e inquebrável. Os aplicativos vivem em ecossistemas isolados.**

Esqueça o famoso "meu Arch quebrou após um update". Com o GearOS, você atualiza o sistema inteiro com um comando. Se algo quebrar, você volta no tempo com outro.

---

### ✨ Destaques e Funcionalidades

- 🛡️ **Imutabilidade Nativa:** Baseado em `bootc`. Atualizações atômicas e reversões instantâneas (`gear rollback`). Seu `/usr` é inviolável.
- 🎮 **Kernel CachyOS:** Compilado com otimizações agressivas para reduzir latência e aumentar os FPS em jogos.
- 🐚 **Gear CLI:** Um gerenciador de ecossistemas próprio. Instale pacotes do Arch, AUR ou Debian de forma isolada usando Distrobox, sem sujar o sistema base.
- 🎨 **Desktop Híbrido Perfeito:** KDE Plasma como shell principal, integrado elegantemente com aplicativos GNOME (Nautilus, Ptyxis, GNOME Software).
- 🧠 **Particionamento Inteligente:** Raiz (`/`) em EXT4 para estabilidade máxima do bootc, enquanto `/var` e `/home` utilizam Btrfs dinâmico para flexibilidade e snapshots.
- ⚡ **Zsh P10K Tunado:** Terminal lindo com Powerlevel10k, autosuggestions e o menu interativo `gear` que abre no primeiro login.

---
