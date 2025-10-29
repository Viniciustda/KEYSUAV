#!/bin/bash

# ==============================================================================
# 28-1_runAlteretedMessageRateNode.sh
#
# Script chamador que executa o cálculo da taxa de mensagens alteradas em 
# paralelo para cada subpasta de simulação.
# ==============================================================================

echo "Iniciando o cálculo de taxas de mensagens alteradas (em paralelo)..."

NUM_CORES=$(nproc)
echo "Utilizando até ${NUM_CORES} núcleos de CPU."
echo "-------------------------------------------------------------"

WORKER_SCRIPT="28-2_alteretedMessageRateNode.sh"

if [ -f "$WORKER_SCRIPT" ]; then
    chmod +x "$WORKER_SCRIPT"
else
    echo "Erro: O script trabalhador '$WORKER_SCRIPT' não foi encontrado." >&2
    exit 1
fi

find . -maxdepth 1 -mindepth 1 -type d | xargs -P $NUM_CORES -I {} bash -c "
    echo \"==> Calculando taxas para a pasta: {}\"
    ./$WORKER_SCRIPT \"{}\"
    echo \"<== Cálculo de taxas concluído para a pasta: {}\"
"

echo "-------------------------------------------------------------"
echo "Análise de taxas concluída."