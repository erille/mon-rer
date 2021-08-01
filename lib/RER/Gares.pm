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
    my $sth = database->prepare('SELECT code FROM gares');
    $sth->execute;
    return $sth->fetchall_arrayref([0]);
}

sub get_stations
{
    my $sth = database->prepare(
        'SELECT code, name, uic FROM gares WHERE is_transilien ORDER BY name');
    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub get_lines
{
    my ($arg) = @_;

    my $uic;
    $uic = $arg->uic if ref $arg eq 'RER::Gare';
    $uic = $arg      if ref $arg ne 'RER::Gare';

    my $sth = database->prepare('SELECT line FROM gares_lines WHERE uic = ?');
    $sth->execute($uic);
    my @result = map { $_->[0] } @{$sth->fetchall_arrayref([0])};
    return \@result;
}

sub find
{
    my %params = @_;

    my $sth;

    if (exists $params{code}) {
        $sth = database->prepare(q{
            SELECT code, name, gares.uic, array_agg(line) AS lines
              FROM gares
                   JOIN gares_lines ON (gares.uic = gares_lines.uic)
             WHERE gares.code = ?
             GROUP BY gares.code
        });
        $sth->execute($params{code});
    }
    elsif (exists $params{uic}) {
        # les codes UIC ont deux variétés : ceux à 7 chiffres et ceux à 8.
        # ceux à 8 chiffres ont un chiffre de contrôle (superflu) qu'on
        # enlève, parce qu'on ne stocke que 7 chiffres dans la BDD.
        my $uic = substr $params{uic}, 0, 7;

        $sth = database->prepare(q{
            SELECT code, name, gares.uic, array_agg(line) AS lines
              FROM gares
                   JOIN gares_lines ON (gares.uic = gares_lines.uic)
             WHERE gares.uic = ?
             GROUP BY gares.code
        });
        $sth->execute($uic);
    }
    else {
        return undef;
    }

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
        'SELECT code, name, uic, lines FROM autocomplete_stations(?);');
    $sth->execute($str);

    return [
        map {
            RER::Gare->new(
                code  => $_->{code},
                name  => $_->{name},
                uic   => $_->{uic},
                lines => $_->{lines}
            )
        } @{$sth->fetchall_arrayref({})}
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
