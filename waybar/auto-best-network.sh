#!/bin/bash

# Configuração inicial das prioridades (todas iguais)
setup_equal_priorities() {
    # Obter todas as redes WiFi salvas
    saved_wifi_networks=$(nmcli -g NAME,TYPE connection show | grep ":802-11-wireless" | cut -d: -f1)
    
    # Configurar mesma prioridade para todas
    while IFS= read -r network; do
        if [[ -n "$network" ]]; then
            nmcli connection modify "$network" connection.autoconnect-priority 500
        fi
    done <<< "$saved_wifi_networks"
    
    #echo "Prioridades equalizadas para todas as redes WiFi salvas"
}

# Encontrar a melhor rede SALVA disponível (com maior sinal)
find_best_saved_network() {
    # Obter todas as redes salvas
    saved_networks=$(nmcli -g NAME,TYPE connection show | grep ":802-11-wireless" | cut -d: -f1)
    
    best_network=""
    best_signal=0
    
    # Para cada rede salva, verificar se está disponível e qual o sinal
    while IFS= read -r network; do
        if [[ -n "$network" ]]; then
            # Verificar se esta rede está disponível no scan
            network_info=$(nmcli -g SSID,SIGNAL device wifi list | grep "^$network:")
            if [[ -n "$network_info" ]]; then
                signal=$(echo "$network_info" | cut -d: -f2)
                # Manter a rede com maior sinal
                if [[ "$signal" -gt "$best_signal" ]]; then
                    best_signal="$signal"
                    best_network="$network"
                fi
            fi
        fi
    done <<< "$saved_networks"
    
    if [[ -n "$best_network" ]]; then
        #echo "$best_network:$best_signal"
    else
        #echo ""
    fi
}

# Verificar e conectar automaticamente na melhor rede SALVA
check_and_connect_best() {
    current_ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
    current_signal=$(nmcli -g ACTIVE,SIGNAL dev wifi | grep '^yes' | cut -d: -f2)
    
    best_network_info=$(find_best_saved_network)
    
    if [[ -n "$best_network_info" ]]; then
        best_ssid=$(echo "$best_network_info" | cut -d: -f1)
        best_signal=$(echo "$best_network_info" | cut -d: -f2)
        
        # Só trocar se a melhor rede for DIFERENTE e tiver sinal SIGNIFICATIVAMENTE melhor
        if [[ "$best_ssid" != "$current_ssid" ]] && [[ "$best_signal" -gt $((current_signal + 10)) ]]; then
            nmcli connection up "$best_ssid"
        fi
    fi
}

# Menu inteligente universal
show_smart_menu() {
    current_network=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
    current_signal=$(nmcli -g ACTIVE,SIGNAL dev wifi | grep '^yes' | cut -d: -f2)
    
    # Encontrar a melhor rede salva
    best_network_info=$(find_best_saved_network)
    best_ssid=$(echo "$best_network_info" | cut -d: -f1)
    best_signal=$(echo "$best_network_info" | cut -d: -f2)
    
    # Obter todas as redes salvas disponíveis
    saved_networks=$(nmcli -g NAME,TYPE connection show | grep ":802-11-wireless" | cut -d: -f1)
    
    menu="📡 Redes Salvas - Status:\n"
    menu+="Atual: $current_network ($current_signal%)\n"
    
    if [[ -n "$best_ssid" ]]; then
        menu+="Melhor: $best_ssid ($best_signal%)\n\n"
    else
        menu+="Melhor: Nenhuma rede salva disponível\n\n"
    fi
    
    # Listar todas as redes salvas com status
    while IFS= read -r network; do
        if [[ -n "$network" ]]; then
            # Verificar se está disponível e qual sinal
            network_info=$(nmcli -g SSID,SIGNAL device wifi list | grep "^$network:")
            if [[ -n "$network_info" ]]; then
                signal=$(echo "$network_info" | cut -d: -f2)
                status=""
                if [[ "$network" == "$current_network" ]]; then
                    status="✅ CONECTADO"
                elif [[ "$network" == "$best_ssid" ]]; then
                    status="🎯 MELHOR REDE"
                else
                    status="📶 Disponível"
                fi
                menu+=" $network: $signal% $status\n"
            else
                menu+="❌ $network: Fora de alcance\n"
            fi
        fi
    done <<< "$saved_networks"
    
    menu+="\n🤖 Ações:\n"
    
    # Mostrar opção de conectar à melhor rede se não for a atual
    if [[ -n "$best_ssid" && "$best_ssid" != "$current_network" ]]; then
        menu+=" Conectar à Melhor Rede ($best_ssid)\n"
    fi
    
    menu+=" Verificação Automática Agora\n"
    menu+=" Gerenciar redes..."
    menu+=" Listar todas as redes visíveis"
    
    choice=$(echo -e "$menu" | dmenu -l 15 -p "Redes WiFi:")
    
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
        *"Listar todas as redes visíveis"*)
            # Mostrar todas as redes disponíveis (não só salvas)
            alacritty -e nmcli device wifi list
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
    "list")
        nmcli -g NAME,TYPE connection show | grep ":802-11-wireless" | cut -d: -f1
        ;;
    *)
        show_smart_menu
        ;;
esac
