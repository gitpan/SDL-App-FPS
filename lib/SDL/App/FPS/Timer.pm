
# Timer class for SDL::App::FPS - it represents on timer that is checked on
# each frame

package SDL::App::FPS::Timer;

# (C) by Tels <http://bloodgate.com/>

use strict;

use Exporter;
use vars qw/@ISA $VERSION/;
@ISA = qw/Exporter/;

$VERSION = '0.02';

  {
  my $id = 1;
  sub ID { return $id++;}
  }

sub new
  {
  # create a new instance of SDL::App::FPS::Timer
  my $class = shift;
  my $self = {}; bless $self, $class;

  $self->{id} = ID();
  # times can be negative, for instance when clock goes backwards!
  $self->{time} = shift;			
  $self->{count} = shift;			# count < 0 => infitite
  $self->{delay} = shift || $self->{time};
  $self->{rand} = abs(shift || 0);		# wiggle firing
  $self->{start} = shift;			# time we started to live
  $self->{code} = shift;			# callback
  if (ref($self->{code}) ne 'CODE')
    {
    require Carp; Carp::croak ("Timer needs a coderef as callback!");
    }
  $self->{self} = shift;			# additional arguments
  $self->{args} = [ @_ ];			# additional arguments
  $self->{due} = 0;				# not yet
  $self->{next_shot} = $self->{start} + $self->{time};
  $self->{overshot} = 0;			# when we fire, we are late
						# by this amount

  if ($self->{time} == 0)			# well, maybe due right now
    {
    $self->_fire($self->{start});
    }

  $self;
  }

sub next_shot
  {
  # when will next shot be fired?
  my $self = shift;
  $self->{next_shot};
  }

sub fired
  {
  # did this timer fire?
  my $self = shift;
  $self->{due};
  }

sub count
  {
  # how many shots left?
  my $self = shift;
  $self->{count};
  }

sub _fire
  {
  # fire the timer
  my ($self,$now) = @_;

  $self->{due} = 1;
  $self->{overshot} = $now - $self->{next_shot};	# we are late
  # our next shot will be then (regardless of when this shot was fired)
  $self->{next_shot} += $self->{delay};			
  $self->{count}-- if $self->{count} > 0;		# one shot less
  $self->{time} = $self->{delay};			# allow a positive
							# time and then
							# negative delays
  # fire timer now
  &{$self->{code}}( 
    $self->{self}, $self, $self->{id}, $self->{overshot}, @{$self->{args} });
  1;
  }

sub due
  {
  # check whether this timer is due or not
  my ($self,$now,$time_warp) = @_;
 
  $self->{due} = 0;				# not yet
  return 0 if ($time_warp == 0) || ($self->{count} == 0);

  # freeze backwards looking timers if time goes forward and vice versa
  if ($self->{time} > 0)
    {
    return 0 if $time_warp < 0 || $now < $self->{next_shot};
    }
  else
    {
    return 0 if $time_warp > 0 || $now > $self->{next_shot};
    }
  $self->_fire($now); 
  }

sub id
  {
  # return timer id
  my $self = shift;
  $self->{id};
  }

1;

__END__

=pod

=head1 NAME

SDL::App::FPS::Timer - a timer class for SDL::App::FPS

=head1 SYNOPSIS

	my $timer = SDL::App::FPS::Timer->new(
		$time_to_first_shot,
		$count,
		$delay_between_shots,
		$randomize,
		$now,
		$callback,
		@arguments_to_callback
	);

=head1 DESCRIPTION

This package provides a timer class. It is used by SDL::App::FPS and you need
not to use it directly.

=head1 CALLBACK

Once the timer has expired, the callback code (CODE ref) is called with the
following parameters:

	&{$callback}($self,$timer,$id,$overshot,@arguments);

C<$self> is the app the timer resides in (e.g. the object of type
SDL::App::FPS), C<$timer> is the timer itself, C<$id> it's id, C<$overshot>
is the time the timer is late (e.g. it fires now, but should have fired
C<-$overshot> ms ago) and the additional arguments are whatever was passed
when the timer was created.

=head1 METHODS

=over 2

=item new()

	my $timer = SDL::App::FPS::Timer->new(
		$time_to_first_shot,
		$count,
		$delay_between_shots,
		$randomize,
		$now,
		$callback,
		@arguments_to_callback
	);

Creates a new timer that will first fire at $time_to_first_shot from $now on
(assuming $now is the current time), fire at most of $count times (negative
counts means infinitely often), and between each shot will wait for $delay.
Both initial time and delay are in ms.

The randomize parameter should be smaller than the time and/or delay, it
will be used to randomize the delay times.

If you setup a timer with a delay of 1000 ms and a randomize value of 100, the
earliest time it will fire is 900 ms, and the latest time would be 1100 ms.

=item next_shot()

	$timer->next_shot();

Returns the absolute time when the timer will fire the next time.

=item due()

Check whether the time is due or not. If is ise due (or overdue), it will
fire.

=item id()

Returns the timers unique id.

=item fired()

Returns whether the timer fired or not. Use only after calling C<due()>.

=item count()

Returns the number of 'shots' left. Negative value means the timer will
fire infinitely often.

=back

=head1 BUGS

C<due()> does ignore when the timer should have fire multiple times between
it was started and the time it is checked. E.g. when then timer is due in 100
ms, and should fire 3 times, and then is checked the first time after 1000 ms,
it should imidiately 3 times, each time having a different overdue time.

Currently it fires only once.

=head1 AUTHORS

(c) Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<SDL:App::FPS>, L<SDL::App> and L<SDL>.

=cut

