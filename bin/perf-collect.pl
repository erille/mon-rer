#!/usr/bin/perl

use warnings;
use strict;

use Dancer ':script';
use Dancer::Plugin::Redis;
use RRD::Simple;


if (! config->{'use_redis'})
{
	warn 'Not using redis in this configuration, nothing to do!';
	exit
}

my $time = time;

sub update_data {
	my ($rrd) = @_;

        my $api_incoming = redis->get("rer-web.api_incoming") || 0;
        my $api_sent     = redis->get("rer-web.api_sent") || 0;
        my $api_errors   = redis->get("rer-web.api_errors") || 0;

        debug "counters: incoming = $api_incoming, sent = $api_sent, errors = $api_errors";

	$rrd->update($time,
		api_incoming 	=> $api_incoming,
		api_sent	=> $api_sent,
		api_errors	=> $api_errors,
	);
}

sub open_rrd_file {
	my ($file) = @_;

	my $rrd = RRD::Simple->new(file => $file);
	if (! -e $file) {
		$rrd->create('month',
			api_incoming 	=> 'COUNTER',
			api_sent	=> 'COUNTER',
			api_errors	=> 'COUNTER',
		);
	}

	return $rrd;
}

my $rrd = open_rrd_file(config->{'rrd_file'})
	or die config->{'rrd_file'} . ": cannot open RRD file\n";

update_data($rrd);
