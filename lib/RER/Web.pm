#!/usr/bin/env perl

package RER::Web;

use strict;
use warnings;
use utf8;

use Dancer ':syntax';
use Dancer::Plugin::Database;
use Dancer::Plugin::Redis;

use RER::Cache;
use RER::Transilien;
use RER::Results;
use RER::Gares;
use RER::DataSource::Transilien;
use RER::DataSource::TransilienGTFS;
use Storable qw(dclone);

our $VERSION = '0.1';

my %stats;

sub check_code {
    my ($code) = @_;

    return undef unless $code;

    $code = uc $code;

    if ($code =~ /^(?:[A-Z]{1,3}|NC[1-7])$/) {
        return $code;
    }
    else {
        return undef;
    }
}



sub stats_add {
    my ($key, $value) = @_;

    return unless $key;

    if (!defined ($value)) {
        if (config->{'use_redis'}) {
            eval { redis->incr("rer-web.$key"); };
        }
    }
    # else {
    #     $stats{$key} = $value;
    # }
}

# Expires a given train objet cache entry
sub cache_invalidate {
    my ($key) = @_;

    RER::Cache::cache_del($key);
}

# Sets a given train objet cache entry to a new value
sub cache_set_hash {
    my ($key, $value) = @_;

    RER::Cache::cache_put($key, $value, 60, 60);
}

# Gets a train objet cache entry (or undef if cache miss)
sub cache_get_hash {
    my ($key) = @_;

    my $obj = RER::Cache::cache_get($key);
    if (defined $obj) {
        $obj = RER::Results->new(%$obj);
    }
    return $obj;
}




get '/' => sub {
    # rediriger (302) vers l'url /?s=<blah> si l'user a sauvegardé sa dernière gare
    # (et sinon on redirige vers la gare par défaut)
    if (! defined params->{'s'}) {
        if (my $station_code = cookie('station')) {
            return redirect uri_for('/', {s => $station_code});
        }
        else {
            return redirect uri_for('/', {s => 'EVC'})
        }
    }

    # trouver la gare dans la base de données
    my $station = RER::Gares::find(code => check_code(params->{'s'}));
    if (!defined $station) {
        status 'not_found';
        send_file '404.html';
        # l’exécution de la route s’arrête ici
    }

    # positionner le cookie (valable 4 semaines)
    # on y touche dans le code js, donc http_only = 0
    cookie "station" => check_code($station->code),
        expires => '4w',
        http_only => 0;

    template 'rer', {
        origin_station => $station->name,
        origin_code    => $station->code,
        dmaj     => RER::Gares::get_last_update(),
        stations => RER::Gares::get_stations(),
    };
};

get '/json' => sub {
    header 'Cache-Control' => 'no-cache';

    set serializer => 'JSON';

    stats_add 'api_incoming';

    my $station = RER::Gares::find(code => check_code(params->{'s'}));
    if (!defined $station) {
        status 404;
        return { error => 'Gare non trouvée' };
    }

    my $code = $station->code;
    my $line = params->{'l'};

    my $ds  = RER::DataSource::Transilien->new(
        url         => config->{'sncf_url'},
        username    => config->{'sncf_username'},
        password    => config->{'sncf_password'});
    my $ds2 = RER::DataSource::TransilienGTFS->new(dbh => database);

    my $ret = cache_get_hash($station->code);

    if (! defined $ret) {

        stats_add 'api_sent';

        my $data;
        eval {
            $data = RER::Transilien::new(
                from => $station->code,
                ds   => [ $ds, $ds2 ],
            );
        };
        if (my $err = $@) {
            status 503;
            stats_add 'api_errors';
            cache_invalidate $station->code;

            # log error
            error "$code: $err";

            # return error to client
            return { error => $err };
        } else {
            cache_set_hash($code, $data);
        }
        $ret = dclone $data;
    }

    # Filtrer par ligne si cela est désiré

    if ($line) {
        @{$ret->{trains}} = grep { $_->{ligne} && $_->{ligne} eq $line } @{$ret->{trains}};
    }
    # Limiter à 6 le nombre de trains renvoyés
    if (scalar @{$ret->{trains}} > 6) {
        @{$ret->{trains}} = @{$ret->{trains}}[0..5];
    }

    if (config->{'use_redis'}) {
        my $api_incoming = redis->get("rer-web.api_incoming") || 0;
        my $api_sent     = redis->get("rer-web.api_sent") || 0;
        my $api_errors   = redis->get("rer-web.api_errors") || 0;

        debug "counters: incoming = $api_incoming, sent = $api_sent, errors = $api_errors";
    }

    return $ret;
};

get '/autocomp' => sub {
    header 'Cache-Control' => 'no-cache';

    set serializer => 'JSON';

    my $str = params->{'s'} || '';

    return RER::Gares::get_autocomp($str);
};

true;

# vi:ts=4:sw=4:et:
