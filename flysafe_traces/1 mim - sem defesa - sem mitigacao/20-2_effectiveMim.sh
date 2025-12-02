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

# Garante que TARGET_FOLDER termine com /
[[ "$TARGET_FOLDER" != */ ]] && TARGET_FOLDER="$TARGET_FOLDER"/

shopt -s nullglob
MIM_FILES=("$TARGET_FOLDER"/flysafe_MiM_traces_192.168.1.*.txt)
shopt -u nullglob

if [ ${#MIM_FILES[@]} -eq 0 ]; then
    echo "Nenhum arquivo de trace MiM encontrado em '$TARGET_FOLDER'. Ignorando."
    exit 0
fi

# Loop através de cada arquivo MiM encontrado na pasta
for mim_file in "${MIM_FILES[@]}"; do
    
    # Define o nome do arquivo de saída
    output_file="${mim_file/traces/effective}"
    
    # Copia o cabeçalho para o arquivo de saída
    head -n 1 "$mim_file" > "$output_file"
    
    #echo "Processando '$mim_file' -> Gerando '$output_file'"

    # --- AWK MODIFICADO ---
    awk -v folder="$TARGET_FOLDER" -F'\t+' '
        FNR > 1 { # Pula a linha do cabeçalho
            sender_ip = $2;
            receiver_ip = $3;
            forged_pos = $9; # Coluna da posição forjada

            # Limpa espaços extras da posição forjada
            gsub(/[[:space:]]+/, "", forged_pos);
            
            # Monta a string de busca (remetente + posição forjada)
            search_string = sender_ip "," forged_pos;

            found = 0; # Flag para indicar se a mensagem foi encontrada

            # Verifica se é broadcast ou unicast
            if (receiver_ip == "255.255.255.255") {
                # --- Lógica para BROADCAST ---
                # Procura em TODOS os arquivos neighborhood_evolution_*.txt
                # Usamos um wildcard (*) no nome do arquivo
                grep_cmd = "sh -c '\''grep -qF \"" search_string "\" " folder "neighborhood_evolution_*.txt'\''";
                
                # system() retorna 0 se grep encontrar a string em *pelo menos um* arquivo
                if (system(grep_cmd) == 0) {
                    found = 1;
                }
            } else {
                # --- Lógica para UNICAST (original) ---
                # Define o arquivo específico do destinatário
                neighborhood_file = folder "neighborhood_evolution_" receiver_ip ".txt";
                
                # Verifica se o arquivo do destinatário existe antes de tentar o grep
                # (O comando stat retorna 0 se o arquivo existir)
                check_file_cmd = "stat \"" neighborhood_file "\" > /dev/null 2>&1";
                if (system(check_file_cmd) == 0) {
                     # O arquivo existe, então podemos procurar
                    grep_cmd = "grep -qF \"" search_string "\" \"" neighborhood_file "\"";
                    # system() retorna 0 se grep encontrar a string no arquivo específico
                    if (system(grep_cmd) == 0) {
                        found = 1;
                    }
                }
                # Se o arquivo não existir, found continua 0 (não encontrado)
            }

            # Se a flag found for 1 (encontrado em broadcast ou unicast), imprime a linha original do MiM
            if (found == 1) {
                print $0;
            }
        }
    ' "$mim_file" >> "$output_file"
    # --- FIM DO AWK MODIFICADO ---

done