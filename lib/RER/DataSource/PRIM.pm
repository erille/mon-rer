#!/usr/bin/env perl

package RER::DataSource::PRIM;

use strict;
use warnings;
use utf8;
use 5.010;

use DateTime::Format::ISO8601;
use HTTP::Request;
use JSON qw(decode_json);
use LWP::UserAgent;
use Dancer qw(:syntax debug);

use RER::Gares;
use RER::Train;

sub new {
    my ($class, %args) = @_;

    my $self = {
        api_token => $args{api_token}
    };

    return bless($self, __PACKAGE__);
}

sub api_token { $_[0]->{api_token} = $_[1] || $_[0]->{api_token}; }

sub get_next_trains {
    my ($self, $station) = @_;

    die "Invalid station\n" if ! defined ($station);

    my $search_key = $station->prim_api_search_key();
    my %urlparams = ('MonitoringRef' => $search_key);

    my $api_json = $self->do_request($search_key);

    return parse_result($api_json);
}

sub do_request {
    my ($self, $monitoring_ref) = @_;

    my $uri = URI->new('https://prim.iledefrance-mobilites.fr/marketplace/stop-monitoring');
    $uri->query_form('MonitoringRef' => $monitoring_ref);

    my $headers = HTTP::Headers->new(
        Accept => 'application/json',
        Accept_Encoding => 'gzip, deflate',
        Apikey => $self->api_token(),
        User_Agent => 'RER::Web (+https://bitbucket.org/xtab/rer-web)'
        );

    my $req = HTTP::Request->new('GET', $uri, $headers);

    my $ua = LWP::UserAgent->new();
    $ua->timeout(5);
    push(@LWP::Protocol::http::EXTRA_SOCK_OPTS, SendTE => 0);
    my $response = $ua->request($req);

    if ($response->code >= 400) {
        my $code = $response->code;
        my $content = $response->decoded_content;
        my $message = eval { $_ = decode_json($content); $_->{message} } // "<no message>";
        die "Error $code: $message";
    }

    return decode_json($response->decoded_content);
}

# Careful, the trains are NOT necessarily sorted by departure time!
sub parse_result {
    my ($result_obj) = @_;

    my @trains = get_trains_in_result($result_obj);
    my @objs = map { train_from_vehicle_journey($_->{'MonitoredVehicleJourney'}) } @trains;
    return \@objs;
}

sub get_trains_in_result {
    my ($result_obj) = @_;

    my $visits = $result_obj->{'Siri'}
                            ->{'ServiceDelivery'}
                            ->{'StopMonitoringDelivery'}->[0]
                            ->{'MonitoredStopVisit'};

    return @$visits;
}

sub status_from_vehicle_journey {
    my ($call) = @_;

    my $at_stop = $call->{'VehicleAtStop'};
    my $arrival_status = $call->{'DepartureStatus'} // $call->{'ArrivalStatus'};

    my %status_to_letter = (
        'onTime' => 'N',
        'cancelled' => 'S',
        'delayed' => 'R'
       );

    return $status_to_letter{$arrival_status} // $arrival_status;
}

sub parse_datetime {
    my ($datetime_str) = @_;

    return undef unless defined $datetime_str;
    eval {
        DateTime::Format::ISO8601->parse_datetime($datetime_str);
    };
}

sub train_from_vehicle_journey {
    my ($vehicle_journey) = @_;

    my $call = $vehicle_journey->{'MonitoredCall'};
    my $real_time = $call->{'ExpectedDepartureTime'} // $call->{'ExpectedArrivalTime'};
    my $due_time = $call->{'AimedDepartureTime'} // $call->{'AimedArrivalTime'};

    my $sncf_number = $vehicle_journey->{'TrainNumbers'}{'TrainNumberRef'}[0]{'value'};
    my $ratp_number = $vehicle_journey->{'VehicleJourneyName'}[0]{'value'};

    my $terminus = RER::Gares::find(prim_key_arr => $vehicle_journey->{'DestinationRef'}{'value'});

    return RER::Train->new(
        number => $sncf_number // $ratp_number,
        code => $vehicle_journey->{'JourneyNote'}[0]{'value'},
        platform => $call->{'ArrivalPlatformName'}{'value'},
        status => status_from_vehicle_journey($vehicle_journey->{'MonitoredCall'}),
        real_time => parse_datetime($real_time),
        due_time => parse_datetime($due_time),
        terminus => $terminus,
    );
}

1;
