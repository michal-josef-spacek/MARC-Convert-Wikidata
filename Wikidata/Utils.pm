package MARC::Convert::Wikidata::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Readonly;
use Roman;
use Unicode::UTF8 qw(decode_utf8);

Readonly::Array our @EXPORT_OK => qw(clean_date clean_edition_number clean_number_of_pages
	clean_oclc clean_subtitle clean_title);

our $VERSION = 0.01;
our $DEBUG = 0;

sub clean_date {
	my $date = shift;

	if (! defined $date) {
		return;
	}
	if (! $date) {
		return;
	}

	my $months_hr = {
		'leden' => '01',
		decode_utf8('únor') => '02',
		decode_utf8('březen') => '03',
		'duben' => '04',
		decode_utf8('květen') => '05',
		decode_utf8('červen') => '06',
		decode_utf8('červenec') => '07',
		'srpen' => '08',
		decode_utf8('září') => '09',
		decode_utf8('říjen') => '10',
		'listopad' => '11',
		'prosinec' => '12',
	};

	my $ret_date = $date;
	foreach my $month (keys %{$months_hr}) {
		$ret_date =~ s/^(\d{4})\s*$month\s*(\d+)\.$/$1-$months_hr->{$month}-$2/ms;
	}
	my $bk = decode_utf8('př. Kr.');
	$ret_date =~ s/^(\d+)\s*$bk/-$1/ms;
	$ret_date =~ s/\s*\.$//ms;

	return $ret_date;
}

sub clean_edition_number {
	my $edition_number = shift;

	if (! defined $edition_number) {
		return;
	}

	my $ret_edition_number = $edition_number;
	$ret_edition_number =~ s/^Vyd. (\d+)./$1/ms;
	$ret_edition_number =~ s/\s+$//ms;
	$ret_edition_number =~ s/^První/1/ms;
	$ret_edition_number =~ s/^Druhé/2/ms;
	$ret_edition_number =~ s/\s*vyd\.$//ms;
	$ret_edition_number =~ s/\s*vydání$//ms;
	$ret_edition_number =~ s/\s*opr\. a rozmn\.$//ms;
	$ret_edition_number =~ s/\s*\.$//ms;
	if (isroman($ret_edition_number)) {
		$ret_edition_number = arabic($ret_edition_number);
	}

	if ($ret_edition_number !~ m/^\d+$/ms) {
		if ($DEBUG) {
			warn "Edition number '$edition_number' couldn't clean.";
		}
		$ret_edition_number = undef;
	}

	return $ret_edition_number;
}

sub clean_number_of_pages {
	my $number_of_pages = shift;

	if (! defined $number_of_pages) {
		return;
	}

	my $ret_number_of_pages = $number_of_pages;
	$ret_number_of_pages =~ s/\s+$//g;
	$ret_number_of_pages =~ s/\s*:$//g;
	$ret_number_of_pages =~ s/\s*;$//g;
	$ret_number_of_pages =~ s/\s*s\.$//g;
	$ret_number_of_pages =~ s/\s*stran$//g;
	my $trail = decode_utf8('nečíslovaných');
	$ret_number_of_pages =~ s/\s*$trail$//g;
	$ret_number_of_pages =~ s/^\[(.*?)\]$/$1/ms;

	if ($ret_number_of_pages !~ m/^\d+$/ms) {
		if ($DEBUG) {
			warn "Number of pages '$number_of_pages' couldn't clean.";
		}
		$ret_number_of_pages = undef;
	}

	return $ret_number_of_pages;
}

sub clean_oclc {
	my $oclc = shift;

	if (! defined $oclc) {
		return;
	}

	my $ret_oclc = $oclc;
	$ret_oclc =~ s/^\(OCoLC\)//ms;

	return $ret_oclc;
}

sub clean_subtitle {
	my $subtitle = shift;

	if (! defined $subtitle) {
		return;
	}

	my $ret_subtitle = $subtitle;
	$ret_subtitle =~ s/\s+$//g;
	$ret_subtitle =~ s/\/$//g;
	$ret_subtitle =~ s/\s+$//g;

	return $ret_subtitle;
}

sub clean_title {
	my $title = shift;

	if (! defined $title) {
		return;
	}

	my $ret_title = $title;
	$ret_title =~ s/\s+$//g;
	$ret_title =~ s/\s*\/$//g;
	$ret_title =~ s/\s*\:$//g;

	return $ret_title;
}

1;

__END__
