use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'SDL::App::FPS',
    'VERSION_FROM'	=> 'lib/SDL/App/FPS.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			SDL => 'v1.20.3', # see http://bloodgate.com/sdl/
			Config::Simple => '4.48',
			Games::OpenGL::Font::2D => '0.05',
			Games::Console => '0.02',
			}, # e.g., Module::Name => 1.1
    'LIBS'		=> [ '-lSDL' ], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '', # e.g., '-I/usr/include/other'
);
