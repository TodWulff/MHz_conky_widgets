#!/bin/bash

# Debugging
enable_debug="0"
debug_level="4"
debug_trigger="Conky debug"
start_nanotime=$(date +%s%N)
debug_proc="calc_cpu_power.sh"

[[ "$enable_debug" != "0" ]] && logger -p user."$debug_level" "$debug_trigger:\t$debug_proc\tStart @ $start_nanotime"

# Configuration
prev_energy_file="/home/todwulff/tmp/rapl_prev_energy"
time_file="/home/todwulff/tmp/rapl_prev_time"
average_file="/home/todwulff/tmp/rapl_averages"
tmp_avg_file="/home/todwulff/tmp/rapl_averages_tmp"

max_iterations=5
max_inst_power=79
graph_y_size=25.0
max_graph_val=100.0

# Ensure files exist
touch "$average_file" "$tmp_avg_file"

# Initial values
last_power="0.00"
last_avg_power="0"
last_adj_power="0"

# Calculate constants using bc
max_adjusted_val=$(echo "scale=10; 79.0" | bc)
graph_scalar=$(echo "scale=10; $max_graph_val / $max_adjusted_val" | bc)
min_adjusted_val=$(echo "scale=10; $max_graph_val / $graph_y_size" | bc)

# Get current energy and time
current_energy=$(sudo cat /sys/class/powercap/intel-rapl:0/energy_uj)
current_time=$(date +%s.%N)

# Calculate power
if [[ -f "$prev_energy_file" && -f "$time_file" ]]; then
    prev_energy=$(cat "$prev_energy_file")
    prev_time=$(cat "$time_file")

    energy_diff=$(echo "scale=6; ($current_energy - $prev_energy) / 1000000" | bc)
    time_diff=$(echo "scale=6; $current_time - $prev_time" | bc)

    if [[ $(echo "$time_diff > 0" | bc) -eq 1 ]]; then
        power=$(echo "scale=2; $energy_diff / $time_diff" | bc)
        if [[ $(echo "$power > 0" | bc) -eq 1 ]]; then
            last_power="$power"
        fi
    else
        power="$last_power"
    fi
else
    power="$last_power"
fi

# Round power using awk
rounded_power=$(echo "$power" | awk '{printf "%.0f\n", $1 + 0.5}')

#Save current values
echo "$current_energy" > "$prev_energy_file"
echo "$current_time" > "$time_file"

if [[ $(echo "$rounded_power < $max_inst_power" | bc) -eq 1 ]]; then
    # Update average file
    echo "$rounded_power" >> "$average_file"
    tail -n "$max_iterations" "$average_file" > "$tmp_avg_file"
    cp "$tmp_avg_file" "$average_file"

    # Calculate and adjust average power
    averaged_power=$(awk '{sum += $1} END {if (NR > 0) printf "%.0f\n", sum / NR + 0.5; else print 0}' "$average_file")
    last_avg_power="$averaged_power"

    adjusted_power=$(echo "$averaged_power" | awk -v min="$min_adjusted_val" -v max="$max_graph_val" -v scalar="$graph_scalar" '{ pwr = $1 * scalar; if (pwr < min) pwr = min; if (pwr > max) pwr = max; printf "%.0f\n", pwr + 0.5 }')
    last_adj_power="$adjusted_power"
    echo "$averaged_power $adjusted_power"
else
    echo "$last_avg_power $last_adj_power"
fi

# Debugging
end_nanotime=$(date +%s%N)
dur_nanotime=$(((end_nanotime - start_nanotime)))
[[ "$enable_debug" != "0" ]] && logger -p user."$debug_level" "$debug_trigger:\t$debug_proc\tEnd @ $end_nanotime\tTook: $dur_nanotime ns"
