#!/usr/bin/env perl

package RER::DataSource::Transilien;

use RER::Gare;
use RER::Gares;
use RER::Train;

use HTTP::Request;
use LWP::UserAgent;
use XML::Simple;

use strict;
use warnings;
use utf8;
use 5.010;


sub do_request {
    my ($self, $path) = @_;

    my $req = HTTP::Request->new(GET => $self->{url} . $path);
    $req->header('User-Agent' => 'RER::Web (+http://bitbucket.org/xtab/rer-web)');
    $req->header('Accept'     => 'application/vnd.sncf.transilien.od.depart+xml;vers=1');
    $req->authorization_basic($self->username, $self->password);

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    push(@LWP::Protocol::http::EXTRA_SOCK_OPTS, SendTE => 0);
    my $response = $ua->request($req);

    for ($response->code) {
        if ($_ == 401) { die "Authentication failed or missing (invalid API key?)\n"; }
        elsif ($_ == 403) {
            if (defined $response->header('Retry-After')) {
                my $retry_after = $response->header('Retry-After');
                die "API call quota exceeded (retry after $retry_after s)\n";
            }
            else {
                die "Forbidden (invalid station or other error)\n";
            }
        }
        elsif ($_ == 404) { die "Invalid path supplied to API call\n"; }
        elsif ($_ == 406) { die "Unsupported version\n"; }
        elsif ($_ == 500) { die "API is broken\n"; }
        elsif ($_ == 503) { die "API is overloaded\n"; }
    }

    return $response->decoded_content;
}



sub process_xml_trains {
    my ($self, $xml) = @_;

    my $xs = XML::Simple->new();
    my $data = $xs->XMLin($xml);

    my @trains;

    # S'il n'y a qu'un seul train, XML::Simple renvoie un hash au lieu d'un
    # tableau.  Forcer un tableau à un seul élément dans ce cas.
    my @train_data = (ref $data->{train} eq 'ARRAY') ? @{$data->{train}} : 
                     (ref $data->{train} eq 'HASH') ? ( $data->{train} ) : ();

    foreach my $train_hash (@train_data) {
        my $time_type  = ($train_hash->{date}{mode} eq 'R') ? 'real_time' : 'due_time';

        $train_hash->{date}{content} =~ m#^([\d]{2})/([\d]{2})/([\d]{4}) ([\d]{2}):([\d]{2})$#;
        my $time_value = DateTime->new(
            year    => $3,
            month   => $2,
            day     => $1,
            hour    => $4,
            minute  => $5,
            second  => 0,
            time_zone => 'Europe/Paris'
        );

        my $terminus;

        if (exists $train_hash->{term}) {
            $terminus = RER::Gares::find(uic => $train_hash->{term});
            $terminus ||= RER::Gare->new(
                            uic =>  $train_hash->{term},
                            code => '',
                            name => "Gare " . $train_hash->{term});
        }
        else {
            $terminus = RER::Gare->new(
                   uic => 0,
                   code => '',
                   name => "Gare non référencée");
        }

        my $train_etat = 'N';
        $train_etat = $train_hash->{etat} if exists $train_hash->{etat};
        $train_etat = 'S' if $train_etat eq 'Supprimé';
        $train_etat = 'R' if $train_etat eq 'Retardé';   # not sure if this works

        push @trains, RER::Train->new(
            number     => $train_hash->{num},
            code       => $train_hash->{miss},
            $time_type => $time_value,
            status     => $train_etat,
            terminus   => $terminus,
        );
    }
    
    return \@trains;
}


sub get_next_trains {
    my ($self, $station) = @_;

    die "Invalid station\n" if ! defined ($station);

    my $path = '/gare/' . $station->uic8() . '/depart/';
    my $data = $self->do_request($path);

    return $self->process_xml_trains($data);
}




sub url      { $_[0]->{url} = $_[1] || $_[0]->{url}; }
sub username { $_[0]->{username} = $_[1] || $_[0]->{username}; }
sub password { $_[0]->{password} = $_[1] || $_[0]->{password}; }


sub new {
	my ($self, %args) = @_;

	$self = {};

	return undef if ! exists $args{username};
	return undef if ! exists $args{password};

	$self->{url}  = $args{url} || 'http://api.transilien.com';
	$self->{username} = $args{username};
	$self->{password} = $args{password};

	return bless $self, __PACKAGE__;
}


1;

# vi:ts=4:sw=4:et:
