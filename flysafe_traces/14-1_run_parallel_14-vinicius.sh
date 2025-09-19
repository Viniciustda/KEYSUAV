#!/bin/bash

echo "Iniciando a execução paralela da etapa 14..."

# Detecta o número de núcleos de CPU
N_CORES=$(nproc)
echo "Utilizando até $N_CORES núcleos de CPU em paralelo."

# --- ÚNICA MUDANÇA É AQUI ---
# O nome do nosso novo script "worker"
WORKER_SCRIPT="14-2_parallel_worker-vinicius.sh"
# -----------------------------

# Encontra as subpastas de simulação e as envia para o xargs
find . -maxdepth 1 -type d -name '*_*' | xargs -P $N_CORES -I {} bash -c "
    echo '==> Iniciando processamento da pasta: {}'
    ./$WORKER_SCRIPT {}
    echo '<== Finalizado processamento da pasta: {}'
"

echo "Processamento paralelo da etapa 14 concluído!"