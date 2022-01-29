#!/usr/bin/env perl

package RER::Gare;

use strict;
use warnings;
use utf8;

sub name { $_[0]->{name} = $_[1] || $_[0]->{name}; }
sub code { $_[0]->{code} = $_[1] || $_[0]->{code}; }
sub uic  { $_[0]->{uic} = $_[1] || $_[0]->{uic}; }
sub lines  { $_[0]->{lines} = $_[1] || $_[0]->{lines}; }
sub transilien_api_ok { $_[0]->{transilien_api_ok} = $_[1] || $_[0]->{transilien_api_ok}; }

our @attributes = qw(code name uic lines transilien_api_ok);

# Return 8-digit UIC code
# Calculates control sum for a 7-digit UIC code
sub uic8 {
    my ($self, $code) = @_;

    my $uic8 = (ref $self) ? $self->uic : $code;
    return undef if ! (ref $self) && !$code;

    my @chars = split //, $uic8;

    my $ctl = 2 * ($chars[2] + $chars[4] + $chars[6])
        + ($chars[3] + $chars[5]);
    $ctl += 1 if $chars[2] >= 5;
    $ctl += 1 if $chars[4] >= 5;
    $ctl += 1 if $chars[6] >= 5;

    $ctl = (10 - ($ctl % 10)) % 10;

    $uic8 .= $ctl;

    return $uic8;
}


sub new {
    my ($self, %args) = @_;

    $self = {};

    return undef if ! exists $args{code} || ! defined $args{code};
    return undef if ! exists $args{uic} || ! defined $args{uic};
    return undef if ! exists $args{name} || ! defined $args{name};

    for my $attr (@attributes) {
        $self->{$attr} = $args{$attr};
    }

    return bless $self, __PACKAGE__;
}



sub TO_JSON {
    my ($self) = @_;

    # On n'a pas besoin de l'attribut transilien_api_ok dans la
    # représentation JSON de l'objet.
    return {
        code => $self->{code},
        name => $self->{name},
        uic  => $self->{uic},
        lines => $self->{lines}
    }
}


1;
