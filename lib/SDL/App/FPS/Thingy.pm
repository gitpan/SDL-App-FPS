
# Thingy - a base class for SDL::App::FPS timers, event handlers, buttons etc

package SDL::App::FPS::Thingy;

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
  # create a new instance of a thingy
  my $class = shift;
  my $self = {}; bless $self, $class;

  $self->{id} = ID();
  $self->{app} = shift;

  $self->{active} = 1;
  $self->{group} = undef;
  
  $self->_init(@_);
  $self;
  }

sub _init
  {
  my $self = shift;

  $self;
  }

sub group
  {
  # return the group this thing belongs to or undef
  my $self = shift;
  $self->{group};
  }

sub activate
  {
  my ($self) = shift;

  $self->{active} = 1;
  }

sub deactivate
  {
  my ($self) = shift;

  $self->{active} = 0;
  }

sub is_active
  {
  my ($self) = shift;

  $self->{active};
  }

sub id
  {
  # return event handler id
  my $self = shift;
  $self->{id};
  }

1;

__END__

=pod

=head1 NAME

SDL::App::FPS::Thingy - base class for SDL::App::FPS event handlers, timers etc

=head1 SYNOPSIS

	package SDL::App::FPS::MyThingy;

	use SDL::App::FPS::Thingy;
	require Exporter;

	@ISA = qw/SDL::App::FPS::Thingy/;

	sub _init
	  {
	  my ($self) = shift;

	  # init with arguments from @_
	  }

	# override or add any method you need

=head1 EXPORTS

Exports nothing on default.

=head1 DESCRIPTION

This package provides a base class for "things" in SDL::App::FPS.

=head1 METHODS

These methods need not to be overwritten:

=over 2

=item new()

	my $thingy = SDL::App::FPS::Thingy->new($app,@options);

Creates a new thing, and registers it with the application $app (usually
an instance of a subclass of SDL::App::FPS).

=item is_active()

	$thingy->is_active();

Returns true if the thingy is active, or false for inactive.

=item activate()

	$thingy->activate();

Set the thingy to active. Newly created ones are always active.

=item deactivate()
	
	$thingy->deactivate();

Set the thingy to inactive. Newly created ones are always active.

=item id()

Return the thingy's unique id.

=back

=head1 AUTHORS

(c) 2002, 2003, Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<SDL:App::FPS>, L<SDL::App> and L<SDL>.

=cut

