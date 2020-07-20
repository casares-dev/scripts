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
    if [ ! -d /mnt/$ISONOEXT ]; then
        mkdir -p /mnt/$ISONOEXT
        mount -o loop $1 /mnt/$ISONOEXT/
    else
        umount /mnt/$ISONOEXT
        mount -o loop $1 /mnt/$ISONOEXT
    fi

    if [ ! -d $NFSISOPATH/$OSNAME/$OSMAJ/$OSMIN ]; then
        echo "Creating copy path in ISO share..."
        mkdir -p $NFSISOPATH/$OSNAME/$OSMAJ/$OSMIN || echo "Could not create folder."
    fi

    # Copy the ISO contents to the ISO share
    cp -rv /mnt/$ISONOEXT/. $NFSISOPATH/$OSNAME/$OSMAJ/$OSMIN

    printf "\n\n"
    echo "Unmounting ISO..."
    umount /mnt/$ISONOEXT
    printf "\n\n"
    echo "Done!"
}

confirmChoice () {
    read -p "Does this look correct? [y/n] " CONFIRM

    case $CONFIRM in
        [Yy])
            mountAndCopy
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
elif [ "$ISO_OSNAME" == "debian" ]; then
    OSNAME="Debian"
elif [ "$ISO_OSNAME" == "alpine"]; then
    OSNAME="Alpine"
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
