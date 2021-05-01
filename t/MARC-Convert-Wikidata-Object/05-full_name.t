use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Object;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 2;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb000750997')->s);
my $obj = MARC::Convert::Wikidata::Object->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
my $ret = $obj->full_name;
is($ret, decode_utf8('Krakatit: Román'), 'Get full name of book edition.');
