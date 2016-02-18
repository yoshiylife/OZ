/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* 
gcc pikopiko.c -I/usr/X11R5/include -L/usr/X11R5/lib -lX11 -lXpm -o pikopiko
*/

#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/xpm.h>
#include <stdio.h>
#include <signal.h>
#include <fcntl.h>
#include <sys/param.h>
#include <stdlib.h>
#include <errno.h>
#include <termios.h>

#define OZ_ROOT

#if 1
#  define PIKO_SUBDIR "include/pixmaps"
#else
#  define PIKO_SUBDIR "tmp"
#endif

typedef struct PikoData {
  XImage *image;
  int height, width;
} PikoData;

static char *OzRoot = 0 ;
static int mypid;

static Display *d;
static Window canvas;
static GC gc;
static PikoData data_off, data_on;
static int blocking = 0;

void SigioIntr()
{
  XImage *image;
  char buf[16];
  int rval = 0;

  for (;;) {
    rval = read(0, buf, 2);
    if (rval == -1) {
      if (errno == EWOULDBLOCK)
	return;
      else
	exit(1);
    }
    buf[1] = '\0';
#if 0
    printf("buf = %s, rval = %d\n", buf, rval);
#endif
    switch (atoi(buf)) {
    case 0:
      image = data_off.image;
      break;
    case 1:
      image = data_on.image;
      break;
    case 2:
      exit(0);
    default:
      break;
    }
    if (! blocking)
      XPutImage(d, canvas, gc, image, 0, 0, 0, 0, data_off.width,
		data_off.height);
    rval = write(1, "OK\n", 3);
    if (rval == -1)
      if (errno != EWOULDBLOCK)
	exit(1);
  }
}

void InitIO()
{
  struct sigvec vec;

  mypid = getpid();
  vec.sv_handler = SigioIntr;
  vec.sv_mask = ~0;
  /* vec.sv_flags = SV_ONSTACK; */
  sigvec(SIGIO, &vec, (struct sigvec *)0);
  fcntl(0, F_SETFL, FASYNC|FNDELAY);
  fcntl(0, F_SETOWN, mypid);
}

int LoadScreen (char *fname, Display *d, GC gc, PikoData *data)
{
  XImage *image, *shape;
  XpmAttributes attributes;
  int result;

  attributes.valuemask = XpmReturnInfos;
  result = XpmReadFileToImage
    (d, fname, &image, &shape, &attributes);
  switch (result) {
  case XpmOpenFailed:
    fprintf(stderr, "LoadScreen: %s open failed.\n", fname);
    return 0;
  case XpmFileInvalid:
    fprintf(stderr, "LoadScreen: Invalid file contents.\n");
    return 0;
  case XpmNoMemory:
    fprintf(stderr, "LoadScreen: No memory.\n");
    return 0;
  case XpmColorError:
    fprintf(stderr, "LoadScreen: Color error.\n");
    return 0;
  case XpmColorFailed:
    fprintf(stderr, "LoadScreen: Color failed.\n");
    return 0;
  }
#if 0
  printf("LoadScreen: Accomplished successfully.\n");
#endif
  data->image = image;
  data->height = attributes.height;
  data->width = attributes.width;
  return(1);
}

main(int argc, char **argv)
{
  Window r, w;
  XEvent e;
  char path[MAXPATHLEN + 1];
  int rval;
  
  InitIO();
#ifdef OZ_ROOT
  if (!(OzRoot = getenv("OZROOT")))
#else
  if (!(OzRoot = getenv("OZHOME")))
#endif OZ_ROOT
    OzRoot = "/home/oz++";
  d = XOpenDisplay (NULL);
  r = RootWindow (d, 0);
  gc = XCreateGC (d, r, 0, 0);

#if 1
  sprintf(path, "%s/%s/off.h", OzRoot, PIKO_SUBDIR);
#else
  sprintf(path, "/home/oni/src/X/off.h");
#endif
  if (!(LoadScreen(path, d, gc, &data_off)))
    exit(1);
#if 1
  sprintf(path, "%s/%s/on.h", OzRoot, PIKO_SUBDIR);
#else
  sprintf(path, "/home/oni/src/X/on.h");
#endif
  if (!(LoadScreen(path, d, gc, &data_on)))
    exit(1);
  if (!(data_off.height == data_on.height
	&& data_off.width == data_on.width)) {
    fprintf(stderr, "pikopiko: off and off are in different size\n");
    exit(1);
  }

  w = XCreateSimpleWindow
    (d, r, 0, 0, data_off.width, data_off.height, 0, 0, 1);
  XStoreName(d, w, argv[1]);
  canvas = XCreateSimpleWindow
    (d, w, 0, 0, data_off.width, data_off.height, 0, 0, 1);
  XSelectInput (d, w, ExposureMask);
  XSelectInput (d, canvas, ExposureMask);

  XMapWindow (d, w);
  XMapSubwindows (d, w);

  XPutImage(d, canvas, gc, data_off.image, 0, 0, 0, 0, data_off.width,
	    data_off.height);
  rval = write(1, "OK\n", 3); /* ack */
  if (rval == -1)
    if (errno != EWOULDBLOCK)
      exit(1);
  while ( 1 ) {
    XNextEvent (d, &e);
    switch (e.type) {
    case Expose :
      blocking = 1;
      XPutImage(d, canvas, gc, data_off.image, 0, 0, 0, 0, data_off.width,
		data_off.height);
      blocking = 0;
      break;
    }
  }
}
