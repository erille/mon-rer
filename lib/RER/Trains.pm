#!/usr/bin/perl

package RER::Trains;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(uc_woac);

use strict;
use warnings;
use utf8;
use charnames ();

use JSON;



# Uppercase without accents (to improve search reliability for Transilien website)
sub uc_woac($)
{
    my $src = shift;
    my $dest = '';

    foreach (split //, $src)
    {
        my $c = charnames::viacode(ord($_));
        $c =~ s/^LATIN (SMALL|CAPITAL) LETTER ([[:upper:]])( WITH .*)?$/LATIN CAPITAL LETTER $2/;
        $dest .= chr(charnames::vianame($c));
    }
    return $dest;
}






sub new
{
    my ($from, $to, $trains, $messages) = @_;
    my %obj = ( 
        from => $from,
        to => $to,
        trains => $trains,
        messages => $messages
    );

    bless \%obj;
}

sub get_trains {
    return $_[0]->{trains};
}

sub format
{
    my ($self) = @_;
    
    my $obj = { lines => $self->{from}->lines, trains => $self->{trains}, info => $self->{messages} };
    my $ret = encode_json $obj;
    utf8::decode $ret;
    return $ret;
}


1;
