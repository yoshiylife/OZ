/*
Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan (IPA)

All right reserved.
This software and documentation is a result of the Open Fundamental Software
Technology Project of Information-technology Promotion Agency, Japan (IPA).

Permission to use, copy, modify and distribute this software are granted by
the terms and conditions set forth in the file COPYRIGHT, located in this
release package.
*/

#include <sys/types.h> 
#include <sys/wait.h> 
#include <sys/time.h> 
#include <sys/resource.h> 
#include <sys/socket.h> 
#include <sys/uio.h> 
#include <sys/stat.h> 
#include <sys/ioctl.h> 
#include <sys/file.h> 
#include <sys/param.h> 
#include <sys/unistd.h> 
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
#include <pwd.h>

#include "ncl.h"
#include "ncl_defs.h"
#include "ncl_shell.h"
#include "ex_ncl_event.h"
#include "ncl_table.h"
#include "exec_table.h"
#include "ncl_extable.h"

extern	int	errno;

static void	en_search_c_n(EventData hp);
static void	en_creat_executor(EventData hp);
static void	en_start_executor(EventData hp);
static void	ncl_nop(EventData hp);
static void	nn_primary(EventData hp);
static void	nn_secondary(EventData hp);
static void	nn_relay(EventData hp);
static void	nn_reply(EventData hp);
static void	bc_primary(EventData hp);
static void	bc_secondary(EventData hp);
static void	bc_relay(EventData hp);
static void	nn_created_exid(EventData hp);
static void	nn_exid_request(EventData hp);
extern void	ncl_ment_command(EventData hp);
extern void	ncl_deb_command(EventData hp);
extern void	ag_ar_query(EventData hp);
extern void	ag_ar_reply(EventData hp);

void	en_unknown_exid(EventData hp);
void	nn_creat_executor(EventData hp);

typedef	struct	{
	void	(*func)();
} EventFuncs;

EventFuncs	event_act[] = {
	en_unknown_exid, en_search_c_n, en_creat_executor, en_start_executor,
	ncl_nop, ncl_nop, ncl_nop, ncl_nop,
	nn_primary, nn_secondary, nn_relay, nn_reply,
	bc_primary, bc_secondary, bc_relay,
	nn_creat_executor, nn_created_exid,
	nn_exid_request, ncl_nop,
	ncl_ment_command, ncl_deb_command,
	ag_ar_query, ag_ar_reply
};

NclEnvRec	envofncl;
NclArg		nclarg;

extern NclTableRec	ncl_table;
extern ExTableEntryRec	extentry;

extern void	init_ncl_log();
extern void	init_exid_mnginfo();
extern void	init_executor_table();
extern int	init_ncl_table();
extern int	rg_ncllog(char *msg, int sw);
extern void	renewal_extable(long long id, struct sockaddr_in *addr, int loc);
extern void	purge_extable();
extern struct sockaddr_in *ExidToAddr(long long id);
extern MySTExBlock	IsExidEntry(long long id);
extern void	SetExCondition(long long id, long st);
/*
extern int	st_newexid(void *p);
*/
extern void	gt_exmng_block(int pid, EventData hp, int exfd);
extern void	fr_exmng_block(int fd);
extern void	SetExFd(fd_set *rfds);
extern int	FdIsSetEX(fd_set *rfds);
extern void	ExMulticast(char *datap, int size);
extern void	SetHalfRouterTbl(int fd, long addr);
extern void	SetHalfRouterFd(fd_set *rfds);
extern int	FdIsSetHalfRouter(fd_set *rfds, long *addr);
extern void	fr_halfroutertbl(int fd);
extern char	*ipaddr2str(long addr);

extern void	recv_exid_request(EventData np);
extern void	ment_interpreter();
extern long long	ExFdToExid(int exfd);
extern RequestTbl	get_requesttbl();
extern void	fr_requesttbl(int fd);
extern void	remove_executor_table();
extern void	SetNclFd(fd_set *rfds);
extern int	FdIsSetNCL(fd_set *rfds);

int	strhtoi(char *str)
{
int		n, i;
unsigned int	m, g;
char		*p;

static char	hd[] = "0123456789abcdef";

#if	0
	if(strncmp(str, "0x", 2)) {
		for(p=str; *p!=0x00; p++)
			if(isdigit(*p) == 0) return(-1);
		return(atoi(str));
	}

	p = str + 2;
#endif
	p = str;
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

void	end_ncl(int exn)
{
char	buf[64];

	if(extentry.ex_cnt) {
#if	0
		disp_exmng_block();
#endif
		printf("################################################\n");
		printf("# Attention: Executor must be still alive yet. #\n");
		printf("################################################\n");
#if	0
		printf("May Nucleus finish?(yes/no): ");
		scanf("%s", buf);
		if(strcmp(buf, "yes"))
			return;
#endif
	}
	fr_halfroutertbl(-1);
	if(!extentry.ex_cnt) {
		remove_executor_table();
	}
	if(envofncl.s) {
		if(close(envofncl.s) == (-1))
			perror("end_ncl: close");
	}
	if(envofncl.frd_pid) {
		kill(envofncl.frd_pid, SIGTERM);
	}
	if(envofncl.fsd_pid) {
		kill(envofncl.fsd_pid, SIGTERM);
	}

	exit(exn);
}

static void	init_ncl_port()
{
struct servent		*sp;

#ifndef	DEBUG
	if((sp = getservent("oz-ncl", "tcp")) == (struct servent *)NULL) {
		fprintf(stderr, "init_ncl_port: unknown service oz-ncl\n");
		exit(1);
	}
	envofncl.myaddr.sin_port	= sp->s_port;
#else
	envofncl.myaddr.sin_port	= (unsigned short)PROVISIONAL_PORT;
#endif
	envofncl.myaddr.sin_family	= AF_INET;

	if ((envofncl.s = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
		perror("init_ncl_port: socket");
		exit(1);
	}
	if (bind(envofncl.s, &(envofncl.myaddr), sizeof(struct sockaddr_in)) < 0) {
		perror("init_ncl_port: bind");
		(void)fprintf(stderr, "init_ncl_port: Other Nucleus start up already ?\n");
		exit(1);
	}
	listen(envofncl.s, 5);
}

static long gt_braddr(int s)
{
struct ifreq		ifr;
char			name[256];
struct sockaddr_in	*sin;

	strncpy(ifr.ifr_name, "le0", sizeof(ifr.ifr_name));
	ifr.ifr_addr.sa_family	= AF_INET;
	if (ioctl(s, SIOCGIFFLAGS, (caddr_t)&ifr) < 0) {
		perror("gt_braddr: ioctl (SIOCGIFFLAGS)");
		exit(1);
	}
	if((ifr.ifr_flags & IFF_BROADCAST) == 0) {
		printf("gt_braddr: Can't found broadcast address\n");
		exit(1);
	}
	if (ioctl(s, SIOCGIFBRDADDR, (caddr_t)&ifr) < 0) {
		if (errno == EADDRNOTAVAIL)
			bzero((char *)&ifr.ifr_addr, sizeof(ifr.ifr_addr));
		else
			perror("ioctl (SIOCGIFADDR)");
	}
	sin = (struct sockaddr_in *)&ifr.ifr_addr;
	if (sin->sin_addr.s_addr == 0) {
		printf("gt_braddr: Can't found broadcast address\n");
		exit(1);
	}
	printf("gt_braddr: le0 broadcast address: %s\n", inet_ntoa(sin->sin_addr));
	return(sin->sin_addr.s_addr);
}

static void	init_ncl_bport()
{
int			on;
struct sockaddr_in	sin;
unsigned long		nid;

#ifndef	DEBUG
	if((sp = getservent("oz-ncl", "udp")) == (struct servent *)NULL) {
		fprintf(stderr, "init_tcp_pot: unknown service oz-ncl\n");
		exit(1);
	}
	sin.sin_port	= sp->s_port;
#else
	sin.sin_port	= (unsigned short)PROVISIONAL_UPORT;
#endif
	sin.sin_family	= AF_INET;
	sin.sin_addr.s_addr	= INADDR_ANY;

	if ((envofncl.bs = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
		perror("init_ncl_bport: socket");
		exit(1);
	}
	on	 = 1;
	if (setsockopt(envofncl.bs, SOL_SOCKET, SO_BROADCAST, &on, sizeof (on)) < 0) {
		perror("init_ncl_bport: setsockopt SO_BROADCAST");
		exit(1);
	}
	if (bind(envofncl.bs, (struct sockaddr *)&sin, sizeof(sin)) < 0) {
		perror("init_ncl_bport: bind");
		exit(1);
	}

	envofncl.baddr.sin_family	= AF_INET;
	nid	= envofncl.mynclid;
	envofncl.baddr.sin_addr.s_addr = gt_braddr(envofncl.bs);
/*
	if (IN_CLASSA(nid))
		envofncl.baddr.sin_addr.s_addr = nid & IN_CLASSA_NET;
	else if (IN_CLASSB(nid))
		envofncl.baddr.sin_addr.s_addr = nid & IN_CLASSB_NET;
	else
		envofncl.baddr.sin_addr.s_addr = nid & IN_CLASSC_NET;
*/
	envofncl.baddr.sin_port	= (unsigned short)PROVISIONAL_UPORT;
#ifdef	DEBUG
printf("UDP Broadcast address is %s\n", ipaddr2str(envofncl.baddr.sin_addr.s_addr));
#endif
}

char	*ntime(char *dp)
{
struct tm       *tmp;
long		tm;

	time(&tm);
	tmp     = localtime(&tm);
	sprintf(dp, "%02d/%02d/%02d", tmp->tm_year, tmp->tm_mon+1,tmp->tm_mday);
	sprintf(dp+8, " %02d:%02d:%02d", tmp->tm_hour,tmp->tm_min,tmp->tm_sec);
	return(dp);
}

static void	accept_event(EventData hp)
{
struct sockaddr_in	sin;
int			nfd, nb, efd, cfd, len, size;
fd_set			rfds;
long long		exid;
long			addr;
char			ntm[128], tmp[256];

	fflush(stdout);

	size	= sizeof(sin);
	for(;;) {
		FD_ZERO(&rfds);
#if	0
		FD_SET(0, &rfds);
#endif
		FD_SET(envofncl.s, &rfds);
		FD_SET(envofncl.bs, &rfds);
		SetNclFd(&rfds);
		if(AM_I_HALFROUTER)
			SetHalfRouterFd(&rfds);
		SetExFd(&rfds);
		nfd = select(getdtablesize(), &rfds, NULL, NULL, NULL);
		if(nfd < 0) {
			perror("NCL> select: ");
			if(!envofncl.frd_pid || !envofncl.fsd_pid)
				if(!extentry.ex_cnt)
					end_ncl(1);
			continue;
		}
#if	0
		if(FD_ISSET(0, &rfds)) {
			bzero(hp->data.data, 104);
			if((nb = read(0, hp->data.data, 104)) == 0) {
				printf("accept_event: EOF keyboard\n");
				continue;
			}
			len	= strlen(hp->data.data);
        		hp->data.data[len - 1]	= 0x00;
			hp->head.event_num	= NCL_MENT_COMMAND;
			hp->head.req_exfd	= 0;
			return;
		}
#endif
		if(cfd = FdIsSetNCL(&rfds)) {
#ifdef	DEBUG
printf("NCL> Event from NCL or NFE <%s>\n", ntime(ntm));
rg_ncllog("Event from NCL or NFE", 1);
#endif
			nb = read(cfd, (char *)hp, SZ_EventData);
			if(nb > 0) {
				hp->head.req_nclfd	= cfd;
				return;
			}
			fr_requesttbl(cfd);
printf("NCL> Connect was closed fd(%d)\n", cfd);
			continue;
		}
		if(cfd = FdIsSetHalfRouter(&rfds, &addr)) {
#ifdef	DEBUG
printf("NCL> Event from Half Router NCL(%s) <%s>\n", ipaddr2str(addr), ntime(ntm));
sprintf(tmp, "Event from Half Router NCL(%s)", ipaddr2str(addr));
rg_ncllog(tmp, 1);
#endif
			nb = read(cfd, (char *)hp, SZ_EventData);
			if(nb > 0)
				return;
printf("NCL> Connect was closed for Half Router\n");
			fr_halfroutertbl(cfd);
			continue;
		}
		if(FD_ISSET(envofncl.bs, &rfds)) {
#ifdef	DEBUG
printf("NCL> Event from UDP <%s>\n", ntime(ntm));
rg_ncllog("Event from UDP(Broadcast)", 1);
#endif
			nb = recv(envofncl.bs, (char *)hp, SZ_EventData, 0);
			if(nb <= 0) {
				perror("accept_event: recv: ");
				continue;
			}
			if((hp->head.req_siteid&SITEID_MASK)!=envofncl.siteid) {
#ifdef	DEBUG
printf("  Received broadcast message from out site, This event was ignored.\n");
rg_ncllog("Received broadcast message from out site, This event was ignored.", 1);
#endif
				continue;
			}
			return;
		}
		if(FD_ISSET(envofncl.s, &rfds)) {
#ifdef	DEBUG
printf("NCL> Event from TCP <%s>\n", ntime(ntm));
rg_ncllog("Event from TCP", 1);
#endif
			bzero((char *)&sin, size);
			envofncl.ns	= accept(envofncl.s, (struct sockaddr *)&sin, &size);
			if(envofncl.ns == (-1)) {
				perror("accept_event: accept: ");
				printf("accept address is %s\n",  ipaddr2str(sin.sin_addr.s_addr));
				continue;
			}
			nb = read(envofncl.ns, (char *)hp, SZ_EventData);
			if(nb > 0) {
				hp->head.req_nclfd	= envofncl.ns;
				/* for Debugger	*/
				if(hp->data.so_addr.req_exid == 0LL)
					hp->head.req_exfd	= envofncl.ns;
				return;
			}
			perror("accept_event: read: ");
			printf("accept address is %s\n",  ipaddr2str(sin.sin_addr.s_addr));
			close(envofncl.ns);
			continue;
		}
		if(efd = FdIsSetEX(&rfds)) {
#ifdef	DEBUG
printf("NCL> Event from Executor <%s>\n", ntime(ntm));
rg_ncllog("Event from Executor", 1);
#endif
			if(nb = read(efd, (char *)hp, SZ_EventData)) {
				hp->head.req_exfd	= efd;
				return;
			}
#ifdef	DEBUG
exid	= ExFdToExid(efd);
printf(" + Executor(0x%06x) Terminated, Executor socket fd(%d) was closed\n", (int)((exid>>24)&0xffffff), efd);
sprintf(tmp, "Executor(0x%06x) Terminated, Executor socket fd(%d) was closed", (int)((exid>>24)&0xffffff), efd);
rg_ncllog(tmp, 1);
#endif
			fr_exmng_block(efd);
			close(efd);
			continue;
		}
#ifdef	DEBUG
printf("NCL> Unknown event <%s>, ", ntime(ntm));
printf("rfds(0x%08x%08x)\n", (&rfds)->fds_bits[1], (&rfds)->fds_bits[0]);
sprintf(tmp, "Unknown event: rfds(0x%08x%08x)", (&rfds)->fds_bits[1], (&rfds)->fds_bits[0]);
rg_ncllog(tmp, 1);
#endif
	}
}

static void	ncl_nop(EventData hp)
{
char	tmp[256];

	sprintf(tmp, "ncl_nop: Happened illegal event(0x%x)\n", hp->head.event_num); 
	printf("%s\n", tmp); 
	rg_ncllog(tmp, 1);
	dump((char *)hp, SZ_EventData);
}

#ifdef	DEBUG
#define	LINEWID	16
dump(dt, n)
char	dt[];
int	n;
{
int	r_sz = 0;
int	i, j, k, d_pos, cnt;
int	c;

	cnt = n / LINEWID;
	if(n % LINEWID) cnt++;

	for(j=0; j<cnt; j++, r_sz+=LINEWID) {
		printf("0x%04x   ", r_sz);
		d_pos = j * 16;
		k = n - d_pos;

		if(k >= LINEWID) k = LINEWID;
		for(i=0; i<k; i++) {
			printf("%02x ", dt[i + d_pos] & 0xff);
		}
		if(k < LINEWID) {
			for(i=k; i<LINEWID; i++)
				printf("   ");
		}
		printf("   ");
		for(i=0; i<k; i++) {
			c = (int)dt[i + d_pos];
			if((c < 0x20 || c > (int)'~') && (c < 0xa1 || c > 0xdf)) {
				printf(".");
				continue;
			}
			printf("%c", (char)c);
		}
		if(k < LINEWID) {
			for(i=k; i<LINEWID; i++)
				printf("  ");
		}
		putchar('\n');
	}
	printf("*\n");
}
#endif

static void	NclMulticast(char *datap, int size)
{
int			i, j, s;
struct sockaddr_in	sin;
NclHostent		nhp;
char			tmp[256];

        sin.sin_family = AF_INET;
        sin.sin_port = (unsigned short)PROVISIONAL_PORT;
	for(i=0,j=0; j<ncl_table.h_router_cnt; i++) {
        	nhp	= &(ncl_table.h_router_tbl[i]);
        	if(nhp->addr == (long)0)
			continue;
		j++;
		if(nhp->fd == 0) {
			if(nhp->delay_base != nhp->delay_cnt) {
				nhp->delay_cnt++;
				continue;
			}
			if((s = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
				perror("NclMulticast: socket");
				continue;
			}
        		nhp->fd	= s;
        		sin.sin_addr.s_addr = nhp->addr;
			if(connect(nhp->fd, (struct sockaddr *)&sin, sizeof(sin)) < 0) {
        			close(nhp->fd);
        			nhp->fd	= 0;
				perror("NclMulticast: connect");
#ifdef	DEBUG
printf("   = Half Router NCL(%s) is not Active ?\n", ipaddr2str(sin.sin_addr.s_addr));
sprintf(tmp, "NclMulticast: Half Router NCL(%s) is not Active ?", ipaddr2str(sin.sin_addr.s_addr));
rg_ncllog(tmp, 1);
#endif
				if(nhp->delay_base) {
					nhp->delay_base	*= 2;
					nhp->delay_cnt	= 0;
				} else {
					nhp->delay_base	= 1;
				}
				continue;
			}
#ifdef	DEBUG
printf("   = Connected to Half Router NCL(%s)\n", ipaddr2str(sin.sin_addr.s_addr));
sprintf(tmp, "Connected to Half Router NCL(%s)\n", ipaddr2str(sin.sin_addr.s_addr));
rg_ncllog(tmp, 1);
#endif
		}
#ifdef	DEBUG
printf("   = Send Event to Half Router NCL(%s)\n", ipaddr2str(sin.sin_addr.s_addr));
sprintf(tmp, "Send Event to Half Router NCL(%s)\n", ipaddr2str(sin.sin_addr.s_addr));
rg_ncllog(tmp, 1);
#endif
		if(write(nhp->fd, datap, size) <= 0) {
        		close(nhp->fd);
        		nhp->fd	= 0;
			perror("NclMulticast: write failed");
			continue;
		}
		if(nhp->delay_base) {
			nhp->delay_base	= 0;
			nhp->delay_cnt	= 0;
		}
	}
}

static void	NclBroadcast(char *datap, int size)
{
int	sb;

	sb = sendto(envofncl.bs, datap, size, 0, &(envofncl.baddr), sizeof(envofncl.baddr));
	if(sb < 0) {
		perror("NclBroadcast: sendto:");
	}
}

#ifdef	DEBUG
static void	msg_monitor(EventData hp, char *kind)
{
SolutAddress	sop;
long long	keid;
long		req_n;
char		tmp[256];

	sop	= &(hp->data.so_addr);
	keid	= sop->unknown_exid;
	printf(" + Received request of address solution: Unkown Exid: %08x%08x\n", (int)((keid>>32)&0xffffffffLL), (int)(keid&0xffffffffLL));
	sprintf(tmp, "Received request of address solution: Unkown Exid: %08x%08x", (int)((keid>>32)&0xffffffffLL), (int)(keid&0xffffffffLL));
	rg_ncllog(tmp, 1);
	req_n	= hp->head.req_nclid_sav?hp->head.req_nclid_sav:hp->head.req_nclid;
	if(sop->req_exid == 0LL) {
		printf("    Type(%s), Requester(DEBUGGER)", kind);
		sprintf(tmp, "Type(%s), Requester(DEBUGGER)", kind);
		rg_ncllog(tmp, 0);
	} else {
		printf("    Type(%s), Requester(Site: %04x, Exid: %06x, Host: %s)\n", kind, GET_SITEID(hp->data.so_addr.req_exid), GET_EXID(hp->data.so_addr.req_exid), ipaddr2str(req_n));
		sprintf(tmp, "Type(%s), Requester(Site: %04x, Exid: %06x, Host: %s)", kind, GET_SITEID(hp->data.so_addr.req_exid), GET_EXID(hp->data.so_addr.req_exid), ipaddr2str(req_n));
		rg_ncllog(tmp, 0);
	}
}

static void     msg_monitor1(EventData hp, char *kind)
{
BroadcastParam	bpp;
char		tmp[256];

printf(" + Received message(%s) of search class&name\n", kind);
sprintf(tmp, "Received message(%s) of search class&name", kind);
rg_ncllog(tmp, 0);
bpp = &(hp->data.sc_name.params);
printf("   = sender(%08x%08x) id(%x) P1(%08x%08x) P2(%08x)\n", (int)((bpp->sender>>32)&0xffffffffLL), (int)(bpp->sender&0xffffffffLL), bpp->id, (int)((bpp->param1>>32)&0xffffffffLL), (int)(bpp->param1&0xffffffffLL), bpp->param2);
sprintf(tmp, "sender(%08x%08x) id(%x) P1(%08x%08x) P2(%08x)", (int)((bpp->sender>>32)&0xffffffffLL), (int)(bpp->sender&0xffffffffLL), bpp->id, (int)((bpp->param1>>32)&0xffffffffLL), (int)(bpp->param1&0xffffffffLL), bpp->param2);
rg_ncllog(tmp, 0);
}
#endif

/********************************************************
* Address resolution message of Executor to Nucleus	*
********************************************************/
void	en_unknown_exid(EventData hp)
{
struct sockaddr_in	*addr;
long long		rexid;

	rexid	= ExFdToExid(hp->head.req_exfd);

	ADDR_CLR(hp->data.so_addr.address);
	hp->head.event_num	= NCL_NN_PRIMARY;
	hp->head.req_nclid	= envofncl.mynclid;
	hp->head.req_nclfd	= envofncl.bs;
	hp->head.req_siteid	= envofncl.siteid;

	hp->data.so_addr.req_exid	= rexid;
	if(addr = ExidToAddr(rexid)) {
		ADDR_CPY(&(hp->data.so_addr.req_exaddr), addr);
	}
#ifdef	DEBUG
msg_monitor(hp, "REQUEST");
#endif
#ifdef	DEBUG
printf(" + Send Broadcast Message(SOLUT_ADDR[PRIMARY]) to Segment\n");
#endif
	NclBroadcast((char *)hp, SZ_EventData);
}

/********************************************************
* Search out Class/Name message of Executor to Nucleus	*
********************************************************/
static void	en_search_c_n(EventData hp)
{
#ifdef	DEBUG
msg_monitor1(hp, "REQUEST from EX");
#endif
	hp->head.event_num	= NCL_BC_PRIMARY;
	hp->head.req_nclid	= envofncl.mynclid;
	hp->head.req_nclfd	= envofncl.bs;
	hp->head.req_siteid	= envofncl.siteid;

#ifdef	DEBUG
printf(" + Send Broadcast Message(SEARCH_C_N) to Segment\n");
rg_ncllog("Send Broadcast Message(SEARCH_C_N) to Segment", 1);
#endif
	NclBroadcast((char *)hp, SZ_EventData);
}

static int	exid_check_ment(EventData hp)
{
	if(hp->data.cr_exec.inst_exid == 0LL) {
/*
		if(st_newexid(&(hp->data.cr_exec.inst_exid)))
*/
			sprintf(&(hp->data.data[800]), "Failed get new executor-ID");
		hp->data.cr_exec.status	= ER_GETNEW_EXID;
		return(ER_GETNEW_EXID);
	} else {
		SET_SITE(hp->data.cr_exec.inst_exid, envofncl.siteid);
		if(IsExidEntry(hp->data.cr_exec.inst_exid)) {
			printf("exid_check_ment: Multiple Executor-ID appointed\n");
			sprintf(&(hp->data.data[800]), "Multiple Executor-ID apponted");
			hp->data.cr_exec.status	= ER_MULTI_EXID;
			return(ER_MULTI_EXID);
		}
	}
	return(0);

}

static int	set_nclargs(char *dp)
{
int     i, sw;
char    *p;

	bzero((char *)&nclarg, sizeof(NclArg));
	for(i=0,sw=0,p=dp; *p!=0x00; p++) {
		if(*p == ' ' || *p == '\t') {
			if(i == 0)  continue;
			i = 0;
			sw = 1;
			continue;
		}
		if(sw) {
			nclarg.argc++;
			sw = 0;
		}
		nclarg.argv[nclarg.argc][i++] = *p;
	}
	if(nclarg.argc == 0 && nclarg.argv[0][0] == 0x00)
		return(-1);

	return(0);
}

static int	excomm_check_ment(EventData hp, char *excomm, char *im_dir, char *exid)
{
char		*ozroot;
struct stat	st;

	ozroot = (char *)&(hp->data.data[807]);
	sprintf(im_dir, "%s/images/%s", ozroot, exid);
	sprintf(excomm, "%s/bin/%s", ozroot, EX_COMMAND);
	if(stat(excomm, &st)) {
		printf("Can't found executor command: %s\n", excomm);
		sprintf(&(hp->data.data[800]), "Can't found executor command: %s\n", excomm);
		hp->data.cr_exec.status	= ER_NFND_EXCOMM;
		return(ER_NFND_EXCOMM);
	}
	return(0);
}

static int	creat_executor_myST(EventData hp)
{
int	i, j, upid, er;
int	s[2];
char	excomm[256], exid[32];
char	buf[128], buf1[64], im_dir[256];
char	*ex_args[20];

#ifdef	DEBUG
	printf("creat_executor_myST: Creat New Executor My Station Now\n");
	rg_ncllog("creat_executor_myST: Creat New Executor My Station Now", 1);
#endif
	sprintf(exid, "%06x", (int)((hp->data.cr_exec.inst_exid>>24)&0xffffffLL));
	if(er = excomm_check_ment(hp, excomm, im_dir, exid))
		return(er);
	if(er = exid_check_ment(hp))
		return(er);

#ifdef	DEBUG
	printf(" + Executor command(%s)\n", excomm);
#endif

	if(socketpair(AF_UNIX, SOCK_STREAM, 0, s) == (-1)) {
		perror("creat_executor_myST: socketpair failed");
		sprintf(&(hp->data.data[800]), "Executor socketpair failed");
		hp->data.cr_exec.status	= ER_SOCK_PAIR;
		return(ER_SOCK_PAIR);
	}
	gethostname(buf1, 64);

	if((upid = fork()) == 0) {
		for (i = 3; i < NOFILE; i++)
			if(s[1] != i)
				close(i);
		dup2(s[1], 3);

		set_nclargs(&(hp->data.data[400]));
		ex_args[0] = EX_COMMAND;
		ex_args[1] = "-Z";
		for(i=2,j=2; nclarg.argv[j][0]!=0x00; i++,j++)
			ex_args[i] = nclarg.argv[j];
		ex_args[i] = (char *)0;

		putenv(&(hp->data.data[700]));	/* DISPLAY	*/
		putenv(&(hp->data.data[800]));	/* OZROOT	*/

		if(setuid(hp->head.req_uid) == (-1)) {
			perror("creat_executor_myST: setuid:");
			exit(1);
		}
		if(chdir(im_dir) != 0) {
			perror("creat_executor_myST: chdir:");
			exit(1);
		}

		signal(SIGPIPE, SIG_DFL);
		signal(SIGCHLD, SIG_DFL);
		signal(SIGHUP, SIG_DFL);
		signal(SIGTERM, SIG_DFL);

		execv(excomm, ex_args);
		perror("execv: ");
		exit(1);
	}
	close(s[1]);

	gt_exmng_block(upid, hp, s[0]);

	if(write(s[0], (char *)hp, SZ_EventData) <= 0)
		perror("creat_executor_myST: write:");
	return(0);
}

int	NclToNclTCP(long saddr, char *datap, int size)
{
int			s, fd;
struct sockaddr_in	peer;
RequestTbl		rtp;

        peer.sin_family = AF_INET;
        peer.sin_port = (unsigned short)PROVISIONAL_PORT;
	peer.sin_addr.s_addr = saddr;
	rtp	= get_requesttbl();
	if((fd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
		perror("NclToNclTCP: socket");
		return(0);
	}
	rtp->fd	= fd;
	if(connect(fd, (struct sockaddr *)&peer, sizeof(peer)) < 0) {
		perror("NclToNclTCP: connect");
		fr_requesttbl(fd);
		return(0);
	}
	rtp->con |= NCL_CONNECTED;
	if(write(fd, datap, size) < 0) {
		perror("NclToNclTCP: write");
		fr_requesttbl(fd);
		return(0);
	}
	rtp->con |= NCL_REQUEST;
	return(fd);
}

static void	NclToEx(int fd, char *datap, int size)
{
	if(fd) {
		if(write(fd, datap, size) <= 0)
			perror("NclToEx: write:");
	} else {
		printf("Warning: NclToEx FD is ZERO\n");
	}
}

static void	en_creat_executor(EventData hp)
{
int	status;

#ifdef	DEBUG
printf("RECV:EN_CREAT_EXECUTOR <- \n");
#endif
	if(SENDER_IS_MYSELF(hp->data.cr_exec.creat_nclid)) {
		hp->head.event_num	= NE_EXEC_INFO;
		if(status = creat_executor_myST(hp)) {
			hp->head.event_num	= NE_CREATED_EXID;
#ifdef	DEBUG
printf("SEND:NE_CREATED_EXID -> EX fd(%d)\n", hp->head.req_exfd);
#endif
			NclToEx(hp->head.req_exfd, (char *)hp, SZ_EventData);
		} else {
#ifdef	DEBUG
printf("SEND:NE_EXEC_INFO -> EX\n");
#endif
		}
		return;
	}

	hp->head.event_num	= NCL_NN_CREAT_EXECUTOR;
	hp->head.req_nclid	= envofncl.mynclid;
	ADDR_CLR(hp->data.cr_exec.exaddress);

#ifdef	DEBUG
printf("SEND:NN_CREAT_EXECUTOR -> NCL\n");
#endif
	NclToNclTCP(hp->data.cr_exec.creat_nclid, (char *)hp, SZ_EventData);
}

static void	en_start_executor(EventData hp)
{
char	tmp[256];
#ifdef	DEBUG
long long	exid;

exid	= hp->data.cr_exec.inst_exid;
printf(" + Received Message(START_EXEC) from Executor(0x%06x)\n", (int)((exid>>24)&0xffffff));
sprintf(tmp, "Received Message(START_EXEC) from Executor(0x%06x)", (int)((exid>>24)&0xffffff));
rg_ncllog(tmp, 1);
#endif

	hp->head.event_num	= NCL_NN_CREATED_EXID;

	renewal_extable(hp->data.cr_exec.inst_exid, &(hp->data.cr_exec.exaddress), ET_LOCAL);
	SetExCondition(hp->data.cr_exec.inst_exid, EX_ACTIVE);
#ifdef	DEBUG
printf(" + Send Message(START_EXEC) to NFE(%s)\n", ipaddr2str(hp->head.req_nclid));
sprintf(tmp, "Send Message(START_EXEC) to NFE(%s)", ipaddr2str(hp->head.req_nclid));
rg_ncllog(tmp, 1);
#endif
	if(write(hp->head.req_nclfd, (char *)hp, SZ_EventData) <= 0) {
		perror("en_start_executor: write");
	}
}

static void	NclToNclUDP(long saddr, char *datap, int size)
{
int			sb;
struct sockaddr_in	to;

	bcopy((char *)&(envofncl.baddr), (char *)&to, sizeof(to));
	to.sin_addr.s_addr	= saddr;
	
	sb = sendto(envofncl.bs, datap, size, 0, &to, sizeof(to));
	if(sb < 0) {
		perror("NclBroadcast: sednto:");
	}
}

static void	renew_req_exinfo(EventData hp)
{
SolutAddress	sop;
int		loc;

	if(SENDER_IS_MYSELF(hp->head.req_nclid) && !IS_REQ_OSITE(hp->head.req_siteid))
		return;
	sop	= &(hp->data.so_addr);
	if(sop->req_exid == 0LL)
		return;
	loc	= IS_REQ_OSITE(hp->head.req_siteid)?ET_OUTSITE:ET_INSITE;
	renewal_extable(sop->req_exid, &(sop->req_exaddr), loc);
}

static int	SendApgw(char *datap, int size)
{
int			s, fd;
struct sockaddr_in	peer;
RequestTbl		rtp;

	if(ncl_table.apgwid == 0)
		return;

        peer.sin_family = AF_INET;
        peer.sin_port = (unsigned short)PROVISIONAL_PORT - 1;
	peer.sin_addr.s_addr = ncl_table.apgwid;
#if	0
	rtp	= get_requesttbl();
#endif
	if((fd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
		perror("SendApgw: socket");
		return;
	}
#if	0
	rtp->fd	= fd;
#endif
	if(connect(fd, (struct sockaddr *)&peer, sizeof(peer)) < 0) {
		perror("SendApgw: connect");
printf("APGW(%s) is not active?\n", ipaddr2str(ncl_table.apgwid));
		close(fd);
		return;
	}
#if	0
	rtp->con |= APGW_CONNECTED;
#endif
	if(write(fd, datap, size) < 0) {
		perror("SendApgw: write");
		close(fd);
		return;
	}
#if	0
	rtp->con |= APGW_REQUEST;
#endif
	close(fd);
	return(fd);
}

void	ag_ar_query(EventData hp)
{
	hp->head.req_siteid	= (hp->head.req_siteid<<16)|envofncl.siteid;
	hp->head.event_num	= NCL_NN_PRIMARY;
#ifdef	DEBUG
msg_monitor(hp, "REQUEST_FROM_OUTSITE");
#endif
#ifdef	DEBUG
printf(" + Send Broadcast Message(SOLUT_ADDR[PRIMARY]) to Segment\n");
#endif
	NclBroadcast((char *)hp, SZ_EventData);
}

void	ag_ar_reply(EventData hp)
{
#ifdef	DEBUG
msg_monitor(hp, "RESPONCE_FROM_OUTSITE");
#endif
	if(hp->head.req_nclid == envofncl.mynclid) {
		hp->head.event_num	= NE_SOLUT_ADDR;
		renewal_extable(hp->data.so_addr.unknown_exid, &(hp->data.so_addr.address), ET_OUTSITE);
		hp->data.so_addr.location	= ET_OUTSITE;
#ifdef	DEBUG
if(hp->data.so_addr.req_exid) {
printf(" + Send Message(SOLUT_ADDR) to Requester Executor(0x%06x)\n", (int)((hp->data.so_addr.req_exid>>24)&0xffffff));
} else {
printf(" + Send Message(SOLUT_ADDR) to Requester DEBUGGER\n");
}
#endif
		NclToEx(hp->head.req_exfd, (char *)hp, SZ_EventData);
	} else {
		hp->head.event_num	= NCL_NN_REPLY;
#ifdef	DEBUG
printf(" + Send Message(SOLUT_ADDR[REPLY]) to Requester NCL(%s)\n", ipaddr2str(hp->head.req_nclid));
#endif
		NclToNclUDP(hp->head.req_nclid, (char *)hp, SZ_EventData);
	}
}

static void	nn_primary(EventData hp)
{
struct sockaddr_in	*addr;
char			tmp[256];

#ifdef	DEBUG
msg_monitor(hp, "PRIMARY");
#endif
	renew_req_exinfo(hp);

	if(addr = ExidToAddr(hp->data.so_addr.unknown_exid)) {
		if(SENDER_IS_MYSELF(hp->head.req_nclid) && !IS_REQ_OSITE(hp->head.req_siteid)) {
			hp->head.event_num	= NE_SOLUT_ADDR;
			ADDR_CPY(&(hp->data.so_addr.address), addr);
			renewal_extable(hp->data.so_addr.unknown_exid, addr, ET_LOCAL);
			hp->data.so_addr.location	= ET_LOCAL;
#ifdef	DEBUG
if(hp->data.so_addr.req_exid) {
printf(" + Send Reply Message(SOLUT_ADDR) to Requester Executor(0x%06x)\n", (int)((hp->data.so_addr.req_exid>>24)&0xffffff));
sprintf(tmp, "Send Reply Message(SOLUT_ADDR) to Requester Executor(0x%06x)", (int)((hp->data.so_addr.req_exid>>24)&0xffffff));
rg_ncllog(tmp, 1);
} else {
printf(" + Send Reply Message(SOLUT_ADDR) to Requester DEBUGGER\n");
rg_ncllog("Send Reply Message(SOLUT_ADDR) to Requester DEBUGGER", 1);
}
#endif
			NclToEx(hp->head.req_exfd, (char *)hp, SZ_EventData);
			return;
		}

		hp->head.event_num	= NCL_NN_REPLY;
		hp->head.res_nclid	= envofncl.mynclid;
		ADDR_CPY(&(hp->data.so_addr.address), addr);
		hp->data.so_addr.location	= ET_INSITE;
		if(AM_I_RELAYNCL && IS_REQ_OSITE(hp->head.req_siteid)) {
			hp->head.req_siteid	= (long)((hp->head.req_siteid>>16)&SITEID_MASK);
#ifdef	DEBUG
printf(" + Send Reply Message(SOLUT_ADDR) to APGW(%s)\n", ipaddr2str(ncl_table.apgwid));
sprintf(tmp, "Send Reply Message(SOLUT_ADDR) to APGW(%s)", ipaddr2str(ncl_table.apgwid));
rg_ncllog(tmp, 1);
#endif
			SendApgw((char *)hp, SZ_EventData);
		} else {
#ifdef	DEBUG
printf(" + Send Reply Message(SOLUT_ADDR) to Requester NCL(%s)\n", ipaddr2str(hp->head.req_nclid));
sprintf(tmp, "Send Reply Message(SOLUT_ADDR) to Requester NCL(%s)", ipaddr2str(hp->head.req_nclid));
rg_ncllog(tmp, 1);
#endif
			NclToNclUDP(hp->head.req_nclid, (char *)hp, SZ_EventData);
		}
		return;
	}

	if(AM_I_RELAYNCL && ISNOT_MYSITEID(hp->data.so_addr.unknown_exid)) {
#ifdef	DEBUG
printf(" + Send Message(SOLUT_ADDR) to APGW(%s)\n", ipaddr2str(ncl_table.apgwid));
sprintf(tmp, "Send Message(SOLUT_ADDR) to APGW(%s)", ipaddr2str(ncl_table.apgwid));
rg_ncllog(tmp, 1);
#endif
		SendApgw((char *)hp, SZ_EventData);
		return;
	}

	if(AM_I_HALFROUTER) {
		hp->head.event_num	= NCL_NN_RELAY;
        	hp->head.req_hnclid	= envofncl.mynclid;
#ifdef	DEBUG
printf(" + Send Multicast Message(SOLUT_ADDR) to Half router NCL\n");
rg_ncllog("Send Multicast Message(SOLUT_ADDR) to Half router NCL", 1);
#endif
		NclMulticast((char *)hp, SZ_EventData);
	}
}

static  void	nn_secondary(EventData hp)
{
struct sockaddr_in	*addr;
char			tmp[256];

#ifdef	DEBUG
msg_monitor(hp, "SECONDARY");
#endif
	renew_req_exinfo(hp);

	if(addr = ExidToAddr(hp->data.so_addr.unknown_exid)) {
		hp->head.event_num	= NCL_NN_REPLY;
		hp->head.res_nclid	= envofncl.mynclid;
		ADDR_CPY(&(hp->data.so_addr.address), addr);
		hp->data.so_addr.location	= ET_INSITE;
		if(AM_I_RELAYNCL && IS_REQ_OSITE(hp->head.req_siteid)) {
			hp->head.req_siteid	= (long)((hp->head.req_siteid>>16)&SITEID_MASK);
#ifdef	DEBUG
printf(" + Send Reply Message(SOLUT_ADDR) to APGW(%s)\n", ipaddr2str(ncl_table.apgwid));
sprintf(tmp, "Send Reply Message(SOLUT_ADDR) to APGW(%s)", ipaddr2str(ncl_table.apgwid));
rg_ncllog(tmp, 1);
#endif
			SendApgw((char *)hp, SZ_EventData);
		} else {
#ifdef	DEBUG
printf(" + Send Message(SOLUT_ADDR[REPLY]) to Requester NCL(%s)\n", ipaddr2str(hp->head.req_nclid));
sprintf(tmp, "Send Message(SOLUT_ADDR[REPLY]) to Requester NCL(%s)", ipaddr2str(hp->head.req_nclid));
rg_ncllog(tmp, 1);
#endif
			NclToNclUDP(hp->head.req_nclid, (char *)hp, SZ_EventData);
		}
		return;
	}

	if(AM_I_RELAYNCL && ISNOT_MYSITEID(hp->data.so_addr.unknown_exid)) {
#ifdef	DEBUG
printf(" + Send APGW Relay Message(SOLUT_ADDR) to APGW(%s)\n", ipaddr2str(ncl_table.apgwid));
sprintf(tmp, "Send APGW Relay Message(SOLUT_ADDR) to APGW(%s)", ipaddr2str(ncl_table.apgwid));
rg_ncllog(tmp, 1);
#endif
		SendApgw((char *)hp, SZ_EventData);
	}
}

static  void	nn_relay(EventData hp)
{
char	tmp[256];

#ifdef	DEBUG
msg_monitor(hp, "RELAY");
#endif
	SetHalfRouterTbl(hp->head.req_nclfd, hp->head.req_hnclid);

	hp->head.event_num	= NCL_NN_SECONDARY;
#ifdef	DEBUG
printf(" + Send Broadcast Message(SOLUT_ADDR[SECONDARY]) to Segment\n");
rg_ncllog("Send Broadcast Message(SOLUT_ADDR[SECONDARY]) to Segment", 1);
#endif
	NclBroadcast((char *)hp, SZ_EventData);
}

static  void	nn_reply(EventData hp)
{
char	tmp[256];
SolutAddress	sop;
#ifdef	DEBUG
msg_monitor(hp, "REPLY");
#endif

	if(AM_I_RELAYNCL && IS_REQ_OSITE(hp->head.req_siteid)) {
		hp->head.req_siteid	= (long)((hp->head.req_siteid>>16)&SITEID_MASK);
#ifdef	DEBUG
printf(" + Send Message(REPLY) to APGW(%s)\n", ipaddr2str(ncl_table.apgwid));
printf(tmp, "Send Message(REPLY) to APGW(%s)", ipaddr2str(ncl_table.apgwid));
rg_ncllog(tmp, 1);
#endif
		SendApgw((char *)hp, SZ_EventData);
		return;
	}
	hp->head.event_num	= NE_SOLUT_ADDR;
	sop	= &(hp->data.so_addr);
	sop->location	= IS_REQ_OSITE(GET_SITEID(sop->unknown_exid))?ET_OUTSITE:ET_INSITE;
	renewal_extable(sop->unknown_exid, &(sop->address), sop->location);

#ifdef	DEBUG
if(sop->req_exid) {
printf(" + Send Message(SOLUT_ADDR) to Requester Executor(0x%06x)\n", (int)((sop->req_exid>>24)&0xffffff));
sprintf(tmp, "Send Message(SOLUT_ADDR) to Requester Executor(0x%06x)", (int)((sop->req_exid>>24)&0xffffff));
rg_ncllog(tmp, 1);
} else {
printf(" + Send Message(SOLUT_ADDR) to Requester DEBUGGER\n");
rg_ncllog("Send Message(SOLUT_ADDR) to Requester DEBUGGER", 1);
}
#endif

	NclToEx(hp->head.req_exfd, (char *)hp, SZ_EventData);
}

static  void	bc_primary(EventData hp)
{
BroadcastParam	bpp;
char		tmp[256];

	bpp	= &(hp->data.sc_name.params);
#ifdef	DEBUG
msg_monitor1(hp, "PRIMARY");
#endif

	hp->head.event_num	= NE_DOYOUKNOW_C_N;
#ifdef	DEBUG
printf(" + Send Multicast Message(SEARCH_C_N) to EX on Station\n");
rg_ncllog("Send Multicast Message(SEARCH_C_N) to EX on Station", 1);
#endif
	ExMulticast((char *)hp, SZ_EventData);

	if(AM_I_HALFROUTER) {
		hp->head.event_num	= NCL_BC_RELAY;
        	hp->head.req_hnclid	= envofncl.mynclid;
#ifdef	DEBUG
printf(" + Send Multicast Message(SEARCH_C_N) to Half router NCL\n");
rg_ncllog("Send Multicast Message(SEARCH_C_N) to Half router NCL", 1);
#endif
		NclMulticast((char *)hp, SZ_EventData);
	}

	if(AM_I_RELAYNCL && bpp->param1 != 0LL && ISNOT_MYSITEID(bpp->param1)) {
		hp->head.event_num	= NCL_BC_PRIMARY;
#ifdef	DEBUG
printf(" + Send Message(SEARCH_C_N[PRIMARY]) to APGW(%s)\n", ipaddr2str(ncl_table.apgwid));
sprintf(tmp, "Send Message(SEARCH_C_N[PRIMARY]) to APGW(%s)", ipaddr2str(ncl_table.apgwid));
rg_ncllog(tmp, 1);
#endif
		SendApgw((char *)hp, SZ_EventData);
		return;
	}

}

static  void	bc_secondary(EventData hp)
{
BroadcastParam	bpp;
char		tmp[256];

	bpp	= &(hp->data.sc_name.params);
#ifdef	DEBUG
msg_monitor1(hp, "SECONDARY");
#endif
	hp->head.event_num = NE_DOYOUKNOW_C_N;
#ifdef	DEBUG
printf(" + Send Multicast Message(SEARCH_C_N) to EX on station\n");
rg_ncllog(" + Send Multicast Message(SEARCH_C_N) to EX on station", 1);
#endif
	ExMulticast((char *)hp, SZ_EventData);

	if(AM_I_RELAYNCL && bpp->param1 != 0LL && ISNOT_MYSITEID(bpp->param1)) {
		hp->head.event_num	= NCL_BC_SECONDARY;
#ifdef	DEBUG
printf(" + Send Message(SEARCH_C_N[SECONDARY]) to APGW(%s)\n", ipaddr2str(ncl_table.apgwid));
sprintf(tmp, "Send Message(SEARCH_C_N[SECONDARY]) to APGW(%s)\n", ipaddr2str(ncl_table.apgwid));
rg_ncllog(tmp, 1);
#endif
		SendApgw((char *)hp, SZ_EventData);
		return;
	}
}

static  void	bc_relay(EventData hp)
{
#ifdef	DEBUG
msg_monitor1(hp, "RELAY from HalfRouter");
#endif
	SetHalfRouterTbl(hp->head.req_nclfd, hp->head.req_hnclid);

	hp->head.event_num	= NCL_BC_SECONDARY;

#ifdef	DEBUG
printf(" + Send Broadcast Message(SEARCH_C_N[SECONDARY]) to Segment\n");
rg_ncllog("Send Broadcast Message(SEARCH_C_N[SECONDARY]) to Segment", 1);
#endif
	NclBroadcast((char *)hp, SZ_EventData);
}

void	nn_creat_executor(EventData hp)
{
struct sockaddr_in	*addr;
char			tmp[256];

	hp->head.event_num = NE_EXEC_INFO;
	addr	= &(hp->data.cr_exec.exaddress);
        addr->sin_family	= AF_INET;
        addr->sin_port		= 0;
        addr->sin_addr.s_addr	= envofncl.mynclid;

	if(creat_executor_myST(hp)) {
		if(hp->data.cr_exec.request_id == (-1))
			return;
		hp->head.event_num	= NCL_NN_CREATED_EXID;
#ifdef	DEBUG
printf(" + Send Message(CREATE_EXECUTOR) to NFE(%s)\n", ipaddr2str(hp->head.req_nclid));
sprintf(tmp, "Send Message(CREATE_EXECUTOR) to NFE(%s)", ipaddr2str(hp->head.req_nclid));
rg_ncllog(tmp, 1);
#endif
		if(write(hp->head.req_nclfd, (char *)hp, SZ_EventData) <= 0) {
			perror("nn_creat_executor: write");
		}
		return;
	}
#ifdef	DEBUG
printf(" + Send Message(CREATE_EXEC_INFO) to Executor(0x%06x)\n", (int)((hp->data.cr_exec.inst_exid>>24)&0xffffff));
sprintf(tmp, "Send Message(CREATE_EXEC_INFO) to Executor(0x%06x)", (int)((hp->data.cr_exec.inst_exid>>24)&0xffffff));
rg_ncllog(tmp, 1);
#endif
}

static void	nn_created_exid(EventData hp)
{
#ifdef	DEBUG
printf("RECV:NN_CREAT_EXID <- \n");
#endif

	hp->head.event_num	= NE_CREATED_EXID;
	renewal_extable(hp->data.cr_exec.inst_exid, &(hp->data.cr_exec.exaddress), ET_INSITE);

#ifdef	DEBUG
printf("SEND:NE_CREATED_EXID -> EX\n");
#endif
	NclToEx(hp->head.req_exfd, (char *)hp, SZ_EventData);
}

static void	nn_exid_request(EventData hp)
{
char	tmp[256];
#ifdef	DEBUG
printf(" + Received Message(EXID_REQUEST) from NCL(%s)\n", ipaddr2str(hp->head.req_nclid));
sprintf(tmp, "Received Message(EXID_REQUEST) from NCL(%s)", ipaddr2str(hp->head.req_nclid));
rg_ncllog(tmp, 1);
#endif

	hp->head.event_num	= NCL_NN_EXID_RESPONCE;
	hp->head.res_nclid	= envofncl.mynclid;
	recv_exid_request(hp);
	if(write(hp->head.req_nclfd, (char *)hp, SZ_EventData) <= 0) {
		perror("nn_exid_request: write");
		return;
	}
#ifdef	DEBUG
printf(" + Send Message(EXID_RESPONCE) to NCL(%s)\n", ipaddr2str(hp->head.req_nclid));
sprintf(tmp, "Send Message(EXID_RESPONCE) to NCL(%s)", ipaddr2str(hp->head.req_nclid));
rg_ncllog(tmp, 1);
#endif
}

static int	gt_siteid_fromf()
{
FILE	*fp;
char    buf[MAX_LINESIZE], fn[256];

	sprintf(fn, "%s/etc/site-id", envofncl.ozroot);
	if((fp = fopen(fn, "r")) == (FILE *)NULL) {
		fprintf(stderr, "Can't found site-id file %s/etc/site-id\n", envofncl.ozroot);
		return(1);
        }
	if(fgets(buf, MAX_LINESIZE, fp) == (char *)NULL) {
		fprintf(stderr, "%s/etc/site-id is empty\n", envofncl.ozroot);
		return(1);
	}
	if(buf[strlen(buf)-1] == '\n') buf[strlen(buf)-1] = 0x00;
	fclose(fp);
	envofncl.siteid	= strhtoi(buf);
	if(envofncl.siteid == (long)0 || envofncl.siteid == (long)(-1)) {
		fprintf(stderr, "%s missing data %s\n", fn, buf);
		return(1);
	}
	printf("Get site-id(%04x) from file(%s)\n", envofncl.siteid, fn);
	return(0);
}

static void	init_nclopt(int argc, char *argv[])
{
int		i;
struct hostent	*hp;
char		*p, buf[80];

	if(argc != 1 && argc != 3) {
		printf("Usage: %s\n", argv[0]);
		exit(1);
	}
	bzero((char *)&envofncl, sizeof(NclEnvRec));
	if((p = (char *)getenv("OZROOT")) == (char *)NULL) {
		(void)printf("init_nclopt: Please set enveronment value OZROOT\n");
		exit(1);
	}
	strcpy(envofncl.ozroot, p);
	if(argc == 3) {
		if(strcmp(argv[1], "-p")) {
			printf("Usage: %s [-p UDP-Port-number-offset]\n", argv[0]);
			exit(1);
		}
		envofncl.seg_num	= atoi(argv[2]);
	}
	if(envofncl.siteid == (long)0) {
		if(gt_siteid_fromf())
			exit(1);
	} else {
		printf("Get site-id(%d) from Nucleus Argument\n", envofncl.siteid);
	}
	gethostname(buf, 80);
	if (!(hp = gethostbyname(buf))) {
		fprintf(stderr, "init_nclopt: %s: unknown host\n", buf);
		exit(1);
	}
	bcopy(hp->h_addr, &(envofncl.mynclid), sizeof(long));
}

void	getchild()
{
union wait	status;
int		pid;
long long	exid;
char		tmp[256];

	for(;;) {
		pid = wait3(&status, WNOHANG, (struct rusage *)0);
		if(pid <= 0)
	    		break;
		
#ifdef	DEBUG
		printf("\ngetchild: Child process finished pid(%d)  ", pid);
		if (status.w_termsig != 0) {
			sprintf(tmp, "%s exited with signal %d", EX_COMMAND, status.w_termsig);
			printf("%s\n", tmp);
		} else {
			sprintf(tmp, "%s exited with status %d", EX_COMMAND, status.w_retcode);
			printf("%s\n", tmp);
		}
#endif
		if(envofncl.frd_pid == pid) {
			printf(" => OZ++ Daemon OzFileReceiver terminated\n");
			envofncl.frd_pid	= 0;
		}
		if(envofncl.fsd_pid == pid) {
			printf(" => OZ++ Daemon OzFileSender terminated\n");
			envofncl.fsd_pid	= 0;
		}
	}
}

static void	exec_ozfiledaemon()
{
int	i;
char	*frd[5] = { "OzFileReceiver", (char *)0 };
char	*fsd[5] = { "OzFileSender", (char *)0 };
char	ofr[256], ofs[256];

	sprintf(ofr, "%s/bin/OzFileReceiver", envofncl.ozroot);
	sprintf(ofs, "%s/bin/OzFileSender", envofncl.ozroot);
	if((envofncl.frd_pid = fork()) == 0) {
		for (i = 3; i < NOFILE; i++)
			close(i);
		signal(SIGPIPE, SIG_DFL);
		signal(SIGCHLD, SIG_DFL);
		signal(SIGHUP, SIG_DFL);
		signal(SIGTERM, SIG_DFL);
		execv(ofr, frd);
		perror("execv: OzFileReceiver");
		exit(1);
	}
	if((envofncl.fsd_pid = fork()) == 0) {
		for (i = 3; i < NOFILE; i++)
			close(i);
		signal(SIGPIPE, SIG_DFL);
		signal(SIGCHLD, SIG_DFL);
		signal(SIGHUP, SIG_DFL);
		signal(SIGTERM, SIG_DFL);
		execv(ofs, fsd);
		perror("execv: OzFileSender");
		exit(1);
	}
}

main(int argc, char *argv[])
{
EventDataRec	hh;
struct sigvec	vec;

	init_nclopt(argc, argv);

	printf("################################################################################\n");

	printf("# Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan (IPA)  #\n");
	printf("#                                                                              #\n");

	printf("# All right reserved.                                                          #\n");
	printf("# This software and documentation is a result of the Open Fundamental Software #\n");
	printf("# Technology Project of Information-technology Promotion Agency, Japan (IPA).  #\n");
	printf("#                                                                              #\n");
	printf("# Permission to use, copy, modify and distribute this software are granted by  #\n");
	printf("# the terms and conditions set forth in the file COPYRIGHT, located in this    #\n");
	printf("# release package.                                                             #\n");
	printf("################################################################################\n");
	printf("### OZ++ System Nucleus(Version 3.2) Started ###\n");
	init_ncl_log();

	if(sysconf(_POSIX_SAVED_IDS) == (-1)) {
		perror("sysconf(_POSIX_SAVED_IDS)");
		exit(1);
	}

	if(init_ncl_table())
		exit(1);
	init_ncl_port();
	init_ncl_bport();
	init_executor_table();
	init_exid_mnginfo();

	signal(SIGPIPE, SIG_IGN);
	signal(SIGHUP, end_ncl);
	signal(SIGTERM, end_ncl);
	vec.sv_handler	= getchild;
	vec.sv_mask	= 0;
	vec.sv_flags	= 0;
	if(sigvec(SIGCHLD, &vec, 0) == (-1)) {
		perror("sigvec");
		end_ncl(1);
	}

	exec_ozfiledaemon();

	bzero((char *)&hh, SZ_EventData);
	for (;;) {	/* Event loop	*/ 
		bzero((char *)&nclarg, sizeof(NclArg));
		accept_event(&hh);
		(*(event_act[hh.head.event_num].func))(&hh);
	}
}

