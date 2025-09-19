#!/bin/bash

echo "Iniciando a execução paralela da etapa 13 (versão corrigida)..."

# Detecta o número de núcleos de CPU
N_CORES=$(nproc)
echo "Utilizando até $N_CORES núcleos de CPU em paralelo."

# O nome do novo script "worker"
WORKER_SCRIPT="13-2_parallelRoundsAchieveAwarenessNodeAnalysis.sh"

# Encontra as subpastas de simulação e as envia para o xargs
find . -maxdepth 1 -type d -name '*_*' | xargs -P $N_CORES -I {} bash -c "
    echo '==> Iniciando processamento da pasta: {}'
    ./$WORKER_SCRIPT {}
    echo '<== Finalizado processamento da pasta: {}'
"

echo "Processamento paralelo concluído!"