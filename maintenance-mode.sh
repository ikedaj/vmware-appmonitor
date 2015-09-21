#/bin/sh

APPMON_BIN=/opt/GuestSDK/bin/bin64/vmware-appmonitor
APPMON_LIB=/opt/GuestSDK/lib/lib64

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${APPMON_LIB}

function modify-cib() {
# Edit the id for primitive resource
# ex. prmAppmon-monitor-10s
#	resource name = prmAppmon
#	operaion = monitor
#	interval = 10s

	echo "Try to modify CIB"
	cibadmin --modify --xml-text '<op id="prmAppmon-monitor-10s" enabled=${1}/>'
	[ $? -eq 0 ] && return 0 || echo "Failed to modify CIB ${1}"; exit 3
}

function run-appmonitor() {
	echo "Set vSphereHA monitor status to ${1}"
	${APPMON_BIN} ${1}
	[ $? -eq 0 ] && return 0 || echo "Failed to set vmware-appmonitor ${1}"; exit 4
}

function maintenance-mode() {
	echo "Set maintenance-mode to ${1}"
	crm configure property maintenance-mode=${1} >/dev/null 2>&1
	[ $? -eq 0 ] && return 0 || echo "Failed to set maintenance-mode ${1}"; exit 5
}

function crm-status() {
	crm_mon -1 >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "Pacemaker is not running on this node."
		exit 2;
	fi
	return 0
}

function mode-status() {
	crm configure show | grep 'maintenance-mode="true"' >/dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "Current maintenance-mode status is true"
		return 0	 
	else
		echo "Current maintenance-mode status is false"
		return 1
	fi
}

function monitor-status() {
	${APPMON_BIN} isEnabled >/dev/null 2>&1
        if [ $? -eq 1 ]; then
                echo "Current vSphereHA monitor status is enable on this node"
                return 0
        else
                echo "Current vSphereHA monitor status is disable on this node"
                echo "This is STANDBY node, This script must be run on ACTIVE node"
                return 1
        fi
}

function election-status() {
	for i in `seq 1 10`
	do
		sleep 3
		STATUS=`crmadmin -S \`crmadmin -D | awk '{print $4}'\` | awk '{print $4}'`
		echo "State transition, ${STATUS}"
		if [ ${STATUS} = "S_IDLE" ]; then
			return 0
		fi
	done

	echo "Election timeout"
	exit 1
}

function usage() {
	echo "Usage: `basename $0` < true | false > "
	return 0
}

case ${1} in
true)
	crm-status
	mode-status && exit 2
	monitor-status || exit 2 
	modify-cib false
	election-status
	run-appmonitor disable
	maintenance-mode true
	election-status
	echo "SUCCESS" ;exit 0
	;;
false)
	crm-status
	mode-status || exit 2
	maintenance-mode false
	election-status
	run-appmonitor enable
	modify-cib true 
	election-status
	echo "SUCCESS" ;exit 0
	;;
*)
	usage
	exit 1
	;;
esac
