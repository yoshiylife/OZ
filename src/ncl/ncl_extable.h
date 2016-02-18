/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

typedef	struct {
	long		uid;	/* Requester UNIX User ID		*/
	long		pid;	/* Executor UNIX Process ID		*/
	int		fd;	/* Executor Socket File Descriptor	*/
	long long	exid;	/* Executor ID				*/
	enum {
		EX_START, EX_ACTIVE
	} status;		/* Status of Executor			*/
	time_t		tm;	/* Executor Boot up Time		*/
	long		ipaddr;	/* Requester HOST IP Address		*/
	int		req_fd;	/* Requester Tool Socket Descriptor	*/
	long		reserve;/* Unused				*/
} MySTExBlockRec, *MySTExBlock;

typedef	struct	{
	ExecTable	extbl;	/* Executor Table Top Address		*/
	ETHashTable	ethash;	/* Executor Hash Table Top Address	*/
	int		ex_cnt;	/* Executor Count on Station		*/
	MySTExBlock	freep;	/* Free Executor Management Table addr	*/
} ExTableEntryRec;
