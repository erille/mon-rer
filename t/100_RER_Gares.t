#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More tests => 24;

use FindBin;
use Cwd qw(realpath);
use Dancer qw(:script !pass);
use Data::Dumper;

BEGIN { use_ok('RER::Gares'); }

my $appdir = realpath("$FindBin::Bin/..");
Dancer::Config::setting(appdir => $appdir);
Dancer::Config::load();

$RER::Gares::config{dsn} 	= config->{'db_dsn'};
$RER::Gares::config{username} 	= config->{'db_username'};
$RER::Gares::config{password} 	= config->{'db_password'};

ok (RER::Gares::db_connect());

like (RER::Gares::get_last_update(), qr/[\d]+ [^ ]+ [\d]{4}/);

#
# Tests for get_station_by_code
#
my $station = RER::Gares::find(code => 'CLX');
isa_ok($station, 'RER::Gare');

is($station->code, 'CLX');
# is() doesn't work here because of utf-8
is($station->name, "Châtelet les Halles");
ok(utf8::is_utf8($station->name), '$station->name is utf-8');
is($station->uic,  '8775860');

$station = RER::Gares::find(uic => '8775860');
isa_ok($station, 'RER::Gare');

is($station->code, 'CLX');
is($station->name, 'Châtelet les Halles');
is($station->uic,  '8775860');
is_deeply($station->lines, [ qw(A B D) ], 'CLX lines is [A, B, D]');
is_deeply(RER::Gares::get_lines('8739300'), [ qw(C N U) ], 'VC lines is [C, N, U]');
is_deeply(RER::Gares::get_lines('8754524'), [ qw(C D) ], 'JY lines is [C, D]');

$station = RER::Gares::find(uic => '87393009');
isa_ok($station, 'RER::Gare');
is($station->name, 'Versailles Chantiers');
is($station->uic,  '8739300');

$station = RER::Gares::find(code => 'prout');
is($station, undef, 'Invalid station yields undef');

#
# Tests for get_autocomp
#
my $list = RER::Gares::get_autocomp('evry');

isa_ok(\@$list, 'ARRAY', "get_autocomp returns an array");
is(scalar(@$list), 2, 'Autocomp for "evry" contains 2 items');

$list = RER::Gares::get_autocomp('clx');

is(scalar(@$list), 1, 'Autocomp for "clx" contains 1 item');

isa_ok($list->[0], 'RER::Gare');
is($list->[0]->name, 'Châtelet les Halles');

# done_testing;
