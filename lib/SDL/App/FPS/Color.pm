
# Color - provides color names => SDL::Color mapping

package SDL::App::FPS::Color;

# (C) by Tels <http://bloodgate.com/>

use strict;

use Exporter;
use vars qw/@ISA $VERSION @EXPORT_OK $AUTOLOAD/;
@ISA = qw/Exporter/;

$VERSION = '0.01';

@EXPORT_OK = qw/
  RED GREEN BLUE
  ORANGE YELLOW PURPLE MAGENTA CYAN BROWN
  WHITE BLACK GRAY LIGHTGRAY DARKGRAY
  LIGHTRED DARKRED LIGHTBLUE DARKBLUE LIGHTGREE DARKGREEN
  darken lighten
  /;

use SDL::Color;

my $color = 
  {
  BLACK		=> [0x00,0x00,0x00],
  WHITE		=> [0xff,0xff,0xff],
  LIGHTGRAY	=> [0xa0,0xa0,0xa0],
  DARKGRAY	=> [0x40,0x40,0x40],
  GRAY		=> [0x80,0x80,0x80],
  RED		=> [0xff,0x00,0x00],
  GREEN		=> [0x00,0xff,0x00],
  BLUE 		=> [0x00,0x00,0xff],
  LIGHTRED	=> [0xff,0x80,0x80],
  LIGHTGREEN	=> [0x80,0xff,0x80],
  LIGHTBLUE 	=> [0x80,0x80,0xff],
  DARKRED	=> [0x80,0x00,0x00],
  DARKGREEN	=> [0x00,0x80,0x00],
  DARKBLUE	=> [0x00,0x00,0x80],
  YELLOW	=> [0xff,0xff,0x00],
  PURPLE	=> [0x80,0x00,0x80],
  MAGENTA	=> [0xff,0x80,0xff],
  CYAN		=> [0x80,0xff,0xff],
  ORANGE	=> [0xff,0x80,0x00],
  TURQUISE	=> [0xff,0xff,0x80],
  BROWN		=> [0x80,0x40,0x40],
  SALMON	=> [0xff,0x80,0x80],
  };

sub AUTOLOAD
  {
  # create at runtime the different color routines (and the SDL::Color
  # objects) Only the first call has an overhead, and this avoids to
  # create dozend objects at load time, that probably are never used.
  my $name = $AUTOLOAD;

  $name =~ s/.*:://;    # split package

  if (exists $color->{$name})
    {
    if (ref($color->{$name}) ne 'SDL::Color')		# will always be true?
      {
      # create object on the fly
      my ($r,$g,$b) = @{ $color->{$name} };
      $color->{$name} = SDL::Color->new( -r => $r, -g => $g, -b => $b);
      }
    no strict 'refs';
    *{"SDL::App::FPS::Color"."::$name"} = sub { $color->{$name}; };
    &$name;      # uses @_
    }
  else
    {
    # delayed load of Carp and avoid recursion
    require Carp;
    Carp::croak ("SDL::App::FPS::Color $name is unknown");
    }
  }

sub darken
  {
  my ($color,$factor) = @_;

  if ($factor < 0 || $factor > 1)
    {
    require Carp; Carp::croak ("Darkening factor must be between 0..1");
    }
  return SDL::Color->new ( 
    -r => $color->r() * $factor, 
    -g => $color->g() * $factor, -b => $color->b() * $factor);
  }

sub lighten
  {
  my ($color,$factor) = @_;

  if ($factor < 0 || $factor > 1)
    {
    require Carp; Carp::croak ("Darkening factor must be between 0..1");
    }
  my $r = $color->r();
  my $g = $color->g();
  my $b = $color->b();
  return SDL::Color->new ( 
    -r => $r + (0xff - $r) * $factor, 
    -g => $g + (0xff - $g) * $factor, 
    -b => $b + (0xff - $b) * $factor ); 
  }

1;

__END__

=pod

=head1 NAME

SDL::App::FPS::Color- provides color names => SDL::Color mapping

=head1 SYNOPSIS

	package SDL::App::FPS::Color qw/RED BLUE GREEN/;

	my $yellow = SDL::App::FPS::Color::YELLOW();
	my $red = RED();
	my $blue = BLUE;
	
=head1 EXPORTS

Can export the color names on request.

=head1 DESCRIPTION

This package provides SDL::Color objects that corrospond to the basic
color names.

=head1 METHODS

The following color names exist:

  	RED		GREEN		BLUE
	ORANGE		YELLOW		PURPLE
	MAGENTA 	CYAN 		BROWN
	WHITE		BLACK		GRAY
	LIGHTGRAY	DARKGRAY
	LIGHTRED 	DARKRED
	LIGHTBLUE	DARKBLUE
	LIGHTGREE	DARKGREEN

=head2 darken

	$new_color = SDL::App::FPS::Color::darken($color,$factor);

C<$factor> must be between 0 (result is black) and 1 (result is original
color). C<darken()> darkens the color by this factor, for instance 0.5 makes
a color of 50% color values from the original color.

=head2 lighten

	$new_color = SDL::App::FPS::Color::lighten($color,$factor);

C<$factor> must be between 0 (result is original color) and 1 (result is
white). C<lighten()> darkens the color by this factor, for instance 0.5 makes
a color of 50% higher color values from the original color.

=head1 METHODS

=head1 AUTHORS

(c) 2003 Tels L<http://bloodgate.com/perl/sdl/|http://bloodgate.com/perl/sdl/>

=head1 SEE ALSO

L<SDL:App::FPS>, L<SDL::App> and L<SDL>.

=cut

