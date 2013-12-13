#!/usr/bin/perl

package RER::Gares;
use RER::Trains qw(uc_woac);
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
		return RER::Gare->new(
			code => $code,
			name => $name,
			uic  => $uic
		);
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
		RER::Gare->new(code => $code, name => $name, uic => $uic) 
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

sub get_ligne {
	my ($num, $dest) = @_;
	return '' if not defined $num;

	if ($num =~ /^\d+$/) {
		my $sth = $dbh->prepare(qq{
			SELECT route_short_name, route_long_name 
				FROM trips 
				JOIN routes USING (route_id) 
			WHERE SUBSTRING(trip_id, 6, 6) = ?;
			});
		$sth->execute($num) or die $DBI::errstr;

		my $result = $sth->fetchall_arrayref([0]);

		if (scalar(@$result)) {
			my $value = $result->[0][0];

			# $value should usually contain a one-letter value, or
			# "TER".  However SNCF somehow manages to fuck this up
			# big time.
			given ($value) {
				$value = 'C' when /Gare d'Aus/i;
				$value = 'C' when /Invalides /i; # note the space
				$value = 'D' when /Evry Courc/i;
				$value = 'D' when /Grigny Cen/i;
				$value = 'D' when /Le Bras de/i;
				$value = 'D' when /Orangis Bo/i;
				$value = 'D' when /Juvisy => /i; # note the space
				$value = 'E' when /Haussmann /i; # note the space
				$value = 'H' when /LUZARCHES /i; # note the space
				$value = 'J' when /Gisors => /i; # note the space
				$value = 'J' when /Mantes la /i; # note the space
				$value = 'R' when /Montargis /i; # note the space
				$value = 'TER' when 'Train';
			}
			return $value;
		}
		elsif (($num % 2) == 1) {
			return get_ligne(int($num) - 1);
		} 
		else {
			return '';
		}
	} else {
		my $mission = substr $num, 0, 4;
		given ($mission) {
			# FIXME: certains codes servent sur les deux lignes !
			return 'B' when qr/^A/;

			return 'A' when qr/^B/;

			return 'A' when qr/^D/;

			return 'A' when qr/^E(?:CAR|CRI|DUR)/;
			return 'B' when qr/^E(?:BER|BRE|CCO|EVE|DAM|FL[AE]|FOC|GON|
						JIX|KIL|KLI|LA[NS]|LIE|MEU|MIR|MOI|
						NRY|NZO|OLE|PA[RUV]|PIS|PEE|QUI|RAS|
						RIO|RNE|SOR|STE|TAL|TUI|URO|VAM|VEN|
						WIL|WOK|X[AI]L|YLO|ZAN)/x;

			return 'B' when qr/^G/;

			return 'B' when qr/^I/;

			return 'A' when qr/^JONE/;
			return 'B' when qr/^J(?:IBY|ONA|EAN|YJY)/;

			return 'B' when qr/^K/;
			return 'B' when qr/^L/;

			return 'A' when qr/^N/;
			return 'A' when qr/^O/;

			return 'A' when qr/^P(?:UC[EU]|OPY)/;
			return 'B' when qr/^P(?:AZZ|BAU|COT|DGE|E[LP]E|ERA|GAS|
					        I[RS][ET]|JAB|LAN|LIC|LUS|MAR|NYX|
						OLY|QUR|ROC|SIT|SOU|TAH|ULE)/x;

			when (qr/^PAPY/) {
				return '' if not defined $dest;
				if ($dest eq 'SNM') {
					return 'B';
				} else {
					return 'A';
				}
			}

			when (qr/^Q/) {
				return '' if not defined $dest;
				if ($dest eq 'LPN') {
					return 'B';
				} else {
					return 'A';
				}
			}
			return 'A' when qr/^R/;

			return 'B' when qr/^S/;

			return 'A' when qr/^T/;
			return 'A' when qr/^U(?:BOS|DON|DRE|I[LT]E|KRA|LLE|MID|PA[CL]|PEL|PIR|R[AE]C|RAM|VAR|XOL|ZAL)/;
			return 'B' when qr/^U(?:BAN|LLE)/;

			return 'A' when qr/^[X-Z]/;
		}
		return '';
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
