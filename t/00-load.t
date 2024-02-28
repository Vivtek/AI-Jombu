#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    #use_ok( 'AI::Jombu' ) || print "Bail out!\n";
    use_ok( 'AI::Jombu::Chunkabet' ) || print "Bail out!\n";
}

diag( "Testing AI::Jombu $AI::Jombu::VERSION, Perl $], $^X" );
