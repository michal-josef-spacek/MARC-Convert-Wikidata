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
my $marc_data = slurp($data->file('cnb002181872.mrc')->s);
my $obj = MARC::Convert::Wikidata::Object->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
my @ret = $obj->editors;
is_deeply(
	\@ret,
	[{
		'date_of_birth' => 1814,
		'date_of_death' => 1883,
		'name' => decode_utf8('Antonín'),
		'nkcr_aut' => 'jk01033252',
		'surname' => 'Halouzka',
	}],
	'Get editors (in 100 field).',
);

# Test.
$marc_data = slurp($data->file('cnb003059138.mrc')->s);
$obj = MARC::Convert::Wikidata::Object->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
@ret = $obj->editors;
is_deeply(
	\@ret,
	[],
	'Get editors (none).',
);
