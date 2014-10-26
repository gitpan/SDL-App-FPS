#!/usr/bin/perl -w

# spinning cube in OpenGL

use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, './lib';
  unshift @INC, '../lib';
  unshift @INC, '../blib/arch/';
  }

use SDL::App::FPS::MyOpenGL;

my $options = { 
 width => 640, height => 480, depth => 16, gl => 1, max_fps => 0
 };

print
  "SDL::App::FPS OpenGL Demo v0.01 (C) 2002,2003 by Tels <http://Bloodgate.com/>\n\n";

print "Mouse buttons for speed changes, f for fullscreen and q for quit.\n";

my $app = SDL::App::FPS::MyOpenGL->new( $options );
$app->main_loop();

print "Running time was ", int($app->now() / 10)/100, " seconds\n";
print "Minimum framerate ",int($app->min_fps()*10)/10,
      " fps, maximum framerate ",int($app->max_fps()*10)/10," fps\n";
print "Minimum time per frame ", $app->min_frame_time(),
      " ms, maximum time per frame ", $app->max_frame_time()," ms\n";
print "Thank you for playing!\n";
