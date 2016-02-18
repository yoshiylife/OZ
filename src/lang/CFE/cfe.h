/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _CFE_H_
#define _CFE_H_

#include "lang/school.h"

extern char *ClassPath, *OzRoot, *User;
extern int Boot;

enum EXEC_MODE {
  NORMAL_MODE,
  TCL_MODE,
};

extern enum EXEC_MODE ExecMode;

extern School SearchEntry (char *);
extern School CreateEntry (char *, int);
extern char *CleanupName (char *);
extern int LoadInitialSchool (char *);
extern void RemoveSchool (char *);
extern int Lock (char *);
extern void UnLock (char *);

extern char *GetGenericParams (char *);
extern char *GetClassName (char *, int *, int);
extern char **GetAllClasses (char *, char *);
extern void InternalCompileStart (int);
extern int InternalCompileEnd ();
extern char **GetWanted (int *);
extern void PrintWanteds (FILE *fp);
extern void CleanupWanteds ();
extern void LoadPrevWanteds (char *);
extern FILE *ExecOzc (char *, ...);
extern int CloseOzc (FILE *);
extern void PrintOzcCommands (char *, ...);
extern void AddWantedDir (char *);

extern int GetRealGenerics (char *, char ***);

extern char *GetOriginalName (char *, int);
extern int GenerateNew (char *, char *, char *, char *);

extern void WriteToTcl (char *, ...);

extern void Auth ();

extern char *Start (int, int);

#define OZCC "gcc -c"
#define OZLINK "ld -d -assert pure-text"

#define OZLOCK ".class"

static char class_kind_str[][20] = {
  "class", "" , "" ,"", "", 
  "shared", "static class", "record", "abstract class",
};

#if 0
#define free(p) printf ("%x\n", p)
#endif

#endif _CFE_H_



