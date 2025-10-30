#!/bin/bash

# ============================================================================
# Script para executar uma sequência de análises
#
# Este script executa uma lista de scripts .sh e .gnu na ordem
# numérica predefinida. Para scripts divididos em partes (-1 e -2),
# apenas a parte -1 é chamada.
# ============================================================================

# --- 1. Garantir permissões de execução ---
echo "Garantindo permissões de execução para todos os scripts .sh..."
chmod +x *.sh
echo "Permissões atualizadas."
echo ""

# --- 2. Iniciar a execução da sequência ---
echo "Iniciando a execução da sequência de scripts..."

# --- Execução dos Scripts ---

echo "Executando (1/30): 1_neighRxAnalysisStat.gnu"
gnuplot 1_neighRxAnalysisStat.gnu

echo "Executando (2/30): 2_globalNeighDiscoveryErrorData.sh"
bash 2_globalNeighDiscoveryErrorData.sh

echo "Executando (3/30): 3_globalNeighDiscoveryAnalysisStat.gnu"
gnuplot 3_globalNeighDiscoveryAnalysisStat.gnu

echo "Executando (4/30): 4_localizationErrorAnalysisStat.gnu"
gnuplot 4_localizationErrorAnalysisStat.gnu

echo "Executando (5/30): 5_globalLocalizationErrorData.sh"
bash 5_globalLocalizationErrorData.sh

echo "Executando (6/30): 6_globalLocalizationErrorAnalysisStat.gnu"
gnuplot 6_globalLocalizationErrorAnalysisStat.gnu

echo "Executando (7/30): 7_globalDeviationErrorRxAnalysisStat.gnu"
gnuplot 7_globalDeviationErrorRxAnalysisStat.gnu

echo "Executando (8/30): 8_globaDeviationDelayErrorData.sh"
bash 8_globaDeviationDelayErrorData.sh

echo "Executando (9/30): 9_globalDeviationDelayAnalysisStat.gnu"
gnuplot 9_globalDeviationDelayAnalysisStat.gnu

echo "Executando (10/30): 10_spatialAwarenessNodeAnalysis.sh"
bash 10_spatialAwarenessNodeAnalysis.sh

echo "Executando (11/30): 11_globalSpatialAwarenessRxAnalysisStat.gnu"
gnuplot 11_globalSpatialAwarenessRxAnalysisStat.gnu

echo "Executando (12/30): 12_globalNoSpatialAwarenessRxAnalysisStat.gnu"
gnuplot 12_globalNoSpatialAwarenessRxAnalysisStat.gnu

echo "Executando (13/30): 13-1_runParallel13.sh"
bash 13-1_runParallel13.sh

echo "Executando (14/30): 14-1_runParallel14.sh"
bash 14-1_runParallel14.sh

echo "Executando (15/30): 15_globalKeepAwareNodeStat.gnu"
gnuplot 15_globalKeepAwareNodeStat.gnu

echo "Executando (16/30): 16_globalAchieveAwareNodeStat.gnu"
gnuplot 16_globalAchieveAwareNodeStat.gnu

echo "Executando (17/30): 17-1_runPlotNeighborhoodEvolution.sh"
bash 17-1_runPlotNeighborhoodEvolution.sh

echo "Executando (18/30): 18-1_runMimAnalysis.sh"
bash 18-1_runMimAnalysis.sh

echo "Executando (19/30): 19_globlaMimAnalysis.sh"
bash 19_globlaMimAnalysis.sh

echo "Executando (20/30): 20-1_runEffectiveMim.sh"
bash 20-1_runEffectiveMim.sh

echo "Executando (21/30): 21-1_runMimEffectiveAnalysis.sh"
bash 21-1_runMimEffectiveAnalysis.sh

echo "Executando (22/30): 22_globlaMimEffectiveAnalysis.sh"
bash 22_globlaMimEffectiveAnalysis.sh

echo "Executando (23/30): 23-1_runMimDurationCalculation.sh"
bash 23-1_runMimDurationCalculation.sh

echo "Executando (24/30): 24-1_runMimTimeStats.sh"
bash 24-1_runMimTimeStats.sh

echo "Executando (25/30): 25_globalMimTimeStats.sh"
bash 25_globalMimTimeStats.sh

echo "Executando (26/30): 26-1_runNetworkContaminationTime.sh"
bash 26-1_runNetworkContaminationTime.sh

echo "Executando (27/30): 27_globalNetworkContaminationTime.sh"
bash 27_globalNetworkContaminationTime.sh

echo "Executando (28/30): 28-1_runAlteretedMessageRateNode.sh"
bash 28-1_runAlteretedMessageRateNode.sh

echo "Executando (29/30): 29_globalAlteretedMessageRateNode.sh"
bash 29_globalAlteretedMessageRateNode.sh

echo "Executando (30/30): 30_globalTotalMessagesSentAndReceived.gnu"
gnuplot 30_globalTotalMessagesSentAndReceived.gnu

echo "---"
echo "Todos os scripts foram executados com sucesso!"
echo "---"
