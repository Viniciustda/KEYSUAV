#!/bin/bash
# ==============================================================================
# 26-2_networkContaminationTime.sh
#
# Script trabalhador que calcula o tempo total que a rede ficou com
# informação falsa em uma única simulação, usando o algoritmo de
# fusão de intervalos sobrepostos.
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

OUTPUT_FILE="$TARGET_FOLDER/network_contamination_time.txt"

# O processo é um pipeline de 3 etapas:
# 1. AWK-1: Extrai todos os intervalos [start, end] de todos os arquivos.
# 2. SORT: Ordena esses intervalos pelo tempo de início.
# 3. AWK-2: Percorre os intervalos ordenados, funde os que se sobrepõem e soma as durações.

LC_NUMERIC=C awk '
    # 1. Extrai os intervalos de tempo [start, end]
    FNR > 1 {
        # start = receivedTime ($2), end = receivedTime ($2) + activeTime ($3)
        printf "%.3f\t%.3f\n", $2, $2 + $3 
    }
' "${EFFECTIVE_FILES[@]}" | \
sort -n -k1,1 | \
LC_NUMERIC=C awk '
    # 2. Funde os intervalos ordenados e soma as durações
    BEGIN { total_duration = 0; }
    
    # Para a primeira linha, apenas inicializamos o primeiro intervalo de fusão
    NR == 1 {
        merged_start = $1;
        merged_end = $2;
        next;
    }

    # Para as linhas seguintes
    {
        current_start = $1;
        current_end = $2;

        # Verifica se o intervalo atual se sobrepõe ao intervalo de fusão anterior
        if (current_start <= merged_end) {
            # Se houver sobreposição, estende o final do intervalo de fusão se necessário
            if (current_end > merged_end) {
                merged_end = current_end;
            }
        } else {
            # Se não houver sobreposição, o intervalo de fusão anterior terminou.
            # Adicionamos sua duração ao total.
            total_duration += (merged_end - merged_start);
            
            # E começamos um novo intervalo de fusão com os dados da linha atual.
            merged_start = current_start;
            merged_end = current_end;
        }
    }

    # Após a última linha, o último intervalo de fusão ainda precisa ser contabilizado.
    END {
        total_duration += (merged_end - merged_start);
        printf "%.3f\n", total_duration;
    }
' > "$OUTPUT_FILE"

# echo "Arquivo de tempo de contaminação gerado em '$OUTPUT_FILE'."