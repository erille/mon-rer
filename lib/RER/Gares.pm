#!/usr/bin/env perl

package RER::Gares;

use Dancer ':syntax';
use Dancer::Plugin::Database;

use RER::Gare;

use DBI;
use DateTime;
use DateTime::Format::Strptime;
use Memoize;

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

sub find
{
    my ($key, $value) = @_;

    if ($key eq 'uic') {
        # les codes UIC ont deux variétés : ceux à 7 chiffres et ceux à 8.
        # ceux à 8 chiffres ont un chiffre de contrôle (superflu) qu'on
        # enlève, parce qu'on ne stocke que 7 chiffres dans la BDD.
        $value = substr($value, 0, 7);
    }

    my $data = database->selectrow_hashref(q{
       SELECT code, uic, name, lines,
              transilien_api_search_key, prim_api_search_key
         FROM find_station_by_key(?, ?)},
       {},
       $key, $value);

    if (defined $data) {
        return RER::Gare->new(%$data);
    }
    else {
        return undef;
    }
}

memoize('find');

sub get_autocomp
{
    my ($str) = @_;

    return [] unless (defined $str && $str ne '');

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
