#!/usr/bin/perl -w

use Test::More tests => 35;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  unshift @INC, '.';
  chdir 't' if -d 't';
  use_ok ('SDL::App::MyFPS');
  }

can_ok ('SDL::App::MyFPS', qw/ 
  new time_warp frames current_time lastframe_time now
  _init quit option fullscreen
  main_loop update draw_frame handle_events
  freeze_time thaw_time
  stop_time_warp_ramp
  ramp_time_warp
  _ramp_time_warp
  time_is_frozen
  time_is_ramping
  pause
  min_fps max_fps
  min_frame_time max_frame_time
  width height app
  del_timer timers add_timer get_timer
  add_event_handler del_event_handler
  add_group
  in_fullscreen
  /);

use SDL::Event;

my $options = { width => 640, height => 480, };

my $app = SDL::App::MyFPS->new( $options );

is (keys %$app, 2, 'data all encapsulated');
is (exists $app->{_app}, 1, 'data all encapsulated');
is (exists $app->{myfps}, 1, 'data all encapsulated');

$app->add_event_handler(SDL_KEYDOWN, SDLK_q, { });
my $timer = 0;
$app->add_timer(20, 1, 0, 0, sub { $timer++ } );

$app->main_loop();

is ($app->{myfps}->{quit_handler},1, 'quit_handler() run once');
is ($app->{myfps}->{pre_init_handler},1, 'pre_init_handler() run once');
is ($app->{myfps}->{post_init_handler},1, 'post_init_handler() run once');
is ($app->{myfps}->{drawcounter},100, 'drawn 100 frames');
is ($app->{myfps}->{now} > 0, 1, 'now was initialized');
is ($app->{myfps}->{timer_fired}, 1, 'timer fired once');
is ($app->time_warp(), 1, 'time_warp is 1.0');
is ($app->time_is_frozen(), '', 'time is not frozen');
is ($app->time_is_ramping(), '', 'time is not ramping');
is ($app->timers(), 0, 'no timers running');

is (scalar keys %{$app->{_app}->{event_handler}}, 1, 'one handler');

is ($app->in_fullscreen(), 0, 'were in windowed mode');
is ($app->fullscreen(0), 0, 'already were in windowed mode');
is ($app->fullscreen(), 1, 'toggled fullscreen');
is ($app->fullscreen(1), 1, 'already fullscreen');
is ($app->in_fullscreen(), 1, 'really in fullscreen');
is ($app->fullscreen(0), 0, 'back to windowed mode');

is ($app->max_frame_time() > 0, 1, 'max_frame_time was set');
is ($app->min_frame_time() < 10000, 1, 'min_frame_time was set');

# we cap at 60 frames, so the framerate should not be over 65 (some extra due
# to timer inaccuracies)
is ($app->current_fps() < 65, 1, 'fps < 65');

# test that adding timer really adds more of them
my $timer1 = $app->add_timer( 2000,1,200, 0, sub {});
is ($app->timers(), 1, '1 timer running');
my $timer2 = $app->add_timer( 2000,1,200, 0, sub {});
is ($app->timers(), 2, '2 timer running');

$app->del_timer($timer1);
is ($app->timers(), 1, '1 left');
$timer2 = $app->get_timer($timer2);
is (ref($timer2), 'SDL::App::FPS::Timer', 'got timer from id');
$app->del_timer($timer2->{id});
is ($app->timers(), 0, 'none left');

is ($app->current_time() > 0, 1, 'current time elapsed');
is ($app->now() == $app->current_time(), 1, 'current time equals real time');

##############################################################################

is (keys %$app, 2, 'data all encapsulated');
is (exists $app->{_app}, 1, 'data all encapsulated');
is (exists $app->{myfps}, 1, 'data all encapsulated');

 
