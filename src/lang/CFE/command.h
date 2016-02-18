/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _COMMAND_H_
#define _COMMAND_H_

extern int AddFiles (int argc, char **arg);
extern int ClassBrowse (int argc, char **arg);
extern int Chdir (int argc, char **arg);
extern int Children (int argc, char **arg);
extern int CompileAll (int argc, char **arg);
extern int Compile (int argc, char **arg);
extern int Config (int argc, char **arg);
extern int ConfigAll (int argc, char **arg);
extern int Generate (int argc, char **arg);
extern int GenerateAll (int argc, char **arg);
extern int Generic (int argc, char **arg);
extern int Info (int argc, char **arg);
extern int Instantiate (int argc, char **arg);
extern int Invoke (int argc, char **arg);
extern int Load (int argc, char **arg);
extern int List (int argc, char **arg);
extern int Parents (int argc, char **arg);
extern int Quit (int argc, char **arg);
extern int ReGenerate (int argc, char **arg);
extern int RemoveFiles (int argc, char **arg);
extern int Reset (int argc, char **arg);
extern int SchoolBrowse (int argc, char **arg);
extern int Save (int argc, char **arg);
extern int Wanted (int argc, char **arg);

typedef int (CommandProc) (int argc, char **argv);

typedef struct CommandsRec 
{
  char *name;
  CommandProc *proc;
} CommandsRec, *Commands;

static CommandsRec commands[] = {
  "add", AddFiles,
  "all", CompileAll,
  "cb", ClassBrowse,
#if 1
  "cb2", ClassBrowse,
  "cd", Chdir,
#endif
  "cfe2", Compile,
  "children", Children,
  "clean", Compile,
#if 0
  "cnffe", Config,
#endif
  "compile", Compile,
  "config", Config,
  "configall", ConfigAll,
#if 0
  "gen", Generic,
#endif
  "generate", Generate,
  "generateall", GenerateAll,
  "info", Info,
  "instantiate", Instantiate,
  "invoke", Invoke,
#if 0
  "link", Compile,
#endif
  "list", SchoolBrowse,
  "load", Load,
  "ls", List,
  "parents", Parents,
  "quit", Quit,
  "regenerate", ReGenerate,
  "remove", RemoveFiles,
  "reset", Reset,
  "save", Save,
  "sb", SchoolBrowse,
  "wanted", Wanted,
};

#define COMMAND_SIZE sizeof (commands) / sizeof (CommandsRec)

#endif _COMMAND_H_
