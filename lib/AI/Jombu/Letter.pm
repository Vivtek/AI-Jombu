package AI::Jombu::Letter;

use 5.006;
use strict;
use warnings;

=head1 NAME

AI::Jombu::Letter - The 'letter' semantic unit, and the codelets that work with it

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS


=head1 SUBROUTINES/METHODS

=head2 new (type, id, [frame], [data])

Creates a new unit of the named type, and optionally assigns its content. You will almost never need to do this; normally you'll parse a descriptive language into
a workspace structure. If the unit is a sensory unit, it represents data outside the memory, and C<data> is used to specify it.

=cut

sub new {
   my ($class, $type, $id, $frame, $data) = @_;
   my $self = bless ({}, $class);
   $self->{type} = $type;
   $self->{frame} = defined $frame ? { %$frame } : {};
   $self->set_data ($data) if defined $data;
   $self->{id} = ref $id ? $id->get_id() : $id if defined $id;
   $self;
}

=head2 set (slot, value), add (slot, value), del (slot, value)

A named slot can have one or more values (if the latter, they're just a list). The C<set> method sets a single value; C<add> adds a value to the list and
C<del> removes an existing value from the list. Values are other units, so there is always exact identity.

If the type prohibits the value named, this should croak.

=cut

sub set {
   my ($self, $slot, $value) = @_;
   $self->{frame}->{$slot} = $value;
}
sub add {
   my ($self, $slot, $value) = @_;
   if (not $self->has_slot ($slot)) {
      $self->{frame}->{$slot} = { $value => $value };
   } elsif (ref ($self->{frame}->{$slot}) eq 'HASH') {
      $self->{frame}->{$slot}->{$value} = $value;
   } else {
      $self->{frame}->{$slot} = { $self->{frame}->{$slot} => $self->{frame}->{$slot}, $value => $value };
   }
}
sub del {
   my ($self, $slot, $value) = @_;
   return unless $self->has_slot ($slot);
   delete $self->{frame}->{$slot}->{"$value"};
}

=head2 get (slot), has_slot (slot)

Gets either the single value or the arrayref of values for the named slot. Returns undef if the unit does not have this slot.

=cut

sub get {
   my ($self, $slot) = @_;
   return undef unless $self->has_slot ($slot);
   if (ref ($self->{frame}->{$slot}) eq 'HASH') {
      return [ values %{$self->{frame}->{$slot}} ];
   }
   return $self->{frame}->{$slot};
}
sub has_slot {
   my ($self, $slot) = @_;
   defined ($self->{frame}->{$slot});
}

=head2 get_type()

Gets the type of the unit.

=cut

sub get_type {
   my ($self) = @_;
   $self->{type};
}

=head2 get_data(), set_data()

If this is a sensory unit (if it points to external data), this returns that data.

=cut

sub get_data {
   my ($self) = @_;
   $self->{data};
}
sub set_data {
   my ($self, $data) = @_;
   $self->{data} = $data;
}

=head2 get_id(), set_id()

Gets or sets the ID of the unit.

=cut

sub get_id {
   my ($self) = @_;
   $self->{id};
}
sub set_id {
   my ($self, $data) = @_;
   $self->{id} = $data;
}

=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ai-terracedscan at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=AI-TerracedScan>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AI::Jombu::Letter


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

1; # End of AI::Jombu::Letter
