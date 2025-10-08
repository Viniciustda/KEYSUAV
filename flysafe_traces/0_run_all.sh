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

echo "Executando (1/29): 1_neighRxAnalysisStat.gnu"
gnuplot 1_neighRxAnalysisStat.gnu

echo "Executando (2/29): 2_globalNeighDiscoveryErrorData.sh"
bash 2_globalNeighDiscoveryErrorData.sh

echo "Executando (3/29): 3_globalNeighDiscoveryAnalysisStat.gnu"
gnuplot 3_globalNeighDiscoveryAnalysisStat.gnu

echo "Executando (4/29): 4_localizationErrorAnalysisStat.gnu"
gnuplot 4_localizationErrorAnalysisStat.gnu

echo "Executando (5/29): 5_globalLocalizationErrorData.sh"
bash 5_globalLocalizationErrorData.sh

echo "Executando (6/29): 6_globalLocalizationErrorAnalysisStat.gnu"
gnuplot 6_globalLocalizationErrorAnalysisStat.gnu

echo "Executando (7/29): 7_globalDeviationErrorRxAnalysisStat.gnu"
gnuplot 7_globalDeviationErrorRxAnalysisStat.gnu

echo "Executando (8/29): 8_globaDeviationDelayErrorData.sh"
bash 8_globaDeviationDelayErrorData.sh

echo "Executando (9/29): 9_globalDeviationDelayAnalysisStat.gnu"
gnuplot 9_globalDeviationDelayAnalysisStat.gnu

echo "Executando (10/29): 10_spatialAwarenessNodeAnalysis.sh"
bash 10_spatialAwarenessNodeAnalysis.sh

echo "Executando (11/29): 11_globalSpatialAwarenessRxAnalysisStat.gnu"
gnuplot 11_globalSpatialAwarenessRxAnalysisStat.gnu

echo "Executando (12/29): 12_globalNoSpatialAwarenessRxAnalysisStat.gnu"
gnuplot 12_globalNoSpatialAwarenessRxAnalysisStat.gnu

echo "Executando (13/29): 13-1_runParallel13.sh"
bash 13-1_runParallel13.sh

echo "Executando (14/29): 14-1_runParallel14.sh"
bash 14-1_runParallel14.sh

echo "Executando (15/29): 15_globalKeepAwareNodeStat.gnu"
gnuplot 15_globalKeepAwareNodeStat.gnu

echo "Executando (16/29): 16_globalAchieveAwareNodeStat.gnu"
gnuplot 16_globalAchieveAwareNodeStat.gnu

echo "Executando (17/29): 17-1_runPlotNeighborhoodEvolution.sh"
bash 17-1_runPlotNeighborhoodEvolution.sh

echo "Executando (18/29): 18-1_runMimAnalysis.sh"
bash 18-1_runMimAnalysis.sh

echo "Executando (19/29): 19_globlaMimAnalysis.sh"
bash 19_globlaMimAnalysis.sh

echo "Executando (20/29): 20-1_runEffectiveMim.sh"
bash 20-1_runEffectiveMim.sh

echo "Executando (21/29): 21-1_runMimEffectiveAnalysis.sh"
bash 21-1_runMimEffectiveAnalysis.sh

echo "Executando (22/29): 22_globlaMimEffectiveAnalysis.sh"
bash 22_globlaMimEffectiveAnalysis.sh

echo "Executando (23/29): 23-1_runMimDurationCalculation.sh"
bash 23-1_runMimDurationCalculation.sh

echo "Executando (24/29): 24-1_runMimTimeStats.sh"
bash 24-1_runMimTimeStats.sh

echo "Executando (25/29): 25_globalMimTimeStats.sh"
bash 25_globalMimTimeStats.sh

echo "Executando (26/29): 26-1_runNetworkContaminationTime.sh"
bash 26-1_runNetworkContaminationTime.sh

echo "Executando (27/29): 27_globalNetworkContaminationTime.sh"
bash 27_globalNetworkContaminationTime.sh

echo "Executando (28/29): 28-1_runAlteretedMessageRateNode.sh"
bash 28-1_runAlteretedMessageRateNode.sh

echo "Executando (29/29): 29_globalAlteretedMessageRateNode.sh"
bash 29_globalAlteretedMessageRateNode.sh

echo "---"
echo "Todos os scripts foram executados com sucesso!"
echo "---"
