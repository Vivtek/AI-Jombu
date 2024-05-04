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
   "a-initial"     => "wow",
   "a-middle"      => "wow",
   "a-final"       => "wow",
   "a"             => "wow",
   
   "ai-initial"    => "meh",
   "ai-middle"     => "good",
   "ai"            => "good",
   
   "au-middle"     => "meh",
   "au"            => "good",
   
   "ay-middle"     => "meh",
   "ay-final"      => "good",
   "ay"            => "good",
   
   "b-initial"     => "wow",
   "b"             => "wow",
   
   "bl-initial"    => "ok",
   "bl"            => "ok",
   
   "ble-final"     => "ok", # Added manually 2024-05-02
   "ble"           => "ok",

   "br-initial"    => "ok", # Added manually 2024-05-02
   "br"            => "ok",
  
   "c-initial"     => "strong",
   "c-final"       => "ok",
   "c"             => "strong",
   
   "ce-final"      => "meh",
   "ce"            => "meh",
   
   "ch-initial"    => "wow", # Added manually 2024-05-02
   "ch-final"      => "good",
   "ch"            => "wow",
   
   "ck-final"      => "ok",
   "ck"            => "ok",
   
   "d-initial"     => "strong",
   "d-final"       => "strong",
   "d"             => "d",
   
   "dd-final"      => "meh",
   "dd"            => "meh",
   
   "de-final"      => "ok",
   "de"            => "ok",
   
   "e-initial"     => "wow",
   "e-middle"      => "wow",
   "e-final"       => "wow",
   "e"             => "wow",

   "ea-initial"    => "good",
   "ea-middle"     => "good",
   "ea"            => "good",
   
   "ee-middle"     => "good",
   "ee-final"      => "ok",
   "ee"            => "good",
   
   "ei-middle"     => "ok",
   "ei"            => "ok",
   
   "eo-final"      => "ok",
   "eo"            => "ok",
   
   "ey-final"      => "good",
   "ey"            => "ok",
   
   "f-initial"     => "strong",
   "f-final"       => "wow",
   "f"             => "wow",
   
   "ff-final"      => "meh",
   "ff"            => "meh",
   
   "fr-initial"    => "good",
   "fr"            => "good",
   
   "g-initial"     => "strong",
   "g-final"       => "meh",
   "g"             => "strong",
   
   "gh-final"      => "ok",
   "gh"            => "ok",
   
   "ght-final"     => "ok",
   "ght"           => "ok",
   
   "gr-initial"    => "meh",
   "gr"            => "meh",
   
   "h-initial"     => "wow",
   "h"             => "wow",
   
   "i-initial"     => "wow",
   "i-middle"      => "wow",
   "i-final"       => "strong",
   "i"             => "wow",
   
   "ie-final"      => "ok",
   "ie"            => "ok",
   
   "io-middle"     => "good",
   "io"            => "good",
   
   "j-initial"     => "ok",
   "j"             => "ok",
   
   "k-final"       => "ok",
   "k"             => "ok",
   
   "ke-final"      => "good",
   "ke"            => "good",
   
   "kn-initial"    => "meh",
   "kn"            => "meh",
   
   "l-initial"     => "wow",
   "l-final"       => "strong",
   "l"             => "wow",
   
   "ld-final"      => "good",
   "ld"            => "good",
   
   "lf-final"      => "meh",
   "lf"            => "meh",
   
   "ll-final"      => "strong",
   "ll"            => "strong",
   
   "lp-final"      => "meh",
   "lp"            => "meh",

   "m-initial"     => "wow",
   "m-final"       => "strong",
   "m"             => "wow",
   
   "me-final"      => "strong",
   "me"            => "strong",
   
   "n-initial"     => "strong",
   "n-final"       => "wow",
   "n"             => "wow",
   
   "nce-final"     => "meh",
   "nce"           => "meh",

   "nd-final"      => "wow",
   "nd"            => "wow",

   "ne-final"      => "good",
   "ne"            => "good",

   "ng-final"      => "strong",
   "ng"            => "strong",

   "ngs-final"     => "meh",
   "ngs"           => "meh",
   
   "nk-final"      => "meh",
   "nk"            => "meh",

   "ns-final"      => "ok",
   "ns"            => "ok",

   "nt-final"      => "good",
   "nt"            => "good",
   
   "o-initial"     => "wow",
   "o-middle"      => "wow",
   "o-final"       => "wow",
   "o"             => "wow",
   
   "oa-middle"     => "wow", # added manually 2024-04-01
   "oa"            => "wow",
   
   "oe-middle"     => "meh",
   "oe"            => "meh",
   
   "oo-middle"     => "good",
   "oo-final"      => "meh",
   "oo"            => "good",
   
   "ou-initial"    => "good",
   "ou-middle"     => "strong",
   "ou"            => "strong",
   
   "p-initial"     => "strong",
   "p-final"       => "good",
   "p"             => "strong",
   
   "pl-initial"    => "good",
   "pl"            => "good",
   
   "pr-initial"    => "ok",
   "pr"            => "ok",
   
   "r-initial"     => "strong",
   "r-final"       => "wow",
   "r"             => "wow",
   
   "rd-final"      => "ok",
   "rd"            => "ok",

   "rds-final"     => "ok",
   "rds"           => "ok",

   "re-final"      => "strong",
   "re"            => "strong",

   "rk-final"      => "meh",
   "rk"            => "meh",

   "rld-final"     => "meh",
   "rld"           => "meh",

   "rm-final"      => "meh",
   "rm"            => "meh",

   "rn-final"      => "meh",
   "rn"            => "meh",

   "rs-final"      => "good",
   "rs"            => "good",

   "rst-final"     => "ok",
   "rst"           => "ok",

   "rt-final"      => "meh",
   "rt"            => "meh",

   "rth-final"     => "meh",
   "rth"           => "meh",

   "s-initial"     => "strong",
   "s-final"       => "wow",
   "s"             => "wow",

   "se-final"      => "good",
   "se"            => "good",

   "sh-initial"    => "good",
   "sh"            => "good",

   "sm-initial"    => "meh",
   "sm"            => "meh",

   "st-initial"    => "ok",
   "st-final"      => "good",
   "st"            => "good",

   "t-initial"     => "wow",
   "t-final"       => "wow",
   "t"             => "wow",

   "te-final"      => "ok",
   "te-final"      => "ok",
   "te"            => "ok",

   "th-initial"    => "wow",
   "th-final"      => "strong",
   "th"            => "wow",

   "thr-initial"   => "ok",
   "thr"           => "ok",

   "tr-initial"    => "meh",
   "tr"            => "meh",

   "ts-final"      => "ok",
   "ts"            => "ok",

   "tw-initial"    => "ok",
   "tw"            => "ok",

   "u-initial"     => "strong",
   "u-middle"      => "strong",
   "u-final"       => "good",
   "u"             => "strong",

   "v-initial"     => "good",
   "v-final"       => "ok",
   "v"             => "good",

   "ve-final"      => "good",
   "ve"            => "good",

   "w-initial"     => "wow",
   "w-final"       => "strong",
   "w"             => "wow",

   "wh-initial"    => "strong",
   "wh"            => "strong",

   "wn-final"      => "ok",
   "wn"            => "ok",

   "wr-initial"    => "ok",
   "wr"            => "ok",
   
   "x-final"       => "good",
   "x"             => "good",

   "y-initial"     => "strong",
   "y-final"       => "wow",
   "y"             => "wow",
   
   "yea-initial"   => "meh",
   "yea"           => "meh",
   
 # "you-final"     => "strong",
   "you-initial"   => "strong",
   "you"           => "strong",
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
   
   # We could speed this up by precalculating these and just putting them in the chunkabet (2024-05-02 - which I've just done)
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
