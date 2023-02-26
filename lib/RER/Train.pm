package RER::Train;

use RER::Gare;

use strict;
use warnings;
use utf8;
use 5.010;

our @attributes = qw(number code platform status line
                     real_time due_time terminus stations);

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

    # Pour chaque attribut, on prend celui de gauche s’il est défini,
    # sinon celui de droite.
    foreach my $attr (@attributes) {
        $attributes{$attr} = $self->{$attr} // $obj->{$attr};
    }

    # Dans le cas particulier où l’objet de gauche a un numéro de train
    # pair-impair et l’objet de droite a un numéro de train qui correspond
    # à l’un ou à l’autre, on prend celui de droite.
    if ($self->{number} =~ /^([0-9]{5})[02468]-\1[13579]$/
        && defined $obj->{number}
        && $obj->{number} =~ /^[0-9]{6}$/) {
        $attributes{number} = $obj->{number};
    }

    return __PACKAGE__->new(%attributes);
}

sub new {
    my ($class, %args) = @_;

    my $self = {};

    foreach my $attr (@attributes) {
        $self->{$attr} = $args{$attr};
    }

    return bless $self, __PACKAGE__;
}

1;
