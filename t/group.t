#!/usr/bin/perl -w

use Test::More tests => 17;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  unshift @INC, '.';
  chdir 't' if -d 't';
  use_ok ('SDL::App::FPS::Group');
  }

can_ok ('SDL::App::FPS::Group', qw/ 
  new member members add del id
  /);

##############################################################################
package DummyThing;

# a dummy package to simulate some object

my $id = 1;
sub new { bless { id => $id++, }, 'DummyThing'; }

my $done = 0;
sub done
  {
  $done++;
  }

##############################################################################

package main;

# create group

my $group = SDL::App::FPS::Group->new ( app => { } );

is (ref($group), 'SDL::App::FPS::Group', 'group new worked');
is ($group->id(), 1, 'group id is 1');

is ($group->members(), 0, 'group has 0 members');

# add somethig
$group->add( DummyThing->new() );
is ($group->members(), 1, 'group has 1 members');
is (ref($group->member(1)), 'DummyThing', 'group member 1 exist');
is ($group->contains(1), 1, 'group member 1 exist');

# mass-add 
$group->add( DummyThing->new(), DummyThing->new() );
is ($group->members(), 3, 'group has 3 members');
is (ref($group->member(1)), 'DummyThing', 'group member 1 exist');
is (ref($group->member(2)), 'DummyThing', 'group member 2 exist');
is (ref($group->member(3)), 'DummyThing', 'group member 3 exist');
is ($group->contains(1), 1, 'group member 1 exist');
is ($group->contains(2), 1, 'group member 2 exist');
is ($group->contains(3), 1, 'group member 3 exist');

# for_each
is ($group->for_each('done'), $group, 'for_each did something');
is ($done, 3 , 'three member methods called' );

