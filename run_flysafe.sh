#!/bin/bash

# --- Configurações ---
# Número total de vezes que a simulação será executada.
TOTAL_RUNS=35
# O comando exato da simulação. Coloque entre aspas.
SIM_COMMAND="./waf --run \"scratch/flysafe.cc -nNodes=40 -runMode=R -nMalicious=1 -defense=true\" > result.txt"
# Pasta onde os traços são salvos.
TRACES_DIR="flysafe_traces"


# --- Início do Script ---

# Garante que estamos no diretório correto do ns-3.34
# Se o script for salvo em ~/ns-allinone-3.34/ns-3.34/, esta linha não é estritamente necessária,
# mas é uma boa prática para garantir a execução no local certo.
cd "$(dirname "$0")"

echo "Iniciando a execução de $TOTAL_RUNS simulações..."
echo "----------------------------------------------------"

# Loop principal que executa a simulação N vezes
for i in $(seq 1 $TOTAL_RUNS)
do
    echo ">> [$(date +%T)] Iniciando simulação $i de $TOTAL_RUNS..."

    # 1. Executa o comando da simulação
    # Usamos `eval` para que as aspas dentro da string SIM_COMMAND sejam interpretadas corretamente.
    eval $SIM_COMMAND

    echo "   Simulação $i concluída. Movendo os arquivos de resultado..."

    # 2. Identifica a última pasta criada em flysafe_traces
    # ls -td: lista diretórios (*/) em ordem de modificação (t), mais recente primeiro.
    # head -n 1: pega apenas o primeiro item da lista (o mais recente).
    LATEST_DIR=$(ls -td "$TRACES_DIR"/*/ | head -n 1)

    # 3. Verifica se um diretório foi encontrado
    if [ -d "$LATEST_DIR" ]; then
        # 4. Move o result.txt e todos os arquivos .pcap para o diretório encontrado
        mv result.txt "$LATEST_DIR"
        mv flysafe.xml "$LATEST_DIR"
        mv *.pcap "$LATEST_DIR"
        echo "   Arquivos movidos com sucesso para: $LATEST_DIR"
    else
        echo "   !! AVISO: Nenhum diretório de destino foi encontrado em '$TRACES_DIR'. Os arquivos não foram movidos."
    fi

    echo "----------------------------------------------------"
done

echo ">> Todas as $TOTAL_RUNS simulações foram concluídas."
