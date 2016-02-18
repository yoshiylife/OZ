/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _SCHOOL_H_
#define _SCHOOL_H_

typedef struct SchoolRec {
  struct SchoolRec *next;
  char vid[3][17];
  char ccid[17];
  char root[17];
  int class_sc;
  int generic;
  char name[1];
} SchoolRec, *School;

#define NOT_GENERIC 0
#define FORMAL_GENERIC 1
#define REAL_GENERIC 2

extern char *GetVID (char *, int);
extern long long GetVIDValue (long long, int);
extern struct SchoolRec *AddSchool (char *, char (*)[17], int, char *, char *);

extern int LoadSchool (char *);
extern int GetClassSC (char *);

extern void PrintSchool (int, int);

#define OBJECT_NAME "Object"
#define OBJECT_CID "0001000002fffffb"
#define OBJECT_PUBLIC "0001000002fffffd"
#define OBJECT_PROTECTED "0001000002fffffe"
#define OBJECT_PRIVATE "0001000002ffffff"

#define OBJECT_PUBLIC_VID 0x0001000002fffffdLL
#define OBJECT_PROTECTED_VID 0x0001000002fffffeLL

#define NEW_OBJECT "NewObject"

#if 0
#define OLD_OBJECT
#endif

#if 0
#define OLD_NEW
#endif

#if 0
#ifdef OLD_OBJECT
#define OM_NEW_OBJECT_FORMAT "GG"
#else
#define OM_NEW_OBJECT_FORMAT "GGO"
#endif
#endif

#ifndef OLD_OBJECT
#define LOOKUP_CONFIG "LookupConfigurationSet"
#define SET_CONFIG_SET "SetConfigurationSet"
#define CONFIG_SET "ConfigurationSet"
#endif

static struct object_methods {
  char name[30];
} object_methods[] = {
  "Go",
  "Stop",
  "Removing",
  "Where",
  "Flush",
  NEW_OBJECT,
#ifndef OLD_OBJECT
  "GetConfigurationSet",
  SET_CONFIG_SET,
  LOOKUP_CONFIG,
  "GetPropertyPathName",
#endif
};

#define OBJECT_METHODS sizeof (object_methods) / sizeof (struct object_methods)

#endif _SCHOOL_H_
