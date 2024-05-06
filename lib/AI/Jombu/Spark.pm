package AI::Jombu::Spark;

use 5.006;
use strict;
use warnings;

use parent qw(AI::TerracedScan::Type);
use AI::TerracedScan::Codelet;
use AI::Jombu::Letter;
use AI::Jombu::Chunkabet;
use Carp;
use Data::Dumper;


=head1 NAME

AI::Jombu::Spark - The 'spark' semantic unit type, and the codelets that work with it

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

# Values for "spark"
our $name = 'spark';
our @codelets = qw( spark-checker );
sub name { return $name; }
sub codelets { return @codelets; }

=head1 SCOUTING

Sparks do not scout; the only codelet pertaining to sparks is bound to a specific spark.

=head1 CODELETS

The method name of each codelet handler is just the name of the codelet. Recall that the active codelet itself is an entry in the Coderack action table.
The codelet handler is given a link to the codelet action record and the current Workspace, and can:
- fizzle if it's no longer a valid action
- make changes to the Workspace, usually by adding a unit or changing the type of an existing unit

=head2 post (scan, codelet-type, [parms])

Given the (string) name of a codelet and an optional list of codelet parameters, post a codelet of that name to the Coderack. This is type-specific.

=cut

sub post {
   my $class = shift;
   my $ts = shift;
   my $cn = shift;
   if ($cn eq 'spark-checker') {
      post_spark_checker ($ts, @_);
   } else {
      croak "unknown codelet type $cn [type 'spark']";
   }
}

=head2 spark-checker: post_spark_checker ( scan ), handle_spark_checker (scan, codelet-record)

The C<spark-checker> codelet's single parameter is the spark it's bound to, and its origin is the scout that created it along with its spark.

When called, it examines the spark it's bound to, and asks the chunkabet how good a bond the letter pair might be. If the pair isn't a valid bond
at all, the codelet fails. Otherwise, what happens depends on the bonding status of the letters it pairs:

- If both unbonded, it simply promotes the spark to a bond
- If it extends from a singly bonded letter to an unbonded letter in the same direction as the bond, it promotes the spark to a bond, extending the bond chain
- If it extends from an unbonded letter to a singly bonded letter, again in the same direction as the bond, it promotes the spark and extends the bond chain
- If both letters are bonded, either is doubly bonded, or if the spark and existing single bond are in incompatible directions, it will roll the dice to see if
  it will dissolve all the existing incompatible bonds and promote its spark to bond status. This dice roll's canonical probability depends on relative bond quality
  and, like all the random distributions, it is skewed by the global temperature. If the die roll fails, the spark is killed and the existing bonds left intact.

=cut

sub post_spark_checker {
   my $ts = shift;
   my $desc = shift;
   my $spark = shift;
   my $parent;
   if (ref $desc) {
      $parent = $desc;
      $desc = $parent->{desc};
   }
   AI::TerracedScan::Codelet->post_new ($ts, {
      type => 'spark',
      name => 'spark-checker',
      desc => defined $desc ? $desc : '',
      origin => defined $parent ? $parent->{origin} : '',
      urgency => 'normal',
      frame => { spark => $spark },
      callback => sub { my $cr = shift; return sub { handle_spark_checker ( $ts, $cr ); }; },
   });
}
sub handle_spark_checker {
   my ($ts, $cr) = @_;
   
   my $ws = $ts->{workspace};
   my $spark = $cr->{frame}->{spark};
   my ($from_bonded, @from_bonds) = @{ AI::Jombu::Letter::bonded ($spark->{frame}->{from}) };
   my ($to_bonded,   @to_bonds)   = @{ AI::Jombu::Letter::bonded ($spark->{frame}->{to}) };
   
   # What proposed bond are we testing?
   my $proposal;
   my @bonds_for_dissolution = ();
   if (($from_bonded eq 'no'         and $to_bonded eq 'single-out') or
       ($from_bonded eq 'single-in'  and $to_bonded eq 'no')) {  # The only two cases in which we propose a triple-letter chunk consisting of a two-bond chain [sgl]
      $proposal = $to_bonded eq 'single-out' ? $ts->describe_unit($spark->{frame}->{from}) . $ts->describe_unit($to_bonds[0])            :
                                               $ts->describe_unit($from_bonds[0])           . $ts->describe_unit($spark->{frame}->{to});  # [3lc]
      # And no bonds will be dissolved in this case
   } else {
      $proposal = $ts->describe_unit($spark->{frame}->{from}) . $ts->describe_unit($spark->{frame}->{to});
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

=head2 describe_unit (unit)

Provides a brief descriptive string for a spark unit.

=cut

sub describe_unit {
   my ($self, $unit, $scan) = @_;
   
   return $scan->describe_unit ($unit->{frame}->{from}) . '-' . $scan->describe_unit ($unit->{frame}->{to});
}


=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ai-jombu at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=AI-Jombu>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AI::Jombu::Letter


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Michael Roberts.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of AI::Jombu::Letter
