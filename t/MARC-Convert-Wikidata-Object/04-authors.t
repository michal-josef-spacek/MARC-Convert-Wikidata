use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Object;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb000750997.mrc')->s);
my $obj = MARC::Convert::Wikidata::Object->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
my @ret = $obj->authors;
is_deeply(
	\@ret,
	[{
		'date_of_birth' => 1890,
		'date_of_death' => 1938,
		'name' => 'Karel',
		'nkcr_aut' => 'jk01021023',
		'surname' => decode_utf8('Čapek'),
	}],
	'Get authors (in 100 field).',
);

# Test.
$marc_data = slurp($data->file('cnb003059138.mrc')->s);
$obj = MARC::Convert::Wikidata::Object->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
@ret = $obj->authors;
is_deeply(
	\@ret,
	[{
		'name' => 'Elena',
		'nkcr_aut' => 'xx0221236',
		'surname' => 'Favilli',
	}, {
		'date_of_birth' => 1983,
		'name' => 'Francesca',
		'nkcr_aut' => 'xx0221237',
		'surname' => 'Cavallo',
	}],
	'Get authors (one in 100 field, second in 700 field).',
);
