#!/bin/bash
# ==============================================================================
# 28-2_alteretedMessageRateNode.sh (v2 - Corrigido para Broadcast)
#
# Script trabalhador que, para uma única pasta:
# 1. Pré-processa os arquivos 'effective' para expandir broadcasts
#    em múltiplas entradas unicast.
# 2. Calcula as estatísticas sobre a CONTAGEM de mensagens alteradas por nó.
# 3. Calcula as estatísticas sobre a TAXA de mensagens alteradas por nó.
# ==============================================================================

TARGET_FOLDER=$1
if [ -z "$TARGET_FOLDER" ]; then
    echo "Erro: Nenhuma pasta alvo foi especificada." >&2
    exit 1
fi

# Garante que a pasta termine com /
[[ "$TARGET_FOLDER" != */ ]] && TARGET_FOLDER="$TARGET_FOLDER"/

NUM_NODES=40 # Número de nós para o loop de broadcast

shopt -s nullglob
EFFECTIVE_FILES=("$TARGET_FOLDER"flysafe_MiM_effective_192.168.1.*.txt)
shopt -u nullglob

if [ ${#EFFECTIVE_FILES[@]} -eq 0 ]; then
    echo "Nenhum arquivo 'effective' encontrado em '$TARGET_FOLDER'. Ignorando."
    exit 0
fi

# Nomes dos arquivos de saída
OUTPUT_FILE_COUNTS="$TARGET_FOLDER/flysafe_MiM_altered_counts.txt"
OUTPUT_FILE_RATES="$TARGET_FOLDER/flysafe_MiM_altered_rates.txt"

# Arquivos temporários
TEMP_EXPANDED_RECEIVERS=$(mktemp) # NOVO: Para a lista de IPs expandida
TEMP_COUNTS_PER_NODE=$(mktemp)
TEMP_RATES=$(mktemp)


# --- ETAPA 0.5: PRÉ-PROCESSAMENTO (Expandir Broadcasts) ---
# Lê os arquivos 'effective', e para cada linha, determina
# o(s) receptor(es) real(is) e imprime o IP na lista temporária.
# echo "Passo 0.5: Expandindo broadcasts..."
LC_NUMERIC=C awk -v folder="$TARGET_FOLDER" -v num_nodes="$NUM_NODES" -F'\t+' '
    FNR > 1 {
        # $5 é receiverIP, $2 é sender_ip, $9 é forgedPosition
        receiver_ip = $5;
        sender_ip = $2;
        forged_pos = $9;
        
        gsub(/[[:space:]]+/, "", forged_pos);
        search_string = sender_ip "," forged_pos;

        if (receiver_ip == "255.255.255.255") {
            # BROADCAST: Procura em todos os 40 arquivos de nó
            for (i = 1; i <= num_nodes; i++) {
                neighborhood_file = folder "/neighborhood_evolution_192.168.1." i ".txt";
                
                # system(grep) é mais simples aqui do que ler o arquivo
                cmd = "grep -qF \"" search_string "\" \"" neighborhood_file "\"";
                
                if (system(cmd) == 0) {
                    # Encontrou! Imprime o IP do nó que recebeu
                    print "192.168.1." i;
                }
            }
        } else {
            # UNICAST: Apenas imprime o IP do receptor original
            print receiver_ip;
        }
    }
' "${EFFECTIVE_FILES[@]}" > "$TEMP_EXPANDED_RECEIVERS"


# --- ETAPA 1: Contar mensagens alteradas por nó ---
# MODIFICADO: Em vez de ler os ${EFFECTIVE_FILES[@]},
# lemos o arquivo temporário que acabamos de criar.
# echo "Passo 1: Contando mensagens alteradas por nó..."
cat "$TEMP_EXPANDED_RECEIVERS" | sort | uniq -c | awk '{print $2, $1}' > "$TEMP_COUNTS_PER_NODE"

# --- ETAPA 2: Gerar o relatório de CONTAGENS ---
# (O código original é mantido. Nenhuma alteração necessária)
# echo "Passo 2: Calculando estatísticas de contagem..."
LC_NUMERIC=C awk '
    {
        count = $2; # A contagem é a segunda coluna do nosso arquivo temporário
        total += count;
        num_nodes++;
        if (NR == 1) { max = count; min = count; }
        if (count > max) max = count;
        if (count < min) min = count;
    }
    END {
        if (num_nodes > 0) {
            mean = total / num_nodes;
            print "total\tmax\t\tmin\t\tmean";
            printf "%.0f\t\t%.0f\t\t%.0f\t\t%.2f\n", total, max, min, mean;
        } else {
            print "total\tmax\tmin\tmean";
            print "0\t\t0\t\t0\t\t0.00";
        }
    }
' "$TEMP_COUNTS_PER_NODE" > "$OUTPUT_FILE_COUNTS"


# --- ETAPA 3: Gerar o relatório de TAXAS ---
# (O código original é mantido. Nenhuma alteração necessária)
# echo "Passo 3: Calculando estatísticas de taxas..."

# Lemos o arquivo de contagens por nó linha por linha
while read -r node altered_count; do
    total_received_file="$TARGET_FOLDER/messages_received_${node}.txt"

    if [ ! -f "$total_received_file" ]; then
        echo "Aviso: Arquivo '$total_received_file' não encontrado. Nó $node ignorado para cálculo de taxa."
        continue
    fi
    
    # Conta as linhas não-vazias e subtrai 1 (cabeçalho)
    total_lines=$(grep -c . "$total_received_file")
    total_count=$(( total_lines > 0 ? total_lines - 1 : 0 ))

    if [ $total_count -le 0 ]; then
        rate="0"
    else
        rate=$(LC_NUMERIC=C echo "scale=4; $altered_count / $total_count" | bc)
    fi
    
    # Salva a taxa calculada no arquivo temporário de taxas
    echo "$rate" >> "$TEMP_RATES"
    
done < "$TEMP_COUNTS_PER_NODE"

# Agora, usamos awk para calcular as estatísticas do arquivo de taxas
LC_NUMERIC=C awk '
    {
        rate = $1;
        sum += rate;
        num_rates++;
        if (NR == 1) { max = rate; min = rate; }
        if (rate > max) max = rate;
        if (rate < min) min = rate;
    }
    END {
        if (num_rates > 0) {
            mean = sum / num_rates;
            print "max\t\tmin\t\tmean";
            printf "%.4f\t%.4f\t%.4f\n", max, min, mean;
        } else {
            print "max\t\tmin\t\tmean";
            print "0.0000\t0.0000\t0.0000";
        }
    }
' "$TEMP_RATES" > "$OUTPUT_FILE_RATES"


# --- ETAPA 4: Limpeza ---
# Remove os arquivos temporários
rm "$TEMP_COUNTS_PER_NODE" "$TEMP_RATES" "$TEMP_EXPANDED_RECEIVERS"

# echo "Arquivos de estatísticas gerados."