#!/bin/bash

# Configuração inicial das prioridades (todas iguais)
setup_equal_priorities() {
    nmcli connection modify "André_5G" connection.autoconnect-priority 500
    nmcli connection modify "André-EXT" connection.autoconnect-priority 500  
    nmcli connection modify "André_Ext2" connection.autoconnect-priority 500
    echo "Prioridades equalizadas - decisão por sinal"
}

# Encontrar a melhor rede disponível (com maior sinal)
find_best_network() {
    # Obter todas as redes André disponíveis com seus sinais
    available_networks=$(nmcli -g SSID,SIGNAL device wifi list | grep "André")
    
    # Ordenar por sinal (maior primeiro) e pegar a melhor
    best_network=$(echo "$available_networks" | sort -t: -k2 -nr | head -n1)
    
    if [[ -n "$best_network" ]]; then
        best_ssid=$(echo "$best_network" | cut -d: -f1)
        best_signal=$(echo "$best_network" | cut -d: -f2)
        echo "$best_ssid:$best_signal"
    else
        echo ""
    fi
}

# Verificar e conectar automaticamente na melhor rede
check_and_connect_best() {
    current_ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
    current_signal=$(nmcli -g ACTIVE,SIGNAL dev wifi | grep '^yes' | cut -d: -f2)
    
    best_network_info=$(find_best_network)
    
    if [[ -n "$best_network_info" ]]; then
        best_ssid=$(echo "$best_network_info" | cut -d: -f1)
        best_signal=$(echo "$best_network_info" | cut -d: -f2)
        
        #echo "📊 Status atual: $current_ssid ($current_signal%)"
        #echo "🎯 Melhor rede disponível: $best_ssid ($best_signal%)"
        
        # Só trocar se a melhor rede for DIFERENTE e tiver sinal SIGNIFICATIVAMENTE melhor
        if [[ "$best_ssid" != "$current_ssid" ]] && [[ "$best_signal" -gt $((current_signal + 10)) ]]; then
            #echo "🔄 TROCA AUTOMÁTICA: $current_ssid → $best_ssid ($best_signal% vs $current_signal%)"
            nmcli connection up "$best_ssid"
        elif [[ "$best_ssid" != "$current_ssid" ]]; then
            #echo "⚖️  Melhor rede: $best_ssid ($best_signal%), mas diferença insuficiente para trocar"
        else
            #echo "✅ Já conectado na melhor rede: $best_ssid ($best_signal%)"
        fi
    else
        #echo "❌ Nenhuma rede André disponível"
    fi
}

# Menu inteligente
show_smart_menu() {
    current_network=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
    current_signal=$(nmcli -g ACTIVE,SIGNAL dev wifi | grep '^yes' | cut -d: -f2)
    
    # Informações de todas as redes André
    fiveg_info=$(nmcli -g SSID,SIGNAL device wifi | grep "André_5G")
    ext1_info=$(nmcli -g SSID,SIGNAL device wifi | grep "André-EXT")
    ext2_info=$(nmcli -g SSID,SIGNAL device wifi | grep "André_Ext2")
    
    # Encontrar a melhor rede
    best_network_info=$(find_best_network)
    best_ssid=$(echo "$best_network_info" | cut -d: -f1)
    best_signal=$(echo "$best_network_info" | cut -d: -f2)
    
    menu="📡 Redes André - Status:\n"
    menu+="Atual: $current_network ($current_signal%)\n"
    menu+="Melhor: $best_ssid ($best_signal%)\n\n"
    
    if [[ -n "$fiveg_info" ]]; then
        fiveg_signal=$(echo "$fiveg_info" | cut -d: -f2)
        status=""
        if [[ "$current_network" == "André_5G" ]]; then
            status="✅ CONECTADO"
        elif [[ "$best_ssid" == "André_5G" ]]; then
            status="🎯 MELHOR REDE"
        else
            status="📶 Disponível"
        fi
        menu+=" André_5G: $fiveg_signal% $status\n"
    else
        menu+="❌ André_5G: Fora de alcance\n"
    fi
    
    if [[ -n "$ext1_info" ]]; then
        ext1_signal=$(echo "$ext1_info" | cut -d: -f2)
        status=""
        if [[ "$current_network" == "André-EXT" ]]; then
            status="✅ CONECTADO"
        elif [[ "$best_ssid" == "André-EXT" ]]; then
            status="🎯 MELHOR REDE"
        else
            status="📶 Disponível"
        fi
        menu+=" André-EXT: $ext1_signal% $status\n"
    fi
    
    if [[ -n "$ext2_info" ]]; then
        ext2_signal=$(echo "$ext2_info" | cut -d: -f2)
        status=""
        if [[ "$current_network" == "André_Ext2" ]]; then
            status="✅ CONECTADO"
        elif [[ "$best_ssid" == "André_Ext2" ]]; then
            status="🎯 MELHOR REDE"
        else
            status="📶 Disponível"
        fi
        menu+=" André_Ext2: $ext2_signal% $status\n"
    fi
    
    menu+="\n🤖 Ações:\n"
    
    # Mostrar opção de conectar à melhor rede se não for a atual
    if [[ "$best_ssid" != "$current_network" ]]; then
        menu+=" Conectar à Melhor Rede ($best_ssid)\n"
    fi
    
    menu+=" Verificação Automática Agora\n"
    menu+=" Gerenciar redes..."
    
    choice=$(echo -e "$menu" | dmenu -l 12 -p "Redes André:")
    
    case "$choice" in
        *"Conectar à Melhor Rede"*)
            nmcli connection up "$best_ssid"
            ;;
        *"Verificação Automática"*)
            check_and_connect_best
            ;;
        *"Gerenciar redes"*)
            networkmanager_dmenu
            ;;
    esac
}

# Executar
case "${1:-}" in
    "setup")
        setup_equal_priorities
        ;;
    "check")
        check_and_connect_best
        ;;
    *)
        show_smart_menu
        ;;
esac
