
# base class for SDL Perl applications that have a non-constant framerate
# can monitor framerate, cap it, and also has interleaved event-handling

package SDL::App::FPS;

# (C) by Tels <http://bloodgate.com/>

use strict;

use SDL;
use SDL::App;
use SDL::Event;

use SDL::App::FPS::Timer;
use SDL::App::FPS::EventHandler;

require DynaLoader;
require Exporter;

use vars qw/@ISA $VERSION/;
@ISA = qw/Exporter DynaLoader/;

$VERSION = '0.08';

bootstrap SDL::App::FPS $VERSION;

##############################################################################

sub new
  {
  # create a new instance of SDL::App::FPS
  my $class = shift;
  my $self = {}; bless $self, $class;

  $self->_init(@_);			# parse options
  $self->pre_init_handler();
  $self->create_window();
  
  $self->{now} = SDL::GetTicks();
  $self->{start_time} = $self->{now};		# for time_warp
  $self->{current_time} = $self->{now};		# warped clock (current frame)
  $self->{lastframe_time} = $self->{now};	# warped clock (last frame)
  $self->{lastframes} = [ $self->{now} ];

  $self->post_init_handler();

  $self;
  }

sub _init
  {
  my $self = shift;

  my $args;
  if (ref($_[0]) eq 'HASH')
    {
    $args = shift;
    }
  else
    {
    $args = { @_ };
    }
  $self->{options} = {};
  my $opt = $self->{options};
  foreach my $key (keys %$args)
    {
    $opt->{$key} = $args->{$key};
    }
  # set some sensible defaults
  my $def = {
    width => 800,
    height => 600,
    depth => 32,
    fullscreen => 0,
    max_fps => 60,
    cap_fps => 1,
    time_warp => 1,
    };
  foreach my $key (qw/width height depth fullscreen max_fps cap_fps time_warp/) 
    {
    $opt->{$key} = $def->{$key} unless exists $opt->{$key};
    }

  $self->{in_fullscreen} = 0;			# start windowed
  $self->fullscreen() if $opt->{fullscreen};	# switch to fullscreen
  
  # limit to some sensible value
  $opt->{max_fps} = 500 if $opt->{max_fps} > 500;
  $opt->{max_fps} = 1 if $opt->{max_fps} < 1;
  $opt->{max_fps} = 0 if $opt->{max_fps} < 0;		# disable cap
  $opt->{width} = 16 if $opt->{width} < 16;
  $opt->{height} = 16 if $opt->{height} < 16;
  $opt->{depth} = 8 if $opt->{depth} < 8;

  $self->{event} = SDL::Event->new();		# create an event handler

  $self->{time_warp} = $opt->{time_warp};	# copy to modify it later

  # setup the framerate monitoring
  $self->{min_time} = 1000 / $opt->{max_fps};
  # contains the FPS avaraged over the last second
  $self->{current_fps} = 0;
  $self->{min_fps} = 10000;			# insanely high to get lower
  $self->{max_fps} = 0;				# insanely low to get higher
  $self->{min_frame_time} = 10000; 		# how long per frame min?
  $self->{max_frame_time} = 0; 			# how long per frame max?
  $self->{wake_time} = 0;			# adjust for fps capping
  $self->{frames} = 0;				# number of frames
  $self->{fps_monitor_time} = 1000;		# 1 second (hardcode for now)
  $self->{ramp_warp_target} = 0;		# disable ramping
  $self->{ramp_warp_time} = 0;			# disable ramping
  
  $self->{timers} = {};				# none yet
  $self->{event_handler} = {};			# none yet

  $self->{next_timer_check} = 0;		# disable (always check)
  $self->{quit} = 0;				# don't let handle_events quit
  $self;
  }

sub option
  {
  # get/set a specific option as it was originally set 
  my $self = shift;
  my $key = shift;

  my $opt = $self->{options};
  if (@_ > 0)
    {
    $opt->{$key} = shift;
    if ($key eq 'max_fps')
      {
      $self->{min_time} = 1000 / $opt->{max_fps};
      $self->{wake_time} = 0;
      }
    if ($key eq 'fullscreen')
      {
      $self->{app}->fullscreen();
      }
    }
  return undef unless exists $opt->{$key};
  $opt->{$key};
  }

sub width
  {
  my $self = shift;
  return $self->{app}->width();
  }

sub height
  {
  my $self = shift;
  return $self->{app}->height();
  }

sub update
  {
  my $self = shift;
  return $self->{app}->update(@_);
  }

sub app
  {
  my $self = shift;
  return $self->{app};
  }

sub in_fullscreen
  {
  # returns true for in fullscreen, false for in window
  my $self = shift;

  $self->{in_fullscreen};
  }

sub fullscreen
  {
  # toggle the application into and out of fullscreen
  # if given an argument, and this is true, switches to fullscreen
  # if given an argument, and this is fals, switches to windowed
  # returns true for in fullscreen, false for in window
  my $self = shift;

  if (@_ > 0)
    {
    my $t = shift || 0; $t = 1 if $t != 0;
    return $self->{in_fullscreen} if ($t == $self->{in_fullscreen});
    }
  $self->{in_fullscreen} = 1 - $self->{in_fullscreen};	# toggle
  $self->{app}->fullscreen();				# switch
  $self->{in_fullscreen};
  }

sub create_window
  {
  my $self = shift;

  my @opt = ();
  foreach my $k (qw/width height depth/)
    {
    push @opt, "-$k", $self->{$k};
    }
  $self->{app} = SDL::App->new( @opt );
  $self->fullscreen() if $self->{options}->{fullscreen};
  $self;
  }
	
sub stop_time_warp_ramp
  {
  # disable time warp ramping when it is in progress (otherwise does nothing)
  my $self = shift;
  $self->{ramp_warp_time} = 0;
  }

sub freeze_time
  {
  # stop the waped clock (by simple setting time_warp to 0)
  my $self = shift;

  $self->{time_warp_frozen} = $self->{time_warp};
  $self->{time_warp} = 0;
  # disable ramping
  $self->{ramp_warp_time} = 0;
  }

sub time_is_frozen
  {
  # return true if the time is currently frozen
  my $self = shift;

  return $self->{time_warp} == 0;
  }

sub time_is_ramping
  {
  # return true if the time warp is currently ramping (changing)
  my $self = shift;

  return $self->{ramp_warp_time} != 0;
  }

sub thaw_time
  {
  # reset the time warp to what it was before unfreeze_time() was called, thus
  # re-enabling the clock. Does nothing when the clock is not frozen.
  my $self = shift;

  return if $self->{time_warp} != 0;
  $self->{time_warp} = $self->{time_warp_frozen};
  # disable ramping
  $self->{ramp_warp_time} = 0;
  }

sub ramp_time_warp
  {
  # $target_factor,$time_to_ramp
  my $self = shift;

  if (@_ == 0)
    {
    if ($self->{ramp_warp_time} == 0)	# ramp in effect?
      {
      return;				# no
      }
    else
      {
      return 
       ($self->{ramp_warp_target}, $self->{ramp_warp_time}, 
        $self->{time_warp}, $self->{ramp_warp_startwarp},
        $self->{ramp_warp_startime});
      }
    }
  # if target warp is already set, don't do anything
  return if $self->{time_warp} == $_[0];
 
  # else setup a new ramp
  ($self->{ramp_warp_target}, $self->{ramp_warp_time}) = @_;
  $self->{ramp_warp_time} = abs(int($self->{ramp_warp_time})); 
  $self->{ramp_warp_startwarp} = $self->{time_warp};
  $self->{ramp_warp_starttime} = $self->{now};
  $self->{ramp_warp_endtime} = $self->{now} + $self->{ramp_warp_time};
  $self->{ramp_warp_factor_diff} = 
   $self->{ramp_warp_target} - $self->{time_warp};
  }

sub _ramp_time_warp
  {
  # do the actual ramping by computing a new time warp at start of frame
  my $self = shift;

  # no ramping in effect?
  return if $self->{ramp_warp_time} == 0;

  # if we passed the end time, stop ramping
  if ($self->{now} >= $self->{ramp_warp_endtime})
    {
    $self->{ramp_warp_time} = 0;
    $self->{time_warp} = $self->{ramp_warp_target};
    }
  else
    {
    # calculate the difference between now and the start ramp time
    # 600 ms from 1000 ms elapsed, diff is 2, so we have 2 * 600 / 1000 => 1.2
    $self->{time_warp} = 
     $self->{ramp_warp_startwarp} + 
      ($self->{now} - $self->{ramp_warp_starttime}) *
       $self->{ramp_warp_factor_diff} / $self->{ramp_warp_time}; 
    }
  }

sub time_warp
  {
  # get/set the current time_warp, e.g. the factor how fast the time passes
  # the time_warp will be effective from the next frame onwards
  my $self = shift;

  if (@_ > 0)
    {
    $self->{time_warp} = shift;
    $self->{ramp_warp_target} = 0;		# disable ramping
    $self->{ramp_warp_time} = 0;		# disable ramping
    }
  $self->{time_warp};
  }

sub start_time
  {
  # get the time when the app started in ticks
  my $self = shift;
  
  $self->{start_time};
  }

sub current_fps
  {
  # return current number of frames per second, averaged over the last 1000ms
  my $self = shift;

  $self->{current_fps};
  }

sub min_fps
  {
  # return minimum fps we ever achieved
  my $self = shift;

  $self->{min_fps};
  }

sub max_fps
  {
  # return maximum fps we ever achieved
  my $self = shift;

  $self->{max_fps};
  }

sub max_frame_time
  {
  # return maximum time per frame ever
  my $self = shift;

  $self->{max_frame_time};
  }

sub min_frame_time
  {
  # return minimum time per frame ever
  my $self = shift;

  $self->{min_frame_time};
  }

sub frames
  {
  # return number of frames already drawn
  my $self = shift;

  $self->{frames};
  }

sub now
  {
  # return current time at the start of the frame in ticks, unwarped.
  my $self = shift;

  $self->{now};
  }

sub current_time
  {
  # return current time at the start of the frame. This time will be warped
  # by time_warp, e.g a time_warp of 2 makes it go twice as fast as now().
  # Note that the returned value will only change at the start of each frame.
  my $self = shift;

  $self->{current_time};
  }

sub lastframe_time
  {
  # return time at the start of the last frame. See current_time().
  my $self = shift;

  $self->{lastframe_time};
  }

sub next_frame
  {
  my $self = shift;
  
  $self->{frames}++;				# one more
 
  # get current time at start of frame, and wait a bit if we are too fast
  my $diff; 
  ($self->{now},$diff,$self->{wake_time}) = 
    _delay($self->{lastframes}->[-1],$self->{min_time},$self->{wake_time});

  # advance our clock warped by time_warp
  $self->{current_time} =
    $self->{time_warp} * $diff + $self->{lastframe_time};
  $self->_ramp_time_warp() if $self->{ramp_warp_time} != 0;

  # remember $now
  push @{$self->{lastframes}}, $self->{now};
  # track min/max time between two frames
  $self->{min_frame_time} = $diff 
   if $diff < $self->{min_frame_time}; 
  $self->{max_frame_time} = $diff 
   if $diff > $self->{max_frame_time}; 

  # keep only frame times over the last X milliseconds
  while ($self->{lastframes}->[0] < ($self->{now} - $self->{fps_monitor_time}))
    {
    shift @{$self->{lastframes}};		# remove one
    }

  # calculate current_fps
  my $time = $self->{now} - $self->{lastframes}->[0] + 1;
  $self->{current_fps} = 1000 * scalar @{$self->{lastframes}} / $time;
  # update these timers only when the time to track the framerate was long
  # enough to make sense
  if ($time > 850)
    {
    $self->{min_fps} = $self->{current_fps} if
     $self->{current_fps} < $self->{min_fps}; 
    $self->{max_fps} = $self->{current_fps} if
     $self->{current_fps} > $self->{max_fps}; 
    }

  # now do something that takes time, like updating the world and drawing it
  $self->draw_frame(
   $self->{current_time},$self->{lastframe_time},$self->{current_fps});

  $self->{lastframe_time} = $self->{current_time};
  }  

sub handle_events
  {
  # handle all events (actually, only handles SDL_QUIT event=, return true if
  # SDL_QUIT occured, otherwise false
  my $self = shift;

  my $done = 0;
  my $event = $self->{event};
  # inner while to handle all events, not only one per frame
  while ($event->poll())			# got one event?
    {
    return 1 if $event->type() == SDL_QUIT;	# check this first
    # check event with all registered event handlers
    # TODO: group event handlers on type, and let event only be checked
    # by the appropriate handlers for speed
    foreach my $id (keys %{$self->{event_handler}})
      {
      $self->{event_handler}->{$id}->check($event);
      }
    }
  $done += $self->{quit};	# if an event handler set it, terminate
  }

sub quit
  {
  # can be called to quit the application
  my $self = shift;

  $self->{quit} = 1;		# make next handle_events quit
  }

sub pause
  {
  # can be called to let the application to wait for the next event
  my $self = shift;

  if (@_ == 0)
    {
    $self->{event}->wait();
    $self->handle_event($self->{event});	# give handler a chance
    }
  else
    {
    my $type;
    while ($self->{event}->wait())
      {
      $type = $self->{event}->type();
      if ($type == SDL_QUIT)			# don't ignore this one
        {
        $self->{quit} = 1; last;		# quit ASAP
        }
      foreach my $t (@_)
        {
        if ($t == $type)
          {
          $self->handle_event($self->{event});	# give handler a chance
          return;
          }
        }
      }
    }
  }

sub main_loop
  {
  my $self = shift;

  # TODO:
  # don't call handle_events() when there are no events? Does this matter?
  while (!$self->{quit} && $self->handle_events() == 0)
    {
    if (scalar keys %{$self->{timers}} > 0)			# no timers?
      {
      if ($self->{time_warp} > 0)
        {
        $self->expire_timers() 
         if (($self->{next_timer_check} == 0) ||
            ($self->{current_time} >= $self->{next_timer_check}));
        }
      else
        {
        $self->expire_timers() 
         if (($self->{next_timer_check} == 0) ||
           ($self->{current_time} <= $self->{next_timer_check}));
       }
      }
    $self->next_frame();		# update the screen and fps monitor
    }
  $self->quit_handler();
  }

##############################################################################
# timer stuff

sub add_timer
  {
  # add a timer to the list of timers
  # The timer fires the first time after $time ms, then after each $delay ms
  # for $count times. $count < 0 means fires infinity times. $callback must
  # be a coderef, which will be called when the timer fires
  my $self = shift;
  my ($time, $count, $delay, $rand, $callback, @args) = @_;

  my $timer = SDL::App::FPS::Timer->new( 
    $time, $count, $delay, $rand, $self->{current_time}, $callback,
    $self, @args);
  return undef if $timer->count() == 0;		# timer fired once, and expired

  # otherwise remember it
  $self->{timers}->{$timer->{id}} = $timer;
  $self->{next_timer_check} = 0;		# disable (always check)
  $self->{timer_modified} = 1;
  # return it's id
  $timer->{id};
  }

sub expire_timers
  {
  # check all timers for whether they have expired (need to fire) or not
  my $self = shift;

  return 0 if scalar keys %{$self->{timers}} == 0;	# no timers?
  return 0 if $self->{time_warp} == 0;			# time stand still

  $self->{timer_modified} = 0;				# track add/del
  my $now = $self->{current_time};			# timers are warped
  my $time_warp = $self->{time_warp};			# timers are warped
  foreach my $id (keys %{$self->{timers}})
    {
    my $timer = $self->{timers}->{$id};
    $timer->due($now,$time_warp);			# let timer fire
    # remember nearest time to fire a time
    if ($self->{time_warp} > 0)
      {
      $self->{next_timer_check} = $timer->{next_shot}
        if $timer->{next_shot} < $self->{next_timer_check} ||
         $self->{next_timer_check} == 0;
      }
    else
      {
      $self->{next_timer_check} = $timer->{next_shot}
        if $timer->{next_shot} > $self->{next_timer_check} ||
         $self->{next_timer_check} == 0;
      }
   $self->{timer_modified} = 1 && delete $self->{timers}->{$id}
     if $timer->count() == 0;				# remove any expired
    }
  $self->{next_timer_check} = 0			# disable (always check)
   if $self->{timer_modified} != 0;	
  }

sub timers
  {
  # return amount of still active timers 
  my $self = shift;

  return scalar keys %{$self->{timers}};
  }

sub get_timer
  {
  # return ptr to a timer with id $id
  my ($self,$id) = @_;

  return unless exists $self->{timers}->{$id};
  $self->{timers}->{$id};
  }

sub del_timer
  {
  # delete a timer with a specific id
  my ($self,$id) = @_;

  $id = $id->{id} if ref($id) eq 'SDL::App::FPS::Timer';

  $self->{next_timer_check} = 0;		# disable (always check)
  $self->{timer_modified} = 1;
  delete $self->{timers}->{$id};
  }

##############################################################################
# event handling stuff

sub add_event_handler
  {
  # add an event handler
  my ($self,$type,$kind,$callback) = @_;

  my $handler = SDL::App::FPS::EventHandler->new($type,$kind,$callback,$self);

  $self->{event_handler}->{$handler->{id}} = $handler;
  }

sub del_event_handler
  {
  my ($self,$handler) = @_;

  delete $self->{event_handler}->{$handler->{id}};
  }

##############################################################################
# routines that are usually overriden in a subclass

sub draw_frame
  {
  # draw one frame, usually overrriden in a subclass. If necc., this might
  # call $self->handle_event().
  my ($self,$current_time,$lastframe_time,$current_fps) = @_;
 
  $self; 
  }

sub post_init_handler
  {
  $_[0];
  }

sub pre_init_handler
  {
  $_[0];
  }

sub quit_handler
  {
  $_[0];
  }

1;

__END__

=pod

=head1 NAME

SDL::App::FPS - a parent class for FPS (framerate centric) applications

=head1 SYNOPSIS

Subclass SDL::App::FPS and override some methods:

	package SDL::App::MyFPS;
	use Exporter;
	use strict;
	use SDL::App::FPS;
	use SDL::Event;

	use vars qw/@ISA/;
	@ISA = qw/SDL::App::FPS/;

        # override the method draw_frame with something to draw
	sub draw_frame
          {
	  my ($self,$current_time,$lastframe_time,$current_fps) = @_;
          }

        # override post_init_handler and add some event handlers
	sub post_init_handler
	  {
	  my ($self} = shift;

	  my $self->add_event_handler(SDL_KEYDOWN, SDLK_q, sub
            {
            my $self = shift; $self->quit();
            } );
	  }

Then write a small script using SDL::App::MyFPS like this:

	#!/usr/bin/perl -w
	
	use strict;
	use SDL::App::MyFPS;

	# fill in here options or use Getopt::Long for command line
	my $options = { };

	my $app = SDL::App::MyFPS->new( $options );
	$app->main_loop();

That's all!

=head1 DESCRIPTION

This package provides you with a base class to write your own SDL Perl
applications.

=head2 The Why

When building a game or screensaver displaying some continously running
animation, a couple of basics need to be done to get a smooth animation and
to care of copying with varying speeds of the system. Ideally, the animation
displayed should be always the same, no matter how fast the system is.

This not only includes different systems (a PS/2 for instance would be slower
than a 3 Ghz PC system), but also changes in the speed of the system over
time, for instance when a background process uses some CPU time or the
complexity of the scene changes.

In many old (especial DOS) games, like the famous Wing Commander series, the
animation would be drawn simple as fast as the system could, meaning that if
you would try to play such a game on a modern machine it we end before you
had the chance to click a button, simple because it wizzes a couple 10,000
frames per second past your screen.

While it is quite simple to restrict the maximum framerate possible, care
must be taken to not just "burn" surplus CPU cycles. Instead the application
should free the CPU whenever possible and give other applications/thread
a chance to run. This is especially important for low-priority applications
like screensavers.

C<SDL::App::FPS> makes this possible for you without you needing to worry
about how this is done. It will restrict the frame rate to a possible maximum
and tries to achive the average framerate as close as possible to this
maximum.
 
C<SDL::App::FPS> also monitors the average framerate and gives you access
to this value, so that you can, for instance, adjust the scene complexity
based on the current framerate. You can access the current framerate,
averaged over the last second (1000 ms) by calling L<current_fps>.

=head2 Frame-rate Independend Clock

Now that our application is drawing frames (via the method L<draw_frame>,
which you should override in a subclass), we need a method to decouple the
animation speed from the framerate.

If we would simple put put an animation step every frame, we would get some
sort of Death of the Fast Machine" effect ala Wing Commander. E.g. if the
system manages only 10 FPS, the animation would be slower than when we do
60 FPS.

To achive this, C<SDL::App::FPS> features a clock, which runs independed of
the current frame rate (and actually, independend of the system's clock, but
more on this in the next section).

You can access it via a call to L<current_time>, and it will return the ticks
e.g. the number of milliseconds elapsed since the start of the application.

To effectively decouple animation speed from FPS, get at each frame the
current time, then move all objects (or animation sequences) according to
their speed and display them at the location that matches the time at the
start of the frame. See examples/ for an example on how to do this.

Note that it is better to draw all objects according to the time at the start
of the frame, and not according to the time when you draw a particular object.
Or in other words, treat the time like it is standing still when drawing a
complete frame. Thus each frame becomes a snapshot in time, and you don't get
nasty sideeffects like one object beeing always "behind" the others just
because it get's drawn earlier.

=head2 Time Warp

Now that we have a constant animation speed independend from framerate
or system speed, let's have some fun.

Since all our animation steps are coupled to the current time, we can play
tricks with the current time.

The function L<time_warp> let's you access a time warp factor. The default is
1.0, but you can set it to any value you like. If you set it, for instance to
0.5, the time will pass only half as fast as it used to be. This means
instant slow motion! And when you really based all your animation on the
current time, as you should, then it will really slow down your entire
application to a crawl.

Likewise a time warp of 2 let's the time pass twice as fast. There are
virtually no restrictions to the time warp.

For instance, a time warp greater than one let's the player pass boring
moments in a game, for instance when you need to wait for certain events in
a strategy game, like your factory beeing completed.

Try to press the left (fast forward), right (slow motion) and middle (normal)
mousebuttons in the example application and watch the effect.

If you are very bored, press the 'b' key and see that even negative time warps
are possible...

=head2 Ramping Time Warp

Now, setting the time war to factor of N is nice, but sometimes you want to
make dramatic effects, like slowly freezing the time into ultra slow motion
or speeding it up again.

For this, L<ramp_time_warp> can be used. You give it a time warp factor you
want to reach, and a time (based on real time, not the warped, but you can
of course change this). Over the course of the time you specified, the time
warp factor will be adapted until it reaches the new value. This means it
is possible to slowly speeding up or down.

You can also check whether the time warp is constant of currently ramping
by using L<time_is_ramping>. When a ramp is in effect, call L<ramp_time_warp>
without arguments to get the current parameters. See below for details.

The example application uses the ramping effect instead instant time warp.

=head2 Event handlers

This section describes events as external events that typically happen due
to user intervention.

Such events are keypresses, mouse movement, mouse button presses, or just
the flipping of the power switch. Of course the last event cannot be handled
in a sane way by our framework :)

All the events are checked and handled by SDL::App::FPS automatically. The
event SDL_QUIT (which denotes that the application should shut down) is also
carried out automatically. If you want to do some tidying up when this
happens, override the method L<quit_handler>.

The event checking and handling is done at the start of each frame. This
means no event will happen while you draw the current frame. Well, it will
happen, but the action caused by that event will delayed until the next
frame starts. This simplifies the frame drawing routine tremendously, since
you know that your world will be static until the next frame.

To associate an event with an action, you use the L<add_event_handler> method.
This method get's an event kind (like SDL_KEYDOWN or MOUSEBUTTONDOWN) and an
event type (like SDLL_SPACE). When this specific event is encountered, the
also given callback routine is called. In the simplest form, this would be
an anonymous subroutine. Here is an example:

	my $handler = $app->add_event_handler ( SDL_KEYDOWN, SDLK_SPACE, sub {
	  my ($self) = shift;
	  $self->pause();
	} );

This would pause the game when the space key (you know, the one also known
as "any key" or "that longish bar at the bottom") is pressed.

You can easily reconfigure the event to trigger for a different key like this:
	
	$handler->rebind( SDL_KEYDOWN, SDLK_p );

If you want the same event to be triggered by different external events, then
simple add another event:

	my $handler2 = $app->add_event_handler ( SDL_KEYDOWN, SDLK_P, sub {
	  my ($self) = shift;
	  $self->pause();
	} );

This would also alow the user to pause with 'P'.

Event bindings can also be removed with L<del_event_handler()>, if so desired.

See L<add_event_handler()> for more details.

=head2 Timers

Of course not always should all things happen instantly. Sometimes you need
to delay some events or have them happening at regular or irregular
intervalls again.

For these cases, C<SDL::App::FPS> features timers. These timers are different
from the normal SDL::Timers in that they run in the application clock space,
e.g. the time warp effects them. So if you application is in slow motion,
the events triggers by the timers will still happen at the correct time.


=head1 SUBCLASSING

It is a good idea to store additional data under C<$self->{name_of_subclass}>,
this way it does not interfere with changes in the base class.

Also, when adding subroutines to your subclass, prefix them with '__' so that
they do not interfere with changes in this base class.

Do not access the data in the baseclass directly, always use the accessor
methods!

=head1 METHODS

The following methods should be overridden to make a usefull application:

=over 2

=item draw_frame()

Responsible for drawing the current frame. It's first two parameters, the
time (in ticks) at the start of the current frame, and the time at the
start of the last frame. These times are warped according to C<time_warp()>,
see there for an explanation on how this works.

The third parameter is the current framerate, averaged. You can use this to
reduce dynamically the complexity of the scene to achieve a faster FPS if it
falls below a certain threshold.

=item handle_event()

Responsible for handling a single event. Gets one parameter, C<$event>, the
SDL::Event object. Check the event type with $event->type() and then take
the appropriate action.

Should return 1 to quit the application (if necc.), and 0 to keep it running.

=back

The following methods can be overriden if so desired:

=over 2

=item pre_init_handler()

Called by L<new()> just before the creating the SDL application and window.

=item post_init_handler()

Called by L<new()> just after the creating the SDL application and window.

=item quit_handler()

Called by L<main_loop()> just before the application is exiting.

=back

The following methods can be used, but need not be overriden except in very
special cases:

=over 2

=item new()

	$app = SDL::App::FSL->new($options);

Create a new application, init the SDL subsystem, create a window, starts
the frame rate monitoring and the application time-warped clock.

Get's a hash ref with options, the following options are supported:

	width     the width of the application window in pixel
	height    the width of the application window in pixel
	depth     the depth of the screen (colorspace) in bits
	max_fps   maximum number of FPS to do (save CPU cycles)
	cap_fps   use a better model to cap the FPS to the desired
		  rate (default), set to 0 to disable - but you don't want
                  to do this - trust me)

Please note that to the resulution of the timer the maximum achivable FPS
with capping is about 200 FPS even with an empty draw routine. Of course,
my machine could do about 50000 FPS; but then it hogs 100% of the CPU. Thus
the framerate capping might not be accurate and cap the rate at a much lower
rate than you want. However, only max_fps > 100 is affected, anything below
100 works usually as intended.

C<new()> calls L<pre_init_handler()> before creating the SDL application, and
L<post_init_handler()> afterwards. So you can override thess two for your own
desires.

=item quit()

Set a flag to quit the application at the end of the current frame. Can be
called in L<draw_frame()>, for instance.

=item pause()

	$app->pause();
	$app->pause(SDL_KEYDOWN);

Pauses the application until the next event occurs. Given an optional event
type (like SDL_KEYDOWN), it will wait until this event happens. All
other events will be ignored, with the exception of SDL_QUIT.

=item fullscreen()

	$app->fullscreen();		# toggle
	$app->fullscreen(1);		# fullscreen
	$app->fullscreen(0);		# windowed

When called without arguments, toggles the application's fullscreen status.
When given an argument that is true, set's fullscreen mode, otherwise sets
windowed mode. Returns true when fullscreenmode was activated, otherwise
false. See L<is_fullscreen()>.

=item is_fullscreen()

	if ($app->is_fullscreen())
	  {
	  }

Retursn true if the application is currently in fullscreen mode.

=item width()

	my $w = $self->width();

Return the current width of the application's surface.

=item height()

	my $w = $self->height();

Return the current height of the application's surface.

=item update()

	$self->update($rect);

Call the SDL::App's update method.

=item add_timer()

	$app->add_timer($time,$count,$delay,$callback, @args ]);

Adds a timer to the list of timers. When time is 0, the timer fires
immidiately (calls $callback). When the count was 1, and time 0, then
the timer will not be added to the list (it already expired) and undef will be
returned. Otherwise the unique timer id will be returned.

C<@args> can be empty, otherwise the contents of these will be passed to the
callback function as additional parameters.

The timer will fire for the first time at C<$time> ms after the time it was
added, and then wait C<$delay> ms between each shot. if C<$count> is positive,
it gives the number of shots the timer fires, if it is negative, the timer
will fire endlessly until it is removed.

The timers added via add_timer() are coupled to the warped clock.

=item get_timer()

	$timer = $self->get_timer($timer_id);

Given a timer id, returns the timer object or undef.

=item del_timer()

	$app->del_timer($timer);
	$app->del_timer($timerid);
	
Delete the given timer (or the one by the given id).

=item timers()

Return count of active timers.

=item add_event_handler

        my $handler = SDL::App::FPS::EventHandler->new(
                $type,
                $kind,
                $callback
        );

Creates a new event handler to watch out for $type events (SDL_KEYDOWN,
SDL_MOUSEMOVED, SDL_MOUSEBUTTONDOWN etc) and then for $kind kind of it,
like SDLK_SPACE. Mouse movement events ignore the $kind parameter.

The created handler is added to the application.

See L<SDL::App::FPS::EventHandler::new()> for details.

=item del_event_handler

Delete an event handler from the application. 

=item app()

	my $sdl_app = $self->app();

Return a pointer to the SDL application object. Usefull for calling it's
methods.

=item option()

	print $app->option('max_fps'),"\n";	# get
	$app->option('max_fps',40);		# set to 40

Get/sets an option defined by the key (name) and an optional value.

=item freeze_time_warp_ramp()

	$app->freeze_time_warp_ramp();

Disables any ramping of the time warp that might be in effect.

=item freeze_time()

	$app->freeze_time();

Sets the time warp factor to 0, effectively stopping the warped clock. Note
that the real clock still ticks and frames are still drawn, so you can overlay
some menu/animation over a static (froozen in time) background. Of course it
might be more efficient to save the current drawn frame as image and stop
the drawing if the not-changing background altogether.

=item thaw_time()

	$app->thaw_time();

Sets the time warp factor back to what it was before L<freeze_time()> was
called. Does nothing when the clock is not frozen.

=item ramp_time_warp

	$app->ramp_time_warp($target_factor,$time_to_ramp);

Set a tagret time warp factor and a time it will take to get to this factor.
The time warp (see L<time_warp()>) will then be gradually adjusted to the
target factor. C<$time_to_ramp> is in ms (aka 1000 == one second).

It is sometimes a good idea to read out the current time warp and ramp it to
a specific factor, like so:

	$time_warp = $app->time_warp();
	$app->ramp_time_warp($time_warp * 2, 1000);

But you need to restrict this somehow, otherwise the clock might be speed up
or slowed down to insanely high or low speeds. So sometimes it is just better
to do this:

	sub enable_slow_motion
	  {
	  # no matter how fast clock now is, slow it down to a fixed value
	  $app->ramp_time_warp(0.5, 1000);
	  }

When ramp_time_warp() is called without arguments, and ramping is in effect,
it returns a list consisting of:

	target factor		# to where we ramp
	time to ramp		# how long it takes (ticks)
	current time warp	# where are currently
	start time warp		# from where we ramp (factor)
	start time warp time	# from where we ramp (real time ticks)

When no ramping is in effect, it returns an empty list or undef.

You can disable/stop the time warping by setting a new time warp factor
directly like so:

	my $t = $app->time_warp(); $app->time_warp($t);

Or easier:

	$app->freeze_time_warp();

=item time_warp

	$app->time_warp(2);		# fast forward

Get or set the current time warp, e.g. the factor how fast the time passes.
The new time warp will be effective from the next frame onwards.

Please note that setting a time warp factor will disable time warp ramping.

=item time_is_ramping

	if ($app->time_is_ramping())
	  {
	  }

Returns true if the time warp factor is currently beeing ramped, e.g. chaning.

=item time_is_frozen

	if ($app->time_is_frozen())
	  {
	  }

Return true if the time is currently frozen, e.g. the clock is standing still.

=item frames()

Return number of frames drawn since start of app. 

=item start_time()

Return the time when the application started in ticks.

=item current_fps()
  
Return current number of frames per second, averaged over the last 1000ms.

=item max_fps()
  
Return maximum number of frames per second we ever achieved.

=item min_fps()
  
Return minimum number of frames per second we ever achieved.

=item now()

Return current time at the start of the frame in ticks, unwarped. See
L<current_time> for a warped version. This is usefull for tracking the real
time clock as opposed to the warped application clock.

=item current_time()

Return current time at the start of this frame (the same as it is passed
to L<draw_frame()>. This time will be warped by time_warp, e.g a time_warp of
2 makes it go twice as fast as GetTicks(). Note that the returned value will
only change at the start of each frame.

=item lastframe_time()
  
Return time at the start of the last frame. See current_time(). The same value
is passed to L<draw_frame()>.

=back

The following routines are used internally and automatically, so you need not
to call them.

=over 2

=item create_window

Initialized the SDL subsysten and creates the window.

=item next_frame

Updates the FPS monitoring process, the frame counter, the average frame rate,
and then calls L<draw_frame()>.

=item handle_events()

Checks for events and hands all of them to L<event_handler> for user handling.
The only event it handles directly is SDL_QUIT. Returns 0 for keeping
the application running, and > 0 for quit.

=item main_loop()

	$app->main_loop();

The main loop of the application, only returns when an SDL_QUIT event occured,
or $self->quit() was called.

=item expire_timers()

Check all the timers for whether they are due ot not and let them fire.
Removes unnecc. timers from the list.

=back

=head1 AUTHORS

(c) Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<SDL::App> and L<SDL>.

=cut

