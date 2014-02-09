#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use RER::Train;
use RER::Message;
use RER::Gare;

use Test::More tests => 15;
# use Test::Exception;

BEGIN { 
	use_ok 'RER::Results'; 
}


my $train_11 = RER::Train->new(number => 123456, code => 'BIPE');
my $train_12 = RER::Train->new(number => 123457, code => 'ROVO');
my $train_21 = RER::Train->new(number => 123456, platform => '2');
my $train_22 = RER::Train->new(number => 123457, platform => '1');

my $train1 = $train_11->merge($train_21);
my $train2 = $train_12->merge($train_22);
my $train3 = RER::Train->new(number => 123458, platform => '4');

my @r1_trains = ( $train_11, $train_12 );
my @r2_trains = ( $train_21, $train_22, $train3 );

my @r1_messages = (
	RER::Message->new(priority => 'high', content => 'Test message'),
	RER::Message->new(priority => 'high', content => 'Test message 2'),
);
my @r2_messages = (
	RER::Message->new(priority => 'medium', content => 'Test message 3'),
);

my $from_station_1 = RER::Gare->new(
	code => 'JY', 
	uic  => 8754524, 
	name => 'Juvisy',
	lines => [ qw(C D) ],
);
my $from_station_2 = RER::Gare->new(
	code => 'LDU', 
	uic  => 8738221, 
	name => 'La Défense',
	lines => [ qw(A L U) ],
);


ok(
	my $r1 = RER::Results->new(
		from   => $from_station_1,
		trains => \@r1_trains,
		messages => \@r1_messages,
),
'First object creation is successful');

ok(
	my $r2 = RER::Results->new(
		from   => $from_station_1,
		trains => \@r2_trains,
		messages => \@r2_messages
),
'Second object creation is successful');

ok(
	my $r3 = RER::Results->new(
		from   => $from_station_2,
		trains => \@r2_trains,
		messages => \@r2_messages
),
'Third object creation is successful');



isa_ok($r1, 'RER::Results');
isa_ok($r2, 'RER::Results');
isa_ok($r3, 'RER::Results');



is_deeply ($r1->trains(), \@r1_trains, 'trains method works');
is_deeply ($r1->messages(), \@r1_messages, 'messages method works');

is_deeply ($r1->TO_JSON(), {
	lines => [ qw(C D) ],
	trains => \@r1_trains,
	info =>  \@r1_messages,
}, 'TO_JSON method works');


ok (my $r4 = $r1->merge($r2), 'merge method works');
isa_ok ($r4, 'RER::Results');

is (scalar @{$r4->trains()}, 3, 'Merged results contain 3 trains');
is_deeply (
	$r4->trains(), 
	[ $train1, $train2, $train3 ], 
	'Trains are correctly merged when merging results'
);

is (scalar @{$r4->messages()}, 3, 'Merged results contain 3 messages');

