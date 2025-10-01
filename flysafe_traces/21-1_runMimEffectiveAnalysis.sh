#!/bin/bash

# ==============================================================================
# 21-1_runMimEffectiveAnalysis.sh
#
# Este script encontra todas as subpastas de simulação no diretório atual
# e executa o script trabalhador '21-2_mimEffectiveAnalysis.sh' para cada
# uma delas em paralelo, utilizando todos os núcleos de CPU disponíveis.
# ==============================================================================

echo "Iniciando a análise paralela dos traços de ataques Man-in-the-Middle..."

# Detecta o número de núcleos de CPU para otimizar a paralelização
NUM_CORES=$(nproc)
echo "Utilizando até ${NUM_CORES} núcleos de CPU."
echo "-------------------------------------------------------------"

# O nome do script "trabalhador" que fará a análise em cada pasta
WORKER_SCRIPT="21-2_mimEffectiveAnalysis.sh"

# Garante que o script trabalhador seja executável
if [ -f "$WORKER_SCRIPT" ]; then
    chmod +x "$WORKER_SCRIPT"
else
    echo "Erro: O script trabalhador '$WORKER_SCRIPT' não foi encontrado."
    exit 1
fi

# Encontra todas as subpastas no diretório atual e as envia para o xargs
# O xargs executa o script trabalhador para cada pasta, em paralelo (-P $NUM_CORES)
find . -maxdepth 1 -mindepth 1 -type d | xargs -P $NUM_CORES -I {} bash -c "
    # O {} é o placeholder para o caminho da pasta (ex: ./25092025_0957)
    echo \"==> Iniciando processamento da pasta: {}\"
    ./$WORKER_SCRIPT \"{}\"
    echo \"<== Finalizado processamento da pasta: {}\"
"

echo "-------------------------------------------------------------"
echo "Análise paralela concluída. Arquivos 'flysafe_MiM_effective.txt' gerados nas subpastas."