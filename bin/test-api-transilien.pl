#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use 5.010;

use lib '../lib';
use lib 'lib';

use RER::DataSource::Transilien;
use RER::DataSource::TransilienGTFS;

use RER::Gares;
use Dancer qw(:script !pass);
use Dancer::Plugin::Database;

binmode STDOUT, ':encoding(UTF-8)';

my $code = $ARGV[0] || die "usage: $0 <tr3>\n";

my $gare = RER::Gares::find(code => $code);
die "$code: gare non valable\n" if ! defined ($gare);

print "code UIC : " . $gare->uic() . "\n";

my $ds  = RER::DataSource::Transilien->new(
    url		=> config->{'sncf_url'},
    username	=> config->{'sncf_username'},
    password	=> config->{'sncf_password'});
my $ds2 = RER::DataSource::TransilienGTFS->new(dbh => database);

my $real_time_data = $ds->get_next_trains($gare);
my @data = @{$ds2->complete_train_info($gare, $real_time_data)};

foreach my $train (@data) {
    my $terminus_name = ($train->terminus) ? $train->terminus->name : "?";

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

        (defined $train->stations ? scalar(@{$train->stations}) : 0),
        $terminus_name;
}
