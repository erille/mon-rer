#!/usr/bin/perl

package RER::Transilien;

use strict;
use warnings;
use utf8;
use 5.010;

use JSON::XS;
use WWW::Mechanize;
use RER::Trains qw(uc_woac);
use RER::Gares;
use List::Util qw(min);

sub new {
    my %param = @_;

    utf8::upgrade($param{'from'});
    utf8::upgrade($param{'to'}) if defined($param{'to'});

    # Obtention des trigrammes correspondant aux gares recherchées
    my ($trig_from, $trig_to);

    my $tmp = RER::Gares::get_station_by_code($param{'from'});
    die $param{'from'} . ": gare non trouvée" unless length($tmp) > 0;
    $trig_from = $param{'from'};

    my $mech = WWW::Mechanize->new();

    my $url = "http://sncf.mobi/infotrafic/iphoneapp/transilien/?gare=$trig_from";

    my $init_page = $mech->get($url) or die("Le site a l'air de s'être chié dessus... URL: $url");

    my $data = decode_json $mech->content();
    my @t = sort { $a->{heureprobable} cmp $b->{heureprobable} } @{$data->{'D'}};

    # si gare de destination donnée, filtrer les trains qui desservent la gare
    @t = grep { (join ",", @{$_->{dessertes}}) =~ /\b$trig_to\b/ } @t if $trig_to;

    my @messages = ();
    my @trains;

    my $i;
    
    # Récupération des vrais noms de gares
    $param{'from'} = RER::Gares::get_station_by_code($trig_from);
    $param{'to'}   = RER::Gares::get_station_by_code($trig_to) if defined($param{'to'});

    # Récupération de l'ensemble des trains
    foreach my $train (@t[0..5])
    {
        next if not defined $train;

        my $mission = $train->{codevoyageur};
        my $numero  = $train->{numerotrain};
        my $time    = (split /\s+/, $train->{heureprobable})[1];
        my $destination = RER::Gares::get_station_by_code((@{$train->{dessertes}})[-1]);
        my @arr_dessertes = @{$train->{dessertes}};
        my $platform = $train->{voie};

        my $trainclass = $train->{mention} =~ /^[TI]$/ ? 'train delayed' :
            $train->{mention} eq 'S' ? 'train canceled' : 'train';
        my $col2class = $train->{mention} eq 'P' ? 'col2 approche' : 
            $train->{mention} ne 'N' ? 'col2 texte' : 'col2';

        @arr_dessertes = map { RER::Gares::get_station_by_code($_) or (defined $_ ? "$_" : "<i>Gare inconnue</i>") } @arr_dessertes;
        my $dessertes = join ' &bull; ', @arr_dessertes;

        # L'attribut "mention" indique si le train est retardé, supprimé...
        my $time_info;
        given ($train->{mention}) {
            when ('N') { $time_info = $time } # N = Normal
            when ([qw(T I)]) { $time_info = 'Retardé'; }
            when ('S') { $time_info = 'Supprimé'; }
            when ('P') { $time_info = 'À l\'approche'; }
            when ('Q') { $time_info = 'À quai'; }
            default { $time_info = "$time (MENTION '" . $train->{mention} . "' INCONNUE)"; }
        }

        # Un peu de nettoyage (et de passage en UTF-8) pour les infos concernant
        # chaque train
        eval {
            map
            {
                $_ = '' unless defined($_);
                utf8::decode($_);
            } ($mission, $time, $destination, $dessertes, $platform);
        };

        # Obtention du retard
        my $delay = RER::Gares::get_delay($numero, $trig_from, $time);
        $delay = RER::Gares::format_delay($delay);

        push @trains, { 
            mission => $mission, 
            numero  => $numero,
            time    => $time_info,
            destination => $destination,
            dessertes   => $dessertes,
            platform => $platform,
            col2class => $col2class,
            trainclass => $trainclass,
            retard => $delay,
        };
    }

    my $obj = RER::Trains::new(
        $param{'from'},
        $param{'to'},
        \@trains,
        \@messages);

    return $obj;
}




1;

# vi:ts=4:sw=4:et
