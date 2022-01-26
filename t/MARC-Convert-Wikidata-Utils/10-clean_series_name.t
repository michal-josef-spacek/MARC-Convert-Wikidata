use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_series_name);
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $input_series_name = 'Lidové umění slovesné. Řada A ;';
my $ret = clean_series_name($input_series_name);
is($ret, 'Lidové umění slovesné. Řada A', "Series name '$input_series_name' after cleanup.");
