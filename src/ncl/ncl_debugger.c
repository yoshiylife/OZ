/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <sys/types.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <stdlib.h>

#include "ncl.h"
#include "ncl_defs.h"
#include "ex_ncl_event.h"
#include "ncl_debugger.h"

extern NclEnvRec	envofncl;

extern RequestTbl	get_requesttbl();
extern void		en_unknown_exid(EventData hp);
extern char		*ipaddr2str(long ll);

static void	deb_solutaddr(EventData hp)
{
EventDataRec	hh;
DebugMent	dp;

#ifdef	DEBUG
printf(" + Received Message(SOLUT_ADDR) from DEBUGGER\n");
#endif
	bzero((char *)&hh, SZ_EventData);
	hp->head.req_exfd	= hp->head.req_nclfd;
	bcopy((char *)&(hp->head), (char *)&(hh.head), sizeof(EventHeaderRec));
	dp	= (DebugMent)hp->data.data;
	bcopy((char *)&(dp->data.so_addr), (char *)&(hh.data.so_addr), sizeof(SolutAddressRec));
	en_unknown_exid(&hh);
}

void	ncl_deb_command(EventData hp)
{
RequestTbl	rtp;
DebugMent	dp;

	
	dp	= (DebugMent)hp->data.data;
	switch(dp->deb_comm) {
		case DEBUG_CONNECT:
			rtp	= get_requesttbl();
			rtp->fd = hp->head.req_nclfd;
			rtp->con |= DEB_CONNECTED;
			return;
		case DEBUG_SOLUTADDR:
			deb_solutaddr(hp);
			return;
		default:
			printf("ncl_deb_command: Illegal command 0x%x\n", dp->deb_comm);
			return;
	}
}
