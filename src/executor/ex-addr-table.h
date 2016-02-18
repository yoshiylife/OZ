/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _EX_ADDR_TABLE_H_
#define _EX_ADDR_TABLE_H_

#include "ncl/ex_ncl_event.h"

typedef struct _AddressReqRec {
	EventDataRec    ed;
	OZ_ConditionRec	ready;
	int		ref_count;
} AddressReqRec, *AddressReq;

extern ExecTable AddressRequest(long long exid);
extern void AddressReply(SolutAddressRec data);

#endif /* _EX_ADDR_TABLE_H_ */
