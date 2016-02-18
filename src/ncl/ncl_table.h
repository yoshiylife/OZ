/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#define NCL_TABLE_FILE	"NCL_table"
#define	MAX_LINESIZE	80

typedef	struct {
	long	addr;
	int	fd;
	int	delay_base;
	int	delay_cnt;
} NclHostentRec, *NclHostent;

typedef	struct ncl_table_rec	{
	NclHostentRec	exid_manage;
	NclHostentRec	h_router_tbl[MAX_OF_HROUTER];
	int		h_router_cnt;
	long		apgwid;
	char		buf[128];
} NclTableRec, *NclTable;

