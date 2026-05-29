#!/bin/bash
# Script de automação total GearOS

set -e

# ==========================================
# MENU DE SELEÇÃO DE FLAVOR (SABOR)
# ==========================================
echo -e "\n=== BEM-VINDO AO BUILDER DO GEAROS ==="
echo "Qual versão deseja compilar?"
echo "  [1] Base (AMD/Intel) - O Padrão"
echo "  [2] NVIDIA Moderna (Série 900+)"
echo "  [3] NVIDIA Legacy (Série 600/700 - Driver 470xx)"
echo -n "Escolha [1/2/3]: "
read ESCOLHA

case "$ESCOLHA" in
    2)
        TAG_SUFIXO="nvidia"
        ARQUIVO_BUILD="Containerfile.nvidia"
        echo -e "\n>> Preparando compilação: NVIDIA Moderna..."
        ;;
    3)
        TAG_SUFIXO="nvidia-legacy"
        ARQUIVO_BUILD="Containerfile.nvidia-legacy"
        echo -e "\n>> Preparando compilação: NVIDIA Legacy..."
        ;;
    *)
        TAG_SUFIXO="latest"
        ARQUIVO_BUILD="Containerfile"
        echo -e "\n>> Preparando compilação: BASE (AMD/Intel)..."
        ;;
esac

# Verifica se o ficheiro específico existe antes de tentar compilar
if [ ! -f "$ARQUIVO_BUILD" ]; then
    echo "ERRO: O ficheiro '$ARQUIVO_BUILD' não existe na pasta!"
    exit 1
fi

# Configurações Dinâmicas
NOME_IMAGEM="ghcr.io/dogo7777/gearos:$TAG_SUFIXO"
NOME_LOCAL="localhost/gearos:$TAG_SUFIXO"
PASTA_TEMP="/home/luis/tmp_podman"
DIRETORIO_PROJETO="$HOME/Fedora-Steam"
CONFIG_TOML="$DIRETORIO_PROJETO/config.toml"
SAIDA="$DIRETORIO_PROJETO/output"
ARQUIVO_TOKEN="$HOME/.github_token"

mkdir -p "$PASTA_TEMP"
mkdir -p "$SAIDA"

# Autentica sudo uma vez no início
echo ">> Autenticando sudo (necessário apenas uma vez)..."
sudo -v

# Mantém o sudo ativo durante todo o script
while true; do sudo -v; sleep 50; done &
SUDO_PID=$!
trap "kill $SUDO_PID" EXIT

echo "--- 1. Construindo a imagem GearOS ($TAG_SUFIXO) ---"
sudo TMPDIR="$PASTA_TEMP" podman build \
    --no-cache \
    --network host \
    -t "$NOME_LOCAL" \
    -f "$ARQUIVO_BUILD" . || exit 1

echo "--- 2. Enviando para o GitHub ---"
if [ -f "$ARQUIVO_TOKEN" ]; then
    echo ">> Autenticando no GHCR..."
    cat "$ARQUIVO_TOKEN" | sudo podman login ghcr.io -u dogo7777 --password-stdin || exit 1
else
    echo "ERRO: Token não encontrado em $ARQUIVO_TOKEN"
    echo "Crie com: echo 'seu_token' > ~/.github_token && chmod 600 ~/.github_token"
    exit 1
fi

sudo podman tag "$NOME_LOCAL" "$NOME_IMAGEM"
sudo TMPDIR="$PASTA_TEMP" podman push "$NOME_IMAGEM" || exit 1

echo "--- 2.5. Pull da imagem ---"
sudo podman pull "$NOME_IMAGEM"

echo "--- 3. Gerando a ISO ---"
sudo rm -rf "$SAIDA"/*

sudo podman run --rm -it \
    --privileged \
    --network host \
    --pull=always \
    --security-opt label=type:unconfined_t \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    -v "$SAIDA":/output \
    -v "$CONFIG_TOML":/config.toml:z \
    -v "$PASTA_TEMP":/var/tmp:z \
    ghcr.io/osbuild/bootc-image-builder:latest \
    --type anaconda-iso \
    --rootfs ext4 \
    --output /output \
    --config /config.toml \
    "$NOME_IMAGEM"

echo ""
echo "--- Processo concluído! ---"
echo "ISO pronta em: $SAIDA/bootiso/install.iso"
ls -lh "$SAIDA/bootiso/install.iso" 2>/dev/null || ls -lh "$SAIDA"
