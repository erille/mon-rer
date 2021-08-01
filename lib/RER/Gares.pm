#!/usr/bin/env perl

package RER::Gares;

use Dancer ':syntax';
use Dancer::Plugin::Database;

use RER::Gare;
use DBI;
use DateTime;
use DateTime::Format::Strptime;

use strict;
use warnings;
use utf8;
use 5.010;

sub get_last_update {
    my $sth = database->prepare("SELECT value FROM metadata WHERE key = 'dmaj'");
    $sth->execute;
    my $result = $sth->fetchall_arrayref([0]);

    if (defined $result && defined $result->[0] && defined $result->[0][0]) {
        my $strp = DateTime::Format::Strptime->new(
            pattern => '%e %B %Y',
            locale  => 'fr_FR',
        );

        my $dt = DateTime->from_epoch(
            epoch => $result->[0][0],
            formatter => $strp,
        );

        return $strp->format_datetime($dt);
    }
}


sub get_station_codes
{
    my $sth = database->prepare('SELECT code FROM station_codes');
    $sth->execute;
    return $sth->fetchall_arrayref([0]);
}

sub get_stations
{
    my $sth = database->prepare(q{
        SELECT code, name, uic
          FROM station_codes
               JOIN station_names ON (station_codes.pa_id = station_names.pa_id)
         ORDER BY name});
    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub get_lines
{
    my ($arg) = @_;

    my $uic;
    $uic = $arg->uic if ref $arg eq 'RER::Gare';
    $uic = $arg      if ref $arg ne 'RER::Gare';

    my $sth = database->prepare(q{
       SELECT line
           FROM station_codes
           JOIN station_lines ON (station_lines.pa_id = station_codes.pa_id)
        WHERE station_codes.uic = ?
        ORDER BY line});
    $sth->execute($uic);
    my @result = map { $_->[0] } @{$sth->fetchall_arrayref([0])};
    return \@result;
}

sub find
{
    my %params = @_;

    my ($key, $value);

    if (exists $params{code}) {
        ($key, $value) = ('code', $params{code});
    }
    elsif (exists $params{uic}) {
        # les codes UIC ont deux variétés : ceux à 7 chiffres et ceux à 8.
        # ceux à 8 chiffres ont un chiffre de contrôle (superflu) qu'on
        # enlève, parce qu'on ne stocke que 7 chiffres dans la BDD.
        ($key, $value) = ('uic', substr($params{uic}, 0, 7));
    }
    else {
        return undef;
    }

    my $sth = database->prepare(q{
       SELECT code, uic, name, lines FROM find_station_by_key(?, ?)});
    $sth->execute($key, $value);

    my $result = $sth->fetchall_arrayref({});

    if (scalar(@$result)) {
        return RER::Gare->new(
            code  => $result->[0]{code},
            name  => $result->[0]{name},
            uic   => $result->[0]{uic},
            lines => $result->[0]{lines},
        );
    }
    else {
        return undef;
    }
}

sub get_autocomp
{
    my ($str) = @_;

    my $sth = database->prepare(
        'SELECT codes, name, lines FROM autocomplete_stations(?);');
    $sth->execute($str);

    return [
        map +{
            codes  => $_->{codes},
            name  => $_->{name},
            lines => $_->{lines}
        }, @{$sth->fetchall_arrayref({})}
    ];
}

sub format_delay {
    my ($num) = @_;
    return ""           if not defined $num;
    return "à l'heure"  if $num == 0;

    my $abs = abs $num;

    my $hours = int($num / 60);
    my $min   = $abs % 60;

    my $str;
    if ($abs >= 60) {
        $str = sprintf "%+d h %02d", $hours, $min;
    }
    else {
        $str = sprintf "%+d min", $min;
    }
    return $str;
}


1;
