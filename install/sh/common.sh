#!/bin/sh

GTFS_DOWNLOAD_DIR="input/sncf_gtfs"
GTFS_EXTRACT_DIR="input/sncf_gtfs"
GTFS_PATH="${GTFS_DOWNLOAD_DIR}/export-TN-GTFS-LAST.zip"
GTFS_URL='https://eu.ftp.opendatasoft.com/sncf/gtfs/transilien-gtfs.zip'

PRIM_DOWNLOAD_DIR="input/prim"
PRIM_RELATIONS_URL='https://data.iledefrance-mobilites.fr/api/explore/v2.1/catalog/datasets/relations/exports/csv?lang=fr&timezone=Europe%2FBerlin&use_labels=true&delimiter=%3B'
PRIM_RELATIONS_PATH="${PRIM_DOWNLOAD_DIR}/relations.csv"
PRIM_ZDA_URL='https://data.iledefrance-mobilites.fr/api/explore/v2.1/catalog/datasets/zones-d-arrets/exports/csv?lang=fr&timezone=Europe%2FBerlin&use_labels=true&delimiter=%3B'
PRIM_ZDA_PATH="${PRIM_DOWNLOAD_DIR}/zda.csv"


# Make sure this doesn't break on anything else than Linux
UNAME=`uname`
case "$UNAME" in
        FreeBSD)
                STAT="stat -f %m"

                BLUE=`tput AF 4`
                BOLD=`tput md`
                NORMAL=`tput me`
                ;;
        Linux)
                STAT="stat -c %Y"

                BLUE=`tput setaf 4`
                BOLD=`tput bold`
                NORMAL=`tput sgr0`
                ;;
        *)
                BLUE=""
                BOLD=""
                NORMAL=""
                ;;
esac

download() {
    case "$UNAME" in
        FreeBSD)
            fetch -o "$1" "$2"
            ;;
        Linux)
            wget -O "$1" -N "$2"
            ;;
        *)
            wget -O "$1" -N "$2"
            ;;
    esac
}


echo_status() { echo "${BOLD}${BLUE} :: ${NORMAL}${BOLD}$@${NORMAL}"; }

get_and_extract_gtfs() {
    echo_status "Obtaining SNCF GTFS data"
    mkdir -p -- "${GTFS_DOWNLOAD_DIR}"
    download "$GTFS_PATH" "$GTFS_URL" || exit 1

    echo_status "Unzipping SNCF GTFS data"
    rm -f -- "${GTFS_DOWNLOAD_DIR}"/*.txt
    unzip -jd "${GTFS_EXTRACT_DIR}" "${GTFS_PATH}" || exit 1
}

get_prim() {
    echo_status "Obtaining PRIM data"
    mkdir -p -- "${PRIM_DOWNLOAD_DIR}"
    download "$PRIM_RELATIONS_PATH" "$PRIM_RELATIONS_URL" || exit 1
    download "$PRIM_ZDA_PATH" "$PRIM_ZDA_URL" || exit 1
}
