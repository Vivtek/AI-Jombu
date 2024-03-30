#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;

use AI::Jombu;
use AI::Jombu::Letter;

my $jm = AI::Jombu->new ('atob');

isa_ok ($jm, 'AI::Jombu');
isa_ok ($jm, 'AI::TerracedScan');
my $ws = $jm->{workspace};
isa_ok ($ws, 'AI::TerracedScan::Workspace');

is_deeply ([ $ws->list_types() ], ['letter']);
is_deeply ([ sort $ws->list_ids() ], ['0', '1', '2', '3']);

#$jm->run();
# Run 5 steps
$jm->step();
$jm->step();
$jm->step();
$jm->step();
$jm->step();

$jm->step();
$jm->step();
$jm->step();
$jm->step();
$jm->step();

$jm->step();
$jm->step();
$jm->step();
$jm->step();
$jm->step();

$jm->step();
$jm->step();
$jm->step();
$jm->step();
$jm->step();

#diag Dumper ($jm);
diag $jm->iterate_workspace()->select('id', 'type', 'desc')->table->show_decl;
diag $jm->{coderack}->iterate_current()->select('type', 'origin', 'desc', 'posted', 'urgency')->table->show_decl;
diag '';
diag $jm->{coderack}->iterate_enactment()->select('type', 'desc', 'run', 'origin', 'posted', 'urgency', 'outcome', 'rule')->table->show_decl;

done_testing();

