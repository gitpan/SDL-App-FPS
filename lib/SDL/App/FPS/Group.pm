
# Group - a container class for SDL::App::FPS timer and eventhandlers

package SDL::App::FPS::Group;

# (C) by Tels <http://bloodgate.com/>

use strict;

use Exporter;
use vars qw/@ISA $VERSION/;
@ISA = qw/Exporter/;

$VERSION = '0.01';

  {
  my $id = 1;
  sub ID { return $id++;}
  }

sub new
  {
  # create a new instance of SDL::App::FPS::Group
  my $class = shift;
  my $self = {}; bless $self, $class;

  $self->{id} = ID();

  $self->{members} = {};

  my $args = $_[0];
  if (@_ > 0) { $args = { @_ }; }
  $self->{app} = $args->{app};

  $self;
  }

sub for_each
  {
  # call a routine for each member of the group
  my $self = shift;
  my $call = shift;

  my $app = $self->{app};
  foreach my $id (keys %{$self->{members}})
    {
    my $obj = $self->{members}->{$id};
    $obj->$call($app,$obj,$id,@_);
    }
  $self;
  }

sub contains ($$)
  {
  # given an ID, returns true when the group contains this ID
  my ($self,$id) = @_;

  exists $self->{members}->{$id};
  }

sub member ($$)
  {
  # given an ID, returns the member or undef
  my ($self,$id) = @_;

  return $self->{members}->{$id} if exists $self->{members}->{$id};
  return;
  }

sub members ($)
  {
  # returns count of members
  my ($self) = @_;

  scalar keys %{$self->{members}};
  }

sub add
  {
  # given an object ref, adds this object
  my ($self) = shift;

  for my $obj (@_)
    {
    my $id = $obj->{id};
    $self->{members}->{$id} = $obj;
    #$obj->{group} = $self;
    #$obj->{group_id} = $self->{id};
    }
  $self;
  }

sub del ($$)
  {
  # given an object ID, delete this object
  my ($self,$id) = @_;

  delete $self->{members}->{$id};
  }

sub id
  {
  # return group id
  my $self = shift;
  $self->{id};
  }

1;

__END__

=pod

=head1 NAME

SDL::App::FPS::Group - a container class for SDL::App::FPS

=head1 SYNOPSIS

	use SDL::FPS::App;
	use SDL::FPS::App::Group;
	use SDL::FPS::App::Timer;

	$app = SDL::FPS::App->new( ... );

	my $group = SDL::App::FPS::Group->new( $app );

	my $handler = SDL::App::FPS::EventHandler->new(
          SDL_KEYDOWN, SDLK_SPACE, { ... });

        $group->add($handler);

	$group->for_each( $CODE_ref, @arguments );

=head1 DESCRIPTION

This package provides a container class, which is used to store timers,
event handlers and other things.

It is used by SDL::App::FPS and you need not to use it directly for timer
and event handlers. However, it may be usefull for other things.

=head1 CALLBACK

Once for_each() is called, the given callback code (CODE ref) is called with
the following parameters:

	&{$callback}($self,$object,$object_id,@arguments);

C<$self> is the app the object resides in (e.g. the object of type
SDL::App::FPS), C<$object> is the object itself, C<$id> it's id, and the
additional arguments are whatever was passed when for_each() was called.

=head1 METHODS

=over 2

=item new()

	my $group = SDL::App::FPS::Group->new();

Creates a new group container.

=item add()

	$group->add($object);
	$group->add(@objects);

Add a list of obects (given as reference) to the group. The object(s) must have
one internal field, called C<id>. These IDs should be unique numbers or
strings.

=item del()

	$group->del($object_id);

Given an object ID, remove this object from the group.

=item contains()

	$group->contains($object_id);

Given an object ID, returns true when the group contains an object with this
ID.

=item id()

	$group->id();

Returns the ID of the group itself.

=item member()

	$object = $group->member($id);

Given an object ID, returns the object or undef.

=item member()

	$count = $group->members();

Returns the number of members in this group.

=item for_each()

	$count = $group->for_each($methodname, @arguments);

For each of the members in this group call their method C<$methodname> with
the C<@arguments>.

=back

=head1 BUGS

None known yet.

=head1 AUTHORS

(c) 2002, 2003 Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<SDL:App::FPS>, L<SDL::App> and L<SDL>.

=cut

