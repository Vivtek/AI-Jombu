package AI::Jombu;

use 5.006;
use strict;
use warnings;

use parent qw(AI::TerracedScan);

use AI::Jombu::Scene;
use AI::Jombu::Chunkabet;

use Data::Dumper;

#use AI::Jombu::Letter;
#use AI::Jombu::Spark;
#use AI::Jombu::Bond;
#use AI::Jombu::Glom;

use Path::Tiny;

=head1 NAME

AI::Jombu - Jombu is not Jumbo

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Jombu is the first microdomain I'm implementing as part of L<AI::TerracedScan>. To implement a domain, you subclass AI::TerracedScan to add
appropriate semunit types (and their codelets) and other optional things like a more domain-specific problem instance parser.

=head1 SUBROUTINES/METHODS

=head2 new (initial string, parameters)

Jombu is called with a string containing the initial jumble, and an optional hashref of parameters.

=cut

sub new {
   my ($class, $init, $parameters) = @_;
   my $self = bless ({}, $class);
   $self->_init_({musing => { letter => [['letter-spark',        1, 100]],
                              bond   => [['bond-chain-spark',    1, 20],
                                         ['bond-glom-scout',     1, 50]],
                              glom   => [['glom-syllable-scout', 1, 20],
                                         ['glom-shuffle-scout',  1, 20]],
                            },
                  codelets => { 'letter-spark'        => ['letter', \&letter_spark],
                                'letter-glom-scout'   => ['letter', \&letter_glom_scout],
                                'spark-checker'       => ['spark',  \&spark_checker],
                                'bond-chain-spark'    => ['bond',   \&bond_chain_spark],
                                'bond-glom-scout'     => ['bond',   \&bond_glom_scout],
                                'glom-syllable-scout' => ['glom',   \&glom_syllable_scout],
                                'glom-shuffle-scout'  => ['glom',   \&glom_shuffle_scout],
                              },
                  init => $init,
                  parameters => $parameters,
                 });
    $self;
}

=head2 parse_setup (string)

Jombu has a much easier initial setup structure, so we can save a lot of time by having a parser to split the letters out into unit specs.

=cut

sub parse_setup {
   my $self = shift;
   my $units = [];
   foreach (split //, $_[0]) {
      push @$units, ['letter', undef, $_, undef, $_];
   }
   return Iterator::Records->new ($units, ['type', 'id', 'data', 'frame', 'desc']);
}

=head2 setup_display (directory)

If we're going to make use of the display animation scene, which outputs Pikchr, then it needs to be initialized before the run starts.
This basically consists of specifying a directory where the SVG for each scene will be written.

=cut

sub setup_display {
   my ($self, $directory) = @_;
   $self->{scene} = AI::Jombu::Scene->new($self);
   $self->{scene}->jombu_initialize (path ($directory));
   $self->{scene}->add_label (2, 0, sub { sprintf ('codelets: %d, %0.3fs, %0.3fcps', $self->ticks(), $self->time(), $self->cps()); });

}

=head1 STRUCTURAL QUERIES

I have a sneaking suspicion that this aspect of semantic units - defining actual semantic queries - is going to be important, so I'm highlighting this with
a header-1 section. My intuition is that this kind of thing should be generalized and migrate into the Workspace object. The bonds query is probably a form
of neighborhood, or operates on the neighborhood, or something.

=head2 bonded()

Asks the letter about its bonding environment. The response is an arrayref consisting of a string response and zero, one, or two bonds, as follows:

=over

=item no

=item single-in = single bond, incoming (this letter is the "to" in the bond), with the bond

=item single-out = single bond, outgoing (this letter is the "from" in the bond), with the bond

=item chain-in = single bond, incoming, but the end of a chain, with two bonds: first the near one, then the far one

=item chain-out = single bond, outgoing, but the start of a chain, with two bonds: first the near one, then the far one

=item chain-middle = doubly bonded letter (this letter is bonded to two other letters in a chain), with two bonds: first the incoming, then the outgoing

=back

=cut

sub bonds {
   my ($letter) = @_;
   grep { $_->get_type() eq 'bond' } $letter->list_in();
}
sub bonded {
   my ($letter) = @_;
   #return ['no'] unless defined $letter;
   
   my @bonds = bonds($letter);
   return ['no'] unless @bonds;
   
   if (scalar @bonds == 2) {
      if ($bonds[0]->{frame}->{to} == $letter) {
         return ['chain-middle', $bonds[0], $bonds[1] ];
      } else {
         return ['chain-middle', $bonds[1], $bonds[0] ];
      }
   }
   
   if ($bonds[0]->{frame}->{to} == $letter) {
      my @other_bonds = bonds($bonds[0]->{frame}->{from});
      return ['single-in', $bonds[0] ] if scalar @other_bonds == 1;
      return ['chain-in',  $bonds[0], $other_bonds[0] == $bonds[0] ? $other_bonds[1] : $other_bonds[0] ];
   } else {
      my @other_bonds = bonds($bonds[0]->{frame}->{to});
      return ['single-out', $bonds[0] ] if scalar @other_bonds == 1;
      return ['chain-out',  $bonds[0], $other_bonds[0] == $bonds[0] ? $other_bonds[1] : $other_bonds[0] ];
   }
   
   die 'something is screwed up with bonds';
}


=head1 CODELET HANDLERS

This is where the actual domain is defined.

=head2 letter_spark, letter_glom_scout

The codelets for semunits of type 'letter'.

=cut

sub letter_spark {
   my ($ts, $cr) = @_;
   my $ws = $ts->{workspace};
   
   my @units = $ws->choose_units ('letter', 2);
   
   $cr->{desc} = $units[0]->[2]->describe . '-' . $units[1]->[2]->describe;
   my ($let1, $let2) =  map { $_->[2]->get_id() } @units;
   
   my %mutual = map { ($_, 1) } $ws->container_types ($let1, $let2);
   my %either;
   foreach my $t ($ws->container_types ($let1)) {
      $either{$t} = 1;
   }
   foreach my $t ($ws->container_types ($let2)) {
      $either{$t} = 1;
   }

   return $cr->fizzle ('mutual spark') if $mutual{spark};
   return $cr->fail   ('either spark') if $either{spark} && $ts->decide_failure (10);
   
   return $cr->fizzle ('mutual bond')  if $mutual{bond};
   return $cr->fail   ('either bond')  if $either{bond}  && $ts->decide_failure (50);

   return $cr->fizzle ('mutual glom')  if $mutual{glom};
   return $cr->fail   ('either glom')  if $either{glom}  && $ts->decide_failure (90);
   
   my $spark = $ws->add_link ('spark', $cr->{desc}, {from=>$let1, to=>$let2});
   $spark->describe ($cr->{desc});
   $ts->post_codelet ('spark-checker', $cr, { spark => $spark }, { urgency=>'normal' });
   return $cr->fire ('added spark ' . $spark->get_id());
}

sub letter_glom_scout {
   my ($ts, $cr) = @_;
   
   my $ws = $ts->{workspace};
   my @units = $ws->choose_units ('letter', 1); # -- weight this by frustration, with a floor under which the letter won't be chosen
   return $cr->fail   ('temp fail')
}

=head2 spark_checker

The only codelet specific to sparks.

=cut

sub spark_checker {
   my ($ts, $cr) = @_;
   my $ws = $ts->{workspace};
   
   my $spark = $cr->{frame}->{spark};
   if (not defined $spark or not defined $spark->{frame}->{from} or not defined $spark->{frame}->{to}) {
      #$ws->kill_unit ($spark->get_id);
      print "corrupt\n";
      return $cr->fail ('corrupt spark');
   }
   my ($from_bonded, @from_bonds) = @{ AI::Jombu::bonded ($spark->{frame}->{from}) };
   my ($to_bonded,   @to_bonds)   = @{ AI::Jombu::bonded ($spark->{frame}->{to}) };
   
   # What proposed bond are we testing?
   my $proposal;
   my @bonds_for_dissolution = ();
   if (($from_bonded eq 'no'         and $to_bonded eq 'single-out') or
       ($from_bonded eq 'single-in'  and $to_bonded eq 'no')) {  # The only two cases in which we propose a triple-letter chunk consisting of a two-bond chain [sgl]
      $proposal = $to_bonded eq 'single-out' ? $spark->{frame}->{from}->describe . $to_bonds[0]->describe            :
                                               $from_bonds[0]->describe          . $spark->{frame}->{to}->describe;  # [3lc]
      # And no bonds will be dissolved in this case
   } else {
      $proposal = $spark->{frame}->{from}->describe . $spark->{frame}->{to}->describe;
      @bonds_for_dissolution = (@from_bonds, @to_bonds); # All existing bonds will be dissolved in all other cases (including the degenerate case of two free letters)
   }
   $proposal =~ s/-//g; # Remove any extraneous dashes from the bond name
   
   my $felicity = AI::Jombu::Chunkabet::chunk_felicity ($proposal);
   #print STDERR "felicity of $proposal is $felicity";

   # If our proposed bond is barred ('no') then let's just quit now while we're ahead   
   if ($felicity eq 'no') {
      $ws->kill_unit ($spark->get_id);
      return $cr->fail ("bad chunk '$proposal'");
   }
   
   # If it's not immediately terrible, let's compare it to what would be dissolved, and probabilistically decide whether to proceed.
   my @to_beat = map { $_->{chunk} } @bonds_for_dissolution;
   my $stronger = 1;
   foreach my $existing (@to_beat) {
      if (not AI::Jombu::Chunkabet::chunk_beats ($felicity, AI::Jombu::Chunkabet::chunk_felicity($existing))) {
         $stronger = 0;
         last;
      }
   }
   if ($stronger) { # There should probably be a stochastic element to this decision but I'm not sure how to bias it
      # Reset all letters in bonds to be dissolved to null chunk, null felicity
      # Reset all bonds to be dissolved to null chunk, null felicity
      # Kill all bonds to be dissolved
      foreach my $bond (@bonds_for_dissolution) {
         $bond->{frame}->{from}->{chunk} = undef;
         $bond->{frame}->{from}->{chunk_quality} = undef;
         $bond->{frame}->{to}->{chunk} = undef;
         $bond->{frame}->{to}->{chunk_quality} = undef;
         
         $bond->{chunk} = undef;
         $bond->{chunk_quality} = undef;
         
         $ws->kill_unit ($bond->get_id);
      }
      
      # Set chunk and felicity in letters being bonded and in spark, as well as far bond and letter if we're extending a chain
      foreach my $unit ($spark, @from_bonds, @to_bonds) {
         $unit->{frame}->{from}->{chunk} = $proposal;
         $unit->{frame}->{from}->{chunk_quality} = $felicity;
         $unit->{frame}->{to}->{chunk} = $proposal;
         $unit->{frame}->{to}->{chunk_quality} = $felicity;
         
         $unit->{chunk} = $proposal;
         $unit->{chunk_quality} = $felicity;
      }
      
      # Promote spark to bond
      $ws->promote_unit ($spark->get_id, 'bond');
      return $cr->fire ("chunk '$proposal' ($felicity) bonded");
   } else {
      $ws->kill_unit ($spark->get_id);
      return $cr->fail ("chunk '$proposal' ($felicity) did not beat " . join (', ', @to_beat));
   }
}

=head2 bond_chain_spark, bond_glom_scout

Bond-specific codelets.

The C<bond-chain-spark> codelet is a type scout, meaning that it is unbound and has no posting parent.

When called, C<bond-chain-spark> first selects a random bond, and tries to extend it either forwards or backwards. If the bond is already in a chain, we'll fizzle.
To extend the bond in the forward direction, the "to" letter is sparked with a randomly selected letter that is not either the "from" or the "to" letter. To extend in the
backward direction, a randomly selected letter is sparked with the "from" letter.

The resulting spark unit is identical to one created by C<letter-spark>.

When called, C<bond-glom-scout> first selects a random bond and asks the Workspace for its bond-group neighborhood. It fizzles if there are no bonds to be found.
If it does find a bond neighborhood, it builds the chunk, asks the Chunkabet whether it's a vowel chunk or not, dissolves the bonds, promotes the letters to
glommed-letters, and creates the glom object.


=cut

sub bond_chain_spark {
   my ($ts, $cr) = @_;
   my $ws = $ts->{workspace};
   return $cr->fizzle ('temporary fizzle');
   
   my ($bond) = map { $_->[2] } $ws->choose_units ('bond', 1);
   return $cr->fizzle ('already double bond') if length($bond->{chunk}) > 2;

   my $from = $bond->get('from')->get_id();
   my $to   = $bond->get('to'  )->get_id();
   
   # Pick a letter from the workspace to spark with.
   my ($letter) = map { $_->[2]->get_id() } $ws->choose_units ('letter', 1);
   return $cr->fizzle ("target already in our bond (3)") if $from eq $letter or $to eq $letter;
   foreach my $t ($ws->container_types ($letter, $from)) {
      return $cr->fizzle ("target already in our bond group (1)") if $t eq 'bond';
   }
   foreach my $t ($ws->container_types ($letter, $to)) {
      return $cr->fizzle ("target already in our bond group (2)") if $t eq 'bond';
   }
   foreach my $t ($ws->container_types ($letter)) {
      return $cr->fail ("target already sparking") if $t eq 'spark' && $ts->decide_failure (10);
      return $cr->fail ("target already bonded")   if $t eq 'bond'  && $ts->decide_failure (90);  # The point is not to grab letters out of other bonds
   }
   
   # Pick the from or the to letter to spark with something else.
   my $spark;
   if ($ts->decide_yesno (50)) {
      $spark = $ws->add_link ('spark', undef, {from=>$to, to=>$letter});
   } else {
      $spark = $ws->add_link ('spark', undef, {from=>$letter, to=>$from});
   }
   $ts->post_codelet ('spark-checker', $cr, $spark);
   return $cr->fire ('added spark ' . $spark->get_id());
}

sub bond_glom_scout {
   my ($ts, $cr) = @_;
   my $ws = $ts->{workspace};
   
   my ($bond) = $ws->choose_units_ids ('bond', 1);
   return $cr->fizzle ('no bonds available') if not defined $bond;
   
   my $nhd = $ws->get_neighborhood ($bond, 'letter', 'bond');
   return $cr->fail ('temp fail');

   #return $cr->fire ('added spark ' . $spark->get_id());
}

=head2 glom_syllable_scout, glom_shuffle_scout

Glom-specific codelets

=cut

sub glom_syllable_scout {
   my ($ts, $cr) = @_;
   
   my $ws = $ts->{workspace};
   my $glom = $cr->{frame}->{glom};
   #$ws->kill_unit ($spark->get_id);
   
   $cr->fail ('temp fail #' . $glom->get_id());
}

sub handle_glom_shuffle_scout {
   my ($ts, $cr) = @_;
   
   my $ws = $ts->{workspace};
   my $glom = $cr->{frame}->{glom};
   #$ws->kill_unit ($spark->get_id);
   
   $cr->fail ('temp fail #' . $glom->get_id());
}


=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ai-jombu at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=AI-Jombu>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AI::Jombu


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

1; # End of AI::Jombu
