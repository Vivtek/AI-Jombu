package AI::Jombu;

use 5.006;
use strict;
use warnings;

use parent qw(AI::TerracedScan);

use AI::Jombu::Scene;

use AI::Jombu::Letter;
use AI::Jombu::Spark;

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

=head2 new (initial string)

Jombu is called with a string containing the initial jumble.

=cut

sub new {
   my ($class, $init) = @_;
   my $self = bless ({}, $class);
   $self->_init_({typereg => {'letter',     'AI::Jombu::Letter',
                              'spark',      'AI::Jombu::Spark',
                              #'bond',       'AI::Jombu::Bond',
                              #'ccluster',   'AI::Jombu::ConsonantCluster',
                              #'vcluster',   'AI::Jombu::VowelCluster',
                              #'syllable',   'AI::Jombu::Syllable',
                              #'wordoid',    'AI::Jombu::Wordoid',
                             },
                  init => $init
                 });
}

=head2 parse_setup (string)

Jombu has a much easier initial setup structure, so we can save a lot of time by having a parser to split the letters out into unit specs.

=cut

sub parse_setup {
   my $self = shift;
   my $units = [];
   foreach (split //, $_[0]) {
      push @$units, ['letter', undef, $_, undef];
   }
   return Iterator::Records->new ($units, ['type', 'id', 'data', 'frame']);
}

=head2 setup_display (directory)

If we're going to make use of the display animation scene, which outputs Pikchr, then it needs to be initialized before the run starts.
This basically consists of specifying a directory where the SVG for each scene will be written.

=cut

sub setup_display {
   my ($self, $directory) = @_;
   $self->{scene} = AI::Jombu::Scene->new($self);
   $self->{scene}->jombu_initialize (path ($directory));
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
