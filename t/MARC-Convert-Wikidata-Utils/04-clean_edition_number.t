use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_edition_number);
use Test::More 'tests' => 10;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

# Test.
my $input_edition_number = '1. vyd.';
my $ret = clean_edition_number($input_edition_number);
is($ret, 1, "Edition number '$input_edition_number' after cleanup.");

# Test.
$input_edition_number = decode_utf8('1. vydání');
$ret = clean_edition_number($input_edition_number);
is($ret, 1, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('První vydání');
$ret = clean_edition_number($input_edition_number);
is($ret, 1, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('Druhé vydání');
$ret = clean_edition_number($input_edition_number);
is($ret, 2, encode_utf8("Edition number '$input_edition_number' after cleanup."));

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

# Test.
$input_edition_number = decode_utf8('Druhé, přepracované a doplněné vydání');
$ret = clean_edition_number($input_edition_number);
is($ret, 2, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# TODO Lidové vydání
