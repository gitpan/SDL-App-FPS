
# example subclass of SDL::App::FPS

package SDL::App::FPS::Kcirb;

# (C) 2002 by Tels <http://bloodgate.com/>

use strict;

use SDL::App::FPS;
use SDL::Event;

use vars qw/@ISA/;
@ISA = qw/SDL::App::FPS/;

##############################################################################
# routines that are usually overriden in a subclass

sub _kcirb_animate_rectangle
  {
  # this animates the moving ractangle
  my $self = shift;

  my $rect = $self->{kcirb}->{rect};

  # how much time elapsed since we started at start point
  my $time_elapsed = $self->current_time() - $rect->{now};
  # calculate how many pixels we must have moved in that time
  my $distance = $rect->{speed} * $time_elapsed / 1000; 

  # calculate the point were we land when we go $distance from the startpoint
  # in the current direction
  my $x_dist = $distance * cos($rect->{angle} * $self->{kcirb}->{PI} / 180);
  my $y_dist = $distance * sin($rect->{angle} * $self->{kcirb}->{PI} / 180);
 
  $rect->{x} = $rect->{x_s} + $x_dist; 
  $rect->{y} = $rect->{y_s} + $y_dist; 

  my $col = 0;	# collison with borders?
  # check whether the rectangle is still in the bounds of the screen
  if ($rect->{x} < 0)
    {
    $col++;
    # we hit the left border
    $rect->{x} = 0;
    # angle is between 90 and 270 degrees)
    $rect->{angle} = 180 - $rect->{angle};
    $rect->{angle} += 360 if $rect->{angle} < 0;
    }
  if ($rect->{x} + $rect->{w} >= $self->width())
    {
    $col++;
    # we hit the right border
    $rect->{x} = $self->width() - $rect->{w};
    # angle is between 270..360 and 0..90 degrees)
    $rect->{angle} = 180 - $rect->{angle};
    $rect->{angle} += 360 if $rect->{angle} < 0;
    }
  if ($rect->{y} < 0)
    {
    $col++;
    # we hit the upper border
    $rect->{y} = 0;
    # angle is between 180 and 360
    $rect->{angle} = 360 - $rect->{angle};
    }
  if ($rect->{y} + $rect->{h} >= $self->height())
    {
    $col++;
    # we hit the lower border
    $rect->{y} = $self->height() - $rect->{h};
    # angle is between 180..360
    $rect->{angle} = 360 - $rect->{angle};
    }
  # hit a wall?
  if ($col > 0)
    {
    # scatter the new angle a bit (avoids endless loops)
    $rect->{angle} += rand(12) - 4;		# skew the scatter to one side
    $rect->{angle} += 360 if $rect->{angle} < 0;
    $rect->{angle} -= 360 if $rect->{angle} >= 360;
    # reset start point and time 
    $rect->{x_s} = $rect->{x};
    $rect->{y_s} = $rect->{y};
    $rect->{now} = $self->current_time();
    }

  }

sub _kcirb_draw_rectangle
  {
  # draw the rectangle on the screen
  my ($self,$rect,$color) = @_;

  my $r = new SDL::Rect ( -height => $rect->{h}, -width => $rect->{w},
   -x => $rect->{x}, -y => $rect->{y},
  );
  $self->{app}->fill($r,$color);

  }

sub draw_frame
  {
  # draw one frame, usually overrriden in a subclass. If necc., this might
  # call $self->handle_event().
  my ($self,$current_time,$lastframe_time,$current_fps) = @_;

  # using pause() would be a bit more efficient, though 
  return if $self->time_is_frozen();

  # undraw the rectangle at the current location
  $self->_kcirb_draw_rectangle($self->{kcirb}->{rect},$self->{kcirb}->{black});

  # move it
  $self->_kcirb_animate_rectangle();

  # draw the rectangle at the current location
  $self->_kcirb_draw_rectangle($self->{kcirb}->{rect},$self->{kcirb}->{color});
  
  # update the screen with the changes
  my $rect = SDL::Rect->new(
   -width => $self->width(), -height => $self->height());
  $self->update($rect);

  }

sub handle_event
  {
  # called for each event that occurs, override in a subclass
  my ($self, $event) = @_;

  my $type = $event->type();

  if ($type == SDL_KEYDOWN)
    {
    # check which key it was
    my $key = $event->key_sym();
    if ($key == SDLK_q)
      {
      $self->quit();
      }
    elsif ($key == SDLK_f)
      {
      $self->fullscreen();
      }
    elsif ($key == SDLK_SPACE)
      {
      if ($self->time_is_frozen())
        {
        $self->thaw_time();
        }
      else
        {
        $self->freeze_time();
        }
      }
    }
  elsif ($type == SDL_MOUSEBUTTONDOWN && 
     !$self->time_is_ramping() && !$self->time_is_frozen())
    {
    # check which button it was
    my $button = $event->button();
    if ($button == 1)				# left button
      {
      $self->ramp_time_warp('3',1500);		# ramp up
      }
    elsif ($button == 3)			# right button
      {
      $self->ramp_time_warp('0.3',1500);	# ramp down
      }
    elsif ($button == 2)			# middle button
      {
      $self->ramp_time_warp('1',1500);		# ramp to normal
      }
    }

  0;
  }

sub post_init_handler
  {
  my $self = shift;
 
  my $k = { 
    x => $self->option('width') / 2,
    y => $self->option('height') / 2,
    w => 32,
    h => 16,
    angle => rand(360),
    speed => rand(50)+200,			# in pixel/second
    now => $self->current_time(),
  };
  $self->{kcirb}->{rect} = $k;
  
  # make it a perfect square, independ from screen resolution (works only
  # in fullscreen mode, of course)
  $k->{h} = int($k->{w} * $self->height()/ $self->width());

  $k->{x_s} = $k->{x};		 # start x
  $k->{y_s} = $k->{y};		 # start y
  
  $self->{kcirb}->{black} = new SDL::Color (-r => 0, -g => 0, -b => 0);
  $self->{kcirb}->{color} = new SDL::Color (-r => 0xff, -g => 0xff, -b => 0);
  $self->{kcirb}->{PI} = 3.141592654;
  }

1;

__END__

