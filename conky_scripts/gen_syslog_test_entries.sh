#!/bin/bash


logger -p user.alert "================================="; sleep 1.0 
logger -p user.emerg "This is a test emerg message"; sleep 1.0
logger -p user.alert "This is a test alert message"; sleep 1.0
logger -p user.crit "This is a test crit message"; sleep 1.0
logger -p user.error "This is a test err message"; sleep 1.0
logger -p user.warning "This is a test warning message"; sleep 1.0
logger -p user.notice "This is a test notice message"; sleep 1.0
logger -p user.info "This is a test info message"; sleep 1.0
logger -p user.debug "This is a test debug message"; sleep 1.0
logger -p user.alert "================================="; sleep 1.0
