#!/bin/sh

GTFS_DOWNLOAD_DIR="input/sncf_gtfs"
GTFS_EXTRACT_DIR="input/sncf_gtfs"
GTFS_PATH="${GTFS_DOWNLOAD_DIR}/export-TN-GTFS-LAST.zip"
GTFS_URL='https://eu.ftp.opendatasoft.com/sncf/gtfs/transilien-gtfs.zip'

PREPROCESS_CSV='bin/preprocess-csv.pl'

PRIM_DOWNLOAD_DIR="input/prim"
PRIM_RELATIONS_URL='https://data.iledefrance-mobilites.fr/api/explore/v2.1/catalog/datasets/relations/exports/csv?lang=fr&timezone=Europe%2FBerlin&use_labels=true&delimiter=%3B'
PRIM_RELATIONS_PATH="${PRIM_DOWNLOAD_DIR}/orig/relations.csv"
PRIM_ZDA_URL='https://data.iledefrance-mobilites.fr/api/explore/v2.1/catalog/datasets/zones-d-arrets/exports/csv?lang=fr&timezone=Europe%2FBerlin&use_labels=true&delimiter=%3B'
PRIM_ZDA_PATH="${PRIM_DOWNLOAD_DIR}/orig/zda.csv"


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
        *)
            curl --progress-bar -o "$1" "$2"
            ;;
    esac
}


echo_status() { echo "${BOLD}${BLUE} :: ${NORMAL}${BOLD}$@${NORMAL}"; }

preprocess() {
    DATA_DIR=$1
    BASENAME=$2
    shift 2;
    CSV_COLUMNS=$@

    $PREPROCESS_CSV \
        "${DATA_DIR}/orig/${BASENAME}" \
        $CSV_COLUMNS \
        > "${DATA_DIR}/${BASENAME}" || exit 1
}

gtfs_preprocess() {
    preprocess "${GTFS_EXTRACT_DIR}" $@
}

prim_preprocess() {
    preprocess "${PRIM_DOWNLOAD_DIR}" $@
}

get_and_extract_gtfs() {
    echo_status "Obtaining SNCF GTFS data"
    mkdir -p -- "${GTFS_DOWNLOAD_DIR}/orig"
    download "$GTFS_PATH" "$GTFS_URL" || exit 1

    echo_status "Unzipping SNCF GTFS data"
    rm -rf -- "${GTFS_DOWNLOAD_DIR}/orig/"*.txt "${GTFS_DOWNLOAD_DIR}"/*.txt
    unzip -jd "${GTFS_EXTRACT_DIR}/orig" "${GTFS_PATH}" || exit 1

    echo_status "Preprocessing SNCF GTFS data"

    gtfs_preprocess calendar.txt \
        service_id monday tuesday wednesday thursday friday saturday sunday \
        start_date end_date

    gtfs_preprocess calendar_dates.txt \
        service_id date exception_type

    gtfs_preprocess routes.txt \
        route_id route_short_name route_type

    gtfs_preprocess stop_times.txt \
        trip_id arrival_time departure_time stop_id stop_sequence

    gtfs_preprocess trips.txt \
        route_id service_id trip_id trip_headsign trip_short_name
}

get_prim() {
    echo_status "Obtaining PRIM data"
    mkdir -p -- "${PRIM_DOWNLOAD_DIR}/orig"
    rm -rf -- "${PRIM_DOWNLOAD_DIR}/orig/"*.csv

    download "$PRIM_RELATIONS_PATH" "$PRIM_RELATIONS_URL" || exit 1
    download "$PRIM_ZDA_PATH" "$PRIM_ZDA_URL" || exit 1

    echo_status "Preprocessing PRIM data"

    prim_preprocess relations.csv ZdAId ArRId

    prim_preprocess zda.csv ZdAId ZdAType
}
