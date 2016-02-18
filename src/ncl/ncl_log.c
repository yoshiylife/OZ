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

char	ncl_logfile[256];

extern NclEnvRec	envofncl;
extern NclTableRec	ncl_table;
extern int		errno;

extern void	end_ncl(int st);
extern char	*ntime(char *dp);

void	init_ncl_log()
{
char	buf[256], buf1[64], hostn[64];
int	fd;

	gethostname(hostn, 64);
	sprintf(ncl_logfile, "%s/etc/ncl-data/log/%s", envofncl.ozroot, hostn);
	unlink(ncl_logfile);
	if((fd = open(ncl_logfile, O_CREAT|O_RDWR, 0666)) < 0) {
		perror("init_ncl_log: open:");
		printf("init_ncl_log: %s create failed\n", ncl_logfile);
		end_ncl(1);
	}
	sprintf(buf, "%s: Nucleus(%s) log started.\n", ntime(buf1), hostn);
	if(write(fd, buf, strlen(buf)) == (-1)) {
		perror("init_ncl_log: write: ");
	}
	close(fd);
}

int	rg_ncllog(char *msg, int sw)
{
int	fd;
char	buf[256], buf1[64];

	if((fd = open(ncl_logfile, O_APPEND|O_WRONLY)) < 0) {
		perror("rg_logwrite: ");
		printf("rg_logwrite: Can't open LOG file(%s)\n", ncl_logfile);
		return(0);
	}

	sprintf(buf, "%s: %s\n", sw?ntime(buf1):"                 ", msg);
	if(write(fd, buf, strlen(buf)) == (-1)) {
		perror("rg_logwrite: write: ");
		close(fd);
		return(1);
	}
	close(fd);
	return(0);
}

