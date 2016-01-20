#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More tests => 21;

use FindBin;
use Cwd qw(realpath);
use Dancer qw(:script !pass);
use Data::Dumper;

BEGIN { use_ok('RER::DataSource::TransilienGTFS'); }

my $appdir = realpath("$FindBin::Bin/..");
Dancer::Config::setting(appdir => $appdir);
Dancer::Config::load();

$RER::Gares::config{dsn} 	= config->{'db_dsn'};
$RER::Gares::config{username} 	= config->{'db_username'};
$RER::Gares::config{password} 	= config->{'db_password'};

my $ds;
ok($ds = RER::DataSource::TransilienGTFS->new(
	dsn		=> config->{'db_dsn'},
	username	=> config->{'db_username'},
	password	=> config->{'db_password'},
));

my $data;
# ok($data = $ds->get_info_for_train('2013-12-11', 'JY', '121414'));
ok($data = $ds->get_info_for_train('2016-02-06', 'JY', '147483'));
isa_ok($data, 'ARRAY');
is(scalar @$data, 1, 'Array contains one element');
isa_ok($data->[0], 'RER::Train');
is($data->[0]->number, '147483');

# Tests de check_ligne
is(RER::DataSource::TransilienGTFS::check_ligne('A', 'RER A'), 'A', 'check_ligne for RER A');
is(RER::DataSource::TransilienGTFS::check_ligne('B', 'RER B'), 'B', 'check_ligne for RER B');
is(RER::DataSource::TransilienGTFS::check_ligne('C', 'RER C'), 'C', 'check_ligne for RER C');
is(RER::DataSource::TransilienGTFS::check_ligne('D', 'RER D'), 'D', 'check_ligne for RER D');
is(RER::DataSource::TransilienGTFS::check_ligne('E', 'RER E'), 'E', 'check_ligne for RER E');
is(RER::DataSource::TransilienGTFS::check_ligne('N', 'Paris Rive Gauche'), 'N', 'check_ligne for Transilien N');
is(RER::DataSource::TransilienGTFS::check_ligne("Gare d'Aus", 'RER C'), 'C', 'check_ligne for broken RER C');
is(RER::DataSource::TransilienGTFS::check_ligne("Villiers l", 'RER D'), 'D', 'check_ligne for broken RER D');
is(RER::DataSource::TransilienGTFS::check_ligne("non valable", 'RER D'), 'D', 'check_ligne for generic broken route_short_name');
is(RER::DataSource::TransilienGTFS::check_ligne('non valable', 'Paris Nord'), '', 'check_ligne for broken Transilien H/K');
is(RER::DataSource::TransilienGTFS::check_ligne('non valable', 'Paris St Lazare'), '', 'check_ligne for broken Transilien J/L');
is(RER::DataSource::TransilienGTFS::check_ligne('non valable', 'Paris Est'), 'P', 'check_ligne for broken Transilien P');
is(RER::DataSource::TransilienGTFS::check_ligne('non valable', 'Paris Sud Est'), 'R', 'check_ligne for broken Transilien R');
is(RER::DataSource::TransilienGTFS::check_ligne('non valable', 'Paris Rive Gauche'), 'N', 'check_ligne for broken Transilien N');

done_testing;
