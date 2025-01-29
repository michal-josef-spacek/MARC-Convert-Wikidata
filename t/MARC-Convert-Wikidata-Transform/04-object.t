use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Transform;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 50;
use Test::NoWarnings;
use Test::Warn;
use Unicode::UTF8 qw(decode_utf8);

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb000750997.mrc')->s);
my $obj;
warning_like
	{
		$obj = MARC::Convert::Wikidata::Transform->new(
			'marc_record' => MARC::Record->new_from_usmarc($marc_data),
		);
	}
	qr{^Edition number 'Lidové vydání' cannot clean\.},
	"Test of warning about 'Lidové vydání' edition number.",
;
my $ret = $obj->object;
my $author = $ret->authors->[0];
is($author->name, 'Karel', 'Krakatit: Get author name.');
is($author->surname, decode_utf8('Čapek'), 'Krakatit: Get author surname.');
is($author->date_of_birth, 1890, 'Krakatit: Get author date of birth.');
is($author->date_of_death, 1938, 'Krakatit: Get author date of death.');
my $author_ext_ids_ar = $author->external_ids;
is(@{$author_ext_ids_ar}, 1, 'Krakatit: Get author external ids count (1).');
is($author_ext_ids_ar->[0]->name, 'nkcr_aut', 'Krakatit: Get author external value name (nkcr_aut).');
is($author_ext_ids_ar->[0]->value, 'jk01021023', 'Krakatit: Get author NKCR id (jk01021023).');
is($ret->edition_number, undef, 'Krakatit: Get edition number.');
is_deeply($ret->editors, [], 'Krakatit: Get editors.');
my $external_ids_ar = $ret->external_ids;
is(@{$external_ids_ar}, 2, 'Krakatit: Get external ids count (2).');
is($external_ids_ar->[0]->name, 'cnb', 'Krakatit: Get external value name (cnb).');
is($external_ids_ar->[0]->value, 'cnb000750997', 'Krakatit: Get ČČNB number (cnb000750997).');
is($external_ids_ar->[1]->name, 'lccn', 'Krakatit: Get external value name (lccn).');
is($external_ids_ar->[1]->value, '3791532', 'Krakatit: Get ICCN number (3791532).');
is_deeply($ret->illustrators, [], 'Krakatit: Get illustrators.');
is_deeply($ret->isbns, [], 'Krakatit: Get ISBN-10.');
is_deeply($ret->krameriuses, [], 'Krakatit: Get Kramerius objects.');
is_deeply($ret->languages, ['cze'], 'Krakatit: Get language.');
is($ret->number_of_pages, 377, 'Krakatit: Get number of pages.');
is($ret->publication_date, 1939, 'Krakatit: Get publication date.');
is($ret->publishers->[0]->name, decode_utf8('Fr. Borový'), 'Krakatit: Get publisher.');
is($ret->publishers->[0]->place, 'Praha', 'Krakatit: Get publisher place.');
is_deeply($ret->subtitles, [decode_utf8('Román')], 'Krakatit: Get subtitles.');
is($ret->title, 'Krakatit', 'Krakatit: Get title.');
is_deeply($ret->translators, [], 'Krakatit: Get translators.');
# TODO book series
# TODO book series series ordinal
# TODO Kramerius link

# Test.
$marc_data = slurp($data->file('cnb000576456.mrc')->s);
$obj = MARC::Convert::Wikidata::Transform->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
$ret = $obj->object;
$author = $ret->authors->[0];
is($author->name, 'Jan', 'Broučci: Get author name.');
is($author->surname, decode_utf8('Karafiát'), 'Broučci: Get author surname.');
is($author->date_of_birth, 1846, 'Broučci: Get author date of birth.');
is($author->date_of_death, 1929, 'Broučci: Get author date of death.');
$author_ext_ids_ar = $author->external_ids;
is(@{$author_ext_ids_ar}, 1, 'Broučci: Get author external ids count (1).');
is($author_ext_ids_ar->[0]->name, 'nkcr_aut', 'Broučci: Get author external value name (nkcr_aut).');
is($author_ext_ids_ar->[0]->value, 'jk01052941', 'Broučci: Get author NKCR id (jk01052941).');
is($ret->edition_number, 2, 'Broučci: Get edition number.');
is_deeply($ret->editors, [], 'Broučci: Get editors.');
$external_ids_ar = $ret->external_ids;
is(@{$external_ids_ar}, 1, 'Broučci: Get external ids count (2).');
is($external_ids_ar->[0]->name, 'cnb', 'Broučci: Get external value name (cnb).');
is($external_ids_ar->[0]->value, 'cnb000576456', 'Broučci: Get ČČNB number (cnb000576456).');
is_deeply($ret->illustrators, [], 'Broučci: Get illustrators.');
is_deeply($ret->isbns, [], 'Broučci: Get ISBN-10.');
is_deeply($ret->krameriuses, [], 'Broučci: Get Kramerius objects.');
is_deeply($ret->languages, ['cze'], 'Broučci: Get language.');
is($ret->number_of_pages, 85, 'Broučci: Get number of pages.');
# TODO + ?
is($ret->publication_date, 1919, 'Broučci: Get publication date.');
is($ret->publishers->[0]->name, 'Alois Hynek', 'Broučci: Get publisher.');
is($ret->publishers->[0]->place, 'Praha', 'Broučci: Get publisher place.');
is_deeply($ret->subtitles, [decode_utf8('pro malé i veliké děti')], 'Broučci: Get subtitles.');
is($ret->title, decode_utf8('Broučci'), 'Broučci: Get title.');
is_deeply($ret->translators, [], 'Broučci: Get translators.');
