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
 * bcparam.oz
 *
 * Broadcast Parameter Holder
 */


class BroadcastParameter {
  constructor: New;
  public: GetSender, GetID, GetParam1, GetParam2,
          SetSender, SetID, SetParam1, SetParam2;

/* members */
    /*
      Param1: 0 for name directory lookup
              any ClassID for class lookup
      Param2: architecture ID for class lookup
      */
    global ObjectManager Sender;
    unsigned int ID;
    global ClassID Param1;
    ArchitectureID Param2;


/* method implementations */
    void New (global ObjectManager sender, unsigned int id,
	      global ClassID cid, ArchitectureID aid) {
	SetSender (sender);
	SetID (id);
	SetParam1 (cid);
	SetParam2 (aid);
    }
    global ObjectManager GetSender () {return Sender;}
    int GetID () {return ID;}
    global ClassID GetParam1 () {return Param1;}
    ArchitectureID GetParam2 () {return Param2;}
    void SetSender (global ObjectManager sender) {Sender = sender;}
    void SetID (int id) {ID = id;}
    void SetParam1 (global ClassID p1) {Param1 = p1;}
    void SetParam2 (ArchitectureID p2) {Param2 = p2;}

}
