/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

typedef struct {
	enum {
		DEBUG_CONNECT, DEBUG_SOLUTADDR
	} deb_comm;
	union	{
		SolutAddressRec	so_addr;
	} data;
} DebugMentRec, *DebugMent;
