/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

typedef struct {
	long	exid;
	long	rest_of_exid;
} ExidInfoSTRec, *ExidInfoST;

typedef struct {
	long		exid_of_site_now;
	long		filler;
	ExidInfoSTRec	active;
	ExidInfoSTRec	reserve;
} ExidMngInfoRec, *ExidMngInfo;

#define	SZ_ExidMngInfo	sizeof(ExidMngInfoRec)

#if	1
typedef struct {
	long long	start_exid;
	long		num_of_exid;
	long		filler;
} ExidInfoSTOldRec, *ExidInfoSTOld;

typedef struct {
	long long	start_exid_site;
	long		sw;
	long		filler;
	ExidInfoSTOldRec	exid_infoST[2];
} ExidMngInfoOldRec, *ExidMngInfoOld;

#define	SZ_ExidMngInfoOld	sizeof(ExidMngInfoOldRec)
#endif
