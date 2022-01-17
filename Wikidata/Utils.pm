package MARC::Convert::Wikidata::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Readonly;
use Roman;
use Unicode::UTF8 qw(decode_utf8);

Readonly::Array our @EXPORT_OK => qw(clean_edition_number clean_number_of_pages);

our $VERSION = 0.01;

sub clean_edition_number {
	my $edition_number = shift;

	if (! defined $edition_number) {
		return;
	}

	my $ret_edition_number = $edition_number;
	$ret_edition_number =~ s/\s+$//g;
	$ret_edition_number =~ s/^První/1/ms;
	$ret_edition_number =~ s/^Druhé/2/ms;
	$ret_edition_number =~ s/\s*vyd\.$//g;
	$ret_edition_number =~ s/\s*vydání$//g;
	$ret_edition_number =~ s/\s*opr\. a rozmn\.$//g;
	$ret_edition_number =~ s/\s*\.$//g;
	if (isroman($ret_edition_number)) {
		$ret_edition_number = arabic($ret_edition_number);
	}

	if ($ret_edition_number !~ m/^\d+$/ms) {
		warn "Edition number '$edition_number' couldn't clean.";
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

	if ($ret_number_of_pages !~ m/^\d+$/ms) {
		warn "Number of pages '$number_of_pages' couldn't clean.";
		$ret_number_of_pages = undef;
	}

	return $ret_number_of_pages;
}

1;

__END__
