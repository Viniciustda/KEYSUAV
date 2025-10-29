#!/bin/bash

# ==============================================================================
# 20-1_runEffectiveMim.sh
#
# Script chamador que encontra todas as subpastas e executa o script 
# trabalhador '20-2_effectiveMim.sh' para cada uma em paralelo.
# ==============================================================================

echo "Iniciando a verificação de eficácia do ataque MiM em paralelo..."

# Detecta o número de núcleos de CPU para otimizar a paralelização
NUM_CORES=$(nproc)
echo "Utilizando até ${NUM_CORES} núcleos de CPU."
echo "-------------------------------------------------------------"

WORKER_SCRIPT="20-2_effectiveMim.sh"

# Garante que o script trabalhador seja executável
if [ -f "$WORKER_SCRIPT" ]; then
    chmod +x "$WORKER_SCRIPT"
else
    echo "Erro: O script trabalhador '$WORKER_SCRIPT' não foi encontrado."
    exit 1
fi

# Encontra todas as subpastas e as envia para o xargs para processamento paralelo
find . -maxdepth 1 -mindepth 1 -type d | xargs -P $NUM_CORES -I {} bash -c "
    echo \"==> Analisando a pasta: {}\"
    ./$WORKER_SCRIPT \"{}\"
    echo \"<== Análise concluída para a pasta: {}\"
"

echo "-------------------------------------------------------------"
echo "Verificação de eficácia concluída. Arquivos 'flysafe_MiM_effective_192.168.1.x.tx' gerados."