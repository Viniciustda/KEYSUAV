#!/bin/bash
# ==============================================================================
# 27_globalNetworkContaminationTime.sh
#
# Agrega os resultados de todos os arquivos 'network_contamination_time.txt'
# e cria um relatório global com as estatísticas de max, min e mean.
# ==============================================================================

echo "Iniciando a geração do relatório global de contaminação da rede..."

OUTPUT_DIR="flysafe_global_traces"
OUTPUT_FILE="$OUTPUT_DIR/global_network_contamination_time.txt"
INPUT_FILES=$(find . -mindepth 2 -name 'network_contamination_time.txt')

mkdir -p "$OUTPUT_DIR"

if [ -z "$INPUT_FILES" ]; then
    echo "Nenhum arquivo 'network_contamination_time.txt' foi encontrado. Execute o script 26-1 primeiro."
    exit 1
fi

# Concatena todos os arquivos (cada um com uma linha/número) e calcula as estatísticas
LC_NUMERIC=C awk '
    {
        duration = $1;
        sum += duration;
        count++;
        
        if (count == 1) {
            min = duration;
            max = duration;
        } else {
            if (duration < min) min = duration;
            if (duration > max) max = duration;
        }
    }
    END {
        # Imprime o cabeçalho da tabela
        print "max\t\tmin\t\tmean";
        
        if (count > 0) {
            # Imprime a linha de dados com os valores calculados
            printf "%.3f\t%.3f\t%.3f\n", max, min, sum / count;
        } else {
            # Imprime uma linha de zeros se não houver dados
            print "0.000\t0.000\t0.000";
        }
    }
' $(echo $INPUT_FILES) > "$OUTPUT_FILE"

echo "Relatório global de contaminação gerado em: $OUTPUT_FILE"