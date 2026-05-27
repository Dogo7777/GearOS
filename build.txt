#!/bin/bash
# Script de automação total GearOS

# Configurações
NOME_IMAGEM="ghcr.io/dogo7777/gearos:latest"
PASTA_TEMP="/home/luis/tmp_podman"
CONFIG_TOML="$HOME/Fedora-Steam/config.toml"
SAIDA="$HOME/GearOS/output"
ARQUIVO_TOKEN="$HOME/.github_token"

# Cria pasta de temp se não existir
mkdir -p "$PASTA_TEMP"
mkdir -p "$SAIDA"

echo "--- 1. Construindo a imagem GearOS ---"
sudo TMPDIR="$PASTA_TEMP" podman build --network host -t "$NOME_IMAGEM" -f Containerfile . || exit 1

echo "--- 2. Enviando para o GitHub ---"
# Verifica se o ficheiro do token existe e faz o login automático
if [ -f "$ARQUIVO_TOKEN" ]; then
    echo ">> Autenticando no GitHub Container Registry..."
    cat "$ARQUIVO_TOKEN" | sudo podman login ghcr.io -u dogo7777 --password-stdin || exit 1
else
    echo "ERRO: O ficheiro de token não foi encontrado em $ARQUIVO_TOKEN"
    echo "Crie o ficheiro usando: echo 'seu_token' > ~/.github_token"
    exit 1
fi

# Faz o push após o login ter sucesso
sudo TMPDIR="$PASTA_TEMP" podman push "$NOME_IMAGEM" || exit 1

echo "--- 3. Gerando a ISO ---"
sudo podman run --rm -it \
    --privileged \
    --network host \
    --pull=always \
    --security-opt label=type:unconfined_t \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    -v "$HOME/Fedora-Steam/output":/output \
    -v "$HOME/Fedora-Steam/config.toml":/config.toml \
    ghcr.io/osbuild/bootc-image-builder:latest \
    --type anaconda-iso \
    --rootfs btrfs \
    --output /output \
    --config /config.toml \
    ghcr.io/dogo7777/gearos:latest

echo "--- Processo concluído! ISO pronta em $SAIDA ---"
