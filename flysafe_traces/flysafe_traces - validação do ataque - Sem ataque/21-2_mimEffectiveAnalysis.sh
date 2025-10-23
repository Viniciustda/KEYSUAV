#!/bin/bash

# ==============================================================================
# 21-2_mimEffectiveAnalysis.sh
#
# Script trabalhador que processa uma única subpasta de simulação.
# Recebe o caminho da pasta como primeiro argumento.
#
# 1. Procura por arquivos 'flysafe_MiM_effective_192.168.1.x.txt'.
# 2. Se não encontrar, ignora a pasta e encerra.
# 3. Se encontrar, soma os totais das colunas msgBroad, msgId e msgTrap.
# 4. Salva o resultado em 'flysafe_MiM_effective.txt' dentro da própria pasta.
# ==============================================================================

# Pega o nome da pasta do primeiro argumento da linha de comando
TARGET_FOLDER=$1

# Verifica se o argumento da pasta foi fornecido
if [ -z "$TARGET_FOLDER" ]; then
    echo "Erro: Nenhuma pasta alvo foi especificada."
    exit 1
fi

# Usando shopt e array para contar os arquivos de forma segura
shopt -s nullglob
FILES_TO_PROCESS=("$TARGET_FOLDER"/flysafe_MiM_effective_192.168.1.*.txt)
NUM_FILES=${#FILES_TO_PROCESS[@]}
shopt -u nullglob

OUTPUT_FILE="$TARGET_FOLDER/flysafe_MiM_effective.txt"

# Se não houver arquivos, ignora a pasta
if [ $NUM_FILES -eq 0 ]; then
    echo "Nenhum arquivo de trace MiM encontrado em '$TARGET_FOLDER'. Ignorando."
    exit 0
fi

# Arrays para armazenar os totais de cada drone (cada arquivo)
declare -a broad_sums
declare -a id_sums
declare -a trap_sums
declare -a total_sums

# Loop para processar cada arquivo e extrair os totais por drone
for file in "${FILES_TO_PROCESS[@]}"; do
    # Usa awk para somar as colunas 4, 5 e 6 de um único arquivo
    read b_sum i_sum t_sum < <(awk 'FNR > 1 {b+=$4; i+=$5; t+=$6} END {print b+0, i+0, t+0}' "$file")
    
    # Armazena os resultados nos arrays
    broad_sums+=($b_sum)
    id_sums+=($i_sum)
    trap_sums+=($t_sum)
    total_sums+=($(($b_sum + $i_sum + $t_sum)))
done

# Função para calcular estatísticas (total, max, min, mean) de um array de números
calculate_stats() {
    local -n arr=$1
    if [ ${#arr[@]} -eq 0 ]; then
        echo "0 0 0 0.00"
        return
    fi
    local total=0
    local max=0
    local min=${arr[0]}
    for val in "${arr[@]}"; do
        total=$(($total + $val))
        if (( $(echo "$val > $max" | bc -l) )); then max=$val; fi
        if (( $(echo "$val < $min" | bc -l) )); then min=$val; fi
    done
    if [ $NUM_FILES -lt 5 ]; then
        min=0
    fi
    local mean=0
    if [ ${#arr[@]} -gt 0 ]; then
        mean=$(echo "scale=2; $total / ${#arr[@]}" | bc)
    fi
    echo "$total $max $min $mean"
}

# Inicia a criação do arquivo de saída
{
    # Cabeçalho
    printf "%-18s\t%s\t%s\t%s\t%s\n" "Description" "total" "max" "min" "mean"

    # Para cada métrica, primeiro lemos os resultados para variáveis separadas
    # e depois usamos o printf. Isso evita erros de interpretação do shell.

    read -r total max min mean < <(calculate_stats total_sums)
    printf "%-18s\t%s\t%s\t%s\t%s\n" "Sent msgs" "$total" "$max" "$min" "$mean"

    read -r total max min mean < <(calculate_stats broad_sums)
    printf "%-18s\t%s\t%s\t%s\t%s\n" "Sent broad" "$total" "$max" "$min" "$mean"

    read -r total max min mean < <(calculate_stats id_sums)
    printf "%-18s\t%s\t%s\t%s\t%s\n" "Sent ident" "$total" "$max" "$min" "$mean"

    read -r total max min mean < <(calculate_stats trap_sums)
    printf "%-18s\t%s\t%s\t%s\t%s\n" "Sent trap" "$total" "$max" "$min" "$mean"

} > "$OUTPUT_FILE"