/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <stdio.h>
#include <string.h>

#include "ncl_defs.h"
#include "ncl_table.h"
#include "ncl.h"
#include "ex_ncl_event.h"

NclTableRec	ncl_table;

extern NclEnvRec	envofncl;

char	*ipaddr2str(long addr)
{
struct hostent	*hep;
unsigned long	l;

	hep 	= gethostbyaddr((char *)&(addr), sizeof(long), AF_INET);
	if((int)hep) {
		strcpy(ncl_table.buf, hep->h_name);
	} else {
		l = addr;
		sprintf(ncl_table.buf, "%d.%d.%d.%d", l>>24,(l>>16)&0xff,(l>>8)&0xff, l&0xff);
	}
	return(ncl_table.buf);
}

void	fr_halfroutertbl(int fd)
{
int	i, j;

	for(i=0,j=0; j<ncl_table.h_router_cnt; i++) {
        	if(ncl_table.h_router_tbl[i].addr == (long)0) 
			continue;
		j++;
		if(fd == (-1)) {
			if(ncl_table.h_router_tbl[i].fd) {
				if(close(ncl_table.h_router_tbl[i].fd) == (-1))
					perror("fr_halfroutertbl: close");
			}
			continue;
		}
		if(ncl_table.h_router_tbl[i].fd != fd)
			continue;
		if(close(ncl_table.h_router_tbl[i].fd) == (-1))
			perror("fr_halfroutertbl: close");
		bzero((char *)&(ncl_table.h_router_tbl[i]), sizeof(NclHostentRec));
		return;
	}
}

int	FdIsSetHalfRouter(fd_set *rfds, long *addr)
{
int	i, j;

	for(i=0,j=0; j<ncl_table.h_router_cnt; i++) {
        	if(ncl_table.h_router_tbl[i].addr == (long)0) 
			continue;
		j++;
		if(ncl_table.h_router_tbl[i].fd == 0)
			continue;
		if(FD_ISSET(ncl_table.h_router_tbl[i].fd, rfds)) {
        		*addr	= ncl_table.h_router_tbl[i].addr;
			return(ncl_table.h_router_tbl[i].fd);
		}
	}
	return(0);
}

void     SetHalfRouterFd(fd_set *rfds)
{
int	i, j;

	for(i=0,j=0; j<ncl_table.h_router_cnt; i++) {
        	if(ncl_table.h_router_tbl[i].addr == (long)0) 
			continue;
		j++;
		if(ncl_table.h_router_tbl[i].fd == 0)
			continue;
		FD_SET(ncl_table.h_router_tbl[i].fd, rfds);
	}
}

void     SetHalfRouterTbl(int fd, long addr)
{
int	i, j;

	for(i=0,j=0; j<ncl_table.h_router_cnt; i++) {
        	if(ncl_table.h_router_tbl[i].addr != addr) 
			continue;
		j++;
		if(ncl_table.h_router_tbl[i].fd == 0) {
			ncl_table.h_router_tbl[i].fd = fd;
#ifdef  DEBUG
printf("   = Connected from Half Router NCL(%s)\n", ipaddr2str(addr));
#endif
			return;
		}
#ifdef	DEBUG
printf("SetHalfRouterTbl: Half Router Multi connection?\n"); 
#endif
	}
}

static	long	hostn2addr(char *hostn)
{
struct hostent	*hp;
long		addr;

	addr = inet_addr(hostn);
	if (addr == (-1)) {
		if (!(hp = gethostbyname(hostn))) {
			fprintf(stderr, "hostn2addr: unknown host(%s) in NCL_table\n", hostn);
			return(0);
		}
		bcopy(hp->h_addr, &addr, sizeof(long));
	}
	return(addr);
}

static int	get_hostaddr(char *ncl_t, char *hostn, char *apgwn)
{
char			*inet_ntoa();
long			addr;

	addr	= hostn2addr(hostn);
	if(!strcmp("HALFROUTER", ncl_t)) {
		if(envofncl.mynclid != addr)
			ncl_table.h_router_tbl[ncl_table.h_router_cnt++].addr = addr;
		if(envofncl.mynclid == addr)
			envofncl.typeofncl |= HALFROUTER;
	} else if(!strcmp("EXIDMANAGE", ncl_t)) {
		if(ncl_table.exid_manage.addr) {
			fprintf(stderr, "get_hostaddr: EXIDMANAGE Multi defined in Nucleus table\n");
			return(1);
		}
		ncl_table.exid_manage.addr = addr;
		if(envofncl.mynclid == addr)
			envofncl.typeofncl |= EXIDMANAGE;
	} else if(!strcmp("RELAYNCL", ncl_t)) {
		if(envofncl.mynclid != addr)
			return(0);
		if(envofncl.mynclid == addr)
			envofncl.typeofncl |= RELAYNCL;
		if((ncl_table.apgwid = hostn2addr(apgwn)) == 0)
			return(1);
		printf("APGW:(%s)\n", apgwn);
	} else {
		fprintf(stderr, "get_hostaddr: Illegal data in %s\n", NCL_TABLE_FILE);
		return(1);
	}
	return(0);
}

void	 ncl_ncltable(EventData hp)
{
#ifdef	DEBUG
printf(" + Received Request Message(NCL_NCLTABLE) from NFE(%s)\n", ipaddr2str(hp->head.req_nclid));
#endif
	bcopy((char *)&(ncl_table), (char *)hp->data.data, sizeof(NclTableRec));
	if(write(hp->head.req_nclfd, (char *)hp, SZ_EventData) <= 0) {
		perror("ncl_ncltable: write");
		fr_requesttbl(hp->head.req_nclfd);
		return;
	}
#ifdef	DEBUG
printf(" + Send Responce Message(NCL_NCLTABLE) to NFE(%s)\n", ipaddr2str(hp->head.req_nclid));
#endif
}

int	init_ncl_table()
{
FILE	*fp;
char	buf[MAX_LINESIZE], *cp, *cp1, *cp2;
char	ncltype[MAX_LINESIZE], hostn[MAX_LINESIZE], apgwn[MAX_LINESIZE];

char	*index();

	sprintf(buf, "%s/etc/ncl-data/%s", envofncl.ozroot, NCL_TABLE_FILE);
	if((fp = fopen(buf, "r")) == (FILE *)NULL) {
		fprintf(stderr, "Can't found NCL table file %s\n", NCL_TABLE_FILE);
		return(1);
	}

	bzero((char *)&ncl_table, sizeof(NclTableRec));
	while(fgets(buf, MAX_LINESIZE, fp) != (char *)NULL) {
		if(buf[0] == '#' || buf[0] == '\n')
			continue;
		if(cp = index(buf, '\n'))
			*cp	= 0x00;
		
		if((cp = index(buf, ':')) == (char *)NULL)
			continue;;
		*cp = 0x00;
		strcpy(ncltype, buf);
		if((cp1 = index(cp + 1, ':')) == (char *)NULL)
			continue;
		*cp1 = 0x00;
		strcpy(hostn, cp + 1);
		strcpy(apgwn, cp1 + 1);
		
		if(get_hostaddr(ncltype, hostn, apgwn)) {
			fclose(fp);
			return(1);
		}
		printf("%s: (%s)\n", ncltype, hostn);
	}
	fclose(fp);
	return(0);
}

