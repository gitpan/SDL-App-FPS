#!/usr/bin/perl -w

use Test::More tests => 8;
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
  /);

# fill in here options or use Getopt::Long for command line
my $options = { width => 640, height => 480, };

my $app = SDL::App::MyFPS->new( $options );
$app->main_loop();

is ($app->{myfps}->{quit_handler},1, 'quit_handler() run once');
is ($app->{myfps}->{pre_init_handler},1, 'pre_init_handler() run once');
is ($app->{myfps}->{post_init_handler},1, 'post_init_handler() run once');
is ($app->{myfps}->{drawcounter},100, 'drawn 100 frames');
is ($app->time_warp(), 1, 'time_warp is 1.0');

# we cap at 60 frames, so the framerate should not be over 65 (some extra due
# to timer inaccuracies)
is ($app->current_fps() < 65, 1, 'fps < 65');
