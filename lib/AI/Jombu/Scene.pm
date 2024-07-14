package AI::Jombu::Scene;

use 5.006;
use strict;
use warnings;

use parent qw(AI::TerracedScan::Scene);
use Carp;
use Data::Dumper;
use Path::Tiny;
use Data::Tab;

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
   $self->{log} = Data::Tab->new ([], headers => ['action', 'id', 'data']);
   
   my $it = $self->{scan}->iterate_workspace()->where(sub {$_[0] eq 'letter'}, 'type')->iter;
   while (my $row = $it->()) {
      my ($id, $type, $unit, $desc) = @$row;
      my $x = rand(4);
      my $y = rand(4);
      $self->log ('letter', $id, $desc);
      $self->log ('locate', $id, sprintf ("x=%f,y=%f", $x, $y));
      
      $self->add_unit ($id, $type, $unit, $desc);
      $self->locate_unit ($id, $x, $y);

      #$self->{units}->{$id} = {
      #   type => $type,
      #   unit => $unit,
      #   desc => $desc,
      #   x_c => $x,
      #   y_c => $y,
      #   label => "L$id",
      #   pik => "L$id: circle \"$desc\" at $x, $y",
      #   live => 1,
      #};
      push @{$self->{unit_list}}, $id;
   }
   
   #$self->write_frame();
}

sub log {
   my ($self, $action, $id, $data) = @_;
   return unless $self->{log};
   $self->{log}->add_row ([$action, $id, $data]);
}

sub replay {
   my ($self, $directory, $action_iterator) = @_;
   $self->{frame_no} = 0;
   $self->{directory} = $directory;
   
   my $it = $action_iterator->iter;
   while (my $row = $it->()) {
      my ($action, $id, $data) = @$row;
      $id =~ s/^ *//; # Clean up for some formatting issues
      if      ($action eq 'letter') {
         $self->add_unit ($id, 'letter', undef, $data);
      } elsif ($action eq 'glom') {
         $self->add_unit ($id, 'glom', undef, $data);
      } elsif ($action eq 'locate') {
         my $p = unpack_data ($data);
         $self->locate_unit ($id, $p->{x}, $p->{y});

      } elsif ($action eq 'f-loc') {
         my $p = unpack_data ($data);
         $self->set ($id, 'x-old', $self->get ($id, 'x_c')) unless defined $self->get ($id, 'x-old');
         $self->set ($id, 'y-old', $self->get ($id, 'y_c')) unless defined $self->get ($id, 'y-old');
         my $x = $self->get ($id, 'x-old');
         my $y = $self->get ($id, 'y-old');
         $self->set ($id, 'x_c', $x + ($p->{x} - $x) * $p->{r});
         $self->set ($id, 'y_c', $y + ($p->{y} - $y) * $p->{r});
         $self->gen_pik ($id);

      } elsif ($action eq 'spark') {
         $self->add_unit ($id, 'spark', undef, ''); # These semantics are a little cockeyed
         $self->set_data ($id, $data);
      } elsif ($action eq 'spark-status') {
         $self->{units}->{$id}->{status} = $data;
         $self->gen_pik ($id);
      } elsif ($action eq 'spark-kill') {
         $self->{units}->{$id}->{status} = 'dead';
         $self->set ($id, 'pik', '');
         
      } elsif ($action eq 'promote') {
         $self->set ($id, 'type', $data);
         $self->gen_pik ($id);
      } elsif ($action eq 'kill') {
         $self->set ($id, 'status', 'dead');
         $self->set ($id, 'pik',    '');
      } elsif ($action eq 'move') {
         my $p = unpack_data ($data);
         $self->start_process ($id, $self->make_mover ($id, $p->{x}, $p->{y}, $p->{frames}));
         
      } elsif ($action eq 'label') {
         if ($data =~ /\[(.*),(.*)\]:(.*)$/) {
            push @{$self->{framelabels}}, [$1, $2, $3];
         }


      } elsif ($action eq 'frame') {
         $self->write_frame();
      }
   }
}

sub unpack_data {
   my $p = {};
   foreach my $d (split /,/, shift) {
      my ($var, $val) = split /=/, $d;
      $p->{$var} = $val;
   }
   $p;
}

sub get {
   my ($self, $id, $var) = @_;
   $self->{units}->{$id}->{$var};
}
sub set {
   my ($self, $id, $var, $val) = @_;
   $self->{units}->{$id}->{$var} = $val;
}
sub set_data {
   my ($self, $id, $data) = @_;
   my $p = unpack_data ($data);
   foreach my $k (keys %$p) {
      $self->set ($id, $k, $p->{$k});
   }
}


sub label_from_id {
   my ($self, $id) = @_;
   return "L$id";
}
sub pik_from_id {
   my ($self, $id) = @_;
   my $type = $self->{units}->{$id}->{type};
   if      ($type eq 'letter') {
      return sprintf ("L$id: circle \"%s\" at %s, %s", $self->{units}->{$id}->{desc}, $self->{units}->{$id}->{x_c}, $self->{units}->{$id}->{y_c});
   } elsif ($type eq 'spark') {
      if ($self->{units}->{$id}->{status} eq 'half') {
         return sprintf ("arrow dashed from L%s to 1/2 way between L%s and L%s chop",
                         $self->{units}->{$id}->{from}, $self->{units}->{$id}->{from}, $self->{units}->{$id}->{to});
      } else {
         return sprintf ("arrow dashed from L%s to L%s chop",
                         $self->{units}->{$id}->{from}, $self->{units}->{$id}->{to});
      }
   } elsif ($type eq 'bond') {
      return sprintf ("arrow from L%s to L%s chop",
                      $self->{units}->{$id}->{from}, $self->{units}->{$id}->{to});
   } elsif ($type eq 'glom') {
      return sprintf ("box thick \"%s\" width 0.5 height 0.25 radius 4px at %s, %s", $self->{units}->{$id}->{desc}, $self->{units}->{$id}->{x_c}, $self->{units}->{$id}->{y_c});
   }
}

sub gen_pik {
   my ($self, $id) = @_;
   $self->{units}->{$id}->{pik} = $self->pik_from_id ($id);
}

sub add_unit {
   my ($self, $id, $type, $unit, $desc) = @_;
   
   $self->{units}->{$id} = {
      type => $type,
      unit => $unit,
      desc => $desc,
      label => '',
      pik => '', # Unit is invisible until a location is assigned
      live => 1,
   };
   $self->{units}->{$id}->{label} = $self->label_from_id($id);
   push @{$self->{unit_list}}, $id;
}
sub locate_unit {
   my ($self, $id, $x, $y) = @_;
   $self->set ($id, 'x_c', $x);
   $self->set ($id, 'y_c', $y);
   $self->set ($id, 'x-old', undef);
   $self->set ($id, 'y-old', undef);
   $self->gen_pik ($id);
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
      $self->add_unit ($id, 'spark', $unit, '') if $action eq 'add';
      $self->set ($id, 'from', $unit->{frame}->{from}->get_id());
      $self->set ($id, 'to',   $unit->{frame}->{to}->get_id());
      $self->log ('spark', $id, sprintf ("from=%s,to=%s", $self->{units}->{$id}->{from}, $self->{units}->{$id}->{to}));

      $self->set ($id, 'status', 'half');
      $self->gen_pik ($id);
      $self->log ('spark-status', $id, 'half');
      $self->write_frame();

      $self->{units}->{$id}->{status} = 'full';      
      $self->{units}->{$id}->{pik} = $self->pik_from_id ($id);
      $self->log ('spark-status', $id, 'full');
      $self->write_frame();
   } elsif ($action eq 'kill') {
      $self->{units}->{$id}->{pik} = "";
      $self->log ('kill', $id, '');
      $self->write_frame();
   }
}

sub display_bond {
   my ($self, $action, $id, $unit) = @_;
   
   if ($action eq 'promote') {
      $self->{units}->{$id}->{type} = 'bond' if $action eq 'promote';
      $self->log ('promote', $id, 'bond');
      $self->gen_pik ($id);
      $self->write_frame();
      
      my ($new_from_x, $new_from_y, $new_to_x, $new_to_y) = $self->bond_move_calculate ($self->{units}->{$id}->{from}, $self->{units}->{$id}->{to});
      $self->log ('move', $self->{units}->{$id}->{from}, sprintf ("x=%f,y=%f,frames=4", $new_from_x, $new_from_y));
      $self->log ('move', $self->{units}->{$id}->{to},   sprintf ("x=%f,y=%f,frames=4", $new_to_x,   $new_to_y));
      
      $self->start_process ($self->{units}->{$id}->{from}, $self->make_mover ($self->{units}->{$id}->{to},   $new_to_x,   $new_to_y,   4));
      $self->start_process ($self->{units}->{$id}->{to},   $self->make_mover ($self->{units}->{$id}->{from}, $new_from_x, $new_from_y, 4));
   } elsif ($action eq 'kill') {
      $self->{units}->{$id}->{pik} = "";
      $self->log ('kill', $id, '');
      $self->write_frame();
   }
}

sub bond_move_calculate {
   my ($self, $from, $to) = @_;

   my $start_from_x = $self->{units}->{$from}->{x_c};
   my $start_from_y = $self->{units}->{$from}->{y_c};

   my $start_to_x   = $self->{units}->{$to}  ->{x_c};
   my $start_to_y   = $self->{units}->{$to}  ->{y_c};
   
   my $centroid_x = ($start_from_x + $start_to_x) / 2;
   my $centroid_y = ($start_from_y + $start_to_y) / 2;
   
   my $target_from_x = $centroid_x - 0.4;
   my $target_to_x   = $centroid_x + 0.4;
   
   return ($target_from_x, $centroid_y, $target_to_x, $centroid_y);

}

sub make_mover {
   my ($self, $id, $new_x, $new_y, $frames) = @_;
   
   my $step = 0;
   my $start_x = $self->{units}->{$id}->{x_c};
   my $start_y = $self->{units}->{$id}->{y_c};
   
   sub {
      my $cur_x = $start_x + ($new_x - $start_x) * (0.15, 0.5, 0.85, 1.0)[$step];
      my $cur_y = $start_y + ($new_y - $start_y) * (0.15, 0.5, 0.85, 1.0)[$step];
      
      $self->{units}->{$id}->{x_c} = $cur_x;
      $self->{units}->{$id}->{y_c} = $cur_y;
      $self->gen_pik ($id);
      
      $step += 1;
      return 'done' if $step >= $frames;
      return 'ok';
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

   $self->log ('move', $from, sprintf ("x=%f,y=%f,frames=4", $target_from_x, $centroid_y));
   $self->log ('move', $to,   sprintf ("x=%f,y=%f,frames=4", $target_to_x, $centroid_y));
   
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
      my $text =  $fn->();
      $self->log ('label', '', sprintf ("[%f,%f]:%s", $x, $y, $text));
      print $svg '"' . $fn->() . '" at ' . "$x, $y\n";
   }
   foreach my $label (@{$self->{framelabels}}) {
      my ($x, $y, $text) = @$label;
      print $svg '"' . $text . '" at ' . "$x, $y\n";
   }
   $self->{framelabels} = [];
   close ($svg);   

   $self->log ('frame', $self->{frame_no}, '');
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
