package RER::Web;
use Dancer ':syntax';

use RER::Transilien;
use RER::Trains;
use Data::Dumper;

our $VERSION = '0.1';



my %train_obj;
my %train_obj_last_update;

prefix '/rer';


sub check_code {
    my ($code) = @_;

    return undef unless $code;

    $code = uc $code;
    if($code =~ /^[A-Z]{1,3}$/) {
        return $code;
    }
    else {
        return undef;
    }
}

get '/' => sub {
    my $origin_code = check_code(params->{'s'}) || 'EVC';
    my $origin_station = RER::Gares::get_station_by_code($origin_code);
    utf8::decode($origin_station);

    template 'rer', {
    	origin_station => $origin_station,
        origin_code => $origin_code,
        stations => RER::Gares::get_stations(),
    };
};

get '/json' => sub {
    header 'Content-type' => 'text/plain; charset=utf-8';

    my $code = check_code(params->{'s'}) || 'EVC';

    if (   !defined $train_obj_last_update{$code} 
        || time - $train_obj_last_update{$code} > 10) {
        $train_obj{$code} = RER::Transilien::new(from => $code);
        $train_obj_last_update{$code} = time;
    }

    return $train_obj{$code}->format();
};


true;

# vi:ts=4:sw=4:et:
