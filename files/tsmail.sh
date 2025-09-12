#!/bin/sh

INITFILE=/etc/init.d/tsmail
SERVICE_PID_FILE=/var/run/tsmail.pid
APP=$0
PAR1=$1
PAR2=$2

usage() {
    echo "Usage: $APP [ COMMAND [ OPTIONS ] ]"
    echo "Without any command Tsmail will be runned in the foreground without debug mode"
    echo
    echo "Commands are:"
    echo "    start|stop|restart|reload     controlling the daemon"
    echo "    debug                         run in debug mode"
    echo "    help                          show this and exit"
    doexit
}
callinit() {
    [ -x $INITFILE ] || {
        echo "No init file '$INITFILE'"
        return
    }
    exec $INITFILE $1
    RETVAL=$?
}
run() {
    uci set tsmail.general.debug='0'
    uci commit tsmail
    exec /usr/bin/lua /usr/lib/lua/tsmail/app.lua
    RETVAL=$?
}

debug() {
    tsmail stop
    uci set tsmail.general.debug='1'
    uci commit tsmail
    exec /usr/bin/lua /usr/lib/lua/tsmail/app.lua
    RETVAL=$?
}

doexit() {
    exit $RETVAL
}

[ -n "$INCLUDE_ONLY" ] && return

CMD="$1"
[ -z $CMD ] && {
    run
    doexit
}
shift
# See how we were called.
case "$CMD" in
    start|restart|reload)
        callinit $CMD
        ;;
    debug)
        debug
        ;;
    stop)
        uci set tsmail.general.debug='0'
        uci commit tsmail
        callinit $CMD
        ;;
    *help|*?)
        usage $0
        ;;
    *)
        RETVAL=1
        usage $0
        ;;
esac

doexit
