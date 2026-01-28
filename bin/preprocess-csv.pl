#!/usr/bin/env perl

# Ce script fait un prétraitement sur les fichiers CSV du GTFS reçus par la
# SNCF. Il charge un ensemble de fichiers CSV, change l'ordre des colonnes et
# ne conserve que les colonnes nécessaires. En particulier, les colonnes qui
# ne sont pas nécessaires ne sont pas conservées et leur présence ou leur
# absence n'a aucune influence sur le script.

use warnings;
use strict;
use v5.26;
use utf8;

use Text::CSV;

sub assign_columns {
    my ($wanted_columns, $input_columns) = @_;

    my $n = 0;
    my %input_map = map { $_ => $n++ } (@$input_columns);

    my @mapping;
    for my $col (@$wanted_columns) {
        if (not exists $input_map{$col}) {
            warn "$col: no such column in input\n";
            next;
        }
        push @mapping, $input_map{$col};
    }

    if (scalar @mapping != scalar @$wanted_columns) {
        warn "Columns in file: " . join(', ', @$input_columns) . ".\n";
        die "Aborting.\n";
    }

    return \@mapping;
}

sub do_file {
    my ($csv_in, $csv_out, $filename, $columns) = @_;

    open my $fh, '<:encoding(utf8)', $filename or die "$filename: $!\n";

    my @input_columns = $csv_in->header($fh, { munge => "none" });
    my $mapping = assign_columns($columns, \@input_columns);

    $csv_out->say(*STDOUT, $columns);
    while (my $row = $csv_in->getline($fh)) {
        my @new_columns = @{$row}[@$mapping];
        $csv_out->say(*STDOUT, \@new_columns);
    }

    close $fh;
}

sub usage {
    say "Usage: $0 <FILE> <COLUMN> [<MORE_COLUMNS_TO_KEEP>...]";
}

sub main {
    binmode *STDOUT, ':encoding(utf8)';
    binmode *STDERR, ':encoding(utf8)';
    if (scalar @ARGV == 0 or $ARGV[0] eq "--help") {
        usage();
        exit(2);
    }

    my $csv_in = Text::CSV->new({});
    my $csv_out = Text::CSV->new({ eol => "\n" });

    my ($filename, @columns) = @ARGV;

    do_file($csv_in, $csv_out, $filename, \@columns);
}

main;
