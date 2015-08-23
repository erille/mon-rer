#!/bin/sh

BLUE=`tput setaf 4`
BOLD=`tput bold`
NORMAL=`tput sgr0`

echo_status() { echo "${BOLD}${BLUE} :: ${NORMAL}${BOLD}$@${NORMAL}"; }

# Make sure this doesn't break on anything else than Linux
UNAME=`uname`
case "$UNAME" in 
	FreeBSD)
		WGET="fetch -o export-TN-GTFS-LAST.zip"
		STAT="stat -f %m"
		;;
	Linux)
		WGET="wget -O export-TN-GTFS-LAST.zip -N"
		STAT="stat -c %Y"
		;;
	*)
		WGET="wget -O export-TN-GTFS-LAST.zip -N"
		;;
esac


cat <<EOF
DATABASE INITIALIZATION/UPDATE SCRIPT FOR RER-WEB
=================================================

You MUST:

 1. Create the database which is going to contain the data;
 2. Create an unprivileged user (it only needs a GRANT SELECT) for the database;
 3. Run this script and supply it with a MySQL user that has administrative
    access to the database.

=================================================
EOF


USER=$1
DATABASE=$2

#
# Get some info needed by user
#
while [ -z "$USER" ]; do
	printf "Username for database (e.g. root)? "
	read USER
done

while [ -z "$DATABASE" ]; do
	printf "Database name (e.g. sncf_gtfs)? "
	read DATABASE
done

#
# Get Perl-GTFS scripts
#
echo_status "Obtaining Perl-GTFS scripts"
if [ -d Perl-GTFS ]; then
	cd Perl-GTFS; git pull; cd ..
else 
	git clone https://github.com/xtab/Perl-GTFS.git || exit 1
fi

#
# Obtain GTFS data
#
echo_status "Obtaining SNCF GTFS data"
mkdir -p input/sncf_gtfs
cd input/sncf_gtfs
$WGET 'https://ressources.data.sncf.com/api/datasets/1.0/sncf-transilien-gtfs/attachments/export_tn_gtfs_last_zip/'
LAST_UPDATE=`$STAT export-TN-GTFS-LAST.zip`

#
# Unzip
#
echo_status "Unzipping SNCF GTFS data"
rm -f agency.txt calendar.txt calendar_dates.txt routes.txt stops.txt stop_times.txt trips.txt
unzip 'export-TN-GTFS-LAST.zip'

#
# Preprocess
#
echo_status "Running preprocessor.pl on GTFS data"
perl -i ../../Perl-GTFS/preprocessor.pl *.txt

#
# Generate
#
echo_status "Generating MySQL table creation statements"
cd ../..

perl ./Perl-GTFS/loadfromfile.pl -p input -d "${DATABASE}"

#
# Import
#
echo_status "Importing GTFS data and station data into MySQL"

echo Last update: ${LAST_UPDATE}

echo "INSERT INTO metadata (\`key\`, \`value\`) VALUES ('dmaj', '${LAST_UPDATE}');" | \
	cat ./Perl-GTFS/load-gtfs.sql ./input/sncf_gtfs/load-data.sql ./db.sql - | \
	sed -e '1,5d' | \
	mysql --local-infile=1 -u "${USER}" -p -D "${DATABASE}" 

echo_status "You're now ready!"
