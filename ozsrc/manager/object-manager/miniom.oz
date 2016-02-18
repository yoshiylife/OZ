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
 * miniom.oz
 *
 * StandAloneOM
 *
 * An ObjectManager which can run stand alone (without Distributed Object
 * Managerment System).
 * A local object ApplicationStarter can start the user application.
 */

inline "C" {
#include <oz++/object-type.h>
}

class StandAloneOM : ObjectManager (alias Init SuperInit;
				    alias Shutdown SuperShutdown;) {
  public:
    /* Object Table Manager */
    ExecutorID,
    FlushObject, FlushObjectWaitingObjectManager,
    IsPermanentObject, IsSuspendedObject,
    ListObjects, ListObjectsOfStatus, ListLoadedObjects,
    ListReadyObjects, ListSuspendedObjects, ListSwappedOutObjects,
    LoadObject, LookupObject, NewObject, NewOID, PermanentizeObject,
    QueuedInvocation, RemoveMe, RemoveObject, RestoreObject, Size,
    StopObject, SuspendObject, ResumeObject, TransientizeObject,
    WasSafelyShutdown, WhichStatus,

    /* Name Directory Holder */
    GetNameDirectory, PeekNameDirectory, SetNameDirectory,

    /* Local Class Lookupper */
    LookupClass, RegisterClass, TransferFile, UnregisterClass,

    /* Class Search */
    SearchClass, SearchClassImpl,

    /* Owner */
    ChangeOwner, GetOwner,

    /* Configuration Table */
    AddBootConfiguration, ChangeConfigurationCache,
    ChangeConfigurationCacheExpirationTick, ClearConfigurationCache,
    DeleteBootConfiguration, DisableConfigurationCacheExpiration,
    EnableConfigurationCacheExpiration, GetConfigurationCacheExpirationTick,
    GetConfiguredClassID, IsConfigurationCacheExpired, RebuildConfiguration,
    SetConfigurationTable, ShowConfigurationCache,

    /* Station */
    GetStation, MyArchitecture,

    /* Executor statistics */
    ExecutorLoadAverage, ExecutorUptime, GlobalObjectGCOccurrence,
    GlobalObjectCellOutOccurrence, MemoryShortageOccurrence,
    GetNumberOfStartingExecutor,

    /* initialization and shutdown */
    Go, Flush, Stop, Shutdown,

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

    /* Domain name */
    ChangeDomain, WhichDomain,

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
    AID, BootConfiguration, aClassBroadcastManager, aClassLookupper,
    ConfigurationCache, ConfigurationCacheExpiration,
    ConfigurationCacheExpirationTick, aConfigurationCacheExpirer,
    aConfigurationTables, aDaemons, anExecutor,
    KeysOfInitialConfiguration, aNameDirectoryHolder, NumberOfStartingExecutor,
    Owner, OTEntryModifying, OTM, aPreloader, SizeOfInitialConfiguration,
    aStation, ValuesOfInitialConfiguration, FirstWarningAtSearchClassImpl,
    SuccessiveWarningAtSearchClassImpl;

/* instance variables */
    Starter ApplicationStarter;

/* method implementations */
    void Init() {
	detach fork SuperInit();
	if (ApplicationStarter == 0) {
	    ApplicationStarter=>New();
	}
	ApplicationStarter->Start();
    }

    global ConfiguredClassID
      GetConfiguredClassID(global VersionID vid,
			   global ConfigurationID confid): global {
        if (confid == 0) {
	    global ConfiguredClassID ccid;

	    ccid = ConfigurationCache->Lookup(vid);
	    if (ccid == 0) {
		ccid = BootConfiguration->Lookup(vid);
		if (ccid == 0) {
		    ccid = ApplicationStarter->GetConfiguredClassID(vid);
		    if (ccid != 0) {
			BootConfiguration->Set(vid, ccid);
		    } else {
			global Class c;

			debug (0, "ObjectManager::GetConfiguredClassID ");
			debug (0, "configured class ID fault %O\n", vid);
			c = SearchClassImpl(vid, AID);
			ccid = c->GetDefaultConfiguredClassID(vid);
		    }
		}
		if (ccid != 0) {
		    ConfigurationCache->Set(vid, ccid);
		}
	    }
	    return ccid;
	} else {
	    return aConfigurationTables->Lookup(vid, confid);
	}
    }

    void Shutdown() : global, locked {
	ApplicationStarter->Shutdown();
	SuperShutdown();
    }
}
