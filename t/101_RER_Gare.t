#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More tests => 140;

BEGIN { use_ok('RER::Gare'); }

is (RER::Gare->uic8(), undef, "Static method returns undef if no argument given");

#
# Constructor tests
#

my $obj;
is ($obj = RER::Gare->new(name => undef, uic => 8754524, code => 'JY', lines => [qw(C D)] ), undef, 'Constructor returns undef if name is undef');
is ($obj = RER::Gare->new(uic => 8754524, code => 'JY', lines => [qw(C D)] ), undef, 'Constructor returns undef if name is missing');

#
# Getter/setter tests
#

my $jy;
ok ($jy = RER::Gare->new(name => "Juvisy", uic => 8754524, code => 'JY', lines => [qw(C D)] ), 'Object creation works');
isa_ok ($jy, 'RER::Gare');
is ($jy->name, 'Juvisy', '"name" getter works');
is ($jy->uic, '8754524', '"uic" getter works');
is ($jy->code, 'JY', '"code" getter works');
is ($jy->uic8, '87545244', '"uic8" method seems to work');
is_deeply ($jy->lines, [qw(C D)], '"lines" method seems to work');
is ($jy->code('BLA'), 'BLA', '"code" setter works');

foreach (<main::DATA>) {
	my ($uic, $checkdigit) = split;
	is (RER::Gare->uic8($uic), $uic . $checkdigit, "Check digit for $uic is $checkdigit");
}

# done_testing;

__END__
8711127 8
8727114 8
8727120 5
8727124 7
8727214 6
8727605 5
8727606 3
8727607 1
8727608 9
8727609 7
8727610 5
8727613 9
8727617 0
8732832 8
8733448 2
8733798 0
8736692 2
8738101 2
8738102 0
8738103 8
8738104 6
8738111 1
8738112 9
8738113 7
8738145 9
8738165 7
8738190 5
8738200 2
8738220 0
8738221 8
8738225 9
8738226 7
8738233 3
8738234 1
8738235 8
8738236 6
8738237 4
8738238 2
8738243 2
8738244 0
8738245 7
8738246 5
8738247 3
8738248 1
8738249 9
8738265 5
8738280 4
8738281 2
8738286 1
8738287 9
8738288 7
8738328 1
8738400 8
8738600 3
8738630 0
8738631 8
8738640 9
8738641 7
8738642 5
8739300 9
8739303 3
8739304 1
8739305 8
8739306 6
8739307 4
8739308 2
8739315 7
8739316 5
8739317 3
8739321 5
8739322 3
8739330 6
8739332 2
8739350 4
8739351 2
8739353 8
8739354 6
8739356 1
8739357 9
8739361 1
8739363 7
8739364 5
8739365 2
8739384 3
8739387 6
8749210 8
8754017 9
8754318 1
8754320 7
8754513 7
8754514 5
8754515 2
8754516 0
8754517 8
8754518 6
8754519 4
8754520 2
8754521 0
8754522 8
8754523 6
8754524 4
8754525 1
8754526 9
8754527 7
8754528 5
8754529 3
8754530 1
8754535 0
8754545 9
8754546 7
8754547 5
8754548 3
8754549 1
8754550 9
8754551 7
8754552 5
8754565 7
8754573 1
8754575 6
8754619 2
8754620 0
8754622 6
8754629 1
8754631 7
8754702 6
8754730 7
8754731 5
8738162 4
