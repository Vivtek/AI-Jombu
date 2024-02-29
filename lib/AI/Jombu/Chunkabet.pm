package AI::Jombu::Chunkabet;

use 5.006;
use strict;
use warnings;
use Exporter qw(import);
our @EXPORT = qw(chunk_felicity chunk_beats chunk_vowel);

=head1 NAME

AI::Jombu::Chunkabet - Exposes an API for our chunkabet (a list of how much we like or dislike different letter clusters)

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

our %chunkabet = (
   "a-final"       => "wow",
   "a-initial"     => "wow",
   "a-middle"      => "wow",
   "ai-initial"    => "meh",
   "ai-middle"     => "good",
   "au-middle"     => "meh",
   "ay-final"      => "good",
   "ay-middle"     => "meh",
   "b-initial"     => "wow",
   "bl-initial"    => "ok",
   "c-final"       => "ok",
   "c-initial"     => "strong",
   "ce-final"      => "meh",
   "ch-final"      => "good",
   "ck-final"      => "ok",
   "d-final"       => "strong",
   "d-initial"     => "strong",
   "dd-final"      => "meh",
   "de-final"      => "ok",
   "e-final"       => "wow",
   "e-initial"     => "wow",
   "e-middle"      => "wow",
   "ea-initial"    => "good",
   "ea-middle"     => "good",
   "ee-final"      => "ok",
   "ee-middle"     => "good",
   "ei-middle"     => "ok",
   "eo-final"      => "ok",
   "ey-final"      => "good",
   "f-final"       => "wow",
   "f-initial"     => "strong",
   "ff-final"      => "meh",
   "fr-initial"    => "good",
   "g-final"       => "meh",
   "g-initial"     => "strong",
   "gh-final"      => "ok",
   "ght-final"     => "ok",
   "gr-initial"    => "meh",
   "h-initial"     => "wow",
   "i-final"       => "strong",
   "i-initial"     => "wow",
   "i-middle"      => "wow",
   "ie-final"      => "ok",
   "io-middle"     => "good",
   "j-initial"     => "ok",
   "k-final"       => "ok",
   "ke-final"      => "good",
   "kn-initial"    => "meh",
   "l-final"       => "strong",
   "l-initial"     => "wow",
   "ld-final"      => "good",
   "lf-final"      => "meh",
   "ll-final"      => "strong",
   "lp-final"      => "meh",
   "m-final"       => "strong",
   "m-initial"     => "wow",
   "me-final"      => "strong",
   "n-final"       => "wow",
   "n-initial"     => "strong",
   "nce-final"     => "meh",
   "nd-final"      => "wow",
   "ne-final"      => "good",
   "ng-final"      => "strong",
   "ngs-final"     => "meh",
   "nk-final"      => "meh",
   "ns-final"      => "ok",
   "nt-final"      => "good",
   "o-final"       => "wow",
   "o-initial"     => "wow",
   "o-middle"      => "wow",
   "oe-middle"     => "meh",
   "oo-final"      => "meh",
   "oo-middle"     => "good",
   "ou-initial"    => "good",
   "ou-middle"     => "strong",
   "p-final"       => "good",
   "p-initial"     => "strong",
   "pl-initial"    => "good",
   "pr-initial"    => "ok",
   "r-final"       => "wow",
   "r-initial"     => "strong",
   "rd-final"      => "ok",
   "rds-final"     => "ok",
   "re-final"      => "strong",
   "rk-final"      => "meh",
   "rld-final"     => "meh",
   "rm-final"      => "meh",
   "rn-final"      => "meh",
   "rs-final"      => "good",
   "rst-final"     => "ok",
   "rt-final"      => "meh",
   "rth-final"     => "meh",
   "s-final"       => "wow",
   "s-initial"     => "strong",
   "se-final"      => "good",
   "sh-initial"    => "good",
   "sm-initial"    => "meh",
   "st-final"      => "good",
   "st-initial"    => "ok",
   "t-final"       => "wow",
   "t-initial"     => "wow",
   "te-final"      => "ok",
   "th-final"      => "strong",
   "th-initial"    => "wow",
   "thr-initial"   => "ok",
   "tr-initial"    => "meh",
   "ts-final"      => "ok",
   "tw-initial"    => "ok",
   "u-final"       => "good",
   "u-initial"     => "strong",
   "u-middle"      => "strong",
   "v-final"       => "ok",
   "v-initial"     => "good",
   "ve-final"      => "good",
   "w-final"       => "strong",
   "w-initial"     => "wow",
   "wh-initial"    => "strong",
   "wn-final"      => "ok",
   "wr-initial"    => "ok",
   "x-final"       => "good",
   "y-final"       => "wow",
   "y-initial"     => "strong",
   "yea-initial"   => "meh",
 # "you-final"     => "strong",
   "you-initial"   => "strong",
);


=head1 SYNOPSIS


=head1 EXPORTED FUNCTIONS

=head2 chunk_felicity (string, [position])

Given a string and optional position (initial, middle, or final) retrieves the felicity of that combination from the chunkabet. If the position is omitted, the
most felicitous position will be returned: "w-initial" is wow and "w-final" is strong, so the felicity of "w" as a cluster is wow.

=cut

sub chunk_felicity {
   my ($chunk, $pos) = @_;
   if (defined $pos) {
      my $s = $chunkabet{"$chunk-$pos"};
      return $s if defined $s;
      return 'no';
   }
   
   # We could speed this up by precalculating these and just putting them in the chunkabet
   my $s = 'no';
   foreach my $alt (chunk_felicity ($chunk, 'initial'), chunk_felicity ($chunk, 'middle'), chunk_felicity ($chunk, 'final')) {
      $s = $alt if chunk_beats ($alt, $s);
   }
   return $s;
}

=head2 chunk_beats (a, b)

True if C<a> beats C<b>. Later, we might want to do some kind of fuzzy ordering here, based on temperature. But for now, we're playing it straight.

=cut

sub chunk_beats {
   my ($a, $b) = @_;
   return 0 if $a eq $b;     # A fails a challenge to B if they're equal
   
   return 1 if $a eq 'wow';
   return 0 if $b eq 'wow';
   return 1 if $a eq 'strong';
   return 0 if $b eq 'strong';
   return 1 if $a eq 'good';
   return 0 if $b eq 'good';
   return 1 if $a eq 'ok';
   return 0 if $b eq 'ok';
   return 1 if $a eq 'meh';
   return 0;
}

=head2 chunk_vowel (chunk)

Returns 1 if the chunk is a vowel cluster, 0 otherwise. (Note that e.g. "ble" is a consonant cluster despite the presence of 'e'.)

=cut

sub chunk_vowel {
   return 1 if $_[0] =~ /[aeiou]+w/;  # Special case for vowel(s)+w
   return 0 if $_[0] =~ /[^aeiouy]/;
   return 1;
}


=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ai-jombu at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=AI-Jombu>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AI::Jombu::Chunkabet


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=AI-Jombu>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/AI-Jombu>

=item * Search CPAN

L<https://metacpan.org/release/AI-Jombu>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Michael Roberts.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of AI::Jombu::Chunkabet
