use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Object;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb000750997.mrc')->s);
my $obj = MARC::Convert::Wikidata::Object->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
my $ret = $obj->publication_date;
is($ret, 1939, 'Get publication date (field 260c).');

# Test.
$marc_data = slurp($data->file('cnb002981333.mrc')->s);
$obj = MARC::Convert::Wikidata::Object->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
$ret = $obj->publication_date;
is($ret, 2018, 'Get publication date (field 264c).');

# Test.
$marc_data = slurp($data->file('cnb000573607.mrc')->s);
$obj = MARC::Convert::Wikidata::Object->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
($ret, my $ret2) = $obj->publication_date;
is($ret, 1925, 'Get supposition publication date (field 260c).');
is($ret2, 1, 'Publication date is supposition.');

# Test
## TODO Without publication date
## TODO With unknown publication date
