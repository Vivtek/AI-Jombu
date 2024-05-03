package AI::Jombu::Scene;

use 5.006;
use strict;
use warnings;

use parent qw(AI::TerracedScan::Scene);
use Carp;
use Data::Dumper;
use Path::Tiny;

=head1 NAME

AI::Jombu::Scene - Subclasses AI::TerracedScan::Scene to provide Pikchr output for Jombu runs

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

A scene is used to represent a diagram or other visual display of (some of) the semunits in the Workspace. The Jombu Scene builds Pikchr diagrams for each
frame of an animation sequence representing the run; these can be strung together to make a GIF animation.

=head1 TYPE-SPECIFIC INITIALIZATION

=cut

sub jombu_initialize {
   my $self = shift;
   $self->{frame_no} = 0;
   $self->{directory} = shift;
   
   my $it = $self->{scan}->iterate_workspace()->where(sub {$_[0] eq 'letter'}, 'type')->iter;
   while (my $row = $it->()) {
      my ($id, $type, $unit, $desc) = @$row;
      my $x = rand(4);
      my $y = rand(4);
      $self->{units}->{$id} = {
         type => $type,
         unit => $unit,
         desc => $desc,
         x_c => $x,
         y_c => $y,
         label => "L$id",
         pik => "L$id: circle \"$desc\" at $x, $y",
         live => 1,
      };
      push @{$self->{unit_list}}, $id;
   }
   #$self->write_frame();
}

=head1 DISPLAYING AN ACTION

We subclass display_action to build Jombu-specific display diagrams.

=head2 display_action (action, id, type, unit)

=cut


sub display_action {
   my ($self, $action, $id, $type, $unit) = @_;
   
   return $self->display_letter ($action, $id, $unit) if $type eq 'letter';
   return $self->display_spark  ($action, $id, $unit) if $type eq 'spark';
   return $self->display_bond   ($action, $id, $unit) if $type eq 'bond';
}

sub display_letter {
   my ($self, $action, $id, $unit) = @_;
}

sub display_spark {
   my ($self, $action, $id, $unit) = @_;
   
   if ($action eq 'add' or $action eq 'unkill') {
      push @{$self->{unit_list}}, $id if $action eq 'add';

      my $from = $unit->{frame}->{from}->get_id();
      my $to = $unit->{frame}->{to}->get_id();
      
      $self->{units}->{$id}->{pik} = "arrow dashed from L$from to 1/2 way between L$from and L$to chop";
      $self->write_frame();
      $self->{units}->{$id}->{pik} = "arrow dashed from L$from to L$to chop";
      $self->write_frame();
   } elsif ($action eq 'kill') {
      my $from = $unit->{frame}->{from}->get_id();
      my $to = $unit->{frame}->{to}->get_id();
      $self->{units}->{$id}->{pik} = "line thin color 0xf0f0f0 from L$from to L$to chop";
      $self->write_frame();
   }
}

sub display_bond {
   my ($self, $action, $id, $unit) = @_;
   
   if ($action eq 'add' or $action eq 'unkill' or $action eq 'promote') {
      push @{$self->{unit_list}}, $id if $action eq 'add';
      $self->{units}->{$id}->{type} = 'bond' if $action eq 'promote';

      my $from = $unit->{frame}->{from}->get_id();
      my $to = $unit->{frame}->{to}->get_id();
      
      $self->{units}->{$id}->{pik} = "arrow from L$from to L$to chop";
      $self->write_frame();
      
      $self->start_process ($id, $self->make_bond_mover ($id, $from, $to));
   } elsif ($action eq 'kill') {
      my $from = $unit->{frame}->{from}->get_id();
      my $to = $unit->{frame}->{to}->get_id();
      $self->{units}->{$id}->{pik} = "";
      $self->write_frame();
   }
}

sub make_bond_mover {
   my ($self, $id, $from, $to) = @_;
   #printf ("Moving bond %s\n", $self->{units}->{$id}->{desc});
   my $start_from_x = $self->{units}->{$from}->{x_c};
   my $start_from_y = $self->{units}->{$from}->{y_c};
   #printf ("%s is at %0.1f,%0.1f\n", $self->{units}->{$from}->{desc}, $self->{units}->{$from}->{x_c}, $self->{units}->{$from}->{y_c});
   my $start_to_x   = $self->{units}->{$to}  ->{x_c};
   my $start_to_y   = $self->{units}->{$to}  ->{y_c};
   #printf ("%s is at %0.1f,%0.1f\n", $self->{units}->{$to}->{desc}, $self->{units}->{$to}->{x_c}, $self->{units}->{$to}->{y_c});
   
   my $centroid_x = ($start_from_x + $start_to_x) / 2;
   my $centroid_y = ($start_from_y + $start_to_y) / 2;
   #printf ("centroid is at %0.1f,%0.1f\n", $centroid_x, $centroid_y);
   
   my $target_from_x = $centroid_x - 0.4;
   my $target_to_x   = $centroid_x + 0.4;
   
   my $step = 0;
   my $frames = 4;
   
   sub {
      my $cur_from_x = $start_from_x + ($target_from_x - $start_from_x) * (0.15, 0.5, 0.85, 1.0)[$step];
      my $cur_to_x   = $start_to_x   + ($target_to_x   - $start_to_x)   * (0.15, 0.5, 0.85, 1.0)[$step];
      my $cur_from_y = $start_from_y + ($centroid_y    - $start_from_y) * (0.15, 0.5, 0.85, 1.0)[$step];
      my $cur_to_y   = $start_to_y   + ($centroid_y    - $start_to_y)   * (0.15, 0.5, 0.85, 1.0)[$step];
      
      $self->{units}->{$from}->{x_c} = $cur_from_x;
      $self->{units}->{$from}->{y_c} = $cur_from_y;
      $self->{units}->{$from}->{pik} = "L$from: circle \"" . $self->{units}->{$from}->{desc} . "\" at $cur_from_x, $cur_from_y";
      $self->{units}->{$to}  ->{x_c} = $cur_to_x;
      $self->{units}->{$to}  ->{y_c} = $cur_to_y;
      $self->{units}->{$to}  ->{pik} = "L$to: circle \"" . $self->{units}->{$to}->{desc} .   "\" at $cur_to_x, $cur_to_y";
      
      $step += 1;
      return 'done' if $step >= $frames;
      return 'ok';
   }
}

sub write_frame {
   my $self = shift;
   my $file = path($self->{directory}, sprintf ('frame%03s.svg', $self->{frame_no}));
   $self->{frame_no} += 1;
   
   foreach my $process_id (keys %{$self->{processes}}) {
      my $ret = $self->{processes}->{$process_id}->();
      delete $self->{processes}->{$process_id} if $ret eq 'done';
   }
   
   open (my $svg, '|-', "pikchr --svg-only - > $file");
   #open (my $svg, '>', $file);
   print $svg "dot at -0.2,-0.2\n";
   print $svg "dot at 4.2,4.2\n";
   foreach my $id (@{$self->{unit_list}}) {
      print $svg $self->{units}->{$id}->{pik} . "\n";
   }
   foreach my $label (@{$self->{labels}}) {
      my ($x, $y, $fn) = @$label;
      print $svg '"' . $fn->() . '" at ' . "$x, $y\n";
   }
   close ($svg);   
}

=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ai-terracedscan at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=AI-TerracedScan>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AI::TerracedScan::Scene


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=AI-TerracedScan>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/AI-TerracedScan>

=item * Search CPAN

L<https://metacpan.org/release/AI-TerracedScan>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Michael Roberts.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of AI::TerracedScan::Scene
