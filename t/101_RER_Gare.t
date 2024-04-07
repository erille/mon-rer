#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More tests => 9;

BEGIN { use_ok('RER::Gare'); }

#
# Constructor tests
#

my $obj;
is ($obj = RER::Gare->new(name => undef, code => 'JY', lines => [qw(C D)] ), undef, 'Constructor returns undef if name is undef');
is ($obj = RER::Gare->new(code => 'JY', lines => [qw(C D)] ), undef, 'Constructor returns undef if name is missing');

#
# Getter/setter tests
#

my $jy;
ok ($jy = RER::Gare->new(name => "Juvisy", code => 'JY', lines => [qw(C D)] ), 'Object creation works');
isa_ok ($jy, 'RER::Gare');
is ($jy->name, 'Juvisy', '"name" getter works');
is ($jy->code, 'JY', '"code" getter works');
is_deeply ($jy->lines, [qw(C D)], '"lines" method seems to work');
is ($jy->code('BLA'), 'BLA', '"code" setter works');
