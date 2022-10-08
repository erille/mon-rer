#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use DateTime;
use JSON qw(decode_json);
use Test::More;

use Cwd qw(realpath);
use Dancer qw(:script !pass);

BEGIN { use_ok('RER::DataSource::PRIM'); }

my $appdir = realpath("$FindBin::Bin/..");
Dancer::Config::setting(appdir => $appdir);
Dancer::Config::load();

$RER::Gares::config{dsn} 	= config->{'db_dsn'};
$RER::Gares::config{username} 	= config->{'db_username'};
$RER::Gares::config{password} 	= config->{'db_password'};

sub load_json {
    my ($file) = @_;
    local $/ = undef;
    open(my $FH, '<', $file) or die $!;
    my $json_text = <$FH>;
    my $obj = decode_json($json_text);
    close($FH);

    return $obj;
}

# Example data for Gare de Lyon
my $prim1 = load_json('t/data/prim1.json');

my $trains = RER::DataSource::PRIM::parse_result($prim1);

ok(scalar(@$trains) > 6);

is($trains->[0]->number, '151815');
is($trains->[0]->code, 'GAMO');
is($trains->[0]->status, 'N');
is($trains->[0]->platform, undef);
is($trains->[0]->real_time,
   DateTime->new(
       year => 2022, month => 10, day => 7,
       hour => 7, minute => 16, second => 0,
       time_zone => 'UTC'));
is($trains->[0]->due_time,
   DateTime->new(
       year => 2022, month => 10, day => 7,
       hour => 7, minute => 16, second => 0,
       time_zone => 'UTC'));
is($trains->[0]->terminus->code, 'MS');


is($trains->[1]->number, '155827');
is($trains->[1]->code, 'ROPE');
is($trains->[1]->status, 'S');
is($trains->[1]->platform, '1');

# A train operated by RATP
is($trains->[78]->number, 'QMAR36');
is($trains->[78]->real_time,
   DateTime->new(
       year => 2022, month => 10, day => 7,
       hour => 7, minute => 43, second => 53,
       time_zone => 'UTC'));
is($trains->[78]->due_time, undef);

done_testing();
