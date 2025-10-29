#!/bin/bash
# ==============================================================================
# 20-2_worker_process_effective_mim.sh (Versão Corrigida e Robusta)
#
# Script trabalhador que analisa uma única pasta para encontrar mensagens MiM
# que foram efetivamente recebidas e armazenadas pelo destinatário.
# ==============================================================================

# Pega o caminho da pasta do primeiro argumento
TARGET_FOLDER=$1

if [ -z "$TARGET_FOLDER" ]; then
    echo "Erro: Nenhuma pasta alvo foi especificada." >&2
    exit 1
fi

shopt -s nullglob
MIM_FILES=("$TARGET_FOLDER"/flysafe_MiM_traces_192.168.1.*.txt)
shopt -u nullglob

if [ ${#MIM_FILES[@]} -eq 0 ]; then
    echo "Nenhum arquivo de trace MiM encontrado em '$TARGET_FOLDER'. Ignorando."
    exit 0
fi

# Loop através de cada arquivo MiM encontrado na pasta
for mim_file in "${MIM_FILES[@]}"; do
    
    output_file="${mim_file/traces/effective}"
    
    head -n 1 "$mim_file" > "$output_file"
    
    # echo "Processando '$mim_file' -> Gerando '$output_file'"

    # -F'\t+' trata uma ou mais tabs como um só separador.
    # Isso garante que as colunas $2, $3 e $9 sejam lidas corretamente.
    awk -v folder="$TARGET_FOLDER" -F'\t+' '
        FNR > 1 {
            sender_ip = $2;
            receiver_ip = $3;
            forged_pos = $9;

            gsub(/[[:space:]]+/, "", forged_pos);
            
            search_string = sender_ip "," forged_pos;
            neighborhood_file = folder "/neighborhood_evolution_" receiver_ip ".txt";
            
            grep_cmd = "grep -qF \"" search_string "\" \"" neighborhood_file "\"";
            
            if (system(grep_cmd) == 0) {
                print $0;
            }
        }
    ' "$mim_file" >> "$output_file"
done