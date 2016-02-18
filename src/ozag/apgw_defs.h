/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _APGW_DEFS_H_
#define _APGW_DEFS_H_

#ifdef  DEBUG
#define PROVISIONAL_PORT	3777


#define	AA_BROADCAST		0
#define	EE_METH_CALL		1
#define	DELIV_CLASS		2
#endif

#define	V_EXID(v)	(int)((v>>32)&0xffffffffLL),(int)(v&0xffffffffLL)

#define ERROR_CODE -4

#define	MAX_OF_LSITE		256
#define	MAX_APGW_SITETBL	1000

#define	APGW_SITETABLE		"SITE_table"

#define IS_WHITESPACE(C) ((C==' ')||(C=='\t')||(C=='\n')||(C=='\r'))

#define SITETABLE_MASTER_HOST "www.etl.go.jp"
#define SITETABLE_MASTER_PORT 80
#define SITETABLE_MASTER_GET "GET /etl/bunsan/OZ/SiteList.txt HTTP/1.0"
#define CRLF "\r\n"
#define HTTP_NO_CACHE "Pragma: no-cache"
#define HTTP_IF_MODIFIED_SINCE "If-Modified-Since:"
#define HTTP_RESPONSE "HTTP/1.0"
#define HTTP_LAST_MODIFIED "Last-Modified:"


#define MAX_APGW_RECEIVE     15
#define MAX_APGW_SEND        15
#define TOO_FEW_FREE_RPORT    3

#define MESSAGE_BUFFER_SIZE         1024
#define MAX_MESSAGE_BUFFER_RESERVE  64

#define ADDRESS_TIMEOUT  5
#define ADDRESS_RETRY    5

#define EXID_MASK    0xffffffffff000000LL
#define INTEGER_MASK 0x00000000ffffffffLL

#define LARGE_UINT 0xffffffff
#endif _APGW_DEFS_H_
