
# base class for SDL Perl applications that have a non-constant framerate
# can monitor framerate, cap it, and also has interleaved event-handling

package SDL::App::FPS;

# (C) by Tels <http://bloodgate.com/>

use strict;

use SDL;
use SDL::App;
use SDL::Event;

use SDL::App::FPS::Timer;

use Exporter;
use vars qw/@ISA $VERSION/;
@ISA = qw/Exporter/;

$VERSION = '0.04';

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
  
  # limit to some sensible value
  $opt->{max_fps} = 200 if $opt->{max_fps} > 200;
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

sub fullscreen
  {
  # toggle the application into and out of fullscreen
  my $self = shift;

  $self->{options}->{fullscreen} = !$self->{options}->{fullscreen};
  $self->{app}->fullscreen();
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
  # else setup a new ramping
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
  
  # get current time (in ticks)
  $self->{now} = SDL::GetTicks();

  $self->_ramp_time_warp() if $self->{ramp_warp_time} != 0;

  my $diff = $self->{now} - $self->{lastframes}->[-1];	# ticks between frames

  # advance our clock warped by time_warp
  $self->{current_time} =
    $self->{time_warp} * $diff + $self->{lastframe_time};

  # and sleep a bit if we are to fast for the maximum fps we want to achive
  if ($diff < $self->{min_time})
    {
    # So slow down...
    my $time_to_sleep = $self->{min_time} - $diff - $self->{wake_time};
    #print "time to sleep ",
    #  "$time_to_sleep, wake_time $self->{wake_time}, diff $diff\n";
    my $after_sleep = $self->{now};
    if ($time_to_sleep > 1)
      {
      SDL::Delay($time_to_sleep);		# but don't sleep 0 or 1!
      $after_sleep = SDL::GetTicks();
      $diff = $after_sleep - $self->{lastframes}->[-1];
      #print "diff $diff now $after_sleep\n";
      }
   
    $self->{wake_time} = 0;
    if ($self->{options}->{cap_fps})
      { 
      # the Delay() will be quite a bit off, on my system it seems to like to
      # sleep up to 20 ms (most of the time 10) more than it should. So we
      # record this: $after_sleep - $now is the time we sleep, $min_time the
      # time we should have spent at most.
      # Without this calculation, the achieved framerate will wildly differ
      # from the target framerate, but the code will be simpler and the frames
      # spread more even in the time. Set $wake_time to 0 below to disable this.
      $self->{wake_time} = $after_sleep - $self->{now};
      #print "$wake_time (time for this frame including sleep)\n";
      if ($self->{wake_time} > $self->{min_time})
        {
        $self->{wake_time} -= $self->{min_time};
        }
      else { $self->{wake_time} = 0; }
      }
    #  print "$self->{wake_time} (time we already sleept)\n";
    $self->{now} = $after_sleep;
    }

  # remember $now
  push @{$self->{lastframes}}, $self->{now};
  # track min/max time between two frames
  my $frame_diff = $self->{now} - $self->{lastframes}->[-2];
  $self->{min_frame_time} = $frame_diff 
   if $frame_diff < $self->{min_frame_time}; 
  $self->{max_frame_time} = $frame_diff 
   if $frame_diff > $self->{max_frame_time}; 

  # keep only frame times over the last X milliseconds
  while ($self->{lastframes}->[0] < ($self->{now} - $self->{fps_monitor_time}))
    {
    shift @{$self->{lastframes}};		# remove one
    }

  # calculate current_fps
  my $time = $self->{lastframes}->[-1] - $self->{lastframes}->[0] + 1;
  $self->{current_fps} = 1000 * scalar @{$self->{lastframes}} / $time;
  # update these timers only when the time to track the framerate was long
  # enough to make sense
  if ($time > 800)
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

  my $done = $self->{quit};
  my $event = $self->{event};
  # inner while to handle all events, not only one per frame
  while ($event->poll())			# got one event?
    {
    return 1 if $event->type() == SDL_QUIT;
    $done += $self->handle_event($event);	# let subclass handle event
    }
  $done;
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
    $self->expire_timers() if scalar keys %{$self->{timers}} > 0; # no timers?
    $self->next_frame();		# update the screen and fps monitor
    }
  $self->quit_handler();
  }

sub add_timer
  {
  # add a timer to the list of timers
  # The timer fires the first time after $time ms, then after each $delay ms
  # for $count times. $count < 0 means fires infinity times. $callback must
  # be a coderef, which will be called once the timer fires with:
  # $coderef($timer->{id},$timer);
  my $self = shift;
  my ($time,$count,$delay,$callback) = @_;

  my $timer = SDL::App::FPS::Timer->new( 
    $time, $count, $delay, $self->{current_time}, $callback, $self);
  return undef if $timer->count() == 0;		# timer fired once, and expired

  # otherwise remember it
  $self->{timers} = { $timer->{id} => $timer };
  # return it's id
  $timer->{id};
  }

sub expire_timers
  {
  # check all timers for whether they have expired (need to fire) or not
  my $self = shift;

  return 0 if scalar keys %{$self->{timers}} == 0;	# no timers?

  my $now = $self->{current_time};			# timers are warped
  foreach my $id (keys %{$self->{timers}})
    {
    $self->{timers}->{$id}->due($now);			# let timer fire
    delete $self->{timers}->{$id}
     if $self->{timers}->{$id}->count() == 0;		# remove any expired
    }
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
  }

sub remove_timer
  {
  # delete a timer with a specific id
  my ($self,$id) = @_;

  delete $self->{timers}->{$id};
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

sub handle_event
  {
  # called for each event that occurs, override in a subclass
  my ($self, $event) = @_;

  0;				# ignore event and keep running
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

	use vars qw/@ISA/;
	@ISA = qw/SDL::App::FPS/;

        # override the method draw_frame with something to draw
	sub draw_frame
          {
	  my ($self,$current_time,$lastframe_time,$current_fps) = @_;
          }

        # override the event handler to handle events interesting to you
	sub handle_event
	  {
	  my ($self,$event} = shift;
 
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

Toggle the application's fullscreen status.

=item width()

	my $w = $self->width();

Return the current width of the applications surface.

=item height()

	my $w = $self->height();

Return the current height of the applications surface.

=item update()

	$self->update($rect);

Call the SDL::App's update method.

=item add_timer()

	$app->add_timer($time,$count,$delay,$callback);

Adds a timer to the list of timers. When time is 0, the timer fires
immidiately (calls $callback). When the count was 1, and time 0, then
the timer will not be added to the list (it already expired) and undef will be
returned. Otherwise the unique timer id will be returned.

The timer will fire for the first time at C<$time> ms after the time it was
added, and then wait C<$delay> ms between each shot. if C<$count> is positive,
it gives the number of shots the timer fires, if it is negative, the timer
will fire endlessly until it is removed.

The timers added via add_timer() are coupled to the warped clock.

=item get_timer()

	$timer = $self->get_timer($timer_id);

Given a timer id, returns the timer object or undef.

=item timers()

Return count of active timers.

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
or the user event handler (see L<handle_event>) returned true.

=item expire_timers()

Check all the timers for whether they are due ot not and let them fire.
Removes unnecc. timers from the list.

=back

=head1 AUTHORS

(c) Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<SDL::App> and L<SDL>.

=cut

