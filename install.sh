#!/bin/sh

# Make sure this doesn't break on anything else than Linux
UNAME=`uname`
case "$UNAME" in
        FreeBSD)
                WGET="fetch -o input/sncf_gtfs/export-TN-GTFS-LAST.zip"
                STAT="stat -f %m"

                BLUE=`tput AF 4`
                BOLD=`tput md`
                NORMAL=`tput me`
                ;;
        Linux)
                WGET="wget -O input/sncf_gtfs/export-TN-GTFS-LAST.zip -N"
                STAT="stat -c %Y"

                BLUE=`tput setaf 4`
                BOLD=`tput bold`
                NORMAL=`tput sgr0`
                ;;
        *)
                WGET="wget -O input/sncf_gtfs/export-TN-GTFS-LAST.zip -N"

                BLUE=""
                BOLD=""
                NORMAL=""
                ;;
esac

echo_status() { echo "${BOLD}${BLUE} :: ${NORMAL}${BOLD}$@${NORMAL}"; }

usage() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "    -U <user>     Database role to connect as for this script"
    echo "    -D <database> Name of database to create"
    echo "    -k <role>     Name of database updater role to use"
    echo "    -u <role>     Name of database role to use for normal operation"
    echo "    -y            Do not prompt for confirmation"
    echo
}

args=$(getopt hU:D:u:k:y $*)
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
            db_superuser="$2"
            shift; shift
            ;;
        -D)
            db_name="$2"
            shift; shift
            ;;
        -k)
            db_updater_role="$2"
            shift; shift
            ;;
        -u)
            db_normal_role="$2"
            shift; shift
            ;;
        -y)
            no_confirm="yes"
            shift; shift
            ;;
        --)
            shift; break
    esac
done

: ${db_superuser:=postgres}
: ${db_name:="rer_web"}
: ${db_updater_role:="rer_web_update"}
: ${db_normal_role:="rer_web"}
: ${no_confirm:="no"}

#
# Confirm data
#

if [ "$no_confirm" != "yes" ]; then
    echo "This script will use the following parameters:"
    echo
    echo " * Database superuser:      ${BOLD}$db_superuser${NORMAL}"
    echo " * Database name to create: ${BOLD}$db_name${NORMAL}"
    echo " * Database updater role:   ${BOLD}$db_updater_role${NORMAL}"
    echo " * Normal usage role:       ${BOLD}$db_normal_role${NORMAL}"
    echo
    echo "Press ENTER to start, or Ctrl-C to cancel."
    read
fi

#
# Obtain GTFS data
#
echo_status "Obtaining SNCF GTFS data"
mkdir -p input/sncf_gtfs
$WGET 'https://eu.ftp.opendatasoft.com/sncf/gtfs/gtfs-nouveau-format.zip' || exit 1
LAST_UPDATE=`$STAT input/sncf_gtfs/export-TN-GTFS-LAST.zip`

#
# Unzip
#
echo_status "Unzipping SNCF GTFS data"
rm -f input/sncf_gtfs/*.txt
unzip -jd input/sncf_gtfs 'input/sncf_gtfs/export-TN-GTFS-LAST.zip' || exit 1

echo_status "Setting up and populating database"

psql -X --quiet -f - -U "$db_superuser" <<-EOF
CREATE DATABASE "$db_name";

\c "$db_name"

REVOKE ALL ON SCHEMA PUBLIC FROM PUBLIC;

GRANT CREATE ON DATABASE "$db_name" TO "$db_updater_role";

GRANT CREATE, USAGE ON SCHEMA public TO "$db_updater_role";

ALTER DEFAULT PRIVILEGES
    FOR ROLE "$db_updater_role"
    GRANT SELECT ON TABLES TO "$db_normal_role";

ALTER DEFAULT PRIVILEGES
    FOR ROLE "$db_updater_role"
    GRANT EXECUTE ON FUNCTIONS TO "$db_normal_role";

SET SESSION AUTHORIZATION "$db_updater_role";

\i install/install.sql

INSERT INTO metadata (key, value)
    VALUES ('dmaj', ${LAST_UPDATE})
    ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

RESET SESSION AUTHORIZATION;

REVOKE CREATE ON DATABASE "$db_name" FROM "$db_updater_role";

GRANT USAGE ON SCHEMA raw, public TO "$db_normal_role";
EOF

# TODO: write an install/update.sql script that also temporarily drops the
# constraints before reloading everything

if [ $? -eq 0 ]; then
    echo_status "You're now ready!"
else
    echo "Database creation failed!" >&2
    exit 1
fi
