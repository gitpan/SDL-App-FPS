#!/usr/bin/perl -w

use Test::More tests => 22;
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
   darken lighten
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
