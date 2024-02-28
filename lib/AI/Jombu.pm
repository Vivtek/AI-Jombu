package AI::Jombu;

use 5.006;
use strict;
use warnings;

use parent qw(AI::TerracedScan);

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

=head2 new

=cut

sub new {
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
