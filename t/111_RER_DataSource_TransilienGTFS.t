#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More tests => 8;

use FindBin;
use Cwd qw(realpath);
use Dancer qw(:script !pass);
use Dancer::Plugin::Database;
use RER::Web;

BEGIN {
    use_ok('RER::Gare');
    use_ok('RER::DataSource::TransilienGTFS');
}

my $appdir = realpath("$FindBin::Bin/..");
Dancer::Config::setting(appdir => $appdir);
Dancer::Config::load();

$RER::Gares::config{dsn} 	= config->{'db_dsn'};
$RER::Gares::config{username} 	= config->{'db_username'};
$RER::Gares::config{password} 	= config->{'db_password'};

my $ds;
ok($ds = RER::DataSource::TransilienGTFS->new(dbh => database));

my $data;
ok($data = $ds->get_info_for_trains(
       DateTime->new(year => 2022, month => 4, day => 1, hour => 14, minute => 0),
       RER::Gare->new(name => "Juvisy", uic => 8754524, code => 'JY', lines => [qw(C D)] ),
       ['148228']));
isa_ok($data, 'ARRAY');
is(scalar @$data, 1, 'Array contains one element');
isa_ok($data->[0], 'RER::Train');
is($data->[0]->number, '148228');

