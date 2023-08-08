#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More tests => 4;

use FindBin;
use Cwd qw(realpath);
use Dancer qw(:script !pass);
use Data::Dumper;

BEGIN { use_ok('RER::Line'); }

my $appdir = realpath("$FindBin::Bin/..");
Dancer::Config::setting(appdir => $appdir);
Dancer::Config::load();

is(RER::Line::from_prim_id('STIF:Line::C01731:'), 'R');
is(RER::Line::from_prim_id('STIF:Line::C99999:'), undef);
is(RER::Line::from_prim_id("STIF:Line::INVALID"), undef);
