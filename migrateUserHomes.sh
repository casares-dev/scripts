#!/bin/bash

##### Variable + Array Declarations #####

DESTSRV="0.0.0.0"
LOGDIR="/tmp/isilon-migration"
declare -a LEBHOMES01DIRS=("/marcom" "/home")
declare -a LEBHOMES02DIRS=("/dev1" "/dev3" "/sup1" "/sup2")
declare -a LEBHOMES03DIRS=("/home" "/dev1" "/dev2" "/dev3")
declare -a LEBHOMES04DIRS=("/home")
declare -a LEBHOMES05DIRS=("/foo")
declare -a LEBHOMES06DIRS=("/foo")
declare -a LEBHOMES07DIRS=("/foo")

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

if ping -q -c 1 -W 1 "$LEBISILON" >/dev/null; then
	printf "Destination is reachable...\n"
else
	printf "Destination is not reachable...\n"
	exit 1
fi


##### Migrate lebhomes01 #####

function migrateLH01 {
	for dir in "${LEBHOMES01DIRS[@]}"
	do
		printf "Gathering directory size...\n"
		du -h 
		STARTTIME=$(date +'%s')
		rsync -avz --progress "$dir" "$DESTSRV":"$DESTPATH" > "$LOGDIR"/lebhomes01-migration.log
		ENDTIME=$(date +'%s')
		TOTALTIME=$(("$ENDTIME" - "$STARTTIME"))
		echo "Migration time: $TOTALTIME seconds" >> "$LOGDIR"/lebhomes01-migration-$dir-time.log
	done
}

function migrateLH02 {
	for dir in "${LEBHOMES02DIRS[@]}"
	do
		STARTTIME=$(date +'%s')
		rsync -avz --progress "$dir" "$DESTSRV":"$DESTPATH" > "$LOGDIR"/lebhomes02-migration.log
		ENDTIME=$(date +'%s')
		TOTALTIME=$(("$ENDTIME" - "$STARTTIME"))
		echo "Migration time: $TOTALTIME seconds" >> "$LOGDIR"/lebhomes02-rsync-$dir-time.log
	done
}

function migrateLH03 {
	for dir in "${LEBHOMES03DIRS[@]}"
	do
		STARTTIME=$(date +'%s')
		rsync -avz --progress "$dir" "$DESTSRV":"$DESTPATH" > "$LOGDIR"/lebhomes03-migration.log
		ENDTIME=$(date +'%s')
		TOTALTIME=$(("$ENDTIME" - "$STARTTIME")) 
		echo "Migration time: $TOTALTIME seconds" >> "$LOGDIR"/lebhomes03-rsync-$dir-time.log
	done
}

function migrateLH04 {
	for dir in "${LEBHOMES04DIRS[@]}"
	do
		STARTTIME=$(date +'%s')
		rsync -avz --progress "$dir" "$DESTSRV":"$DESTPATH" > "$LOGDIR"/lebhomes04-migration.log
		ENDTIME=$(date +'%s')
		TOTALTIME=$(("$ENDTIME" - "$STARTTIME"))
		echo "Migration time: $TOTALTIME seconds" >> "$LOGDIR"/lebhomes04-rsync-$dir-time.log
	done
}

function migrateLH05 {
	for dir in "${LEBHOMES05DIRS[@]}"
	do
		STARTTIME=$(date +'%s')
		rsync -avz --progress "$dir" "$DESTSRV":"$DESTPATH" > "$LOGDIR"/lebhomes05-migration.log
		ENDTIME=$(date +'%s')
		TOTALTIME=$(("$ENDTIME" - "$STARTTIME"))
		echo "Migration time: $TOTALTIME seconds" >> "$LOGDIR"/lebhomes05-rsync-$dir-time.log
	done
}

function migrateLH06 {
	for dir in "${LEBHOMES06DIRS[@]}"
	do
		STARTTIME=$(date +'%s')
		rsync -avz --progress "$dir" "$DESTSRV":"$DESTPATH" > "$LOGDIR"/lebhomes06-migration.log
		ENDTIME=$(date +'%s')
		TOTALTIME=$(("$ENDTIME" - "$STARTTIME"))
		echo "Migration time: $TOTALTIME seconds" >> "$LOGDIR"/lebhomes06-rsync-$dir-time.log
	done
}

function migrateLH07 {
	for dir in "${LEBHOMES05DIRS[@]}"
	do
		STARTTIME=$(date +'%s')
		rsync -avz --progress "$dir" "$DESTSRV":"$DESTPATH" > "$LOGDIR"/lebhomes07-migration.log
		ENDTIME=$(date +'%s')
		TOTALTIME=$(("$ENDTIME" - "$STARTTIME"))
		echo "Migration time: $TOTALTIME seconds" >> "$LOGDIR"/lebhomes07-rsync-$dir-time.log
	done
}


##### Server Selection Prompt #####

printf "\n"
printf "SERVERS"
printf "=-=-=-=-=-=-\n"
printf "1) lebhomes01\n"
printf "2) lebhomes02\n"
printf "3) lebhomes03\n"
printf "4) lebhomes04\n"
printf "5) lebhomes05\n"
printf "6) lebhomes06\n"
printf "7) lebhomes07\n"
printf "Select a server to migrate (1-7): "
read -re SRVSELECTION

case $SRVSELECTION in
	1) migrateLH01
	;;
	2) migrateLH02
	;;
	3) migrateLH03
	;;
	4) migrateLH04
	;;
	5) migrateLH05
	;;
	6) migrateLH06
	;;
	7) migrateLH07
	;;
	*) printf "Please select a number between 1 and 7.\n"
	;;
esac


printf "\nComplete! Logs and metrics written to $LOGDIR"
exit 0
