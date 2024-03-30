package AI::Jombu::Letter;

use 5.006;
use strict;
use warnings;

use parent qw(AI::TerracedScan::Type);
use AI::TerracedScan::Codelet;
use Carp;


=head1 NAME

AI::Jombu::Letter - The 'letter' semantic unit type, and the codelets that work with it

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

# Values for "letter"
our $name = 'letter';
our @codelets = qw( letter-spark );
sub name { return $name; }
sub codelets { return @codelets; }


=head1 SCOUTING

Each semunit type class is asked periodically to propose some scout codelets. This is a judgment made on the basis of the current state of the Workspace and Coderack,
but how it's done is left entirely up to the type. We'll probably end up with some stock strategies that types can use; for now I don't know enough to propose any.
If the type has no scouts to propose, leave this out; the superclass's method just returns an empty list.

=head2 propose_scouts (scan)

=cut

sub propose_scouts {
   my ($class, $ts) = @_;
   post ($ts, 'letter-spark');
}

=head1 CODELETS

The method name of each codelet handler is just the name of the codelet. Recall that the active codelet itself is an entry in the Coderack action table.
The codelet handler is given a link to the codelet action record and the current Workspace, and can:
- fizzle if it's no longer a valid action
- make changes to the Workspace, usually by adding a unit or changing the type of an existing unit

=head2 post (scan, codelet-type, [parms])

Given the (string) name of a codelet and an optional list of codelet parameters, post a codelet of that name to the Coderack. This is type-specific.

=cut

sub post {
   my $ts = shift;
   my $cn = shift;
   if ($cn eq 'letter-spark') {
      post_letter_spark ($ts, @_);
   } else {
      croak "unknown codelet type $cn [type 'letter']";
   }
}

=head2 letter-spark: post_letter_spark ( scan ), handle_letter_spark (scan, codelet-record)

When called, C<letter-spark> chooses two letters at random, checks them for enclosure (which could be grounds for failure), and if it seems kosher, proposes a bond.
The bond proposal unit is called a "spark". Then we also post a new codelet, a "spark-checker" bound to the spark unit.

The codelet has no parameters.

=cut

sub post_letter_spark {
   my $ts = shift;
   AI::TerracedScan::Codelet->post_new ($ts, {
      type => 'letter',
      name => 'letter-spark',
      callback => sub { my $cr = shift; return sub { handle_letter_spark ( $ts, $cr ); }; },
   });
}
sub handle_letter_spark {
   my ($ts, $cr) = @_;
   
   my $ws = $ts->{workspace};
   my @units = $ws->choose_units ('letter', 2);
   
   $cr->{desc} = $ts->describe_unit ($units[0]->[2]) . '-' . $ts->describe_unit ($units[1]->[2]);
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
   
   my $spark = $ws->add_link ('spark', {from=>$let1, to=>$let2});
   $ts->post_codelet ('spark-checker', $cr, $spark);
   return $cr->fire ('added spark ' . $spark->get_id());
}

=head2 describe_unit (unit)

Provides a brief descriptive string for a letter unit.

=cut

sub describe_unit {
   my ($self, $unit) = @_;
   return $unit->{data} if defined $unit;
   return $self->{data};
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
