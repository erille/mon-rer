package RER::Train;

use RER::Gare;

use strict;
use warnings;
use utf8;
use 5.010;

sub number    { $_[0]->{number} = $_[1] || $_[0]->{number}; }
sub code      { $_[0]->{code} = $_[1] || $_[0]->{code}; }
sub platform  { $_[0]->{platform} = $_[1] || $_[0]->{platform}; }
sub status    { $_[0]->{status} = $_[1] || $_[0]->{status}; }
sub real_time { $_[0]->{real_time} = $_[1] || $_[0]->{real_time}; }
sub due_time  { $_[0]->{due_time} = $_[1] || $_[0]->{due_time}; }
sub terminus  { $_[0]->{terminus} = $_[1] || $_[0]->{terminus}; }
sub stations  { $_[0]->{stations} = $_[1] || $_[0]->{stations}; }
sub line      { $_[0]->{line} = $_[1] || $_[0]->{line}; }

sub merge {
    my ($self, $obj) = @_;

    my %attributes;

    foreach my $attr (qw(number code platform status line
                         real_time due_time terminus stations)) {
        $attributes{$attr} = $self->{$attr} || $obj->{$attr};
    }

    return __PACKAGE__->new(%attributes);
}

sub new {
    my ($self, %args) = @_;

    $self = {};

    $self->{number}     = $args{number};
    $self->{code}       = $args{code};
    $self->{platform}   = $args{platform};
    $self->{status}     = $args{status};
    $self->{line}       = $args{line};
    $self->{real_time}  = $args{real_time};
    $self->{due_time}   = $args{due_time};
    $self->{terminus}   = $args{terminus};
    $self->{stations}   = $args{stations};

    return bless $self, __PACKAGE__;
}

1;
