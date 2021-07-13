use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Object;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb000087983.mrc')->s);
my $obj = MARC::Convert::Wikidata::Object->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
my @ret = $obj->translators;
is_deeply(
	\@ret,
	[{
		'date_of_birth' => 1939,
		'name' => decode_utf8('Jiří'),
		'nkcr_aut' => 'jk01121492',
		'surname' => decode_utf8('Stromšík'),
	}],
	'Get translators (one).',
);

# Test.
$marc_data = slurp($data->file('cnb000750997.mrc')->s);
$obj = MARC::Convert::Wikidata::Object->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
@ret = $obj->translators;
is_deeply(
	\@ret,
	[],
	'Get translators (zero).',
);

# Test.
$marc_data = slurp($data->file('cnb003059138.mrc')->s);
$obj = MARC::Convert::Wikidata::Object->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
@ret = $obj->translators;
is_deeply(
	\@ret,
	[{
		'date_of_birth' => 1992,
		'name' => decode_utf8('Alžběta'),
		'nkcr_aut' => 'kv2016916117',
		'surname' => decode_utf8('Franková'),
	}, {
		'date_of_birth' => 1993,
		'name' => decode_utf8('Kryštof'),
		'nkcr_aut' => 'mzk2016922818',
		'surname' => 'Herold',
	}],
	'Get translators (two in 700 field).',
);
