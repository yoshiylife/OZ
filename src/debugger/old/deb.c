/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <sys/types.h> 
#include <sys/time.h> 
#include <sys/socket.h> 
#include <sys/stat.h> 
#include <sys/ioctl.h> 
#include <sys/file.h> 
#include <net/if.h> 
#include <netinet/in.h> 
#include <nlist.h> 
#include <stdio.h> 
#include <signal.h> 
#include <errno.h> 
#include <utmp.h> 
#include <ctype.h>
#include <netdb.h>
#include <syslog.h>

#include "ncl_defs.h"
#include "ex_ncl_event.h"
#include "ncl_debugger.h"

#define	TSUIKA

struct sockaddr_in	ncl_sin;

static int	strhtoi(char *str)
{
int		n, i;
unsigned int	m, g;
char		*p;

static char	hd[] = "0123456789abcdef";

	if(strncmp(str, "0x", 2))
		return(atoi(str));

	p = str + 2;
	for(n=(strlen(p)-1),m=1,g=0; n>=0; n--, m*=16) {
		for(i=0; i<16; i++) {
			if(*(p+n) == hd[i]) {
				g += (m * i);
				break;
			}
		}
		if(i==16) return(-1);
	}
	return((int)g);
}

static long	init_ncl_port()
{
struct hostent	*hp;
char		buf[80];
struct servent	*sp;
int		on = 1;

#ifndef	DEBUG
	if((sp = getservent("oz-ncl", "tcp")) == (struct servent *)NULL) {
		fprintf(stderr, "init_ncl_port: unknown service oz-ncl\n");
		return(0);
	}
	ncl_sin.sin_port	= sp->s_port;
#else
	ncl_sin.sin_port	= (unsigned short)PROVISIONAL_PORT;
#endif
	ncl_sin.sin_family	= AF_INET;

	gethostname(buf, 80);
	if (!(hp = gethostbyname(buf))) {
		fprintf(stderr, "init_ncl_port: %s: unknown host\n", buf);
                return(0);
        }
        bcopy(hp->h_addr, &(ncl_sin.sin_addr.s_addr), sizeof(long));

	return((long)(hp->h_addr));
}

static int	wait_responce(int s, EventData hp)
{
int		nfd, nb;
fd_set		rfds;
struct timeval	tw;
long long	exid;
DebugMent	rp;

	tw.tv_sec        = 5;
	tw.tv_usec       = 0;

	FD_ZERO(&rfds);
	FD_SET(s, &rfds);
	nfd = select(getdtablesize(), &rfds, NULL, NULL, &tw);
	if(nfd < 0) {
		perror("wait_responce: select: ");
		return(0);
	}
	if(FD_ISSET(s, &rfds) == 0) {
		printf("Can't found Executor-address for ");
		rp	= (DebugMent)(hp->data.data);
		exid	= rp->data.so_addr.unknown_exid;
		printf("EXID(0x%08x%08x)\n", (int)(exid>>32), (int)(exid&0xffffffff));
		return(0);
	}
	nb = read(s, (char *)hp, SZ_EventData);
	if(nb <= 0) {
		perror("wait_responce: read: ");
		return(0);
	}

	return((int)hp);
}

static int	connect_ncl()
{
int			s;
char			buf[80];

	if((s = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
		perror("connect_ncl: socket");
		return(0);
	}
	if(connect(s, (struct sockaddr *)&ncl_sin, sizeof(ncl_sin)) < 0) {
		perror("connect_ncl: connect");
		return(0);
	}
	return(s);
}

static int	send_request(int s, EventData hp)
{
	if(write(s, (char *)hp, SZ_EventData) < 0) {
		perror("send_request: write");
		return(0);
	}
	return(s);
}

#ifdef	TSUIKA
void	make_connect_event(EventData hp, long ip)
{
DebugMent rp;

	hp->head.arch_id	= SPARC;
	hp->head.event_num	= NCL_DEBUGGER_COMM;
	hp->head.req_nclid	= ip;
	hp->head.req_uid	= getuid();
	rp	= (DebugMent)hp->data.data;
	rp->deb_comm		= DEBUG_CONNECT;
}
#endif

static void	make_solutaddr_event(EventData hp, int sid, int eid, long ip)
{
DebugMent	rp;

	bzero((char *)hp, SZ_EventData);
	hp->head.arch_id	= SPARC;
	hp->head.event_num	= NCL_DEBUGGER_COMM;
	hp->head.req_nclid	= ip;
	hp->head.req_uid	= getuid();
	rp	= (DebugMent)(hp->data.data);
        rp->deb_comm	= DEBUG_SOLUTADDR;
	SET_SITE(rp->data.so_addr.unknown_exid, sid);
	SET_EX(rp->data.so_addr.unknown_exid, eid);
}

static void	disp_info(EventData hp)
{
char			*locstr[] = { "LOCAL", "INSITE", "OUTSITE" };
long long		exid;
struct sockaddr_in	*ap;

	exid	= hp->data.so_addr.unknown_exid;
	ap	= &(hp->data.so_addr.address);
	printf("## Successful in Address Solution\n");
	printf("EXID                    NET-ADDR             LOCATION\n");
	printf("0x%08x%08x", (int)(exid>>32), (int)(exid&0xffffffff));
	printf("    %15s:%d", inet_ntoa(ap->sin_addr), ap->sin_port);
	printf("      %s\n", locstr[hp->data.so_addr.location]);
}

#if	0
struct sockaddr_in	*ExidToAddr(long long exid)
#else
main(int argc, char *argv[])
#endif
{
long			my_ipaddr;
struct sockaddr_in	addr;
EventDataRec		oo;
int			s;

	if(argc != 3) {
		printf("Usage: %s Site-ID Executor-ID\n", argv[0]);
		exit(0);
	}

	if((my_ipaddr = init_ncl_port()) == 0)
		exit(2);

	if((s = connect_ncl()) == 0)
		exit(1);

#ifdef	TSUIKA
	make_connect_event(&oo, my_ipaddr);
        if(send_request(s, &oo) == 0) {
		close(s);
		exit(3);
	}
#endif

	make_solutaddr_event(&oo, strhtoi(argv[1]), strhtoi(argv[2]), my_ipaddr);
        if(send_request(s, &oo) == 0) {
		close(s);
		exit(3);
	}
	if(wait_responce(s, &oo) == 0) {
		close(s);
		exit(4);
	}
	disp_info(&oo);
	close(s);
}
