/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* multithread system include */
#include "thread/thread.h"
#include "oz++/ozlibc.h"

#include "switch.h"
#include "main.h"
#include "pkif.h"
#include "ot.h"
#include "channel.h"
#include "g-invoke.h"
#include "global-trace.h"
#include "executor/global-invoke.h"
#include "executor/method-invoke.h"
#include "executor/exception.h"
#include "oz++/sysexcept.h"

/*
 *	External Function Signature without include file
 */
extern	OzSendChannel	OzCreateRemoteSendChannel( OID caller, OID callee ) ;

long long
OzExecGlobalInvoke(OID caller, OID callee, OID cvid, int slot1,
			     int slot2, char *fmt, int dummy1, int dummy2, ...)
     /* In order to use __builtin_apply, two more additional words in
	'args' are needed. 'send_args' passes the pointer to 'dummy1'. */
{
  OzSendChannel chan;
  Oz_ExceptionCatchTable exception_list;
  OZ_ExceptionIDRec eid;
  long long eparam;
  char efmt;
  va_list args=NULL;	/* for gcc warining message */
  long long rval=0;	/* for gcc warining message */
  int block ;
  int local ;
  extern OzSendChannel LcCreateLocalChannel(OID caller, OID callee);
  OZ_Object o = 0; /* for TRACE */

  if ( callee == 0ll ) {
    OzExecRaise( OzExceptionIllegalInvoke, 0, 0 ) ;
  }

  block = ThrBlockSuspend() ;

  exception_list = ExMergeExceptionList();
  TRACE(o, caller, callee);
  local = (caller>>24 == callee>>24) ? 1 : 0 ;
  if ( local ) chan = LcCreateLocalChannel(caller, callee);
  else chan = (OzSendChannel)OzCreateRemoteSendChannel(caller, callee);

  if (! chan) {
    ThrUnBlockSuspend( block ) ;
    OzExecRaise(OzExceptionGlobalInvokeFailed, callee, 0);
    /* NOT REACHED */
  }

  chan->ops->send_cvid(chan, cvid);
  chan->ops->send_slot(chan, slot1, slot2);
  va_start(args,dummy2);
  chan->ops->send_args(chan, fmt, args);
  va_end(args);
  chan->ops->send_exception_list(chan, exception_list);
  switch(chan->ops->recv_return(chan)) {
  case EXCEPTION:
    eid = chan->ops->recv_exception(chan);
    efmt = chan->ops->recv_exception_fmt(chan);
    eparam = chan->ops->recv_exception_param(chan);
    TRACE(o, caller, callee);
    chan->ops->free(chan);
    ThrUnBlockSuspend( block ) ;
    if ( ! local ) OzFree( exception_list ) ;
    OzExecRaise(eid, eparam, efmt);
    /* NOT REACHED */
    break;
  case NORMAL:
    rval = chan->ops->recv_value(chan);
    TRACE(o, caller, callee);
    chan->ops->free(chan);
    ThrUnBlockSuspend( block ) ;
    if ( ! local ) OzFree( exception_list ) ;
    break ;
  case ERROR:
    OzError("OzGlobalInvoke(%016lx,%016lx): "
		"Error occured in global invocation.",caller,callee);
    TRACE(o, caller, callee);
    chan->ops->free(chan);
    ThrUnBlockSuspend( block ) ;
    OzFree( exception_list ) ;
    OzExecRaise(OzExceptionGlobalInvokeFailed, callee, 0);
    /* NOT REACHED */
  }
  return(rval);
}

static long long invoke(void (*func)(), int size, void *args)
{
  void *p;
  *((int **)args) = (int *)(((int **)args) + 2); /* Magic! */
  p = __builtin_apply(func, args, size);  /* GCC C extentions */
  __builtin_return(p);                    /* GCC C extentions */
}

inline static OZ_Object narrow_to_class
  (OZ_Object from, OZ_ClassPartID compiled_vid)
{
  OZ_Header all, o;

  all = (OZ_Header)OzExecGetObjectTop(from);
  for (o = (OZ_Header)from; o > all; o--)
    if (o->a == compiled_vid)
      return((OZ_Object)o);
#if	0
  OzDebugf("global-invoke.c: narrow_to_class: fail\n");
#endif
  return((OZ_Object)0);
}

void GiGlobalInvokeStub(OzRecvChannel chan)
{
  OZ_ClassID cvid;
  int slot1;
  int slot2;
  volatile int size;
  int code;
  void *args;
  char *fmt;
  Oz_ExceptionCatchTable exception_list;
  OZ_ExceptionRec e_rec;
  long long rval;
  OZ_MethodImplementationRec imp;
  int block ;
  void **ptr;
  volatile OZ_Object this;

  block = ThrBlockSuspend() ;
  
  if ( OzGIMonitor ) PkBiff() ;
  cvid = chan->ops->recv_cvid(chan);
  slot1 = chan->ops->recv_slot(chan);
  slot2 = chan->ops->recv_slot(chan);
  if (OtInvokePre(chan->o, slot1, slot2)) {
    chan->ops->send_return(chan, ERROR);
    chan->ops->free(chan);
    ThrUnBlockSuspend( block );
    return;
  }
  fmt = chan->ops->recv_fmt(chan);
  args = chan->ops->recv_args(chan);
       /* Set va_list from the 4th word. First 3 blank words are necessary. */
  size = *((int *)args) + 4;
       /* The size of data which exist on the stack (except that of OZ_Object)
	  'recv_args' set the size in the 1st word of 'args'. 
	  '4' means the size of OZ_Object. */
  if (size & 7)
    size = (size & ~7) + 8;			/* Round up by 8. */
  ThrRunningThread->args = args ;
  ThrRunningThread->arg_size = size + 8 ;
  if ((this = narrow_to_class(chan->o->object, cvid)) == 0) {
    chan->ops->send_return(chan, EXCEPTION);
    chan->ops->send_exception(chan, OzExceptionIllegalInvoke, chan->o->oid, 0);
    OtInvokePost(chan->o);
    ThrUnBlockSuspend( block ) ;
    return;
  }
  ptr = ((void **)args) + 2;
  *ptr = (void *)this;
  exception_list = chan->ops->recv_exception_list(chan);
  ExInitializeExceptionHandlerWith(&e_rec, exception_list);
  TRACE(this, chan->caller, chan->callee);
  OzExecRegisterExceptionHandlerFor(&e_rec);
  if ((code = SETJMP(e_rec.jmp)) == 0) {
    void *top = OzExecGetMethodImplementation ();
    OzExecFindMethodImplementation(&imp, *ptr, slot1, slot2);
    ThrUnBlockSuspend( block ) ;
    switch (*fmt) {
      /* 8bytes type(long long) */
    case 'l': case 'd': case 'P': case 'G': case 'Z':
      rval = (long long)
	((long long (*)())invoke)((void *)imp.function, size, args);
      break ;
      /* pointer type(void *) */
    case 'O': case 'S': case 'R': case 'A':
      rval = (long long)
	(int)(((void *(*)())invoke)((void *)imp.function, size, args));
      break ;
      /* 4bytes type(int) */
    case 'c': case 's': case 'i': case 'f':
      rval = (long long)
	((int (*)())invoke)((void *)imp.function, size, args);
      break ;
      /* void type */
    default:
      rval = 0 ;
      ((void (*)())invoke)((void *)imp.function, size, args);
    }
    ThrBlockSuspend() ;
    OzExecFreeMethodImplementation (top);
    OzExecUnregisterExceptionHandler();
    TRACE(this, chan->caller, chan->callee);
    chan->ops->send_return(chan, NORMAL);
    chan->ops->send_value(chan, rval);
  } else {
    ThrBlockSuspend() ;
    TRACE(this, chan->caller, chan->callee);
    chan->ops->send_return(chan, EXCEPTION);
    chan->ops->send_exception(chan, e_rec.eid, e_rec.param, e_rec.eimpl->fmt);
  }
  OtInvokePost(chan->o);
  chan->ops->free(chan);
  /*
   * Don't suspend after now becase of channel destroyed.
   */
  /* ThrUnBlockSuspend( block ) ; */
}
