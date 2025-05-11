#!/bin/bash

# test logger event with delays to help drive sequencing for visual purposes

delay=1.0

sleep $delay
logger -s -t "test" -p user.debug " "				; sleep $delay
logger -s -t "test" -p user.debug   "  ===================="	; sleep $delay
logger -s -t "test" -p user.emerg   "  Test emerg message"	#; sleep $delay
logger -s -t "test" -p user.alert   "  Test alert message"	#; sleep $delay
logger -s -t "test" -p user.crit   "   Test crit message"	#; sleep $delay
logger -s -t "test" -p user.error "    Test err message"	#; sleep $delay
logger -s -t "test" -p user.warning 	 "Test warning message"	#; sleep $delay
logger -s -t "test" -p user.notice 	" Test notice message"	#; sleep $delay
logger -s -t "test" -p user.info   "   Test info message"	#; sleep $delay
logger -s -t "test" -p user.debug   "  Test debug message"	; sleep $delay
logger -s -t "test" -p user.debug   "  ===================="	; sleep $delay
logger -s -t "test" -p user.debug " "				#; sleep $delay
