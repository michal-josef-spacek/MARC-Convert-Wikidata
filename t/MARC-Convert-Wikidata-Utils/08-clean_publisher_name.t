use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_publisher_name);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

# Test.
my $input_publisher_name = decode_utf8('Archiv města Brna :');
my $ret = clean_publisher_name($input_publisher_name);
is($ret, decode_utf8('Archiv města Brna'),
	encode_utf8("Publisher name '$input_publisher_name' after cleanup."));

# Test.
$input_publisher_name = decode_utf8('Muzejní a vlastivědná společnost,');
$ret = clean_publisher_name($input_publisher_name);
is($ret, decode_utf8('Muzejní a vlastivědná společnost'),
	encode_utf8("Publisher name '$input_publisher_name' after cleanup."));