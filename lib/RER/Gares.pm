#!/usr/bin/perl

package RER::Gares;
use RER::Trains qw(uc_woac);
use DBI;

use strict;
use warnings;
use utf8;


# Don't even think of modifying this directly.  You should be fiddling with
# config.yml instead.
our %config = (
	dsn => 'dbi:SQLite:dbname=gares.db',
	username => '',
	password => ''
);

our $dbh; 

sub db_connect()
{
	$dbh = DBI->connect(
		$config{dsn}, 
		$config{username}, 
		$config{password}) or die $DBI::errstr;
}


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

sub get_delay {
	my ($numero, $from, $time) = @_;

	return undef if ($numero !~ /^1[0-9]{5}$/);

	my $sth = $dbh->prepare(qq{
		SELECT (TIME_TO_SEC(?) - TIME_TO_SEC(departure_time)) DIV 60 AS retard 
		FROM train_times 
		WHERE code = ? AND train_number = ? LIMIT 1;
		});
	$sth->execute($time, $from, $numero) or die $DBI::errstr;

	my $result = $sth->fetchall_arrayref([0]);

	if (scalar(@$result)) {
		return $result->[0][0];
	}
	elsif (($numero % 2) == 1) {
		return get_delay(int($numero) - 1, $from, $time);
	} 
	else {
		return undef;
	}
}

sub format_delay {
	my ($num) = @_;
	return "" 		if not defined $num;
	return "à l'heure" 	if $num == 0;

	my $abs = abs $num;

	my $hours = int($num / 60);
	my $min   = $abs % 60;

	my $str;
	if ($abs >= 60) {
		$str = sprintf "+%d h %02d", $hours, $min;
	}
	else {
		$str = sprintf "+%d min", $min;
	}
	return $str;
}


1;
