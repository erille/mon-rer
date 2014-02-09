#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More tests => 16;

use DateTime;

BEGIN { use_ok('RER::Train'); use_ok('RER::Gare'); }


ok(my $gare_by = RER::Gare->new(
	code => 'BY',
	uic  => 8754519,
	name => 'Brétigny')
);

ok(my $gare_mpu = RER::Gare->new(
	code => 'MPU',
	uic  => 8754519,
	name => 'Massy Palaiseau RER C')
);

ok(my $train1 = RER::Train->new(
	number	=> '147343',
	code	=> 'BALI',
	terminus => $gare_by,
	real_time => DateTime->new(
		year => 2013, month => 12, day => 12,
		hour => 17, minute => 53, second => 0,
		time_zone => 'Europe/Paris'),
	status	=> 'N')
);

ok(my $train2 = RER::Train->new(
	number	=> '147343',
	code	=> 'CACA',
	due_time => DateTime->new(
		year => 2013, month => 12, day => 12,
		hour => 17, minute => 52, second => 0,
		time_zone => 'Europe/Paris'),
	line	=> 'C',
	stations => [ $gare_by, $gare_by ],
	terminus => $gare_mpu )
);

is ($train1->line, undef);
is ($train1->stations, undef);

ok($train1 = $train1->merge($train2));

is ($train1->number,	'147343');
is ($train1->code,	'BALI');
is ($train1->terminus->code, 'BY');
is ($train1->due_time->time, '17:52:00');
is ($train1->real_time->time, '17:53:00');
is ($train1->line, 'C');
is (scalar(@{$train1->stations}), 2);


