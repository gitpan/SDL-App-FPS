
# EventHandler class for SDL::App::FPS - used to register callbacks for events

package SDL::App::FPS::EventHandler;

# (C) by Tels <http://bloodgate.com/>

use strict;

use Exporter;
use SDL::App::FPS::Thingy;
use vars qw/@ISA $VERSION @EXPORT_OK/;
@ISA = qw/SDL::App::FPS::Thingy Exporter/;

use SDL::Event;

$VERSION = '0.02';

sub _init
  {
  my $self = shift;

  $self->{type} = shift;			
  $self->{kind} = shift;			
  $self->{callback} = shift;			
  
  $self->{args} = [ @_ ];

  $self;
  }

sub check
  {
  # check whether the event matched the occured event or not
  my ($self,$event) = @_;

  return if $self->{active} == 0;

  my $type = $event->type();  
  return unless $type == $self->{type};

  if ($type == SDL_KEYDOWN || $type == SDL_KEYUP)
    {
    my $kind = $event->key_sym();
    return unless $kind == $self->{kind};
    }
  elsif ($type == SDL_MOUSEBUTTONUP || $type == SDL_MOUSEBUTTONDOWN)
    {
    my $kind = $event->button();
    # SDL uses 1,2,3, we use 1,2,4 to add them together for Buttons
    $kind = 4 if $kind == 3;
    # this enables to watch for more than one button with one event:
    return unless ($self->{kind} & $kind) != 0;
    }
  
  # event happened, so call callback
  &{$self->{callback}}($self->{app},$self,$event,@{$self->{args}});
  }

sub rebind
  {
  my ($self) = shift;

  $self->{type} = shift;
  $self->{kind} = shift;
  $self->{app}->_rebound_event_handler($self);
  $self; 
  }

sub type
  {
  # return the type this event handler watches out for
  my $self = shift;
  $self->{type};
  }

sub kind
  {
  # return the kind this event handler watches out for
  my $self = shift;
  $self->{kind};
  }

1;

__END__

=pod

=head1 NAME

SDL::App::FPS::EventHandler - a event handler class for SDL::App::FPS

=head1 SYNOPSIS

	my $handler = SDL::App::FPS::EventHandler->new( $app,
		SDL_KEYDOWN,
		SDLK_SPACE,
		sub { my $self = shift; $self->pause(); },
	};

	my $handler2 = SDL::App::FPS::EventHandler->new( $app,
		SDL_MOUSEBUTTONDOWN,
		LEFTMOUSEBUTTON,
		sub { my $self = shift; $self->time_warp(2,2000); },
	};

=head1 DESCRIPTION

This package provides an event handler class.

Event handlers are register to watch out for certain external events like
keypresses, mouse movements and so on, and when these happen, call a callback
routine.

=head1 CALLBACK

Once the event has occured, the callback code (CODE ref) is called with the
following parameters:

	&{$callback}($self,$handler,$event);

C<$self> is the app the event handler resides in (e.g. the object of type
SDL::App::FPS), C<$handler> is the event handler itself, and C<$event> the
SDL::Event that caused the handler to be activated.

=head1 METHODS

=over 2

=item new()

	my $handler = SDL::App::FPS::EventHandler->new(
		$app,
		$type,
		$kind,
		$callback,
	);

Creates a new event handler to watch out for $type events (SDL_KEYDOWN,
SDL_MOUSEMOVED, SDL_MOUSEBUTTONDOWN etc) and then for $kind kind of it,
like SDLK_SPACE. Mouse movement events ignore the $kind parameter.

C<$app> is the ref to the application the handler resides in and is passed
as first argument to the callback function when called.

=item is_active()

	$handler->is_active();

Returns true if the event handler is active, or false for inactive. Inactive
event handlers ignore any events that might happen.

=item activate()

Set the event handler to active. Newly created ones are always active.

=item deactivate()

Set the event handler to inactive. Newly created ones are always active.

=item rebind()

	$handler->rebind(SDL_KEYUP, SDLK_P);

Set a new type and kind for the handler to watch out for.

=item id()

Return the handler's unique id.

=back

=head1 AUTHORS

(c) 2002, 2003, Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<SDL:App::FPS>, L<SDL::App> and L<SDL>.

=cut

