
# example subclass of SDL::App::FPS

package SDL::App::FPS::MyMandel;

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

sub _mandel_recursive
  {
  # this routine takes a given rectangle and divides it into two halves
  # if any of the two halves has the same color
  my $self = shift;

  return if ($self->{state} == 3);

  my $cache = $self->{cache};
  if ($self->{state} == 1)
    {
    # in stage 1, we must setup a rectangle around the screen
    # once we are done, we enter stage 2
    if ($self->{done} == 0)
      {
      # calculate the upper line
      for my $x (0 .. $self->{width}-1)
        {
        $self->_mandel_draw_point($x,0,
          $cache->[$x]->[0] = $self->_mandel_point($x,0) );
        }
      $self->{done} = 1;
      return;
      }
    if ($self->{done} == 1)
      {
      # calculate the lower line
      for my $x (0 .. $self->{width}-1)
        {
        $self->_mandel_draw_point($x,$self->{height}-1,
         $cache->[$x]->[$self->{height}-1] =
           $self->_mandel_point($x,$self->{height}-1) );
        }
      $self->{done} = 2;
      return;
      }
    if ($self->{done} == 2)
      {
      # calculate the left line
      for my $y (0 .. $self->{height}-1)
        {
        $self->_mandel_draw_point(0,$y,
         $cache->[0]->[$y] = $self->_mandel_point(0,$y) );
        }
      $self->{done} = 3;
      return;
      }
    if ($self->{done} == 3)
      {
      # calculate the right line
      for my $y (0 .. $self->{height}-1)
        {
        $self->_mandel_draw_point($self->{width}-1,$y,
         $cache->[$self->{width}-1]->[$y] =
          $self->_mandel_point($self->{width}-1,$y) ); 
        }
      $self->{done} = 0;	# divide next
      $self->{state} = 2;
      push @{$self->{stack}}, [ 0, 0, $self->{width}-1, $self->{height}-1, 0 ];
      return;
      }
    }

  my $now = $self->app()->ticks();
  my $rect = SDL::Rect->new( -x => 0, -y => 0, -width => 1, -height => 1);
  # our stack contains the rectangles we must still do
  RECTANGLE:
   while (@{$self->{stack}} > 0)
    {
    print "\rRectangles still todo: ",scalar @{$self->{stack}},"    ";
    if ($self->{done} == 0)
      {

      # take current from stack 
      my ($xl,$yl,$xr,$yr,$level) = @{ shift @{$self->{stack}} };
      #print "Now at level $level, $xl, $yl => $xr, $yr\n";
      my $w = ($xr-$xl);
      my $h = ($yr-$yl);
    
      # check that the rectangle has all the same border color around
      # if yes, fill it and be done with it
      my $border = $cache->[$xl]->[$yl];
      my $same = 0;
      for my $x ($xl .. $xr)
        {
        $same++, last if $cache->[$x]->[$yl] != $border;
        $same++, last if $cache->[$x]->[$yr] != $border;
        }
      if ($same == 0)
        {
        # hm, upper/lower borders were the same, so check left/right
        for my $y ($yl+1 .. $yr-1)
          {
          $same++, last if $cache->[$xl]->[$y] != $border;
          $same++, last if $cache->[$xr]->[$y] != $border;
          }
        # all the same
        if ($same == 0)
          {
          # skip blacks
          if ($border != 0)
            {
            # color it and stop dividing it
            my $c = new SDL::Color (
               -r => $border & 0xff,
               -g => $border & 0xff,
               -b => (128 + $border) & 0xff);
            $rect->x($xl+1);
            $rect->y($yl+1);
            $rect->width($w-1);
            $rect->height($h-1);
            $self->app()->fill($rect,$c);
            }
          next RECTANGLE;			# done with that
          }
        }
      # nope, border did not have the same colors, so "do" rectangle 
      # if to small, compute it iteratively
      if (($w < 6) || ($h < 6))
        {
        #print "too small $xl, $yl => $xr, $yr\n";
        for (my $x = $xl+1; $x < $xr; $x++)
          {
          for (my $y = $yl+1; $y < $yr-1; $y++)
            {
            $self->_mandel_draw_point($x,$y, $self->_mandel_point($x,$y) );
            }
          }
        }
      else
        {
        # accoring to level (odd/even) divide it horizontal or vertically
        if (($level & 1) == 0)
          {
          # store the current line we do
          $self->{sy} = $yl;
          $self->{sy2} = $yr; 
          $self->{sx} = int($xl+$w/2);
          # divide vertically, and put both up the stack
          push @{$self->{stack}}, [$xl,$yl,$self->{sx},$yr,$level+1];
          push @{$self->{stack}}, [$self->{sx},$yl,$xr,$yr,$level+1];
          }
        else
          {
          # store the current line we do
          $self->{sy} = int($yl+$h/2);
          $self->{sx} = $xl; 
          $self->{sx2} = $xr; 
          # divide hoizontal, and put both up the stack
          push @{$self->{stack}}, [$xl,$yl,$xr,$self->{sy},$level+1];
          push @{$self->{stack}}, [$xl,$self->{sy},$xr,$yr,$level+1];
          }
        }
      $self->{done} = 1;		# flag that we already divided 
      }
    last if scalar @{ $self->{stack} } == 0;		# all done ?
    # we divided, and have still to do the line between the halves
    # access current rectangle
    my ($xl,$yl,$xr,$yr,$level) = @{ $self->{stack}->[-1] };
    if (($level & 1) != 0)
      {
      my $x = $self->{sx};
      $self->{sy}++;
      do 
        {
        $self->_mandel_draw_point($x,$self->{sy},
         $cache->[$x]->[$self->{sy}] =
          $self->_mandel_point($x,$self->{sy}) );
        } while ($self->{sy}++ < $self->{sy2});
      $self->{done} = 0;		# next comes divide
      }
    else
      {
      my $y = $self->{sy};
      $self->{sx}++;
      do 
        {
        $self->_mandel_draw_point($self->{sx}, $y,
         $cache->[$self->{sx}]->[$y] =
          $self->_mandel_point($self->{sx},$y) );
        } while ($self->{sx}++ < $self->{sx2});
      $self->{done} = 0;		# next comes divide
      }
    return if ($self->app()->ticks() - $now > 150);
    }
  print " (points drawn $self->{points})\n";
  print "Took ",int(($self->app()->ticks - $self->{start}) / 10)/100,
   " seconds\n";
  $self->{points} = 0;
  $self->{state} = 3;		# all done
  }

sub _mandel_draw_point
  {
  my ($self,$x,$y,$color) = @_;

  $self->{points}++;
  return if $color == 0;		# black
  my $c = new SDL::Color (
    -r => $color & 0xff, -g => $color & 0xff, -b => (128 + $color) & 0xff);

  # XXX: Does not work
  #my $r = $self->{rect};
  #$self->{rect}->x($x);
  #$self->{rect}->y($y);
  #$self->{app}->fill($self->{rect},$c);

  # XXX: wrong colors and crashes if bpp==32: 
  # $self->{app}->pixel($x,$y,$c);
   
  # XXX does also not work and crash 
  #my $r = $color & 0xff; my $g = $color & 0xff; my $b = (128 + $color) & 0xff;
  #$self->{app}->pixel($x,$y, (int($r) << 16) + (int($g) << 8) + int($b));

  # XXX does also not work:
  #$self->{app}->pixel($x,$y, $c->pixel());

  # works, but slow
  my $r = SDL::Rect->new( -x => $x, -y => $y, -width => 1, -height => 1);
  $self->{app}->fill($r,$c);
  }

sub _mandel_iterative
  {
  # this routine calculates the all points in the mandelbrot fractal in a step
  # by step manner. It stops after at elast 150 ms
  my $self = shift;

  return if $self->{state} != 1;

  my $r = $self->{rect}; 
  #SDL::Rect->new( -x => 0, -y => 0, -width => 1, -height => 1);
  my $now = $self->app()->ticks();
  my $w = $self->{width};
  my $h = $self->{height};
  my $app = $self->{app};

  my $lastcolor = 0; my $c = $self->{black};
  do
    {
    my $y = $self->{y};
    do
      {
      my $x = $self->{x};
      my $color = $self->_mandel_point($x,$y);
      $r->x($x);
      $r->y($y);
      if ($color != 0)
        {
        if ($lastcolor != $color)
	  {
          $c = new SDL::Color (
           -r => $color & 0xff,
           -g => $color & 0xff,
           -b => (128 + $color) & 0xff);
          }
        $app->fill($r,$c);
        $lastcolor = $color;
        }
      return if ($self->app()->ticks() - $now > 150);
      } while (++$self->{x} < $w);
    $self->{x} = 0;
    } while (++$self->{y} < $h);
  print "Took ",int(($self->app()->ticks - $self->{start}) / 10)/100,
   " seconds\n" if $self->{state} != 2;
  $self->{state} = 2;		# all done
  }

sub _mandel_point
  {
  # calculate the mandelbrot fractal at one point
  my ($self,$x,$y) = @_;

  my $x1 = $self->{x1}; 
  my $x2 = $self->{x2};
  my $y1 = $self->{y1};
  my $y2 = $self->{y2};

  # setup start parameters
  my $ca = $x1 + $x * ($x2 - $x1) / $self->{width};
  my $cb = $y1 + $y * ($y2 - $y1) / $self->{height};
  my $za = 0;
  my $zb = 0;

  my $iter = 0; my ($za1,$zb1);
  my $max_iter = $self->{max_iter};
  while ($iter++ < $max_iter)
    {
    $za1 = $za * $za - $zb * $zb + $ca;
    $zb = 2 * $za * $zb + $cb;
    $za = $za1;
    return $iter if $za * $za + $zb * $zb > 5;
    }
  return 0;
  }

sub _mandel_setup
  {
  # setup the calculation to start all over
  my $self = shift;

  $self->{width} = $self->width();
  $self->{height} = $self->height();
  $self->{x1} = -2.2; 
  $self->{x2} = +1;
  $self->{y1} = -1.1;
  $self->{y2} = +1.1;
  $self->{x} = 0;
  $self->{y} = 0;
  $self->{state} = 1;
  $self->{start} = $self->now();
  $self->{max_iter} = 600;
  # for recursive:
  $self->{done} = 0;
  $self->{stack} = [];
  $self->{cache} = [ ];
  $self->{rect} = SDL::Rect->new( -x => 0, -y => 0, -width => 1, -height => 1);
  for my $i (0..$self->{width})
    {
    $self->{cache}->[$i] = [];
    }
  }

sub draw_frame
  {
  # draw one frame, usually overrriden in a subclass.
  my ($self,$current_time,$lastframe_time,$current_fps) = @_;

  # using pause() would be a bit more efficient, though 
  return if $self->time_is_frozen();

  # draw a bit (wit iterative or recursive method)
  &{$self->{method}}($self);

  $self->_update(); 
  }

sub _update
  {
  my $self = shift;
  # update the screen with the changes
  my $rect = SDL::Rect->new(
   -width => $self->{width}, -height => $self->{height});
  $self->app()->update($rect);
  }

sub post_init_handler
  {
  my $self = shift;
 
  $self->{black} = new SDL::Color (-r => 0, -g => 0, -b => 0);

  $SDL::DEBUG = 0;  			# disable debug, it slows us down
  $self->_mandel_setup();
  $self->{method} = \&_mandel_iterative;

  $self->{app} = $self->app();

  # state 0 => start calc
  # state 1 => in calc
  # state 2 => done

  # set up the event handlers

  # create a group for events that are active in state 1, one for state 2
  # and one for event handlers that are always active (like QUIT)
  for my $state (1..2)
    {
    $self->{demo}->{group}->{$state} = $self->add_group();
    }
  $self->{demo}->{group_all} = $self->add_group();

  # setup the event handlers that are always active
  my $group = $self->{demo}->{group_all};

  $group->add(
    $self->add_event_handler (SDL_KEYDOWN, SDLK_q, 
     sub { my $self = shift; $self->quit(); }),
  
    $self->add_event_handler (SDL_KEYDOWN, SDLK_f, 
     sub { my $self = shift; $self->fullscreen(); }),
    
    $self->add_event_handler (SDL_KEYDOWN, SDLK_s, 
     sub { my $self = shift; $self->_mandel_setup(); }),

    $self->add_event_handler (SDL_KEYDOWN, SDLK_1, 
     sub {
      my $self = shift; $self->{method} = \&_mandel_iterative;
      $self->_mandel_reset();
      }),
    
    $self->add_event_handler (SDL_KEYDOWN, SDLK_2,
     sub {
       my $self = shift; $self->{method} = \&_mandel_recursive;
       $self->{sub_method} = 1;
       $self->_mandel_reset();
       }),

    $self->add_event_handler (SDL_KEYDOWN, SDLK_3,
     sub {
       my $self = shift; $self->{method} = \&_mandel_recursive;
       $self->{sub_method} = 2;
       $self->_mandel_reset();
       }),

    $self->add_event_handler (SDL_MOUSEBUTTONDOWN, LEFTMOUSEBUTTON, 
     \&_mandel_zoom, 5),
    $self->add_event_handler (SDL_MOUSEBUTTONDOWN, RIGHTMOUSEBUTTON, 
     \&_mandel_zoom, 1/5),

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
      }),
    );
  }
       
sub _mandel_reset
  {
  my $self = shift;
  $self->{x} = 0;
  $self->{y} = 0;
  $self->{state} = 1;
  $self->{start} = $self->now();
  $self->{done} = 0;
  $self->{stack} = [];
  $self->{cache} = [ ];
  my $rect = SDL::Rect->new(
   -width => $self->{width}, -height => $self->{height});
  $self->app()->fill($rect,$self->{black});
  for my $i (0..$self->{width})
    {
    $self->{cache}->[$i] = [];
    }
  }

sub _mandel_zoom
  {
  my ($self,$handler,$event,$factor) = @_;
  $self->_mandel_reset();

  # figure out where mouse has hit
  my $xm = $event->motion_x(); 
  my $ym = $event->motion_y();
  my $xs = ($self->{x2} - $self->{x1}) / $self->{width};
  my $ys = ($self->{y2} - $self->{y1}) / $self->{height};
  my $xc = $self->{x1} + $xs * $xm;
  my $yc = $self->{y1} + $ys * $ym;
  if ($factor > 1)
    {
    # zooming in, so calculate a bit further
    $self->{max_iter} += 100;
    }
  else
    {
    # zooming out, so step back
    $self->{max_iter} -= 100;
    }
  $factor *= 2;
  $xs = ($self->{x2} - $self->{x1});
  $ys = ($self->{y2} - $self->{y1});
  $self->{x1} = $xc - $xs / $factor;
  $self->{x2} = $xc + $xs / $factor;
  $self->{y1} = $yc - $ys / $factor;
  $self->{y2} = $yc + $ys / $factor;
  }

1;

__END__

