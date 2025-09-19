#!/bin/bash

# Este é o script "worker", uma versão modificada do script 13.
# Ele aceita o nome da pasta a ser processada como um argumento.

# MODIFICAÇÃO 1: Validar se o nome da pasta foi passado como argumento
TARGET_DIR=$1
if [ -z "$TARGET_DIR" ]; then
    echo "Erro: O nome do diretório alvo não foi fornecido."
    exit 1
fi

# Usa um nome de arquivo temporário único para evitar conflitos
TEMP_FILE="_traceFiles_$$"

#: <<'COMMENT0'
IPFile="spatial_no_awareness_192.168.1.*"

# MODIFICAÇÃO 2: O comando 'find' agora busca APENAS dentro da pasta alvo
find "$TARGET_DIR" -name $IPFile  > $TEMP_FILE

cat $TEMP_FILE | while read line
do
	# O resto deste bloco (análise Rx e Tx) permanece o mesmo do script original...
	dateTime=${line:2:13}
	fileLength=${#line}
	if [ $fileLength == "52" ]; then
		nodeNumber=${line:47:1}
	else
		if [ $fileLength == "53" ]; then
			nodeNumber=${line:47:2}
		else
			nodeNumber=${line:47:3}
		fi
	fi

	#***************************************************************************************************
	# Received messages analysis (CÓDIGO IDÊNTICO AO SCRIPT 13 ORIGINAL)
	#***************************************************************************************************
	rxAwareFile="./"$dateTime"/rounds_rx_achieve_spatial_awareness_analysis_192.168.1."$nodeNumber".txt"
	echo -e "sTime\teTime\tdur\tnMsg\tnBroad\tnId\tnTrap" >> $rxAwareFile
	nLines=$(wc -l < $line)
	for i in $(seq 2 $nLines)
	do
		nRxMsg=0; nTrap=0; nBroad=0; nId=0
		fileLine=$(sed $i'q;d' $line)
		startTime=$(echo $fileLine | cut -d ' ' -f 1)
		endTime=$(echo $fileLine | cut -d ' ' -f 2)
		rxFile="./"$dateTime"/messages_received_192.168.1."$nodeNumber".txt"
		nRxLines=$(wc -l < $rxFile)
		for j in $(seq 2 $nRxLines)
		do
			rxFileLine=$(sed $j'q;d' $rxFile)
			rxTime=$(echo $rxFileLine | cut -d ' ' -f 1)
			rxMsg=$(echo $rxFileLine | cut -d ' ' -f 3)
			if (( $(echo "$rxTime >= $startTime && $rxTime <= $endTime" |bc -l) )); then
				nRxMsg=$((nRxMsg + 1))
				if [ $rxMsg == "0" ]; then nBroad=$((nBroad + 1));
				elif [ $rxMsg == "1" ]; then nId=$((nId + 1));
				else nTrap=$((nTrap + 1)); fi
			elif (( $(echo "$rxTime > $endTime" |bc -l) )); then
				break
			fi
		done
		if (( $(echo "$nRxMsg > 0" |bc -l) )); then
			duration=$(bc <<< "$endTime-$startTime")
			echo -e $startTime"\t"$endTime"\t"$duration"\t"$nRxMsg"\t"$nBroad"\t"$nId"\t"$nTrap >> $rxAwareFile
		fi
	done

	#***************************************************************************************************
	# Transmitted messages analysis (CÓDIGO IDÊNTICO AO SCRIPT 13 ORIGINAL)
	#***************************************************************************************************
	txAwareFile="./"$dateTime"/rounds_tx_achieve_spatial_awareness_analysis_192.168.1."$nodeNumber".txt"
	echo -e "sTime\teTime\tdur\tnMsg\tnBroad\tnId\tnTrap" >> $txAwareFile
	nLines=$(wc -l < $line)
	for i in $(seq 2 $nLines)
	do
		nTxMsg=0; nTrap=0; nBroad=0; nId=0
		fileLine=$(sed $i'q;d' $line)
		startTime=$(echo $fileLine | cut -d ' ' -f 1)
		endTime=$(echo $fileLine | cut -d ' ' -f 2)
		txFile="./"$dateTime"/messages_sent_192.168.1."$nodeNumber".txt"
		nTxLines=$(wc -l < $txFile)
		for j in $(seq 2 $nTxLines)
		do
			txFileLine=$(sed $j'q;d' $txFile)
			txTime=$(echo $txFileLine | cut -d ' ' -f 1)
			txMsg=$(echo $txFileLine | cut -d ' ' -f 3)
			if (( $(echo "$txTime >= $startTime && $txTime <= $endTime" |bc -l) )); then
				nTxMsg=$((nTxMsg + 1))
				if [ $txMsg == "0" ]; then nBroad=$((nBroad + 1));
				elif [ $txMsg == "1" ]; then nId=$((nId + 1));
				else nTrap=$((nTrap + 1)); fi
			elif (( $(echo "$txTime > $endTime" |bc -l) )); then
				break
			fi
		done
		if (( $(echo "$nTxMsg > 0" |bc -l) )); then
			duration=$(bc <<< "$endTime-$startTime")
			echo -e $startTime"\t"$endTime"\t"$duration"\t"$nTxMsg"\t"$nBroad"\t"$nId"\t"$nTrap >> $txAwareFile
		fi
	done
done
[ -e $TEMP_FILE ] && rm $TEMP_FILE
#COMMENT0

#***************************************************************************************************
# Resume all date in only one file for each node
#***************************************************************************************************
noAwareFile="spatial_no_awareness_192.168.1.*"

# MODIFICAÇÃO 3: O comando 'find' aqui também busca APENAS dentro da pasta alvo
find "$TARGET_DIR" -name $noAwareFile  > $TEMP_FILE

cat $TEMP_FILE | while read line
do
	# O resto deste bloco (resumo dos dados) permanece o mesmo do script original...
	dateTime=${line:2:13}
	fileLength=${#line}
	if [ $fileLength == "52" ]; then
		nodeNumber=${line:47:1}
	else
		if [ $fileLength == "53" ]; then
			nodeNumber=${line:47:2}
		else
			nodeNumber=${line:47:3}
		fi
	fi
	awareGlobal="./"$dateTime"/rounds_achieve_aware_analysis_192.168.1."$nodeNumber".txt"
	headerTx="sTime\teTime\tdur\tnTM\tnTB\tnTI\tnTT"
	headerRx="nRM\tnRB\tnRI\tnRT\tnTM"
	echo -e $headerTx"\t"$headerRx >> $awareGlobal
	rxFile="./"$dateTime"/rounds_rx_achieve_spatial_awareness_analysis_192.168.1."$nodeNumber".txt"
	txFile="./"$dateTime"/rounds_tx_achieve_spatial_awareness_analysis_192.168.1."$nodeNumber".txt"
	nLines=$(wc -l < $line)
	for k in $(seq 2 $nLines)
	do
		nRxMsg=0; nRxBroad=0; nRxId=0; nRxTrap=0
		nTxMsg=0; nTxBroad=0; nTxId=0; nTxTrap=0
		noAwareLine=$(sed $k'q;d' $line)
		startTime=$(echo $noAwareLine | cut -d ' ' -f 1)
		endTime=$(echo $noAwareLine | cut -d ' ' -f 2)
		duration=$(echo $noAwareLine | cut -d ' ' -f 3)
		
		# Procura pela linha correspondente no arquivo RX
		matchLineRx=$(grep "^$startTime" $rxFile)
		if [ ! -z "$matchLineRx" ]; then
			nRxMsg=$(echo $matchLineRx | cut -d ' ' -f 4)
			nRxBroad=$(echo $matchLineRx | cut -d ' ' -f 5)
			nRxId=$(echo $matchLineRx | cut -d ' ' -f 6)
			nRxTrap=$(echo $matchLineRx | cut -d ' ' -f 7)
		fi
		
		# Procura pela linha correspondente no arquivo TX
		matchLineTx=$(grep "^$startTime" $txFile)
		if [ ! -z "$matchLineTx" ]; then
			nTxMsg=$(echo $matchLineTx | cut -d ' ' -f 4)
			nTxBroad=$(echo $matchLineTx | cut -d ' ' -f 5)
			nTxId=$(echo $matchLineTx | cut -d ' ' -f 6)
			nTxTrap=$(echo $matchLineTx | cut -d ' ' -f 7)
		fi
		
		nTotalMsg=$(bc <<< "$nRxMsg+$nTxMsg")
		lineTx=$startTime"\t"$endTime"\t"$duration"\t"$nTxMsg"\t"$nTxBroad"\t"$nTxId"\t"$nTxTrap
		lineRx=$nRxMsg"\t"$nRxBroad"\t"$nRxId"\t"$nRxTrap"\t"$nTotalMsg
		echo -e $lineTx"\t"$lineRx >> $awareGlobal
	done
done
[ -e $TEMP_FILE ] && rm $TEMP_FILE