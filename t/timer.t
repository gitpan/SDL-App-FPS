#!/usr/bin/perl -w

use Test::More tests => 26;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../lib';
  unshift @INC, '.';
  chdir 't' if -d 't';
  use_ok ('SDL::App::FPS::Timer');
  }

can_ok ('SDL::App::FPS::Timer', qw/ 
  new count due id next_shot
  _fire
  /);

my $fired = 0;

sub fire
  {
  my ($self,$timer,$timer_id) = @_;

  $fired++;
  }

##############################################################################
# timer with limited count

my $timer = SDL::App::FPS::Timer->new (100, 2, 200, 128, \&fire, ); 

is (ref($timer), 'SDL::App::FPS::Timer', 'timer new worked');
is ($timer->id(), 1, 'timer id is 1');
is ($timer->count(), 2, 'timer count is 2');
is ($timer->next_shot(), 228, 'timer fires at 228');
is ($timer->due(227), 0, 'timer is not due at 227');
is ($timer->due(229), 1, 'timer was due at 229');
is ($fired, 1, 'timer fired');
is ($timer->count(), 1, 'one less');
is ($timer->next_shot(), 428, 'next shot at 228 + 200');
is ($timer->due(429), 1, 'timer was due at 429');
is ($fired, 2, 'timer fired again');
is ($timer->count(), 0, 'one less');
is ($timer->next_shot(), 628, 'never');
is ($timer->due(629), 0, 'timer is not due');
is ($fired, 2, "timer didn't fire");

##############################################################################
# timer with unlimited count

$timer = SDL::App::FPS::Timer->new (0, -1, 200, 128, \&fire, ); 

is (ref($timer), 'SDL::App::FPS::Timer', 'timer new worked');
is ($fired, 3, "timer already fired once");
is ($timer->id(), 2, 'timer id is unqiue and 2');
is ($timer->count(), -1, 'timer count is -1');
is ($timer->next_shot(), 328, 'timer fires next at 128+200');
is ($timer->due(327), 0, 'timer is not due at 227');
is ($timer->due(329), 1, 'timer was due at 229');
is ($fired, 4, 'timer fired again');
is ($timer->count(), -1, 'count unchanged');


