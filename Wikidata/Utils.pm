package MARC::Convert::Wikidata::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Readonly;
use Roman;
use Unicode::UTF8 qw(decode_utf8);

Readonly::Array our @EXPORT_OK => qw(clean_cover clean_date clean_edition_number
	clean_number_of_pages clean_oclc clean_publisher_name
	clean_publisher_place clean_series_name clean_series_ordinal clean_subtitle
	clean_title);

our $VERSION = 0.01;
our $DEBUG = 0;

sub clean_cover {
	my $cover = shift;

	if (! defined $cover) {
		return;
	}

	my $ret_cover = $cover;
	$ret_cover =~ s/\s*:\s*$//ms;
	my $c = decode_utf8('Váz');
	$ret_cover =~ s/^\(($c).\)$/hardback/ms;
	$c = decode_utf8('Vázáno');
	$ret_cover =~ s/^\(($c)\)$/hardback/ms;
	$c = decode_utf8('vázáno');
	$ret_cover =~ s/^($c)\)$/hardback/ms;
	$c = decode_utf8('váz');
	$ret_cover =~ s/^\(?($c).\)$/hardback/ms;
	$c = decode_utf8('Brož');
	$ret_cover =~ s/^\(?($c).\)$/paperback/ms;
	$c = decode_utf8('brož');
	$ret_cover =~ s/^\(?($c).\)$/paperback/ms;
	$c = decode_utf8('Brožováno');
	$ret_cover =~ s/^\(($c)\)$/paperback/ms;
	$c = decode_utf8('brožováno');
	$ret_cover =~ s/^($c)\)$/paperback/ms;

	return $ret_cover;
}

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

	# Remove [] on begin and end.
	$ret_edition_number = _remove_square_brackets($ret_edition_number);

	# Remove trailing whitespace
	$ret_edition_number =~ s/^\s+//ms;
	$ret_edition_number =~ s/\s+$//ms;

	# Remove special meanings.
	$ret_edition_number =~ s/opr\. a rozmn\.//ms;
	my $re = decode_utf8('rozš');
	$ret_edition_number =~ s/,\s*$re\.\s*a\s*aktualiz\.//ms;
	$ret_edition_number =~ s/,\s*upr\.//ms;
	$re = decode_utf8('přepracované a doplněné');
	$ret_edition_number =~ s/, $re//ms;

	# Rewrite number in Czech to number.
	# TODO Better
	my $w1 = decode_utf8('První');
	$ret_edition_number =~ s/$w1/1/ms;
	my $w2 = decode_utf8('Druhé');
	$ret_edition_number =~ s/$w2/2/ms;
	my $w3 = decode_utf8('druhé');
	$ret_edition_number =~ s/$w3/2/ms;

	# Remove edition word.
	my $v1 = decode_utf8('Vydání');
	my $v2 = decode_utf8('vydání');
	$ret_edition_number =~ s/\s*(Vyd\.|vyd\.|$v1|$v2)\s*//gx;

	# Remove dots.
	$ret_edition_number =~ s/\.//ms;

	# Rename roman to arabic
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
	$ret_number_of_pages =~ s/^\[(\d+)\]/$1/ms;
	$ret_number_of_pages =~ s/^(\d+)\s*(s\.|stran).*$/$1/ms;

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

sub clean_publisher_name {
	my $publisher_name = shift;

	if (! defined $publisher_name) {
		return;
	}

	my $ret_publisher_name = $publisher_name;

	# Trailing whitespace on begin and end
	$ret_publisher_name = _remove_trailing_whitespace($ret_publisher_name);

	# Separators on the end.
	$ret_publisher_name =~ s/\s*,$//g;
	$ret_publisher_name =~ s/\s*:$//g;
	$ret_publisher_name =~ s/\s*;$//g;

	# Remove ( from begin and not ending.
	$ret_publisher_name =~ s/^\(([^\)]+)$/$1/ms;

	# Remove [] on begin and end.
	$ret_publisher_name = _remove_square_brackets($ret_publisher_name);

	return $ret_publisher_name;
}

sub clean_publisher_place {
	my $publisher_place = shift;

	if (! defined $publisher_place) {
		return;
	}

	my $dict_hr = {
		'Praze' => 'Praha',
		decode_utf8('Pardubicích') => 'Pardubice',
		decode_utf8('Brně') => 'Brno',
	};

	my $ret_publisher_place = $publisher_place;

	$ret_publisher_place =~ s/\s+$//g;
	$ret_publisher_place =~ s/\s*:$//g;
	$ret_publisher_place =~ s/\s*;$//g;

	$ret_publisher_place =~ s/^V\s*//ms;

	foreach my $origin (keys %{$dict_hr}) {
		$ret_publisher_place =~ s/^$origin$/$dict_hr->{$origin}/ms;
	}

	$ret_publisher_place =~ s/^V\s*([\s\w]+)$/$1/ms;
	# [Praha]
	$ret_publisher_place =~ s/^\[(.*?)\]$/$1/ms;

	return $ret_publisher_place;
}

sub clean_series_name {
	my $series_name = shift;

	if (! defined $series_name) {
		return;
	}

	my $ret_series_name = $series_name;

	# Trailing whitespace on begin and end
	$ret_series_name = _remove_trailing_whitespace($ret_series_name);

	$ret_series_name =~ s/\s*;$//g;
	$ret_series_name =~ s/\s*:$//g;

	# Remove [] on begin and end.
	$ret_series_name = _remove_square_brackets($ret_series_name);

	return $ret_series_name;
}

sub clean_series_ordinal {
	my $series_ordinal = shift;

	if (! defined $series_ordinal) {
		return;
	}

	my $ret_series_ordinal = $series_ordinal;
	$ret_series_ordinal =~ s/\s+$//g;
	$ret_series_ordinal =~ s/sv\.\s*(\d+)$/$1/g;
	$ret_series_ordinal =~ s/svazek\s*(\d+)$/$1/g;
	$ret_series_ordinal =~ s/^\s*(\d+)\.?\s*svazek/$1/g;
	$ret_series_ordinal =~ s/Sv\.\s*(\d+)\.?$/$1/g;
	my $c = decode_utf8('č');
	$ret_series_ordinal =~ s/^$c\.\s*//ms;
	$c = decode_utf8('Č');
	$ret_series_ordinal =~ s/^$c\.\s*//ms;
	$c = decode_utf8('číslo');
	$ret_series_ordinal =~ s/^$c\s*//ms;
	if ($ret_series_ordinal =~ m/^(\d+)-(\d+)$/ms) {
		my $first = $1;
		my $second = $2;
		if ($second < $first) {
			my $first_len = length $first;
			my $second_len = length $second;
			my $first_addition = substr $first, 0, ($first_len - $second_len);
			$ret_series_ordinal = $first.'-'.$first_addition.$second;
		}
	}

	return $ret_series_ordinal;
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

sub _remove_trailing_whitespace {
	my $string = shift;

	$string =~ s/^\s+//g;
	$string =~ s/\s+$//g;

	return $string;
}

sub _remove_square_brackets {
	my $string = shift;

	$string =~ s/^\[\s*(.*?)\s*\]$/$1/ms;
	$string =~ s/^\[\s*([^\]]+)$/$1/ms;

	return $string;
}

1;

__END__
