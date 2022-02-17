#!/bin/bash -e

# Helper logging functions to log to rsyslog
# 1: message to log
SYSLOGTAG="waggle-init"
log () {
    echo "$1" | logger -t ${SYSLOGTAG}
}
log_error() {
    echo "$1" | logger -t ${SYSLOGTAG} -p "err"
}
log_warn() {
    echo "$1" | logger -t ${SYSLOGTAG} -p "warning"
}
# forward all stdout/stderr output to our rsyslog
# TODO: remove this syslogger stuff, hope for journalctl to work
exec 1> >(logger -s -t "$SYSLOGTAG") 2>&1

log "Disable first boot script"
mv /etc/waggle/firstboot.sh /etc/waggle/firstboot.sh.$(date '+%Y%m%d-%H%M%S').bck

wall -n "Waggle first boot: configuration complete (reboot needed to finish setup)"
log "First boot configuration complete, Schedule reboot"
shutdown -r +1
