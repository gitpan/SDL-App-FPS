
# example of SDL::App::FPS demonstrating usage of OpenGL. Shows a .md2
# model

package SDL::App::FPS::MyMD2;

# (C) 2002-2003 by Tels <http://bloodgate.com/>

use strict;

use SDL::OpenGL;
use SDL::App::FPS qw/
  BUTTON_MOUSE_LEFT
  BUTTON_MOUSE_MIDDLE
  BUTTON_MOUSE_RIGHT
  /;
use SDL::Event;

use Games::3D::Model;

use vars qw/@ISA/;
@ISA = qw/SDL::App::FPS/;

##############################################################################

sub _gl_init_view
  {
  my $self = shift;

  glViewport(0,0,$self->width(),$self->height());

  glMatrixMode(GL_PROJECTION());
  glLoadIdentity();

  # set up the view frustrum, anything in there will be rendered, anything
  # outside will be "clipped" off, e.g. not rendered

  glFrustum(-0.1,0.1,-0.075,0.075,0.3,300.0);

  glMatrixMode(GL_MODELVIEW());
  glLoadIdentity();
  
  glEnable(GL_CULL_FACE);	# cull faces, and
  glCullFace(GL_BACK); 		# specifically backwards pointing faces
  glFrontFace(GL_CCW);		# front faces are defined to be
				# counter-clock-wise

  glClearColor(0, 0, 0, 0);	# black as default

  glShadeModel(GL_SMOOTH());	# use smooth shading
  glEnable(GL_DEPTH_TEST);	# we need this

#  glEnable(GL_LIGHTING());	# setup el cheapo lighting
#  glEnable(GL_LIGHT0());
#  glEnable(GL_COLOR_MATERIAL());

  }

sub _gl_clear_screen
  {
  my $self = shift;

  glClear( GL_DEPTH_BUFFER_BIT() | GL_COLOR_BUFFER_BIT());

  glLoadIdentity();

  glTranslate(0,8,-180.0);		# fudge factors

  # compute the current angle based on elapsed time
  my $angle = ($self->current_time() / 9) % 360;
  glRotate($angle,0,1,0);
  glRotate(-90,1,0,0);			# put model upright

  }

sub draw_frame
  {
  # draw one frame, usually overrriden in a subclass.
  my ($self,$current_time,$lastframe_time,$current_fps) = @_;

  # using pause() would be a bit more efficient, though 
  return if $self->time_is_frozen();
       
  $self->_gl_clear_screen();

  my $model = $self->{model};

  my $states = $model->states();	# how many states do we have?
  # each second, do a different one
  my $current_state = ($current_time / 5000) % $states;
  if ($self->{last_model_state} != $current_state)
    {
    # switch
    $model->state($current_state,$current_time,100);	# 100 ms to next state
    print "Current state $current_state\n";
    $self->{last_model_state} = $current_state;
    }
  $model->render($current_time);

# my $frame = ($current_time / 70)  % $self->{model}->frames();
# $self->{model}->render_frame($frame);

  SDL::GLSwapBuffers();		# without this, you won't see anything!
  }

sub resize_handler
  {
  my $self = shift;

  $self->_gl_init_view();
  }

sub post_init_handler
  {
  my $self = shift;

  $self->_gl_init_view();

  # set up some event handlers
  $self->watch_event ( 
    quit => SDLK_q, fullscreen => SDLK_f, freeze => SDLK_SPACE,
   );
  
  $self->{last_model_state} = 0;

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

sub _set_model
  {
  my ($self,$file) = @_;

  $self->{model_name} = $file;
  $self->{model} = Games::3D::Model->new( file => $file, type => 'MD2', );
  }

1;

__END__

