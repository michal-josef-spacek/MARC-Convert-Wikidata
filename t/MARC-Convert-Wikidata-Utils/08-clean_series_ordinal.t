use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_series_ordinal);
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $input_series_ordinal = 'sv. 4';
my $ret = clean_series_ordinal($input_series_ordinal);
is($ret, '4', "Series ordinal '$input_series_ordinal' after cleanup.");
