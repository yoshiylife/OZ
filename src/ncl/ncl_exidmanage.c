/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <errno.h>

#include "ncl.h"
#include "ncl_defs.h"
#include "ex_ncl_event.h"
#include "ncl_table.h"
#include "ncl_exid.h"

char	exidmngdir[256];
char	exidmnglog[256];

extern NclEnvRec	envofncl;
extern NclTableRec	ncl_table;
extern int		errno;

extern int	rg_ncllog(char *msg, int sw);
extern char	*ipaddr2str(long addr);
extern int	NclToNclTCP(long saddr, char *p, int size);
extern void	end_ncl(int st);
extern char	*ntime(char *dp);
extern int	strhtoi(char *dp);
extern char	*index(char *p, char c);

static int	ana_exidinfo_sub(char *tmp, ExidInfoST ep)
{
char	*tp, *etp;

	for(tp=tmp; *tp!='('; tp++);
	for(etp=tp+1; *etp!=')'; etp++);
	*etp	= 0x00;
	ep->exid	= (long)strhtoi(tp + 1);

	for(tp=etp; *tp!='('; tp++);
	for(etp=tp+1; *etp!=')'; etp++);
	*etp	= 0x00;
	ep->rest_of_exid	= (long)strhtoi(tp + 1);
	return(0);
}

static int	ana_exidinfo(char *dt, int n, ExidMngInfo info)
{
char	*p, *ep, *tp;
char	tmp[128];

	for(p=dt,ep=dt+n; p<ep; p++) {
		bzero(tmp, 128);
		for(tp=tmp; *p!='\n'&&*p!=0x00; p++,tp++)
			*tp	= *p;
		if(isalpha(tmp[0]) == 0) continue;
		if(!strncmp(tmp, "IN_ACTIVITY:", 12)) {
			ana_exidinfo_sub(tmp, &(info->active));
			continue;
		}
		if(!strncmp(tmp, "RESERVATION:", 12)) {
			ana_exidinfo_sub(tmp, &(info->reserve));
			continue;
		}
		if(!strncmp(tmp, "EXID_OF_SITE:", 13)) {
			tp	= index(tmp, ':') + 1;
			info->exid_of_site_now	= (long)strhtoi(tp);
			continue;
		}
	}
	return(0);
}

static int	attatch_exidinfo(ExidMngInfo info)
{
int	fd, n;
char	buf[2048];
#if	1
ExidMngInfoOld	opp;
ExidInfoSTOld	oldp;
#endif

	if((fd = open(exidmngdir, O_RDONLY)) < 0) {
		return(0);
	}
	bzero(buf, 2048);
	if((n = read(fd, buf, 2048)) == 0) {
		perror("attatch_exidinfo: ");
		close(fd);
		return(0);
	}

#if	1
	if(buf[0] == 0x00) {
		opp	= (ExidMngInfoOld)buf;
		bzero((char *)info, SZ_ExidMngInfo);
		if(opp->sw != (-1)) {
			oldp	= &(opp->exid_infoST[opp->sw]);
			info->active.exid = (long)((oldp->start_exid>>24)&0xffffffLL);
			info->active.rest_of_exid = oldp->num_of_exid;
		}
		info->exid_of_site_now = (long)((opp->start_exid_site>>24)&0xffffffLL);
	} else {
#endif
		ana_exidinfo(buf, n, info);
#if	1
	}
#endif

	close(fd);
	return(fd);
}

static int	set_exidinfo(char *dt, ExidMngInfo info)
{
char		*p;
ExidInfoST	ep;

	sprintf(dt, "#\n# Informations of ExecutorID management\n#\n");
	p	= dt + strlen(dt);
	ep	= &(info->active);
	sprintf(p, "IN_ACTIVITY:ExecutorID(%06x),Rest(%x)\n", ep->exid, ep->rest_of_exid);
	p	= dt + strlen(dt);
	ep	= &(info->reserve);
	sprintf(p, "RESERVATION:ExecutorID(%06x),Rest(%x)\n", ep->exid, ep->rest_of_exid);
	if(AM_I_EXIDMANAGE) {
		p	= dt + strlen(dt);
		sprintf(p, "EXID_OF_SITE:%06x\n", info->exid_of_site_now);
	}
	return(strlen(dt));
}

static int	dettach_exidinfo(ExidMngInfo info)
{
int	fd, n;
char	buf[2048];

	if((fd = open(exidmngdir, O_RDWR)) < 0) {
		return(0);
	}

	bzero(buf, 2048);
	n	= set_exidinfo(buf, info);
	if(write(fd, buf, n) == (-1)) {
		perror("dettach_exidinfo: ");
		close(fd);
		return(0);
	}
	close(fd);
	return(fd);
}

static int	wait_exid_responce(int s, ExidMngInfo info)
{
EventDataRec		hh;
struct sockaddr_in	sin;
int			nfd, nb, size;
fd_set			rfds;
ExidInfoST		ep;
#ifdef	DEBUG
char	*np;
#endif

	size	= sizeof(sin);

	FD_ZERO(&rfds);
	FD_SET(s, &rfds);
	nfd = select(getdtablesize(), &rfds, NULL, NULL, NULL);
	if(nfd < 0) {
		perror("wait_exid_responce: select: ");
		return(1);
	}
	if(FD_ISSET(s, &rfds) == 0)
		return(1);

	nb = read(s, (char *)&hh, SZ_EventData);
	fr_requesttbl(s);
	if(nb <= 0)
		return(1);
	ep = (info->active.exid==(long)0)?&(info->active):&(info->reserve);
	ep->exid	= (long)((hh.data.gt_exid.start_exid>>24)&0xffffffLL);
	ep->rest_of_exid	= hh.data.gt_exid.num_of_exid;
#ifdef	DEBUG
np	= ipaddr2str(ncl_table.exid_manage.addr);
printf("   Adopted ExID(0x%06x from %d counts) from Exid-management Nucleus(%s)\n", ep->exid, ep->rest_of_exid, np);

printf(" + Received Massage(EXID_RESPONCE) from Nucleus(%s)\n", np);
#endif
	return(0);
}

int	send_exid_request(int *er)
{
int		s;
EventDataRec	nn;
char		tmp[256];

	if(ncl_table.exid_manage.addr == (long)0) {
		printf(" => EXID Management Nucleus is not registered among the Nuclues-Table\n");
		*er	= 1;

		return(0);
	}
#ifdef	DEBUG
printf(" + Send Massage(EXID_REQUEST) to Nucleus(%s)\n", ipaddr2str(ncl_table.exid_manage.addr));
sprintf(tmp, "Send Massage(EXID_REQUEST) to Nucleus(%s)", ipaddr2str(ncl_table.exid_manage.addr));
rg_ncllog(tmp, 1);
#endif
	nn.head.event_num	= NCL_NN_EXID_REQUEST;
	nn.head.req_nclid	= envofncl.mynclid;
	nn.head.req_nclfd	= envofncl.s;

	s = NclToNclTCP(ncl_table.exid_manage.addr, (char *)&nn, SZ_EventData);
	if(s == 0) {
		printf(" =>  Exid Managemnet Nucleus(%s) connect failed\n", ipaddr2str(ncl_table.exid_manage.addr));
		*er	= 2;
		return(0);
	}

	return(s);
}

static void	init_exid_mnglog(char *hostn)
{
int	fd;
char	buf[256], buf1[64];

	sprintf(exidmnglog, "%s/etc/ncl-data/ExID_manage.log", envofncl.ozroot);
	if((fd = open(exidmnglog, O_RDONLY)) >= 0) {
		close(fd);
		return;
	}

	if((fd = open(exidmnglog, O_CREAT|O_RDWR, 0666)) < 0) {
		perror("init_exid_mnglog: open:");
		printf("init_exid_mnglog: %s create failed\n", exidmnglog);
		end_ncl(1);
	}
	sprintf(buf, "%s: <ExecutorID management nucleus(%s) log start>\n", ntime(buf1), hostn);
	if(write(fd, buf, strlen(buf)) == (-1)) {
		perror("dettach_exidinfo: ");
	}
	close(fd);
}

static int	exid_manage_log(long exid, long cnt, long naddr, int er)
{
int	fd;
char	buf[256], buf1[64];
char	*ermsg[] = {
	"",
	"Can't open ExecutorID management file"
};

	if((fd = open(exidmnglog, O_APPEND|O_WRONLY)) < 0) {
		perror("exid_manage_log: ");
		printf("exid_manage_log: Can't open LOG file(%s)\n", exidmnglog);
		return(0);
	}

	ntime(buf1);
	if(er) {
		sprintf(buf, "%s: %s: %s\n", buf1, ipaddr2str(naddr), ermsg[er]);
	} else {
		sprintf(buf, "%s: provided ExID(0x%06x from %d counts) to Nucleus(%s)\n", buf1, exid, cnt, ipaddr2str(naddr));
	}

	if(write(fd, buf, strlen(buf)) == (-1)) {
		perror("exid_manage_log: ");
		close(fd);
		return(0);
	}
	close(fd);
}

void	init_exid_mnginfo()
{
int		fd, er, n;
ExidMngInfoRec	info;
char		buf[2048];

	gethostname(buf, 64);
	sprintf(exidmngdir, "%s/etc/ncl-data/EXID/%s", envofncl.ozroot, buf);
	if(AM_I_EXIDMANAGE) {
		init_exid_mnglog(buf);
	}
	if(attatch_exidinfo(&info))
		return;

	if(AM_I_EXIDMANAGE) {
		printf("init_exid_mnginfo: Can't open ExecutorID management file(%s)\n", exidmngdir);
		exid_manage_log(0, 0, envofncl.mynclid, 1);
		end_ncl(1);
	}
	if((fd = open(exidmngdir, O_CREAT|O_RDWR, 0666)) < 0) {
		printf("init_exid_mnginfo: %s create failed\n", exidmngdir);
		end_ncl(1);
	}
	bzero((char *)&info, SZ_ExidMngInfo);
	if(AM_I_EXIDMANAGE) {
		info.exid_of_site_now	= START_EXID_SITE;
	}
	n	= set_exidinfo(buf, &info);
	if(write(fd, buf, n) == (-1)) {
		perror("dettach_exidinfo: ");
	}
	close(fd);
}

void	disp_exid_mnginfo()
{
ExidMngInfoRec	info;

	attatch_exidinfo(&info);
	if(AM_I_EXIDMANAGE) {
		printf("This Nucleus is Executor-ID manager\n");
		printf("ExecutorID of Site: 0x%06x\n", info.exid_of_site_now);
	}
	printf("IN_ACTIVITY:ExecutorID(0x%06x),Rest(%d)\n", info.active.exid, info.active.rest_of_exid);
	printf("RESERVATION:ExecutorID(0x%06x),Rest(%d)\n", info.reserve.exid, info.reserve.rest_of_exid);
}

void	recv_exid_request(EventData np)
{
ExidMngInfoRec	info;

	if(attatch_exidinfo(&info) == 0) {
		printf("recv_exid_request: exidinfo attatch failed\n");
		return;
	}

#ifdef	DEBUG
printf("   Maintenanced EXID(0x%06x from %d counts) for requester Nucleus(%s)\n", info.exid_of_site_now, INC_EXID_ST, ipaddr2str(np->head.req_nclid));
#endif
	SET_EX(np->data.gt_exid.start_exid, info.exid_of_site_now);
	np->data.gt_exid.num_of_exid	= INC_EXID_ST;

	exid_manage_log(info.exid_of_site_now, INC_EXID_ST, np->head.req_nclid, 0);

	info.exid_of_site_now += INC_EXID_ST;

	dettach_exidinfo(&info);
}

static int	gt_newexid_myST(ExidMngInfo info)
{
int		n;
int		er;
ExidInfoST	ep;

	if(AM_I_EXIDMANAGE == 0) {
		if((n = send_exid_request(&er)) == 0)
			return(er);
		if(wait_exid_responce(n, info)) {
			printf(" => EXID Management Nucleus(%s) connection was down.\n", ipaddr2str(ncl_table.exid_manage.addr));
			return(3);
		}
		return(0);
	}

	ep = (info->active.exid==(long)0)?&(info->active):&(info->reserve);
	ep->exid		= info->exid_of_site_now;
	ep->rest_of_exid	= INC_EXID_ST;
	exid_manage_log(ep->exid, INC_EXID_ST, envofncl.mynclid, 0);
	info->exid_of_site_now += INC_EXID_ST;
	return(0);
}

int	st_newexid(long *p)
{
int		er;
ExidMngInfoRec	info;

	if(attatch_exidinfo(&info) == 0) {
		printf("st_newexid: exidinfo attatch failed\n");
		return(ER_GETNEW_EXID);
	}

	if(info.active.rest_of_exid == 0L && info.reserve.exid != 0L) {
		info.active.exid	= info.reserve.exid;
		info.active.rest_of_exid = info.reserve.rest_of_exid;
		info.reserve.exid	= 0L;
		info.reserve.rest_of_exid = 0L;
	}
	if(info.active.rest_of_exid <= (long)10) {
		if(er = gt_newexid_myST(&info)) return(er);
	}
	*p	= info.active.exid;
	info.active.exid++;
	info.active.rest_of_exid--;

	dettach_exidinfo(&info);
	return(0);
}
