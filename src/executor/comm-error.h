/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _COMM_ERROR_H_
#define _COMM_ERROR_H_

/* This header file defines kind of error which relate remote-channel
*  communication.
*/
/* socket related */
#define CommErrConn      1  /* fail of connection */
#define CommErrDisConn   2  /* unexpedted disconnection */
#define CommErrException 3  /* some exception occures */
#define CommErrConnRefuse 4 /* fail to connection (refused) */

/* address resolve related */
#define CommErrNoSuchExec 10 /* executor not found by address resolve */

#define CommErrNoSuchObj 100 /* object not found */
#define CommErrNoThread  200 /* thread create failure */

#endif /* _COMM_ERROR_H_ */
