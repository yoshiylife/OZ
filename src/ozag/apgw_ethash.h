/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _APGW_ETHASH_H_
#define _APGW_ETHASH_H_
  
  /* hash routines for executor table.					*/
  /* hash table is an associative list of message-Id(64bit) and pointer	*/
#define INIT_EXEC_TABLE_SIZE	1024
#define ET_HASH_MASK	0xffffffLL

  typedef enum {ET_LOCAL, ET_INSITE, ET_OUTSITE}
    executor_location;

  typedef struct _ExecTableRec {
    long long		eid;
    struct sockaddr_in	addr;
    executor_location loc;
/*    SendPort waiting; */
  } ExecTableRec, *ExecTable;

#define	SZ_EXTBL	sizeof(ExecTableRec)

#endif _APGW_ETHASH_H_
