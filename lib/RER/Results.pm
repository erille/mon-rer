#!/usr/bin/perl

package RER::Results;

use strict;
use warnings;
use utf8;

use Storable qw(dclone);


sub new
{
    my $self = shift;
    my %param = @_;
    my %obj = ( 
        from =>     $param{from},
        trains =>   $param{trains},
        messages => $param{messages}
    );

    return bless \%obj, __PACKAGE__;
}

sub trains { return $_[0]->{trains}; }
sub messages { return $_[0]->{messages}; }

sub TO_JSON
{
    my ($self) = @_;
    return { 
        lines => $self->{from}->lines, 
        trains => $self->{trains}, 
        info => $self->{messages},
    };
}


sub merge {
    my ($self, $other) = @_;

    return undef if ref $self ne 'RER::Results'
                 || ref $other ne 'RER::Results';

    # On pourrait vérifier si $self->from et $other->from sont la même gare,
    # mais à terme on pourrait vouloir fusionner deux résultats de "gares"
    # différentes (ex. Ermont-Eaubonne qui a 2 "gares")

    
    # Fusionner les trains
    my @new_trains;
    {
        my @temp = @{$self->trains()};
        push @temp, @{$other->trains()};

        while (scalar @temp > 0) {
            my $train = shift @temp;
            if (my $merger = (grep { $_->number eq $train->number } @temp)[0]) {
                $train = $train->merge($merger);
                @temp = grep { $_ != $merger } @temp;
            }
            push @new_trains, $train;
        }
    }

    

    # Fusionner les messages
    my @new_messages = @{$self->{messages}};
    push @new_messages, @{$other->{messages}};

    return __PACKAGE__->new(
        from => $self->{from},
        trains => \@new_trains,
        messages => \@new_messages,
    );
}

1;

# vi:ts=4:sw=4:et:
