#!/bin/bash

# Configurações
PROJECTOR_OUTPUT="HDMI-A-1"  # Ajuste conforme seu output
LAPTOP_OUTPUT="eDP-1"        # Ajuste conforme seu laptop
PROJECTOR_RESOLUTION="1920x1080"  # Resolução do projetor

detect_projector() {
    if swaymsg -t get_outputs | grep -q "$PROJECTOR_OUTPUT"; then
        echo "🖥️"  # Ícone quando projetor conectado
        return 0
    else
        echo ""  # Vazio quando desconectado
        return 1
    fi
}

configure_projector() {
    if swaymsg -t get_outputs | grep -q "$PROJECTOR_OUTPUT"; then
        # Configura o projetor
        swaymsg output "$PROJECTOR_OUTPUT" enable
        swaymsg output "$PROJECTOR_OUTPUT" mode "$PROJECTOR_RESOLUTION"
        swaymsg output "$PROJECTOR_OUTPUT" pos 0 0
        
        # Configura o laptop (ajuste conforme necessário)
        swaymsg output "$LAPTOP_OUTPUT" pos 1920 0
        
        notify-send "Projetor" "Projetor conectado e configurado: $PROJECTOR_RESOLUTION"
    else
        swaymsg output "$PROJECTOR_OUTPUT" disable
        notify-send "Projetor" "Projetor desconectado"
    fi
}

case "$1" in
    --detect)
        detect_projector
        ;;
    --configure)
        configure_projector
        ;;
    *)
        echo "Uso: $0 --detect | --configure"
        exit 1
        ;;
esac