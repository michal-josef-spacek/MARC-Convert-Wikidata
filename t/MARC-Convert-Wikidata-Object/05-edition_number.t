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
my $marc_data = slurp($data->file('cnb000087983')->s);
my $obj = MARC::Convert::Wikidata::Object->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
my $ret = $obj->edition_number;
is($ret, 1, 'Get edition number (1. vyd.).');

# Test.
$marc_data = slurp($data->file('cnb000573607')->s);
$obj = MARC::Convert::Wikidata::Object->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
$ret = $obj->edition_number;
is($ret, 2, 'Get edition number (II. vyd.).');

# Test.
$marc_data = slurp($data->file('cnb000750997')->s);
$obj = MARC::Convert::Wikidata::Object->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
$ret = $obj->edition_number;
is($ret, undef, 'Get edition number (Lidove vydani).');
