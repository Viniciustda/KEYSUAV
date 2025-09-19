#!/bin/bash

# -----------------------------------------------------------------------------
# WORKER SCRIPT para a Etapa 14.
#
# Aceita o nome de uma pasta de simulação como argumento e realiza a análise
# de "keep spatial awareness" apenas dentro daquela pasta.
#
# Este script foi projetado para ser chamado em paralelo pelo
# '14-1_run_parallel_14-vinicius.sh'.
#
# Baseado no script original '14_roundsKeepAwarenessNodeAnalysis.sh' e
# otimizado com as mesmas técnicas do '13-2_parallel_worker-vinicius.sh'.
# -----------------------------------------------------------------------------

# MODIFICAÇÃO 1: Validar se o nome da pasta foi passado como argumento
TARGET_DIR=$1
if [ -z "$TARGET_DIR" ]; then
    echo "Erro: O nome do diretório alvo não foi fornecido."
    exit 1
fi

# Usa um nome de arquivo temporário único para evitar conflitos
TEMP_FILE="_traceFiles_$$"

#: <<'COMMENT0'
IPFile="spatial_awareness_192.168.1.*"

# MODIFICAÇÃO 2: O comando 'find' agora busca APENAS dentro da pasta alvo
find "$TARGET_DIR" -name $IPFile > $TEMP_FILE

cat $TEMP_FILE | while read line # get each file of one specific node
do
	# A extração de 'dateTime' e 'nodeNumber' permanece a mesma
	dateTime=${line:2:13}
	fileLength=${#line}
	if [ $fileLength == "49" ]; then
		nodeNumber=${line:44:1}
	else
		if [ $fileLength == "50" ]; then
			nodeNumber=${line:44:2}
		else
			nodeNumber=${line:44:3}
		fi
	fi

	#***************************************************************************************************
	# Received messages analysis (Lógica idêntica ao script 14 original)
	#***************************************************************************************************
	rxAwareFile="./"$dateTime"/rounds_rx_keep_spatial_awareness_analysis_192.168.1."$nodeNumber".txt"
	echo -e "sTime\teTime\tdur\tnMsg\tnBroad\tnId\tnTrap" > $rxAwareFile # Usar > para criar/sobrescrever o arquivo
	nLines=$(wc -l < $line)
	for i in $(seq 2 $nLines)
	do
		nRxMsg=0; nTrap=0; nBroad=0; nId=0
		fileLine=$(sed -n ${i}p $line)
		startTime=$(echo $fileLine | cut -d ' ' -f 1)
		endTime=$(echo $fileLine | cut -d ' ' -f 2)
		rxFile="./"$dateTime"/messages_received_192.168.1."$nodeNumber".txt"
		
        # Otimização: ler o arquivo de mensagens apenas uma vez
        if [ -f "$rxFile" ]; then
            tail -n +2 "$rxFile" | while read -r rxFileLine; do
                rxTime=$(echo $rxFileLine | cut -d ' ' -f 1)
                rxMsg=$(echo $rxFileLine | cut -d ' ' -f 3)

                # Se o tempo da msg for maior que o tempo final, podemos parar de procurar
                if (( $(echo "$rxTime > $endTime" | bc -l) )); then
                    break
                fi

                if (( $(echo "$rxTime >= $startTime && $rxTime <= $endTime" | bc -l) )); then
                    nRxMsg=$((nRxMsg + 1))
                    if [ "$rxMsg" == "0" ]; then #broadcast
                        nBroad=$((nBroad + 1))
                    elif [ "$rxMsg" == "1" ]; then #id
                        nId=$((nId + 1))
                    else # trap
                        nTrap=$((nTrap + 1))
                    fi
                fi
            done
        fi

		if (( $(echo "$nRxMsg > 0" |bc -l) )); then
			duration=$(bc <<< "$endTime-$startTime")
			echo -e "$startTime\t$endTime\t$duration\t$nRxMsg\t$nBroad\t$nId\t$nTrap" >> $rxAwareFile
		fi
	done
	
	#***************************************************************************************************
	# Transmitted messages analysis (Lógica idêntica ao script 14 original)
	#***************************************************************************************************
	txAwareFile="./"$dateTime"/rounds_tx_keep_spatial_awareness_analysis_192.168.1."$nodeNumber".txt"
	echo -e "sTime\teTime\tdur\tnMsg\tnBroad\tnId\tnTrap" > $txAwareFile # Usar > para criar/sobrescrever
	nLines=$(wc -l < $line)
	for i in $(seq 2 $nLines)
	do
		nTxMsg=0; nTrap=0; nBroad=0; nId=0
		fileLine=$(sed -n ${i}p $line)
		startTime=$(echo $fileLine | cut -d ' ' -f 1)
		endTime=$(echo $fileLine | cut -d ' ' -f 2)
		txFile="./"$dateTime"/messages_sent_192.168.1."$nodeNumber".txt"
		
        # Otimização: ler o arquivo de mensagens apenas uma vez
        if [ -f "$txFile" ]; then
            tail -n +2 "$txFile" | while read -r txFileLine; do
                txTime=$(echo $txFileLine | cut -d ' ' -f 1)
                txMsg=$(echo $txFileLine | cut -d ' ' -f 3)

                if (( $(echo "$txTime > $endTime" | bc -l) )); then
                    break
                fi

                if (( $(echo "$txTime >= $startTime && $txTime <= $endTime" | bc -l) )); then
                    nTxMsg=$((nTxMsg + 1))
                    if [ "$txMsg" == "0" ]; then #broadcast
                        nBroad=$((nBroad + 1))
                    elif [ "$txMsg" == "1" ]; then #id
                        nId=$((nId + 1))
                    else # trap
                        nTrap=$((nTrap + 1))
                    fi
                fi
            done
        fi

		if (( $(echo "$nTxMsg > 0" |bc -l) )); then
			duration=$(bc <<< "$endTime-$startTime")
			echo -e "$startTime\t$endTime\t$duration\t$nTxMsg\t$nBroad\t$nId\t$nTrap" >> $txAwareFile
		fi
	done
done

[ -e $TEMP_FILE ] && rm $TEMP_FILE
#COMMENT0

#***************************************************************************************************
# Resume all data in only one file for each node
#***************************************************************************************************
noAwareFile="spatial_awareness_192.168.1.*"

# MODIFICAÇÃO 3: O comando 'find' aqui também busca APENAS dentro da pasta alvo
find "$TARGET_DIR" -name $noAwareFile > $TEMP_FILE

cat $TEMP_FILE | while read line # get each file of one specific node
do
	dateTime=${line:2:13}
	fileLength=${#line}
	if [ $fileLength == "49" ]; then
		nodeNumber=${line:44:1}
	else
		if [ $fileLength == "50" ]; then
			nodeNumber=${line:44:2}
		else
			nodeNumber=${line:44:3}
		fi
	fi

	awareGlobal="./"$dateTime"/rounds_keep_aware_analysis_192.168.1."$nodeNumber".txt"
	headerTx="sTime\teTime\tdur\tnTM\tnTB\tnTI\tnTT"
	headerRx="nRM\tnRB\tnRI\tnRT\tnTM"
	echo -e "$headerTx\t$headerRx" > $awareGlobal # Usar > para criar/sobrescrever

	rxFile="./"$dateTime"/rounds_rx_keep_spatial_awareness_analysis_192.168.1."$nodeNumber".txt"
	txFile="./"$dateTime"/rounds_tx_keep_spatial_awareness_analysis_192.168.1."$nodeNumber".txt"

	nLines=$(wc -l < $line)
	for k in $(seq 2 $nLines)
	do
        # Zera as variáveis para cada linha do arquivo principal
        nRxMsg=0; nRxBroad=0; nRxId=0; nRxTrap=0
        nTxMsg=0; nTxBroad=0; nTxId=0; nTxTrap=0

		keepAwareLine=$(sed -n ${k}p $line)
		startTime=$(echo $keepAwareLine | cut -d ' ' -f 1)
		endTime=$(echo $keepAwareLine | cut -d ' ' -f 2)
		duration=$(echo $keepAwareLine | cut -d ' ' -f 3)

		# MODIFICAÇÃO 4 (OTIMIZAÇÃO): Usa grep para encontrar a linha correspondente no arquivo RX
		if [ -f "$rxFile" ]; then
			matchLineRx=$(grep "^$startTime" "$rxFile")
			if [ ! -z "$matchLineRx" ]; then
				nRxMsg=$(echo $matchLineRx | cut -d ' ' -f 4)
				nRxBroad=$(echo $matchLineRx | cut -d ' ' -f 5)
				nRxId=$(echo $matchLineRx | cut -d ' ' -f 6)
				nRxTrap=$(echo $matchLineRx | cut -d ' ' -f 7)
			fi
		fi
		
		# MODIFICAÇÃO 4 (OTIMIZAÇÃO): Usa grep para encontrar a linha correspondente no arquivo TX
		if [ -f "$txFile" ]; then
			matchLineTx=$(grep "^$startTime" "$txFile")
			if [ ! -z "$matchLineTx" ]; then
				nTxMsg=$(echo $matchLineTx | cut -d ' ' -f 4)
				nTxBroad=$(echo $matchLineTx | cut -d ' ' -f 5)
				nTxId=$(echo $matchLineTx | cut -d ' ' -f 6)
				nTxTrap=$(echo $matchLineTx | cut -d ' ' -f 7)
			fi
		fi

		nTotalMsg=$(bc <<< "$nRxMsg+$nTxMsg")

		lineTx="$startTime\t$endTime\t$duration\t$nTxMsg\t$nTxBroad\t$nTxId\t$nTxTrap"
		lineRx="$nRxMsg\t$nRxBroad\t$nRxId\t$nRxTrap\t$nTotalMsg"

		echo -e "$lineTx\t$lineRx" >> $awareGlobal
	done
done	

[ -e $TEMP_FILE ] && rm $TEMP_FILE