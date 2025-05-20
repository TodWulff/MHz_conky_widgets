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
#	✓ Implemented filter keyword lists vs. a single term
#
#.........................................................................................
# 5130_1930		 TAW	10May25	feature additions - Released:  via github
#
#	✓ Alter color naming scheme, reinstated severity in widget display, spewed a bit about
#		why/what in the readme.  This help to reduce conky buffer overruns especially with
#		longer log entry lines.  Requires config of color codes in the widgets config file 
#		as well as the shell script.
#
#.........................................................................................
# 5131_1700		 TAW	11May25	feature additions - Released:  via github
#
#	✓ make default value changes, added and went all OCD on test message script <roll eyes>
#	✓ initially added an attn (bell) to the log_debug proc and then went all rube goldbert
#		and decided to address all permutations of potential scenarios:
#		
#		attention - helper proc to emit a bell to somewhere - it works.  lol
#		debug_attn - this is a helper proc too - wrapped the above with debug mode test
#		
#		So I did a matrix up of all possible reasonable uses of log, echo, when in debug or
#		not, and if a bell is desired or not:
#		
#		# case 1 - echo (built into bash interpreter)
#		# case 2 - log			Expects severity number as the first argument
#		# case 3 - echo_log		Expects severity number as the first argument
#		# case 4 - echo_attn
#		# case 5 - log_attn		Expects severity number as the first argument
#		# case 6 - echo_log_attn	Expects severity number as the first argument
#		# case 7 - dbg_echo						
#		# case 8 - dbg_log		Expects severity number as the first argument
#		# case 9 - dbg_echo_log		Expects severity number as the first argument
#		# case 10 - dbg_echo_attn
#		# case 11 - dbg_log_attn	Expects severity number as the first argument
#		# case 12 - dbg_echo_log_attn	Expects severity number as the first argument
#		
#		
#		tgt_log_sev_no="6"	# <- ultimately passed as a parameter - but setting early
#		
#		debug_sever="7"		# this is the severity used for debug logging in ... debug.!.
#		error_sever="3"		# this is the severity used for logging of script ... errors
#		mark_sever="6"		# severity used for the periodic -- MARK -- logs,
#			if so enabled in the parameters (6=info - followed rsyslogd's lead here)
#
#.........................................................................................
# 5132_1000		 TAW	12May25	code/implementation refinement -  Released:  via github
#
#	✓ strip out all of the journal shite#
#	✓ need to cache generated ouput on a the initial run and then any runs < a second later, just repost same
#	✓ having the scrip just exiting early w/o providing content if it runs <1sec ago causes flashing of the widget
#	✓ only rerun the log ingestion and parsing once per second
#	✓ figure out how to do an inverted filter list - to reject display of items: 
#		'-' prefix to be an exclude,otherwise it is and include.  This script does includes
#		 first to filter out desired log entries and then any excludes are applied thereon
#
#.........................................................................................
# 5135_1830		 TAW	15May25	code/implementation refinement -  Released:  via github
#
#	✓ modified date/time presentation format to show MM-DD HH:MM:SS.mmm (removed year, added milliseconds)
#	✓ improved temporal sorting with millisecond precision to ensure stable ordering of entries
#	✓ added vitals postpended onto header string with time and log message counts
#		... [last_dur; TemporalFetchCount/CountPostInclude/CountPostExclude/CountPostPruneFormat]
#	✓ added temporal duration data to header, and uptime
#	✓ added more 'expressive/elaborate' spinner (rotating moon phase) prepended onto display header
#	✓ cleaned up presentation of display header from a colors perspective
#		syslog no longer highlighted as journal processing entirely removed
#	✓ implemented programmatic disablement of debug files when running debug but not worrying
#		about the fetching or filtering.#
#	✓ started implementation of PID enumeration in self logging - more work to do there
#	
#.........................................................................................
# 5135_1900		 TAW	15May25	code/implementation refinement -  Released:  via github
#
#	✓ implemented fix for bug introduced with date/time presentation formatting - temporal
#		highlighting for aging and aged log entries became borked.  Copilot is my friend.
#
#.........................................................................................
# 5136_1200		 TAW	16May25	code/implementation refinement -  Released:  via github
#
#	✓ Completed implementing a more expressive presentation of PID dynamics - normal ops,
#		PID of hostconky widget is presented in header bar and any log entries made 
#		(--id=blah logger param).  When in debug mode, this script's PID is presented 
#		(-i logger param and the PID chain is part of the log message when organic log
#		entries are programmatically made.
#
#.........................................................................................
# 5137_1430		 TAW	17May25	code/implementation refinement -  Released:  via github
#
#	✓ Completed implementing a more expressive presentation of the display header.  Still
#		need to migrate the header presentation over to the cached presentation.
#
#.........................................................................................
# 5138_1430		 TAW	17May25	code/implementation refinement -  Released:  via github
#
#	✓ Completed commenting of procs and variables to enable easier understanding of logic
#	✓ 
#
#.........................................................................................
#.........................................................................................
# To Dos:
#	- implement emission of the conky panel PID embedded into the PID of the shell - this will
#		impute that the -i logger option is redacted and customized - the goal is to have not 
#		only the PID of the spawned shell, but also the PID of the parent conky instance
#	- considerimplementing aural warnings on a threshold level (i.e. alert, critical, emerg/panic)
#	- consider supporting passing severity names vs. (magic) numbers?
#	- looks like conky is calling the script at a 20ms rate (50x per sec) on this box/system .?.  that seems wrong?
#	- fix mia header when the tool is starved of content
#	- see about the intermitted space between the header and body
#	- adapt coloring to respect the dimming with age concept (3 levels for each:  'fields',
#		cyan, green, yellow, red 
#		- so conky's keywords only support colorX where X is 0-9 inclusive, and all are used
#		in current highlighting and log decorations - hmm
#	- fix the dynamic warn/warning highlights - may need to look at error/err & emerg/panic too
#		yeah, this is a nag only - depending on the script behavior and regex and automatic list sorting?, 
#		for terms with dual keywords/names (emer/panic, warn/warning, err/error, the 'logic' i've crafted is borked
#	- consider sudo and getting 'nice' escalations in place - needed ISO programmatic control/
#		adj call's 'nice' factor ;)
#	- consider a rules implementation approach - dunno where my gray matter was when I
#		drafted this note and WTF it means <cage eyes hard here>
#	- can widget text be made to be selectable (would like to be able to copy from the widget
#		in support of searching or other use, before it scrolls off the top of the display
#	- can the widget be made into a window (similar context here...)
#	- can widget have event support - click on header severity to popup and select different
#		severities ... exclude ... include ...
#	- add hotspot on click on duration to change it
#	- consider collections separate from display for logs (see cpu power polling/calculation | formatting/reporting)
#	- on save, evaluate impact of blocking wait on fs save
#	  
#========================================================================================

##################################################################################################

# optional		1) debug enable - Optional integer to 0=disabled (default) any other value to enable
# parameters:	2) Optional int seconds to self emit in the monitored log - 0 to disable, default is 10 min (600 secs)
#				3) tgt_log_sev_no - Optional log severity number (defaults to 4 [warning] and 'higher' severity)
#				4) max_entry_count - Optional Number of log entries (defaults to 60)
#				5) max_entry_width - Optional Max char width to trim each line to (default of 152)
#				6) keyword_filter - Optional keyword to filter logs
#				7) hilt_cyan_list - Optional "comma,separated,values" list of keywords to decorate a specifc term to a specific color
#				8) hilt_green_list - Optional "comma,separated,values" list of keywords to decorate a specifc term to a specific color
#				9) hilt_yellow_list - Optional "comma,separated,values" list of keywords to decorate a specifc term to a specific color
#				10) hilt_red_list - Optional "comma,separated,values" list of keywords to decorate a specifc term to a specific color
#				11) fresh_period - Optional int period in Seconds for 'Fresh' decorations to be applied = 
#				12) aging_period - Optional int period in Seconds for 'Aging' decorations to be applied
#				13) temporal fetch - Optional int period in Seconds for pulling in pre-filtered syslog entries

##################################################################################################

# --- Configuration ---
enable_debug="1"				# parameterized - 0 = disable, !0 = enable <- ultimately passed as a parameter, but may want one emission at app start.?.
enable_fetch_filter_debug="0"	# 0 = disable, !0 = enable <- to enable phases debug file saves

app="Conky_Widget"				# app name used in logger in NON-DEGUB context
proc="Syslog_Panel"				# proc name used in logger in NON_DEBUG context

debug_app="Syslog_Panel"		# app name used in logger in DEGUB context
debug_proc="logs.sh"    		# proc name used in logger in DEBUG context

tgt_log_sev_no="7"				# parameterized - but setting early, in case it's needed

mark_period=0					# parameterized - time between self-made -- MARK --, in seconds - 0 to disable
mark_sever="6"					# severity used for the periodic -- MARK -- log msgs, if so enabled in the parameters

debug_sever="7"					# this is the severity used for debug self-logging
error_sever="3"					# this is the severity used for sript error logs

syslog_format="short-unix"		# a pretty critical setting - affect temporal functionality

fresh_period=60					# parameterized - used in aging of log message display - must be less than aging_period
aging_period=120				# parameterized - used in aging of log message display - must be greater than fresh_period

rate_limit_period=1000			# time in mS to force emit of cached logs when faster than this

# color defs for reading ease - COLOR HEX CODES ARE DEFINED IN THE VARS SECTION OF THE WIDGET
# also taking this approach to minimize the text length of the decorations to help minimize buffer overruns

col_white="color0"
col_ltgray="color1"
col_dkgray="color2"
#col_blah="color3"
col_cyan="color4"
col_green="color5"
col_yellow="color6"
col_red="color7"
col_orange="color8"
col_magenta="color9"

recent_color="$col_white"
aging_color="$col_ltgray"
aged_color="$col_dkgray"
debug_color="$col_white"
#blah_color="$col_blah"
trim_ind_color="$col_magenta"
highlight_colors=("$col_cyan" "$col_green" "$col_yellow" "$col_red")

# Spinner schtuffs - to depict logger widget life - and is also icing on the cake, ya know...
#("―" "\\" "|" "/")							# rotating chars
#("🌑" "🌒" "🌓" "🌔" "🌕" "🌖" "🌗" "🌘")	# ccw moon
#("🌔" "🌓" "🌒" "🌑" "🌘" "🌗" "🌖" "🌕")	# cw moon
spinner_chars=("🌔" "🌓" "🌒" "🌑" "🌘" "🌗" "🌖" "🌕")
cache_spinner="⁂" # ⁂ to visually denote cached log displayed (char is a tri-snowflake)
starve_spinner="⇱" # to visually denote starvation




spinner_voffset=23							# vercial offset of spinner

# these are conky directives to enable decorating the spinner and manipulate it as desired
spinner_decor="\${font Common:size=18}\${color6}\${voffset $spinner_voffset}"
spinner_undecor="\${voffset -$spinner_voffset}\${font Common:size=13} \${font}"

# for visual purposes
severity_levels=("EMERGENCY" "ALERT" "CRITICAL" "ERROR" "WARNING" "NOTICE" "INFO" "DEBUG")

# for programmatic purposes
severity_names=("emerg" "alert" "crit" "error" "warning" "notice" "info" "debug")

syslog_processing_vitals="Fetch/Include/Exclude/Prune/Format"		# placeholder content

tmp_cache_file="${content_cache_file}.tmp.$$"						# because: atomic cache update

content_cache_file="/home/todwulff/tmp/conky_logs_cache"			# cache file
proc_vitals_file="/home/todwulff/tmp/syslog_vitals_tmp"				# because: spawned proc
last_run_file="/home/todwulff/tmp/conky_logs_last_run"				# var persistence across runs
last_dur_file="/home/todwulff/tmp/conky_logs_last_dur"				# var persistence across runs
last_mark_file="/home/todwulff/tmp/conky_logs_last_mark"			# var persistence across runs
spinner_state_file="/home/todwulff/tmp/conky_logs_spinner_state"	# var persistence across runs

dbg_temporal_syslog_file="/home/todwulff/tmp/dbg_temporal_syslog"	# for debug, if files enabled
dbg_format_syslog_file="/home/todwulff/tmp/dbg_format_syslog"		# for debug, if files enabled
dbg_include_syslog_file="/home/todwulff/tmp/dbg_include_syslog"		# for debug, if files enabled
dbg_exclude_syslog_file="/home/todwulff/tmp/dbg_exclude_syslog"		# for debug, if files enabled
dbg_pruned_syslog_file="/home/todwulff/tmp/dbg_pruned_syslog"		# for debug, if files enabled

# array for log fetch methods - was journal and syslog, now only syslog
#	(must config journal to emit *.* to syslog with template as noted in fetch_syslog proc)
log_fetchers=(
    "fetch_syslog"                     								# Index 0 / Not used (for safety)
    "fetch_syslog"                     								# 1: syslog only
)

##################################################################################################

# --- Functions ---

attention() {				# emits bell to console
	printf "\a" >&2; sleep 0.1; printf "\a" >&2
}

dbg_attn() {				# emits bell to console if in DEBUG context
    if [[ "$enable_debug" != "0" ]]; then
		attention
	fi
}

log() {						# emits msg to logger
	local sever_no="$1"
	shift
	local message=("$@")
	local log_tgt=$(get_log_name "$sever_no")
    if [[ "$enable_debug" != "0" ]]; then
		# provide granular log entries [includes PID chain up to init] also echos to standard error as well as the log
		logger -s -p user."$log_tgt" -t "$debug_app.$debug_proc" -i -- "[$pid_chain] $message"	
	else
		# provides high-level log entries [PID referenced to the parent widget's PID]
		logger -p user."$log_tgt" -t "$app.$proc" --id="$widget_pid" -- "$message"
	fi
}

echo_log() { 				# emits msg to console
	local log_tgt="$1"
	shift
	log "$log_tgt" "$@"
	echo "$@"
}

echo_attn() {				# emits msg to console and bell to console
	echo "$@"
	attention
}

log_attn() {				# emits msg to logger and bell to console
	local tgt="$1"
	shift
	log "$tgt" "$@"
	attention
}

echo_log_attn() {			# emits msg to logger and to console with bell
	local tgt="$1"
	shift
	echo "$@"
	log_attn "$tgt" "$@"
}

dbg_echo() {				# emits msg to console if in DEBUG context
    if [[ "$enable_debug" != "0" ]]; then
		echo "$@"
	fi
}
								
dbg_log() {					# emits msg to logger if in DEBUG context
    if [[ "$enable_debug" != "0" ]]; then
		local log_tgt="$1"
		shift
		log "$log_tgt" "$@"
    fi
}

dbg_echo_log() {			# emits msg to logger and console if in DEBUG context
    if [[ "$enable_debug" != "0" ]]; then
		local log_tgt="$1"
		shift
		echo_log "$log_tgt" "$@"
	fi
}

dbg_echo_attn() {			# emits msg to console with bell if in DEBUG context
	dbg_echo "$@"
    dbg_attn
}

dbg_log_attn() {			# emits msg to logger if in DEBUG context
	local log_tgt="$1"
	shift
    dbg_log "$log_tgt" "$@"
    dbg_attn
}

dbg_echo_log_attn() {		# emits msg to logger and msg with bell to console if in DEBUG context
	local log_tgt="$1"
	shift
	dbg_echo_log "$log_tgt" "$@"
    dbg_attn
}

get_log_name() {			# takes sev # and returns sev name (debug, warning, ...)
    local idx="$1"
    if [[ ! "$idx" =~ ^[0-7]$ ]]; then
        echo_log_attn "$error_sever" "Error: target syslog must be an integer between 0 and 7 - got: >$idx<"
        return 1
    fi
    echo "${severity_names[$idx]:-debug}"
}

get_next_spinner() {		# returns a single char string based on a global rollover counter
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

generate_ms_hash() {		# Generate millisecond hash based on log line content
    local log_line="$1"
    local log_epoch="$2"
    
    # Create a deterministic hash from the log line and epoch
    # Using last 3 digits of the hash ensures consistent milliseconds for the same entry
    local ms_value=$(echo "${log_line}${log_epoch}" | md5sum | tr -cd '0-9' | head -c 3)
    echo "$ms_value"
}

fetch_syslog() {			# this is the primary worker proc here - way much is being done...
	#
	# ASSUMES RSYSLOGD /etc/rsyslog.d/50-default.conf TEMPLATE:
	#	$template SyslogFormatWithSeverity,"%timegenerated% %HOSTNAME% %syslogseverity-text% %syslogtag% %msg%\n"
	#
	# ASSUMES RSYSLOGD /etc/rsyslog.d/50-default.conf RULE:
	#	*.*				/var/log/syslog;SyslogFormatWithSeverity
	#
	# ASSUMES journald.conf is config'd to emit messages to rsyslogd
	#	ForwardToSyslog=yes	#<-- uncommented in journald.conf
	#
	
    # Validate inputs
    if [[ ! "$temporal_seconds" =~ ^[0-9]+$ ]]; then
        echo_log_attn "$error_sever" "Error: temporal_seconds must be a positive integer"
        return 1
    fi
	
    if [[ ! "$tgt_log_sev_no" =~ ^[0-7]$ ]]; then
        echo_log_attn "$error_sever" "Error: tgt_log_sev_no must be an integer between 0 and 7"
        return 1
    fi
	
    if [[ ! "$fetch_entry_count" =~ ^[0-9]+$ ]]; then
        echo_log_attn "$error_sever" "Error: fetch_entry_count must be a positive integer"
        return 1
    fi

    # Severity keywords for filtering (mapping syslog severity levels)
    local severities
    case "$tgt_log_sev_no" in
        0) severities="emerg" ;;
        1) severities="alert" ;;
        2) severities="crit" ;;
        3) severities="error" ;;
        4) severities="warning" ;;
        5) severities="notice" ;;
        6) severities="info" ;;
        7) severities="debug" ;;
    esac

	# clear vitals prior to processing
	syslog_processing_vitals=""

    dbg_log "$debug_sever" "Fetching up to $fetch_entry_count entries since '$temporal_seconds seconds ago' with severity $tgt_log_sev_no"

	##################################################################################################

    # Step 1: Temporal fetch from syslog - have adapted to also do severity filtering on the same pass.
    local sev_str="$severities"
	local since_str=$(date --date="$temporal_seconds seconds ago" "+%b %d %H:%M:%S")
	
	dbg_log "$debug_sever" "Since: $since_str  Sev: $sev_str"
	
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
        echo_log_attn "$error_sever" "Error: syslog temporal_fetch command failed for since_str: '$since_str'"
        return 1
    fi
	
    # Check if syslog is empty
    if [[ -z "$temporal_fetch" ]]; then
		dbg_log "$debug_sever" "No syslog entries found since '$since_str'"
		return 0
    fi
	
	#save temporal Syslog fetch
	if [[ "$enable_debug" != "0" && "$enable_fetch_filter_debug" != "0" ]]; then
		echo -e "$temporal_fetch" > "$dbg_temporal_syslog_file"
	fi

    # log line count of temporal temporal_fetch
    local temporal_line_count=$(echo -e "$temporal_fetch" | wc -l | awk '{print $1}')	
    dbg_log "$debug_sever" "temporal_fetch: $temporal_line_count entries from syslog for processing"
	
	syslog_processing_vitals="$temporal_line_count"
	##################################################################################################

    # Step 2: Include regex filter
    local include_results
    if [[ -n "$include_regex" ]]; then
        include_results=$(echo "$temporal_fetch" | grep -aEi -- "$include_regex" || true)
		dbg_log "$debug_sever" "+) include_regex: >$include_regex<"
    else
        include_results="$temporal_fetch"
        dbg_log "$debug_sever" "+) No include_regex"
    fi

	#save the temporal+include syslog
	if [[ "$enable_debug" != "0" && "$enable_fetch_filter_debug" != "0" ]]; then
		echo -e "$include_results" > "$dbg_include_syslog_file"
	fi
	
    local include_line_count=$(echo -e "$include_results" | wc -l | awk '{print $1}')
	dbg_log "$debug_sever" "include_regex: $include_line_count line(s) after include_regex"
	
	syslog_processing_vitals+="/$include_line_count"
	##################################################################################################

    # Step 3: Exclude regex filter
    local exclude_results
    if [[ -n "$exclude_regex" ]]; then
        exclude_results=$(echo "$include_results" | grep -aEiv -- "$exclude_regex" || true)
		dbg_log "$debug_sever" "-) exclude_regex: >$exclude_regex<"
    else
        exclude_results="$include_results"
        dbg_log "$debug_sever" "-) No exclude_regex"
   fi
	
	#save the temporal+include+exclude syslog
	if [[ "$enable_debug" != "0" && "$enable_fetch_filter_debug" != "0" ]]; then
		echo -e "$exclude_results" > "$dbg_exclude_syslog_file"
	fi
	
    local exclude_line_count=$(echo -e "$exclude_results" | wc -l | awk '{print $1}')
	dbg_log "$debug_sever" "exclude_regex: $exclude_line_count line(s) after exclude_regex"
	
	syslog_processing_vitals+="/$exclude_line_count"
	##################################################################################################

    # Step 4: Limit to fetch_entry_count lines, save to debug file and report line count
    local pruned_output
    pruned_output=$(echo "$exclude_results" | tail -n "$fetch_entry_count")
	
	if [[ "$enable_debug" != "0" && "$enable_fetch_filter_debug" != "0" ]]; then
		echo -e "$pruned_output" > "$dbg_pruned_syslog_file"
	fi
	
    local pruned_line_count=$(echo -e "$pruned_output" | wc -l | awk '{print $1}')
	dbg_log "$debug_sever" "prune: $pruned_line_count line(s) after pruning"
	
	syslog_processing_vitals+="/$pruned_line_count"
	##################################################################################################

    # Step 5: format output for display
    local format_output
    local output_line
	local format_line_count
	
	format_output=""
	
    while IFS= read -r line; do
        # Skip empty lines
        [[ -z "$line" ]] && continue

        # Parse syslog line
        log_time=$(awk '{print $1" "$2" "$3}' <<< "$line")
        log_epoch=$(date -d "$log_time" +%s 2>/dev/null)

        if [[ -z "$log_epoch" ]]; then
            dbg_log "$debug_sever" "Skipping line with invalid log_time: $log_time"
            continue
        fi

        source_machine=$(awk '{print $4}' <<< "$line")
        log_sev_level=$(awk '{print $5}' <<< "$line")
        
        # Generate milliseconds based on the log content
        ms_hash=$(generate_ms_hash "$line" "$log_epoch")
        
        # Format the time without year and with added milliseconds
        formatted_time=$(date -d "@$log_epoch" +"%m-%d %H:%M:%S").$ms_hash
        
        log_message=$(cut -d' ' -f6- <<< "$line")

        # Format the output line - use epoch+ms for precise sorting
#        output_epoch="${log_epoch}${ms_hash}"  # Append ms to epoch for precise sorting
#        output_line="${output_epoch}|SYSLOG|$formatted_time|$source_machine|$log_sev_level $log_message"
		output_line="${log_epoch}|${ms_hash}|SYSLOG|$formatted_time|$source_machine|$log_sev_level $log_message"

        format_output+="$output_line\n"
    done <<< "$pruned_output"

	#save temporal+include+exclude+format syslog fetch
	if [[ "$enable_debug" != "0" && "$enable_fetch_filter_debug" != "0" ]]; then
		echo -e "$format_output" > "$dbg_format_syslog_file"
	fi
	
    format_line_count=$(echo -e "$format_output" | wc -l | awk '{print $1}')
#	dbg_log "$debug_sever" "format: $format_line_count line(s) after formatting"
	dbg_log "$debug_sever" "format: $(($format_line_count - 1)) line(s) after formatting"    # off by one somewhere...

	##################################################################################################

	# get last runtime and prepend onto the vitals

    # write the value to a temp file (this proc gets spawned in a subshell...)
    echo "$syslog_processing_vitals" > "$proc_vitals_file"

    # Output the filtered and limited results
    echo -e "$format_output"
}

select_severity() {			# takes sev # and returns SEV NAME STRING (DEBUG, INFO, ...)
    local idx="$1"
	dbg_log "$debug_sever"  "select_severity: lookup: $idx  Result: ${severity_levels[$idx]:-DEBUG}"
    echo "${severity_levels[$idx]:-DEBUG}"
}

temporal_color() {			# returns the color to be applied based on temporal age of a log item
    local time_diff="$1"
    local log_message="$2"

    if [[ $time_diff -le $fresh_period ]]; then
        [[ "$log_message" == *"$debug_app"* ]] && echo "$debug_color" || echo "$recent_color"
    elif [[ $time_diff -le $aging_period ]]; then
        echo "$aging_color"
    else
        echo "$aged_color"
    fi
}

set_hilt_color() {			# returns the color to be used based on an index (highlight colors...)
    local idx="$1"
    echo "${highlight_colors[$idx]:-$col_cyan}"
}

calc_time_delta_ns() {		# calcs/returns difference between two ns times, with unit scaling
  local start_ns="$1"
  local end_ns="$2"

  # Validate input
  if ! [[ "$start_ns" =~ ^[0-9]+$ ]] || ! [[ "$end_ns" =~ ^[0-9]+$ ]]; then
    echo_log_attn "$error_sever" "Error: Invalid time format. Please provide nanosecond values (integers)."
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

script_start() {			# snaps start time and debugs vitals
	start_nanotime=$(date +%s%N)
	dbg_log "$debug_sever" "---------------------------------------------------"
	dbg_log "$debug_sever" "Started: $start_nanotime"
}

script_complete() {			# snaps end time, calcs dur, saves last_dur, and debugs vitals
	end_nanotime=$(date +%s%N)
	dur_nanotime=$(calc_time_delta_ns "$start_nanotime" "$end_nanotime")
	
	dbg_log "$debug_sever" "Finished: $end_nanotime - Took: $dur_nanotime"
	dbg_log "$debug_sever" "==================================================="
	
	#save duration to last duration file here
	echo "$dur_nanotime" > "$last_dur_file"
}

get_pid_chain() {			# emit series of PIDs from (init) 1 ... Subject_PID 
    local pid="$1"
    local pid_chain="$pid"

    while [[ "$pid" -ne 1 ]]; do
        pid=$(ps -o ppid= -p "$pid" | awk '{print $1}')
        pid_chain="$pid:$pid_chain"
    done

    echo "$pid_chain"
}

get_pid_chain_rev() {		# emit series of PIDs from Subject_PID ... 1 (init)
    local pid="$1"
    local pid_chain="$pid"

    while [[ "$pid" -ne 1 ]]; do
        pid=$(ps -o ppid= -p "$pid" | awk '{print $1}')
        pid_chain="$pid_chain:$pid"
    done

    echo "$pid_chain"
}

get_syslog_header() {		# blah
    local chache_hit="$1"

#  Ok there are three contexts when this proc is called
#	1) Normal: prior to emitting the syslog content to the widget - moon spinner
#	2) Starved: prior to emitting 'no matching logs' output to the widget - moon spinner
#	3) Throttled: in the event of a cache hit  - in this case, make us of the - snowflake spinner


}


##################################################################################################

# --- Startup ---
current_time_ms=$(date +%s%3N)
current_time=$(date +%s)
spinner=$(get_next_spinner)

current_pid=$$  # Capture the current script's PID
parent_pid=$(ps -o ppid= -p "$current_pid" | awk '{print $1}')
widget_pid=$(ps -o ppid= -p "$parent_pid" | awk '{print $1}')

# Get the full PID chain
#pid_chain=$(get_pid_chain "$current_pid")
pid_chain=$(get_pid_chain_rev "$current_pid")

# Get CLI arguments (they are all Optional)
enable_debug="${1:-0}"		 	# 0=disabled (default) any other value to enable
mark_period="${2:-600}"        	# Optional int seconds to self emit in the monitored log 0 to disable, default is 10 mon (600 secs)
tgt_log_sev_no="${3:-4}"   	 	# log severity number (defaults to 4 [warning])
max_entry_count="${4:-60}"   	# Number of log entries (defaults to 60)
max_entry_width="${5:-152}"  	# max char width to trim each line to (default of 220)
keyword_filter="${6:-}"      	# Optional keyword to filter logs (highlighted purple)
hilt_cyan_list="${7:-}"      	# Optional to highlight a specifc term cyan
hilt_grn_list="${8:-}"      	# Optional to highlight a specifc term green
hilt_yel_list="${9:-}"      	# Optional to highlight a specifc term yellow
hilt_red_list="${10:-}"    	 	# Optional to highlight a specifc term red
fresh_period="${11:-30}"     	# Optional to temporally highlight a specifc entry w/ 'Fresh' decorations
aging_period="${12:-120}"     	# Optional to temporally highlight a specifc entry w/ 'Aging' decorations
temporal_seconds="${13:-3600}"  # Optional temporal period for log fetching.

# Validate inputs
if ! [[ "$max_entry_count" =~ ^[0-9]+$ ]]; then
	echo_attn "Invalid max_entry_count: $max_entry_count \(must be a positive integer\)"
	script_complete
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

##################################################################################################

# Build include and exclude regexe constructs to be used in filtering syslog
include_regex=""
exclude_regex=""

if [[ ${#include_filters[@]} -gt 0 ]]; then
    include_regex=$(IFS='|'; echo "${include_filters[*]}")
fi

if [[ ${#exclude_filters[@]} -gt 0 ]]; then
    exclude_regex=$(IFS='|'; echo "${exclude_filters[*]}")
fi

##################################################################################################

# Build filter display string for use in header row
filter_display=""

if [[ ${#include_filters[@]} -gt 0 ]]; then
    IFS=', '
    filter_display+="\${$col_cyan}Include: \${$col_yellow}${include_filters[*]}"
    unset IFS
fi

if [[ ${#include_filters[@]} -gt 0 ]]; then
	if [[ ${#exclude_filters[@]} -gt 0 ]]; then
		filter_display+="\${$col_orange} | "
	fi
fi 

if [[ ${#exclude_filters[@]} -gt 0 ]]; then
    IFS=', '
    filter_display+="\${$col_cyan}Exclude: \${$col_yellow}${exclude_filters[*]}"
    unset IFS
fi

# Trim trailing space on filter_display (part of header line and wrapped in parens so cleanliness is godliness)
#filter_display=$(echo "$filter_display" | sed 's/ *$//')

##################################################################################################

# --- Build Output Header ---
severity_string=$(select_severity "$tgt_log_sev_no")
cache_source="\${font DejaVu Sans Mono:size=12:style=Bold}SYSLOG\${font}"
display_header=""
display_header+="\${$col_orange}$cache_source\${$col_orange} "
display_header+="entries ≥ \${$col_cyan}$severity_string \${$col_orange}(\${$col_white}Recent, \${$col_ltgray}Aging, \${$col_dkgray}Aged\${$col_orange})"
[[ -n "$filter_display" ]] && display_header+="\n   \${font}\${$col_orange}[$filter_display\${$col_orange}]"

##################################################################################################

script_start # when here, this respects debug param passed

##################################################################################################

# --- Rate Limit: Allow only one heavy execution every rate_limit_period ms ---
if [[ -f "$last_run_file" ]]; then
    last_time_ms=$(<"$last_run_file")

    if [[ $((current_time_ms - last_time_ms)) -lt $rate_limit_period ]]; then
        # Too soon - output previously cached content
        if [[ -f "$content_cache_file" ]]; then
            cached_payload=$(<"$content_cache_file")
			spinner="$cache_spinner"
			echo "$spinner_decor$spinner$spinner_undecor$display_header"
			echo "$cached_payload"
			dbg_echo_log_attn "$debug_sever" "Log rate limit exceeded - cache_hit"
			script_complete
			exit 0
        else
            # No previous content? Emit a simple fallback
            echo "\${$col_cyan}Loading..."
			echo_log_attn "$error_sever" "Cache hit, but Cache is MIA"
			script_complete
            exit 0
        fi
	fi
else	# file is MIA so create it
	echo_log "$error_sever" "last_run_file is MIA - creating it..."
	touch "$last_run_file"
fi

##################################################################################################

# --- emit '-- MARK --' to syslog, at the variable severity, at the parameterized interval, beeping if in debug
if [[ ${mark_period} -ne 0 ]]; then
	if [[ -f "$last_mark_file" ]]; then
		last_mark_ms=$(<"$last_mark_file")	
		if [[ $((current_time_ms - last_mark_ms)) -gt $((mark_period * 1000)) ]]; then
			echo "$current_time_ms" > "$last_mark_file"
			if [[ "$enable_debug" != "0" ]]; then
				log_attn "$mark_sever" "-- MARK --"
			else
				log "$mark_sever" "-- MARK --"
			fi
		fi
	else	# file is missing, so emit and create it
		echo "$current_time_ms" > "$last_mark_file"
		if [[ "$enable_debug" != "0" ]]; then
			log_attn "$mark_sever" "-- MARK --"
		else
			log "$mark_sever" "-- MARK --"
		fi
	fi
fi

##################################################################################################

# Otherwise, proceed with normal fresh fetch, recording start time in file
echo "$current_time_ms" > "$last_run_file"

# Calculate how many logs to pull initially
fetch_multiplier=1

if [[ -n "$keyword_filter" ]]; then
    fetch_multiplier=1
fi

fetch_entry_count=$((max_entry_count * fetch_multiplier))
#dbg_log "$debug_sever" "Generating log entries."

##################################################################################################

# --- Fetch and Process Logs ---
all_logs=$(fetch_syslog | sort -n -t'|' -k1 | tail -n "$max_entry_count")
# ^^^this^^^ spawns a subshell - due to command substitution - need to pass 
# vitals' variable contents via file (fetch_syslog saves the var to the file)
syslog_processing_vitals=$(<"$proc_vitals_file")


# append the proc vitals onto header line
last_dur=$(<"$last_dur_file")
last_dur_trimmed=$(printf "%.1f%s\n" $(echo "$last_dur"))

display_header+="\n   \${font}\${$col_orange}[Up: \${$col_ltgray}\${uptime}\${$col_orange}] [$last_dur_trimmed: $syslog_processing_vitals ($max_entry_width"x"$max_entry_count|$temporal_seconds"s")] [pid: $widget_pid]:"	# uptime is a conky function, iirc.

# anything else.?.
display_header+="\n"

# Handle no logs case
if [[ -z "$all_logs" ]]; then
	echo -e "$spinner_decor$spinner$spinner_undecor$display_header$cache_content\n" #had \n
    echo "\${$col_dkgray}No logs available matching criteria"
	dbg_echo_log "$debug_sever No matching criteria."
	script_complete
    exit 0
fi

##### dbg_log "$debug_sever" "filter_display: $filter_display"  # placed here after log ingestion to avoid filtering on this

cache_content=""

##################################################################################################

# --- Build Output Content ---
# loop through logs and build the balance of the display content.

while IFS='|' read -r log_epoch ms_hash source formatted_time source_machine log_message; do
    time_diff=$((current_time - log_epoch))

    tenure_color=$(temporal_color "$time_diff" "$log_message")
    
    # Trim and mark with tooltip if needed
    if [[ ${#log_message} -gt $max_entry_width ]]; then
        trimmed_message="${log_message:0:max_entry_width}"
        formatted_line="${trimmed_message}\${$col_magenta}█\${$tenure_color}"
    else
        formatted_line="$log_message"
    fi

    # Highlight keyword inside log message if filtering is active
    if [[ -n "$keyword_filter" ]]; then
	    formatted_line=$(sed "s/\($keyword_filter\)/\${$col_orange}\1\${$tenure_color}/Ig" <<< "$formatted_line")
    fi
	
	# Apply all highlight groups
	for idx in "${!highlight_groups[@]}"; do
		group_name="${highlight_groups[$idx]}"
		decor_color=$(set_hilt_color "$idx")   ############

		# <<< Correct way to pull real array values:
		eval "terms=(\"\${${group_name}[@]}\")"

		if [[ ${#terms[@]} -gt 0 ]]; then
			for term in "${terms[@]}"; do
				if [[ -n "$term" ]]; then
					formatted_line=$(sed "s/\($term\)/\${$decor_color}\1\${$tenure_color}/Ig" <<< "$formatted_line")
				fi
			done
		fi
	done

    cache_content+="\${$tenure_color}${formatted_time} ${source_machine} ${formatted_line}\n"
done <<< "$all_logs"

##################################################################################################

# Sort cache_content if needed
#sorted_logs=$(sort <<< "$cache_content")
sorted_logs="$cache_content"

# trim to last fetch_entry_count lines
cache_content=$(echo -e "$sorted_logs" | tail -n "$fetch_entry_count")

line_count=$(wc -l <<< "${cache_content}")
dbg_log "$debug_sever" "Syslog output to be displayed: $(($line_count + 1)) line(s)"  # off by one somewhere...

# Save the newly built cache_content to FS cache atomically
echo -e "$cache_content" > "$tmp_cache_file"
mv -f "$tmp_cache_file" "$content_cache_file"

# --- Output ---  w/ decoration & spinner
echo -e "$spinner_decor$spinner$spinner_undecor$display_header$cache_content"

# --- End Logging ---
script_complete
