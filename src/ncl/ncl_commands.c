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
#include <signal.h>
#include <errno.h>

#include "ncl.h"
#include "ncl_defs.h"
#include "ncl_shell.h"
#include "exec_table.h"
#include "ncl_extable.h"
#include "ex_ncl_event.h"

int		request_cnt = 0;
RequestTblRec	requesttbl[MAX_OF_REQTBL];

extern int	errno;
extern char	*sys_errlist[];

extern NclEnvRec	envofncl;
extern ExTableEntryRec	extentry;

extern int	rg_ncllog(char *msg, int sw);
extern void	ncl_exstatus(EventData hp);
extern void	ncl_extable(EventData hp);
extern void	ncl_ncltable(EventData hp);
extern void	mySTEx_killall();
extern void	end_ncl(int st);
extern int	st_newexid(long *p);
extern char	*ipaddr2str(long ll);
extern void	fr_halfroutertbl(int fd);
extern void	remove_executor_table();
extern char	*ntime(char *dp);
extern void	SetExFd(fd_set *rfds);
extern int	FdIsSetEX(fd_set *rfds);
extern MySTExBlock	IsExidEntry(long long id);

RequestTbl	get_requesttbl()
{
int	i;

	if(!request_cnt)
		bzero((char *)requesttbl, sizeof(RequestTblRec)*MAX_OF_REQTBL);

	for(i=0; i<MAX_OF_REQTBL; i++) {
		if(requesttbl[i].fd == 0) {
			request_cnt++;
			time(&(requesttbl[i].tm));
			return(&requesttbl[i]);
		}
	}
	printf("get_requesttbl: Request Table over fllow\n");
	return((RequestTbl)0);
}

void	fr_requesttbl(int fd)
{
int	i;

	for(i=0; i<MAX_OF_REQTBL; i++) {
		if(requesttbl[i].fd == fd) {
			if(close(requesttbl[i].fd) == (-1))
				perror("fr_requesttbl: close");
			bzero((char *)&requesttbl[i], sizeof(RequestTblRec));
			request_cnt--;
			return;
		}
	}
	printf("fr_requesttbl: Warning: File descriptor(%d) not match\n", fd);
}

void	SetNclFd(fd_set *rfds)
{
int	i;

	if(!request_cnt)
		return;

	for(i=0; i<MAX_OF_REQTBL; i++) {
		if(requesttbl[i].fd == 0)
			continue;
		FD_SET(requesttbl[i].fd, rfds);
	}
}

int	FdIsSetNCL(fd_set *rfds)
{
int	i;

	if(!request_cnt)
		return(0);

	for(i=0; i<MAX_OF_REQTBL; i++) {
		if(requesttbl[i].fd == 0)
			continue;
		if(FD_ISSET(requesttbl[i].fd, rfds))
			return(requesttbl[i].fd);
	}
	return(0);
}

void	 ncl_rwho(EventData hp)
{
int		i;
char		*p;

#ifdef	DEBUG
printf(" + Received Request Message(NCL_RWHO) from NFE(%s)\n", ipaddr2str(hp->head.req_nclid));
#endif
	p	= (char *)hp->data.data;
	bcopy((char *)&(request_cnt), p, sizeof(long));
	p += sizeof(long);

	for(i=0; i<MAX_OF_REQTBL; i++) {
		if(requesttbl[i].fd == 0)
			continue;
		bcopy((char *)&requesttbl[i], p, sizeof(RequestTblRec));
		p += sizeof(RequestTblRec);
	}
	if(write(hp->head.req_nclfd, (char *)hp, SZ_EventData) <= 0) {
		perror("ncl_rwho: write");
		fr_requesttbl(hp->head.req_nclfd);
		return;
	}
#ifdef	DEBUG
printf(" + Send Responce Message(NCL_RWHO) to NFE(%s)\n", ipaddr2str(hp->head.req_nclid));
#endif
}

void	 ncl_killex(EventData hp)
{
NfeMent		rp;
long long	exid;
int		sig;
MySTExBlock	cp;

#ifdef	DEBUG
printf(" + Received Request Message(NCL_KILLTOEX) from NFE(%s)\n", ipaddr2str(hp->head.req_nclid));
#endif
	rp	= (NfeMent)hp->data.data;

	exid	= 0LL;
	SET_SITE(exid, envofncl.siteid);
	SET_EX(exid, rp->data.ex_kill.exid);
	sig	= rp->data.ex_kill.signum;

	if((cp = IsExidEntry(exid)) == (MySTExBlock)0) {
		rp->data.ex_kill.status = (-1);
		sprintf(&(hp->data.data[800]), "No such process of ExecutorID(%06x)", rp->data.ex_kill.exid);
	} else {
		rp->data.ex_kill.status = kill(cp->pid, sig);
		sprintf(&(hp->data.data[800]), sys_errlist[errno]);
	}

	if(write(hp->head.req_nclfd, (char *)hp, SZ_EventData) <= 0) {
		perror("ncl_killex: write");
		fr_requesttbl(hp->head.req_nclfd);
		return;
	}
#ifdef	DEBUG
printf(" + Send Responce Message(NCL_KILLTOEX) to NFE(%s)\n", ipaddr2str(hp->head.req_nclid));
#endif
}

static void	ncl_getnewexid(EventData hp)
{
NfeMent	rp;
int	er;
long	l;

#ifdef  DEBUG
printf(" + Received Message(GET_NEWEXID) from NFE(%s)\n", ipaddr2str(hp->head.req_nclid));
#endif
        rp      = (NfeMent)hp->data.data;
        if(er = st_newexid(&l)) {
                printf(" + Get New Executor-ID failed\n");
                rp->data.gtneid.status  = er;
        } else {
        	SET_EX(rp->data.gtneid.exid, l);
	}
        if(write(hp->head.req_nclfd, (char *)hp, SZ_EventData) <= 0) {
                perror("ncl_getnewexid: write");
                fr_requesttbl(hp->head.req_nclfd);
        }
#ifdef  DEBUG
printf(" + Send Message(GET_NEWEXID) to NFE(%s)\n", ipaddr2str(hp->head.req_nclid));
#endif
}

static void	NfeMulticast(EventData hp)
{
int	i, n;

	if(!request_cnt)
		bzero((char *)requesttbl, sizeof(RequestTblRec)*MAX_OF_REQTBL);

	for(i=0,n=request_cnt; i<MAX_OF_REQTBL && n; i++) {
		if(requesttbl[i].fd==0 || !(requesttbl[i].con & NFE_CONNECTED))
			return;
		if(write(requesttbl[i].fd, hp, SZ_EventData) <= 0) {
			perror("NfeMulticast: write");
			fr_requesttbl(requesttbl[i].fd);
		}
		n--;
	}
}

static void	wait_nfe_terminate()
{
EventDataRec	hh;
int		nfd, cfd;
fd_set		rfds;
long long	exid;

	while(1) {
		FD_ZERO(&rfds);
		SetNclFd(&rfds);
		nfd = select(getdtablesize(), &rfds, NULL, NULL, NULL);
		if(nfd < 0) {
			perror("wait_nfe_terminate: select: ");
			continue;
		}
		if(cfd = FdIsSetNCL(&rfds)) {
			if(read(cfd, (char *)&hh, SZ_EventData) > 0) {
                                continue;
                        }
                        fr_requesttbl(cfd);
printf("NFE Connect was closed fd(%d)\n", cfd);
                        return;

		}
	}
}

static void	ncl_shutdown(EventData hp)
{
NfeMent	rp;
char	buf[128], tmp[256];
int	i;

	rp	= (NfeMent)hp->data.data;
	if(rp->data.n_stdwn.status == STDWN_CHECK) {
#ifdef	DEBUG
printf(" + Received SHUTDOWN CHECK Message from NFE(%s)\n", ipaddr2str(hp->head.req_nclid));
sprintf(tmp, "Received SHUTDOWN CHECK Message from NFE(%s)", ipaddr2str(hp->head.req_nclid));
rg_ncllog(tmp, 1);
#endif
		if(extentry.ex_cnt) {
			rp->data.n_stdwn.ex_cnt	= extentry.ex_cnt;
			if(write(hp->head.req_nclfd, (char *)hp, SZ_EventData) <= 0) {
				perror("ncl_shutdown: write");
				fr_requesttbl(hp->head.req_nclfd);
			}
			return;
		}
		rp->data.n_stdwn.status	= STDWN_MSG;
	}
	NfeMulticast(hp);
#ifdef	DEBUG
printf(" + Received SHUTDOWN Message from NFE(%s),", ipaddr2str(hp->head.req_nclid));
printf(" Nucleus going down in %d Seconds\n", rp->data.n_stdwn.tm);
sprintf(tmp, "Received SHUTDOWN Message from NFE(%s), Nucleus going down in %d Seconds", ipaddr2str(hp->head.req_nclid), rp->data.n_stdwn.tm);
rg_ncllog(tmp, 1);
#endif
	if(rp->data.n_stdwn.tm)
		return;

	rp->data.n_stdwn.status	= STDWN_START;
	NfeMulticast(hp);
#ifdef	DEBUG
printf(" + Received SHUTDOWN Message from NFE(%s),", ipaddr2str(hp->head.req_nclid));
printf(" Nucleus going down in IMMEDIATELY\n");
printf(" + Nucleus SHUTDOWN time has arrived\n");
sprintf(tmp, "Received SHUTDOWN Message from NFE(%s),Nucleus going down in IMMEDIATELY", ipaddr2str(hp->head.req_nclid));
rg_ncllog(tmp, 1);
sprintf(tmp, "Nucleus SHUTDOWN time has arrived");
rg_ncllog(tmp, 1);
#endif

	if(AM_I_HALFROUTER) {
#ifdef	DEBUG
printf(" => %s Half-Router: connect going down\n", ntime(buf));
rg_ncllog("Half-Router: connect going down", 1);
#endif
		fr_halfroutertbl(-1);
		rp->data.n_stdwn.status	= STDWN_HNCLCLOSE;
		NfeMulticast(hp);
	}

#ifdef	DEBUG
printf(" => %s Executor: going down on signal SIGTERM\n", ntime(buf));
rg_ncllog("Executor: going down on signal SIGTERM", 1);
#endif
	mySTEx_killall();
	rp->data.n_stdwn.status	= STDWN_EXKILL;
	NfeMulticast(hp);

#ifdef	DEBUG
printf(" => %s Executor-table: Shared memory removed\n", ntime(buf));
rg_ncllog("Executor-table: Shared memory removed", 1);
#endif
	remove_executor_table();
	rp->data.n_stdwn.status	= STDWN_DELEXTBL;
	NfeMulticast(hp);
	rp->data.n_stdwn.status	= STDWN_FINISHED;
	NfeMulticast(hp);
	while(request_cnt)
		wait_nfe_terminate();

        if(envofncl.frd_pid) {
                kill(envofncl.frd_pid, SIGTERM);
        }
        if(envofncl.fsd_pid) {
                kill(envofncl.fsd_pid, SIGTERM);
        }
#ifdef	DEBUG
printf("Nucleus is done\n");
rg_ncllog("Nucleus is done", 1);
#endif
	if(envofncl.s) {
                if(close(envofncl.s) == (-1))
                        perror("end_ncl: close");
        }
	exit(0);
}

void	ncl_ment_command(EventData hp)
{
RequestTbl	rtp;
NfeMent	rp;

	
	rp	= (NfeMent)hp->data.data;
	switch(rp->nfe_comm) {
		case NFE_CONNECT:
			rtp	= get_requesttbl();
			rtp->fd = hp->head.req_nclfd;
			rtp->con |= NFE_CONNECTED;
			rtp->uid = hp->head.req_uid;
			rtp->ip = hp->head.req_nclid;
			return;
		case NFE_EXSTATUS:
			ncl_exstatus(hp);
			return;
		case NFE_EXTABLE:
			ncl_extable(hp);
			return;
		case NFE_NCLTABLE:
			ncl_ncltable(hp);
			return;
		case NFE_RWHO:
			ncl_rwho(hp);
			return;
		case NFE_GETNEWEXID:
			ncl_getnewexid(hp);
			return;
		case NFE_KILLTOEX:
			ncl_killex(hp);
			return;
		case NFE_SHUTDOWN:
			ncl_shutdown(hp);
			return;
		default:
			printf("ncl_ment_command: Illegal command 0x%x\n", rp->nfe_comm);
			return;
	}
}
