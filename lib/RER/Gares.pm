#!/usr/bin/perl

package RER::Gares;
use RER::Gare;
use DBI;
use DateTime;
use DateTime::Format::Strptime;

use strict;
use warnings;
use utf8;
use 5.010;


# Don't even think of modifying this directly.  You should be fiddling with
# config.yml instead.
our %config = (
	dsn => 'dbi:SQLite:dbname=gares.db',
	username => '',
	password => ''
);

our $dbh; 

sub db_connect
{
	$dbh = DBI->connect(
		$config{dsn}, 
		$config{username}, 
		$config{password}) or die $DBI::errstr;
}


sub get_last_update {
	my $sth = $dbh->prepare("SELECT value FROM metadata WHERE `key` = 'dmaj'");
	$sth->execute;
	my $result = $sth->fetchall_arrayref([0]);

	my $strp = DateTime::Format::Strptime->new(
		pattern => '%e %B %Y',
		locale  => 'fr_FR',
	);

	my $dt = DateTime->from_epoch( 
		epoch => $result->[0][0],
		formatter => $strp,
	);

	return $strp->format_datetime($dt);
}


sub get_station_codes
{
	my $sth = $dbh->prepare('SELECT code FROM gares');
	$sth->execute;
	return $sth->fetchall_arrayref([0]);
}

sub get_stations
{
	my $sth = $dbh->prepare('SELECT code, name, uic FROM gares WHERE is_transilien = 1 ORDER BY name');
	$sth->execute;
	return $sth->fetchall_arrayref({});
}

sub get_lines 
{
	my ($arg) = @_;

	my $uic;
	$uic = $arg->uic if ref $arg eq 'RER::Gare';
	$uic = $arg 	 if ref $arg ne 'RER::Gare';
		

	my $sth = $dbh->prepare('SELECT line FROM gares_lines WHERE uic = ?');
	$sth->execute($uic);
	my @result = map { $_->[0] } @{$sth->fetchall_arrayref([0])};
	return \@result;
}

sub find
{
	my %params = @_;

	my $sth;

	$dbh ||= db_connect();

	if (exists $params{code}) {
		$sth = $dbh->prepare('SELECT code, name, uic FROM gares WHERE code = ?');
		$sth->execute($params{code});
	}
	elsif (exists $params{uic}) {
		# les codes UIC ont deux variétés : ceux à 7 chiffres et ceux à 8.
		# ceux à 8 chiffres ont un chiffre de contrôle (superflu) qu'on
		# enlève, parce qu'on ne stocke que 7 chiffres dans la BDD.
		my $uic = substr $params{uic}, 0, 7;

		$sth = $dbh->prepare('SELECT code, name, uic FROM gares WHERE uic = ?');
		$sth->execute($uic);
	}
	else {
		return undef;
	}

	my $result = $sth->fetchall_arrayref();
	
	if(scalar(@$result)) {
		my ($code, $name, $uic) = @{$result->[0]};
		# utf8::decode($name);
		my $gare = RER::Gare->new(
			code => $code,
			name => $name,
			uic  => $uic
		);

		$gare->lines(get_lines($gare));

		return $gare;
	}
	else {
		return undef;
	}
}

sub get_autocomp
{
	my ($str) = @_;
	$str =~ s/([_%])/\\$1/g;

	my $sth = $dbh->prepare(qq{
		SELECT code, name, uic
			FROM gares 
			WHERE is_transilien AND (code = UPPER(?) OR name LIKE ?) 
			ORDER BY INSTR(name, ?), name
			LIMIT 10;});
	$sth->execute("$str", "%$str%", "$str");

	my $result = $sth->fetchall_arrayref({});
	
	my @obj_result = map { 
		my $code = $_->{code};
		my $uic  = $_->{uic};
		my $name = $_->{name};
		utf8::decode($name);
		RER::Gare->new(code => $code, name => $name, uic => $uic, lines => get_lines($_->{uic})) 
	} @$result;
	return \@obj_result;
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
		my $value = $result->[0][0];
		$value += 1440 while $value <= -720;
		return $value;
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
		$str = sprintf "%+d h %02d", $hours, $min;
	}
	else {
		$str = sprintf "%+d min", $min;
	}
	return $str;
}


1;
