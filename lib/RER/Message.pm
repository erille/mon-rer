#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Data::Dumper;

package RER::Message;




sub priority { return $_[0]->{priority}; }
sub content { return $_[0]->{content}; }


sub TO_JSON {
	my ($self) = @_;
	return { priority => $self->priority, content => $self->content };
}


sub new {
	my $self = shift;
	my %args = ( @_ );

	$self = {};

	$args{priority} = 'medium' if (! $args{priority});

	# Check priority
	return undef if ($args{priority} !~ /^(?:low|medium|high|urgent)$/);
	
	# Check if message
	return undef if (! exists $args{content} || ! $args{content});

	$self->{priority} = $args{priority};
	$self->{content} = $args{content};


	return bless $self, __PACKAGE__;
}

1;
