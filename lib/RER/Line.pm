#!/usr/bin/env perl

package RER::Line;

use Dancer ':syntax';
use Dancer::Plugin::Database;

use strict;
use warnings;
use utf8;
use 5.010;

sub from_prim_id {
    my ($prim_id) = @_;

    return undef unless $prim_id =~ /\ASTIF:Line::C[\d]+:\Z/;

    my $key = ($prim_id =~ s/\ASTIF:Line::([^:]+):\Z/IDFM:$1/r);
    my $data = database->selectrow_hashref(q{
        SELECT route_short_name
          FROM raw.routes
         WHERE route_id = ?},
        {},
        $key);

    if (defined $data) {
        return $data->{route_short_name};
    }
    else {
        return undef;
    }
}

1;
