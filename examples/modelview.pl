#!/usr/bin/perl -w

# View a .md2 model in OpenGL

use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, './lib';
  unshift @INC, '../lib';
  unshift @INC, '../blib/arch/';
#  unshift @INC, '../../Games-3D-Model-0.02/lib';
  }

use SDL::App::FPS::MyMD2;

my $options = { 
 width => 800, height => 600, depth => 16, gl => 1, max_fps => 60,
 };

print
  "SDL::App::FPS MD2 OpenGL Demo v0.01 (C) 2003 by Tels <http://Bloodgate.com/>\n\n";

print "f for fullscreen and q for quit.\n";
print "Usage: ./modelview.pl modelfile.md2\n";

sleep(2);

my $app = SDL::App::FPS::MyMD2->new( $options );
$app->_set_model( shift || '' );
$app->main_loop();

print "Running time was ", int($app->now() / 10)/100, " seconds\n";
print "Minimum framerate ",int($app->min_fps()*10)/10,
      " fps, maximum framerate ",int($app->max_fps()*10)/10," fps\n";
print "Minimum time per frame ", $app->min_frame_time(),
      " ms, maximum time per frame ", $app->max_frame_time()," ms\n";
print "Thank you for playing!\n";
