/*
 * Copyright(c) 1994-1996 Information-technology Promotion Agency, Japan(IPA)
 *
 * All rights reserved.
 * This software and documentation is a result of the Open Fundamental
 * Software Technology Project of Information-technology Promotion Agency,
 * Japan(IPA).
 *
 * Permissions to use, copy, modify and distribute this software are governed
 * by the terms and conditions set forth in the file COPYRIGHT, located in
 * this release package.
 */
/*
  Copyright (c) 1994 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

inline "C"
{
#include <sys/param.h>
}


class ExternalProgram {
 constructor:
  NewWithPath;
 public:
  Exec, Spawn, KillAll;

  /* instance variables */
  String   Program;

  /* constructors */
  void NewWithPath( String path ){
    Program = path;
  }

  /* private methods */
  unsigned int make_argv( SequencedCollection<String> args )[]{
    int i, argc;
    unsigned int argv[];

    if( args == 0 ){
      OrderedCollection<String> null_arg => New();
      null_arg -> AddLast( Program );
      args = null_arg;
    }
      
    argc = args -> Size();
    length argv = argc + 1;

    for( i = 0; i < argc; i++ ){
      char a[] = args -> At( i ) -> Content();
      inline "C"{
	  (OZ_ArrayElement (argv, unsigned int))[i]
	    = (unsigned int)OZ_ArrayElement (a, char);
      }
    }
    argv[ argc ] = 0;
    return argv;
  }

  /* public methods */
  ExternalProcess Exec( SequencedCollection<String> args ){
    int fd;
    ExternalProcess process;
    char path[] = Program -> Content();
    unsigned int argv[];
    int block;

    inline "C" {
	block = OzBlockSuspend ();
    }
    argv = make_argv( args );
    inline "C"{
      fd = OzVspawn( OZ_ArrayElement( path, char ), (char**)OZ_ArrayElement( argv, char* ));
    }
    inline "C" {
	OzUnBlockSuspend (block);
    }
    if( fd < 0 )
      raise EP::CannotExec( 0 );
    process => NewWithPid( fd );
//    Processes -> Add( process );
    return process;
  }

  ExternalSpawnedProcess Spawn( SequencedCollection<String> args ){
    unsigned int argv[];
    int  pid;
    ExternalSpawnedProcess process;
    int fd;
    char path[];
    int block;

    path = Program -> Content();
    inline "C" {
	block = OzBlockSuspend ();
    }
    argv = make_argv( args );
    inline "C"{
      fd = OzVspawn( OZ_ArrayElement( path, char ), (char**)OZ_ArrayElement( argv, char* ));
    }
    inline "C" {
	OzUnBlockSuspend (block);
    }
    if( fd < 0 )
      raise EP::CannotExec( 0 );

    pid = fd;
    process => NewWithPidAndFd( pid, fd );
//    Processes -> Add( process );
    return process;
  }

  void KillAll(){
/*
    Iterator<ExternalProcess>  ite;
    ExternalProcess process;

    ite => New( Processes );
    while(( process = ite -> PostIncrement()) != 0 ){
      process -> Kill();
    }
*/
  }

}

