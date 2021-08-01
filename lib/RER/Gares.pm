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


sub get_station_codes
{
    my $sth = database->prepare('SELECT code FROM gares');
    $sth->execute;
    return $sth->fetchall_arrayref([0]);
}

sub get_stations
{
    my $sth = database->prepare('SELECT code, name, uic FROM gares WHERE is_transilien = 1 ORDER BY name');
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
        $sth = database->prepare('SELECT code, name, uic FROM gares WHERE code = ?');
        $sth->execute($params{code});
    }
    elsif (exists $params{uic}) {
        # les codes UIC ont deux variétés : ceux à 7 chiffres et ceux à 8.
        # ceux à 8 chiffres ont un chiffre de contrôle (superflu) qu'on
        # enlève, parce qu'on ne stocke que 7 chiffres dans la BDD.
        my $uic = substr $params{uic}, 0, 7;

        $sth = database->prepare('SELECT code, name, uic FROM gares WHERE uic = ?');
        $sth->execute($uic);
    }
    else {
        return undef;
    }

    my $result = $sth->fetchall_arrayref();

    if(scalar(@$result)) {
        my ($code, $name, $uic) = @{$result->[0]};
        my $gare = RER::Gare->new(
            code => $code,
            name => $name,
            uic  => $uic
        );

        $gare->lines(get_lines($gare));

        return $gare;
    }
    else {
        return undef;
    }
}

sub get_autocomp
{
    my ($str) = @_;
    $str =~ s/([_%])/\\$1/g;

    my $sth = database->prepare(qq{
        SELECT code, name, uic,
            IF(code = UPPER(?), 0, IF(INSTR(name, ?), 10 + INSTR(name, ?), 50)) AS score
            FROM gares
            WHERE is_transilien AND (code = UPPER(?) OR name LIKE ?)
            ORDER BY score, name
            LIMIT 10;
        });
    $sth->execute("$str", "$str", "$str", "$str", "%$str%");

    my $result = $sth->fetchall_arrayref({});

    my @obj_result = map {
        my $code = $_->{code};
        my $uic  = $_->{uic};
        my $name = $_->{name};
        RER::Gare->new(code => $code, name => $name, uic => $uic, lines => get_lines($_->{uic}))
    } @$result;
    return \@obj_result;
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
