#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More tests => 22;

use FindBin;
use Cwd qw(realpath);
use Dancer qw(:script !pass);
use Data::Dumper;

BEGIN { use_ok('RER::Gares'); }

my $appdir = realpath("$FindBin::Bin/..");
Dancer::Config::setting(appdir => $appdir);
Dancer::Config::load();

like (RER::Gares::get_last_update(), qr/[\d]+ [^ ]+ [\d]{4}/);

#
# Tests for get_station_by_code
#
my $station = RER::Gares::find(code => 'CLX');
isa_ok($station, 'RER::Gare');

is($station->code, 'CLX');
is($station->name, "Châtelet – Les Halles");
is(ord(substr($station->name, 2)), 0xe2);
is($station->uic,  '8775860');

$station = RER::Gares::find(uic => '8775860');
isa_ok($station, 'RER::Gare');

is($station->code, 'CLX');
is($station->name, 'Châtelet – Les Halles');
is($station->uic,  '8775860');
is_deeply($station->lines, [ qw(A B D) ], 'CLX lines is [A, B, D]');

$station = RER::Gares::find(uic => '87393009');
isa_ok($station, 'RER::Gare');
is($station->name, 'Versailles Chantiers');
is($station->uic,  '8739300');

$station = RER::Gares::find(code => 'prout');
is($station, undef, 'Invalid station yields undef');

$station = RER::Gares::find(prim_key_arr => 'STIF:StopPoint:Q:411481:');
isa_ok($station, 'RER::Gare');
is($station->name, 'Montargis');

#
# Tests for get_autocomp
#
my $list = RER::Gares::get_autocomp('evry');

isa_ok(\@$list, 'ARRAY', "get_autocomp returns an array");
is(scalar(@$list), 2, 'Autocomp for "evry" contains 2 items');

$list = RER::Gares::get_autocomp('clx');

is(scalar(@$list), 1, 'Autocomp for "clx" contains 1 item');

is($list->[0]->{name}, 'Châtelet – Les Halles');

# done_testing;
