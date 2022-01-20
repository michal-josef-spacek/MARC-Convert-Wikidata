use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_edition_number);
use Test::More 'tests' => 9;
use Test::NoWarnings;

# Test.
my $input_edition_number = '1. vyd.';
my $ret = clean_edition_number($input_edition_number);
is($ret, 1, "Edition number '$input_edition_number' after cleanup.");

# Test.
$input_edition_number = '1. vydání';
$ret = clean_edition_number($input_edition_number);
is($ret, 1, "Edition number '$input_edition_number' after cleanup.");

# Test.
$input_edition_number = 'První vydání';
$ret = clean_edition_number($input_edition_number);
is($ret, 1, "Edition number '$input_edition_number' after cleanup.");

# Test.
$input_edition_number = 'Druhé vydání';
$ret = clean_edition_number($input_edition_number);
is($ret, 2, "Edition number '$input_edition_number' after cleanup.");

# Test.
$input_edition_number = 'II. vyd.';
$ret = clean_edition_number($input_edition_number);
is($ret, 2, "Edition number '$input_edition_number' after cleanup.");

# Test.
$input_edition_number = '2. vyd.';
$ret = clean_edition_number($input_edition_number);
is($ret, 2, "Edition number '$input_edition_number' after cleanup.");

# Test.
$input_edition_number = '2. opr. a rozmn. vyd.';
$ret = clean_edition_number($input_edition_number);
is($ret, 2, "Edition number '$input_edition_number' after cleanup.");

# Test.
$input_edition_number = 'Vyd. 1.';
$ret = clean_edition_number($input_edition_number);
is($ret, 1, "Edition number '$input_edition_number' after cleanup.");

# TODO Lidové vydání
