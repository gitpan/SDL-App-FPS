#!/usr/bin/perl -w

use Test::More tests => 15;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../lib';
  unshift @INC, '.';
  chdir 't' if -d 't';
  use_ok ('SDL::App::MyFPS');
  }

can_ok ('SDL::App::MyFPS', qw/ 
  new time_warp frames current_time lastframe_time now
  _init quit option fullscreen
  main_loop update draw_frame handle_events handle_event
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
  remove_timer
  timers
  add_timer
  get_timer
  /);

# fill in here options or use Getopt::Long for command line
my $options = { width => 640, height => 480, };

my $app = SDL::App::MyFPS->new( $options );
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

is ($app->max_frame_time() > 0, 1, 'max_frame_time was set');
is ($app->min_frame_time() < 10000, 1, 'min_frame_time was set');

# we cap at 60 frames, so the framerate should not be over 65 (some extra due
# to timer inaccuracies)
is ($app->current_fps() < 65, 1, 'fps < 65');
