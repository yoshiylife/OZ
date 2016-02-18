/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include	<stdio.h>
#include	<sys/signal.h>
#include	<sys/types.h>
#include	<sys/time.h>
#include	<stropts.h>
#include	<pwd.h>

#include	"exec_table.h"
#include	"ncl_extable.h"
#include	"ncl_defs.h"
#include	"ex_ncl_event.h"
#include	"ncl_shell.h"

#define	SZ_EXTABLE	(sizeof(ExecTableRec)*EXEC_TABLE_SIZE)
#define	SZ_ETHASHTBL	sizeof(ETHashTableRec)

MySTExBlockRec	ex_mng_table[MAX_OF_STEX];

ExTableEntryRec		extentry = {
	(ExecTable)0, (ETHashTable)0, 0, (MySTExBlock)0
};

extern void	end_ncl(int st);
extern int	gt_shmid(key_t key, int size, int flg);
extern void	rm_shmmem(key_t key);
extern void	fr_requesttbl(int fd);
extern char	*alloc_shmmem(int size);
extern int	free_shmmem(char *addr);
extern char	*ipaddr2str(long addr);

void remove_executor_table()
{
	if(extentry.extbl && extentry.ethash) {
		free_shmmem((char *)(extentry.extbl));
		free_shmmem((char *)(extentry.ethash));
	}
}

void	init_executor_table()
{
int	i;

	rm_shmmem(START_SHMKEY);
	if(gt_shmid(START_SHMKEY, 0, 0) != (-1)) {
		(void)fprintf(stderr, "init_executor_table: Shared memory is used alreay ?\n");
		exit(1);
	}

	extentry.extbl	= (ExecTable)alloc_shmmem(SZ_EXTABLE);
	extentry.ethash	= (ETHashTable)alloc_shmmem(SZ_ETHASHTBL);

	bzero((char *)(extentry.extbl), SZ_EXTABLE);
	OzInitETHash(extentry.ethash);
	bzero((char *)ex_mng_table, sizeof(MySTExBlockRec) * MAX_OF_STEX);

	extentry.freep = ex_mng_table;
}

void gt_exmng_block(int pid, EventData hp, int exfd)
{
int		i;
MySTExBlock	cp;

	extentry.freep->uid	= hp->head.req_uid;
	extentry.freep->pid	= pid;
	extentry.freep->fd	= exfd;
	extentry.freep->exid	= hp->data.cr_exec.inst_exid;
	extentry.freep->status	= EX_START;
	time(&(extentry.freep->tm));
	extentry.freep->ipaddr	= hp->head.req_nclid;
	extentry.freep->req_fd	= hp->head.req_nclfd;
	extentry.ex_cnt++;
	for(i=0,cp=ex_mng_table; i<MAX_OF_STEX; i++,cp++) {
		if(cp->pid == 0) {
			extentry.freep = cp;
			break;
		}
	}
}

static void	rm_extmpfile(int pid, int exid)
{
char	buf[64];

	sprintf(buf, "/tmp/Dm%06x", exid);
#if	0
	if(unlink(buf)) {
		perror(buf);
	} else {
		printf("%s, ", buf);
	}
#else
	unlink(buf);
#endif

	sprintf(buf, "/tmp/Oz%06x", exid);
#if	0
	if(unlink(buf)) {
	} else {
		printf("%s", buf);
	}
#else
	unlink(buf);
#endif
#if	0
	printf(")\n");
#endif
}

static void	 clr_extable_entry(long long exid)
{
int		i;
ExecTable	etp;

	for(i=0,etp=extentry.extbl; i<EXEC_TABLE_SIZE; i++,etp++) {
		if(etp->exid == exid) {
			bzero((char *)etp, sizeof(ExecTableRec));
			break;
		}
	}
}

static void	send_crex_responce(MySTExBlock cp)
{
EventDataRec	hh;

	hh.head.arch_id			= SPARC;
	hh.head.event_num		= NCL_NN_CREAT_EXECUTOR;
	hh.head.req_nclid		= cp->ipaddr;
	hh.head.req_uid			= cp->uid;
	hh.data.cr_exec.request_id	= 0;
	hh.data.cr_exec.inst_exid	= cp->exid;
	hh.data.cr_exec.creat_nclid	= 0;
	hh.data.cr_exec.status		= ER_EX_FAILED;

	sprintf((char *)&(hh.data.data[800]), "Executor is aborted before Object Manager is started.");
	if(write(cp->req_fd, (char *)&hh, SZ_EventData) <= 0) {
		perror("send_crex_responce: write");
		return;
	}
#ifdef	DEBUG
printf(" + Send Error Message(CREAT_EXECUTOR) to Create Executor tool\n");
#endif
}

void	fr_exmng_block(int fd)
{
int		i;
MySTExBlock	cp;

	for(i=0,cp=ex_mng_table; i<MAX_OF_STEX; i++,cp++) {
		if(cp->pid == 0)
			continue;
		if(cp->fd == fd) {
			if(cp->status == EX_START && cp->req_fd)
				send_crex_responce(cp);
			cp->uid	= 0;
			rm_extmpfile(cp->pid, (int)((cp->exid>>24)&0xffffff));
			cp->pid	= 0;
			cp->fd	= 0;
			if(cp->status == EX_ACTIVE) {
				OzRemoveETHash(extentry.ethash, cp->exid);
				clr_extable_entry(cp->exid);
			}
			cp->exid	= 0LL;
			cp->status	= 0;
			cp->ipaddr	= 0;
			cp->req_fd	= 0;
			extentry.freep	= cp;
			extentry.ex_cnt--;
		}
	}
}

void	 ncl_exstatus(EventData hp)
{
int		i;
MySTExBlock	cp;
char		*p;

#ifdef	DEBUG
printf(" + Received Request Message(NCL_EXSTATUS) from NFE(%s)\n", ipaddr2str(hp->head.req_nclid));
#endif
	p	= (char *)hp->data.data;
	bcopy((char *)&(extentry.ex_cnt), p, sizeof(long));
	p += sizeof(long);

	for(i=0,cp=ex_mng_table; i<MAX_OF_STEX; i++,cp++) {
		if(cp->pid) {
			bcopy((char *)cp, p, sizeof(MySTExBlockRec));
			p += sizeof(MySTExBlockRec);
		}
	}
	if(write(hp->head.req_nclfd, (char *)hp, SZ_EventData) <= 0) {
		perror("ncl_exstatus: write");
		fr_requesttbl(hp->head.req_nclfd);
		return;
	}
#ifdef	DEBUG
printf(" + Send Responce Message(NCL_EXSTATUS) to NFE(%s)\n", ipaddr2str(hp->head.req_nclid));
#endif
}

void mySTEx_killall()
{
int		i;
MySTExBlock	cp;
long		*lp;

	if(extentry.ex_cnt == 0) return;
	for(i=0,cp=ex_mng_table; i<MAX_OF_STEX; i++,cp++) {
		if(cp->pid) {
			(void)printf("Send to kill signal to pid(%d)\n", cp->pid);
			kill(cp->pid, SIGTERM);
		}
	}
}

struct sockaddr_in	*ExidToAddr(long long exid)
{
int	n;

	if((n = OzSearchETHashNcl(extentry.ethash, exid)) == (-1)) {
		return((struct sockaddr_in *)0);
	}
	if((extentry.extbl + n)->location == ET_LOCAL)
		return(&((extentry.extbl + n)->addr));
	return((struct sockaddr_in *)0);
}

void	SetExCondition(long long exid, long st)
{
int		i;
MySTExBlock	cp;

	if(!extentry.ex_cnt)
		return;

	for(i=0,cp=ex_mng_table; i<MAX_OF_STEX; i++,cp++) {
		if(cp->pid == 0)
			continue;

		if(exid == cp->exid) {
			cp->status = st;
			return;
		}
	}
}

MySTExBlock	IsExidEntry(long long exid)
{
int		i;
MySTExBlock	cp;

	if(!extentry.ex_cnt)
		return(0);

	for(i=0,cp=ex_mng_table; i<MAX_OF_STEX; i++,cp++) {
		if(cp->pid == 0)
			continue;

		if(exid == cp->exid)
			return(cp);
	}
	return(0);
}

void	SetExFd(fd_set *rfds)
{
int		i;
MySTExBlock	cp;

	if(!extentry.ex_cnt)
		return;

	for(i=0,cp=ex_mng_table; i<MAX_OF_STEX; i++,cp++) {
		if(cp->pid == 0)
			continue;

		FD_SET(cp->fd, rfds);
	}
}

int	FdIsSetEX(fd_set *rfds)
{
int		i;
MySTExBlock	cp;

	if(!extentry.ex_cnt)
		return(0);

	for(i=0,cp=ex_mng_table; i<MAX_OF_STEX; i++,cp++) {
		if(cp->pid == 0)
			continue;

		if(FD_ISSET(cp->fd, rfds))
			return(cp->fd);
	}
	return(0);
}

long long	ExFdToExid(int exfd)
{
int		i;
MySTExBlock	cp;

	if(!extentry.ex_cnt)
		return(0);

	for(i=0,cp=ex_mng_table; i<MAX_OF_STEX; i++,cp++) {
		if(cp->pid == 0)
			continue;

		if(cp->fd == exfd)
			return(cp->exid);
	}
	return(0LL);
}

void	ExMulticast(char *datap, int size)
{
int			i;
MySTExBlock		cp;
struct sockaddr_in	*addr;

	for(i=0,cp=ex_mng_table; i<MAX_OF_STEX; i++,cp++) {
		if(cp->pid && cp->status == EX_ACTIVE)
			if(write(cp->fd, datap, size) < 0)
				perror("ExMulticast: write");
	}
}

void	purge_extable()
{
}

void	renewal_extable(long long exid, struct sockaddr_in *addr, int loc)
{
int		i;
ExecTable	etp;

#ifdef	DEBUG
printf("renewal_extable: exid(0x%08x%08x), Location(%d)\n", (int)(exid>>32), (int)(exid&0xffffffff), loc);
#endif

	extentry.ethash->lock++;
	if((i = OzSearchETHashNcl(extentry.ethash, exid)) >= 0) {
		OzRemoveETHash(extentry.ethash, exid);
		extentry.extbl[i].exid = exid;
		ADDR_CPY(&(extentry.extbl[i].addr),addr);
		extentry.extbl[i].location = loc;
	} else {
		for(i=0,etp=extentry.extbl; i<EXEC_TABLE_SIZE; i++,etp++) {
			if(etp->exid == 0LL)
				break;
		}
		etp->exid	= exid;
		ADDR_CPY(&(etp->addr), addr);
		etp->location	= loc;
	}
	if(OzEnterETHash(extentry.ethash, exid, i) == 0) {
		purge_extable();
		OzEnterETHash(extentry.ethash, exid, i);
	}
	extentry.ethash->lock++;
}

void	ncl_extable(EventData hp)
{
int		ref_cnt, n, m;
ExecTable	etp;
char		*p;
NfeMent		rp;

#ifdef	DEBUG
printf(" + Received Request Message(NCL_EXTABLE) from NFE(%s)\n", ipaddr2str(hp->head.req_nclid));
#endif
	n	= (sizeof(hp->data.data)-sizeof(NfeExTableRec)) / sizeof(ExecTableRec);
	ref_cnt	= extentry.ethash->count / n;

	rp	= (NfeMent)hp->data.data;
	rp->data.ex_tbl.entry_cnt_total	= extentry.ethash->count;
	for(etp=extentry.extbl; ref_cnt>=0; ref_cnt--) {
		m	= ((!ref_cnt)? (extentry.ethash->count % n): n);
		rp->data.ex_tbl.ref_cnt		= ref_cnt;
		rp->data.ex_tbl.entry_cnt	= m;
		for(p=(char *)(rp->data.ex_tbl.data); m; etp++) {
			if(etp->exid == 0LL)
				continue;
			bcopy((char *)etp, p, sizeof(ExecTableRec));
			p += sizeof(ExecTableRec);
			m--;
		}
		if(write(hp->head.req_nclfd, (char *)hp, SZ_EventData) <= 0) {
			perror("ncl_extable: write");
			fr_requesttbl(hp->head.req_nclfd);
			return;
		}
	}
#ifdef	DEBUG
printf(" + Send Responce Message(NCL_EXTABLE) to NFE(%s)\n", ipaddr2str(hp->head.req_nclid));
#endif
}

