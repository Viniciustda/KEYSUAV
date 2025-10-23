#!/bin/bash

# ==============================================================================
# 19_globalMimAnalysis.sh
#
# Agrega os resultados de todos os arquivos 'flysafe_MiM_traces.txt'
# gerados nas subpastas e cria um relatório global com estatísticas.
#
# O relatório final é salvo em 'flysafe_global_traces/global_flysafe_MiM_traces.txt'.
# ==============================================================================

echo "Iniciando a geração do relatório global..."

OUTPUT_DIR="flysafe_global_traces"
OUTPUT_FILE="$OUTPUT_DIR/global_flysafe_MiM_traces.txt"
INPUT_FILES=$(find . -mindepth 2 -name 'flysafe_MiM_traces.txt')

mkdir -p "$OUTPUT_DIR"

if [ -z "$INPUT_FILES" ]; then
    echo "Nenhum arquivo 'flysafe_MiM_traces.txt' foi encontrado. Execute o script 18-1 primeiro."
    exit 1
fi

# Concatena todos os arquivos de resultado e os envia para o novo comando awk
cat $INPUT_FILES | awk '
BEGIN {
    # Define a ordem de impressão desejada
    descs[1] = "Sent msgs"
    descs[2] = "Sent broad"
    descs[3] = "Sent ident"
    descs[4] = "Sent trap"
    
    # Associa a descrição a um índice para facilitar o armazenamento
    for (i=1; i<=4; i++) {
        desc_map[descs[i]] = i
    }
    
    file_count = 0
}

# Ignora cabeçalhos e linhas de separação de forma robusta
$1 == "Description" || $1 ~ /^-+$/ { next }

# Bloco principal de processamento: armazena todos os valores
{
    # Reconstrói a descrição (ex: "Sent msgs")
    current_desc = $1 " " $2
    idx = desc_map[current_desc]

    # Armazena os valores de cada arquivo em arrays
    # O primeiro índice é a métrica, o segundo é o número do arquivo
    totals[idx, file_count] = $3
    maxes[idx, file_count] = $4
    mins[idx, file_count] = $5
    means[idx, file_count] = $6

    # Incrementa o contador de arquivos apenas uma vez por arquivo (na última métrica)
    if (current_desc == "Sent trap") {
        file_count++
    }
}

END {
    # Imprime o cabeçalho na ordem correta
    printf "%-18s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", "Description", "total", "max", "min", "mean", "avgMax", "avgMin", "avgMean"
    
    # Itera de 1 a 4 para garantir a ordem de impressão correta
    for (i = 1; i <= 4; i++) {
        d = descs[i]
        
        # Inicializa variáveis para os cálculos
        sum_total = 0
        sum_max = 0
        sum_min = 0
        sum_mean = 0
        
        # Define os valores iniciais para o min/max absolutos
        abs_max_val = maxes[i, 0]
        abs_min_val = mins[i, 0]
        
        # Loop através dos resultados de cada arquivo para agregar os dados
        for (j = 0; j < file_count; j++) {
            sum_total += totals[i, j]
            sum_max   += maxes[i, j]
            sum_min   += mins[i, j]
            sum_mean  += means[i, j]
            
            if (maxes[i, j] > abs_max_val) abs_max_val = maxes[i, j]
            if (mins[i, j] < abs_min_val) abs_min_val = mins[i, j]
        }
        
        # Calcula as médias finais
        geral_mean = (file_count > 0) ? sum_total / file_count : 0
        avg_max    = (file_count > 0) ? sum_max / file_count : 0
        avg_min    = (file_count > 0) ? sum_min / file_count : 0
        avg_mean   = (file_count > 0) ? sum_mean / file_count : 0
        
        # Imprime a linha de resultado final para a métrica
        printf "%-18s\t%d\t%d\t%d\t%.2f\t%.2f\t%.2f\t%.2f\n", \
            d, sum_total, abs_max_val, abs_min_val, geral_mean, \
            avg_max, avg_min, avg_mean
    }
}
' > "$OUTPUT_FILE"

echo "Relatório global gerado com sucesso em: $OUTPUT_FILE"