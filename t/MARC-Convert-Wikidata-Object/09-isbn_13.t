use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Object;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb000750997')->s);
my $obj = MARC::Convert::Wikidata::Object->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
my $ret = $obj->isbn_13;
is($ret, undef, 'Get ISBN-13 (undef).');

# Test.
$marc_data = slurp($data->file('cnb002981333')->s);
$obj = MARC::Convert::Wikidata::Object->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
$ret = $obj->isbn_13;
is($ret, '978-80-270-3565-6', 'Get ISBN-13 (ISBN-13).');

# Test.
$marc_data = slurp($data->file('cnb000087983')->s);
$obj = MARC::Convert::Wikidata::Object->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
$ret = $obj->isbn_13;
is($ret, undef, 'Get ISBN-13 (ISBN-10).');
