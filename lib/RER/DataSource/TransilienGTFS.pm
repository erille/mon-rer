#!/usr/bin/env perl

package RER::DataSource::TransilienGTFS;

use strict;
use warnings;
use utf8;
use 5.010;

use RER::Train;
use Dancer ':syntax';

use DateTime;
use DBI;


sub dsn      { $_[0]->{dsn} = $_[1] || $_[0]->{dsn}; }
sub username { $_[0]->{username} = $_[1] || $_[0]->{username}; }
sub password { $_[0]->{password} = $_[1] || $_[0]->{password}; }
sub dbh      { $_[0]->{dbh} = $_[1] || $_[0]->{dbh}; }


sub new {
    my ($self, %args) = @_;
    $self = {};

    $self->{dsn}      = $args{dsn};
    $self->{username} = $args{username};
    $self->{password} = $args{password};

    $self->{dbh} = DBI->connect(
        $self->{dsn},
        $self->{username},
        $self->{password}
    ) or die $DBI::errstr;

    $self->{sth_ttfd} = $self->{dbh}->prepare(
        'CALL train_times_for_date(?, ?, ?)');
    $self->{sth_tsl}  = $self->{dbh}->prepare(
        'CALL train_station_list(?, ?, ?)');
    $self->{sth_snt}  = $self->{dbh}->prepare(
        'CALL station_next_trains(?, ?, ?)');
    $self->{sth_plfm} = $self->{dbh}->prepare(
        'CALL possible_lines_for_mission(?, ?)');

    return bless $self, __PACKAGE__;
}



sub check_ligne {
	my ($ligne, $agency) = @_;
	return '' if not defined $ligne;

	my $value = $ligne;

    if ($value !~ /^(?:TER|[A-EHJKLNPRU])$/ && defined $agency) {
        for ($agency) {
            $value = $1  if /^RER (.)$/;
            $value = 'N' if $_ eq 'Paris Rive Gauche';
            $value = 'P' if $_ eq 'Paris Est';
            $value = 'R' if $_ eq 'Paris Sud Est';
            $value = 'U' if $_ eq 'La Verrière - La Défense';
        }
    }

	# $value should now usually contain a one-letter value, or
	# "TER".  However SNCF somehow manages to fuck this up
	# big time.
	for ($value) {
        $value = 'C' if /Gare d'Aus/i;
        $value = 'C' if /Dourdan =>/i;
        $value = 'C' if /Invalides /i; # note the space
        $value = 'C' if /Montigny B/i;
        $value = 'C' if /PONT DU GA/i;
        $value = 'D' if /Corbeil Es/i;
        $value = 'D' if /Evry Courc/i;
        $value = 'D' if /Grigny Cen/i;
        $value = 'D' if /Le Bras de/i;
        $value = 'D' if /Orangis Bo/i;
        $value = 'D' if /Juvisy => /i; # note the space
        $value = 'E' if /Haussmann /i; # note the space
        $value = 'H' if /LUZARCHES /i; # note the space
        $value = 'H' if /ERMONT EAU/i;
        $value = 'J' if /Gisors => /i; # note the space
        $value = 'J' if /Mantes la /i; # note the space
        $value = 'L' if /St Nom la /i; # note the space
        $value = 'R' if /Montargis /i; # note the space
        $value = 'TER' if $_ eq 'Train';
	}

    return '' if ($value !~ /^(?:TER|[A-EHJKLNPRU])$/);
	return $value;
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





sub db_run_train_times_for_date {
    my ($self, $date, $station_code, $train_number) = @_;

    if ($train_number =~ /^[0-9]+$/) {
        $train_number = sprintf("%06d", $train_number);
    }

    $self->{sth_ttfd}->execute($date, $station_code, $train_number);
    return $self->{sth_ttfd}->fetchall_arrayref;
}




sub db_run_train_station_list {
    my ($self, $date, $train_number, $index) = @_;

    if ($train_number =~ /^[0-9]+$/) {
        $train_number = sprintf("%06d", $train_number);
    }

    $self->{sth_tsl}->execute($date, $train_number, $index);
    return $self->{sth_tsl}->fetchall_arrayref;
}



sub db_guess_line_for_mission {
    my ($self, $code, $terminus) = @_;

    $self->{sth_plfm}->execute($code, $terminus);
    my $data = $self->{sth_plfm}->fetchall_arrayref([0]);

    if (scalar @$data == 1) {
        debug "Guessing line " . $data->[0] . " for train $code to $terminus ";
        return $data->[0];
    } else {
        return undef;
    }
}



sub get_info_for_train {
    my ($self, $date, $station_code, $train_number, $mission_code, $terminus_station) = @_;

    # Sauvegarder le numéro de train (il se peut qu'on le modifie plus tard)
    my $orig_train_number = $train_number;

    my $data = $self->db_run_train_times_for_date($date, $station_code, $train_number);

    # Hack spécifique aux gares ayant deux numéros UIC identiques
    if ($station_code eq 'ERT' && scalar @$data == 0) {
        $data = $self->db_run_train_times_for_date($date, 'ERE', $train_number);
    }

    # Hack spécifique aux numéros de train impairs : il arrive parfois que les
    # numéros de train changent de parité en cours de route.  Dans ce cas, il
    # faut prendre le numéro de train moins 1 et réessayer.
    # Bien entendu, ne pas faire ça sur les "numéros" de train RATP.
    if ($train_number =~ /^[0-9]+$/ 
            && $train_number % 2 == 1 
            && scalar @$data == 0) {
        $data = $self->db_run_train_times_for_date($date, $station_code, $train_number - 1);
        $train_number--;
    }
        
    my @ret;

    my $row = $data->[0];
    
    if (defined $row)
    {
        my ($stations_mysql, @stations);

        $stations_mysql = $self->db_run_train_station_list($date, $train_number, $row->[7]);

        @stations = map { RER::Gare->new(
            code => $_->[0],
            uic  => $_->[1],
            name => $_->[2]
        ) } @$stations_mysql;

        my $terminus;
        if (scalar @stations == 0) {
            $stations_mysql = $self->db_run_train_station_list($date, $train_number, $row->[7] - 1);

            @stations = map { RER::Gare->new(
                code => $_->[0],
                uic  => $_->[1],
                name => $_->[2]
            ) } @$stations_mysql;
        }

        my $line = check_ligne($row->[0], $row->[1]);

        $row->[3] =~ /^([\d]{4})-([\d]{2})-([\d]{2}) ([\d]{2}):([\d]{2}):([\d]{2})$/;
        my $due_time = DateTime->new(
            year    => $1,
            month   => $2,
            day     => $3,
            hour    => $4,
            minute  => $5,
            second  => $6,
            time_zone => 'Europe/Paris'
        );

        my $train = RER::Train->new(
            number      => $orig_train_number,
            due_time    => $due_time,
            line        => $line,
            stations    => \@stations,
            terminus    => $stations[-1],
        );

        push @ret, $train;
    }
    else {
        # utiliser une heuristique à partir du code mission et de la gare
        # du terminus pour déterminer les lignes possibles
        my $line = $self->db_guess_line_for_mission($mission_code, $terminus_station->code);

        # en dernier recours, le déduire à partir de son terminus
        if (!defined $line) {
            my @terminus_lines = @{$terminus_station->lines};
            if (scalar @terminus_lines == 1) {
                $line = $terminus_lines[0];
            }
        }

        my $train = RER::Train->new(
            number      => $orig_train_number,
            line        => $line,
        );

        push @ret, $train;
    }

    return \@ret;
}

1;
# vi:ts=4:sw=4:et:
