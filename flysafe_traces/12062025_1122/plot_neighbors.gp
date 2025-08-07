# Define o título do gráfico
set title "Comparação de NLSize e nPsbNeigh ao Longo do Tempo"

# Define os rótulos dos eixos
set xlabel "Tempo (segundos)"
set ylabel "Número de Vizinhos"

# Define o formato dos números no eixo Y (se necessário, para evitar notação científica em valores pequenos)
# unset format y # Descomente e ajuste se precisar de formato específico

# Define a legenda
set key autotitle columnhead # Usa a primeira linha do arquivo como título da legenda
set key outside # Coloca a legenda fora da área do gráfico (ajuste se preferir inside)
set key bottom right # Posição da legenda (ajuste conforme necessário)

# Define o estilo da linha para cada plot
# lc = linecolor (cor), lt = linetype (estilo de linha), lw = linewidth (espessura da linha)
# As cores podem ser nomeadas (blue, red, green, etc.) ou usando números
# lt 1 geralmente é linha sólida, lt 2 tracejada, etc.

# Plotando os dados:
# "nome_do_arquivo.txt" - o nome do seu arquivo de dados
# using 1:2 - usa a coluna 1 (Time) como X e a coluna 2 (NLSize) como Y
# with linespoints - plota linhas e pontos (você pode usar just lines ou just points)
# lc rgb "red" - cor da linha
# title "NLSize" - título para a legenda (mas set key autotitle columnhead já fará isso)

plot "neighborhood_rx_analysis_gnuplot_192.168.1.8.txt" using 1:2 with linespoints lc rgb "blue" title "NLSize", \
     "" using 1:3 with linespoints lc rgb "red" title "nPsbNeigh"

# Comando para pausar a execução e exibir o gráfico (opcional, remova se for gerar imagem)
# pause -1 "Pressione Enter para sair."

# Comando para gerar o gráfico em um arquivo de imagem (opcional, descomente para salvar)
set terminal pngcairo enhanced font "arial,10" size 1024,768
set output "result_neighbors_comparison_linespoints.png"
replot
set output