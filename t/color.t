#!/usr/bin/perl -w

use Test::More tests => 40;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  unshift @INC, '.';
  chdir 't' if -d 't';
  use_ok ('SDL::App::FPS::Color');
  }

can_ok ('SDL::App::FPS::Color', qw/
   darken lighten blend
  /);
# fail due to AUTOLOAD. Should we add a can() method to cater for this?
#  red green blue orange yellow purple
#  white black gray lightgray darkgray
#  lightred darkred lightblue darkblue lightgreen darkgreen 

foreach my $name (qw/
  red green blue orange yellow purple magenta cyan brown
  white black gray lightgray darkgray
  lightred darkred lightblue darkblue lightgreen darkgreen
  /)
  {
  my $cname = uc($name);
  my $color = SDL::App::FPS::Color->$cname();
  is (ref($color), 'SDL::Color', "$cname");
  }

my $c = 'SDL::App::FPS::Color';
my $red = $c->RED();
my $green = $c->GREEN();


is ($c->darken($red,0.5)->r(), 0x7f, 'dark red is half red');

is ($c->darken($red,1)->r(), 0, 'result is black');
is ($c->darken($red,1)->g(), 0, 'result is black');
is ($c->darken($red,1)->b(), 0, 'result is black');

is ($c->darken($red,0)->r(), 0xff, 'result is red');
is ($c->darken($red,0)->g(), 0, 'result is red');
is ($c->darken($red,0)->b(), 0, 'result is red');

is ($c->lighten($red,0.5)->g(), 0x7f, 'light red is half green');
is ($c->lighten($red,0.5)->b(), 0x7f, 'light red is half blue');

is ($c->lighten($red,1)->r(), 0xff, 'result is white');
is ($c->lighten($red,1)->g(), 0xff, 'result is white');
is ($c->lighten($red,1)->b(), 0xff, 'result is white');

is ($c->lighten($red,0)->r(), 0xff, 'result is red');
is ($c->lighten($red,0)->g(), 0, 'result is red');
is ($c->lighten($red,0)->b(), 0, 'result is red');

is ($c->blend($red,$green,0.5)->r(), 0x7f, 'result is 50% red');
is ($c->blend($red,$green,0.5)->g(), 0x7f, 'result is 50% green');
is ($c->blend($red,$green,0.5)->b(), 0, 'result is 0% blue');


