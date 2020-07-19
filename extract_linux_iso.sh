#!/bin/sh

### 
### For extracting ISOs into their appropriate folders on FS01
###

ISO=$1
ISOBASENAME=$(basename $ISO)
ISONOEXT=$( echo "${ISOBASENAME%.*}" )
ISO_OSNAME=$(echo $ISOBASENAME | cut -d - -f 1)
OSMAJ=$(echo $ISOBASENAME | cut -d . -f 1 | cut -d - -f 2)
OSMIN=$(echo $ISOBASENAME | cut -d . -f 2 | cut -d - -f 1)
NFSISOPATH='/srv/iso'

mountAndCopy () {
    # Create ISO mount path and perform mount
    if [ ! -d /mnt/$ISO_OSNAME ]; then
        mkdir -p /mnt/$ISOBASENAME && mount -o loop $1 /mnt/$ISOBASENAME
    else
        umount /mnt/$ISON
        mount -o loop $1 /mnt/$ISOBASENAME
    fi

    # Copy the ISO contents to the ISO share
    cp -rv /mnt/$ISOBASENAME/. $NFSISOPATH/$OSNAME/$OSMAJ/$OSMIN

    printf "\n\n"
    echo "Done!"
}

confirmChoice () {
    read -p "Does this look correct? [y/n] " CONFIRM

    case $CONFIRM in
        [Yy])
            mountAndCopy()
            ;;
        [Nn])
            exit 0
            ;;
        *)
            echo "Invalid choice."
            confirmChoice
            ;;
    esac
}

if [ "$ISO_OSNAME" == "rhel" ]; then
    OSNAME='RedHat'
else
    OSNAME=$ISO_OSNAME
fi

echo "OS Nmae: $OSNAME"
echo "OS Major Version: $OSMAJ"
echo "OS Minor Version: $OSMIN"
printf "\n\n"

confirmChoice
mountAndCopy

exit
