
# example of SDL::App::FPS demonstrating usage of OpenGL. Based on code from
# SDL_perl test/OpenGL/test2.pl

package SDL::App::FPS::MyOpenGL;

# (C) 2002-2003 by Tels <http://bloodgate.com/>

use strict;

use SDL::OpenGL;
use SDL::OpenGL::Cube;
use SDL::App::FPS qw/
  BUTTON_MOUSE_LEFT
  BUTTON_MOUSE_MIDDLE
  BUTTON_MOUSE_RIGHT
  /;
use SDL::Event;
use SDL::App::FPS::Color qw/BLACK WHITE GRAY darken lighten blend/;

use vars qw/@ISA/;
@ISA = qw/SDL::App::FPS/;

##############################################################################

sub _gl_draw_cube
  {
  my $self = shift;

  glClear( GL_DEPTH_BUFFER_BIT() | GL_COLOR_BUFFER_BIT());

  glLoadIdentity();

  glTranslate(0,0,-6.0);

  # compute the current angle based on elapsed time

  my $angle = ($self->current_time() / 5) % 360;
  my $other = $angle % 5;

  glRotate($angle,1,1,0);
  glRotate($other,0,1,1);

  glColor(1,1,1);
  $self->{cube}->draw();
  }

sub _gl_init_view
  {
  my $self = shift;

  glViewport(0,0,$self->width(),$self->height());

  glMatrixMode(GL_PROJECTION());
  glLoadIdentity();

  if ( @_ )
    {
    glPerspective(45.0,4/3,0.1,100.0);
    }
  else
    {
    glFrustum(-0.1,0.1,-0.075,0.075,0.3,100.0);
    }

  glMatrixMode(GL_MODELVIEW());
  glLoadIdentity();
  }

sub draw_frame
  {
  # draw one frame, usually overrriden in a subclass.
  my ($self,$current_time,$lastframe_time,$current_fps) = @_;

  #$self->pause(SDL_KEYDOWN);	# we don't draw anything

  # using pause() would be a bit more efficient, though 
  return if $self->time_is_frozen();
       
  $self->_gl_draw_cube();

  SDL::GLSwapBuffers();		# without this, you won't see anything!
  }

sub resize_handler
  {
  my $self = shift;

  glViewport(0,0,$self->width(),$self->height());
  }

sub post_init_handler
  {
  my $self = shift;

  $self->_gl_init_view();

  glEnable(GL_CULL_FACE);
  glFrontFace(GL_CCW);
  glCullFace(GL_BACK);

  $self->{cube} = SDL::OpenGL::Cube->new();

  my @colors =  (
        1.0,1.0,0.0,    1.0,0.0,0.0,    0.0,1.0,0.0, 0.0,0.0,1.0,       #back
        0.4,0.4,0.4,    0.3,0.3,0.3,    0.2,0.2,0.2, 0.1,0.1,0.1 );     #front

  $self->{cube}->color(@colors);

  # set up some event handlers
  $self->watch_event ( 
    quit => SDLK_q, fullscreen => SDLK_f, freeze => SDLK_SPACE,
   );

  $self->add_event_handler (SDL_MOUSEBUTTONDOWN, BUTTON_MOUSE_LEFT,
   sub {
     my $self = shift;
     return if $self->time_is_ramping() || $self->time_is_frozen();
     $self->ramp_time_warp('2',1500);           # ramp up
     });
  $self->add_event_handler (SDL_MOUSEBUTTONDOWN, BUTTON_MOUSE_RIGHT,
   sub {
     my $self = shift;
     return if $self->time_is_ramping() || $self->time_is_frozen();
     $self->ramp_time_warp('0.3',1500);         # ramp down
     });
  $self->add_event_handler (SDL_MOUSEBUTTONDOWN, BUTTON_MOUSE_MIDDLE,
   sub {
     my $self = shift;
     return if $self->time_is_ramping() || $self->time_is_frozen();
     $self->ramp_time_warp('1',1500);           # ramp to normal
     });
  }

1;

__END__

