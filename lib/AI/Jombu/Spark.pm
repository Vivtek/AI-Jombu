package AI::Jombu::Spark;

use 5.006;
use strict;
use warnings;

use parent qw(AI::TerracedScan::Type);
use AI::TerracedScan::Codelet;
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

When called, C<spark-checker> examines the spark it's bound to, and asks the chunkabet how good a bond the letter pair might be. If the pair isn't a valid bond
at all, the codelet fails. Otherwise, it upgrades the spark to a bond, and bond scouts can then randomly choose it for further processing.

The codelet's single parameter is the spark it's bound to.

=cut

sub post_spark_checker {
   my $ts = shift;
   my $desc = shift;
   my $spark = shift;
   AI::TerracedScan::Codelet->post_new ($ts, {
      type => 'spark',
      name => 'spark-checker',
      desc => defined $desc ? $desc : '',
      urgency => 'normal',
      frame => { spark => $spark },
      callback => sub { my $cr = shift; return sub { handle_spark_checker ( $ts, $cr ); }; },
   });
}
sub handle_spark_checker {
   my ($ts, $cr) = @_;
   
   my $ws = $ts->{workspace};
   my $spark = $cr->{frame}->{spark};
   $ws->kill_unit ($spark->get_id);
   
   $cr->fail ('temp fail #' . $spark->get_id());
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
