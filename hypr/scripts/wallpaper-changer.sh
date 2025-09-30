#!/bin/bash

WALLPAPER_DIR="$HOME/Imagens/wallpapers"

# Criar diretório se não existir
mkdir -p "$WALLPAPER_DIR"

# Verificar se swww está rodando
if ! swww query; then
    swww init
    sleep 1
fi

# Escolher wallpaper aleatório
random_wallpaper=$(find "$/home/andre/Imagens/wallpapers" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | shuf -n 1)

if [[ -n "$random_wallpaper" ]]; then
    # Aplicar com transição suave
    swww img "$random_wallpaper" \
        --transition-type grow \
        --transition-duration 2 \
        --transition-fps 60 \
        --transition-step 255 \
        --resize crop
else
    echo "Nenhum wallpaper encontrado em $WALLPAPER_DIR"
fi
