#!/usr/bin/env perl

use Test::More no_plan;

BEGIN { use_ok RER::Message; }

ok(my $ml = RER::Message->new(
	priority => 'low',
	content	 => 'Low-priority message',
),
'Creation of a low-priority message works');

isa_ok($ml, 'RER::Message');
is($ml->priority, 'low', 'priority method works');
is($ml->content, 'Low-priority message', 'content method works');

ok(my $mm = RER::Message->new(
	priority => 'medium',
	content	 => 'Medium-priority message',
),
'Creation of a medium-priority message works');

ok(my $mh = RER::Message->new(
	priority => 'high',
	content	 => 'High-priority message',
),
'Creation of a high-priority message works');

ok(my $mu = RER::Message->new(
	priority => 'urgent',
	content	 => 'Urgent message',
),
'Creation of an urgent message works');

is(my $fail = RER::Message->new(
	priority => 'blaerjhioar',
	content  => 'invalid',
), undef,
'Fail if invalid priority given');

is($fail = RER::Message->new(
	priority => 'high',
	content  => undef,
), undef,
'Fail if content is undef');

is($fail = RER::Message->new(
	priority => 'high',
), undef,
'Fail if no content given');

ok(my $dpm = RER::Message->new(
	content => 'Default priority message',
));

is ($dpm->priority, 'medium',
'Default priority is medium');



is_deeply ($dpm->TO_JSON,
	{ priority => 'medium', content => 'Default priority message' },
	'TO_JSON method works');
