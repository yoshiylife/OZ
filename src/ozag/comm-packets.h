/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* packet types for method invocation between executors */

#ifndef _COMM_PACKETS_H_
#define _COMM_PACKETS_H_

/* OZAG extention                                                       */
/* bit0 is used as TAIL flag. 						*/
/* Packet with TAIL flag means the last packet of those message-ID      */
/* bit1 is used as UNTRUST flag.					*/
/* Packet with UNTRUST flag means contents of the packet is untructable */ 

#define COMM_CALL_IND		0x01010000
#define COMM_CALL_ARG		0x01020000
#define COMM_ABORT		0x03010000
#define COMM_RESULT		0x04010000
#define COMM_EXCEPTION		0x04020000
#ifndef OZAG
#define COMM_ERROR		0x04030000
#else
#define COMM_TAIL_FLAG		0x00000001
#define COMM_TAIL_MASK		0xfffffffe
#define COMM_UNTRUST_MASK	0xfffffffd
/* #define COMM_UNTRUST_FLAG	0x00000002 */
#define COMM_UNTRUST_FLAG	0x00000000
#define COMM_UT_MASK            0xfffffffc

#define COMM_CALL_IND_U		(COMM_CALL_IND|COMM_UNTRUST_FLAG)
#define COMM_CALL_ARG_U		(COMM_CALL_ARG|COMM_UNTRUST_FLAG)
#define COMM_RESULT_T		(COMM_RESULT|COMM_TAIL_FLAG)
#define COMM_EXCEPTION_T	(COMM_EXCEPTION|COMM_TAIL_FLAG)
#define COMM_RESULT_U		(COMM_RESULT|COMM_UNTRUST_FLAG)
#define COMM_EXCEPTION_U	(COMM_EXCEPTION|COMM_UNTRUST_FLAG)
#define COMM_RESULT_TU		(COMM_CALL_IND|COMM_UNTRUST_FLAG|COMM_TAIL_FLAG)
#define COMM_EXCEPTION_TU	(COMM_EXCEPTION|COMM_UNTRUST_FLAG|COMM_TAIL_FLAG)
#define COMM_ERROR		(0x04030000|COMM_TAIL_FLAG)
#endif

typedef struct {
	long		kind;	
	long		arch_id;
	long long	msg_id;
} CommHeadRec, *CommHead;

typedef struct {
	CommHeadRec	head;
	long long	caller;
	long long	callee;
	long long	class_id;
	long		slot1;
	long		slot2;
	long long	proc_id;
} CommCallIndRec, *CommCallInd;

typedef struct {
        CommHeadRec     head;
        long            error_code;
} CommErrorRec, *CommError;

#define SZ_COMM_ERROR sizeof(CommErrorRec)

#endif _COMM_PACKETS_H_
