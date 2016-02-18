/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _APGW_MTHASH_H_
#define _APGW_MTHASH_H_
  
  /* hash routines for message table.					*/
  /* hash table is an associative list of message-Id(64bit) and OIDs of	*/
  /* caller and callee                                                  */

#define INIT_MSG_TABLE_SIZE	1024
#define MT_HASH_MASK	0xffffffffLL
  
  typedef struct _MesgTableRec {
    long long	mid;	/* MessageId		*/
    long long	caller;	/* OID of caller	*/
    long long	callee;	/* OID of callee	*/
  } MsgTableRec, *MsgTable;

#define	SZ_MSGTBL	sizeof(MsgTableRec)

#endif _APGW_MTHASH_H_
