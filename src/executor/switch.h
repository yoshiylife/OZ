/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 * CAUTION
 *	This file have effect on all modules except multithread system.
 *	Don't include from multithread system module.
 *	But, you must be include this file in the other modules.
 */
#ifndef _SWITCH_H_
#define _SWITCH_H_

/*
 * oni
 */

#define GCTEST
/* #define ALWAYS_SIGNAL */

/*
 * hama
 */
/* inter-site communication using oz application gateway(OZAG) is possible */
#define INTERSITE
/* debug message for inter-site communication test */
#define INTERSITE_DEBUG
/*
 * yoshi
 */
#undef	TIMER
/* GC available for OM */
#define	GC_OM

/* #define DEBUGMESSAGE 0 */

#endif  _SWITCH_H_
