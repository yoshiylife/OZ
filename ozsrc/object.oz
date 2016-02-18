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
 * object.oz
 *
 * an object which is managed by an ObjectManager
 *
 * Go : called when ObjectManager loaded global objects from object
 *      image file
 *      (programmer of OZ++ should call Go at last of constructor
 *      methods of a class.)
 * Removing : called at removal.
 * Stop : called at shutdown.
 * Flush : called at flushing into object image file.
 * Where : returns object ID of ObjectManager of the executor.
 * NewObject : tentative
 */

class Object {
/* method interface below */
  public: Go, Removing, Stop, Flush, Where, NewObject;

  public:
    GetConfigurationSet, LookupConfigurationSet,
    SetConfigurationSet, GetPropertyPathName;


/* instance variables below */

    ConfigurationTable ConfigurationSet;


/* method implementations below */
    void Go () : global {}
    void Removing () : global {}
    void Stop () : global {}
    void Flush () : global {Where ()->FlushObject (oid);}

    global ObjectManager Where () : global {
	global Object o = cell;
	global ObjectManager om;

	inline "C" {
	    om = OzExecObjectManagerOf (o);
	}
	return om;
    }

    global Object NewObject (global ConfiguredClassID ccid,
			     ConfigurationTable cset) : global {}


    ConfigurationTable GetConfigurationSet () {return ConfigurationSet;}

    global ConfiguredClassID LookupConfigurationSet (global VersionID vid)
      : global {
	  if (ConfigurationSet != 0) {
	      return ConfigurationSet->Lookup (vid);
	  } else {
	      return 0;
	  }
      }

    void SetConfigurationSet (ConfigurationTable cset) : global {
	ConfigurationSet = cset;
    }

    char GetPropertyPathName (char property_name [])[] : global {
	global ConfiguredClassID ccid;
	global Class c;
	global VersionID impl_ids [];
	ArchitectureID aid;
	int i;
	unsigned int len;
	global ObjectManager om = Where ();

	inline "C" {
	    ccid = OzExecGetObjectTop (self)->head [0].a;
	}
	aid = om->MyArchitecture ();
	c = om->SearchClass (ccid, aid);
	impl_ids = c->GetImplementationParts (ccid);
	len = length impl_ids;
	for (i = len; -- i >= 0;) {
	    char p [] = om->SearchClass (impl_ids [i], aid)
	                      ->LookupProperty (impl_ids [i], property_name);
	    if (p != 0) {
		return p;
	    }
	}
	raise ClassExceptions::UnknownProperty (property_name);
    }

}
