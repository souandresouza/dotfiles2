#!/bin/bash

DEFAULT_WALLPAPER="$HOME/Imagens/wallpapers/default.jpg"

if [[ -f "$DEFAULT_WALLPAPER" ]]; then
    swww img "$DEFAULT_WALLPAPER" \
        --transition-type grow \
        --transition-duration 1.5 \
        --resize crop
else
    # Se não encontrar, usa o script de troca aleatória
    ~/.config/hypr/scripts/wallpaper-changer.sh
fi