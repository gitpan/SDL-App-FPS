#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <SDL/SDL.h>

/*
SDL::App::FPS XS code (C) by Tels <http://bloodgate.com/perl/> 
*/

MODULE = SDL::App::FPS		PACKAGE = SDL::App::FPS

PROTOTYPES: DISABLE


##############################################################################
# _delay() - if the time between last and this frame was too short, delay the
#            app a bit. Also returns GetTicks(), so we avoid one call to it.

SV*
_delay(last,min_time,wake_time)
	int	last
	int	min_time
	int	wake_time
  CODE:
    /*
     last      - time in ticks of last frame
     min_time  - ms to spent between frames minimum
     wake_time - ms we were late in last frame, so we slee this time shorter
    */
    /* caluclate how long we should sleep */
    int now;
    int to_sleep;

    now = SDL_GetTicks();
    to_sleep = min_time - wake_time - (now - last) - 1;

#    printf ("to sleep %i\n",to_sleep);
    # sometimes Delay() does not seem to work, so retry until it we sleeped
    # long enough
    while (to_sleep > 2)
      {
      SDL_Delay(to_sleep);
      now = SDL_GetTicks();
      to_sleep = min_time - (now - last);
      }
    wake_time = 0;
    if (now - last > min_time)
      {
      wake_time = now - last - min_time;
      }
    ST(0) = newSViv(now);
    ST(1) = newSViv(now - last);
    ST(2) = newSViv(wake_time);
    XSRETURN(3);
