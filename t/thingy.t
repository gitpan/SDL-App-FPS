#!/usr/bin/perl -w

use Test::More tests => 8;
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

# create thingy
my $thingy = SDL::App::FPS::Thingy->new ( 'main' );

is (ref($thingy), 'SDL::App::FPS::Thingy', 'new worked');
is ($thingy->id(), 1, 'id is 1');

is ($thingy->is_active(), 1, 'is active');
is ($thingy->deactivate(), 0, 'is deactive');
is ($thingy->is_active(), 0, 'is no longer active');
is ($thingy->activate(), 1, 'is active again');

