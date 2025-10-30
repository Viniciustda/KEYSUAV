#!/bin/bash
# ==============================================================================
# 23-2_mimDurationCalculation.sh 
#
# Script trabalhador que:
# 1. Lê cada linha dos arquivos 'flysafe_MiM_effective...'.
# 2. Para cada linha, aplica a lógica correta:
#    - Unicast: Roda a lógica original (soma das durações para o destinatário).
#    - Broadcast: Roda a nova lógica (janela de tempo global),
#                 calculando o tempo desde a primeira aparição até o
#                 último desaparecimento em *qualquer* nó.
# 3. Reescreve o arquivo 'effective' com os tempos calculados.
# ==============================================================================

TARGET_FOLDER=$1
if [ -z "$TARGET_FOLDER" ]; then
    echo "Erro: Nenhuma pasta alvo foi especificada." >&2
    exit 1
fi

# Garante que a pasta termine com /
[[ "$TARGET_FOLDER" != */ ]] && TARGET_FOLDER="$TARGET_FOLDER"/

SIM_DURATION=1200 # Duração total da simulação em segundos
NUM_NODES=40      # Número total de nós para o loop de broadcast

# Encontra os arquivos 'effective'
shopt -s nullglob
EFFECTIVE_FILES=("$TARGET_FOLDER"flysafe_MiM_effective_192.168.1.*.txt)
shopt -u nullglob

if [ ${#EFFECTIVE_FILES[@]} -eq 0 ]; then
    echo "Nenhum arquivo 'effective' encontrado em '$TARGET_FOLDER'. Ignorando."
    exit 0
fi

# Loop através de cada arquivo 'effective'
for effective_file in "${EFFECTIVE_FILES[@]}"; do
    
    # echo "Processando '$effective_file' para calcular durações..."
    temp_file=$(mktemp) # Arquivo temporário

    # Este único comando awk faz todo o trabalho:
    LC_NUMERIC=C awk -v folder="$TARGET_FOLDER" -v sim_duration="$SIM_DURATION" -v num_nodes="$NUM_NODES" -F'\t+' -v OFS='\t' '
        # Bloco BEGIN: executado uma vez no início. Imprime o novo cabeçalho.
        BEGIN {
            print "time", "receivedTime", "activeTime", "senderIP", "receiverIP", "msgBroad", "msgId", "msgTrap", "originalMessageTime", "senderPosition", "forgedPosition", "senderNeighborList"
        }

        # Bloco Principal: executado para cada linha do arquivo "effective" (exceto cabeçalho)
        FNR > 1 {
            # Extrai os dados da linha atual do arquivo "effective"
            time = $1; sender_ip = $2; receiver_ip = $3;
            msgBroad = $4; msgId = $5; msgTrap = $6;
            originalMessageTime = $7; senderPosition = $8; forgedPosition = $9;
            senderNeighborList = $10;

            # Monta a string de busca
            gsub(/[[:space:]]+/, "", forgedPosition);
            search_string = sender_ip "," forgedPosition;

            final_received_time = 0;
            final_active_time = 0;

            # --- LÓGICA IF/ELSE SOLICITADA ---
            if (receiver_ip == "255.255.255.255") {
                # --- LÓGICA BROADCAST (Janela de Tempo Global) ---
                
                global_min_start = -1;
                global_max_end = 0;

                # Loop através de todos os arquivos de nó (1 a 40)
                for (i = 1; i <= num_nodes; i++) {
                    neighborhood_file = folder "/neighborhood_evolution_192.168.1." i ".txt";
                    
                    last_file_had_match = 0;
                    
                    # Usa getline < file para ler o arquivo
                    while ((getline line < neighborhood_file) > 0) {
                        sub(/\r$/, "", line);
                        # Pega o timestamp da linha
                        current_time = 0;
                        split(line, parts, "\t");
                        current_time = parts[1] + 0;

                        if (index(line, search_string)) {
                            # --- Match encontrado ---
                            # Verifica se é o primeiro tempo global
                            if (global_min_start == -1 || current_time < global_min_start) {
                                global_min_start = current_time;
                            }
                            last_file_had_match = 1;
                        } else {
                            # --- Sem match ---
                            if (last_file_had_match) {
                                # A string acabou de desaparecer neste arquivo
                                if (current_time > global_max_end) {
                                    global_max_end = current_time;
                                }
                            }
                            last_file_had_match = 0;
                        }
                    }
                    close(neighborhood_file);
                    
                    # Se o arquivo terminou com um match, o tempo de fim é 1200
                    if (last_file_had_match) {
                        if (sim_duration > global_max_end) {
                            global_max_end = sim_duration;
                        }
                    }
                } # Fim do loop for (i=1..40)

                if (global_min_start == -1) {
                    final_received_time = 0;
                    final_active_time = 0;
                } else {
                    if (global_max_end < global_min_start) global_max_end = global_min_start;
                    final_received_time = global_min_start;
                    final_active_time = global_max_end - global_min_start;
                }

            } else {
                # --- LÓGICA UNICAST (Seu código original) ---
                neighborhood_file = folder "/neighborhood_evolution_" receiver_ip ".txt";
                
                total_duration = 0;
                first_match_time = -1;
                is_match_on_prev_line = 0;
                prev_match_time = 0;
                
                # Checa se o arquivo existe (lendo a primeira linha)
                if ((getline line < neighborhood_file) > 0) {
                    # Processa a primeira linha que já lemos
                    sub(/\r$/, "", line);
                    split(line, parts, "\t");
                    current_time = parts[1] + 0;
                    if (index(line, search_string)) {
                        first_match_time = current_time;
                        is_match_on_prev_line = 1;
                        prev_match_time = current_time;
                    }

                    # Continua lendo o resto do arquivo
                    while ((getline line < neighborhood_file) > 0) {
                        sub(/\r$/, "", line);
                        split(line, parts, "\t");
                        current_time = parts[1] + 0;

                        if (is_match_on_prev_line) {
                            total_duration += (current_time - prev_match_time);
                        }
                        is_match_on_prev_line = 0;

                        if (index(line, search_string)) {
                            if (first_match_time == -1) {
                                first_match_time = current_time;
                            }
                            is_match_on_prev_line = 1;
                            prev_match_time = current_time;
                        }
                    }
                    
                    # Trata o caso da última linha
                    if (is_match_on_prev_line) {
                        total_duration += (sim_duration - prev_match_time);
                    }
                } # Fim do if (arquivo existe)
                
                close(neighborhood_file);

                if (first_match_time == -1) first_match_time = 0;
                
                final_received_time = first_match_time;
                final_active_time = total_duration;
            }

            # --- Impressão Corrigida ---
            # Imprime as colunas na ordem correta do cabeçalho
            printf "%s\t%.3f\t%.3f\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", \
                   time, final_received_time, final_active_time, \
                   sender_ip, receiver_ip, msgBroad, msgId, msgTrap, \
                   originalMessageTime, senderPosition, forgedPosition, senderNeighborList
        }
    ' "$effective_file" > "$temp_file"

    # Substitui o arquivo antigo pelo novo
    mv "$temp_file" "$effective_file"
done