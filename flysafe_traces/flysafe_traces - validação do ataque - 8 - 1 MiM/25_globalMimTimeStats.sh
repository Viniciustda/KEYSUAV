#!/bin/bash
# ==============================================================================
# 25_globalMimTimeStats.sh
#
# Script final que agrega todas as estatísticas de tempo dos arquivos
# gerados pelo script 24-2.
#
# Ele cria dois relatórios globais na pasta 'flysafe_global_traces':
# 1. global_MiM_message_active_time.txt: Estatísticas globais por mensagem.
# 2. global_flysafe_MiM_node_storage_time.txt: Estatísticas globais por nó.
# ==============================================================================

echo "Iniciando a geração dos relatórios de estatísticas globais..."

OUTPUT_DIR="flysafe_global_traces"
mkdir -p "$OUTPUT_DIR"

# --- TAREFA 1: Relatório Global de Estatísticas por Mensagem ---

OUTPUT_FILE_MSG="$OUTPUT_DIR/global_MiM_message_active_time.txt"
INPUT_FILES_MSG=$(find . -mindepth 2 -name 'flysafe_MiM_message_active_time.txt')

# echo "Processando estatísticas por mensagem..."

if [ -z "$INPUT_FILES_MSG" ]; then
    echo "Nenhum arquivo 'message_active_time.txt' encontrado para processar."
else
    # Concatena todos os arquivos de entrada e os processa com um único awk
    LC_NUMERIC=C awk '
        # Ignora a linha de cabeçalho
        FNR > 1 {
            # $1 é max, $2 é min, $3 é mean daquele arquivo
            sum_of_maxes += $1
            sum_of_mins  += $2
            sum_of_means += $3
            count++
            
            # Encontra o máximo dos máximos e o mínimo dos mínimos
            if (count == 1) {
                abs_max = $1
                abs_min = $2
            } else {
                if ($1 > abs_max) abs_max = $1
                if ($2 < abs_min) abs_min = $2
            }
        }
        END {
            if (count > 0) {
                # A "média geral" mais representativa que podemos calcular aqui é a média das médias
                overall_mean = sum_of_means / count
                
                print "--- Valores Absolutos ---"
                printf "%-10s %.3f\n", "max:", abs_max
                printf "%-10s %.3f\n", "min:", abs_min
                printf "%-10s %.3f\n", "mean:", overall_mean
                
                print "" # Linha em branco para separar
                
                print "--- Média das Estatísticas ---"
                printf "%-10s %.3f\n", "avgMax:", sum_of_maxes / count
                printf "%-10s %.3f\n", "avgMin:", sum_of_mins / count
                printf "%-10s %.3f\n", "avgMean:", overall_mean
            } else {
                print "Nenhum dado encontrado."
            }
        }
    ' $(echo $INPUT_FILES_MSG) > "$OUTPUT_FILE_MSG"
    
    echo "Relatório global por mensagem gerado em: $OUTPUT_FILE_MSG"
fi

echo "---"

# --- TAREFA 2: Relatório Global de Estatísticas por Nó ---

OUTPUT_FILE_NODE="$OUTPUT_DIR/global_flysafe_MiM_node_storage_time.txt"
INPUT_FILES_NODE=$(find . -mindepth 2 -name 'flysafe_MiM_node_storage_time.txt')

# echo "Processando estatísticas por nó..."

if [ -z "$INPUT_FILES_NODE" ]; then
    echo "Nenhum arquivo 'node_storage_time.txt' encontrado para processar."
else
    # A lógica awk é idêntica à anterior, apenas aplicada aos arquivos de estatísticas de nó
    LC_NUMERIC=C awk '
        FNR > 1 {
            sum_of_maxes += $1
            sum_of_mins  += $2
            sum_of_means += $3
            count++
            
            if (count == 1) {
                abs_max = $1
                abs_min = $2
            } else {
                if ($1 > abs_max) abs_max = $1
                if ($2 < abs_min) abs_min = $2
            }
        }
        END {
            if (count > 0) {
                overall_mean = sum_of_means / count
                
                print "--- Valores Absolutos ---"
                printf "%-10s %.3f\n", "max:", abs_max
                printf "%-10s %.3f\n", "min:", abs_min
                printf "%-10s %.3f\n", "mean:", overall_mean

                print ""
                
                print "--- Média das Estatísticas ---"
                printf "%-10s %.3f\n", "avgMax:", sum_of_maxes / count
                printf "%-10s %.3f\n", "avgMin:", sum_of_mins / count
                printf "%-10s %.3f\n", "avgMean:", overall_mean
            } else {
                print "Nenhum dado encontrado."
            }
        }
    ' $(echo $INPUT_FILES_NODE) > "$OUTPUT_FILE_NODE"
    
    echo "Relatório global por nó gerado em: $OUTPUT_FILE_NODE"
fi

echo "-------------------------------------------------------------"
echo "Geração de relatórios globais concluída."