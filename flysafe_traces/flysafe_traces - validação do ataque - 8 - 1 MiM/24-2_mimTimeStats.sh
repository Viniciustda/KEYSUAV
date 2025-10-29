#!/bin/bash
# ==============================================================================
# 24-2_mimTimeStats.sh
#
# Script trabalhador que analisa os arquivos 'flysafe_MiM_effective...' de uma
# pasta e gera dois relatórios de estatísticas:
# 1. flysafe_MiM_message_active_time.txt: Estatísticas por mensagem.
# 2. flysafe_MiM_node_storage_time.txt: Estatísticas por nó (receiver).
# ==============================================================================

TARGET_FOLDER=$1
if [ -z "$TARGET_FOLDER" ]; then
    echo "Erro: Nenhuma pasta alvo foi especificada." >&2
    exit 1
fi

# Usa shopt e array para encontrar os arquivos de forma segura
shopt -s nullglob
EFFECTIVE_FILES=("$TARGET_FOLDER"/flysafe_MiM_effective_192.168.1.*.txt)
shopt -u nullglob

if [ ${#EFFECTIVE_FILES[@]} -eq 0 ]; then
    echo "Nenhum arquivo 'effective' encontrado em '$TARGET_FOLDER'. Ignorando."
    exit 0
fi

# --- TAREFA 1: ESTATÍSTICAS POR MENSAGEM ---

OUTPUT_FILE_MSG="$TARGET_FOLDER/flysafe_MiM_message_active_time.txt"
# echo "Gerando estatísticas por mensagem em '$OUTPUT_FILE_MSG'..."

# Concatena todos os arquivos 'effective' e usa awk para calcular min/max/mean da coluna 3 (activeTime)
LC_NUMERIC=C awk '
    # Ignora a primeira linha (cabeçalho) de cada arquivo
    FNR > 1 {
        active_time = $3;
        sum += active_time;
        count++;
        
        if (count == 1) {
            min = active_time;
            max = active_time;
        } else {
            if (active_time < min) min = active_time;
            if (active_time > max) max = active_time;
        }
    }
    END {
        print "max\t\tmin\t\tmean";
        
        if (count > 0) {
            # Imprime a linha de dados com os valores calculados
            printf "%.3f\t%.3f\t%.3f\n", max, min, sum / count;
        } else {
            # Imprime uma linha de zeros se não houver dados
            print "0.000\t0.000\t0.000";
        }
    }
' "${EFFECTIVE_FILES[@]}" > "$OUTPUT_FILE_MSG"


# --- TAREFA 2: ESTATÍSTICAS POR NÓ (RECEIVER) ---

OUTPUT_FILE_NODE="$TARGET_FOLDER/flysafe_MiM_node_storage_time.txt"
# echo "Gerando estatísticas por nó em '$OUTPUT_FILE_NODE'..."

# Concatena todos os arquivos e usa um awk mais complexo para agrupar por receiverIP
LC_NUMERIC=C awk '
    # Ignora o cabeçalho
    FNR > 1 {
        # Coluna 3 é activeTime, Coluna 5 é receiverIP
        receiver = $5;
        active_time = $3;
        
        # Acumula o tempo total de armazenamento para cada nó
        total_storage_time[receiver] += active_time;
    }
    END {
        # Imprime o cabeçalho da tabela
        print "max\t\tmin\t\tmean";
        
        node_count = 0;
        sum_of_totals = 0;
        
        for (node in total_storage_time) {
            storage_time = total_storage_time[node];
            sum_of_totals += storage_time;
            
            if (node_count == 0) {
                min_storage = storage_time;
                max_storage = storage_time;
            } else {
                if (storage_time < min_storage) min_storage = storage_time;
                if (storage_time > max_storage) max_storage = storage_time;
            }
            node_count++;
        }
        
        if (node_count > 0) {
            # Imprime a linha de dados com os valores calculados
            printf "%.3f\t%.3f\t%.3f\n", max_storage, min_storage, sum_of_totals / node_count;
        } else {
            # Imprime uma linha de zeros se não houver dados
            print "0.000\t0.000\t0.000";
        }
    }
' "${EFFECTIVE_FILES[@]}" > "$OUTPUT_FILE_NODE"