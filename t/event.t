#!/usr/bin/perl -w

use Test::More tests => 14;
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
  rebind check type kind
  new _init activate is_active deactivate id
  /);

use SDL::Event;
use SDL::App::FPS::Button qw/BUTTON_MOUSE_LEFT BUTTON_MOUSE_RIGHT/;

##############################################################################
package DummyEvent;

use SDL::Event;
# a dummy event package to simulate an SDL::Event

sub new { bless { }, 'DummyEvent'; }

sub type { SDL_KEYDOWN; }
sub key_sym { SDLK_SPACE; }

package DummyEventMouse;

use SDL::Event;
# a dummy event package to simulate an SDL::Event

sub new { bless { button => $_[1] }, 'DummyEventMouse'; }

sub type { SDL_MOUSEBUTTONDOWN; }
sub button { $_[0]->{button}; }			# RMB 

##############################################################################

package main;

# create eventhandler

my $space_pressed = 0;
my $handler = SDL::App::FPS::EventHandler->new
  ('main', SDL_KEYDOWN, SDLK_SPACE, sub { $space_pressed++; }, );

is (ref($handler), 'SDL::App::FPS::EventHandler', 'handler new worked');
is ($handler->id(), 1, 'handler id is 1');
is ($handler->type(), SDL_KEYDOWN, 'type is SDL_KEYDOWN');
is ($handler->kind(), SDLK_SPACE, 'kind is SDLK_SPACE');
is ($handler->is_active(), 1, 'handler is active');

is ($handler->deactivate(), 0, 'handler is deactive');
is ($handler->is_active(), 0, 'handler is no longer active');
is ($handler->activate(), 1, 'handler is active again');

my $dummyevent = DummyEvent->new();

$handler->deactivate();
$handler->check($dummyevent);
is ($space_pressed, 0, 'callback was not called');
$handler->activate();
$handler->check($dummyevent);
is ($space_pressed, 1, 'callback was called');		# bug in v0.07

my $pressed = 0;
$dummyevent = DummyEventMouse->new( BUTTON_MOUSE_LEFT );
$handler = SDL::App::FPS::EventHandler->new
  ('main', SDL_MOUSEBUTTONDOWN, BUTTON_MOUSE_LEFT + BUTTON_MOUSE_RIGHT,
   sub { $pressed++; }, );
$handler->check($dummyevent);
is ($pressed, 1, 'callback was called');
$dummyevent = DummyEventMouse->new( BUTTON_MOUSE_RIGHT );
$handler->check($dummyevent);
is ($pressed, 2, 'callback was called again');

