#!/bin/sh

BLUE=`tput setaf 4`
BOLD=`tput bold`
NORMAL=`tput sgr0`

echo_status() { echo "${BOLD}${BLUE} :: ${NORMAL}${BOLD}$@${NORMAL}"; }


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
	git clone https://github.com/xtab/Perl-GTFS.git
fi

#
# Obtain GTFS data
#
echo_status "Obtaining SNCF GTFS data"
mkdir -p input/sncf_gtfs
cd input/sncf_gtfs
wget -N 'http://files.transilien.com/horaires/gtfs/export-TN-GTFS-LAST.zip'
LAST_UPDATE=`stat -c '%Y' export-TN-GTFS-LAST.zip`

#
# Unzip
#
echo_status "Unzipping SNCF GTFS data"
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

echo "INSERT INTO metadata (\`key\`, \`value\`) VALUES ('dmaj', '${LAST_UPDATE}');" 

echo "INSERT INTO metadata (\`key\`, \`value\`) VALUES ('dmaj', '${LAST_UPDATE}');" | \
	cat ./input/sncf_gtfs/load-data.sql ./db.sql -  | \
	mysql -u "${USER}" -p -D "${DATABASE}" 

echo_status "You're now ready!"
