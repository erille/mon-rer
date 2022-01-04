#!/usr/bin/env perl

use warnings;
use strict;
use utf8;
use 5.010;

use Dancer qw(:script);
use Dancer::Plugin::Database;
use DateTime::Format::Pg;
use RRD::Simple;

our @stats_keys = qw(api_incoming api_sent api_errors);

sub process_raw_stats_entry {
    my ($entry) = @_;

    my $time   = DateTime::Format::Pg->parse_timestamptz($entry->{minute})->epoch;
    my $events = from_json($entry->{events});

    # This creates a hash with the correct keys in @stats_keys and adds a “time” key.
    return {(map { $_ => ($events->{$_} // 0) } @stats_keys),
            (time => $time)};
}

sub get_stats_since_last_update {
    my ($rrd) = @_;

    my $last_update = DateTime::Format::Pg->format_timestamptz(
        DateTime->from_epoch(epoch => $rrd->last()));

    my @raw_stats = database->quick_select(
        'stats_by_minute', {minute => {gt => $last_update}});

    return [map { process_raw_stats_entry($_) } @raw_stats];
}

sub update_data {
    my ($rrd) = @_;

    foreach (@{get_stats_since_last_update($rrd)}) {
        $rrd->update($_->{time}, %$_{@stats_keys});
    }
}

sub open_rrd_file {
    my ($file) = @_;

    my $rrd = RRD::Simple->new(file => $file);
    if (! -e $file) {
        $rrd->create('month', map { $_ => 'GAUGE' } @stats_keys);
    }

    return $rrd;
}

my $rrd = open_rrd_file(config->{'rrd_file'})
    or die config->{'rrd_file'} . ": cannot open RRD file\n";

update_data($rrd);
