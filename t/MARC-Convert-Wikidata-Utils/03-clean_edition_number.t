use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_edition_number);
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Test.
my $input_edition_number = '1. vyd.';
my $ret = clean_edition_number($input_edition_number);
is($ret, 1, "Edition number '1. vyd.' after cleanup.");

# Test.
$input_edition_number = '1. vydání';
$ret = clean_edition_number($input_edition_number);
is($ret, 1, "Edition number '1. vydání' after cleanup.");

# Test.
$input_edition_number = 'První vydání';
$ret = clean_edition_number($input_edition_number);
is($ret, 1, "Edition number 'První vydání' after cleanup.");

# Test.
$input_edition_number = 'Druhé vydání';
$ret = clean_edition_number($input_edition_number);
is($ret, 2, "Edition number 'Druhé vydání' after cleanup.");

# Test.
$input_edition_number = 'II. vyd.';
$ret = clean_edition_number($input_edition_number);
is($ret, 2, "Edition number 'II. vyd.' after cleanup.");

# Test.
$input_edition_number = '2. vyd.';
$ret = clean_edition_number($input_edition_number);
is($ret, 2, "Edition number '2. vyd.' after cleanup.");

# Test.
$input_edition_number = '2. opr. a rozmn. vyd.';
$ret = clean_edition_number($input_edition_number);
is($ret, 2, "Edition number '2. opr. a rozmn. vyd.' after cleanup.");

# TODO Lidové vydání
