#!/usr/bin/env perl

use Test::More tests => 14;
use strict;
use warnings;
use utf8;

# the order is important
use RER::Web;
use Dancer::Test;

BEGIN {
	use_ok 'RER::Gares';
}

route_exists [GET => '/autocomp'], 'a route handler is defined for /autocomp';

sub autocomp_test {
	my ($url, $str) = @_;

	my $response = dancer_response GET => $url;
	is $response->{status}, 200, "$url works";
	is $response->content_type, 'application/json', 
		"$url has the right Content-Type header";

    my $content = $response->content;
    utf8::encode($content);
	is_deeply Dancer::from_json($content),
		RER::Gares::get_autocomp($str),
		"$url returns the correct data";
}


autocomp_test '/autocomp', '';
autocomp_test '/autocomp?s=', '';
autocomp_test '/autocomp?s=jy', 'jy';
autocomp_test '/autocomp?s=evry', 'evry';

