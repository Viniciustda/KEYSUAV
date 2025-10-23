# Gnuplot script to plot the neighborhood evolution from log files.
#
# USAGE:
# 1. Save this script as 'plot_evolution.gp' in your root folder 'flysafe_traces'.
# 2. Navigate to the 'flysafe_traces' folder in your terminal.
# 3. Run the script passing the name of the folder containing the .txt files as an argument.
#
# Example command:
# gnuplot -e "folder='FOLDER_NAME'" -p plot_neighborhood_evolution.gp
#
# This will generate a .png image file for each log file found in the specified folder.

# --- Start of Script ---

# 1. Check if the 'folder' variable has been defined
if (!exists("folder")) {
    print "Error: You must define the folder using the -e argument."
    print "Usage: gnuplot -e \"folder='FOLDER_NAME'\" -p plot_neighborhood_evolution.gp"
    exit
}

# 2. Define the output terminal type (PNG) and font/size settings
set terminal pngcairo size 1800,1000 enhanced font "Helvetica,12"

# 3. List all 'neighborhood_evolution' files in the specified folder
files = system('ls '.folder.'/neighborhood_evolution_192.168.1.*.txt')

# 4. Start the loop to process each file found
do for [file in files] {
    
    # 5. Define the output filename, replacing .txt with .png
    output_filename = file[1:strlen(file)-4] . ".png"
    set output output_filename
    
    # 6. Chart settings (title, axes, grid)
    set title 'Neighborhood Evolution for '.file noenhanced
    set xlabel "Time (s)"
    set ylabel "Distance (m)"
    # set ylabel "Distance (m) - Logarithmic Scale"
    set grid
    set key outside right top

    # Force the X-axis to have the exact range from 0 to 1200
    set xrange [0:1200]
    
    # Use a logarithmic scale on the Y-axis to better visualize large variations in distance
    # set logscale y
    
    # Reset the tick settings
    set xtics auto
    set ytics auto
    # Set the X-axis (time) ticks for every 50 seconds.
    set xtics 0, 50
    # Add a specific tick on the Y-axis (distance) for the value 115.
    set ytics add ("115" 115)
    
    # 7. 'awk' command to preprocess the data file.
    #    It filters the relevant lines and extracts:
    #    Column 1: time
    #    Column 2: last octet of the neighbor's IP
    #    Column 3: distance (dist)
    preprocess_cmd = "< awk -F'\\t' 'NF > 3 { for (i=4; i<=NF; i++) { split($i, a, \",\"); if (a[1] != \"\") {split(a[1], ip, \".\"); print $1, ip[4], a[5]} } }' ".file

    # 8. Command to get a list of unique IPs (last octets) for the legend
    get_ips_cmd = "awk -F'\\t' 'NF > 3 { for (i=4; i<=NF; i++) { split($i, a, \",\"); if (a[1] != \"\") {split(a[1], ip, \".\"); print ip[4]} } }' ".file." | sort -nu"
    unique_ips = system(get_ips_cmd)

    # 9. Plot command
    #    - Iterates over each unique IP found.
    #    - Uses the preprocessed data stream (preprocess_cmd).
    #    - The expression 'using ($2==real(ip) ? $3 : 1/0)' filters the data in real-time to plot
    #      only the points corresponding to the current IP in the loop.
    #    - Each IP is plotted with a different color and a legend entry.
    plot for [ip in unique_ips] preprocess_cmd using 1:($2==real(ip) ? $3 : 1/0) with linespoints title 'Node '.ip
    
    # unset logscale

    # print "Chart generated: ".output_filename
}

# --- End of Script ---
# print "Process completed."
unset output