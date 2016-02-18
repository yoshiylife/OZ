/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _APGW_SITETBL_H_
#define _APGW_SITETBL_H_

#define	SITE_TABLE_NUM	1024

#define	LOCAL_SITE	0x0001
#define	REMOTE_SITE	0x0002


#define	STYPE_UNKNOWN	  0x0000
#define	OPEN_SITE	  0x0001
#define	CLOSE_SITE	  0x0002
#define PROGRESSIVE_SITE  0x0010
#define CONSERVATIVE_SITE 0x0020
#define INHIBITED_SITE    0x0030

typedef struct	{
	ushort	siteid;		/* SiteID 				*/
	ushort	stype;		/* Type of site (PROGRESSIVE/CONSERVATIVE/INHIBITED)*/
	ushort	loc;		/* Location of site (REMOTE/LOCAL)*/
	long	apgwaddr;	/* IP-address of APGW			*/
	long	rnclid;		/* Relay NucleusID of local site	*/
	ushort	rncl_port;	/* Port of Relay Nucleus of local site	*/
} SiteTableRec, *SiteTable;

#define	SZ_SITETBL	sizeof(SiteTableRec)

#endif _APGW_SITETBL_H_
