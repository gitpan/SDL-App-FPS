#!/usr/bin/perl -w

use Test::More tests => 6;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  unshift @INC, '.';
  chdir 't' if -d 't';
  use_ok ('SDL::App::FPS::EventHandler');
  }

can_ok ('SDL::App::FPS::EventHandler', qw/ 
  new rebind check id type kind
  LEFTMOUSEBUTTON
  RIGHTMOUSEBUTTON
  MIDDLEMOUSEBUTTON
  /);

use SDL::Event;
  
##############################################################################
# create eventhandler

my $space_pressed = 0;
my $handler = SDL::App::FPS::EventHandler->new
  (SDL_KEYDOWN, SDLK_SPACE, sub { $space_pressed++; },
  {});

is (ref($handler), 'SDL::App::FPS::EventHandler', 'handler new worked');
is ($handler->id(), 1, 'handler id is 1');
is ($handler->type(), SDL_KEYDOWN, 'type is SDL_KEYDOWN');
is ($handler->kind(), SDLK_SPACE, 'kind is SDLK_SPACE');


