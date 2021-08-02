# RER::Web

![Screenshot](http://x0r.fr/blogstuff/rer-web.png)

This web app is yet another variation on the "how can I possibly display the
timetable for the 6 next trains in any way I can imagine" theme.  This project
started an AJAX and Javascript exercise for myself, but a handful of people
have convinced me to make this public.  Only this time, it tries to be classy.
It is primarily intended for display on medium (tablet/desktop) or large
screens (TVs), while trying not to break too badly on cellphones.

See it in action at [http://monrer.fr/] [1].

# Dependencies

You will need the following Perl modules:

 * DateTime
 * DateTime::Format::Strptime
 * DateTime::Format::Pg
 * DBI
 * DBD::Pg
 * Dancer
 * Dancer::Plugin::Database
 * LWP::Protocol::https
 * JSON::XS
 * RRD::Simple
 * Text::CSV
 * Template::Plugin::Decode
 * XML::Simple
 * YAML

You will also need PostgreSQL. No other DBMSes are supported. Sorry, but I’ve
had too many issues with MySQL so I can’t recommend anything but PostgreSQL.

# Installing

Copy `config.yml.example` to `config.yml` and edit it to suit your needs.

Log into an account with superuser access on PostgreSQL and create two
database roles.  The first one is used for normal operation and the second one
is used by update scripts:

    postgres=# CREATE ROLE "rer_web" LOGIN PASSWORD 'secret';
    postgres=# CREATE ROLE "rer_web_update" LOGIN PASSWORD 'secret';

Finally, run `sh ./install.sh`. This install script will create a database,
download the [GTFS-formatted timetable data] [5] from SNCF's website, import
it into the database, import a custom-made station database, and grant the
necessary privileges to the previously-defined users.

**Note**: if you use different user accounts or wish a different database
name, type `sh ./install.sh -h` to see how to alter these options.

**Note 2**: SNCF update their data once a week. In order to reimport the data,
simply run `./install.sh` again.

# Deployment

Deploy this as you would any Perl Dancer application.  If you really
have no idea how to do this, read the [Dancer::Deployment Perldoc page] [2].

# License

This program is licensed under the 3-clause BSD license.

This program uses the following datasets supplied by SNCF under its [Open Data
License] [3] (in French):

 * [API Prochains départs lignes Transilien] [4]
 * [Horaires des lignes Transilien] [5]

This program also contains a custom database derived from the following datasets,
also supplied by SNCF under [the same terms] [3]:

 * [Gares et points d'arrêts du réseau Transilien] [6]
 * [Lignes par gare en Île-de-France] [7]



[1]: http://monrer.fr
[2]: https://metacpan.org/module/Dancer::Deployment
[3]: http://sncf-data.s3.amazonaws.com/assets/licence-sncf-opendata-eda896b0e6b60d3277a61e548cdb8cb5.pdf
[4]: https://ressources.data.sncf.com/explore/dataset/api-temps-reel-transilien/information/
[5]: http://ressources.data.sncf.com/explore/dataset/sncf-horaires-des-lignes-transilien/
[6]: http://ressources.data.sncf.com/explore/dataset/sncf-gares-et-arrets-transilien-ile-de-france/
[7]: http://ressources.data.sncf.com/explore/dataset/sncf-lignes-par-gares-idf/
