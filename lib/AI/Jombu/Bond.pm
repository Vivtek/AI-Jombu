package AI::Jombu::Bond;

use 5.006;
use strict;
use warnings;

use parent qw(AI::TerracedScan::Type);
use AI::TerracedScan::Codelet;
use Carp;
use Data::Dumper;


=head1 NAME

AI::Jombu::Bond - The 'bond' semantic unit type, and the codelets that work with it

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

# Values for "bond"
our $name = 'bond';
our @codelets = qw( bond-chain-spark bond-glom-scout );
sub name { return $name; }
sub codelets { return @codelets; }

=head1 SCOUTING

Bonds try to extend themselves into chains, if there are free letters; this is the alternative pathway to generating sparks.

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
   if ($cn eq 'bond-chain-spark') {
      post_bond_chain_spark ($ts, @_);
   } elsif ($cn eq 'bond-glom-scout') {
      post_bond_glom_scout ($ts, @_);
   } else {
      croak "unknown codelet type $cn [type 'spark']";
   }
}

=head2 bond-chain-spark: post_bond_chain_spark ( scan ), handle_bond_chain_spark (scan, codelet-record)

The C<bond-chain-spark> codelet is a type scout, meaning that it is unbound and has no posting parent.

When called, C<bond-chain-spark> first selects a random bond, and tries to extend it either forwards or backwards. If the bond is already in a chain, we'll fizzle.
To extend the bond in the forward direction, the "to" letter is sparked with a randomly selected letter that is not either the "from" or the "to" letter. To extend in the
backward direction, a randomly selected letter is sparked with the "from" letter.

The resulting spark unit is identical to one created by C<letter-spark>.

=cut

sub post_bond_chain_spark {
   my $ts = shift;
   my $desc = shift;
   my $bond = shift;
   my $parent;
   if (ref $desc) {
      $parent = $desc;
      $desc = $parent->{desc};
   }
   AI::TerracedScan::Codelet->post_new ($ts, {
      type => 'bond',
      name => 'bond-chain-spark',
      desc => defined $desc ? $desc : '',
      origin => defined $parent ? $parent->{origin} : '',
      urgency => 'normal',
      frame => { bond => $bond },
      callback => sub { my $cr = shift; return sub { handle_bond_chain_spark ( $ts, $cr ); }; },
   });
}
sub handle_bond_chain_spark {
   my ($ts, $cr) = @_;
   
   my $ws = $ts->{workspace};
   my $bond = $cr->{frame}->{bond};
   #$ws->kill_unit ($spark->get_id);
   
   $cr->fail ('temp fail #' . $bond->get_id());
}

=head2 describe_unit (unit)

Provides a brief descriptive string for a bond unit; this is identical to that for a spark (sparks are promoted to bonds to start with).

=cut

sub describe_unit {
   my ($self, $unit, $scan) = @_;
   
   return $scan->describe_unit ($unit->{frame}->{from}) . $scan->describe_unit ($unit->{frame}->{to});
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
