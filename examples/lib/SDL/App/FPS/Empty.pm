
# example subclass of SDL::App::FPS - benchmark overhead of empty draw_frame

package SDL::App::FPS::Empty;

# (C) 2002 by Tels <http://bloodgate.com/>

use strict;

use SDL::App::FPS qw/
  BUTTON_MOUSE_LEFT
  BUTTON_MOUSE_MIDDLE
  BUTTON_MOUSE_RIGHT
  /;
use SDL::Event;
#use SDL::App::FPS::EventHandler;

use vars qw/@ISA/;
@ISA = qw/SDL::App::FPS/;

##############################################################################
# routines that are usually overriden in a subclass

sub draw_frame
  {
  # draw one frame, usually overrriden in a subclass.
  my ($self,$current_time,$lastframe_time,$current_fps) = @_;

  }

sub post_init_handler
  {
  my $self = shift;

  # set up the event handlers
  $self->watch_event (
    quit => SDLK_q, fullscreen => SDLK_f, freeze => SDLK_SPACE,
   ); 
  }

1;

__END__

