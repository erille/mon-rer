use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'RER::Web',
    AUTHOR              => q{x0r <x0r@x0r.fr>},
    VERSION_FROM        => 'lib/RER/Web.pm',
    ABSTRACT            => 'HTML5/JavaScript Transilien screen simulator powered by Perl Dancer.',
    LICENSE             => 'bsd',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'YAML'       => 0,
        'Dancer'     => 1.311,
        'WWW::Mechanize' => 0,
        'DBI'        => 0,
        'JSON'       => 0,
        'JSON::XS'   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'RER-Web-*' },
);

# vi:ts=4:sw=4:et
