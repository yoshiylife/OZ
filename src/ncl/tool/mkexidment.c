/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <fcntl.h>
#include <pwd.h>

static char	exidi[512];

int	strhtoi(char *str)
{
int		n, i;
unsigned int	m, g;
char		*p;

char	hd[] = "0123456789abcdef";

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

static void	create_exidinfo(int exid, char *ename, char *ecomm)
{
char	mentfile[512], exdata[512];
int	fd;

	sprintf(mentfile, "%s/%06x/exid.info", exidi, exid);
	if((fd = open(mentfile, O_CREAT|O_RDWR, 0777)) < 0) {
		perror("create_exidinfo: open:");
		fprintf(stderr, "create_exidinfo: Can't create file %s\n", mentfile);
		return;
	}
	sprintf(exdata, "%s\n%s\n", ename, ecomm);
	write(fd, exdata, strlen(exdata));
	close(fd);
	return;
}

static void	init_exidmentdir(int eid)
{
char		*p;
struct stat     st;
char		buf[256];

	if((p = (char *)getenv("OZROOT")) == (char *)NULL) {
		fprintf(stderr, "init_exidmentdir: Shell instance value OZROOT is not defined\n");
		exit(1);
	}
	sprintf(exidi, "%s/images", p);
	sprintf(buf, "%s/%06x", exidi, eid);
	if(stat(buf, &st)) {
		fprintf(stderr, "mkexidment: Can't found Executor-ID(%s)\n", eid);
		exit(1);
	}
	if(st.st_uid == getuid())
		return;
	if((st.st_mode & (S_IWOTH|S_IROTH)) == (S_IWOTH|S_IROTH))
		return;
	fprintf(stderr, "mkexidment: Permission denied Executor-ID(%s)\n", eid);
	exit(1);
}

main(int argc, char *argv[])
{
int		i, exid;
char		ename[128], ecomm[128];

	if(argc == 1) {
		fprintf(stderr, "Usage: %s Executor-ID [-n executor-name] [-c comment]\n", argv[0]);
		exit(1);
	}
	if((exid = strhtoi(argv[1])) == (-1)) {
		fprintf(stderr, "Usage: %s Executor-ID [-n executor-name] [-c comment]\n", argv[0]);
		exit(1);
	}
	init_exidmentdir(exid);

	bzero(ename, 128);
	bzero(ecomm, 128);
	for(i=2; i<argc; i++) {
		if(argv[i][0] == '-') {
			if(!strcmp(argv[i], "-n")) {
				strcpy(ename, argv[++i]);
				continue; }
			if(!strcmp(argv[i], "-c")) {
				strcpy(ecomm, argv[++i]);
				continue;
			}
			printf("%s: Missing option %s\n", argv[0]);
			exit(1);
		}
	}
	create_exidinfo(exid, ename, ecomm);
	exit(0);
}

