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
#include <stdlib.h>
#include <pwd.h>
#include <dirent.h>

#include "ncl.h"
#include "ncl_defs.h"
#include "ex_ncl_event.h"
#include "exec_table.h"
#include "ncl_extable.h"
#include "ncl_table.h"
#include "ncl_shell.h"

#define	OPT_CFLAG	0x00000001

typedef struct {
	char	s[MAX_COMMANDL];
	char	d[MAX_COMMANDL];
} AliasRec;

typedef struct	{
	char	*signame;
	int	signum;
} SignalTableRec,* SignalTable;

typedef	struct	{
	char	*commstr;
	int	commlen;
	void	(*func)();
} MentCommandsRec, *MentCommands;

static void	ment_help();
static void	ment_shutdown();
static void	ment_es();
static void	ment_createx();
static void	ment_ncltbl();
static void	disp_nclenv();
static void	disp_nclman();
static void	ment_alias();
static void	ment_et();
static void	ment_quit();
static void	ment_rwho();
static void	ment_killex();
static void	ment_newimage();
static void	ment_migrateimage();
static void	ment_exidlist();
static void	ment_exidment();
static void	ment_exidrm();
static int	set_nfeargs();
static void	ment_interpreter();

MentCommandsRec	ment_act[] = {
	{ "help", 4, ment_help },
	{ "nclshutdown", 11, ment_shutdown },
	{ "es", 2, ment_es },
	{ "cex", 3, ment_createx },
	{ "ncltbl", 6, ment_ncltbl },
	{ "env", 3, disp_nclenv },
#ifndef	RELEASE
	{ "exidinfo", 8, disp_exid_mnginfo },
#endif
	{ "man", 3, disp_nclman },
	{ "et", 2, ment_et },
	{ "alias", 5, ment_alias },
	{ "source", 6, ment_interpreter },
	{ "who", 3, ment_rwho },
	{ "newimage", 8, ment_newimage },
	{ "migrateimage", 12, ment_migrateimage },
	{ "exidlist", 8, ment_exidlist },
	{ "exidment", 8, ment_exidment },
	{ "exidrm", 6, ment_exidrm },
	{ "killex", 6, ment_killex },
	{ "quit", 4, ment_quit },
	{ (char *)0, 0, 0 }
};

typedef struct	{
	long	myaddr;
	long	nfeaddr;
	int	nfefd;
	int	current_sec;
	int	stdwn_sec;
	int	flag30;
	long	optsw;
	char	ozroot[256];
	char	exidi[256];
} NfeMangTblRec, *NfeMangTbl;

SignalTableRec	sigtbl[20] = {
	"HUP",	1,
	"INT",	2,
	"QUIT",	3,
	"KILL", 9,
	"TERM",	15,
	(char *)0, 0
};

NfeMangTblRec	nfetbl;
int		a_cnt;
AliasRec	alias_tbl[MAX_ALIAS];
NclArg		nfearg;
char		tmpbuf[256];

static int	strhtoi(char *str)
{
int		n, i;
unsigned int	m, g;
char		*p;

char	hd[] = "0123456789abcdef";

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

char	*ipaddr2str(long addr)
{
struct hostent	*hep;
unsigned long	l;

	hep 	= gethostbyaddr((char *)&(addr), sizeof(long), AF_INET);
	if((int)hep) {
		strcpy(tmpbuf, hep->h_name);
	} else {
		l = addr;
		sprintf(tmpbuf, "%d.%d.%d.%d", l>>24,(l>>16)&0xff,(l>>8)&0xff, l&0xff);
	}
	return(tmpbuf);
}

static long	hostn2addr(char *hostn)
{
long		addr;
struct hostent	*hep;

	if ((addr = inet_addr(hostn)) == (-1)) {
		if (!(hep = gethostbyname(hostn))) {
			perror("hostn2addr: gethostbyname: ");
			return(-1);
		}
		bcopy(hep->h_addr, &addr, sizeof(long));
	}
	return(addr);
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

static int	nfe_connect()
{
struct sockaddr_in	peer;
int			fd;

        peer.sin_family = AF_INET;
        peer.sin_port = (unsigned short)PROVISIONAL_PORT;
	peer.sin_addr.s_addr = nfetbl.nfeaddr;
	if((fd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
		perror("nfe_connect: socket");
		return(0);
	}
	if(connect(fd, (struct sockaddr *)&peer, sizeof(peer)) < 0) {
		perror("nfe_connect: connect");
printf(" + Is not active Nucleus(%s) ?\n", ipaddr2str(nfetbl.nfeaddr));
		close(fd);
		return(0);
	}
#ifndef	RELEASE
printf(" + Successful in Connect to Nucleus(%s)\n", ipaddr2str(nfetbl.nfeaddr));
#endif
	nfetbl.nfefd		= fd;
	return(1);
}

static int	write_nclevent(int fd, char *p, int size)
{
	if(fd == 0) {
		if(nfe_connect() == 0)
			return(0);
	}
	if(write(fd, p, size) <= 0) {
		perror("write_nclevent: write");
		close(fd);
		nfetbl.nfefd	= 0;
		return(0);
	}
	return(1);
}

static int      wait_responce(EventData hp)
{
fd_set	rfd;

	while(1) {
		FD_ZERO(&rfd);
		FD_SET(nfetbl.nfefd, &rfd);
		if(select(getdtablesize(), &rfd, NULL, NULL, NULL) < 0) {
			perror("wait_responce: select: ");
			continue;
		}

		if(FD_ISSET(nfetbl.nfefd, &rfd)) {
			bzero((char *)hp, SZ_EventData);
			if(read(nfetbl.nfefd, (char *)hp, SZ_EventData) < SZ_EventData)
				return(1);
			return(0);
		}
	}
}

static int      send_request(EventData hp, char *msg)
{
#ifndef	RELEASE
printf(" + Send %s to Nucleus(%s)\n", msg, ipaddr2str(nfetbl.nfeaddr));
#endif
	if(write_nclevent(nfetbl.nfefd, (char *)hp, SZ_EventData) == 0) {
		return(-1);
	}
#ifndef	RELEASE
printf(" + Waiting for Nucleus(%s) responce\n", ipaddr2str(nfetbl.nfeaddr));
#endif
	if(wait_responce(hp)) {
		printf(" + Disconnect from Nucleus(%s)\n", ipaddr2str(nfetbl.nfeaddr));
		close(nfetbl.nfefd);
		nfetbl.nfefd	= 0;
		return(1);
	}
	return(0);
}

static void	ment_alias()
{
int	i, j;

	if(nfearg.argc == 0) {
		for(i=0; i<a_cnt; i++)
			printf("%-10s %s\n", alias_tbl[i].s, alias_tbl[i].d);
		return;
	}
	for(i=0; i<a_cnt; i++) {
		if(!strcmp(alias_tbl[i].s, nfearg.argv[1])) {
			bzero(alias_tbl[i].d, MAX_COMMANDL);
			strcpy(alias_tbl[i].d, nfearg.argv[2]);
			for(j=3; j<=nfearg.argc; j++) {
				strcat(alias_tbl[i].d, " ");
				strcat(alias_tbl[i].d, nfearg.argv[j]);
			}
			return;
		}
	}
	strcpy(alias_tbl[a_cnt].s, nfearg.argv[1]);
	bzero(alias_tbl[i].d, MAX_COMMANDL);
	strcpy(alias_tbl[i].d, nfearg.argv[2]);
	for(j=3; j<=nfearg.argc; j++) {
		strcat(alias_tbl[i].d, " ");
		strcat(alias_tbl[i].d, nfearg.argv[j]);
	}
		
	a_cnt++;
}

static void	ment_help()
{
int	i, fd, jsw;
char	buf[512], hfile[128];

	if(nfearg.argc == 0) {
		for(i=0; ment_act[i].commstr!=(char *)0; i++) {
			printf("%-16s", ment_act[i].commstr);
			if(((i + 1) % 4) == 0) printf("\n");
		}
		if((i % 4) != 0) printf("\n");
		return;
	}
	jsw = 0;
	for(i=1; i<=nfearg.argc; i++) {
		if(nfearg.argv[i][0] == '-') {
			if(!strcmp(nfearg.argv[i], "-j")) {
				jsw	= 1;
				break;
			}
			printf("Usage: help [-j] [ncl-command]\n");
			return;
		}
	}

	if(nfearg.argc >= 1) {
		if(jsw) {
			sprintf(hfile, "%s/etc/ncl-data/HELP.JP/%s", nfetbl.ozroot, nfearg.argv[nfearg.argc]);
		} else {
			sprintf(hfile, "%s/etc/ncl-data/HELP/%s", nfetbl.ozroot, nfearg.argv[nfearg.argc]);
		}
		if((fd = open(hfile, O_RDONLY)) < 0) {
			printf("help: No help entry for %s.\n", nfearg.argv[1]);
			return;
		}
		while(i = read(fd, buf, 512))
			write(0, buf, i);
		close(fd);
		return;
	}

	printf("Usage: help [command]\n");
}

static void	make_stdwn_event(EventData hp, int tm)
{
NfeMent	rp;

	hp->head.arch_id	= SPARC;
	hp->head.event_num	= NCL_MENT_COMMAND;
        hp->head.req_nclid	= nfetbl.myaddr;
	hp->head.req_uid	= getuid();
	rp	= (NfeMent)hp->data.data;
	rp->nfe_comm	= NFE_SHUTDOWN;
	rp->data.n_stdwn.tm	= tm;
	rp->data.n_stdwn.status	= STDWN_CHECK;
	rp->data.n_stdwn.ex_cnt	= 0;
}

void	check_stdwn_msg()
{
EventDataRec	hh;
int		tm, stm;

	time(&tm);
	if(((nfetbl.stdwn_sec + nfetbl.current_sec) - 30) > tm)
		return;
	if((nfetbl.stdwn_sec + nfetbl.current_sec) < tm) {
		stm	= 0;
	} else {
		if(nfetbl.flag30) {
			stm	= 30;
			nfetbl.flag30	= 0;
		} else
			return;
	}

	bzero((char *)&hh, sizeof(EventDataRec));
	make_stdwn_event(&hh, stm);
#ifndef	RELEASE
printf(" + Send Shutdown message to Nucleus(%s)\n", ipaddr2str(nfetbl.nfeaddr));
#endif
	if(write_nclevent(nfetbl.nfefd, (char *)&hh, SZ_EventData) == 0) {
		return;
	}
}

static void	ment_shutdown()
{
EventDataRec	hh;

	if(nfetbl.nfefd == 0) {
		printf("nclshutdown: Need to be connected first\n");
		return;
	}
	if(nfearg.argc != 1) {
		printf("Usage: nclshutdown time\n");
		return;
	}
	bzero((char *)&hh, sizeof(EventDataRec));
	if(nfearg.argv[1][0] == '+') {
		nfetbl.stdwn_sec	= atoi(&(nfearg.argv[1][1])) * 60;
		nfetbl.flag30		= 1;
		time(&nfetbl.current_sec);
		make_stdwn_event(&hh, nfetbl.stdwn_sec);
	} else if(!strcmp(nfearg.argv[1], "now")) {
		make_stdwn_event(&hh, 0);
	} else {
		printf("Usage: nclshutdown time\n");
		return;
	}
#ifndef	RELEASE
printf(" + Send Shutdown Request to Nucleus(%s)\n", ipaddr2str(nfetbl.nfeaddr));
#endif
	if(write_nclevent(nfetbl.nfefd, (char *)&hh, SZ_EventData) == 0) {
		return;
	}
}

static void	make_res_event(EventData hp)
{
NfeMent	rp;

	hp->head.arch_id	= SPARC;
	hp->head.event_num	= NCL_MENT_COMMAND;
        hp->head.req_nclid	= nfetbl.myaddr;
	hp->head.req_uid	= getuid();
	rp	= (NfeMent)hp->data.data;
	rp->nfe_comm	= NFE_EXSTATUS;
}

static void	 disp_exmng_block(EventData hp)
{
int		i, ex_cnt;
long		*lp;
MySTExBlock	cp;
static char	*st[] = { "Start ", "Active" };
struct tm	*tmp;
struct passwd	*pwp;

	lp	= (long *)hp->data.data;
	ex_cnt	= (int)*lp;
	if((nfetbl.optsw & OPT_CFLAG) == 0)
		printf("Executor Entry count(%d)\n", ex_cnt);
	if(ex_cnt == 0) return;

	if((nfetbl.optsw & OPT_CFLAG) == 0) {
		printf("  USER       PID        EXID        FD   STAT");
		printf("     BOOT TIME     RHOST\n");
	}
	for(i=0,cp=(MySTExBlock)(lp+1); i<ex_cnt; i++,cp++) {
		pwp	= getpwuid(cp->uid);
		printf("%-8s", pwp->pw_name);
		printf("  %6d", cp->pid);
		printf("  %08x%08x", (int)(cp->exid>>32), (int)(cp->exid&0xffffffff));
		printf("  %2d", cp->fd);
		printf("  %s", st[cp->status]);
		tmp	= localtime(&(cp->tm));
		printf("  %02d/%02d", tmp->tm_mon+1,tmp->tm_mday);
		printf(" %02d:%02d:%02d", tmp->tm_hour,tmp->tm_min,tmp->tm_sec);
		printf("  %s\n", ipaddr2str(cp->ipaddr));
	}
}

static void     ment_es()
{
EventDataRec	hh;

	if(nfetbl.nfefd == 0) {
		printf("ment_es: Need to be connected first\n");
		if(nfetbl.optsw & OPT_CFLAG)
			exit(1);
		return;
	}
	bzero((char *)&hh, sizeof(EventDataRec));
	make_res_event(&hh);
	if(send_request(&hh, "Executor Status Request"))
		return;

        disp_exmng_block(&hh);
}

static void	make_crex_event(EventData hp, int exid)
{
	hp->head.arch_id		= SPARC;
	hp->head.event_num		= NCL_NN_CREAT_EXECUTOR;
        hp->head.req_nclid		= nfetbl.myaddr;
	hp->head.req_uid		= getuid();
	hp->data.cr_exec.request_id	= getpid();
	SET_EX(hp->data.cr_exec.inst_exid, exid);
	hp->data.cr_exec.creat_nclid	= nfetbl.nfeaddr;

	strcpy(&(hp->data.data[400]), tmpbuf);
	sprintf(&(hp->data.data[800]), "OZROOT=%s", nfetbl.ozroot);
	if(getenv("DISPLAY")==(char *)NULL || !strcmp(":0.0", getenv("DISPLAY"))) {
		sprintf(&(hp->data.data[700]), "DISPLAY=%s:0", ipaddr2str(nfetbl.myaddr));
	} else {
		sprintf(&(hp->data.data[700]), "DISPLAY=%s", getenv("DISPLAY"));
	}
}

static int	check_exidform(char *exid)
{
char	*p;

	if(strlen(exid) != 6)
		return(1);
	for(p=exid; *p!=0x00; p++)
		if(isxdigit(*p) == 0)
			return(1);
	return(0);
}

static int	check_exidstat(char *eid)
{
struct stat	st;
char		efile[512];

	sprintf(efile, "%s/%s", nfetbl.exidi, eid);
	if(stat(efile, &st))
		return(0);
	if(st.st_uid == getuid())
		return(1);
	if((st.st_mode & (S_IWOTH|S_IROTH)) == (S_IWOTH|S_IROTH))
		return(1);
	return(0);
}

static int	gt_exidinfo(char *exid, char *ename, char *ecomm)
{
char	eifile[512];
FILE	*fp;

	sprintf(eifile, "%s/%s/exid.info", nfetbl.exidi, exid);
	if((fp = fopen(eifile, "r")) == (FILE *)NULL)
		return(0);
	fgets(ename, 128, fp);
	if(ename[strlen(ename)-1] == '\n') ename[strlen(ename)-1] = 0x00;
	fgets(ecomm, 128, fp);
	if(ecomm[strlen(ecomm)-1] == '\n') ecomm[strlen(ecomm)-1] = 0x00;
	fclose(fp);
	return(1);
}

static int	check_regexid(char *eid)
{
DIR		*dirp;
struct dirent	*dp;
char		ename[128], ecomm[128];

	if((dirp = opendir(nfetbl.exidi)) == NULL) {
		printf("check_regexid: Can't open directory(%s)\n", nfetbl.exidi);
		return(0);
	}
	for (dp=readdir(dirp); dp != NULL; dp = readdir(dirp)) {
		if(check_exidform(dp->d_name))
			continue;
		if(strcmp(eid, dp->d_name))
			continue;
		if(gt_exidinfo(eid, ename, ecomm) == 0) {
			printf("check_regexid: Executor-ID(%s) is removed now\n", eid);
			closedir(dirp);
			return(0);
		}
		if(check_exidstat(eid) == 0) {
			printf("check_regexid: Permission denied Executor-ID(%s)\n", eid);
			closedir(dirp);
			return(0);
		}
		closedir(dirp);
		return(strhtoi(eid));
	}
	closedir(dirp);
	printf("check_regexid: Executor-ID(%s) is not registered among the executor information\n", eid);
	return(0);
}

static int	ename2exid(char *en)
{
DIR		*dirp;
struct dirent	*dp;
char		ename[128], ecomm[128];

	if((dirp = opendir(nfetbl.exidi)) == NULL) {
		printf("nfe: Can\'t open directory(%s)\n", nfetbl.exidi);
		return(0);
	}
	for (dp=readdir(dirp); dp != NULL; dp = readdir(dirp)) {
		if(check_exidform(dp->d_name))
			continue;
		if(gt_exidinfo(dp->d_name, ename, ecomm) == 0)
			continue;
		if(strcmp(en, ename))
			continue;
		if(check_exidstat(dp->d_name) == 0) {
			printf("ename2exid: Permission denied Executor-ID(%s)\n", dp->d_name);
			return(0);
		}
		closedir(dirp);
		return(strhtoi(dp->d_name));
	}
	closedir(dirp);
	printf("ename2exid: Executor-Name(%s) is not registered among the executor information\n", en);
	return(0);
}

static int	ana_cex_option()
{
int	exid;
char	efile[10];

/*
	if(nfearg.argc != 1) {
		printf("Usage: cex <Executor-ID or Executor-Name>\n");
		return(0);
	}
*/
	if(nfearg.argv[1][0] != '$') {
		if((exid = strhtoi(nfearg.argv[1])) == (-1)) {
			printf("cex: Argument(%s) miss match\n", nfearg.argv[1]);
			return(0);
		}
		sprintf(efile, "%06x", exid);
		if(check_regexid(efile) == 0) {
			return(0);
		}
		return(exid);
	}
	if((exid = ename2exid(&(nfearg.argv[1][1]))) == 0) {
		return(0);
	}
	if(exid == (-1) || exid == 0) {
		printf("cex: argument(%s) miss match\n", nfearg.argv[1]);
		return(0);
	}
	return(exid);
}

static void	ment_createx()
{
int		exid, i;
long long	e;
EventDataRec	hh;
char		buf[64];

	if(nfetbl.nfefd == 0) {
		printf("cex: Need to be connected first\n");
		if(nfetbl.optsw & OPT_CFLAG)
			exit(1);
		return;
	}
	if((exid = ana_cex_option()) == 0)
		return;

	bzero((char *)&hh, sizeof(EventDataRec));
	make_crex_event(&hh, exid);
	if(send_request(&hh, "Create Executor Request"))
		return;
	if(hh.data.cr_exec.status) {
		printf("cex: Error => %s\n", (char *)&(hh.data.data[800]));
        } else {
		e	= hh.data.cr_exec.inst_exid;
printf(" + Successful in Create executor(0x%08x%08x) on %s\n", (int)(e>>32), (int)(e&0xffffffff), ipaddr2str(hh.data.cr_exec.creat_nclid));
	}
}

static void	make_ncltbl_event(EventData hp)
{
NfeMent	rp;

	hp->head.arch_id	= SPARC;
	hp->head.event_num	= NCL_MENT_COMMAND;
        hp->head.req_nclid	= nfetbl.myaddr;
	hp->head.req_uid	= getuid();
	rp	= (NfeMent)hp->data.data;
	rp->nfe_comm	= NFE_NCLTABLE;
}

void	disp_ncl_table(EventData hp)
{
int		i, j;
long		addr;
NclHostent	nhp;
NclTable	np;

	np	= (NclTable)hp->data.data;
	if(np->exid_manage.addr) {
		printf("EXID MANAGEMENT:(%s)\n", ipaddr2str(np->exid_manage.addr));
	}
	for(i=0,j=0; j<np->h_router_cnt; i++) {
        	nhp	= &(np->h_router_tbl[i]);
        	if(nhp->addr == (long)0)
			continue;
		j++;
		printf("HALF ROUTER:(%s)", ipaddr2str(nhp->addr));
		printf("%s", (nhp->fd)?" => Connected\n": "\n");
	}
}

static void     ment_ncltbl()
{
EventDataRec	hh;

	if(nfetbl.nfefd == 0) {
		printf("ment_ncltbl: Need to be connected first\n");
		return;
	}
	bzero((char *)&hh, sizeof(EventDataRec));
	make_ncltbl_event(&hh);
	if(send_request(&hh, "NCL-table Request"))
		return;

        disp_ncl_table(&hh);
}

static void	make_ret_event(EventData hp)
{
NfeMent	rp;

	hp->head.arch_id	= SPARC;
	hp->head.event_num	= NCL_MENT_COMMAND;
        hp->head.req_nclid	= nfetbl.myaddr;
	hp->head.req_uid	= getuid();
	rp	= (NfeMent)hp->data.data;
	rp->nfe_comm	= NFE_EXTABLE;
}

static int	disp_extable(EventData hp, int sw)
{
char		buf[32];
ExecTable	etp;
char		*locstr[] = { "LOCAL", "INSITE", "OUTSITE" };
int		i;
NfeMent		rp;

	rp	= (NfeMent)hp->data.data;
	if((nfetbl.optsw & OPT_CFLAG) == 0 && !sw)
		printf("Executor Table Entry count(%d)\n", rp->data.ex_tbl.entry_cnt_total);
	if(rp->data.ex_tbl.entry_cnt_total == 0) return(0);

	if((nfetbl.optsw & OPT_CFLAG) == 0 && !sw)
		printf("EXID                  NET-ADDR                LOCATION\n");
	etp	= (ExecTable)(rp->data.ex_tbl.data);
	for(i=0; i<rp->data.ex_tbl.entry_cnt; i++,etp++) {
		printf("%08x%08x", (int)(etp->exid>>32), (int)(etp->exid&0xffffffff));
		sprintf(buf, "%s:%d", inet_ntoa(etp->addr.sin_addr), etp->addr.sin_port);
		printf("    %-22s", buf);
		printf("    %s\n", locstr[etp->location]);
	}
	return(rp->data.ex_tbl.ref_cnt);
}

static void	ment_et()
{
EventDataRec	hh;
int		i;

	if(nfetbl.nfefd == 0) {
		printf("et: Need to be connected first\n");
		if(nfetbl.optsw & OPT_CFLAG)
			exit(1);
		return;
	}
	bzero((char *)&hh, sizeof(EventDataRec));
	make_ret_event(&hh);
#ifndef	RELEASE
printf(" + Send Executor-table Request to Nucleus(%s)\n", ipaddr2str(nfetbl.nfeaddr));
#endif
	if(write_nclevent(nfetbl.nfefd, (char *)&hh, SZ_EventData) == 0) {
		return;
	}
#ifndef	RELEASE
printf(" + Waiting for Nucleus(%s) responce\n", ipaddr2str(nfetbl.nfeaddr));
#endif
	while(1) {
	        if(wait_responce(&hh)) {
			printf(" + Disconnect from Nucleus(%s)\n", ipaddr2str(nfetbl.nfeaddr));
			close(nfetbl.nfefd);
			nfetbl.nfefd	= 0;
			return;
		}

		if(disp_extable(&hh, i++) == 0)
			return;
	}
}

static void	ment_quit()
{
	close(nfetbl.nfefd);
	fflush(stdout);
	exit(0);
}

static void	disp_nclman()
{
int	i, fd, jsw;
char	buf[512], hfile[128];

	jsw	= 0;
	for(i=1; i<=nfearg.argc; i++) {
		if(nfearg.argv[i][0] == '-') {
			if(!strcmp(nfearg.argv[i], "-j")) {
				jsw	= 1;
				break;
			}
			printf("Usage: man [-j]\n");
			return;
		}
	}
	if(jsw) {
		sprintf(hfile, "%s/etc/ncl-data/HELP.JP/ncl", nfetbl.ozroot);
	} else {
		sprintf(hfile, "%s/etc/ncl-data/HELP/ncl", nfetbl.ozroot);
	}
	if((fd = open(hfile, O_RDONLY)) < 0) {
		printf("man: No manual\n");
		return;
	}
	while(i = read(fd, buf, 512))
		write(0, buf, i);
}

static void	disp_nclenv()
{
char	*p;

	printf("  OZROOT  = %s\n", nfetbl.ozroot);
	if(getenv("DISPLAY") == (char *)NULL)
		printf("  DISPLAY = (null)\n");
	else
		printf("  DISPLAY = %s\n", getenv("DISPLAY"));

	printf("  *Executor command: %s/bin/%s\n", nfetbl.ozroot, EX_COMMAND);
#ifndef	RELEASE
	printf("  *Directory path for Executor-ID management: %s/etc/ncl-data/EXID\n", nfetbl.ozroot);
#endif
	printf("  *Directory path for NCL help command: %s/etc/ncl-data/HELP\n", nfetbl.ozroot);
}

static void	conv_argsp(char *dt)
{
char	buf[MAX_COMMANDL], *p;

	for(p=dt; *p!=0x00; p++) {
		if(*p == ' ' || *p == '\t') {
			sprintf(buf, "\"%s\"", dt);
			strcpy(dt, buf);
			break;
		}
	}
}

static int	set_nfeargs(char *dp)
{
int	i, sw, csw;
char	*p, c;

	bzero((char *)&nfearg, sizeof(NclArg));
	for(i=0,sw=0,csw=0,p=dp; *p!=0x00; p++) {
		if(*p == '\"') {
			if(csw) {
				c = *(p + 1);
				csw = 0; 
			} else {
				if(i == 0) csw = 1;
			}
			continue;
		}
		if(!csw && (*p == ' ' || *p == '\t')) {
			if(i == 0)  continue;
			i = 0;
			sw = 1;
			continue;
		}
		if(sw) {
			conv_argsp(nfearg.argv[nfearg.argc]);
			nfearg.argc++;
			sw = 0;
		}
		nfearg.argv[nfearg.argc][i++] = *p;
	}
	if(csw) return(-1);
	if(nfearg.argc == 0 && nfearg.argv[0][0] == 0x00)
		return(-1);

	return(0);
}

static void	make_rwho_event(EventData hp)
{
NfeMent	rp;

	hp->head.arch_id	= SPARC;
	hp->head.event_num	= NCL_MENT_COMMAND;
        hp->head.req_nclid	= nfetbl.myaddr;
	hp->head.req_uid	= getuid();
	rp	= (NfeMent)hp->data.data;
	rp->nfe_comm	= NFE_RWHO;
}

static void	 disp_rwho(EventData hp)
{
int		i, w_cnt;
long		*lp;
RequestTbl	cp;
struct tm	*tmp;
struct passwd	*pwp;

	lp	= (long *)hp->data.data;
	w_cnt	= (int)*lp;
	printf("Who Entry count(%d)\n", w_cnt);
	if(w_cnt == 0) return;

	printf("  USER    FD   CONNECT-TIME   RHOST\n");
	for(i=0,cp=(RequestTbl)(lp+1); i<w_cnt; i++,cp++) {
		if((cp->con & NFE_CONNECTED) == 0)
			continue;
		pwp	= getpwuid(cp->uid);
		printf("%-8s", pwp->pw_name);
		printf("  %2d", cp->fd);
		tmp	= localtime(&(cp->tm));
		printf("  %02d/%02d", tmp->tm_mon+1,tmp->tm_mday);
		printf(" %02d:%02d:%02d", tmp->tm_hour,tmp->tm_min,tmp->tm_sec);
		printf("  %s\n", ipaddr2str(cp->ip));
	}
}

static void     ment_rwho()
{
EventDataRec	hh;

	if(nfetbl.nfefd == 0) {
		printf("who: Need to be connected first\n");
		return;
	}
	bzero((char *)&hh, sizeof(EventDataRec));
	make_rwho_event(&hh);
	if(send_request(&hh, "RWHO Request"))
		return;

        disp_rwho(&hh);
}

static void	make_killex_event(EventData hp, int sig, int exid)
{
NfeMent	rp;

	hp->head.arch_id	= SPARC;
	hp->head.event_num	= NCL_MENT_COMMAND;
        hp->head.req_nclid	= nfetbl.myaddr;
	hp->head.req_uid	= getuid();
	rp	= (NfeMent)hp->data.data;
	rp->nfe_comm	= NFE_KILLTOEX;

	rp->data.ex_kill.exid	= exid;
	rp->data.ex_kill.signum	= sig;
}

static void	ment_killex()
{
EventDataRec	hh;
int		sig, exid;
NfeMent		rp;
SignalTable	spp;

	if(nfearg.argc != 2) {
		printf("Usage: killex -signal ExecutorId\n");
		return;
	}
	if(nfetbl.nfefd == 0) {
		printf("et: Need to be connected first\n");
		if(nfetbl.optsw & OPT_CFLAG)
			exit(1);
		return;
	}
	if(nfearg.argv[1][0] != '-') {
		printf("Usage: killex -signal ExecutorId\n");
		return;
	}
	if(isalpha(nfearg.argv[1][1])) {
		sig	= 0;
		for(spp=sigtbl; spp->signame!=(char *)0; spp++)
			if(!strcmp(spp->signame, &nfearg.argv[1][1])) {
				sig	= spp->signum;
				break;
			}
		if(!sig) {
			printf("killex: Illegal option %s\n", nfearg.argv[1]);
			return;
		}
	} else {
		sig	= atoi(&nfearg.argv[1][1]);
	}
	exid	= strhtoi(nfearg.argv[2]);
	bzero((char *)&hh, sizeof(EventDataRec));
	make_killex_event(&hh, sig, exid);
	if(send_request(&hh, "KillEx Request"))
		return;
	rp	= (NfeMent)hh.data.data;
	if(rp->data.ex_kill.status) {
		printf("killex: %s\n", &(hh.data.data[800]));
		if(nfetbl.optsw & OPT_CFLAG)
			exit(1);
		return;
	}
if((nfetbl.optsw & OPT_CFLAG) == 0)
printf(" + Successful in Send the signal to the Executor(0x%06x)\n", exid);
}

static void	init_nclrc()
{
int		fd;

	nfearg.argc = 1;
	sprintf(nfearg.argv[1], "%s/%s", (char *)getenv("HOME"), DEFAULT_NCLRC);
	if((fd = open(nfearg.argv[1], O_RDONLY)) < 0)
		return;
	close(fd);

	ment_interpreter();
}

static void	make_connect_event(EventData hp)
{
NfeMent	rp;

	hp->head.arch_id	= SPARC;
	hp->head.event_num	= NCL_MENT_COMMAND;
        hp->head.req_nclid	= nfetbl.myaddr;
	hp->head.req_uid	= getuid();
	rp	= (NfeMent)hp->data.data;
	rp->nfe_comm		= NFE_CONNECT;
}

static void	init_nfeopt(int argc, char *argv[])
{
char		buf[64];
long		saddr;
NfeMent		rp;
EventDataRec	hh;
int		i;

	if(gethostname(buf, 64) == (-1)) {
		perror("gethostname: ");
		fprintf(stderr, "init_nfeopt: gethostname failed\n");
		exit(1);
	}
	if((nfetbl.myaddr = hostn2addr(buf)) == (-1)) {
		fprintf(stderr, "%s: unknown host %s\n", argv[0], buf);
		exit(1);
	}
	for(i=1; i<argc; i++) {
		if(!strcmp(argv[i], "-c")) {
			if(argc == (i+1)) {
				fprintf(stderr, "%s: Illegal option(%s)\n", argv[0], argv[i]);
				exit(1);
			}
			strcpy(tmpbuf, argv[++i]);
			nfetbl.optsw	= OPT_CFLAG;
			continue;
		}
		if((saddr = hostn2addr(argv[i])) == (-1)) {
			fprintf(stderr, "%s: unknown host %s\n", argv[0], argv[i]);
			exit(1);
		}
		nfetbl.nfeaddr	= saddr;
	}
	if(nfetbl.nfeaddr == 0)
		nfetbl.nfeaddr	= nfetbl.myaddr;
	if(nfe_connect() == 0)
		exit(1);
	make_connect_event(&hh);
	if(write_nclevent(nfetbl.nfefd, (char *)&hh, SZ_EventData) == 0) {
		exit(1);
	}
}

static void	disp_stdwn_msg(EventData hp)
{
NfeMent	rp;
struct passwd	*pwp;
char		nclh[64], reqh[64], buf[64];

	pwp	= getpwuid(hp->head.req_uid);
	strcpy(nclh, ipaddr2str(nfetbl.nfeaddr));
	strcpy(reqh, ipaddr2str(hp->head.req_nclid));
	rp	= (NfeMent)hp->data.data;
	switch(rp->data.n_stdwn.status) {
		case STDWN_CHECK:
			rp->data.n_stdwn.status	= STDWN_MSG;
			printf(" + Executor is active on Nucleus(%s) yet\n", nclh);
			printf("\007 + Executor count(%d): May Nucleus(%s) really shutdown?(yes/no) ", rp->data.n_stdwn.ex_cnt, nclh);
			gets(buf);
			if(!strcmp(buf, "yes"))
				write_nclevent(nfetbl.nfefd, (char *)hp, SZ_EventData);
			return;
		case STDWN_MSG:
			printf("\007 + Nucleus(%s)", nclh);
			printf(" going down in %d Seconds\n", rp->data.n_stdwn.tm);
			printf("\n   *** FINAL Nucleus(%s)", nclh);
			if(pwp == (struct passwd *)NULL) {
				printf(" shutdown message from ????@%s ***\n\n", reqh);
			} else {
				printf(" shutdown message from %s@%s ***\n\n", pwp->pw_name, reqh);
			}
			return;
		case STDWN_START:
			printf(" + Nucleus(%s) going down in IMMEDIATELY\n", nclh);
			printf(" + Nucleus(%s) SHUTDOWN time has arrived\n", nclh);
			return;
		case STDWN_HNCLCLOSE:
			printf(" => %s %s Half-Router: connect going down\n", ntime(buf), nclh);
			return;
		case STDWN_EXKILL:
			printf(" => %s %s Executor: going down on signal SIGTERM\n", ntime(buf), nclh);
			return;
		case STDWN_DELEXTBL:
			printf(" => %s %s Executor-table: Shared memory removed\n", ntime(buf), nclh);
			return;
		case STDWN_FINISHED:
			printf(" + Nucleus(%s) was brought to an end by the shutdown now\n", nclh);
			close(nfetbl.nfefd);
			printf("\n");
			fflush(stdout);
			exit(0);
	}
}

static int	ment_commands(char *comm)
{
int		i, j, m;
MentCommands	mp;
NclArg		nfearg_sav;

	if(set_nfeargs(comm))
		return(1);

	for(i=0; i<a_cnt; i++) {	/* alias check	*/
		if(strcmp(nfearg.argv[0], alias_tbl[i].s))
			continue;
		memcpy((char *)&nfearg_sav, (char *)&nfearg, sizeof(NclArg));
		set_nfeargs(alias_tbl[i].d);
		for(j=nfearg.argc+1,m=1; m<=nfearg_sav.argc; j++,m++)
			strcpy(nfearg.argv[j], nfearg_sav.argv[m]);
		nfearg.argc += nfearg_sav.argc;
		break;
	}

	for(i=0; ment_act[i].commstr!=(char *)0; i++) {
		mp	= &ment_act[i];
		if(strcmp(nfearg.argv[0], mp->commstr))
			continue;
		(*(mp->func))();
		return(0);
	}
	printf("nfe: No command entry for %s.\n", nfearg.argv[0]);
	return(1);
}

static void	ment_interpreter()
{
FILE		*fp;
char		*p;
int		j;

	if(nfearg.argc != 1) {
		printf("Usage: source nfe-script-file\n");
		return;
	}
	if((fp = fopen(nfearg.argv[1], "r")) == (FILE *)NULL) {
		printf("source: Can\'t open file(%s)\n", nfearg.argv[1]);
		return;
	}

	while(fgets(tmpbuf, 104, fp) != (char *)NULL) {
		p = tmpbuf;
		if(*p == '#') continue;
		for(j=0; *p!='\n'; p++) {
			if(isalpha(*p)) j = 1;
		}
		if(j == 0) continue;
		*p = 0x00;
#ifndef	RELEASE
printf("ment_interpret: -> %s\n", tmpbuf);
#endif
		ment_commands(tmpbuf);
	}
	fclose(fp);
}

static void	ment_exidlist()
{
int		dw, aflg;
DIR		*dirp;
struct dirent	*dp;
char		ename[128], ecomm[128];

	if(nfearg.argc > 2) {
		printf("Usage: exidlist [-a]\n");
		return;
	}
	aflg	= 0;
	if(nfearg.argc == 1) {
		if(strcmp(nfearg.argv[1], "-a")) {
			printf("exidlist: Missing option %s\n", nfearg.argv[1]);
			return;
		}
		aflg	= 1;
	}
	if((dirp = opendir(nfetbl.exidi)) == NULL) {
		printf("exidlist: Can\'t open directory(%s)\n", nfetbl.exidi);
		return;
	}
	for (dw=0,dp=readdir(dirp); dp != NULL; dp = readdir(dirp)) {
		if(check_exidform(dp->d_name))
			continue;
		if(aflg == 0) {
			if(check_exidstat(dp->d_name) == 0) continue;
		}
		if(gt_exidinfo(dp->d_name, ename, ecomm) == 0) continue;
		if(!dw) {
			printf(" EXID     EX-NAME               COMMENT\n");
			dw	= 1;
		}
		printf("%s    %-20s  %s\n", dp->d_name, ename, ecomm);
	}
	closedir(dirp);
}

static void	make_gtnewexid_event(EventData hp)
{
NfeMent	rp;

	hp->head.arch_id	= SPARC;
	hp->head.event_num	= NCL_MENT_COMMAND;
	hp->head.req_nclid	= nfetbl.myaddr;
	hp->head.req_uid	= getuid();
	rp	= (NfeMent)hp->data.data;
	rp->nfe_comm		= NFE_GETNEWEXID;

	sprintf(&(hp->data.data[800]), "OZROOT=%s", getenv("OZROOT"));
}

static int	gt_new_exid(EventData  hp)
{
NfeMent		rp;
char	*errmsg[] = {
	"Successful get executor-ID",
	"Executor-ID Management Nucleus is not registered among the Nuclues-Table",
	"Executor-ID Managemnet Nucleus connect failed",
	"Exeuctor-ID Management Nucleus connection was down"
};

	bzero((char *)hp, SZ_EventData);
	make_gtnewexid_event(hp);
	if(send_request(hp, "Get New EXID Request"))
		return(0);

	rp	= (NfeMent)hp->data.data;
	if(rp->data.gtneid.status == 0)
		return((int)((rp->data.gtneid.exid>>24)&0xffffffLL));

	printf("Error: %s\n", errmsg[rp->data.gtneid.status]);
	return(0);
}

static void	create_exidinfo(int exid, char *ename, char *ecomm)
{
char	mentfile[256], exdata[512];
int	fd;

	sprintf(mentfile, "%s/%06x/exid.info", nfetbl.exidi, exid);
	if((fd = open(mentfile, O_CREAT|O_RDWR, 0777)) < 0) {
		perror("create_exidinfo: open:");
		printf("create_exidinfo: Can\'t create file %s\n", mentfile);
		return;
	}
	sprintf(exdata, "%s\n%s\n", ename, ecomm);
	write(fd, exdata, strlen(exdata));
	close(fd);
	return;
}

static int	ana_newimage_arg(char *ex, char *ni_args[], char *ename, char *ecomm)
{
int	i, j, dir_flg;

	dir_flg	= 0;
	for(i=1,j=1; i<=nfearg.argc; i++) {
#if	0
		if(nfearg.argv[i][0] == '-') {
			switch(nfearg.argv[i][1]) {
				case 'n':
					strcpy(ename, nfearg.argv[++i]);
					continue;
				case 'c':
					strcpy(ecomm, nfearg.argv[++i]);
					continue;
				case 'g':
				case 'p':
				case 'l':
					ni_args[j++]	= nfearg.argv[i];
					continue;
				case 'd':
				case 'u':
				case 'k':
					ni_args[j++]	= nfearg.argv[i];
					ni_args[j++]	= nfearg.argv[++i];
					continue;
				default:
					printf("newimage: Illegal option %s\n", nfearg.argv[i]);
					return(-1);
					
			}
		} else {
			ni_args[j++]	= ex;
			ni_args[j++]	= nfearg.argv[i];
			dir_flg	= 1;
		}
		continue;
#endif
		ni_args[j++]	= nfearg.argv[i];
	}
#if	0
	if(!dir_flg)
#endif
		ni_args[j++]	= ex;
	ni_args[j]	= (char *)0;
	return(j);
}

static void	ment_newimage()
{
EventDataRec	hh;
int		exid, upid, status, argn;
char		ename[128], ecomm[128], ex[10], n_comm[256];
char		*ni_args[MAX_NCLARGS] = { "newimage" };

	if((exid = gt_new_exid(&hh)) == 0)
		return;

	bzero(ename, 128);
	bzero(ecomm, 128);
	sprintf(ex, "%06x", exid);
	sprintf(n_comm, "%s/bin/newimage", nfetbl.ozroot);
	if((argn = ana_newimage_arg(ex, ni_args, ename, ecomm)) < 0)
		return;

	if((upid = fork()) == 0) {
		signal(SIGINT, SIG_DFL);
		execv(n_comm, ni_args);
		perror("execv: ");
		exit(1);
	}
	wait(&status);
	if(status) {
		printf("nfe: newimage was interrupted\n");
		return;
	}

#if	0
	printf("New Exid: 0x%06x\n", exid);
	create_exidinfo(exid, ename, ecomm);
#endif
}

static void	ment_migrateimage()
{
char	m_comm[256];
char	*ni_args[MAX_NCLARGS] = { "migrateimage" };
int	i, j, upid, status;

	sprintf(m_comm, "%s/bin/migrateimage", nfetbl.ozroot);
	for(i=1,j=1; i<=nfearg.argc; i++) {
		ni_args[j++]	= nfearg.argv[i];
	}
	if((upid = fork()) == 0) {
		signal(SIGINT, SIG_DFL);
		execv(m_comm, ni_args);
		perror("execv: ");
		exit(1);
	}
	wait(&status);
	if(status) {
		printf("nfe: migrateimage was interrupted\n");
		return;
	}
}

static void	ment_exidrm()
{
char	rfile[512], sfile[512], efile[10];
int	exid;

	if(nfearg.argc != 1) {
		printf("Usage: exidrm Executor-ID\n");
		return;
	}
	if((exid = strhtoi(nfearg.argv[1])) == (-1)) {
		printf("exidrm: Argument(%s) miss match\n", nfearg.argv[1]);
		return;
	}
	sprintf(efile, "%06x", exid);
	if(check_regexid(efile) == 0) {
		return;
	}
	sprintf(rfile, "%s/%06x/exid.info", nfetbl.exidi, exid);
	sprintf(sfile, "%s.del", rfile);
	link(rfile, sfile);
	unlink(rfile);
}

static void	ment_exidment()
{
int	i, exid;
char	ename[256], ecomm[256], efile[10];

	if(nfearg.argc == 0 || nfearg.argc == 2) {
		printf("Usage: exidment Executor-ID [-n new-name] [-c new-comment]\n");
		return;
	}
	if((exid = strhtoi(nfearg.argv[1])) == (-1)) {
		printf("Usage: exidment Executor-ID [-n new-name] [-c new-comment]\n");
		return;
	}
	sprintf(efile, "%06x", exid);
	if(check_regexid(efile) == 0) {
		return;
	}
	if(gt_exidinfo(efile, ename, ecomm) == 0) {
		printf("exidment: Can't open file %s/%06x/exid.info", nfetbl.exidi, exid);
		return;
	}
	for(i=2; i<=nfearg.argc; i++) {
		if(nfearg.argv[i][0] == '-') {
			if(!strcmp(nfearg.argv[i], "-n")) {
				strcpy(ename, nfearg.argv[++i]);
				continue;
			}
			if(!strcmp(nfearg.argv[i], "-c")) {
				strcpy(ecomm, nfearg.argv[++i]);
				continue;
			}
			printf("exidment: Missing option %s\n", nfearg.argv[i]);
			return;
		}
	}
	create_exidinfo(exid, ename, ecomm);
}

static void	ncl_ment_command(EventData hp)
{
NfeMent	rp;

	rp	= (NfeMent)&(hp->data);
	switch(rp->nfe_comm) {
		case NFE_SHUTDOWN:
			disp_stdwn_msg(hp);
			return;
		default:
			if(hp->head.event_num == NCL_NN_CREATED_EXID)
				return;
			printf("Illegal command 0x%x\n", rp->nfe_comm);
			return;
	}
}

static void	accept_event(char *com)
{
fd_set		rfds;
int		nfd, nb, len;
EventDataRec	hh;
struct timeval	tw, *twp;

	while(1) {
		if(nfetbl.stdwn_sec) {
			tw.tv_sec        = 2;
			tw.tv_usec       = 0;
			twp	= &tw;
			printf(">");
		} else {
			twp	= (struct timeval *)NULL;
			printf("%s> ", com);
		}
		fflush(stdout);

		FD_ZERO(&rfds);
		FD_SET(0, &rfds);
		if(nfetbl.nfefd)
			FD_SET(nfetbl.nfefd, &rfds);

		nfd = select(getdtablesize(), &rfds, NULL, NULL, twp);
		if(nfd < 0) {
			perror("accept_event: select: ");
			continue;
		}
		if(FD_ISSET(0, &rfds)) {
			bzero(tmpbuf, 256);
			if((nb = read(0, tmpbuf, 256)) == 0) {
				close(nfetbl.nfefd);
				printf("\n");
				fflush(stdout);
				exit(0);
			}
			len	= strlen(tmpbuf);
			tmpbuf[len - 1]	= 0x00;
			ment_commands(tmpbuf);
			continue;
		}
		if(FD_ISSET(nfetbl.nfefd, &rfds)) {
                        if(read(nfetbl.nfefd, (char *)&hh, SZ_EventData) <= 0) {
				printf(" + Disconnect from Nucleus(%s)\n", ipaddr2str(nfetbl.nfeaddr));
				close(nfetbl.nfefd);
				nfetbl.nfefd	= 0;
				continue;
                        }
			ncl_ment_command(&hh);
			continue;
		}
		if(nfetbl.stdwn_sec) {
			check_stdwn_msg();
			continue;
		}
printf("accept_event: Unknown event\n");
	}
}

main(int argc, char *argv[])
{
char		*p;

	if(argc > 4) {
		printf("Usage: %s [Hostname]\n", argv[0]);
		exit(0);
	}
	bzero((char *)&nfetbl, sizeof(NfeMangTblRec));
	if((p = (char *)getenv("OZROOT")) == (char *)NULL) {
		(void)printf("%s: Please set enveronment value OZROOT\n", argv[0]);
		exit(1);
	}
	strcpy(nfetbl.ozroot, p);
	sprintf(nfetbl.exidi, "%s/images", nfetbl.ozroot);

	init_nfeopt(argc, argv);
	if(nfetbl.optsw & OPT_CFLAG) {
		if(ment_commands(tmpbuf))
			exit(1);
		ment_quit();
	}
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
	printf("### OZ++ System Nucleus(Version 3.1) Front-End Started ###\n");
	init_nclrc();

	signal(SIGINT, SIG_IGN);

	accept_event(argv[0]);
}

