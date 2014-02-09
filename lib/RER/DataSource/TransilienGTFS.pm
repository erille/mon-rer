#!/usr/bin/env perl

package RER::DataSource::TransilienGTFS;

use strict;
use warnings;
use utf8;
use 5.010;

use RER::Train;

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

    return bless $self, __PACKAGE__;
}



sub check_ligne {
	my ($ligne, $agency) = @_;
	return '' if not defined $ligne;

	my $value = $ligne;

    if ($value !~ /^(?:TER|[A-EHJKLNPRU])$/ && defined $agency) {
        given ($agency) {
            $value = $1  when /^RER (.)$/;
            $value = 'N' when 'Paris Rive Gauche';
            $value = 'P' when 'Paris Est';
            $value = 'R' when 'Paris Sud Est';
            $value = 'U' when 'La Verrière - La Défense';
        }
    }

	# $value should now usually contain a one-letter value, or
	# "TER".  However SNCF somehow manages to fuck this up
	# big time.
	given ($value) {
        $value = 'C' when /Gare d'Aus/i;
        $value = 'C' when /Dourdan =>/i;
        $value = 'C' when /Invalides /i; # note the space
        $value = 'C' when /Montigny B/i;
        $value = 'C' when /PONT DU GA/i;
        $value = 'D' when /Corbeil Es/i;
        $value = 'D' when /Evry Courc/i;
        $value = 'D' when /Grigny Cen/i;
        $value = 'D' when /Le Bras de/i;
        $value = 'D' when /Orangis Bo/i;
        $value = 'D' when /Juvisy => /i; # note the space
        $value = 'E' when /Haussmann /i; # note the space
        $value = 'H' when /LUZARCHES /i; # note the space
        $value = 'H' when /ERMONT EAU/i;
        $value = 'J' when /Gisors => /i; # note the space
        $value = 'J' when /Mantes la /i; # note the space
        $value = 'L' when /St Nom la /i; # note the space
        $value = 'R' when /Montargis /i; # note the space
        $value = 'TER' when 'Train';
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




sub get_info_for_train {
    my ($self, $date, $station_code, $train_number) = @_;

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

        # N'essayer d'avoir le terminus que pour les RER
        # if (defined $line && $line != 'TER' && $train_number ) {
        #     $terminus = $stations[-1];
        # }




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

    return \@ret;
}

1;
# vi:ts=4:sw=4:et:
