#!/bin/bash

# ==============================================================================
# 26-1_runNetworkContaminationTime.sh
#
# Script chamador que executa o cálculo de tempo de contaminação da rede
# em paralelo para cada subpasta de simulação.
# ==============================================================================

echo "Iniciando o cálculo do tempo de contaminação da rede (em paralelo)..."

NUM_CORES=$(nproc)
echo "Utilizando até ${NUM_CORES} núcleos de CPU."
echo "-------------------------------------------------------------"

WORKER_SCRIPT="26-2_networkContaminationTime.sh"

if [ -f "$WORKER_SCRIPT" ]; then
    chmod +x "$WORKER_SCRIPT"
else
    echo "Erro: O script trabalhador '$WORKER_SCRIPT' não foi encontrado." >&2
    exit 1
fi

find . -maxdepth 1 -mindepth 1 -type d | xargs -P $NUM_CORES -I {} bash -c "
    echo \"==> Calculando contaminação para a pasta: {}\"
    ./$WORKER_SCRIPT \"{}\"
    echo \"<== Cálculo concluído para a pasta: {}\"
"

echo "-------------------------------------------------------------"
echo "Cálculo de contaminação por pasta concluído."