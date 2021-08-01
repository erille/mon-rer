#!/usr/bin/env perl

package RER::DataSource::TransilienGTFS;

use strict;
use warnings;
use utf8;
use 5.010;

use RER::Train;
use Dancer ':syntax';

use DateTime;
use DateTime::Format::Pg;
use DBI;

=head2 dbh

Accesseur pour le handle d’accès à la base de données donné à cet objet.

=cut

sub dbh { $_[0]->{dbh} = $_[1] || $_[0]->{dbh}; }

=head2 new

Instancie un nouvel objet TransilienGTFS.

Ce constructeur nécessite un paramètre « dbh » correspondant à un « handle »
de base de données préalablement ouvert. Celui que propose Dancer via son plugin
Dancer::Plugin::Database et la fonction « database » fait l’affaire.

=cut

sub new {
    my ($self, %args) = @_;

    $self = {
        dbh => $args{dbh},
    };

    $self->{sth_sched_info_trains} = $self->{dbh}->prepare(
        'SELECT * FROM schedule_info_for_trains(?, ?, ?)');

    $self->{sth_snt}  = $self->{dbh}->prepare(
        'CALL station_next_trains(?, ?, ?)');

    return bless $self, __PACKAGE__;
}

=head2 pg_row_to_station

Transforme un triplet (code, UIC, nom), exprimé sous la forme d’une chaîne de
caractères dont le séparateur est le caractère U+001F, en un objet RER::Gare.

Si la chaîne est undef, renvoie undef.

=cut

sub pg_row_to_station {
    my ($str) = @_;

    if (defined $str) {
        my ($code, $uic, $name) = split "\x1f", $str;

        return RER::Gare->new(
            code => $code,
            uic  => $uic,
            name => $name
        );
    }
    else {
        return undef;
    }
}



sub get_next_trains {
    my ($self, $station) = @_;

    die "Invalid station\n" if ! defined ($station);

    my $curdate = `date +'%Y-%m-%d'`;
    my $curtime = `date +'%T'`;

    my $trains = $self->db_get_next_trains($curdate, $curtime, $station->code);

    return $trains;
}





sub db_get_next_trains {
    my ($self, $date, $time, $station_code) = @_;

    $self->{sth_snt}->execute($date, $time, $station_code);
    my $data = $self->{sth_snt}->fetchall_arrayref;

    my $count = 0;

    # columns:
    # #0 - route_short_name
    # #1 - agency_name
    # #2 - trip_headsign (mission code)
    # #3 - train number
    # #4 - due time
    # #5 - station code
    # #6 - station uic
    # #7 - station name
    # #8 - stop sequence

    my @trains;

    foreach my $row (@$data) {
        $row->[4] =~ /^([\d]{4})-([\d]{2})-([\d]{2}) ([\d]{2}):([\d]{2}):([\d]{2})$/;
        my $due_time = DateTime->new(
            year    => $1,
            month   => $2,
            day     => $3,
            hour    => $4,
            minute  => $5,
            second  => $6,
            time_zone => 'Europe/Paris'
        );

        my $line = check_ligne($row->[0], $row->[1]);

        push @trains, RER::Train->new(
            number   => int $row->[3],
            code     => $row->[2],
            due_time => $due_time,
            status   => 'N',
        );
    }

    return \@trains;
}

=head2 db_run_sched_info_trains

Exécute la procédure stockée schedule_info_for_trains() dans la base de
données.  Celle-ci prend en entrée un horodatage, un code de gare et un
référence de tableau de numéros de train. Renvoie une liste de tableaux
associatifs.

=cut

sub db_run_sched_info_trains {
    my ($self, $datetime, $station_code, $train_numbers) = @_;

    $self->{sth_sched_info_trains}->execute(
        DateTime::Format::Pg->format_timestamptz($datetime),
        $station_code,
        $train_numbers);
    return $self->{sth_sched_info_trains}->fetchall_arrayref({});
}


=head2 get_info_for_trains

Pour une liste de trains identifiés par leurs numéros, à une gare et une heure
donnée, renvoie une liste d’objets Train contenant les informations des
horaires théoriques. L’ordre des trains renvoyés est le même que celui des
numéros donnés en paramètre. Tout train non trouvé est remplacé par un undef
dans la liste renvoyée.

=cut

sub get_info_for_trains {
    my ($self, $datetime, $station, $train_numbers) = @_;

    my $data = $self->db_run_sched_info_trains(
        $datetime, $station->code, $train_numbers);

    return [
        map {
            if (defined $_->{due_time}) {
                RER::Train->new(
                    number   => $_->{train_number},
                    due_time => DateTime::Format::Pg->parse_timestamptz($_->{due_time}),
                    line     => $_->{line},
                    stations => [map { pg_row_to_station($_) } @{$_->{next_stops}}],
                    terminus => pg_row_to_station($_->{destination}),
                );
            }
            else {
                undef;
            }
        } @$data
    ];
}


=head2 complete_train_info

Complète les informations sur une liste de trains identifiés par leurs numéros,
pour un passage autour d’un horodatage à une gare donnée. Renvoie une liste
d’objets Train ainsi complétés.

=cut

sub complete_train_info {
    my ($self, $station, $trains) = @_;

    my $scheduled_data = $self->get_info_for_trains(
        DateTime->now(), $station, [map { $_->number } @$trains]);

    return [map {
        if (defined $scheduled_data->[$_]) {
            $trains->[$_]->merge($scheduled_data->[$_]);
        }
        else {
            $trains->[$_];
        }
    } (0..$#$trains)];
}

1;
# vi:ts=4:sw=4:et:
