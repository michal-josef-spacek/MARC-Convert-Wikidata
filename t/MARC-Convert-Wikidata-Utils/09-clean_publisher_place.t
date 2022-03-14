use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_publisher_place);
use Test::More 'tests' => 7;
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

# Test.
$input_publisher_place = decode_utf8('V Ústí nad Labem');
$ret = clean_publisher_place($input_publisher_place);
is($ret, decode_utf8('Ústí nad Labem'), encode_utf8("Publisher name '$input_publisher_place' after cleanup."));

# Test.
$input_publisher_place = decode_utf8('Plzeň ;');
$ret = clean_publisher_place($input_publisher_place);
is($ret, decode_utf8('Plzeň'), encode_utf8("Publisher name '$input_publisher_place' after cleanup."));

# Test.
$input_publisher_place = decode_utf8('V Pardubicích :');
$ret = clean_publisher_place($input_publisher_place);
is($ret, decode_utf8('Pardubice'), encode_utf8("Publisher name '$input_publisher_place' after cleanup."));
