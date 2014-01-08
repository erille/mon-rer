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






sub get_info_for_train {
    my ($self, $date, $station_code, $train_number) = @_;

    $self->{sth_ttfd}->execute($date, $station_code, $train_number);
    my $data = $self->{sth_ttfd}->fetchall_arrayref;

    # Hack spécifique aux gares ayant deux numéros UIC identiques
    if ($station_code eq 'ERT' && scalar @$data == 0) {
        $self->{sth_ttfd}->execute($date, 'ERU', $train_number);
        $data = $self->{sth_ttfd}->fetchall_arrayref;
    }

    # Hack spécifique aux numéros de train impairs : il arrive parfois que les
    # numéros de train changent de parité en cours de route.  Dans ce cas, il
    # faut prendre le numéro de train moins 1 et réessayer.
    # Bien entendu, ne pas faire ça sur les "numéros" de train RATP.
    if ($train_number !~ /[A-Z]{4}[0-9]{2}/ 
            && $train_number % 2 == 1 
            && scalar @$data == 0) {
        $self->{sth_ttfd}->execute($date, $station_code, $train_number - 1);
        $data = $self->{sth_ttfd}->fetchall_arrayref;
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
            line        => $row->[0],
            stations    => \@stations,
        );

        push @ret, $train;
    }

    return \@ret;
}

# CALL train_times_for_date(CURDATE(), 'EVC', '121414');

1;
# vi:ts=4:sw=4:et:
