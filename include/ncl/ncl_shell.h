/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#define	MAX_ALIAS	20
#define	MAX_NCLARGS	40
#define	MAX_COMMANDL	80

typedef struct {
	int	argc;
	char	argv[MAX_NCLARGS][MAX_COMMANDL];
} NclArg;

typedef struct {
	int	entry_cnt_total;
	int	ref_cnt;
	int	entry_cnt;
	long	data[1];
} NfeExTableRec, *NfeExTable;

typedef	struct	{
	long long	exid;
	long		status;
} NfeGtNewExidRec, *NfeGtNewExid;

typedef	struct	{
	long	exid;
	long	signum;
	long	status;
	long	filler;
} NfeTermExRec, *NfeTermEx;

typedef struct {
	int	tm;	/* Seconds	*/
	enum {
		STDWN_MSG, STDWN_START, STDWN_HNCLCLOSE, STDWN_EXKILL,
		STDWN_DELEXTBL, STDWN_FINISHED, STDWN_CHECK
	} status;
	int	ex_cnt;
} NfeShutdownRec, *NfeShutdown;

typedef struct {
	enum {
		FILLER, NFE_CONNECT, NFE_EXSTATUS, NFE_EXTABLE,
		NFE_NCLTABLE, NFE_SHUTDOWN, NFE_RWHO, NFE_GETNEWEXID,
		NFE_KILLTOEX
	} nfe_comm;
	union	{
		NfeExTableRec	ex_tbl;
		NfeShutdownRec	n_stdwn;
		NfeGtNewExidRec	gtneid;
		NfeTermExRec	ex_kill;
	} data;
	long	filler;
} NfeMentRec, *NfeMent;
