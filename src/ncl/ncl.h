/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

typedef	struct	{
	long			typeofncl;	/* Type of Nucleus	*/
	long			siteid;		/* Site of Nucleus	*/
	long			mynclid;	/* Own IP Address 	*/
	int			s;		/* TCP socket FD	*/
	int			bs;		/* UDP socket FD	*/
	int			ns;
	int			frd_pid;	/* File Receiver Daemon pid */
	int			fsd_pid;	/* File Sender Daemon pid   */
	struct sockaddr_in 	myaddr;
	struct sockaddr_in 	baddr;
	char			ozroot[128];
#ifdef	DEBUG
	long			seg_num;
#endif
} NclEnvRec, *NclEnv;

typedef struct	{
	int	fd;	/* Connect socket	*/
	long	con;	/* Condition flag	*/
	long	uid;	/* Connect User-ID	*/
	long	ip;	/* Connect IP-address	*/
	long	tm;	/* Connect time		*/
	long	pad;
} RequestTblRec, *RequestTbl;
