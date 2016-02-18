/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <sys/time.h>
#include <time.h>


int gettimeofday(struct timeval *tp, struct timezone *tzp);
size_t strftime(char *buf, size_t size, char *fmt, struct tm *tm);
void bcopy(char *b1, char *b2, int length);

void
gettime(struct tm *tm, struct timeval *tv)
{
  time_t         clock;
  struct tm *tm0;

  tzsetwall();

  gettimeofday(tv,0);
  clock = (time_t)(tv->tv_sec);
  tm0 = gmtime(&clock);
  bcopy(((char *)tm0),((char *)tm),sizeof(struct tm));
}

void
printtime(struct tm *tm, struct timeval *tv)
{
  char buf[32];

  strftime(buf,32,"%d-%b-%y %T",tm);

  printf("%s.%06ld",buf,tv->tv_usec);
}

void
printtimeinterval(struct timeval *from, struct timeval *to)
{
  int sec,usec;

  if(to->tv_usec >= from->tv_usec)
    {
      usec = to->tv_usec - from->tv_usec;
      sec  = to->tv_sec  - from->tv_sec;
    }
  else
    {
      usec = to->tv_usec - from->tv_usec +1000000;
      sec  = to->tv_sec  - from->tv_sec  -1;
    }

  printf("%2d.%06d",sec,usec);
}
