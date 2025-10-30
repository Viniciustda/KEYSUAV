#!/bin/bash

# ==============================================================================
# run_plot_neighborhood_evolution.sh
#
# This script finds all subdirectories in the current location and runs the
# Gnuplot script 'plot_neighborhood_evolution.gp' for each one in parallel,
# using all available CPU cores via xargs.
#
# It automatically ignores directories that do not contain the required
# 'neighborhood_evolution_192.168.1.*.txt' files.
#
# Requirements:
#   - gnuplot
#   - The 'plot_neighborhood_evolution.gp' script (in English) in the same directory.
#
# Usage:
#   1. Make the script executable: chmod +x run_plot_neighborhood_evolution.sh
#   2. Run it from the 'flysafe_traces' directory: ./run_plot_neighborhood_evolution.sh
# ==============================================================================

echo "Starting parallel execution of Gnuplot script..."

# Detect the number of CPU cores
NUM_CORES=$(nproc)
echo "Using up to ${NUM_CORES} CPU cores in parallel."
echo "-------------------------------------------------------------"

# Find all immediate subdirectories and pipe them to xargs for parallel processing.
#
# - 'find . -maxdepth 1 -mindepth 1 -type d' lists only the subdirectories (e.g., ./folder1)
# - '|' sends this list to the next command.
# - 'xargs -P $NUM_CORES' runs up to NUM_CORES processes in parallel.
# - '-I {}' sets the placeholder for the input line (the directory path).
# - 'bash -c "..."' executes the gnuplot command for each directory.
#
# Note: "No such file or directory" messages from 'ls' inside gnuplot are normal
# for folders without data and will be ignored.

find . -maxdepth 1 -mindepth 1 -type d | xargs -P $NUM_CORES -I {} bash -c "
    echo '==> Starting processing for folder: {}'
    
    # Run the Gnuplot script, passing the folder name.
    # We escape the inner quotes for the bash -c command.
    gnuplot -e \"folder='{}'\" -p 17-2_plotNeighborhoodEvolution.gp
    
    echo '<== Finished processing for folder: {}'
"

echo "-------------------------------------------------------------"
echo "Parallel processing completed."