#!/bin/bash
# ==============================================================================
# 29_globalAlteretedMessageRateNode.sh
#
# Script final que agrega todas as estatísticas de contagens e taxas,
# gerando dois relatórios globais na pasta 'flysafe_global_traces'.
# ==============================================================================

echo "Iniciando a geração dos relatórios globais de contagens e taxas..."

OUTPUT_DIR="flysafe_global_traces"
mkdir -p "$OUTPUT_DIR"

# --- TAREFA 1: Relatório Global de Contagens de Mensagens Alteradas ---

OUTPUT_FILE_COUNTS="$OUTPUT_DIR/global_MiM_altered_counts_nodes.txt"
INPUT_FILES_COUNTS=$(find . -mindepth 2 -name 'flysafe_MiM_altered_counts.txt')

echo "Processando estatísticas de CONTAGEM..."

if [ -z "$INPUT_FILES_COUNTS" ]; then
    echo "Nenhum arquivo 'altered_counts.txt' encontrado para processar."
else
    # Concatena todos os arquivos de contagem e os processa com awk
    LC_NUMERIC=C awk '
        # Ignora a linha de cabeçalho
        FNR > 1 {
            count++; # Conta quantos arquivos de simulação estamos processando
            
            # Acumula as somas de cada coluna para calcular as médias depois
            sum_total += $1;
            sum_max   += $2;
            sum_min   += $3;
            sum_mean  += $4;
            
            # Encontra o máximo dos máximos e o mínimo dos mínimos
            if (count == 1) {
                abs_max = $2;
                abs_min = $3;
            } else {
                if ($2 > abs_max) abs_max = $2;
                if ($3 < abs_min) abs_min = $3;
            }
        }
        END {
            if (count > 0) {
                # O "mean" geral é a média das médias de cada simulação
                overall_mean = sum_mean / count;

                print "--- Valores Absolutos ---";
                printf "%-10s %d\n",   "total:", sum_total;      # Soma de todas as mensagens alteradas
                printf "%-10s %d\n",   "max:", abs_max;          # O maior valor da coluna "max" encontrado
                printf "%-10s %d\n",   "min:", abs_min;          # O menor valor da coluna "min" encontrado
                printf "%-10s %.2f\n", "mean:", overall_mean;     # A média das médias por nó

                print ""; # Linha em branco para separar
                
                print "--- Média das Estatísticas ---";
                printf "%-10s %.2f\n", "avgTotal:", sum_total / count; # Média da coluna "total"
                printf "%-10s %.2f\n", "avgMax:", sum_max / count;     # Média da coluna "max"
                printf "%-10s %.2f\n", "avgMin:", sum_min / count;     # Média da coluna "min"
                printf "%-10s %.2f\n", "avgMean:", overall_mean;       # Média da coluna "mean"
            } else {
                print "Nenhum dado encontrado.";
            }
        }
    ' $(echo $INPUT_FILES_COUNTS) > "$OUTPUT_FILE_COUNTS"
    
    echo "Relatório global de contagens gerado em: $OUTPUT_FILE_COUNTS"
fi

echo "---"

# --- TAREFA 2: Relatório Global de Taxas de Mensagens Alteradas ---

OUTPUT_FILE_RATES="$OUTPUT_DIR/global_MiM_altered_rates_nodes.txt"
INPUT_FILES_RATES=$(find . -mindepth 2 -name 'flysafe_MiM_altered_rates.txt')

echo "Processando estatísticas de TAXAS..."

if [ -z "$INPUT_FILES_RATES" ]; then
    echo "Nenhum arquivo 'altered_rates.txt' encontrado para processar."
else
    # A lógica é a mesma, mas para as colunas do arquivo de taxas
    LC_NUMERIC=C awk '
        FNR > 1 {
            count++;
            
            sum_max   += $1;
            sum_min   += $2;
            sum_mean  += $3;
            
            if (count == 1) {
                abs_max = $1;
                abs_min = $2;
            } else {
                if ($1 > abs_max) abs_max = $1;
                if ($2 < abs_min) abs_min = $2;
            }
        }
        END {
            if (count > 0) {
                overall_mean = sum_mean / count;

                print "--- Valores Absolutos ---";
                printf "%-10s %.4f\n", "max:", abs_max;
                printf "%-10s %.4f\n", "min:", abs_min;
                printf "%-10s %.4f\n", "mean:", overall_mean;

                print "";
                
                print "--- Média das Estatísticas ---";
                printf "%-10s %.4f\n", "avgMax:", sum_max / count;
                printf "%-10s %.4f\n", "avgMin:", sum_min / count;
                printf "%-10s %.4f\n", "avgMean:", overall_mean;
            } else {
                print "Nenhum dado encontrado.";
            }
        }
    ' $(echo $INPUT_FILES_RATES) > "$OUTPUT_FILE_RATES"
    
    echo "Relatório global de taxas gerado em: $OUTPUT_FILE_RATES"
fi

echo "-------------------------------------------------------------"
echo "Geração de relatórios globais concluída."