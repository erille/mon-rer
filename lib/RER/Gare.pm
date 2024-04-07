#!/usr/bin/env perl

package RER::Gare;

use strict;
use warnings;
use utf8;

sub name  { $_[0]->{name} = $_[1] || $_[0]->{name}; }
sub code  { $_[0]->{code} = $_[1] || $_[0]->{code}; }
sub lines { $_[0]->{lines} = $_[1] || $_[0]->{lines}; }
sub prim_api_search_key {
    $_[0]->{prim_api_search_key} = $_[1]
        || $_[0]->{prim_api_search_key};
}

our @attributes = qw(code name lines prim_api_search_key);

sub new {
    my ($class, %args) = @_;

    my $self = {};

    return undef if ! exists $args{code} || ! defined $args{code};
    return undef if ! exists $args{name} || ! defined $args{name};

    for my $attr (@attributes) {
        $self->{$attr} = $args{$attr};
    }

    return bless $self, __PACKAGE__;
}

sub TO_JSON {
    my ($self) = @_;

    # On n'a pas besoin de l'attribut prim_api_search_key dans la
    # représentation JSON de l'objet.
    return {
        code => $self->{code},
        name => $self->{name},
        lines => $self->{lines}
    }
}

1;
