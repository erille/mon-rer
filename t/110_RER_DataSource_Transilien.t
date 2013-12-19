#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More tests => 13;

use FindBin;
use Cwd qw(realpath);
use Dancer qw(:script !pass);
use Data::Dumper;

BEGIN { use_ok('RER::DataSource::Transilien'); }

my $appdir = realpath("$FindBin::Bin/..");
Dancer::Config::setting(appdir => $appdir);
Dancer::Config::load();

$RER::Gares::config{dsn} 	= config->{'db_dsn'};
$RER::Gares::config{username} 	= config->{'db_username'};
$RER::Gares::config{password} 	= config->{'db_password'};


my $xml;
$xml .= $_ while <main::DATA>;

my $ds;
is($ds = RER::DataSource::Transilien->new(), undef,
	'Constructor returns undef if no credentials passed');
ok($ds = RER::DataSource::Transilien->new(username => 'test', password => 'bidon', url => 'invalid'), 
	'Constructor works');

my $data_hash;
ok($data_hash = $ds->process_xml_trains($xml), 'process_xml_trains works');

isa_ok($data_hash, 'ARRAY');
is(scalar @$data_hash, 7, 'Data array contains 7 elements');

my $train = $data_hash->[0];
isa_ok($train, 'RER::Train');
is($train->code,   'VERI');
is($train->number, '165303');
is($train->terminus->name, 'Saint-Quentin en Yvelines');
is($train->real_time, '2012-05-23T12:52:00');
is($train->due_time, undef);
is($train->status, 'N');


__END__
<?xml version="1.0" encoding="UTF-8"?>
<passages gare="87393009">
<train><date mode="R">23/05/2012 12:52</date>
<num>165303</num>
<miss>VERI</miss>
<term>87393843</term>
</train>
<train><date mode="R">23/05/2012 12:55</date>
<num>165312</num>
<miss>DEFI</miss>
<term>87382218</term>
</train>
<train><date mode="R">23/05/2012 13:01</date>
<num>165412</num>
<miss>PORO</miss>
<term>87393215</term>
</train>
<train><date mode="R">23/05/2012 13:02</date>
<num>165405</num>
<miss>ROPO</miss>
<term>87393843</term>
</train>
<train><date mode="R">23/05/2012 13:12</date>
<num>148407</num>
<miss>SARA</miss>
<term>87393843</term>
</train>
<train><date mode="R">23/05/2012 13:14</date>
<num>148622</num>
<miss>VICK</miss>
<term>87393157</term>
</train>
<train><date mode="R">23/05/2012 13:16</date>
<num>165514</num>
<miss>POGI</miss>
<term>87393215</term>
</train>
</passages>
