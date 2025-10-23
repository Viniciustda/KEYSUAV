#!/bin/bash
# ==============================================================================
# 23-2_mimDurationCalculation.sh
#
# Script trabalhador que:
# 1. Lê cada linha dos arquivos 'flysafe_MiM_effective...'.
# 2. Para cada linha, calcula o tempo total que a mensagem forjada
#    permaneceu na lista de vizinhos do destinatário.
# 3. Reescreve o arquivo 'effective' adicionando as colunas
#    'receivedTime' e 'activeTime'.
# ==============================================================================

TARGET_FOLDER=$1
if [ -z "$TARGET_FOLDER" ]; then
    echo "Erro: Nenhuma pasta alvo foi especificada." >&2
    exit 1
fi

shopt -s nullglob
EFFECTIVE_FILES=("$TARGET_FOLDER"/flysafe_MiM_effective_192.168.1.*.txt)
shopt -u nullglob

if [ ${#EFFECTIVE_FILES[@]} -eq 0 ]; then
    echo "Nenhum arquivo 'effective' encontrado em '$TARGET_FOLDER'. Ignorando."
    exit 0
fi

# Loop através de cada arquivo 'effective' encontrado na pasta
for effective_file in "${EFFECTIVE_FILES[@]}"; do
    
    # echo "Processando '$effective_file' para calcular durações..."
    temp_file=$(mktemp)

    # Este único comando awk faz todo o trabalho:
    # 1. Lê o arquivo 'effective'
    # 2. Para cada linha, lê o 'neighborhood_evolution' correspondente
    # 3. Calcula os tempos
    # 4. Imprime a nova linha formatada
    LC_NUMERIC=C awk -v folder="$TARGET_FOLDER" -F'\t+' -v OFS='\t' '
        # Bloco BEGIN: executado uma vez no início. Imprime o novo cabeçalho.
        BEGIN {
            print "time", "receivedTime", "activeTime", "senderIP", "receiverIP", "msgBroad", "msgId", "msgTrap", "originalMessageTime", "senderPosition", "forgedPosition", "senderNeighborList"
        }

        # Bloco Principal: executado para cada linha do arquivo "effective" (exceto cabeçalho)
        FNR > 1 {
            # Extrai os dados da linha atual do arquivo "effective"
            time = $1; sender_ip = $2; receiver_ip = $3; forged_pos = $9;

            # Monta a string de busca e o nome do arquivo de vizinhança
            gsub(/[[:space:]]+/, "", forged_pos);
            search_string = sender_ip "," forged_pos;
            neighborhood_file = folder "/neighborhood_evolution_" receiver_ip ".txt";

            # --- Início do Sub-processo de Cálculo de Duração ---
            {
                total_duration = 0;
                first_match_time = -1;
                is_match_on_prev_line = 0;
                prev_match_time = 0;
                
                cmd = "wc -l < \"" neighborhood_file "\"";
                if ((cmd | getline last_line_number) > 0) {
                    close(cmd);
                    
                    # Loop através do arquivo de vizinhança linha por linha
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
                    close(neighborhood_file);

                    # Trata o caso especial da última linha
                    if (is_match_on_prev_line) {
                        total_duration += (1200 - prev_match_time);
                    }
                }
                if (first_match_time == -1) first_match_time = 0;
            }
            # --- Fim do Sub-processo ---

            # Imprime a linha completa, inserindo as novas colunas
            # e preservando todas as colunas originais
            $1 = $1; # Reconstrói a linha para garantir OFS
            printf "%s\t%.3f\t%.3f", $1, first_match_time, total_duration;
            for (i=2; i<=NF; i++) {
                printf "\t%s", $i;
            }
            printf "\n";
        }
    ' "$effective_file" > "$temp_file"

    # Substitui o arquivo antigo pelo novo, agora corrigido e completo
    mv "$temp_file" "$effective_file"
done