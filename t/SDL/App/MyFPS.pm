
# sample subclass of SDL::App::FPS

package SDL::App::MyFPS;

# (C) by Tels <http://bloodgate.com/>

use strict;

use SDL::App::FPS;

use vars qw/@ISA/;
@ISA = qw/SDL::App::FPS/;

##############################################################################
# routines that are usually overriden in a subclass

sub draw_frame
  {
  # draw one frame, usually overrriden in a subclass. If necc., this might
  # call $self->handle_event().
  my ($self,$current_time,$lastframe_time,$current_fps) = @_;
  
  my $last_print = $self->{myfps}->{last_print} || 0;
  my $now = $self->now();

  # once per second print the achieved FPS
  if ($now - $last_print > 1000)
    {
    print ("# FPS $current_fps/s\n");
    $self->{myfps}->{last_print} = $now;
    }
    
  $self->{myfps}->{drawcounter}++;
  
  $self->quit() if $self->frames() >= 100;
  }

#sub handle_event
#  {
#  # called for each event that occurs, override in a subclass
#  my ($self, $event) = @_;
#
#  0;
#  }

sub post_init_handler
  {
  my $self = shift;
  $self->{myfps}->{post_init_handler}++;
  $self->{myfps}->{now} = $self->{now};	# test that now was initialized
  $self;
  }

sub pre_init_handler
  {
  my $self = shift;
  $self->{myfps}->{pre_init_handler}++;
  $self;
  }

sub quit_handler
  {
  my $self = shift;
  $self->{myfps}->{quit_handler}++;
  $self;
  }

1;

__END__

