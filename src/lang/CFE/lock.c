/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>

#include "cfe.h"

int
  Lock (char *lock_file)
{
  int fd;

  if ((fd = creat (lock_file, 0)) == -1)
    return -1;

  close (fd);
  return 0;
}

void 
  UnLock (char *lock_file)
{
  unlink (lock_file);
}
