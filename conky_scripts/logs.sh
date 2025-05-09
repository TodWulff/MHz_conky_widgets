#!/bin/bash

#--------------------------------------------------------------------
# Copyright (C) 2025  Tod A. Wulff
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# Should you need to secure a copy of the GNU General Public License,
# see <https://www.gnu.org/licenses/>.
#--------------------------------------------------------------------

#.........................................................................................
#
#   - This shell script, when called by a conky widget conf will present a widget showing
#		syslog activity, with "include then exclude" regex filtering, highlighting, etc.
#
#	Setup and Use:
#	- TODO: [explain use, file rqmts, lib rqmts, locations, etc. to enable employment]
#
#	Acknowledgements:
#	- AIs are the bomb, as I struggle with this old ('67) dog learning new tricks (Linux)
#
#========================================================================================
#.........................................................................................
# yjjj_hhmm	✓	 TAW	ddMMMyy	feature additions - Released:  not yet.
#
#
# Revision History:
#.........................................................................................
# 5129_0435		 TAW	09May25	feature additions - Released:  via github;
#	https://github.com/TodWulff/MHz_conky_widgets.git
#
#	✓ Implemented a auto-MARK feature for this tool - the 2nd parameter is the mark period
#	✓ Implemented log_debug()
#	✓ Implemented a logger MARK for use when the script is running to emit a MARK every x seconds (x is parameterized in conf)
#	✓ Emelemented filter keyword lists vs. a single term
#
#.........................................................................................

#.........................................................................................
# To Dos:
#	- employ use of color_ vs. hex codes (saves buffer)
#	- consider a change of presented date/time format, adding ms?
#	- consider supporting passing severity names vs. (magic) numbers?
#	- figure out how to do an inverted filter list - to reject display of items
#	- need to save the generated ouput on a the initial run and then any runs < a second later, just repost same
#	- only rerun the log ingestion and parsing once per second
#	- having the scrip just exiting early w/o providing content if it runs <1sec ago causes flashing of the widget
#	- looks like conky is calling the script at a 20ms rate (50x per sec) on this box/system
#	- fix mia header when the tool is starved of content
#	- see about the intermitted space between the header and body
#	- adapt coloring to respect the dimming with age concept (3 levels for each:  'fields', cyan, green, yellow, red
#	- fix the dynamic warn/warning highlights - may need to look at error/err & emerg/panic too
#	- strip out all of the journal shite
#	- consider sudo and getting nice escalations in place
#	- consider a rules implementaiton approach
#	- can widget text be made to be selectable
#	- can the widget be made into a window
#	- can widget have event support - click on header severity to popup and select different severities ... exclude ... include ...
#	- add duration data to header
#	- add hotspot on click on duration to change it
#	- consider collections separate from display (see cpu power polling/calculation vs calculation/reporting)
#	- on save, evaluate impact of blocking wait on fs save
#	  
#========================================================================================

##################################################################################################

# optional		1) debug enable - Optional integer to 0=disabled (default) any other value to enable
# parameters:	2) Optional int seconds to self emit in the monitored log - 0 to disable, default is 10 min (600 secs)
#				3) log_sever_no - Optional log severity number (defaults to 4 [warning] and 'higher' severity)
#				4) max_entry_count - Optional Number of log entries (defaults to 60)
#				5) max_entry_width - Optional Max char width to trim each line to (default of 220)
#				6) keyword_filter - Optional keyword to filter logs
#				7) hilt_cyan_list - Optional "comma,separated,values" list of keywords to decorate a specifc term to a specific color
#				8) hilt_green_list - Optional "comma,separated,values" list of keywords to decorate a specifc term to a specific color
#				9) hilt_yellow_list - Optional "comma,separated,values" list of keywords to decorate a specifc term to a specific color
#				10) hilt_red_list - Optional "comma,separated,values" list of keywords to decorate a specifc term to a specific color
#				11) recent_period - Optional int period in Seconds for 'Fresh' decorations to be applied = 
#				12) aging_period - Optional int period in Seconds for 'Aging' decorations to be applied
#				13) temporal fetch - Optional int period in Seconds for pulling in pre-filtered syslog entries

##################################################################################################

# --- Configuration ---
enable_debug="1"		# <- ultimately passed as a parameter, but may want one emission at app start.?.
log_sever_no="7"		# <- ultimately passed as a parameter, but set to info in case emissions are desired at start
debug_trigger="Conky"
debug_proc="logs.sh"
mark_period=0

syslog_format="short-unix"

recent_period=60
recent_color="FFFFFF"
aging_period=120
aging_color="BBBBBB"
aged_color="777777"

rate_limit_period=1000	# mS

# used to highlinge the whole line of a debug message, and the spinner
debug_color="FFFFFF"

# Purple for Filtered keyword highlights and first line decoration
keyword_color="E196FF"
header_decor="\${font DejaVu Sans Mono:size=9}\${color 00FFFF}"

trim_ind_color="FF00CD"

#highlight_colors=("00FFFF" "83F18D" "FCF151" "FF659F") # Cyan, Green, Yellow, Red
highlight_colors=("00FFFF" "00FF00" "FFEA00" "FF3333") # Cyan, Green, Yellow, Red

severity_levels=("EMERGENCY" "ALERT" "CRITICAL" "ERROR" "WARNING" "NOTICE" "INFO" "DEBUG")	# for visual purposes
severity_names=("emerg" "alert" "crit" "err" "warning" "notice" "info" "debug")				# for programmatic purposes

content_cache_file="/home/todwulff/tmp/conky_logs_cache"
tmp_cache_file="${content_cache_file}.tmp.$$"

last_run_file="/home/todwulff/tmp/conky_logs_last_run"
last_mark_file="/home/todwulff/tmp/conky_logs_last_mark"
spinner_state_file="/home/todwulff/tmp/conky_logs_spinner_state"

dbg_temporal_syslog_file="/home/todwulff/tmp/dbg_temporal_syslog"
dbg_reformat_syslog_file="/home/todwulff/tmp/dbg_reformat_syslog"
dbg_include_syslog_file="/home/todwulff/tmp/dbg_include_syslog"
dbg_exclude_syslog_file="/home/todwulff/tmp/dbg_exclude_syslog"
dbg_pruned_syslog_file="/home/todwulff/tmp/dbg_pruned_syslog"

dbg_logs_presort_file="/home/todwulff/tmp/dbg_logs_presort"
dbg_logs_sorted_file="/home/todwulff/tmp/dbg_logs_sorted"
dbg_logs_pruned_file="/home/todwulff/tmp/dbg_logs_pruned"

spinner_chars=("―" "\\" "|" "/")

# array for log fetch methods - now only containing syslog
log_fetchers=(
    "fetch_syslog"                     # Index 0 / Not used (for safety)
    "fetch_syslog"                     # 1: syslog only
)

##################################################################################################

# --- Functions ---

get_dbg_log_name() {
    local idx="$1"
    echo "${severity_names[$idx]:-debug}"
}

log_debug() {
	debug_log_tgt=$(get_dbg_log_name "$log_sever_no")
    local message="$*"
    if [[ "$enable_debug" != "0" ]]; then
		logger -p user."$debug_log_tgt" "$debug_trigger $debug_proc: $message"
    fi
}

echo_debug() {
    local message="$*"
    if [[ "$enable_debug" != "0" ]]; then
		echo -e "$message" >&2
	fi
}

get_next_spinner() {
    local index=0
    if [[ -f "$spinner_state_file" ]]; then
        index=$(<"$spinner_state_file")
    fi

    # Ensure index is a number and in bounds
    if ! [[ "$index" =~ ^[0-9]+$ ]]; then
        index=0
    fi

    index=$(( (index + 1) % ${#spinner_chars[@]} ))
    echo "$index" > "$spinner_state_file"

    echo "${spinner_chars[$index]}"
}

fetch_syslog() {
	#
	# ASSUMES RSYSLOGD /etc/rsyslog.d/50-default.conf TEMPLATE:
	#	$template SyslogFormatWithSeverity,"%timegenerated% %HOSTNAME% %syslogseverity-text% %syslogtag% %msg%\n"
	#
	# ASSUMES RSYSLOGD /etc/rsyslog.d/50-default.conf RULE:
	#	*.*				/var/log/syslog;SyslogFormatWithSeverity
	#
	# ASSUMES journald conf is config'd to emit messages to rsyslogd (ForwardToSyslog=yes)
	#
	
    echo_debug "\n====================================="

    # Validate inputs
    if [[ ! "$temporal_seconds" =~ ^[0-9]+$ ]]; then
        echo "Error: temporal_seconds must be a positive integer" >&2
        return 1
    fi
	
    if [[ ! "$log_sever_no" =~ ^[0-7]$ ]]; then
        echo "Error: log_sever_no must be an integer between 0 and 7" >&2
        return 1
    fi
	
    if [[ ! "$fetch_entry_count" =~ ^[0-9]+$ ]]; then
        echo "Error: fetch_entry_count must be a positive integer" >&2
        return 1
    fi

    # Severity keywords for filtering (mapping syslog severity levels)
    local severities
    case "$log_sever_no" in
        0) severities="emerg" ;;
        1) severities="alert" ;;
        2) severities="crit" ;;
        3) severities="error" ;;
        4) severities="warning" ;;
        5) severities="notice" ;;
        6) severities="info" ;;
        7) severities="debug" ;;
    esac

    log_debug "SYSLOG: Fetching up to $fetch_entry_count entries since '$temporal_seconds seconds ago' with severity $log_sever_no"
	echo_debug "SYSLOG: Fetching up to $fetch_entry_count entries since '$temporal_seconds seconds ago' with severity $log_sever_no"

	##################################################################################################

    # Step 1: Temporal fetch from syslog - have adapted to also do severity filtering on the same pass.
    local sev_str="$severities"
	local since_str=$(date --date="$temporal_seconds seconds ago" "+%b %d %H:%M:%S")
	echo_debug "since: $since_str  sev: $sev_str"
	
    local temporal_fetch

	temporal_fetch=$(awk -v cutoff="$since_str" -v sev="$sev_str" '
		BEGIN {
			# Map severity text to numerical values, including aliases
			sev_map["emerg"]=0; sev_map["panic"]=0;
			sev_map["alert"]=1;
			sev_map["crit"]=2;
			sev_map["error"]=3; sev_map["err"]=3;
			sev_map["warning"]=4; sev_map["warn"]=4;
			sev_map["notice"]=5;
			sev_map["info"]=6;
			sev_map["debug"]=7;
			# Validate sev_str
			if (!(sev in sev_map)) {
				print "Error: Invalid sev_str: " sev > "/dev/stderr";
				exit 1;
			}
			target_sev = sev_map[sev];
		}
		{
			# Extract timestamp components
			split(cutoff, cutoff_parts, " ");
			m=substr($1,1,3); d=$2; t=$3;
			cm=cutoff_parts[1]; cd=cutoff_parts[2]; ct=cutoff_parts[3];
			
			# Extract log severity (field $5)
			log_sev = $5;
			
			# Check if log severity is valid and meets the requirement
			if (log_sev in sev_map && sev_map[log_sev] <= target_sev) {
				# Temporal comparison
				if (m > cm) print;
				else if (m == cm && d > cd) print;
				else if (m == cm && d == cd && t >= ct) print;
			}
		}' /var/log/syslog)

	# test for last command error
    if [[ $? -ne 0 ]]; then
        log_debug "Error: syslog temporal_fetch command failed for since_str: '$since_str'"
		echo_debug "Error: syslog temporal_fetch command failed for since_str: '$since_str'"
        return 1
    fi
	
    # Check if syslog is empty
    if [[ -z "$temporal_fetch" ]]; then
		log_debug "No syslog entries found since '$since_str'"
		echo_debug "No syslog entries found since '$since_str'"
		return 0
    fi
	
	#save temporal Syslog fetch
	if [[ "$enable_debug" != "0" ]]; then
		echo -e "$temporal_fetch" > "$dbg_temporal_syslog_file"
	fi

    # log line count of temporal temporal_fetch
    local temporal_line_count=$(echo -e "$temporal_fetch" | wc -l | awk '{print $1}')	
    log_debug "Temporal fetched $temporal_line_count entries from syslog for filtering"
	echo_debug "Temporal fetched $temporal_line_count entries from syslog for filtering"

	##################################################################################################

    # Step 2: Include regex filter
    local include_results
    if [[ -n "$include_regex" ]]; then
        include_results=$(echo "$temporal_fetch" | grep -aEi -- "$include_regex" || true)
		log_debug "+) Syslog Applied include_regex: >$include_regex<"
		echo_debug "+) Syslog Applied include_regex: >$include_regex<"
    else
        include_results="$temporal_fetch"
        log_debug "+) Syslog No include_regex"
		echo_debug "+) Syslog No include_regex"
    fi

	#save the temporal+include syslog
	if [[ "$enable_debug" != "0" ]]; then
		echo -e "$include_results" > "$dbg_include_syslog_file"
	fi
	
    local include_line_count=$(echo -e "$include_results" | wc -l | awk '{print $1}')
	log_debug "Syslog output contains $include_line_count line(s) after 'include filtering'"
	echo_debug "Syslog output contains $include_line_count line(s) after 'include filtering'"

	##################################################################################################

    # Step 3: Exclude regex filter
    local exclude_results
    if [[ -n "$exclude_regex" ]]; then
        exclude_results=$(echo "$include_results" | grep -aEiv -- "$exclude_regex" || true)
		log_debug "-) Syslog Applied exclude_regex: >$exclude_regex<"
		echo_debug "-) Syslog Applied exclude_regex: >$exclude_regex<"
    else
        exclude_results="$include_results"
        log_debug "-) Syslog No exclude_regex"
		echo_debug "-) Syslog No exclude_regex"
   fi
	
	#save the temporal+include+exclude syslog
	if [[ "$enable_debug" != "0" ]]; then
		echo -e "$exclude_results" > "$dbg_exclude_syslog_file"
	fi
	
    local exclude_line_count=$(echo -e "$exclude_results" | wc -l | awk '{print $1}')
	log_debug "Syslog output contains $exclude_line_count line(s) after 'exclude filtering'"
	echo_debug "Syslog output contains $exclude_line_count line(s) after 'exclude filtering'"

	##################################################################################################

    # Step 4: Limit to fetch_entry_count lines, save to debug file and report line count
    local pruned_output
    pruned_output=$(echo "$exclude_results" | tail -n "$fetch_entry_count")
	
	if [[ "$enable_debug" != "0" ]]; then
		echo -e "$pruned_output" > "$dbg_pruned_syslog_file"
	fi
	
    local pruned_line_count=$(echo -e "$pruned_output" | wc -l | awk '{print $1}')
	log_debug "Syslog output contains $pruned_line_count line(s) after 'pruning'"
	echo_debug "Syslog output contains $pruned_line_count line(s) after 'pruning'"

	##################################################################################################

    # Step 5: Reformat output for display
    local reformat_output
    local output_line
	local reformat_line_count
	
	reformat_output=""
	
    while IFS= read -r line; do
        # Skip empty lines
        [[ -z "$line" ]] && continue

        # Parse syslog line
        log_time=$(awk '{print $1" "$2" "$3}' <<< "$line")
        log_epoch=$(date -d "$log_time" +%s 2>/dev/null)

        if [[ -z "$log_epoch" ]]; then
            echo_debug "Skipping line with invalid log_time: $log_time"
            continue
        fi

        source_machine=$(awk '{print $4}' <<< "$line")
        formatted_time=$(date -d "@$log_epoch" +"%Y-%m-%d %H:%M:%S")
        log_message=$(cut -d' ' -f6- <<< "$line")

        # Format the output line
		output_line="$log_epoch|SYSLOG|$formatted_time|$source_machine|$log_message"
        reformat_output+="$output_line\n"
    done <<< "$pruned_output"

	#save temporal+include+exclude+reformat syslog fetch
	if [[ "$enable_debug" != "0" ]]; then
		echo -e "$reformat_output" > "$dbg_reformat_syslog_file"
	fi
	
    reformat_line_count=$(echo -e "$reformat_output" | wc -l | awk '{print $1}')
	log_debug "Syslog output contains $reformat_line_count line(s) after 'reformatting'"
	echo_debug "Syslog output contains $reformat_line_count line(s) after 'reformatting'"

	##################################################################################################

    # Output the filtered and limited results
    echo -e "$reformat_output"
    log_debug "SYSLOG: provided $reformat_line_count log entries"
}

read_logs() {
    fetch_syslog
}

select_severity() {
    local idx="$1"
    echo "${severity_levels[$idx]:-DEBUG}"
}

temporal_color() {
    local time_diff="$1"
    local log_message="$2"

    if [[ $time_diff -le $recent_period ]]; then
        [[ "$log_message" == *"$debug_trigger"* ]] && echo "$debug_color" || echo "$recent_color"
    elif [[ $time_diff -le $aging_period ]]; then
        echo "$aging_color"
    else
        echo "$aged_color"
    fi
}

set_hilt_color() {
    local idx="$1"
    echo "${highlight_colors[$idx]:-00FFFF}"
}

calculate_time_difference_ns() {
  local start_ns="$1"
  local end_ns="$2"

  # Validate input
  if ! [[ "$start_ns" =~ ^[0-9]+$ ]] || ! [[ "$end_ns" =~ ^[0-9]+$ ]]; then
    echo "Error: Invalid time format. Please provide nanosecond values (integers)."
    return 1
  fi

  # Calculate difference in nanoseconds and seconds
  local difference_ns=$(echo "$end_ns - $start_ns" | bc)
  local difference_s=$(echo "scale=9; $difference_ns / 1000000000" | bc)

  # Get absolute value for unit selection
  local abs_difference_s="$difference_s"
  if [ "$(echo "$difference_s < 0" | bc -l)" -eq 1 ]; then
    abs_difference_s=$(echo "0 - $difference_s" | bc)
  fi

  local scaled_difference unit
  # Adjust thresholds for better readability
  if [ "$(echo "$abs_difference_s < 0.000000001" | bc -l)" -eq 1 ]; then
    scaled_difference=$(echo "scale=0; $difference_ns" | bc)
    unit="ns"
  elif [ "$(echo "$abs_difference_s < 0.000001" | bc -l)" -eq 1 ]; then
    scaled_difference=$(echo "scale=3; $difference_ns / 1000" | bc | sed 's/^\./0./')
    unit="µs"
  elif [ "$(echo "$abs_difference_s < 1" | bc -l)" -eq 1 ]; then
    scaled_difference=$(echo "scale=3; $difference_ns / 1000000" | bc | sed 's/^\./0./')
    unit="ms"
  else
    scaled_difference=$(echo "scale=3; $difference_s" | bc | sed 's/^\./0./')
    unit="s"
  fi

  # Format output to remove trailing zeros and ensure consistent display
  scaled_difference=$(echo "$scaled_difference" | sed 's/\.0*$//; s/0*$//')
  echo "${scaled_difference} ${unit}"
}

log_start() {
	start_nanotime=$(date +%s%N)
	log_debug "---------------------------------------------------"
	log_debug "Syslog Conky Widget Start"
}

log_end() {
	end_nanotime=$(date +%s%N)
	dur_nanotime=$(calculate_time_difference_ns "$start_nanotime" "$end_nanotime")
	log_debug "Syslog Conky Widget Took: $dur_nanotime"
	log_debug "==================================================="
}

##################################################################################################

# --- Startup ---
current_time_ms=$(date +%s%3N)
current_time=$(date +%s)
spinner=$(get_next_spinner)

#log_debug "Starting Conky logs.sh Script"

# Get CLI arguments
enable_debug="${1:-0}"		 	# 0=disabled (default) any other value to enable
mark_period="${2:-600}"        	# Optional int seconds to self emit in the monitored log 0 to disable, default is 10 mon (600 secs)
log_sever_no="${3:-4}"   	 	# log severity number (defaults to 4 [warning])
max_entry_count="${4:-60}"   	# Number of log entries (defaults to 60)
max_entry_width="${5:-220}"  	# max char width to trim each line to (default of 220)
keyword_filter="${6:-}"      	# Optional keyword to filter logs (highlighted purple)
hilt_cyan_list="${7:-}"      	# Optional to highlight a specifc term cyan
hilt_grn_list="${8:-}"      		# Optional to highlight a specifc term green
hilt_yel_list="${9:-}"      		# Optional to highlight a specifc term yellow
hilt_red_list="${10:-}"    	 	# Optional to highlight a specifc term red
recent_period="${11:-30}"     	# Optional to temporally highlight a specifc entry w/ 'Fresh' decorations
aging_period="${12:-120}"     	# Optional to temporally highlight a specifc entry w/ 'Aging' decorations
temporal_seconds="${13:-3600}"  # Optional temporal period for log fetching.

# Validate inputs
if ! [[ "$max_entry_count" =~ ^[0-9]+$ ]]; then
    echo "Invalid max_entry_count: $max_entry_count \(must be a positive integer\)"
	log_end
    exit 1
fi

# setup and define highlight groups
IFS=',' read -ra hilt_cyan_terms <<< "$hilt_cyan_list"
IFS=',' read -ra hilt_grn_terms <<< "$hilt_grn_list"
IFS=',' read -ra hilt_yel_terms <<< "$hilt_yel_list"
IFS=',' read -ra hilt_red_terms <<< "$hilt_red_list"
highlight_groups=("hilt_cyan_terms" "hilt_grn_terms" "hilt_yel_terms" "hilt_red_terms")

# --- Multi-Filter setup (using 'Include then Exclude' approach) ---
# build filter arrays then build regex constructs therefrom
include_filters=()
exclude_filters=()

IFS=',' read -ra keyword_list <<< "$keyword_filter"

for keyword in "${keyword_list[@]}"; do
    if [[ "$keyword" == -* ]]; then			# test to see if the first char is a '-' minus symbol - denotes an exclusion
        exclude_filters+=("${keyword:1}")	# strip off the leading '-' passed to denote an exclusion
    else
        include_filters+=("$keyword")
    fi
done

# Build include and exclude regexe constructs to be used in filtering syslog
include_regex=""
exclude_regex=""

if [[ ${#include_filters[@]} -gt 0 ]]; then
    include_regex=$(IFS='|'; echo "${include_filters[*]}")
fi

if [[ ${#exclude_filters[@]} -gt 0 ]]; then
    exclude_regex=$(IFS='|'; echo "${exclude_filters[*]}")
fi

# Build filter display string for use in header row
filter_display=""

if [[ ${#include_filters[@]} -gt 0 ]]; then
    IFS=', '
    filter_display+="\${color 00FFFF}Include: \${color $keyword_color}${include_filters[*]} "
    unset IFS
fi

if [[ ${#exclude_filters[@]} -gt 0 ]]; then
    IFS=', '
    filter_display+="\${color 00FFFF}Exclude: \${color $keyword_color}${exclude_filters[*]} "
    unset IFS
fi

# Trim trailing space on filter_display (part of header line and wrapped in parens so cleanliness is godliness)
filter_display=$(echo "$filter_display" | sed 's/ *$//')

# --- Build Output Header ---
severity_string=$(select_severity "$log_sever_no")
cache_source="SYSLOG"
display_header=""

display_header+="\${color $keyword_color}$cache_source\${color2} "
display_header+="entries ≥ \${color $keyword_color}$severity_string \${color2}(\${color $recent_color}Recent, \${color $aging_color}Aging, \${color $aged_color}Aged\${color2})"
[[ -n "$filter_display" ]] && display_header+=" [\${color $keyword_color}$filter_display\${color2}]"

display_header+=":\n"

##################################################################################################

log_start # when here, this respects debug param passed

# --- Rate Limit: Allow only one heavy execution every rate_limit_period ms ---
if [[ -f "$last_run_file" ]]; then
    last_time_ms=$(<"$last_run_file")

    if [[ $((current_time_ms - last_time_ms)) -lt $rate_limit_period ]]; then
        # Too soon - output previously cached content
        if [[ -f "$content_cache_file" ]]; then
            cached_payload=$(<"$content_cache_file")
			spinner="░"			# ░ to visually denote cached log displayed
			echo -e "$header_decor$spinner $display_header$cached_payload"
			log_debug "Log rate limit exceeded - cache_hit"
			log_end
			exit 0
        else
            # No previous content? Emit a simple fallback
            echo "\${color FF0000}Loading..."
			log_end
            exit 0
        fi
	fi
fi

# --- emit '-- MARK --' to syslog, at the current severity, at the parameterized interval
if [[ ${mark_period} -ne 0 ]]; then
	if [[ -f "$last_mark_file" ]]; then
		last_mark_ms=$(<"$last_mark_file")	
		if [[ $((current_time_ms - last_mark_ms)) -gt $((mark_period * 1000)) ]]; then
			# file is present, and time recorded therein exceeds mark period, so emit and save time
			logger -p user."$debug_log_tgt" "$debug_trigger $debug_proc: -- MARK --"
			echo "$current_time_ms" > "$last_mark_file"
		fi
	else	# file is missing, so emit and create it
		logger -p user."$debug_log_tgt" "$debug_trigger $debug_proc: -- MARK --"
		echo "$current_time_ms" > "$last_mark_file"
	fi
fi

# Otherwise, proceed with normal fresh fetch, recording start time in file
echo "$current_time_ms" > "$last_run_file"

##################################################################################################

# Calculate how many logs to pull initially
fetch_multiplier=1

if [[ -n "$keyword_filter" ]]; then
    fetch_multiplier=1
fi

fetch_entry_count=$((max_entry_count * fetch_multiplier))
log_debug "Generating log entries."

##################################################################################################

# --- Fetch and Process Logs ---
all_logs=$(read_logs | sort -n -t'|' -k1 | tail -n "$max_entry_count")

# Handle no logs case
if [[ -z "$all_logs" ]]; then
	echo -e "$header_decor$spinner $cache_content\n"
    echo "\${color $aged_color}No logs available matching criteria"
	log_debug "No matching criteria."
	log_end
    exit 0
fi

log_debug "filter_display: $filter_display"  # placed here after log ingestion to avoid filtering on this

cache_content=""

# --- Build Output Content ---
# loop through logs and build the balance of the display content.

while IFS='|' read -r epoch source formatted_time source_machine log_message; do
    time_diff=$((current_time - epoch))
    color=$(temporal_color "$time_diff" "$log_message")
    
    # Trim and mark with tooltip if needed
    if [[ ${#log_message} -gt $max_entry_width ]]; then
        trimmed_message="${log_message:0:max_entry_width}"
        formatted_line="${trimmed_message}\${color $trim_ind_color}█\${color $color}"
    else
        formatted_line="$log_message"
    fi

    # Highlight keyword inside log message if filtering is active
    if [[ -n "$keyword_filter" ]]; then
        formatted_line=$(sed "s/\($keyword_filter\)/\${color $keyword_color}\1\${color $color}/Ig" <<< "$formatted_line")
    fi
	
	# Apply all highlight groups
	for idx in "${!highlight_groups[@]}"; do
		group_name="${highlight_groups[$idx]}"
		decor_color=$(set_hilt_color "$idx")

		# <<< Correct way to pull real array values:
		eval "terms=(\"\${${group_name}[@]}\")"

		if [[ ${#terms[@]} -gt 0 ]]; then
			for term in "${terms[@]}"; do
				if [[ -n "$term" ]]; then
					formatted_line=$(sed "s/\($term\)/\${color $decor_color}\1\${color $color}/Ig" <<< "$formatted_line")
				fi
			done
		fi
	done

    cache_content+="\${color $color}${formatted_time} ${source_machine} ${formatted_line}\n"
done <<< "$all_logs"

# Sort cache_content if needed
sorted_logs=$(sort <<< "$cache_content")

# trim to last fetch_entry_count lines
cache_content=$(echo -e "$sorted_logs" | tail -n "$fetch_entry_count")

line_count=$(wc -l <<< "${cache_content}")
log_debug "Syslog output to be displayed: $line_count line(s)"

# Save the newly built cache_content to FS cache atomically
echo -e "$cache_content" > "$tmp_cache_file"
mv -f "$tmp_cache_file" "$content_cache_file"

# --- Output ---  w/ decoration & spinner
echo -e "$header_decor$spinner $display_header$cache_content"

# --- End Logging ---
log_end
