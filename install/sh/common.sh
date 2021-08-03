#!/bin/sh

GTFS_DOWNLOAD_DIR="input/sncf_gtfs"
GTFS_EXTRACT_DIR="input/sncf_gtfs"
GTFS_PATH="${GTFS_DOWNLOAD_DIR}/export-TN-GTFS-LAST.zip"
GTFS_URL='https://eu.ftp.opendatasoft.com/sncf/gtfs/gtfs-nouveau-format.zip' 

# Make sure this doesn't break on anything else than Linux
UNAME=`uname`
case "$UNAME" in
        FreeBSD)
                WGET="fetch -o ${GTFS_PATH}"
                STAT="stat -f %m"

                BLUE=`tput AF 4`
                BOLD=`tput md`
                NORMAL=`tput me`
                ;;
        Linux)
                WGET="wget -O ${GTFS_PATH} -N"
                STAT="stat -c %Y"

                BLUE=`tput setaf 4`
                BOLD=`tput bold`
                NORMAL=`tput sgr0`
                ;;
        *)
                WGET="wget -O ${GTFS_PATH} -N"

                BLUE=""
                BOLD=""
                NORMAL=""
                ;;
esac


echo_status() { echo "${BOLD}${BLUE} :: ${NORMAL}${BOLD}$@${NORMAL}"; }

get_and_extract_gtfs() {
    echo_status "Obtaining SNCF GTFS data"
    mkdir -p -- "${GTFS_DOWNLOAD_DIR}"
    $WGET $GTFS_URL || exit 1

    echo_status "Unzipping SNCF GTFS data"
    rm -f -- "${GTFS_DOWNLOAD_DIR}"/*.txt
    unzip -jd "${GTFS_EXTRACT_DIR}" "${GTFS_PATH}" || exit 1
}

