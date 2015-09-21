#!/bin/sh

check_status() {

local flag=0
local rsc
local id
local op

	# Output Example of "crm_mon -1 -o"
	# 
	# Operations:
	# * Node node01:
	#   dummy: migration-threshold=2 fail-count=2
	#    + (15) start: rc=0 (ok)
	#    + (16) monitor: interval=10000ms rc=7 (not running)
	#    + (19) stop: rc=0 (ok)

	# Read each line from "crm_mon -1 -o"
	crm_mon -1 -o | while IFS= read i;
	do
		# Start search from "Operations:".
		echo "$i" | egrep "^Operations:$" > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			flag=1
		fi

		# Run search only "this" node.
		echo "$i" | egrep "^* Node.*: $" > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			echo "$i" | grep `uname -n` > /dev/null 2>&1
			if [ $? -eq 0 ]; then
				flag=1
			else
				flag=0
			fi
		fi

		# Ignore blank line.
		echo "$i" | egrep "^$" > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			flag=0
		fi

		# Search the resource name.
		if [ ${flag} = 1 ]; then
			echo "$i" | egrep ": migration-threshold=" > /dev/null 2>&1
			if [ $? -eq 0 ]; then
				rsc=$i
			fi

		# Search the return code of each operation.
			echo "$i" | egrep "^+ " | egrep -v "Operations|Node|${rsc}" > /dev/null 2>&1
			if [ $? -eq 0 ]; then
				echo "$i" | egrep "rc=0 \(ok\)$" > /dev/null 2>&1
				if [ $? -ne 0 ]; then
					id=`echo $rsc | cut -d : -f 1`
					op=`echo $i | awk '{print $3}' | tr -d :`
					#check_handle ${id} ${op}
					#if [ $? -eq 1 ]; then
		# Print "REBOOT" if there is failure to call vSphereHA.
					#	echo "REBOOT"
					#	break
					#fi
					echo "${id} ${op}"
				fi
			fi
		fi
	done

	return 0 
}

# Run check_status
check_status

