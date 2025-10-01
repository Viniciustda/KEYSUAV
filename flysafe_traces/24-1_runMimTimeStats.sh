#!/bin/bash

# ==============================================================================
# 24-1_runMimTimeStats.sh
#
# Script chamador que encontra todas as subpastas e executa o script 
# trabalhador '24-2_mimTimeStats.sh' para cada uma em paralelo.
# ==============================================================================

echo "Iniciando a geração de estatísticas de duração (em paralelo)..."

NUM_CORES=$(nproc)
echo "Utilizando até ${NUM_CORES} núcleos de CPU."
echo "-------------------------------------------------------------"

WORKER_SCRIPT="24-2_mimTimeStats.sh"

if [ -f "$WORKER_SCRIPT" ]; then
    chmod +x "$WORKER_SCRIPT"
else
    echo "Erro: O script trabalhador '$WORKER_SCRIPT' não foi encontrado." >&2
    exit 1
fi

find . -maxdepth 1 -mindepth 1 -type d | xargs -P $NUM_CORES -I {} bash -c "
    echo \"==> Gerando estatísticas para a pasta: {}\"
    ./$WORKER_SCRIPT \"{}\"
    echo \"<== Estatísticas concluídas para a pasta: {}\"
"

echo "-------------------------------------------------------------"
echo "Geração de estatísticas concluída."