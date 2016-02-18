/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* unix system include */
#include <stdarg.h>
/* multithread system include */
#include "thread/thread.h"
#include "thread/monitor.h"
#include "oz++/ozlibc.h"

#include "switch.h"
#include "channel.h"
#include "common.h"
#include "mem.h"
#include "ot.h"
#include "g-invoke.h"
#include "oz++/type.h"

#define RECORD_USABLE

extern void bcopy(char *b1, char *b2, int len);
extern int bzero(char *b, int len);

typedef	struct	local_channel	{
	OzSendChannelRec	send_channel;
	OzRecvChannelRec	recv_channel;

	/* other */
	OZ_MonitorRec	lock;
	OZ_ConditionRec	send_wait;
	OZ_ConditionRec	recv_wait;
	int	send_done;
	int	recv_done;
	int	ref_count;

	/* for send params */
	int	recv_slot_id;

	/* for recv value */
	int	ret_type;
	long long	rval;
	OZ_ExceptionIDRec exception;
	long long eparam;
	char efmt;
	int	aborted;
        ObjectTableEntry	o;	/* callee's heap entry */
} local_channel;

inline static void lcBlockGcForSender(local_channel *l_chan)
{
  ObjectTableEntry entry = ((OzRecvChannel)ThrRunningThread->channel)->o;
#ifndef	GC_OM
  if ((entry->oid & 0xffffffLL) != 0x1LL) {
#endif	!GC_OM
    l_chan->o = OtGetEntryRaw(entry->oid) ;
    MmBlockGc(entry->heap);
#ifndef	GC_OM
  }
#endif	!GC_OM
}

inline static void lcUnBlockGcForSender(OID oid, local_channel *l_chan)
{
#ifndef	GC_OM
  if ((oid & 0xffffffLL) != 0x1LL) {
#endif	!GC_OM
    MmUnBlockGc(l_chan->o->heap);
    OtReleaseEntry( l_chan->o ) ;
#ifndef	GC_OM
  }
#endif	!GC_OM
}

inline static ObjectTableEntry lcBlockGcForReceiver()
{
  ObjectTableEntry entry = ((OzRecvChannel)ThrRunningThread->channel)->o;
#ifndef	GC_OM
  if ((entry->oid & 0xffffffLL) != 0x1LL) {
#endif	!GC_OM
    MmBlockGc(entry->heap);
    return entry;
#ifndef	GC_OM
  }
#endif	!GC_OM
  return 0;
}

inline static void lcUnBlockGcForReceiver(ObjectTableEntry entry)
{
  if (entry)
    MmUnBlockGc(entry->heap);
}

inline static local_channel *send_to_local_channel(OzSendChannel chan)
{
	return((local_channel *)chan);
}

inline static local_channel *recv_to_local_channel(OzRecvChannel chan)
{
	return (local_channel *)chan->vars.peer.schan ;
}

static void local_channel_free(local_channel *);

/* send routines */

static void send_cvid(OzSendChannel chan, OID cvid)
{
	chan->peer.rchan->vars.cvid = cvid;
}

static void send_slot(OzSendChannel chan, int slot1, int slot2)
{
	chan->peer.rchan->vars.slot1 = slot1;
	chan->peer.rchan->vars.slot2 = slot2;
}

static void send_args(OzSendChannel chan, char *fmt, va_list args)
{
#if 0
        local_channel *l_chan = send_to_local_channel(chan);
        lcBlockGcForSender(l_chan);
#endif
	chan->peer.rchan->vars.fmt = fmt;
	chan->peer.rchan->vars.args = args;
}

static void send_exception_list(OzSendChannel chan,
			   Oz_ExceptionCatchTable exception_list)
{
	local_channel	*l_chan;

	l_chan = send_to_local_channel(chan);

	l_chan->recv_channel.vars.elist = exception_list;

	OzExecEnterMonitor(&(l_chan->lock));
	l_chan->send_done = 1;
	OzExecSignalCondition(&(l_chan->send_wait));
	OzExecExitMonitor(&(l_chan->lock));
}

static int recv_return(OzSendChannel chan)
{
	local_channel	*l_chan;

	l_chan = send_to_local_channel(chan);
	OzExecEnterMonitor(&(l_chan->lock));
	if (!l_chan->recv_done)
		OzExecWaitCondition(&(l_chan->lock), &(l_chan->recv_wait));
	OzExecExitMonitor(&(l_chan->lock));
	if (l_chan->aborted)
		ThrAbortThread(ThrRunningThread);
	return(l_chan->ret_type);
}

static	OZ_Header	traverse(OZ_Header root, Heap heap) ;
#ifdef RECORD_USABLE
static	OZ_Header	copy_record(OZ_Header old, Heap heap) ;
#endif RECORD_USABLE
static long long recv_value(OzSendChannel chan)
{
	local_channel	*l_chan;
	char	*fmt;
	ObjectTableEntry entry = lcBlockGcForReceiver();

	l_chan = send_to_local_channel(chan);

	fmt = l_chan->recv_channel.vars.fmt ;
	switch ( *fmt ) {
	case 'A':
	case 'O':
	case 'S':
		l_chan->rval = (long long)
		  ((int)traverse( (OZ_Header)(int)l_chan->rval,
			((OzRecvChannel)ThrRunningThread->channel)->o->heap ));
		break ;
	/* RECORD must be copied into object heap. */
	case 'R':
		l_chan->rval = (long long)
		  ((int)copy_record( (OZ_Header)(int)l_chan->rval,
			((OzRecvChannel)ThrRunningThread->channel)->o->heap ));
		break ;
        default:
		/* Do nothing */
	}

	lcUnBlockGcForSender(l_chan->recv_channel.o->oid, l_chan);
	lcUnBlockGcForReceiver(entry);

	return( l_chan->rval );
}

static OZ_ExceptionIDRec recv_exception(OzSendChannel chan)
{
	local_channel	*l_chan;

	l_chan = send_to_local_channel(chan);
	return(l_chan->exception);
}

static char recv_exception_fmt(OzSendChannel chan)
{
	local_channel	*l_chan;

	l_chan = send_to_local_channel(chan);
	return(l_chan->efmt);
}

static long long recv_exception_param(OzSendChannel chan)
{
	local_channel	*l_chan;
	ObjectTableEntry entry = lcBlockGcForReceiver();

	l_chan = send_to_local_channel(chan);
	switch ( l_chan->efmt ) {
	case 'A':
	case 'O':
	case 'S':
		l_chan->eparam = (long long)
		  ((int)traverse( (OZ_Header)(int)l_chan->eparam,
			((OzRecvChannel)ThrRunningThread->channel)->o->heap ));
		break ;
	/* RECORD must be copied into object heap. */
        case 'R':
		l_chan->eparam = (long long)
		  ((int)copy_record( (OZ_Header)(int)l_chan->eparam,
			((OzRecvChannel)ThrRunningThread->channel)->o->heap ));
		break ;
	default:
		/* Do nothing */
	}
	lcUnBlockGcForSender(l_chan->recv_channel.o->oid, l_chan);
	lcUnBlockGcForReceiver(entry);

	return( l_chan->eparam );
}

static	void	send_abort(OzSendChannel chan)
{
	local_channel	*l_chan;

	l_chan = send_to_local_channel(chan);
	OzExecEnterMonitor(&(l_chan->lock));
	if (l_chan->recv_channel.vars.next) {
		l_chan->recv_channel.vars.next->ops->send_abort(l_chan->recv_channel.vars.next);
		/* l_chan->recv_channel.vars.next = 0 ; */
	} else
		ThrAbortThread(l_chan->recv_channel.t);
	OzExecExitMonitor(&(l_chan->lock));
}

static	void	send_free(OzSendChannel chan)
{
	local_channel_free(send_to_local_channel(chan));
}

static	OzSendChannelOpsRec	send_ops = {
	send_cvid,
	send_slot,
	send_args,
	send_exception_list,
	recv_return,
	recv_value,
	recv_exception,
	recv_exception_fmt,
	recv_exception_param,
	send_abort,
	send_free,
};

/* recv routines */

static OID recv_cvid(OzRecvChannel chan)
{
	local_channel	*l_chan;

	l_chan = recv_to_local_channel(chan);

	OzExecEnterMonitor(&(l_chan->lock));
	if (!l_chan->send_done)
		OzExecWaitCondition(&(l_chan->lock), &(l_chan->send_wait));
	OzExecExitMonitor(&(l_chan->lock));

	return( l_chan->recv_channel.vars.cvid ) ;
}

static int recv_slot(OzRecvChannel chan)
{
	local_channel	*l_chan;

	l_chan = recv_to_local_channel(chan);

	if (l_chan->recv_slot_id++ == 0)
		return(l_chan->recv_channel.vars.slot1);
	else
		return(l_chan->recv_channel.vars.slot2);
}

static char *recv_format(OzRecvChannel chan)
{
	return(chan->vars.fmt);
}

/* traverse and copy object routines */

/* copy object to new heap */
struct	copy_context	{
	void	*fifo;
	void	*hash;
	Heap	heap;
};

static	int copy_object(OZ_Header *o, struct copy_context *context)
{
	OZ_Header old, new;
	int	rval = 0;
	int	adjust = 0;
	int	i, diff;

	old = *o;
	if (old->h == LOCAL) {
		old -= (adjust = old->e + 1);
	}
	if (!(new = (OZ_Header)OzSearchHash(context->hash, old))) {
	        unsigned int new_size = old->e;

		rval = 1;
		new = (OZ_Header)MmAlloc(context->heap, &new_size);
		bcopy((char *)old, (char *)new, old->e);
	        new->e = new_size;
		OzEnterHash(context->hash, old, new);
		diff = (int)new - (int)old;
		if ( adjust ) {
			for (i = 1; i <= new->h; i++)
				new[i].d += diff;
			new[0].t += diff;
			OzInitializeMonitor((OZ_Monitor)(new->t));
		}
	}
	*o = new + adjust;
	return(rval);
}

static void
traverse_alloc_info(OZ_AllocateInfo ainfo, struct copy_context *context)
{
	OZ_Header	*hp;
	int	i;

	hp = (OZ_Header *)(ainfo + 1);
	for (i = 0; i < ainfo->number_of_pointer_protected; i++) {
		if (*hp && copy_object(hp, context))
			OzPutFifo(context->fifo, *hp);
		hp++;
	}
	hp += (ainfo->number_of_pointer_protected & 1);
	hp += ainfo->data_size_protected / sizeof(OZ_Header *);
	/* initialize protected condition variables */
	for (i = 0; i < ainfo->zero_protected; i++) {
	        OzExecInitializeCondition((OZ_Condition)hp, 1);
		hp += (sizeof(OZ_ConditionRec)/sizeof(OZ_Header *));
	}
	for (i = 0; i < ainfo->number_of_pointer_private; i++) {
		if (*hp && copy_object(hp, context))
			OzPutFifo(context->fifo, *hp);
		hp++;
	}
	/* skip to the zero region */
	hp += (ainfo->number_of_pointer_private & 1);
	hp += ainfo->data_size_private / sizeof(OZ_Header *);
	/* initialize private condition variables */
	for (i = 0; i < ainfo->zero_private; i++) {
	        OzExecInitializeCondition((OZ_Condition)hp, 1);
		hp += (sizeof(OZ_ConditionRec)/sizeof(OZ_Header *));
	}
}

static	
OZ_Header traverse(OZ_Header root, Heap heap)
{
	int		i;
	OZ_Header	o, all;
	OZ_Header	*hp;
	struct	copy_context context;

	if (!root)
		return(root);

	context.fifo = (void *)OzCreateFifo();
	context.hash = (void *)OzCreateHash();
	context.heap = heap;

	if (copy_object(&root, &context))
		OzPutFifo(context.fifo, root);

	while ((o = (OZ_Header)OzGetFifo(context.fifo))) {
		switch (o->h) {
		case LOCAL:		/* object part */
			all = o - (o->e + 1);
			for (i = 0, o = all + 1; /*o->e*/i < all->h; i++, o++)
				traverse_alloc_info(o->d, &context);
			break;
		case STATIC:		/* static object */
			traverse_alloc_info((OZ_AllocateInfo)(o + 1),
					    &context);
			break;
		default:		/* array */
			if ((o->a != OZ_LOCAL_OBJECT) &&
			    (o->a != OZ_STATIC_OBJECT) &&
			    (o->a != OZ_ARRAY))
				break;
			hp = (OZ_Header *)(o + 1);
			for (i = 0; i < o->h; i++) {
				if ( *hp && copy_object(hp, &context))
					OzPutFifo(context.fifo, *hp);
				hp++;
			}
			break;
		}
	}
	OzFreeFifo(context.fifo);
	OzFreeHash(context.hash);
	return(root);
}

#ifdef RECORD_USABLE
static
OZ_Header copy_record(OZ_Header old, Heap heap)
{
  OZ_Header new;
  unsigned int new_size = old->e;
  
  new = (OZ_Header)MmAlloc(heap, &new_size);
  bcopy((char *)old, (char *)new, old->e);
  new->e = new_size;
  return new;
}
#endif RECORD_USABLE

static void *recv_args(OzRecvChannel chan)
{
	char	type, *fmt;
	void	*args;
	int	arg_size = 0;
#if 0
	local_channel *l_chan = recv_to_local_channel(chan);
#endif
	ObjectTableEntry obj_ent = lcBlockGcForReceiver();

	/* traverse object and change ptrs in args */
	fmt = chan->vars.fmt;
	args = chan->vars.args;
#ifndef RECORD_USABLE
	if (*fmt++ == 'R') {
		*((int *)args) = *((int *)args) + 8;
		args += 4;
	}
	while ((type = *fmt++)) {
		switch (type) {
		case 'l':
		case 'd':
		case 'P':
		case 'G':
		case 'Z':
			arg_size = 8;
			break;
		case 'A':
		case 'O':
		case 'S':
			*((OZ_Header *)args) =
				traverse(*((OZ_Header *)args), chan.o->heap);
		case 'v':
		case 'i':
		case 'f':
		case 'R':
		case 's':	/* sun word(4byte) alignment */
		case 'c':	/* sun word(4byte) alignment */
			arg_size = 4 ;
			break ;
		}
		args += arg_size;
	}
#else   /* in case RECORD_USABLE */
	fmt++;
	while ((type = *fmt++)) {
		switch (type) {
		case 'l':
		case 'd':
		case 'P':
		case 'G':
		case 'Z':
			arg_size = 8;
			break;
		case 'A':
		case 'O':
		case 'S':
			*((OZ_Header *)args) =
				traverse(*((OZ_Header *)args),chan->o->heap);
			arg_size = 4;
			break;
		case 'R':
			*((OZ_Header *)args) =
				copy_record(*((OZ_Header *)args),chan->o->heap);
			arg_size = 4;
			break;
		case 'v':
		case 'i':
		case 'f':
		case 's':	/* sun word(4byte) alignment */
		case 'c':	/* sun word(4byte) alignment */
			arg_size = 4 ;
			break;
		}
		args += arg_size;
	}
#endif  /* RECORD_USABLE */
	arg_size = (args - (void *)chan->vars.args);

	chan->vars.args -= 12;
	*(int *)(chan->vars.args) = arg_size;

#if 0
	lcUnBlockGcForSender(chan->caller, l_chan);
#endif
	lcUnBlockGcForReceiver(obj_ent);

	return(chan->vars.args);
}

static	Oz_ExceptionCatchTable 	recv_exception_list(OzRecvChannel chan)
{

	OzExecEnterMonitor( &chan->vars.lock ) ;
	chan->vars.readyToInvoke = 1 ;
	OzExecExitMonitor( &chan->vars.lock ) ;

	return(chan->vars.elist);
}

static void send_return(OzRecvChannel chan, int	ret_type)
{
	local_channel	*l_chan;

	l_chan = recv_to_local_channel(chan);
	l_chan->ret_type = ret_type;
	OzExecEnterMonitor( &l_chan->send_channel.prev->vars.lock ) ;
	l_chan->send_channel.prev->vars.next = 0 ;
	OzExecExitMonitor( &l_chan->send_channel.prev->vars.lock ) ;
	l_chan->aborted = ThrRunningThread->aborted;
#if 1
	if (ret_type == ERROR) {
	  OzExecEnterMonitor(&(l_chan->lock));
	  l_chan->recv_done = 1;
	  OzExecSignalCondition(&(l_chan->recv_wait));
	  OzExecExitMonitor(&(l_chan->lock));
	}
#endif
}

static void send_value(OzRecvChannel chan, long long rval)
{
	local_channel	*l_chan;
	l_chan = recv_to_local_channel(chan);

 	lcBlockGcForSender(l_chan);

	l_chan->send_channel.vars.rval = l_chan->rval = rval;

	OzExecEnterMonitor(&(l_chan->lock));
	l_chan->recv_done = 1;
	OzExecSignalCondition(&(l_chan->recv_wait));
	OzExecExitMonitor(&(l_chan->lock));
}

static void send_exception
  (OzRecvChannel chan, OZ_ExceptionIDRec eid, long long param, char fmt)
{
	local_channel	*l_chan;

	l_chan = recv_to_local_channel(chan);
	l_chan->exception = eid;
 	lcBlockGcForSender(l_chan);
	l_chan->send_channel.vars.eparam = l_chan->eparam = param;
	l_chan->efmt = fmt;
	OzExecEnterMonitor(&(l_chan->lock));
	l_chan->recv_done = 1;
	OzExecSignalCondition(&(l_chan->recv_wait));
	OzExecExitMonitor(&(l_chan->lock));
}

static	void	recv_free(OzRecvChannel chan)
{
	OzExecEnterMonitor( &chan->vars.lock ) ;
	chan->vars.readyToInvoke =  0 ;
	OzExecExitMonitor( &chan->vars.lock ) ;

	local_channel_free(recv_to_local_channel(chan));
}

static	OzRecvChannelOpsRec	recv_ops = {
	recv_cvid,
	recv_slot,
	recv_format,
	recv_args,
	recv_exception_list,
	send_return,
	send_value,
	send_exception,
	recv_free
};

/* channel creation */

OzSendChannel
LcCreateLocalChannel(OID caller, OID callee)
{
	OZ_Thread	t;
	local_channel *l_chan;

	l_chan = (local_channel *)OzMalloc(sizeof(local_channel));
	(void)bzero((char *)l_chan, sizeof(local_channel));
	l_chan->send_channel.ops = &send_ops;
	l_chan->send_channel.callee = callee ;
	l_chan->send_channel.peer.rchan = &l_chan->recv_channel ;
	l_chan->send_channel.prev = (OzRecvChannel)ThrRunningThread->channel ;
	l_chan->recv_channel.ops = &recv_ops;
	l_chan->recv_channel.callee = callee;
	l_chan->recv_channel.caller = caller;
	l_chan->recv_channel.o = OtGetEntryRaw(callee);
	if ( ! l_chan->recv_channel.o ) {
		OzFree( l_chan ) ;
		return( NULL ) ;
	}
	l_chan->recv_channel.pid =
				((OzRecvChannel)ThrRunningThread->channel)->pid;
	OzInitializeMonitor( &l_chan->recv_channel.vars.lock ) ;
	l_chan->recv_channel.vars.peer.schan = &l_chan->send_channel ;
	l_chan->recv_channel.vars.next = 0 ;
	l_chan->recv_channel.vars.readyToInvoke = 0 ;
	OzInitializeMonitor(&(l_chan->lock));
	OzExecInitializeCondition(&(l_chan->send_wait), 0);
	OzExecInitializeCondition(&(l_chan->recv_wait), 0);
	l_chan->ref_count = 2;		/* send & recv */
	l_chan->recv_slot_id = 0;
	t = ThrCreate(GiGlobalInvokeStub,&(l_chan->recv_channel),
			   4096 * 10, 3, OzDebugFlags, 1,
			   &(l_chan->recv_channel));
	if ( t == NULL ) {
		OzFree( l_chan ) ;
		return( NULL ) ;
	}
	l_chan->recv_channel.t = t;
	l_chan->send_channel.prev = (OzRecvChannel)ThrRunningThread->channel ;
	OzExecEnterMonitor( &l_chan->send_channel.prev->vars.lock ) ;
	l_chan->send_channel.prev->vars.next = &l_chan->send_channel ;
	OzExecExitMonitor( &l_chan->send_channel.prev->vars.lock ) ;
	ThrSchedule( t ) ;
	if ( ThrClearThread(ThrRunningThread) ) {
		ThrAbortThread( t ) ;
	}

	return(&(l_chan->send_channel));
}

static	void local_channel_free(local_channel *l_chan)
{
	int	ref_count;

	OzExecEnterMonitor(&(l_chan->lock));
	ref_count = --l_chan->ref_count;
	OzExecExitMonitor(&(l_chan->lock));
	if (!ref_count) {
	        /* OzFree(l_chan->recv_channel.vars.elist); */
		/* commented because 'ExInitializeExceptionHandlerWith'
		 * frees it. */
		OtReleaseEntry( l_chan->recv_channel.o ) ;
		OzFree(l_chan);
	}
}
