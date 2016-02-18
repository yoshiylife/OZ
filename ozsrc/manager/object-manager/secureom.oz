/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
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
 * om.oz
 *
 * Object Manager
 */

inline "C" {
#include <oz++/object-type.h>
}

class SecureObjectManager : ObjectManager, SecureObject {
  public:
    /* Object Table Manager */
    ExecutorID,
    FlushObject, FlushObjectWaitingObjectManager,
    IsPermanentObject, IsSuspendedObject,
    ListObjects, ListObjectsOfStatus, ListLoadedObjects,
    ListReadyObjects, ListSuspendedObjects, ListSwappedOutObjects,
    LoadObject, LookupObject, NewObject, PermanentizeObject,
    QueuedInvocation, RemoveMe, RemoveObject, RestoreObject, Size,
    StopObject, SuspendObject, ResumeObject, TransientizeObject,
    WasSafelyShutdown, WhichStatus,

    /* Name Directory Holder */
    GetNameDirectory, SetNameDirectory,

    /* Local Class Lookupper */
    LookupClass, RegisterClass, TransferFile, UnregisterClass,

    /* Class Search */
    SearchClass, SearchClassImpl,

    /* Owner */
    ChangeOwner, GetOwner,
    ChangePassword, GetPassword,

    /* Configuration Table */
    ChangeConfigurationCache, ClearConfigurationCache,
    GetConfiguredClassID, RebuildConfiguration, SetConfigurationTable,
    ShowConfigurationCache,

    /* Station */
    GetStation, MyArchitecture,

    /* Executor statistics */
    ExecutorLoadAverage, ExecutorUptime, GlobalObjectGCOccurrence,
    GlobalObjectCellOutOccurrence, MemoryShortageOccurrence,
    GetNumberOfStartingExecutor,

    /* initialization and shutdown */
    Go, Flush, Stop, Shutdown, SetFastBoot, ResetFastBoot,

    /* Upcall daemon number */
    /* methods for configuration fault daemon should be added */
    GetNumberOfBroadcastReceiver, GetNumberOfCodeFaultDaemon,
    GetNumberOfLayoutFaultDaemon, GetNumberOfClassRequestDaemon, 
    GetNumberOfObjectFaultDaemon, GetNumberOfDebuggerClassRequestDaemon,
    SetNumberOfBroadcastReceiver, SetNumberOfCodeFaultDaemon,
    SetNumberOfLayoutFaultDaemon, SetNumberOfClassRequestDaemon, 
    SetNumberOfObjectFaultDaemon, SetNumberOfDebuggerClassRequestDaemon,

    /* Reply for broadcast */
    ReplyOfNameDirectoryBroadcast, ReplyOfClassBroadcast,

    /* Preload */
    ListPreloadingCodes, ListPreloadingConfiguredClasses,
    ListPreloadingLayouts, ListPreloadingObjects,
    AddPreloadingCode, AddPreloadingConfiguredClass,
    AddPreloadingLayout, AddPreloadingObject,
    RemovePreloadingCode, RemovePreloadingConfiguredClass,
    RemovePreloadingLayout, RemovePreloadingObject,
    IsaPreloadingCode, IsaPreloadingConfiguredClass,
    IsaPreloadingLayout, IsaPreloadingObject,

    /* warning message at searching class */
    GetFirstWarningAtSearchClassImpl, GetSuccessiveWarningAtSearchClassImpl,
    SetFirstWarningAtSearchClassImpl, SetSuccessiveWarningAtSearchClassImpl;


  protected: Init;


  protected:
    /* Upcall Daemons */ MemoryShortage, UpcallShutdown,
    SetLocks, ReleaseLocks;

  protected:
    AID, aClassBroadcastManager, aClassLookupper, ConfigurationCache,
    aConfigurationTables, aDaemons, anExecutor, FastBoot,
    KeysOfInitialConfiguration, aNameDirectoryHolder,
    NumberOfStartingExecutor, Owner, OTEntryModifying, OTM, aPreloader,
    SizeOfInitialConfiguration, aStation, ValuesOfInitialConfiguration,
    FirstWarningAtSearchClassImpl, SuccessiveWarningAtSearchClassImpl;

/* instance variables */
    ArchitectureID AID;
    ObjectTableManager OTM;
    Preloader aPreloader;
    NameDirectoryHolder aNameDirectoryHolder;
    ClassLookupper aClassLookupper;
    ConfigurationDaemon aConfigurationDaemon;
    ConfigurationTable ConfigurationCache;
    ConfigurationTables aConfigurationTables;
    Executor anExecutor;
    global Station aStation;
    ClassBroadcastManager aClassBroadcastManager;
    char Owner []; /* locked */
    char Password []; /* locked */
    Daemons aDaemons;
    unsigned int NumberOfStartingExecutor;
    BooleanHolder FastBoot;
    SharedAndExclusiveSemaphore OTEntryModifying;
    unsigned int SizeOfInitialConfiguration;
    global VersionID KeysOfInitialConfiguration [];
    global ConfiguredClassID ValuesOfInitialConfiguration [];
    unsigned int FirstWarningAtSearchClassImpl; /* = 2; */
    unsigned int SuccessiveWarningAtSearchClassImpl; /* = 10; */

/* method implementations */
    /* initialization and shutdown */

    /* Go of OM is called by executor. */
    void Go () : global {
	int major = 4, middle = 1, minor = 1;



	inline "C" {
	    OzDebugf ("ObjectManager Started.\n");
	    OzDebugf ("OZ++ Object Mamagement system - Ver. %d.%d.%d\n", 
		      major, middle, minor);
	}



	ReleaseLocks ();
	OTEntryModifying->Reset ();
 	ConfigurationCache->Setup (SizeOfInitialConfiguration,
				   KeysOfInitialConfiguration,
				   ValuesOfInitialConfiguration);
	aConfigurationDaemon->Start ();

	aClassBroadcastManager=>New (anExecutor);
	aNameDirectoryHolder->Init (anExecutor);

	/* CAUTION! class lookupper must be initialized after */
	/* capturing name directory */
	aClassLookupper->Init ();

	aDaemons->Start ();

	AID->Set (anExecutor.OzMyArchitecture ());

	OTM->Download ();
	debug (0, "Downloading objects completed.\n");

	anExecutor->OzOmStarted (0);


	SetPassword ();

	/* starting other daemons */
	detach fork MemoryShortage ();
	detach fork UpcallShutdown ();

	/* preload object images */
	aPreloader->PreloadObjects (OTM);


	inline "C" {
	    OzDebugf ("Preloading objects completed.\n");
	}


	/* make sure name directory */
	aNameDirectoryHolder->MakeSure (oid);

	anExecutor->OzBroadcastReady ();

	debug (0, "NameDirectory returned sound acknowledgement.\n");
	/* count up executor starting */
	NumberOfStartingExecutor ++;
	if (FastBoot->Test ())
	  detach fork Flush ();
	else
	  Flush ();

	/* other initialization */
	detach fork Init ();


	inline "C" {
	    OzDebugf ("ObjectManager::Go: complete.\n");
	}


    }

    void Stop () : global {
	raise AuthenticationExceptions::PermissionDenied;
    }

    void Shutdown () : global {
	raise AuthenticationExceptions::PermissionDenied;
    }

    void SecureShutdown (global SessionID session_id,
			 String encrypted_request_number)
      : global {
	  CheckValid (session_id, encrypted_req_number, OwnerOnly);


	  inline "C" {
	      OzDebugf ("ObjectManager::Shutdown: start.\n");
	  }


	  OTM->Shutdown ();


	  inline "C" {
	      OzDebugf ("ObjectManager::Shutdown: OTM shutdown complete.\n");
	  }


	  aClassLookupper->Shutdown ();


	  inline "C" {
	      OzDebugf ("ObjectManager::Shutdown: "
			"class lookupper shutdown complete.\n");
	  }


	  Flush ();


	  inline "C" {
	      OzDebugf ("ObjectManager::Shutdown: Flush complete.\n");
	  }



	  anExecutor->OzShutdownExecutor ();



	  inline "C" {
	      OzDebugf ("ObjectManager::Shutdown: Must not reach here.\n");
	  }


      }

    void SetFastBoot () : global {
	raise AuthenticationExceptions::PermissionDenied;
    }

    void ResetFastBoot () : global {
	raise AuthenticationExceptions::PermissionDenied;
    }

    /* name directory holder */
    void SetNameDirectory (global NameDirectory nd) : global {
	raise AuthenticationExceptions::PermissionDenied;
    }

    void SecureSetNameDirectory (global SessionID session_id,
				 String encrypted_req_number,
				 global NameDirectory nd)
      : global {
	  CheckValid (session_id, encrypted_req_number, OwnerOnly);
	  aNameDirectoryHolder->Set (nd);
      }

    /* Owner */

    /* Is there any scheme to protect Owner from multiple */
    /* accessing other than locking methods ? */
    void ChangeOwner (char owner []) : global, locked {
	raise AuthenticationExceptions::PermissionDenied;
    }

    void SecureChangeOwner (global SessionID session_id,
			    String encrypted_req_number,
			    char owner [])
      : global, locked {
	  CheckValid (session_id, encrypted_req_number, OwnerOnly);
	  if (IsAllowableChangingOwner (owner)) {
	      ArrayOfCharOperators acops;
	      char tmp [] = Owner;

	      Owner = owner;

	      acops.Free (tmp);

	  } else {
	      inline "C" {
		  OzExecFree ((OZ_Pointer)owner);
	      }
	      raise ObjectManagerExceptions::ProhibitedChangeOwner;
	  }
      }

    char GetPassword (global SessionID session_id,
		      String encrypted_req_number)
      : global, locked {
	  CheckValid (session_id, encrypted_req_number, OwnerOnly);
	  return Password;
      }

    void ChangePassword (char password []) : global, locked {
	Password = password;
    }

    void SetPassword () {
	/* under implementation - must set password here */
    }

    /* object table manager */
    long ExecutorID () : global {

	global Object o = oid;
	long l;

	inline "C" {
	    l = o & 0xffffffffff000000LL;
	}
	return l;

    }

    void LoadObject (global Object o) : global{
	OTEntryModifying->SharedEnter ();
	OTM->GetEntry (o)->Load ();
	OTEntryModifying->SharedExit ();
    }

    global Object LookupObject (global Object o) : global {
	return OTM->Lookup (o);
    }

    global Object NewObject (global ConfiguredClassID ccid,
			     ConfigurationTable cset)
      : global {
	  /* under implementation */
	  /* Short cut. for Alpha version. */
	  global Object o;
	  ObjectTableEntry ote;


	  o = anExecutor->OzAllocateCell (ccid);
	  o->SetConfigurationSet (cset);
	  ote=>New (o, anExecutor, ObjectStatus::Running);

	  OTM->Add (o, ote);
	  return o;
      }

    void SuspendObject (global Object o) : global {
	OTEntryModifying->SharedEnter ();
	OTM->GetEntry (o)->Suspend ();
	OTEntryModifying->SharedExit ();
    }

    void ResumeObject (global Object o) : global {
	OTEntryModifying->SharedEnter ();
	OTM->GetEntry (o)->Resume ();
	OTEntryModifying->SharedExit ();
    }

    void StopObject (global Object o) : global {
	OTEntryModifying->SharedEnter ();
	OTM->GetEntry (o)->StopIt ();
	OTEntryModifying->SharedExit ();
    }

    void RemoveMe (global Object o) : global {
	detach fork RemoveObject (o);
    }

    void RemoveObject (global Object o) : global {
	ObjectTableEntry ote;
	int permanent;

	OTEntryModifying->SharedEnter ();
	ote = OTM->GetEntry (o);
	permanent = ote->IsPermanent ();
	ote->Remove ();
	OTEntryModifying->SharedExit ();
	OTM->Remove (o);
	if (permanent) {
	    Flush ();
	}
    }

    void FlushObject (global Object o) : global {
	OTEntryModifying->SharedEnter ();
	OTM->GetEntry (o)->FlushIt ();
	OTEntryModifying->SharedExit ();
    }

    void FlushObjectWaitingObjectManager (global Object o) : global {
	FlushObject (o);
    }

    int IsPermanentObject (global Object o) : global {
	int s;

	OTEntryModifying->SharedEnter ();
	s = OTM->GetEntry (o)->IsPermanent ();
	OTEntryModifying->SharedExit ();
	return s;
    }

    int IsSuspendedObject (global Object o) : global {
	int s;

	OTEntryModifying->SharedEnter ();
	s = OTM->GetEntry (o)->IsSuspended ();
	OTEntryModifying->SharedExit ();
	return s;
    }

    global Object ListObjects ()[] : global {return OTM->List ();}

    global Object ListObjectsOfStatus (int status)[] : global {
	global Object a [] = ListObjects ();
	SimpleArray <global Object> s=>New ();
	unsigned int i, len = length a;

	for (i = 0; i < len; i ++) {
	    int st;

	    OTEntryModifying->SharedEnter ();
	    st = OTM->GetEntry (a [i])->Status ();
	    OTEntryModifying->SharedExit ();
	    if (st == status) {
		s->Add (a [i]);
	    }
	}
	return s->Content ();
    }

    global Object ListLoadedObjects ()[] : global {
	SimpleArray <global Object> s=>New ();

	s->AddArray (ListObjectsOfStatus (ObjectStatus::Running));
	s->AddArray (ListObjectsOfStatus (ObjectStatus::SwappedOut));
	s->AddArray (ListObjectsOfStatus (ObjectStatus::CellingIn));
	s->AddArray (ListObjectsOfStatus (ObjectStatus::CellingInToStop));
	s->AddArray (ListObjectsOfStatus (ObjectStatus::OrderStopped));
	return s->Content ();
    }

    global Object ListReadyObjects ()[] : global {
	return ListObjectsOfStatus (ObjectStatus::Running);
    }

    global Object ListSuspendedObjects ()[] : global {
	global Object a [] = ListObjects ();
	SimpleArray <global Object> s=>New ();
	unsigned int i, len = length a;

	for (i = 0; i < len; i ++) {
	    int f;

	    OTEntryModifying->SharedEnter ();
	    f = OTM->GetEntry (a [i])->IsSuspended ();
	    OTEntryModifying->SharedExit ();
	    if (f) {
		s->Add (a [i]);
	    }
	}
	return s->Content ();
    }

    global Object ListSwappedOutObjects ()[] : global {
	SimpleArray <global Object> s=>New ();

	s->AddArray (ListObjectsOfStatus (ObjectStatus::SwappedOut));
	s->AddArray (ListObjectsOfStatus (ObjectStatus::CellingIn));
	s->AddArray (ListObjectsOfStatus (ObjectStatus::CellingInToStop));
	return s->Content ();
    }

    void RestoreObject (global Object o) : global {
	OTEntryModifying->SharedEnter ();
	OTM->GetEntry (o)->Restore ();
	OTEntryModifying->SharedExit ();
    }

    void PermanentizeObject (global Object o) : global {
	ObjectTableEntry ote;

	OTEntryModifying->SharedEnter ();
	ote=OTM->GetEntry (o);
	ote->Permanentize ();
	ote->FlushIt ();
	OTEntryModifying->SharedExit ();
	Flush ();
    }

    void TransientizeObject (global Object o) : global {
	OTEntryModifying->SharedEnter ();
	OTM->GetEntry (o)->Transientize ();
	OTEntryModifying->SharedExit ();
    }

    unsigned int Size () : global {return OTM->Size ();}

    void QueuedInvocation (global Object o) : global {
	OTEntryModifying->SharedEnter ();
	OTM->GetEntry (o)->QueuedInvocation ();
	OTEntryModifying->SharedExit ();
    }

    /* return 0 if previous Shutdown of o was erroneous */
    int WasSafelyShutdown (global Object o) : global {
	return OTM->GetEntry (o)->WasSafelyShutdown ();
    }

    int WhichStatus (global Object o) : global {
	int st;

	OTEntryModifying->SharedEnter ();
	st = OTM->GetEntry (o)->Status ();
	OTEntryModifying->SharedExit ();
	return st;
    }

    /* local class lookupper */
    global Class LookupClass (global ClassID cid, ArchitectureID arch)
      : global {
	  return aClassLookupper->Lookup (cid, arch);
      }

    void RegisterClass (global Class c) : global {
	aClassLookupper->RegisterAsLocalClass (c);
    }

    void UnregisterClass (global Class c) : global {
	aClassLookupper->UnregisterClass (c);
    }

    int TransferFile (global Class remote, char from_file [], char to_file [])
      : global {
	  return anExecutor->TransferFile (remote, from_file, to_file);
      }

    global Class SearchClassImpl (global ClassID cid, ArchitectureID aid) {
	AnswersOfClassBroadcast ans = 0;
	global Class c = 0;
	unsigned int count, n = FirstWarningAtSearchClassImpl;

	debug (0, "ObjectManager::SearchClassImpl: cid = %O, aid = %d\n",
	       cid, aid->Get ());

	while (c == 0) {
	    for (count = 0; count < n; count++) {
		aClassLookupper->WaitClassEmployment ();
		if ((c = aClassLookupper->Lookup (cid, aid)) != 0) {
		    break;
		} else if ((ans = aClassBroadcastManager
			            ->Broadcast (oid, cid, aid)) != 0) {
		    unsigned int i, size = ans->Size ();

		    for (i = 0; i < size; i ++) {
			c = aClassLookupper
			      ->LoadClassPart (cid, aid, ans->GetClass (i),
					       ans->GetDirectoryPath (i),
					       ans->GetClassPart (i));
			if (c != 0) {
			    break;
			}
		    }
		}
	    }
	    if (c == 0) {


		inline "C" {
		    OzDebugf ("ObjectManager::SearchClassImpl: "
			      "searching %O ...\n",
			      cid);
		}


	    }
	    n = SuccessiveWarningAtSearchClassImpl;
	}
	return c;
    }

    global Class SearchClass (global ClassID cid, ArchitectureID aid)
      : global {
	  global Class c = SearchClassImpl (cid, aid);
	  inline "C" {
	      OzExecFree ((OZ_Pointer)aid);
	  }
	  return c;
      }

    /* configuration table */
    void ClearConfigurationCache () : global {
	ConfigurationCache->Clear ();
    }

    global ConfiguredClassID
      GetConfiguredClassID(global VersionID vid, global ConfigurationID confid)
	: global {
	    if (confid == 0) {
		global ConfiguredClassID ccid;

		ccid = ConfigurationCache->Lookup (vid);
		if (ccid == 0) {
		    global Class c;

		    debug (0, "ObjectManager::GetConfiguredClassID ");
		    debug (0, "configured class ID fault %O\n", vid);
		    c = SearchClassImpl (vid, AID);
		    ccid = c->GetDefaultConfiguredClassID (vid);
		    if (ccid != 0) {
			ConfigurationCache->Set (vid, ccid);
		    }
		}
		return ccid;
	    } else {
		return aConfigurationTables->Lookup (vid, confid);
	    }
	}

    void RebuildConfiguration (global VersionID vid) : global {
	ChangeConfigurationCache (vid, 0);
	GetConfiguredClassID (vid, 0);
    }

    void SetConfigurationTable (global ConfigurationID confid,
				ConfigurationTable conf)
      : global {
	  aConfigurationTables->SetConfiguration (confid, conf);
      }

    void ChangeConfigurationCache (global VersionID vid,
				   global ConfiguredClassID ccid)
      : global {
	  ConfigurationCache->Set (vid, ccid);
      }

    global ConfiguredClassID
      ShowConfigurationCache (global VersionID vid) : global {
	  return ConfigurationCache->Lookup (vid);
      }

    /* upcall daemons */
    void MemoryShortage () {
	/* should be implemented in Beta version */
    }

    void UpcallShutdown () {
	/* should be implemented in Beta version */
    }

    unsigned int GetNumberOfBroadcastReceiver () : global {
	return aDaemons->GetNumberOfBroadcastReceiver ();
    }

    void SetNumberOfBroadcastReceiver (unsigned int n) : global {
	aDaemons->SetNumberOfBroadcastReceiver (n);
    }

    unsigned int GetNumberOfCodeFaultDaemon () : global {
	return aDaemons->GetNumberOfCodeFaultDaemon ();
    }

    void SetNumberOfCodeFaultDaemon (unsigned int n) : global {
	aDaemons->SetNumberOfCodeFaultDaemon (n);
    }

    unsigned int GetNumberOfLayoutFaultDaemon () : global {
	return aDaemons->GetNumberOfLayoutFaultDaemon ();
    }

    void SetNumberOfLayoutFaultDaemon (unsigned int n) : global {
	aDaemons->SetNumberOfLayoutFaultDaemon (n);
    }

    unsigned int GetNumberOfClassRequestDaemon () : global {
	return aDaemons->GetNumberOfClassRequestDaemon ();
    }

    void SetNumberOfClassRequestDaemon (unsigned int n) : global {
	aDaemons->SetNumberOfClassRequestDaemon (n);
    }

    unsigned int GetNumberOfObjectFaultDaemon () : global {
	return aDaemons->GetNumberOfObjectFaultDaemon ();
    }

    void SetNumberOfObjectFaultDaemon (unsigned int n) : global {
	aDaemons->SetNumberOfObjectFaultDaemon (n);
    }

    unsigned int GetNumberOfDebuggerClassRequestDaemon () : global {
	return aDaemons->GetNumberOfDebuggerClassRequestDaemon ();
    }

    void SetNumberOfDebuggerClassRequestDaemon (unsigned int n) : global {
	aDaemons->SetNumberOfDebuggerClassRequestDaemon (n);
    }

    /* Reply for broadcast */
    void
      ReplyOfNameDirectoryBroadcast (unsigned int id, global NameDirectory nd)
	: global {
	    aNameDirectoryHolder->Reply (nd);
	}

    void ReplyOfClassBroadcast (global ClassID cid, global Class c,
				char dir [], ClassPart cp)
      : global {



	  aClassBroadcastManager->Reply (cid, c, dir, cp);
      }

    unsigned int GetFirstWarningAtSearchClassImpl () {
	return FirstWarningAtSearchClassImpl;
    }

    unsigned int GetSuccessiveWarningAtSearchClassImpl () {
	return SuccessiveWarningAtSearchClassImpl;
    }

    void SetFirstWarningAtSearchClassImpl (unsigned int n) {
	FirstWarningAtSearchClassImpl = n;
    }

    void SetSuccessiveWarningAtSearchClassImpl (unsigned int n) {
	SuccessiveWarningAtSearchClassImpl = n;
    }

    /* station */
    global Station GetStation () : global {return aStation;}

    ArchitectureID MyArchitecture () : global {return AID;}

    /* executor interface */
    /* returns uptime of the executor */

    Time ExecutorUptime () : global {return anExecutor->ExecutorUptime ();}


    /* returns number of ready threads in the executor */
    unsigned int ExecutorLoadAverage () : global {

	return anExecutor->ExecutorLoadAverage ();

    }

    /* returns number of occurrences of global object GC */
    unsigned int GlobalObjectGCOccurrence () : global {

	return anExecutor->GlobalObjectGCOccurrence ();

    }

    /* returns number of occurrences of global object swapping out */
    unsigned int GlobalObjectCellOutOccurrence () : global {

	return anExecutor->GlobalObjectCellOutOccurrence ();

    }

    /* returns number of occurrences of memory shortage upcall */
    unsigned int MemoryShortageOccurrence () : global {

	return anExecutor->MemoryShortageOccurrence ();

    }

    /* returns number of occurrences of starting executor */
    unsigned int GetNumberOfStartingExecutor () : global {
	return NumberOfStartingExecutor;
    }

    /* preload */
    global VersionID ListPreloadingCodes ()[] : global {
	return aPreloader->ListPreloadingCodes ();
    }

    global ConfiguredClassID ListPreloadingConfiguredClasses ()[] : global {
	return aPreloader->ListPreloadingConfiguredClasses ();
    }

    global VersionID ListPreloadingLayouts ()[] : global {
	return aPreloader->ListPreloadingLayouts ();
    }

    global Object ListPreloadingObjects ()[] : global {
	return aPreloader->ListPreloadingObjects ();
    }

    void AddPreloadingCode (global VersionID vid) : global {
	aPreloader->AddPreloadingCode (vid);
    }

    void AddPreloadingConfiguredClass(global ConfiguredClassID ccid) : global {
	aPreloader->AddPreloadingConfiguredClass (ccid);
    }

    void AddPreloadingLayout (global VersionID vid) : global {
	aPreloader->AddPreloadingLayout (vid);
    }

    void AddPreloadingObject (global Object o) : global {
	aPreloader->AddPreloadingObject (o);
    }

    void RemovePreloadingCode (global VersionID vid) : global {
	aPreloader->RemovePreloadingCode (vid);
    }

    void RemovePreloadingConfiguredClass (global ConfiguredClassID ccid)
      : global {
	  aPreloader->RemovePreloadingConfiguredClass (ccid);
      }

    void RemovePreloadingLayout (global VersionID vid) : global {
	aPreloader->RemovePreloadingLayout (vid);
    }

    void RemovePreloadingObject (global Object o) : global {
	aPreloader->RemovePreloadingObject (o);
    }

    int IsaPreloadingCode (global VersionID vid) : global {
	return aPreloader->IsaPreloadingCode (vid);
    }

    int IsaPreloadingConfiguredClass (global ConfiguredClassID ccid) : global {
	return aPreloader->IsaPreloadingConfiguredClass (ccid);
    }

    int IsaPreloadingLayout (global VersionID vid) : global {
	return aPreloader->IsaPreloadingLayout (vid);
    }

    int IsaPreloadingObject (global Object o) : global {
	return aPreloader->IsaPreloadingObject (o);
    }

/* private methods below */
    /*
     * Very naive implementation.
     * Redundant flush (i.e. flushing after a flushing already ordered)
     * should be avoided.
     */
    void Flush () : locked, global {

	ObjectTableEntry ote=>New (oid, anExecutor, ObjectStatus::Running);

	char password [];

	SetLocks ();
	password = Password;
	Password = 0;
	ote->Permanentize ();
	ote->FlushIt ();
	Password = password;
	ReleaseLocks ();
	ote->Destroy ();
    }

    int IsAllowableChangingOwner (char u []) {
	ArrayOfCharOperators acops;
	int res;


	if (acops.IsEqual (Owner, "nobody")) {

	    res = 1;
	} else {

	    char sender [] = anExecutor->SenderOfThisMessage();



	    res = acops.IsEqual (sender, Owner) && acops.IsEqual (u, "nobody");

	    inline "C" {
		OzExecFree ((OZ_Pointer)sender);
	    }
	}
	return res;
    }
}
