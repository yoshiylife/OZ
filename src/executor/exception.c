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
#include "except.h"
#include "channel.h"
#include "debugSupport.h"
#include "executor/method-invoke.h"
#include "executor/exception.h"
#include "oz++/sysexcept.h"

extern	void	bcopy( char *s1, char *s2, int len ) ;

OZ_ExceptionIDRec OzExceptionDoubleFault        = { 0, -2 };
OZ_ExceptionIDRec OzExceptionAny                = { 0, -1 };
OZ_ExceptionIDRec OzExceptionAbort              = { 0,  1 };
OZ_ExceptionIDRec OzExceptionChildAborted       = { 0,  2 };
OZ_ExceptionIDRec OzExceptionObjectNotFound     = { 0,  3 };
OZ_ExceptionIDRec OzExceptionClassNotFound      = { 0,  4 };
OZ_ExceptionIDRec OzExceptionCodeNotFound       = { 0,  5 };
OZ_ExceptionIDRec OzExceptionLayoutNotFound     = { 0,  6 };
OZ_ExceptionIDRec OzExceptionGlobalInvokeFailed = { 0,  7 };
OZ_ExceptionIDRec OzExceptionNoMemory           = { 0,  8 };
OZ_ExceptionIDRec OzExceptionForkFailed         = { 0,  9 };
OZ_ExceptionIDRec OzExceptionKillSelf           = { 0, 10 };
OZ_ExceptionIDRec OzExceptionChildDoubleFault   = { 0, 11 };
OZ_ExceptionIDRec OzExceptionIllegalInvoke      = { 0, 12 };
OZ_ExceptionIDRec OzExceptionNarrowFailed       = { 0, 13 };
OZ_ExceptionIDRec OzExceptionArrayRangeOverflow = { 0, 14 };
OZ_ExceptionIDRec OzExceptionTypeCorrectionFailed = { 0, 15 };
OZ_ExceptionIDRec OzExceptionForeignAccessViolation = { 0, NO_SYS_EXCEPTION };

inline static int
eidcmp_aux(OZ_ExceptionIDRec x, OZ_ExceptionIDRec y)
{
  return (! ((x.cid == y.cid) && (x.val == y.val)));
}

int OzExecEidcmp(OZ_ExceptionIDRec x, OZ_ExceptionIDRec y)
{
  if ((eidcmp_aux(x, OzExceptionAny) == 0)
      || (eidcmp_aux(y, OzExceptionAny) == 0))
    return(0);
  if (eidcmp_aux(x, y) == 0)
    return(0);
  return(1);
}

void OzExecInitializeExceptionHandler(OZ_Exception e_rec, int n)
{
  OZ_ExceptionImpl eimpl
    = (OZ_ExceptionImpl)OzMalloc
	 (sizeof(ExceptionImplRec)
	  + (sizeof(OZ_ExceptionIDRec) * (n ? (n - 1) : 0)));
  eimpl->table.number_of_entries = n;
  eimpl->table.cnt = 0;
  e_rec->eimpl = eimpl;
  e_rec->eid = (OZ_ExceptionIDRec){0, 0};
  e_rec->param = 0;
  eimpl->next = (OZ_Exception)0;
  eimpl->fmt = 0;
  eimpl->handling = 0;
  eimpl->imp = 0;
}

void ExInitializeExceptionHandlerWith
  (OZ_Exception e_rec, Oz_ExceptionCatchTable exception_list)
{
  OzExecInitializeExceptionHandler(e_rec, exception_list->number_of_entries);
  e_rec->eimpl->table.number_of_entries = exception_list->number_of_entries;
  e_rec->eimpl->table.cnt = exception_list->cnt;
  bcopy((char *)(exception_list->exceptions),
	(char *)(&(e_rec->eimpl->table.exceptions)),
	sizeof(OZ_ExceptionIDRec) * (exception_list->number_of_entries));
  OzFree(exception_list);
}

void OzExecRegisterExceptionHandlerFor(OZ_Exception e_rec)
{
  e_rec->eimpl->next = (OZ_Exception)ThrRunningThread->exceptions;
  e_rec->eimpl->imp = (void *)ThrRunningThread->implementation_top;
  ThrRunningThread->exceptions = (void *)e_rec;
}

void OzExecUnregisterExceptionHandler()
{
  OZ_Exception next
    = ((OZ_Exception)ThrRunningThread->exceptions)->eimpl->next;

  OzFree(((OZ_Exception)ThrRunningThread->exceptions)->eimpl);
  ThrRunningThread->exceptions = (void *)next;
}

void OzExecRaise(OZ_ExceptionIDRec eid, long long param, char fmt)
{
  OZ_Exception e_rec;
  int	i;
  char	*name ;
  int	pid ;
  OzRecvChannel	recv ;

  if ( (recv=(OzRecvChannel)ThrRunningThread->channel) != NULL ) {
    pid = (int)(0x0ffffff & recv->pid) ;
  } else pid = 0 ;
  if (OzExecEidcmp(OzExceptionAbort, eid) == 0)
    goto found;
  if (OzExecEidcmp(OzExceptionDoubleFault, eid) == 0)
    goto found;
  for (e_rec = (OZ_Exception)ThrRunningThread->exceptions;
       e_rec;
       e_rec = e_rec->eimpl->next)
    for (i = 0; i < e_rec->eimpl->table.number_of_entries; i++)
      if (OzExecEidcmp(e_rec->eimpl->table.exceptions[i], eid)== 0)
	goto found;
  /* log */
  if ( eid.cid == 0LL && (name=DsExceptionName( eid.val )) != 0 ) {
    ThrPrintf( "Exception not caught:\t%s(%016lx)\n", name, param) ;
  } else {
    ThrPrintf( "Exception not caught:\t%016lx:%08x(%016lx:%c)\n",
			eid.cid, eid.val, param, (fmt==0) ? 'v' : fmt ) ;
  }
  if ( DsCheckException( 'N' ) ) DsTrapException( 'N', &eid, param, fmt ) ;
  /* after debug, clean up thread by ReRaise Exception */
  OzExecRaise(OzExceptionAbort, pid, 0);
 found:
  if (OzExecEidcmp(eid, OzExceptionDoubleFault) != 0
      && (((OZ_Exception)ThrRunningThread->exceptions)->eimpl->handling)) {
    /* log */
    if ( eid.cid == 0LL && (name=DsExceptionName( eid.val )) != 0 ) {
      ThrPrintf( "Exception double fault:\t%s(%016lx)\n", name, param ) ;
    } else {
      ThrPrintf( "Exception double fault:\t%016lx:%08x(%016lx:%c)\n",
			eid.cid, eid.val, param, (fmt==0) ? 'v' : fmt ) ;
    }
    if ( DsCheckException( 'F' ) ) DsTrapException( 'F', &eid, param, fmt ) ;
    OzExecRaise(OzExceptionDoubleFault, pid, 0);
  }
  ((OZ_Exception)ThrRunningThread->exceptions)->eid = eid;
  ((OZ_Exception)ThrRunningThread->exceptions)->param = param;
  ((OZ_Exception)ThrRunningThread->exceptions)->eimpl->fmt = fmt;
  /* log */
  if ( eid.cid == 0LL && (name=DsExceptionName( eid.val )) != 0 ) {
    OzDebugf( "Exception caught:\t%s(%016lx)\n", name, param ) ;
  } else {
    OzDebugf( "Exception caught:\t%016lx:%08x(%016lx:%c)\n",
			eid.cid, eid.val, param, (fmt==0) ? 'v' : fmt ) ;
  }
  if ( DsCheckException( 'C' ) ) DsTrapException( 'C', &eid, param, fmt ) ;
#if 1
  OzExecFreeMethodImplementation
    ((OZ_MethodImplementation)
     (((OZ_Exception)ThrRunningThread->exceptions)->eimpl->imp));
#endif
  LONGJMP(((OZ_Exception)ThrRunningThread->exceptions)->jmp, 1);
  /* NOT REACHED */
}

void OzExecReRaise()
{
  OZ_Exception e_rec;
  char *name ;
  int	pid ;
  OzRecvChannel	recv ;

  if ( (recv=(OzRecvChannel)ThrRunningThread->channel) != NULL ) {
    pid = (int)(0x0ffffff & recv->pid) ;
  } else pid = 0 ;
  if ((e_rec = (OZ_Exception)ThrRunningThread->exceptions)) {
    if (e_rec->eimpl->next) {
      if (OzExecEidcmp(e_rec->eid, OzExceptionDoubleFault) != 0
	  && e_rec->eimpl->next->eimpl->handling) {
        /* log */
        if ( e_rec->eid.cid == 0LL
		&& (name=DsExceptionName( e_rec->eid.val )) != 0 ) {
          ThrPrintf( "Exception double fault:\t%s(%016lx)\n",
				name, e_rec->param ) ;
        } else {
          ThrPrintf( "Exception double fault:\t%016lx:%08x(%016lx:%c)\n",
		    e_rec->eid.cid, e_rec->eid.val, e_rec->param,
			(e_rec->eimpl->fmt==0) ? 'v' : e_rec->eimpl->fmt ) ;
        }
        if ( DsCheckException( 'F' ) )
          DsTrapException( 'F', &e_rec->eid, e_rec->param, e_rec->eimpl->fmt ) ;
	OzExecRaise(OzExceptionDoubleFault, pid, 0);
      }
      ThrRunningThread->exceptions = (void *)(e_rec->eimpl->next);
      ((OZ_Exception)ThrRunningThread->exceptions)->eid = e_rec->eid;
      ((OZ_Exception)ThrRunningThread->exceptions)->param = e_rec->param;
      ((OZ_Exception)ThrRunningThread->exceptions)->eimpl->fmt
	= e_rec->eimpl->fmt;
      /* log */
      if ( e_rec->eid.cid == 0LL
		&& (name=DsExceptionName( e_rec->eid.val )) != 0 ) {
        OzDebugf( "Exception reraise:\t%s(%016lx)\n", name, e_rec->param ) ;
      } else {
        OzDebugf( "Exception reraise:\t%016lx:%08x(%016lx:%c)\n",
		  e_rec->eid.cid, e_rec->eid.val, e_rec->param,
			(e_rec->eimpl->fmt==0) ? 'v' : e_rec->eimpl->fmt ) ;
      }
      if ( DsCheckException( 'R' ) )
        DsTrapException( 'R', &e_rec->eid, e_rec->param, e_rec->eimpl->fmt ) ;
      OzFree(e_rec->eimpl);
      OzExecFreeMethodImplementation
	((OZ_MethodImplementation)
	 (((OZ_Exception)ThrRunningThread->exceptions)->eimpl->imp));
      /* OzExecUnregisterExceptionHandler(); */
      LONGJMP(((OZ_Exception)ThrRunningThread->exceptions)->jmp, 1);
      /* NOT REACHED */
    } else {
      /* in case of aborting process */
    }
  }
  /* case of cleanup after debug */
#if 0
  OzExecFreeMethodImplementation(0);
#endif
  ThrExit();
  /* NOT REACHED */
}

struct exception_list {
  int max_entries;
  Oz_ExceptionCatchTable catches;
};

static	void
insert_entry(struct exception_list *list, OZ_ExceptionIDRec id)
{
  int i;
  Oz_ExceptionCatchTable old;

  for (i = 0; i < list->catches->number_of_entries; i++)
    if (OzExecEidcmp(list->catches->exceptions[i], id) == 0)
      return;
  if (list->max_entries == list->catches->number_of_entries) {
    list->max_entries += 10;
    old = list->catches;
    list->catches =
      (Oz_ExceptionCatchTable)OzRealloc
	(list->catches, sizeof(Oz_ExceptionCatchTableRec)
	 + (list->max_entries + 9) * sizeof(OZ_ExceptionIDRec));
#if	0
	/* Do't free, becase of realloc spec. */
    if (list->catches != old)
      OzFree(old);
#endif
  }
  list->catches->exceptions[list->catches->number_of_entries++] = id;
}

Oz_ExceptionCatchTable ExMergeExceptionList(void)
{
  OZ_Exception e_rec;
  Oz_ExceptionCatchTable table;
  struct exception_list list;
  int	i;
  
  list.max_entries = 10;
  list.catches = (Oz_ExceptionCatchTable)OzMalloc
    (sizeof(Oz_ExceptionCatchTableRec) + 9 * sizeof(OZ_ExceptionIDRec));
  list.catches->number_of_entries = 0;
  for (e_rec = (OZ_Exception)ThrRunningThread->exceptions;
       e_rec;
       e_rec = e_rec->eimpl->next) {
    table = &(e_rec->eimpl->table);
    for (i = 0; i < table->number_of_entries; i++) {
      if (eidcmp_aux(table->exceptions[i], OzExceptionAny) == 0) {
	list.catches->number_of_entries = 1;
	list.catches->exceptions[0] = OzExceptionAny;
	return(list.catches);
      }
      insert_entry(&list, table->exceptions[i]);
    }
  }
  return(list.catches);
}

void OzExecPutEidIntoCatchTable(OZ_Exception e_rec, OZ_ExceptionIDRec eid)
{
  e_rec->eimpl->table.exceptions[e_rec->eimpl->table.cnt++] = eid;
}

void OzExecHandlingException(OZ_Exception e_rec)
{
  e_rec->eimpl->handling = 1;
}
