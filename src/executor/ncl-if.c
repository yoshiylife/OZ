/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* unix system include */
#include <sys/types.h>
#include <netinet/in.h>
/* multithread system include */
#include "thread/signal.h"
#include "thread/thread.h"
#include "thread/monitor.h"
#include "oz++/ozlibc.h"

#include "switch.h"
#include "main.h"
#include "nif.h"
#include "fault-q.h"
#include "queue.h"
#include "ncl/ex_ncl_event.h"
#include "ncl/exec_table.h"
#include "executor/ncl-if.h"

#include "ex-addr-table.h"


#define FD_FOR_NLC  3
#define OMBC_FREE_QUEUE_MAX 10

#undef	DEBUG

/*
 *	Prototype declaration for C Library functions
 */
extern	void	bcopy( char *s1, char *s2, int len ) ;

typedef struct OzBroadcastRequestRec {
  FaultQueueRec header;
  EventDataRec content;
} OzBroadcastRequestRec, *OzBroadcastRequest;

typedef struct BQueueEltRec {
  struct BQueueEltRec *b_prev;
  struct BQueueEltRec *b_next;
} BQueueEltRec, *BQueueElt;

typedef struct BQueueRec {
  OZ_MonitorRec lock;
  int count;
  BQueueElt first;
} BQueueRec, *BQueue;

static inline void InitializeBQueue(BQueue queue)
{
  OzInitializeMonitor(&queue->lock);
  /* OzExecInitializeCondition(&queue->not_empty, 0); */
  InitQueueBinary(queue->first);
  queue->count = 0;
}

static inline void EnqueueIntoBQueue(BQueueElt elt, BQueue queue)
{
  OzExecEnterMonitor(&(queue->lock));
  InsertQueueBinary(elt, queue->first);
  queue->count++;
  OzExecExitMonitor(&(queue->lock));
}

static inline BQueueElt DequeueFromBQueue(BQueue queue)
{
  BQueueElt elt;

  OzExecEnterMonitor(&(queue->lock));
  if ( queue->first ) {
    elt = queue->first ;
    RemoveQueueBinary(elt, queue->first);
    queue->count--;
  } else elt = NULL ;
  OzExecExitMonitor(&(queue->lock));
  return(elt);
}

static inline BQueueElt RemoveFromBQueue(BQueueElt elt, BQueue queue)
{
  OzExecEnterMonitor(&(queue->lock));
  RemoveQueueBinary(elt, queue->first);
  queue->count--;
  OzExecExitMonitor(&(queue->lock));
  return(elt);
}

typedef struct ExecCreationRequestRec {
  BQueueEltRec header;
  EventDataRec content;
  OZ_MonitorRec lock;
  OZ_ConditionRec replied;
} ExecCreationRequestRec, *ExecCreationRequest;
  
extern struct sockaddr_in MyNetworkAddress;

/***
 ***       Basic functions
 ***/

static inline int read_from_ncl(char *buf, int len)
{
  return(OzRead(FD_FOR_NLC, buf, len));
}

int NifWriteToNcl(char *buf, int len)
{
  return(OzWrite(FD_FOR_NLC, buf, len));
}

/***
 ***       Functions for OM Broadcast
 ***/

void OzOmBroadcast(OZ_BroadcastParameterRec param)
{
  EventDataRec event;

  event.head.event_num = EN_SEARCH_C_N;
  bcopy((char *)(&param), (char *)(&(event.data.sc_name)), sizeof(param));
#if	defined(DEBUG)
  OzDebugf( "OzOmBroadcast(): NifWriteToNcl()\n" ) ;
#endif
  NifWriteToNcl((char *)(&event), sizeof(EventDataRec));
}

static FaultQueueRec bc_requests;
static FaultQueueRec free_ombc_requests; /* In order to reuse request
					    structs */

static void init_bc_ready_flg();
static void initializeOmBroadcast()
{
  FqInitializeFaultQueue(&(bc_requests));
  FqInitializeFaultQueue(&(free_ombc_requests));
  init_bc_ready_flg();
}

OZ_BroadcastParameterRec OzOmReceiveBroadcast() /* called by OM */
{
  OZ_BroadcastParameter param;
  OzBroadcastRequest request;

  request = (OzBroadcastRequest)FqReceiveRequest(&(bc_requests));
  param = (OZ_BroadcastParameter)OzMalloc(sizeof(OZ_BroadcastParameterRec));
  bcopy((char *)(&(request->content.data.sc_name)), (char *)(param),
	sizeof(OZ_BroadcastParameterRec));
  if (free_ombc_requests.count < OMBC_FREE_QUEUE_MAX)
    FqEnqueueIntoFreeQueue((FaultQueueElement)request, &free_ombc_requests);
  else
    OzFree(request);
#if	defined(DEBUG)
  OzDebugf( "OzOmReceiveBroadcast(): return\n" ) ;
#endif
  return(*(param));
}

static OzBroadcastRequest get_new_ombc_request();
static void OzNclReceiveBroadcast
  (OZ_BroadcastParameterRec data) /* called by daemon */
{
  OzBroadcastRequest request = get_new_ombc_request();
  bcopy((char *)&data, (char *)(&(request->content.data.sc_name)),
	sizeof(OZ_BroadcastParameterRec));
  FqEnqueueRequest((FaultQueueElement)request, &bc_requests);
#if	defined(DEBUG)
  OzDebugf( "OzNclReceiveBroadcast(): return\n" ) ;
#endif
}

static OzBroadcastRequest get_new_ombc_request()
{
  OzBroadcastRequest request;

  request = (OzBroadcastRequest)FqDequeueFromFreeQueue(&free_ombc_requests);
  if (!request)
    request = (OzBroadcastRequest)OzMalloc(sizeof(OzBroadcastRequestRec));
  return(request);
}

/***
 ***       Functions for Executor Creation
 ***/

static BQueueRec excr_requests;
static BQueueRec free_excr_requests; /* In order to reuse request
					structs */

static void initializeExcrBroadcast()
{
  InitializeBQueue(&(excr_requests));
  InitializeBQueue(&(free_excr_requests));
}

#define EXCR_FREE_QUEUE_MAX    10

static ExecCreationRequest get_new_excr_request()
{
  ExecCreationRequest request;

  request = (ExecCreationRequest)DequeueFromBQueue(&free_excr_requests);
  if (!request) {
    request = (ExecCreationRequest)OzMalloc(sizeof(ExecCreationRequestRec));
    OzInitializeMonitor(&(request->lock));
    OzExecInitializeCondition(&(request->replied), 0);
  }
  return(request);
}

OID /* i.e. exid */ OzOmCreatExecutor(long nclid, OID exid)
{
  OID new_exid;

  ExecCreationRequest request = get_new_excr_request();
  request->content.head.event_num = EN_CREAT_EXECUTOR;
  request->content.data.cr_exec.creat_nclid = nclid;
  request->content.data.cr_exec.inst_exid = exid;
  request->content.data.cr_exec.request_id = ThrRunningThread->tid ;
  EnqueueIntoBQueue((BQueueElt)request, &excr_requests);
  OzExecEnterMonitor(&(request->lock));
  NifWriteToNcl((char *)(&(request->content)), sizeof(EventDataRec));
  OzExecWaitCondition(&(request->lock), &(request->replied));
  OzExecExitMonitor(&(request->lock));
  new_exid = request->content.data.cr_exec.inst_exid;
  if (free_excr_requests.count < EXCR_FREE_QUEUE_MAX)
    EnqueueIntoBQueue((BQueueElt)request, &free_excr_requests);
  else
    OzFree(request);
  return(new_exid);
}

static void OzCreatReply(CreatExecutorRec data)
{
  int request_id;
  CreatExecutor content;
  BQueueElt rest, first;

  request_id = data.request_id;
  OzExecEnterMonitor(&(excr_requests.lock));
  first = (BQueueElt)0;
  for (rest = excr_requests.first; rest && (rest != first);
       rest = rest->b_next) {
    if (!first)
      first = rest;
    content = &(((ExecCreationRequest)rest)->content.data.cr_exec);
    if (content->request_id == request_id) {
      RemoveFromBQueue((BQueueElt)rest, &excr_requests);
      OzExecEnterMonitor(&(((ExecCreationRequest)rest)->lock));
      content->inst_exid = data.inst_exid;
      OzExecSignalCondition(&(((ExecCreationRequest)rest)->replied));
      OzExecExitMonitor(&(((ExecCreationRequest)rest)->lock));
    }
  }
  OzExecExitMonitor(&(excr_requests.lock));
}

/***
 ***       Broadcast Daemon
 ***       (This should be started from OM. Think about Exception.)
 ***/

static int om_bc_ready();
static void broadcast_daemon()
{
  EventDataRec event;
  char *ptr;
  int	ret ;

  while ( 1 ) {
    ret = read_from_ncl((char *)&event, sizeof(EventDataRec)) ;
    if ( ret != sizeof(EventDataRec) ) {
      OzError("OzBroadcastDaemon: read error from nucleus, ret = %d", ret);
      OzShutdownExecutor() ;
    }
    switch (event.head.event_num) {
    case NE_CREATED_EXID:
      ptr = (char *)OzMalloc(sizeof(CreatExecutorRec));
      bcopy((char *)(&(event.data.cr_exec)), ptr, sizeof(CreatExecutorRec));
      OzCreatReply(*(CreatExecutor)ptr);
      break;
    case NE_SOLUT_ADDR:
      ptr = (char *)OzMalloc(sizeof(SolutAddressRec));
      bcopy((char *)(&(event.data.so_addr)), ptr, sizeof(SolutAddressRec));
      AddressReply(*(SolutAddress)ptr);
      break;
    case NE_DOYOUKNOW_C_N:
      if (!(om_bc_ready()))
	break;
      ptr = (char *)OzMalloc(sizeof(OZ_BroadcastParameterRec));
      bcopy((char *)(&(event.data.sc_name)), ptr, sizeof(OZ_BroadcastParameterRec));
      OzNclReceiveBroadcast(*(OZ_BroadcastParameter)ptr);
      break;
    default:
      OzError("broadcast_daemon: Unknown event number");
      OzShutdownExecutor();
    }
  }
}

/***
 ***       Initialization of Broadcast Channel
 ***/

static EventData first_packet;

int NifGetFirstPacketFromNcl()
{
  int ret ;
  ThrAttachIO( FD_FOR_NLC ) ;
  first_packet = (EventData)OzMalloc(sizeof(EventDataRec));
  ret = OzRead(FD_FOR_NLC, (char *)first_packet, sizeof(EventDataRec));
  OzExecutorID = first_packet->data.cr_exec.inst_exid;
  return( ret ) ;
}

void startBroadcastDaemon()
{
  ThrFork(broadcast_daemon, 4096*4, /* priority */7, 0);
}

void NifSetPortNumber() /* Assumed being called after COM Initialization */
{
  first_packet->data.cr_exec.exaddress.sin_port
    = MyNetworkAddress.sin_port;
}

void NifStarted(int status)
{
  extern int	OzStandAlone ;

  if ( OzStandAlone ) return ;

  first_packet->head.event_num = EN_START_EXECUTOR;
  if (status != 0)
    first_packet->data.cr_exec.inst_exid = -1;
  NifWriteToNcl((char *)first_packet, sizeof(EventDataRec));
  OzFree(first_packet);
}

/***
 ***     Monitor for Readyness of OM Broadcast.
 ***/

static int is_broadcast_ready = 0;   /* see OzBroadcastReady() */
static OZ_MonitorRec bc_ready_flg_lock;

static void init_bc_ready_flg()
{
  is_broadcast_ready = 0;
  OzInitializeMonitor(&bc_ready_flg_lock);
}

void OzOmBroadcastReady()
{
  OzExecEnterMonitor(&bc_ready_flg_lock);
  is_broadcast_ready = 1;
  OzExecExitMonitor(&bc_ready_flg_lock);
}

int om_bc_ready()
{
  int result;

  OzExecEnterMonitor(&bc_ready_flg_lock);
  result = is_broadcast_ready;
  OzExecExitMonitor(&bc_ready_flg_lock);
  return(result);
}

/***
 ***     Shutdown OM
 ***/
static	struct	{
	OZ_MonitorRec	lock ;
	OZ_ConditionRec cond ;
	int		flag ;	/* Flag of state for request
				 *	Minus: no wait (initialize)
				 *	Zero : wait request
				 *	Plus : doing (requested)
				 */
} sd = { {}, {}, -1 } ;

static	void
nifHandlerSIGTERM( int signo, int code, GREGS *gregs, void *addr )
{
	/* CAUTION
	 * Debugger refer signo, code, gregs, addr by stack.
	 * Signal handler keep these variables on registers(arguments).
	 */
	ThrPrintf( "%s on thread %d [0x%x]\n", SigName(signo),
			ThrRunningThread->tid, ThrRunningThread ) ;
	if ( gregs ) {
		ThrPrintf( "code=%d pc=0x%x sp=0x%x addr=0x%x.\n",
			code, GREGS_PC(*gregs), GREGS_SP(*gregs), addr ) ;
	}

	OzExecEnterMonitor( &sd.lock ) ;
	if ( sd.flag == 0 ) {
		sd.flag = 1 ;
		OzExecSignalCondition( &sd.cond ) ;
	} else ThrPrintf( "Already shutdown in progress\n" ) ;
	OzExecExitMonitor( &sd.lock ) ;

	/*
	 * MOST IMPORTANT
	 * Following some lines don't remove becase to must be saved these.
	 */
	ThrPrintf( "RESUME thread %d [0x%x] from %s\n",
		ThrRunningThread->tid, ThrRunningThread, SigName(signo) ) ;
	if ( gregs ) {
		ThrPrintf( "code=%d pc=0x%x sp=0x%x addr=0x%x.\n",
			code, GREGS_PC(*gregs), GREGS_SP(*gregs), addr ) ;
	}
}

int
OzOmWaitShutdownRequest()
{
	int	result = -3 ;

	SigAction( SIGTERM, nifHandlerSIGTERM ) ;

	OzExecEnterMonitor( &sd.lock ) ;
	if ( sd.flag < 0 ) {
		sd.flag = 0 ;
		while ( ! sd.flag ) OzExecWaitCondition( &sd.lock, &sd.cond ) ;
		result = 0 ;
	} else result = -1 ;
	OzExecExitMonitor( &sd.lock ) ;

	return( result ) ;
}

int
OzOmShutdownRequest()
{
	int	result = -3 ;

	OzExecEnterMonitor( &sd.lock ) ;
	if ( sd.flag == 0 ) {
		sd.flag = 1 ;
		OzExecSignalCondition( &sd.cond ) ;
		result = 0 ;
	} else result = sd.flag > 0 ? -1 : -2 ;
	OzExecExitMonitor( &sd.lock ) ;

	return( result ) ;
}

/* Initialization of this module */
void NifInit()
{
  initializeOmBroadcast();
  initializeExcrBroadcast();
  startBroadcastDaemon();
  OzInitializeMonitor( &sd.lock ) ;
}
