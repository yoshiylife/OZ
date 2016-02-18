/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#define EX_COMMAND      "executor"
#define	DEFAULT_NCLRC	".nclrc"

#define	HALFROUTER	0x00000001
#define	EXIDMANAGE	0x00000002
#define	RELAYNCL	0x00000004

#define	NCL_CONNECTED	0x00000001
#define	NCL_REQUEST	0x00000002
#define NFE_CONNECTED	0x00000004
#define	DEB_CONNECTED	0x00000008
#define	NMG_CONNECTED	0x00000010
#define	APGW_CONNECTED	0x00000100
#define	APGW_REQUEST	0x00000200

#ifdef  DEBUG
#define PROVISIONAL_PORT	3777
#define PROVISIONAL_UPORT	(3777 + envofncl.seg_num)
#endif

#define START_SHMKEY	1
#define MAX_OF_SHMTBL	10
#define MAX_OF_NCLBUF	1024
#define MAX_OF_HROUTER	64
#define MAX_OF_STEX	100
#define MAX_OF_REQTBL	100
#define	START_EXID_SITE	2048
#define	INC_EXID_ST	256
#define	SITEID_MASK	0x0000ffffL
#define	OSITEID_MASK	0xffff0000L

#define ER_MULTI_EXID	1
#define ER_SOCK_PAIR	2
#define ER_NFND_EXCOMM	3
#define ER_MODE_EXCOMM	4
#define ER_GETNEW_EXID	5
#define ER_EX_FAILED	6

/* NCL Macros	*/
#define	AM_I_HALFROUTER	(envofncl.typeofncl & HALFROUTER)
#define	AM_I_EXIDMANAGE	(envofncl.typeofncl & EXIDMANAGE)
#define	AM_I_RELAYNCL	(envofncl.typeofncl & RELAYNCL)

#define	SENDER_IS_MYSELF(v)	(v == envofncl.mynclid)

#define	ADDR_CLR(s1)		bzero((char *)&(s1), sizeof(struct sockaddr_in))
#define	ADDR_CPY(s1, s2)	bcopy((char *)s2, (char *)s1, sizeof(struct sockaddr_in))

#define	GET_SITEID(v)		(unsigned long)((v>>48)&0xffffLL)
#define	GET_EXID(v)		(long)((v>>24)&0xffffffLL)
#define	ISNOT_MYSITEID(v)	(GET_SITEID(v)!=envofncl.siteid)
#define	IS_REQ_OSITE(v)		(int)(v&OSITEID_MASK)
#define	SET_SITE(v, d1)		(v=((v&0xffffffffffffLL)|(long long)d1<<48))
#define	SET_EX(v, d1)		(v=((v&(0xffffLL<<48))|((long long)d1<<24)))
#define	INC_EX(v, d1)		(v+=((long long)d1<<24))
