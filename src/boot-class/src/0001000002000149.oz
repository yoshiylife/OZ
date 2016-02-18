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
// we don't use record

//#define NORECORDACOPS

// we flush objects
//#define NOFLUSH

// we are debugging
//#define NDEBUG

// we have no bug in remote instantiation
//#define NOREMOTEINSTANTIATION

// we lookup configuration table for configured class ID


// we don't list directory by unix 'ls' command, but opendir library
//#define LISTBYLS

// we need change directory to $OZHOME before OzRead and OzSpawn


// we don't use OzRemoveCode
//#define USEOZREMOVECODE

// we don't read parents version IDs from private.i.
//#define READPARENTSFROMPRIVATEDOTI

// we have no executor who recognize relative path from OZHOME


// we have OzCopy
//#define NOOZCOPY

// we don't have OzRename


// we have no bug in class StreamBuffer
//#define STREAMBUFFERBUG

// we have no support for getting executor ID


// we use Object::GetPropertyPathName
//#define NOGETPROPERTYPATHNAME

// we have a bug in reference counter treatment when forking private thread
//#define NOFORKBUG

// we have a bug in OzOmObjectTableRemove
//#define NOBUGINOZOMOBJECTTABLEREMOVE

// we have no account directory


// boot classes are modifiable


// when object manager is started, its configuration cache won't be cleared
//#define CLEARCONFIGURATIONCACHEATSTART

// the executor doesn't expect a class cannot be found


// now, creating Feb.1 sources


// Executing Plan Plum: compressing the size of class object

/*
 * daemons.oz
 *
 * Daemons
 */

class Daemons : Exclusive (rename New SuperNew;) {
  constructor: New;

  public:
    Start,
    GetNumberOfBroadcastReceiver, GetNumberOfCodeFaultDaemon,
    GetNumberOfLayoutFaultDaemon, GetNumberOfClassRequestDaemon,
    GetNumberOfObjectFaultDaemon, GetNumberOfDebuggerClassRequestDaemon,
    SetNumberOfBroadcastReceiver, SetNumberOfCodeFaultDaemon,
    SetNumberOfLayoutFaultDaemon, SetNumberOfClassRequestDaemon,
    SetNumberOfObjectFaultDaemon, SetNumberOfDebuggerClassRequestDaemon;


  public: Lock, Unlock;
  protected: SuperNew;
  protected:
    aBroadcastReceiver, aCodeFaultDaemon, aLayoutFaultDaemon,
    aClassRequestDaemon, anObjectFaultDaemon, aDebuggerClassRequestDaemon;
  protected: LockCondition, Locking;

/* instance variables */
    BroadcastReceiver aBroadcastReceiver;
    CodeFaultDaemon aCodeFaultDaemon;
    LayoutFaultDaemon aLayoutFaultDaemon;
    ClassRequestDaemon aClassRequestDaemon;
    ObjectFaultDaemon anObjectFaultDaemon;
    DebuggerClassRequestDaemon aDebuggerClassRequestDaemon;

/* method implementations */
    void New (BroadcastReceiver br, CodeFaultDaemon cf,
	      LayoutFaultDaemon lf, ClassRequestDaemon cr,
	      ObjectFaultDaemon of, DebuggerClassRequestDaemon dcr) {
	SuperNew ();
	aBroadcastReceiver = br;
	aCodeFaultDaemon = cf;
	aLayoutFaultDaemon = lf;
	aClassRequestDaemon = cr;
	anObjectFaultDaemon = of;
	aDebuggerClassRequestDaemon = dcr;
    }

    void Start (ObjectManager om) : locked {
	aCodeFaultDaemon->Start (om);
	aLayoutFaultDaemon->Start (om);
	aClassRequestDaemon->Start (om);
	anObjectFaultDaemon->Start (om);
	aBroadcastReceiver->Start (om);
	aDebuggerClassRequestDaemon->Start (om);
    }

    unsigned int GetNumberOfBroadcastReceiver () {
	aBroadcastReceiver->GetNumberOfProcesses ();
    }

    void SetNumberOfBroadcastReceiver (unsigned int n) {
	Lock ();
	aBroadcastReceiver->SetNumberOfProcesses (n);
	Unlock ();
    }

    unsigned int GetNumberOfCodeFaultDaemon () {
	return aCodeFaultDaemon->GetNumberOfProcesses ();
    }

    void SetNumberOfCodeFaultDaemon (unsigned int n) {
	Lock ();
	aCodeFaultDaemon->SetNumberOfProcesses (n);
	Unlock ();
    }

    unsigned int GetNumberOfLayoutFaultDaemon () {
	return aLayoutFaultDaemon->GetNumberOfProcesses ();
    }

    void SetNumberOfLayoutFaultDaemon (unsigned int n) {
	Lock ();
	aLayoutFaultDaemon->SetNumberOfProcesses (n);
	Unlock ();
    }

    unsigned int GetNumberOfClassRequestDaemon () {
	return aClassRequestDaemon->GetNumberOfProcesses ();
    }

    void SetNumberOfClassRequestDaemon (unsigned int n) {
	Lock ();
	aClassRequestDaemon->SetNumberOfProcesses (n);
	Unlock ();
    }

    unsigned int GetNumberOfObjectFaultDaemon () {
	return anObjectFaultDaemon->GetNumberOfProcesses ();
    }

    void SetNumberOfObjectFaultDaemon (unsigned int n) {
	Lock ();
	anObjectFaultDaemon->SetNumberOfProcesses (n);
	Unlock ();
    }

    unsigned int GetNumberOfDebuggerClassRequestDaemon () {
	return aDebuggerClassRequestDaemon->GetNumberOfProcesses ();
    }

    void SetNumberOfDebuggerClassRequestDaemon (unsigned int n) {
	Lock ();
	aDebuggerClassRequestDaemon->SetNumberOfProcesses (n);
	Unlock ();
    }
}
