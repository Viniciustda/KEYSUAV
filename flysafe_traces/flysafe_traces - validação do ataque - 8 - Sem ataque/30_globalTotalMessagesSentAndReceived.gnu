# -----------------------------------------------------------------------------
# Script 30: 30_globalTotalMessagesSentAndReceived.gnu
#
# Agrega os dados de contagem de mensagens de todas as execuções da simulação
# e calcula o min, max e média para cada tipo de mensagem.
#
# Execução: gnuplot 30_globalTotalMessagesSentAndReceived.gnu
# -----------------------------------------------------------------------------

# --- 1. Definição de Arquivos ---

# Arquivo de Saída
globalFile = './flysafe_global_traces/global_total_messages_sent_and_received.txt'

# Arquivos Temporários (um para cada tipo de mensagem)
tempBroad = "_temp_30_broad.txt"
tempIdent = "_temp_30_ident.txt"
tempTrap = "_temp_30_trap.txt"
tempSpecial = "_temp_30_special.txt"
tempSusp = "_temp_30_susp.txt"
tempBlock = "_temp_30_block.txt"
tempReduc = "_temp_30_reduc.txt"
tempTotal = "_temp_30_total.txt"

# --- 2. Extração de Dados ---
# Encontra todos os arquivos de entrada nas subpastas
findCommand = 'find . -maxdepth 2 -type f -name "total_messages_sent_and_received_*.txt"'
ListOfFiles = system(findCommand)

# Itera sobre cada arquivo encontrado e extrai os dados
do for [file in ListOfFiles] {
    # Extrai a linha de Broadcasts (FNR == 2) e salva cols 2 (sent) e 3 (recv)
    system(sprintf("awk 'FNR == 2 {print $2, $3}' %s >> %s", file, tempBroad))
    # Extrai a linha de Identification (FNR == 3)
    system(sprintf("awk 'FNR == 3 {print $2, $3}' %s >> %s", file, tempIdent))
    # Extrai a linha de Trap (FNR == 4)
    system(sprintf("awk 'FNR == 4 {print $2, $3}' %s >> %s", file, tempTrap))
    # Extrai a linha de SpecialId (FNR == 5)
    system(sprintf("awk 'FNR == 5 {print $2, $3}' %s >> %s", file, tempSpecial))
    # Extrai a linha de SuspNeighbors (FNR == 6)
    system(sprintf("awk 'FNR == 6 {print $2, $3}' %s >> %s", file, tempSusp))
    # Extrai a linha de BlockedNeighbor (FNR == 7)
    system(sprintf("awk 'FNR == 7 {print $2, $3}' %s >> %s", file, tempBlock))
    # Extrai a linha de SuspReduction (FNR == 8)
    system(sprintf("awk 'FNR == 8 {print $2, $3}' %s >> %s", file, tempReduc))
    # Extrai a linha de Total (FNR == 9)
    system(sprintf("awk 'FNR == 9 {print $2, $3}' %s >> %s", file, tempTotal))
}

# --- 3. Cálculo e Impressão das Estatísticas ---
set print globalFile
print "type\t\tminSent\tmaxSent\tavgSent\t\tminRecv\tmaxRecv\tavgRecv"

# Processa Broadcasts
stats tempBroad using 1 name "Sent" nooutput
stats tempBroad using 2 name "Recv" nooutput
print "Broadcasts\t", (floor(Sent_min*1e2)/1e2), "\t", (floor(Sent_max*1e2)/1e2), "\t", (floor(Sent_mean*1e2)/1e2), "\t\t", (floor(Recv_min*1e2)/1e2), "\t", (floor(Recv_max*1e2)/1e2), "\t", (floor(Recv_mean*1e2)/1e2)

# Processa Identification
stats tempIdent using 1 name "Sent" nooutput
stats tempIdent using 2 name "Recv" nooutput
print "Identification\t", (floor(Sent_min*1e2)/1e2), "\t", (floor(Sent_max*1e2)/1e2), "\t", (floor(Sent_mean*1e2)/1e2), "\t\t", (floor(Recv_min*1e2)/1e2), "\t", (floor(Recv_max*1e2)/1e2), "\t", (floor(Recv_mean*1e2)/1e2)

# Processa Trap
stats tempTrap using 1 name "Sent" nooutput
stats tempTrap using 2 name "Recv" nooutput
print "Trap\t\t", (floor(Sent_min*1e2)/1e2), "\t", (floor(Sent_max*1e2)/1e2), "\t", (floor(Sent_mean*1e2)/1e2), "\t\t", (floor(Recv_min*1e2)/1e2), "\t", (floor(Recv_max*1e2)/1e2), "\t", (floor(Recv_mean*1e2)/1e2)

# Processa SpecialId
stats tempSpecial using 1 name "Sent" nooutput
stats tempSpecial using 2 name "Recv" nooutput
print "SpecialId\t", (floor(Sent_min*1e2)/1e2), "\t", (floor(Sent_max*1e2)/1e2), "\t", (floor(Sent_mean*1e2)/1e2), "\t\t", (floor(Recv_min*1e2)/1e2), "\t", (floor(Recv_max*1e2)/1e2), "\t", (floor(Recv_mean*1e2)/1e2)

# Processa SuspNeighbors
stats tempSusp using 1 name "Sent" nooutput
stats tempSusp using 2 name "Recv" nooutput
print "SuspNeighbors\t", (floor(Sent_min*1e2)/1e2), "\t", (floor(Sent_max*1e2)/1e2), "\t", (floor(Sent_mean*1e2)/1e2), "\t\t", (floor(Recv_min*1e2)/1e2), "\t", (floor(Recv_max*1e2)/1e2), "\t", (floor(Recv_mean*1e2)/1e2)

# Processa BlockedNeighbor
stats tempBlock using 1 name "Sent" nooutput
stats tempBlock using 2 name "Recv" nooutput
print "BlockedNeighbor\t", (floor(Sent_min*1e2)/1e2), "\t", (floor(Sent_max*1e2)/1e2), "\t", (floor(Sent_mean*1e2)/1e2), "\t\t", (floor(Recv_min*1e2)/1e2), "\t", (floor(Recv_max*1e2)/1e2), "\t", (floor(Recv_mean*1e2)/1e2)

# Processa SuspReduction
stats tempReduc using 1 name "Sent" nooutput
stats tempReduc using 2 name "Recv" nooutput
print "SuspReduction\t", (floor(Sent_min*1e2)/1e2), "\t", (floor(Sent_max*1e2)/1e2), "\t", (floor(Sent_mean*1e2)/1e2), "\t\t", (floor(Recv_min*1e2)/1e2), "\t", (floor(Recv_max*1e2)/1e2), "\t", (floor(Recv_mean*1e2)/1e2)

# Processa Total
stats tempTotal using 1 name "Sent" nooutput
stats tempTotal using 2 name "Recv" nooutput
print "Total\t\t", (floor(Sent_min*1e2)/1e2), "\t", (floor(Sent_max*1e2)/1e2), "\t", (floor(Sent_mean*1e2)/1e2), "\t\t", (floor(Recv_min*1e2)/1e2), "\t", (floor(Recv_max*1e2)/1e2), "\t", (floor(Recv_mean*1e2)/1e2)

unset print

# --- 4. Limpeza ---
system("rm _temp_30_*.txt")

print "Arquivo global 'global_total_messages_sent_and_received.txt' foi gerado."