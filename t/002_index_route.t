#!/usr/bin/env perl

use Test::More tests => 3;
use strict;
use warnings;

# the order is important
use RER::Web;
use Dancer::Test;

route_exists [GET => '/'], 'a route handler is defined for /';
response_status_is ['GET' => '/'], 302, 'response status is 302 for /';
response_status_is ['GET' => '/?s=EVC'], 200, 'response status is 200 for /?s=EVC';
