#!/usr/bin/env perl

package RER::DataSource::TransilienGTFS;

use strict;
use warnings;
use utf8;
use 5.010;

use RER::Train;

use DateTime::Format::Strptime;
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

    return bless $self, __PACKAGE__;
}



sub check_ligne {
	my ($ligne) = @_;
	return '' if not defined $ligne;

	my $value = $ligne;

	# $value should usually contain a one-letter value, or
	# "TER".  However SNCF somehow manages to fuck this up
	# big time.
	given ($value) {
		$value = 'C' when /Gare d'Aus/i;
        $value = 'C' when /Dourdan =>/i;
		$value = 'C' when /Invalides /i; # note the space
		$value = 'C' when /Montigny B/i;
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
	return $value;
}





sub db_run_train_times_for_date {
    my ($self, $date, $station_code, $train_number) = @_;

    if ($train_number =~ /^[0-9]+$/) {
        $train_number = sprintf("%06d", $train_number);
    }

    $self->{sth_ttfd}->execute($date, $station_code, $train_number);
    return $self->{sth_ttfd}->fetchall_arrayref;
}






sub get_info_for_train {
    my ($self, $date, $station_code, $train_number) = @_;

    my $data = $self->db_run_train_times_for_date($date, $station_code, $train_number);

    # Hack spécifique aux gares ayant deux numéros UIC identiques
    if ($station_code eq 'ERT' && scalar @$data == 0) {
        $data = $self->db_run_train_times_for_date($date, 'ERU', $train_number);
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
        
    my $strp = DateTime::Format::Strptime->new(
        pattern     => '%Y-%m-%d %T',
        time_zone   => 'Europe/Paris'
    );

    my @ret;

    foreach my $row (@$data) {
        my ($stations_mysql, @stations);

        $self->{sth_tsl}->execute($date, $train_number, $row->[6]);
        $stations_mysql = $self->{sth_tsl}->fetchall_arrayref;

        @stations = map { RER::Gare->new(
            code => $_->[0],
            uic  => $_->[1],
            name => $_->[2]
        ) } @$stations_mysql;


        my $train = RER::Train->new(
            number      => $train_number,
            due_time    => $strp->parse_datetime($row->[2]),
            line        => check_ligne($row->[0]),
            stations    => \@stations,
        );

        push @ret, $train;
    }

    return \@ret;
}

# CALL train_times_for_date(CURDATE(), 'EVC', '121414');

1;
# vi:ts=4:sw=4:et:
