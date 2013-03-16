#!/usr/bin/perl

package RER::Gares;
use RER::Trains qw(uc_woac);
use DBI;

use strict;
use warnings;

our $dbh = DBI->connect("dbi:SQLite:dbname=gares.db") or die $DBI::errstr;

sub get_station_codes()
{
	my $sth = $dbh->prepare('SELECT code FROM gares');
	$sth->execute;
	return $sth->fetchall_arrayref([0]);
}

sub get_stations()
{
	my $sth = $dbh->prepare('SELECT code, name FROM gares WHERE is_transilien = 1 ORDER BY name');
	$sth->execute;
	return $sth->fetchall_arrayref({});
}

sub get_station_by_code($)
{
	my ($code) = @_;

	my $sth = $dbh->prepare('SELECT name FROM gares WHERE code = ?');
	$sth->execute($code);

	my $result = $sth->fetchall_arrayref([0]);
	
	if(scalar(@$result)) {
		return $result->[0][0];
	}
	else {
		return "<i>Gare inconnue ($code)</i>";
	}
}



1;
