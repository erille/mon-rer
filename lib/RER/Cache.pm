#!/usr/bin/env perl

package RER::Cache;

use strict;
use warnings;
use utf8;
use 5.010;

use Dancer;
use Dancer::Plugin::Database;
use JSON qw(encode_json decode_json);

=head1 RER::Cache

Maintient un cache clef/valeur primitif en base de données.

=cut

=head2 cache_put

Insère un objet dans le cache avec un délai de péremption donné.

=cut

sub cache_put {
    my ($key, $value, $preferred_lifetime, $max_lifetime) = @_;

    my $sth = database()->prepare('CALL cache_put(?, ?, ?, ?);');
    $sth->execute($key,
                  JSON->new->convert_blessed(1)->encode($value),
                  $preferred_lifetime,
                  $max_lifetime);
}

=head2 cache_get

Récupère un objet dans le cache s’il n’est pas périmé.

En contexte scalaire, la fonction renvoie la valeur trouvée si elle existe,
qu’elle n’a pas expirée ni dans l’état « semi-périmé ».

En contexte de liste, cette fonction renvoie trois valeurs : la valeur trouvée
(ou undef si elle est périmée), un booléen indiquant si une valeur existait
dans le cache et un troisième booléen indiquant si la valeur est dans l’état
« semi-périmé » (ou undef si la valeur n’existe pas dans la base).

=cut

sub cache_get {
    my ($key) = @_;

    my $sth = database->prepare(
        'SELECT value, found, "semi-stale" FROM cache_get(?);');
    $sth->execute($key);

    my $result = $sth->fetchrow_hashref();

    my $found = $result->{found};
    my $value = $found ? JSON->new->decode($result->{value}) : undef;
    my $semi_stale = $result->{'semi-stale'};

    if (wantarray) {
        return ($value, $found, $semi_stale)
    }
    else {
        return ($found && ! $semi_stale) ? $value : undef;
    }
}

=head2 cache_del

Invalide un élément du cache, s’il existe.

=cut

sub cache_del {
    my ($key) = @_;

    my $sth = database->prepare('CALL cache_del(?)');
    $sth->execute($key);
}

1;
