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
 * proptableent.oz
 *
 * An entry of the table in propagator.
 */

class PropagatorTableEntry {
  constructor: New;
  public: SetKind, SetProtectedT, SetPublicT, SetSuperclasses;
  public: KindOf, NameOf, ProtectedTOf, PublicTOf, SuperclassesOf;
  public: PickAsPublic, PickAsProtected, PickAsImplementation;
  public: IsPickedAsPublic, IsPickedAsProtected, IsPickedAsImplementation;

    String Name;
    int Kind;
    String Superclasses [];
    School PublicT, ProtectedT;
    int PickedAsPublic, PickedAsProtected, PickedAsImplementation;

    void New (String name) {Name = name;}

    void SetKind (int kind) {Kind = kind;}
    void SetProtectedT (School protectedT) {ProtectedT = protectedT;}
    void SetPublicT (School publicT) {PublicT = publicT;}
    void SetSuperclasses (String superclasses []) {
	Superclasses = superclasses;
    }

    int KindOf () {return Kind;}
    String NameOf () {return Name;}
    School ProtectedTOf () {return ProtectedT;}
    School PublicTOf () {return PublicT;}
    String SuperclassesOf ()[] {return Superclasses;}

    void PickAsPublic () {
	PickedAsPublic = PickedAsProtected = PickedAsImplementation = 1;
    }
    void PickAsProtected () {PickedAsProtected = PickedAsImplementation = 1;}
    void PickAsImplementation () {PickedAsImplementation = 1;}

    int IsPickedAsPublic () {return PickedAsPublic;}
    int IsPickedAsProtected () {return PickedAsProtected;}
    int IsPickedAsImplementation () {return PickedAsImplementation;}
}
