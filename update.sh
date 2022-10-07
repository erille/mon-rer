#!/bin/sh

. ./install/sh/common.sh

usage() {
    echo "Usage: $0 -U <user> -D <database>"
}

args=$(getopt hU: $*)
if [ $? -ne 0 ]; then
    usage
    exit 2
fi

set -- $args

while :; do
    case "$1" in
        -h)
            usage
            exit
            ;;
        -U)
            db_updater_role="$2"
            shift; shift
            ;;
        -D)
            db_name="$2"
            shift; shift
            ;;
        --)
            shift; break
    esac
done

: ${db_updater_role:="rer_web_update"}
: ${db_name:="rer_web"}

#
# Obtain GTFS data
#

get_and_extract_gtfs
get_prim
LAST_UPDATE=`$STAT "${GTFS_PATH}"`

#
# Update database
#

echo_status "Updating database"
psql -X --quiet "$db_name" "$db_updater_role" \
     -f install/update.sql \
     -c "INSERT INTO metadata (key, value)
             VALUES ('dmaj', ${LAST_UPDATE})
             ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;"

if [ $? -eq 0 ]; then
    echo_status "Update completed successfully"
else
    echo "Database creation failed!" >&2
    exit 1
fi
