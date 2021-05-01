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
my $marc_data = slurp($data->file('cnb000750997')->s);
my $obj = MARC::Convert::Wikidata::Object->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
my $ret = $obj->subtitle;
is($ret, decode_utf8('Román'), 'Get subtitle of book edition.');

# Test.
$marc_data = slurp($data->file('cnb000087983')->s);
$obj = MARC::Convert::Wikidata::Object->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
$ret = $obj->subtitle;
is($ret, undef, 'Get subtitle of book edition (undef).');
