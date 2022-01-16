use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Transform;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 47;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb000087983.mrc')->s);
my $obj = MARC::Convert::Wikidata::Transform->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
my $ret = $obj->object;
my $author = $ret->authors->[0];
is($author->name, 'Elias', 'Masa a moc: Get author name.');
is($author->surname, 'Canetti', 'Masa a moc: Get author surname.');
is($author->date_of_birth, 1905, 'Masa a moc: Get author date of birth.');
is($author->date_of_death, 1994, 'Masa a moc: Get author date of death.');
is($author->nkcr_aut, 'jn19990001316', 'Masa a moc: Get author NKČR AUT id.');
is($ret->ccnb, 'cnb000087983', 'Masa a moc: Get ČČNB number.');
is($ret->edition_number, 1, 'Masa a moc: Get edition number.');
is_deeply($ret->editors, [], 'Masa a moc: Get editors.');
is_deeply($ret->illustrators, [], 'Masa a moc: Get illustrators.');
is($ret->language, 'cze', 'Masa a moc: Get language.');
is($ret->isbn_10, '80-85812-08-8', 'Masa a moc: Get ISBN-10.');
is($ret->isbn_13, undef, 'Masa a moc: Get ISBN-13.');
my $kramerius = $ret->krameriuses->[0];
is($kramerius->kramerius_id, 'mzk', 'Masa a moc: Get Kramerius system id.');
is($kramerius->object_id, 'dec885c0-51fc-11e5-bf4b-005056827e51',
	'Masa a moc: Get Kramerius object id.');
is($kramerius->url,
	'http://kramerius.mzk.cz/search/handle/uuid:dec885c0-51fc-11e5-bf4b-005056827e51',
	'Masa a moc: Get Kramerius object link.');
is($ret->number_of_pages, 575, 'Masa a moc: Get number of pages.');
is($ret->publication_date, 1994, 'Masa a moc: Get publication date.');
is($ret->publishers->[0]->name, 'Arcadia', 'Masa a moc: Get publisher.');
is($ret->publishers->[0]->place, 'Praha', 'Masa a moc: Get publisher place.');
is($ret->subtitle, undef, 'Masa a moc: Get subtitle.');
is($ret->title, 'Masa a moc', 'Masa a moc: Get title.');
my $translator = $ret->translators->[0];
is($translator->name, decode_utf8('Jiří'), 'Masa a moc: Get translator name.');
is($translator->surname, decode_utf8('Stromšík'), 'Masa a moc: Get translator surname.');
is($translator->date_of_birth, 1939, 'Masa a moc: Get translator date of birth.');
is($translator->date_of_death, undef, 'Masa a moc: Get translator date of death.');
is($translator->nkcr_aut, 'jk01121492', 'Masa a moc: Get translator NKČR AUT id.');
# TODO book series
# TODO book series series ordinal
# TODO Kramerius link

# Test.
$marc_data = slurp($data->file('cnb000750997.mrc')->s);
$obj = MARC::Convert::Wikidata::Transform->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
$ret = $obj->object;
$author = $ret->authors->[0];
is($author->name, 'Karel', 'Krakatit: Get author name.');
is($author->surname, decode_utf8('Čapek'), 'Krakatit: Get author surname.');
is($author->date_of_birth, 1890, 'Krakatit: Get author date of birth.');
is($author->date_of_death, 1938, 'Krakatit: Get author date of death.');
is($author->nkcr_aut, 'jk01021023', 'Krakatit: Get author NKČR AUT id.');
is($ret->ccnb, 'cnb000750997', 'Krakatit: Get ČČNB number.');
is($ret->edition_number, undef, 'Krakatit: Get edition number.');
is_deeply($ret->editors, [], 'Krakatit: Get editors.');
is_deeply($ret->illustrators, [], 'Krakatit: Get illustrators.');
is($ret->isbn_10, undef, 'Krakatit: Get ISBN-10.');
is($ret->isbn_13, undef, 'Krakatit: Get ISBN-13.');
is_deeply($ret->krameriuses, [], 'Krakatit: Get Kramerius objects.');
is($ret->language, 'cze', 'Krakatit: Get language.');
is($ret->number_of_pages, 377, 'Krakatit: Get number of pages.');
is($ret->publication_date, 1939, 'Krakatit: Get publication date.');
is($ret->publishers->[0]->name, decode_utf8('Fr. Borový'), 'Krakatit: Get publisher.');
is($ret->publishers->[0]->place, 'Praha', 'Krakatit: Get publisher place.');
is($ret->subtitle, decode_utf8('Román'), 'Krakatit: Get subtitle.');
is($ret->title, 'Krakatit', 'Krakatit: Get title.');
is_deeply($ret->translators, [], 'Krakatit: Get translators.');
# TODO book series
# TODO book series series ordinal
# TODO Kramerius link
