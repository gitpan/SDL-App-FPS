
# example subclass of SDL::App::FPS - benchmark overhead of empty draw_frame

package SDL::App::FPS::Empty;

# (C) 2002 by Tels <http://bloodgate.com/>

use strict;

use SDL::App::FPS;
use SDL::Event;
use SDL::App::FPS::EventHandler qw/
  LEFTMOUSEBUTTON RIGHTMOUSEBUTTON MIDDLEMOUSEBUTTON
  /;

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
  $self->add_event_handler (SDL_KEYDOWN, SDLK_q, 
   sub { my $self = shift; $self->quit(); });
  $self->add_event_handler (SDL_KEYDOWN, SDLK_f, 
   sub { my $self = shift; $self->fullscreen(); });
  $self->add_event_handler (SDL_KEYDOWN, SDLK_SPACE, 
   sub {
     my $self = shift;
    if ($self->time_is_frozen())
      {
      $self->thaw_time();
      }
    else
      {
      $self->freeze_time();
      }
    });
  }

1;

__END__

