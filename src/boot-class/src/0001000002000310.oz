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


// we distribute class not by tar'ed directory


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

/*
 * preload.oz
 *
 * Object manager pre-load objects maintener
 */

/*
 * Since there is no way to know when returning array is finished,
 * it is very hard to free arrays to be returned by methods of
 * ObjectManager. (It can, but very complicated.)
 * Thus, mutual exclusion control for array member can only rely on
 * 'locked' qualifier of methods.
 * This means that ObjectManager cannot work while accessing
 * PreLoadings.  Is there any better way?
 */

class Preloader {
  constructor: New;
  public:
    PreloadCodes, PreloadConfiguredClasses, PreloadLayouts, PreloadObjects,
    ListPreloadingCodes, ListPreloadingConfiguredClasses,
    ListPreloadingLayouts, ListPreloadingObjects,
    GetNumberOfPreloadingCodes, GetNumberOfPreloadingConfiguredClasses,
    GetNumberOfPreloadingLayouts, GetNumberOfPreloadingObjects,
    AddPreloadingCode, AddPreloadingConfiguredClass,
    AddPreloadingLayout, AddPreloadingObject,
    RemovePreloadingCode, RemovePreloadingConfiguredClass,
    RemovePreloadingLayout, RemovePreloadingObject,
    IsaPreloadingCode, IsaPreloadingConfiguredClass,
    IsaPreloadingLayout, IsaPreloadingObject;

  protected:
    PreloadingCodes, PreloadingConfiguredClasses, PreloadingLayouts,
    PreloadingObjects,
    anExecutor;

/* instance variables */
    SimpleArray <global VersionID> PreloadingCodes;
    SimpleArray <global ConfiguredClassID> PreloadingConfiguredClasses;
    SimpleArray <global VersionID> PreloadingLayouts;
    SimpleArray <global Object> PreloadingObjects;
    Executor anExecutor;

/* method implementations */
    void New () {
	PreloadingCodes=>New ();
	PreloadingConfiguredClasses=>New ();
	PreloadingLayouts=>New ();
	PreloadingObjects=>New ();
    }

    void AddPreloadingCode (global VersionID vid) : locked {
	PreloadingCodes->Add (vid);
    }

    void AddPreloadingConfiguredClass(global ConfiguredClassID ccid) : locked {
	PreloadingConfiguredClasses->Add (ccid);
    }

    void AddPreloadingLayout (global VersionID vid) : locked {
	PreloadingLayouts->Add (vid);
    }

    void AddPreloadingObject (global Object o) : locked {
	PreloadingObjects->Add (o);
    }

    unsigned int GetNumberOfPreloadingCodes () : locked {
	return PreloadingCodes->Size ();
    }

    unsigned int GetNumberOfPreloadingConfiguredClasses () : locked {
	return PreloadingConfiguredClasses->Size ();
    }

    unsigned int GetNumberOfPreloadingLayouts () : locked {
	return PreloadingLayouts->Size ();
    }

    unsigned int GetNumberOfPreloadingObjects () : locked {
	return PreloadingObjects->Size ();
    }

    int IsaPreloadingCode (global VersionID vid) : locked {
	return PreloadingCodes->Includes (vid);
    }

    int IsaPreloadingConfiguredClass (global ConfiguredClassID ccid) : locked {
	return PreloadingConfiguredClasses->Includes (ccid);
    }

    int IsaPreloadingLayout (global VersionID vid) : locked {
	return PreloadingLayouts->Includes (vid);
    }

    int IsaPreloadingObject (global Object o) : locked {
	return PreloadingObjects->Includes (o);
    }

    global VersionID ListPreloadingCodes ()[] : locked {
	return PreloadingCodes->Content ();
    }

    global ConfiguredClassID ListPreloadingConfiguredClasses ()[] : locked {
	return PreloadingConfiguredClasses->Content ();
    }

    global VersionID ListPreloadingLayouts ()[] : locked {
	return PreloadingLayouts->Content ();
    }

    global Object ListPreloadingObjects ()[] : locked {
	return PreloadingObjects->Content ();
    }

    /* Preload executable codes */
    void PreloadCodes (ObjectManager om) {
	ArchitectureID aid = om->MyArchitecture ();
	unsigned int len = PreloadingCodes->Size (), i;

	for (i = 0; i < len; i ++) {
	    global VersionID vid = PreloadingCodes->At (i);
	    global Class c = om->SearchClass (vid, aid);

	    try {
		anExecutor->OzLoadCode (vid, c->GetCode (vid, aid));
	    } except {
	      ClassExceptions::UnknownProperty (property) {


		  inline "C" {
		      OzDebugf ("Preloader::PreloadCodes: "
				"private.o of %O doesn't exist.\n", vid);
		  }


	      }
	    }
	}
    }

    /* Preload runtime class informations */
    void PreloadConfiguredClasses (ObjectManager om) {
	unsigned int len = PreloadingConfiguredClasses->Size (), i;

	for (i = 0; i < len; i ++) {
	    global ConfiguredClassID ccid = PreloadingConfiguredClasses->At(i);
	    global Class c = om->SearchClass (ccid, om->MyArchitecture ());

	    try {
		anExecutor
		  ->OzLoadClass (ccid,
				 c->GetRuntimeClassInformation (ccid));
	    } except {
	      ClassExceptions::UnknownProperty (property) {


		  inline "C" {
		      OzDebugf ("Preloader::PreloadConfiguredClasses: "
				"private.r of %O doesn't exist.\n", ccid);
		  }


	      }
	    }
	}
    }

    /* Preload layout informations */
    void PreloadLayouts (ObjectManager om) {
	ArchitectureID aid = om->MyArchitecture ();
	unsigned int len = PreloadingLayouts->Size (), i;

	for (i = 0; i < len; i ++) {
	    global VersionID vid = PreloadingLayouts->At (i);
	    global Class c = om->SearchClass (vid, aid);

	    try {
		anExecutor->OzLoadLayout (vid, c->GetLayout (vid, aid));
	    } except {
	      ClassExceptions::UnknownProperty (property) {


		  inline "C" {
		      OzDebugf ("Preloader::PreloadCodes: "
				"private.l of %O doesn't exist.\n", vid);
		  }


	      }
	    }
	}
    }

    /* Preload objects */
    void PreloadObjects (ObjectTableManager OTM) {
	unsigned int len = PreloadingObjects->Size (), i;



	inline "C" {
	    _oz_debug_flag = 1;
	}


	for (i = 0; i < len; i ++) {
	    global Object o = PreloadingObjects->At (i);

	    if (OTM->Lookup (o) != 0) {
		OTM->GetEntry (o)->Load ();
	    } else {
		debug (0,
		       "Preloader::PreloadObjects: Preloading object %O no "
		       "longer exists.\n"
		       "                           Deleting it...\n", o);
		PreloadingObjects->Remove (o);
		-- i;
		-- len;
	    }
	}
    }

    void RemovePreloadingCode (global VersionID vid) : locked {
	PreloadingCodes->Remove (vid);
    }

    void RemovePreloadingConfiguredClass (global ConfiguredClassID ccid)
      : locked {
	  PreloadingConfiguredClasses->Remove (ccid);
      }

    void RemovePreloadingLayout (global VersionID vid) : locked {
	PreloadingLayouts->Remove (vid);
    }

    void RemovePreloadingObject (global Object o) : locked {
	PreloadingObjects->Remove (o);
    }
}
