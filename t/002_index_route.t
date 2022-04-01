#!/usr/bin/env perl

use Test::More tests => 3;
use strict;
use warnings;

use FindBin;
use Cwd qw(realpath);
use Dancer qw(:script !pass);
use RER::Web;
use Dancer::Test;

my $appdir = realpath("$FindBin::Bin/..");
Dancer::Config::setting(appdir => $appdir);
Dancer::Config::load();

$RER::Gares::config{dsn} 	= config->{'db_dsn'};
$RER::Gares::config{username} 	= config->{'db_username'};
$RER::Gares::config{password} 	= config->{'db_password'};

route_exists [GET => '/'], 'a route handler is defined for /';
response_status_is ['GET' => '/'], 302, 'response status is 302 for /';
response_status_is ['GET' => '/?s=EVC'], 200, 'response status is 200 for /?s=EVC';
