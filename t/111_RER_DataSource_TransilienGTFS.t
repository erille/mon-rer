#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More tests => 7;

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
ok($data = $ds->get_info_for_train('2013-12-11', 'JY', '121414'));
isa_ok($data, 'ARRAY');
is(scalar @$data, 1, 'Array contains one element');
isa_ok($data->[0], 'RER::Train');
is($data->[0]->number, '121414');

done_testing;
