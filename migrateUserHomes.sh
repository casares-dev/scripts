#!/bin/sh

##### Variable + Array Declarations #####

DESTSRV=<IP here>
declare -a LEBHOMES01DIRS=("/marcom","/home")
declare -a LEBHOMES02DIRS=("/dev1","/dev3","/sup1","/sup2")
declare -a LEBHOMES03DIRS=("/home","/dev1","/dev2","/dev3")
declare -a LEBHOMES04DIRS=("/home")
declare -a LEBHOMES05DIRS=
declare -a LEBHOMES06DIRS=
declare -a LEBHOMES07DIRS=

##### Confirm rsync Binary #####

if [ -x $(command -v rsync) ]; then
	printf "Binary for rsync found...\n"
else
	printf "Binary for rsync not found on this system... would you like to fetch it? (y/n): "
	read -e BINYN
	case $BINYN in
		[Yy]* )
			if [ -f /etc/os-release ]; then
   			 # freedesktop.org and systemd
    			. /etc/os-release
    			OS=$NAME
    			VER=$VERSION_ID
			elif type lsb_release >/dev/null 2>&1; then
    		# linuxbase.org
			    OS=$(lsb_release -si)
			    VER=$(lsb_release -sr)
			elif [ -f /etc/lsb-release ]; then
    		# For some versions of Debian/Ubuntu without lsb_release command
    			. /etc/lsb-release
    			OS=$DISTRIB_ID
    			VER=$DISTRIB_RELEASE
			elif [ -f /etc/debian_version ]; then
		    # Older Debian/Ubuntu/etc.
			    OS=Debian
			    VER=$(cat /etc/debian_version)
			elif [ -f /etc/SuSe-release ]; then
			    # Older SuSE/etc.
			    ...
			elif [ -f /etc/redhat-release ]; then
			    # Older Red Hat, CentOS, etc.
			    ...
			else
			    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
			    OS=$(uname -s)
			    VER=$(uname -r)
			fi
			;;
		[Nn]* )
			printf "Please re-run when rsync is installed.\n"
			exit 0
			;;
		* )
			printf "Invalid option... please select y/n.\n"
	esac
fi

##### Confirm Isilon Connectivity #####

if ping -q -c 1 -W 1 $LEBISILON >/dev/null; then
	printf "Destination is reachable...\n"
else
	printf "Destination is not reachable...\n"
	exit 1
fi


##### Migrate lebhomes01 #####

migrateLH01 {
	for $dir in "${LEBHOMES01DIRS[@]}"
	do
		STARTLH01=$(date +'%s')
		rsync -avz --progress lebhomes01:$dir $DESTSRV:$DESTPATH
		ENDLH01=$(date +'%s')
		LH01TIME=($ENDLH01 - $STARTLH01) > /tmp/rsync-$dir-time.log
	done
}

