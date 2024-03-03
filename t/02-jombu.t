#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use AI::Jombu;
my $jm = AI::Jombu->new ('atob');

isa_ok ($jm, 'AI::Jombu');
isa_ok ($jm, 'AI::TerracedScan');
my $ws = $jm->{workspace};
isa_ok ($ws, 'AI::TerracedScan::Workspace');

is_deeply ([ $ws->list_types() ], ['letter']);
is_deeply ([ sort $ws->list_ids() ], ['0', '1', '2', '3']);

done_testing();

