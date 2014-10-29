# RER::Web

![Screenshot](http://x0r.fr/blogstuff/rer-web.png)

This web app is yet another variation on the "how can I possibly display the
timetable for the 6 next trains in any way I can imagine" theme.  Only this
time, it tries to be classy.  It is primarily intended for display on medium
(tablet/desktop) or large screens (TVs), while trying not to break too badly on
cellphones.

See it in action at [http://monrer.fr/] [1].

I know the SNCF's website does the same thing, but let's face it, this
interface is sexier.  Also, because this was an AJAX and Javascript exercise
for myself, please try not to be too harsh on the "but this is useless"
remarks.

# Dependencies

You will need the following Perl modules:

 * DateTime
 * DateTime::Format::Strptime
 * DBI
 * DBD::mysql
 * Dancer
 * JSON::XS
 * RRD::Simple
 * Text::CSV
 * Template::Plugin::Decode
 * Tie::Handle::CSV
 * XML::Simple
 * YAML

You will also need `git` for the `install.sh` script to work.

Any kind of DBMS will do; however, you will need to load SNCF's rather massive
GTFS data into it and therefore, I recommend MySQL, PostgreSQL or anything
somewhat beefy.  I have tested this with MySQL without any problems.

# Installing

Copy `config.yml.example` to `config.yml` and edit it to suit your needs.

Log into an account with administrative access on MySQL and create the database
holding the data:

	mysql> CREATE DATABASE sncf_gtfs CHARSET utf8 COLLATE utf8_general_ci;

Create a user which only has the necessary privileges.  This is optional, but
highly recommended (not to mention a good security practice):

	mysql> CREATE USER 'rer-web' IDENTIFIED BY 'some-password';
	mysql> GRANT SELECT, EXECUTE ON sncf_gtfs.* TO 'rer-web'@'localhost';

Finally, run `sh ./install.sh`. This install script will download a GTFS
parsing script, download the [GTFS-formatted timetable data] [5] from SNCF's
website, import it into the database, and import a custom-made station database
as well.

**Note**: SNCF update their data once a week. In order to reimport the data,
simply run `./install.sh` again.

# Deployment

Deploy this as you would any Perl Dancer application.  If you really
have no idea how to do this, read the [Dancer::Deployment Perldoc page] [2].

# License

This program is licensed under the 3-clause BSD license.

This program uses the following datasets supplied by SNCF under its [Open Data
License] [3] (in French):

 * [API Prochains départs lignes Transilien C et L] [4]
 * [Horaires des lignes Transilien] [5]

This program also contains a custom database derived from the following datasets,
also supplied by SNCF under [the same terms] [3]:

 * [Gares et points d'arrêts du réseau Transilien] [6]
 * [Lignes par gare en Île-de-France] [7]



[1]: http://monrer.fr
[2]: https://metacpan.org/module/Dancer::Deployment
[3]: http://sncf-data.s3.amazonaws.com/assets/licence-sncf-opendata-eda896b0e6b60d3277a61e548cdb8cb5.pdf
[4]: http://ressources.data.sncf.com/explore/dataset/sncf-prochains-departs-lignes-c-et-l/
[5]: http://ressources.data.sncf.com/explore/dataset/sncf-horaires-des-lignes-transilien/
[6]: http://ressources.data.sncf.com/explore/dataset/sncf-gares-et-arrets-transilien-ile-de-france/
[7]: http://ressources.data.sncf.com/explore/dataset/sncf-lignes-par-gares-idf/
