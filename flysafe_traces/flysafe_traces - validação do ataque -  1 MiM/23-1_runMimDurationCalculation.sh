#!/bin/bash

# ==============================================================================
# 23-1_runMimDurationCalculation.sh
#
# Script chamador que encontra todas as subpastas e executa o script 
# trabalhador '23-2_mimDurationCalculation.sh' para cada uma em paralelo.
# ==============================================================================

echo "Iniciando o cálculo de duração das mensagens MiM efetivas..."

NUM_CORES=$(nproc)
echo "Utilizando até ${NUM_CORES} núcleos de CPU."
echo "-------------------------------------------------------------"

WORKER_SCRIPT="23-2_mimDurationCalculation.sh"

if [ -f "$WORKER_SCRIPT" ]; then
    chmod +x "$WORKER_SCRIPT"
else
    echo "Erro: O script trabalhador '$WORKER_SCRIPT' não foi encontrado." >&2
    exit 1
fi

find . -maxdepth 1 -mindepth 1 -type d | xargs -P $NUM_CORES -I {} bash -c "
    echo \"==> Calculando durações na pasta: {}\"
    ./$WORKER_SCRIPT \"{}\"
    echo \"<== Cálculo de durações concluído para a pasta: {}\"
"

echo "-------------------------------------------------------------"
echo "Análise de duração concluída. Arquivos 'flysafe_MiM_effective...' atualizados."