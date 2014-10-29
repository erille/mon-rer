#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use lib '../lib';
use lib 'lib';

use RER::DataSource::Transilien;
use RER::DataSource::TransilienGTFS;

use RER::Gares;
use FindBin;
use Cwd qw(realpath);
use Dancer qw(:script !pass);
use Data::Dumper;


my $code = $ARGV[0] || die "usage: $0 <tr3>\n";



my $appdir = realpath("$FindBin::Bin/..");
Dancer::Config::setting(appdir => $appdir);
Dancer::Config::load();

$RER::Gares::config{dsn} 	= config->{'db_dsn'};
$RER::Gares::config{username} 	= config->{'db_username'};
$RER::Gares::config{password} 	= config->{'db_password'};

RER::Gares::db_connect();

my $gare = RER::Gares::find(code => $code);
die "$code: gare non valable\n" if ! defined ($gare);

print "code UIC : " . $gare->uic() . "\n";

my $ds  = RER::DataSource::Transilien->new(
	url		=> config->{'sncf_url'},
	username	=> config->{'sncf_username'},
	password	=> config->{'sncf_password'});
my $ds2 = RER::DataSource::TransilienGTFS->new(
	dsn		=> config->{'db_dsn'},
	username	=> config->{'db_username'},
	password	=> config->{'db_password'});

my $data = $ds->get_next_trains($gare);

foreach my $train (@$data) {
	my $terminus_name = ($train->terminus) ? $train->terminus->name : "?";
	utf8::encode($terminus_name);

	my $today = $train->real_time->ymd('-') 
		|| $train->due_time->ymd('-')
		|| `date +'%Y-%m-%d'`;

	my $train2 = $ds2->get_info_for_train($today, $gare->code, $train->number);
	if ($train2 && $train2->[0]) {
		$train = $train->merge($train2->[0]);
	}


	my $delay;
	if ($train->real_time && $train->due_time) {
		$delay = $train->real_time - $train->due_time;
		$delay = $delay->in_units('minutes');
	}


	printf "%6s %4s %-5s %-5s %-1s %-1s %+3d %-30s\n",
		$train->number,
		$train->code,
		substr($train->real_time->time, 0, 5),
		($train->due_time) ? substr($train->due_time->time, 0, 5) : "--:--",
		$train->status,
		$train->line || '?',
		
		scalar(eval { @{$train->stations} } or ()),
		$terminus_name;
}
