use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_publisher_place);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

# Test.
my $input_publisher_place = 'V Praze : ';
my $ret = clean_publisher_place($input_publisher_place);
is($ret, 'Praha', "Publisher name '$input_publisher_place' after cleanup.");

# Test.
$input_publisher_place = decode_utf8('V Brně');
$ret = clean_publisher_place($input_publisher_place);
is($ret, 'Brno', encode_utf8("Publisher name '$input_publisher_place' after cleanup."));

# Test.
$input_publisher_place = '[Praha]';
$ret = clean_publisher_place($input_publisher_place);
is($ret, 'Praha', encode_utf8("Publisher name '$input_publisher_place' after cleanup."));
