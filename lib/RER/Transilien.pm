#!/usr/bin/env perl

package RER::Transilien;

use strict;
use warnings;
use utf8;
use 5.010;

use JSON;
use RER::Message;
use RER::Results;
use RER::Gares;
use Dancer qw(:syntax config debug error);


sub new {
    my %param = @_;

    my $gare_from = RER::Gares::find(code => $param{'from'})
        || die $param{'from'} . ": gare non trouvée\n";

    if (! defined $param{ds}) {
        die "Pas de datasources passés en argument à RER::Transilien::new()\n";
    }
    my @ds = @{$param{ds}};

    my @messages = ();

    my @data;

    my $warn_no_real_time_times = RER::Message->new(
        priority => 'high',
        content => 'Attention, les horaires affichés sont théoriques. '
        . 'Renseignez-vous en gare pour vérifier si votre train est à l’heure '
        . 'et n’est pas supprimé.');

    # Si la gare choisie est desservie par l'API Temps Réel PRIM, alors on
    # peut utiliser l’API temps réel et le GTFS ensemble.
    my $real_time_data = eval { $ds[0]->get_next_trains($gare_from); };

    if ($@) {
        my $err = $@;
        push @messages, $warn_no_real_time_times;
        push @messages, RER::Message->new(priority => 'high', content => "$err");
        @data = @{$ds[1]->get_next_trains($gare_from)};
    }
    else {
        @data = @{$ds[1]->complete_train_info($gare_from, $real_time_data)};
    }

    # Sort trains by departure time
    @data = sort { DateTime->compare($a->time, $b->time) } @data;
    # Remove any trains in the future
    @data = grep { $_->time >= DateTime->now } @data;
    # Remove any trains that terminate at this station
    @data = grep {
        !defined($_->terminus) ||
            ($_->terminus->code ne $gare_from->code)
        } @data;
    # Remove any trains that do not stop at this station
    @data = grep { $_->is_stopping } @data;

    return RER::Results->new(
        from => $gare_from,
        trains => [map { train_to_json($_) } @data],
        messages => \@messages
    );
}

=head2 format_time_info

Renvoie l’heure temps réel ou, à défaut, l’heure théorique sous la forme d’une
chaîne de caractères (HH:MM).

Cependant, si le train est retardé, cette fonction renvoie « Retardé » à la
place ; s’il est supprimé, la fonction renvoie « Supprimé ».

Si le train n’a aucune information d’heure théorique ou temps réel, alors la
fonction renvoie la chaîne « --:-- ».

=cut

sub format_time_info {
    my ($train) = @_;

    return 'Retardé' if $train->status eq 'R';
    return 'Supprimé' if $train->status eq 'S';
    return "À l'approche" if $train->status eq 'P';
    return 'À quai' if $train->status eq 'Q';

    my $time = $train->real_time // $train->due_time;
    if (defined $time) {
        my $d = $time->clone()->set_time_zone('Europe/Paris');
        return $d->strftime('%H:%M');
    }
    else {
        return '--:--';
    }
}

=head2 format_delay

Renvoie le retard par rapport à l’heure théorique sous la forme d’une chaîne
de caractères, par exemple « +5 min » ou « +1 h 30 » ou encore « −1 min ».

Si l’heure temps réel n’est pas connue ou si le train est retardé ou supprimé,
alors cette fonction renvoie undef.

=cut

sub format_delay {
    my ($train) = @_;

    return undef unless ($train->real_time && $train->due_time);
    return undef if ($train->status eq 'R' || $train->status eq 'S');

    my $delay = ($train->real_time - $train->due_time)->in_units('minutes');

    my $hours = int(abs($delay) / 60);
    my $minutes = abs($delay) % 60;
    my $sign = ($delay >= 0) ? '+' : "\N{MINUS SIGN}";

    if ($delay == 0) {
        return 'à l’heure';
    }
    elsif ($hours == 0) {
        return sprintf("%s%d min", $sign, $minutes);
    }
    else {
        return sprintf("%s%d h %02d", $sign, $hours, $minutes);
    }
}

=head2 train_css_class

Renvoie une liste de classes CSS à utiliser pour la présentation du train
donné en paramètre.

=cut

sub train_css_class
{
    my ($train) = @_;

    for ($train->status) {
        return 'train delayed'  if $_ eq 'R';
        return 'train canceled' if $_ eq 'S';
        return 'train';
        # N = Normal
        # P = À l’approche
        # Q = À quai
    }
}

=head2 train_to_json

Génère un hash, adéquat pour être transformé en JSON par la suite, pour un
élément d’un résultat de recherche des prochains trains d’une gare.

=cut

sub train_to_json
{
    my ($train) = @_;

    return undef unless defined $train;

    my $terminus_name;
    if ($train->is_stopping) {
        $terminus_name = ($train->terminus) ? $train->terminus->name : "?";
    } else {
        $terminus_name = "Train sans arrêt";
    }

    my $dessertes;
    if (defined $train->stations) {
        my @arr_dessertes = map {
            $_ ? ($_->name || $_->uic) : "Gare non trouvée"
        } @{$train->stations};
        $dessertes = join " \x{2022} ", @arr_dessertes;
    }
    else {
        $dessertes = 'Desserte indisponible';
    }

    return {
        mission => $train->code,
        numero  => $train->number,
        time    => format_time_info($train),
        destination => $terminus_name,
        dessertes   => $dessertes,
        platform => $train->platform,
        trainclass => train_css_class($train),
        retard => format_delay($train),
        ligne => $train->line,
    };
}

1;

# vi:ts=4:sw=4:et
