package MARC::Convert::Wikidata::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Readonly;
use Roman;

Readonly::Array our @EXPORT_OK => qw(clean_edition_number);

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

1;

__END__
