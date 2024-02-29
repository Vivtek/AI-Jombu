#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use AI::Jombu::Chunkabet;

#plan tests => 2;

ok (chunk_felicity ('a')  eq 'wow');
ok (chunk_felicity ('ai') eq 'good');
ok (chunk_felicity ('ai', 'initial') eq 'meh');
ok (chunk_felicity ('ai', 'final') eq 'no');
ok (chunk_felicity ('bq') eq 'no');

ok (chunk_beats ('wow', 'meh'));
ok (chunk_beats ('meh', 'no'));
ok (not chunk_beats ('wow', 'wow'));
ok (not chunk_beats ('meh', 'wow'));

ok (chunk_vowel ('ow'));
ok (chunk_vowel ('ou'));
ok (not chunk_vowel ('str'));
ok (not chunk_vowel ('ble'));

done_testing();
