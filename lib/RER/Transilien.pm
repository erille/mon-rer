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


our $url = "http://ods.ocito.com/ods/transilien/android"; 


sub get_train_desserte {
    my ($current_station, $train) = @_;

    my $number = $train->{trainNumber};

    my $mech = WWW::Mechanize->new(autocheck => 0);
    $mech->add_header( 'User-Agent' => undef );


    my $content = qq`[{"listOfMap":null,"map":{"trainNumber":"${number}","theoric":"false"},
        "headers":null,"target":"\\/transilien\\/getTrainDetails","list":null,"serial":5}]`;


    my $r = $mech->post($url, Content => $content);
    if (!$r->is_success) {
        die("Erreur lors de la récupération de la desserte du train ${number} : " 
            . "sncf.mobi a renvoyé l'erreur " . $r->status_line . "\n");
    }

    my $data = decode_json $mech->content();
    $data = $data->[0];

    my @stations = map { $_->{codeGare} } @{$data->{data}};
    my %mentions = map { $_->{codeGare} => $_->{mention} } @{$data->{data}}; 

    if (grep { $_ eq $current_station } @stations) {
        # Par défaut la desserte renvoie TOUTES les gares, y compris celles
        # déjà desservies avant.  Enlever ceux qui ne nous intéressent pas.
        while ($#stations > 0 && shift @stations ne $current_station) { 1 }
    }

    $train->{trainMention} = $mentions{$current_station} || 'N';

    return @stations;
}


sub new {
    my %param = @_;

    utf8::upgrade($param{'from'});
    utf8::upgrade($param{'to'}) if defined($param{'to'});

    # Obtention des trigrammes correspondant aux gares recherchées
    my ($trig_from, $trig_to);

    my $tmp = RER::Gares::get_station_by_code($param{'from'});
    die $param{'from'} . ": gare non trouvée" unless length($tmp) > 0;
    $trig_from = $param{'from'};

    my $mech = WWW::Mechanize->new(autocheck => 0);
    $mech->add_header( 'User-Agent' => undef );

    my $content = qq`[{"listOfMap":null,"map":{"codeDepart":"${trig_from}"},
        "headers":null,"target":"\\/transilien\\/getNextTrains","list":null,"serial":4}]`;


    my $r = $mech->post($url, Content => $content);
    if (!$r->is_success) {
        die("Erreur lors de la récupération des horaires en live : " 
            . "sncf.mobi a renvoyé l'erreur " . $r->status_line . "\n");
    }

    my $data = decode_json $mech->content();
    $data = $data->[0];
    my @t = sort { $a->{trainHour} cmp $b->{trainHour} } @{$data->{'data'}};

    # FIXME: cassé
    # si gare de destination donnée, filtrer les trains qui desservent la gare
    # @t = grep { (join ",", @{$_->{dessertes}}) =~ /\b$trig_to\b/ } @t if $trig_to;

    my @messages = ();
    my @trains;

    my $i;
    
    # Récupération des vrais noms de gares
    $param{'from'} = RER::Gares::get_station_by_code($trig_from);
    $param{'to'}   = RER::Gares::get_station_by_code($trig_to) if defined($param{'to'});

    # Récupération de l'ensemble des trains
    for (my $i = 0; $i < 6; $i++)
    {
        my $train = $t[$i];
        next if not defined $train;

        my $mission = $train->{trainMissionCode};
        my $numero  = $train->{trainNumber};

        my $time    = (split /\s+/, $train->{trainHour})[1];
        my $destination = RER::Gares::get_station_by_code($train->{trainTerminus});
        my @arr_dessertes = get_train_desserte($trig_from, $train);
        my $platform = $train->{trainLane} || $train->{trainDock};


        @arr_dessertes = map { RER::Gares::get_station_by_code($_) or (defined $_ ? "$_" : "<i>Gare inconnue</i>") } @arr_dessertes;
        my $dessertes = join ' &bull; ', @arr_dessertes;

        # L'attribut "trainMention" indique si le train est retardé, supprimé...
        my $time_info;
        my $trainclass;
        my $col2class;
        given ($train->{trainMention}) {
            when ('N') { # rien = Normal
                $time_info = $time;
                $trainclass = 'train';
                $col2class = 'col2';
            }; 
            when ('I') { 
                $time_info = 'Retardé'; 
                $trainclass = 'train delayed';
                $col2class = 'col2 texte';
            };
            when ('S') { 
                $time_info = 'Supprimé';
                $trainclass = 'train canceled';
                $col2class = 'col2 texte';
            };
            when ('P') { 
                $time_info = 'À l\'approche';
                $trainclass = 'train';
                $col2class = 'col2 approche';
            };
            when ('Q') { 
                $time_info = 'À quai';
                $trainclass = 'train';
                $col2class = 'col2 texte';
            };
            default { 
                $time_info = "$time (MENTION '" . ($train->{trainMention} || 'undef') . "' INCONNUE)"; 
                $trainclass = 'train';
                $col2class = 'col2 texte';
            };
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

        # "massage" du numéro de trains dans le cas d'une gare RATP

        $numero =~ s/RATP-([^-]+)-.*$/$1/;
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
            ligne => RER::Gares::get_ligne($numero, $train->{trainTerminus}),
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
