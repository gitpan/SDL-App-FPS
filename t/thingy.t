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
  use_ok ('SDL::App::FPS::Thingy');
  }

can_ok ('SDL::App::FPS::Thingy', qw/ 
  new _init activate deactivate is_active id
  /);

my $de = 0; sub _deactivated_thing { $de ++; }
my $ac = 0; sub _activated_thing { $ac ++; }

# create thingy
my $thingy = SDL::App::FPS::Thingy->new ( 'main' );

is (ref($thingy), 'SDL::App::FPS::Thingy', 'new worked');
is ($thingy->id(), 1, 'id is 1');

is ($thingy->is_active(), 1, 'is active');
is ($thingy->deactivate(), 0, 'is deactive');
is ($de, 1, 'callback to app happened');
is ($thingy->deactivate(), 0, 'is still deactive');
is ($de, 1, 'but nocallback happened');

is ($thingy->is_active(), 0, 'is no longer active');
is ($thingy->activate(), 1, 'is active again');
is ($ac, 1, 'callback to app happened');

is ($thingy->activate(), 1, 'is stil active');
is ($ac, 1, 'but no callback happened');


