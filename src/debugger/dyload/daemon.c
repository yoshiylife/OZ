/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include "switch.h"
#include "main.h"
#include "thr.h"

static	void
CodeDaemon()
{
}

static	void
ClassDaemon()
{
}

void
_start()
{
	OzForkThread( CodeDaemon, THREAD_STACK_SIZE, MAX_PRIORITY, 0 ) ;
	OzForkThread( ClassDaemon, THREAD_STACK_SIZE, MAX_PRIORITY, 0 ) ;
}
