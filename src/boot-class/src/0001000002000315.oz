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

inline "C"{
  #include <signal.h>
}

class ExternalProcess {
 constructor:
  NewWithPid;
 public:
  Kill, SetSignal, Status, Wait, IsEqual, Hash, Id;
 protected:
  Pid, ExitStatus, StatusFlg, Chld, Finished;

  /* Instance Variables */
  int Pid;
  int Sig_id;
  int ExitStatus;
  int StatusFlg;
  condition Finished;

  /* constructors */
  void NewWithPid( int p ){ 
    Pid = p; 
    inline "C"{
      OZ_InstanceVariable_ExternalProcess( Sig_id ) = SIGTERM;
    }
    StatusFlg = 0;

    detach fork Chld();
  }

  /* private methods */
  void set_status( int status ) : locked{
    if( StatusFlg )
      raise EP::IllegalOp;
    StatusFlg = 1;
    ExitStatus = status;
    signalall Finished;
  }

  /* protected methods */
  void Chld( ){
    int status;
    int r;
    inline "C"{
      r = OzWatch( OZ_InstanceVariable_ExternalProcess( Pid ), &status );
    }
    if( r >= 0 ){
      inline "C"{
	  OzClose(OZ_InstanceVariable_ExternalProcess (Pid));
      }
    }

    if( r > 0 )
      raise EP::Killed;
    if (r == -1) {
	raise EP::IllegalOp;
    }
    set_status( status );
  }

  /* public methods */
  /* access */
  int Id(){ return Pid; }

  /* mutate */
  int SetSignal( int sig ){
    int old = Sig_id;
    Sig_id = sig;
    return old;
  }

  /* compare */
  int IsEqual( ExternalProcess p ){ return Pid == p -> Id(); }

  /* service */
  void Kill(){
    inline "C"{
      OzKill( OZ_InstanceVariable_ExternalProcess( Pid ), OZ_InstanceVariable_ExternalProcess( Sig_id ));
    }
    return;
  }

  int Status() : locked{
    if( StatusFlg )
      return ExitStatus;
    raise EP::NotFinish;
  }

  int Wait() : locked{
    while( !StatusFlg )
      wait Finished;
    return ExitStatus;
  }

  unsigned int Hash(){
    return 0; 
  }
}
