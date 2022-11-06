use strict;
use warnings;

use Test::More 'tests' => 4;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog;
use Wikibase::Datatype::Query;

# Common.
my $item = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;

# Test.
my $obj = Wikibase::Datatype::Query->new;
my $ret = $obj->query_item($item, 'label:en');
is($ret, 'dog', 'Get English label (dog).');

# Test.
$obj = Wikibase::Datatype::Query->new;
my @ret = $obj->query_item($item, 'label');
is_deeply(\@ret, ['dog', 'pes'], 'Get all P31 values ([dog, pes]).');

# Test.
$obj = Wikibase::Datatype::Query->new;
$ret = $obj->query_item($item, 'label');
is($ret, 'dog', 'Get first P31 value (dog).');
