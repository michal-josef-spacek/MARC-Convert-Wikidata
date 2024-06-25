use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Transform;
use MARC::File::XML;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 8;
use Test::NoWarnings;
use Test::Warn;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

# Data directory.
my $data = File::Object->new->up->dir('data');

# Read marc from file.
my $marc_data = slurp($data->file('cnb001756719.xml')->s);
my $obj = MARC::Convert::Wikidata::Transform->new(
    'marc_record' => MARC::Record->new_from_xml($marc_data, 'UTF-8'),
);
my $ret = $obj->object;
my $author = $ret->authors->[0];
is($author->name, '', 'Učebnice práva ve čtyřech knihách: Get author name.');
is($author->surname, 'Gaius', 'Učebnice práva ve čtyřech knihách: Get author surname.');
is($author->date_of_birth, undef, 'Učebnice práva ve čtyřech knihách: Get author date of birth.');
is($author->date_of_death, undef, 'Učebnice práva ve čtyřech knihách: Get author date of death.');
is($author->work_period_start, 110, 'Učebnice práva ve čtyřech knihách: Get author work period start.');
is($author->work_period_end, 180, 'Učebnice práva ve čtyřech knihách: Get author work period end.');
is($author->nkcr_aut, 'jn19990002527', 'Učebnice práva ve čtyřech knihách: Get author NKČR AUT id.');
