use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Object;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb002467522.mrc')->s);
my $obj = MARC::Convert::Wikidata::Object->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
my @ret = $obj->illustrators;
is_deeply(
	\@ret,
	[{
		'date_of_birth' => 1853,
		'date_of_death' => 1932,
		'name' => 'Hans',
		'nkcr_aut' => 'xx0104411',
		'surname' => 'Tegner',
	}],
	'Get illustrators (in 700 field).',
);

# Test.
$marc_data = slurp($data->file('cnb003059138.mrc')->s);
$obj = MARC::Convert::Wikidata::Object->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
@ret = $obj->illustrators;
is_deeply(
	\@ret,
	[],
	'Get illustrators (none).',
);
