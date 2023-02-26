#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use 5.010;

use lib '../lib';
use lib 'lib';

use Getopt::Long;
use Pod::Usage;

use RER::DataSource::PRIM;
use RER::DataSource::TransilienGTFS;

use RER::Gares;
use Dancer qw(:script !pass);
use Dancer::Plugin::Database;

binmode STDOUT, ':encoding(UTF-8)';

sub train_to_fields {
    my ($train) = @_;

    my $terminus_name = ($train->terminus) ? $train->terminus->name : "?";

    my $delay;
    if ($train->real_time && $train->due_time) {
        $delay = $train->real_time - $train->due_time;
        $delay = $delay->in_units('minutes');
    }

    my @status = ($train->status);
    unless ($train->is_stopping) {
        push @status, "SA"
    }

    return (
        $train->number,
        $train->code // '',
        ($train->real_time) ? substr($train->real_time->time, 0, 5) : "--:--",
        ($train->due_time) ? substr($train->due_time->time, 0, 5) : "--:--",
        join(",", @status),
        $train->line // '?',
        (defined $train->stations ? scalar(@{$train->stations}) : "?"),
        $train->platform // '',
        $terminus_name);
}

sub usage {
    pod2usage($_[0] // 2);
}

sub main {
    my $want_help = 0;
    my $print_table = 1;
    my $print_api_output = 0;

    GetOptions(
        'help' => \$want_help,
        'table!' => \$print_table,
        'raw!' => \$print_api_output,
        );

    usage(0) if $want_help;
    my $code = $ARGV[0];
    usage() unless defined $code;

    my $gare = RER::Gares::find(code => $code);
    die "$code: gare non valable\n" if ! defined ($gare);

    say STDERR ("MonitoringRef : " . $gare->prim_api_search_key());

    exit(0) unless $print_table || $print_api_output;

    my $ds  = RER::DataSource::PRIM->new(
        api_token	=> config->{'prim_token'});

    my ($real_time_data, $json) = $ds->get_next_trains($gare);
    utf8::decode($json);

    if ($print_table) {
        my $ds2 = RER::DataSource::TransilienGTFS->new(dbh => database);
        my @data = @{$ds2->complete_train_info($gare, $real_time_data)};

        my @widths = (6, 4, 5, 5, 4, 5, 6, 4, 30);
        my @headers = qw(Numéro Nom Réel Théo. État Ligne Arrêts Voie Terminus);

        say(join " ", map { sprintf("%-*s", $widths[$_], $headers[$_]) } (0..$#widths));
        say(join " ", map { "=" x $_ } @widths);

        foreach my $train (@data) {
            my @fields = train_to_fields($train);
            say join(" ", map { sprintf("%-*s", $widths[$_], $fields[$_]) } (0..$#widths));
        }
    }
    
    say $json if $print_api_output;
}

main();

__END__

=head1 NAME

test_api.pl - Test and debug API access

=head1 SYNOPSIS

./test_api.pl [options] station-code

=head1 OPTIONS

=over 8

=item B<--help>

Prints a brief help message and exits.

=item B<--no-table>

Do not print the timetable.

=item B<--raw>

Print the raw JSON output received from the API.
