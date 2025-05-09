#!/bin/bash

# DEBUG Configuration
enable_debug="0"
debug_level="4"
debug_trigger="Conky debug"
start_nanotime=$(date +%s%N)
debug_proc="report_cpu_power.sh"

[[ "$enable_debug" != "0" ]] && logger -p user."$debug_level" "$debug_trigger:\t$debug_proc\tStart @ $start_nanotime"

# Graph parameters
graph_y_size=25.0
max_graph_val=100.0

# File for average power readings
average_file="/home/todwulff/tmp/rapl_averages"

# Calculate constants using bc
max_adjusted_val=$(echo "scale=10; 79.0" | bc)
graph_scalar=$(echo "scale=10; $max_graph_val / $max_adjusted_val" | bc)
min_adjusted_val=$(echo "scale=10; $max_graph_val / $graph_y_size" | bc)

# Calculate the average power
averaged_power=$(awk '{sum += $1} END {if (NR > 0) printf "%.0f\n", sum / NR + 0.5; else print 0}' "$average_file")

# Adjust the averaged power for graphing
adjusted_power=$(echo "$averaged_power" | awk -v min="$min_adjusted_val" -v max="$max_graph_val" -v scalar="$graph_scalar" '{ pwr = $1 * scalar; if (pwr < min) pwr = min; if (pwr > max) pwr = max; printf "%.0f\n", pwr + 0.5 }')

# Output the values
echo "$averaged_power $adjusted_power"

# Logging end
end_nanotime=$(date +%s%N)
dur_nanotime=$(((end_nanotime - start_nanotime)))
[[ "$enable_debug" != "0" ]] && logger -p user."$debug_level" "$debug_trigger:\t$debug_proc\tEnd @ $end_nanotime\tTook: $dur_nanotime ns"
