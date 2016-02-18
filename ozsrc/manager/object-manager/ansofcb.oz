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
 * ansofcb.oz
 *
 * Answers of broadcast for class
 */

class AnswersOfClassBroadcast {
  constructor: New;
  public: Add, GetClass, GetClassPart, GetDirectoryPath, Size;

/* instance variables */
    unsigned int Numbers;
    unsigned int Capacity;
    global Class Classes [];
    char DirectoryPathes [][];
    ClassPart ClassParts [];

/* method implementations */
    void New () {
	Numbers = 0;
	Capacity = 4;
	length Classes = Capacity;
	length DirectoryPathes = Capacity;
	length ClassParts = Capacity;
    }

    void Add (global Class c, char dir [], ClassPart cp) {
	if (Numbers == Capacity) {
	    Expand ();
	}
	Classes [Numbers] = c;
	DirectoryPathes [Numbers] = dir;
	ClassParts [Numbers] = cp;
	Numbers ++;
    }

    void Expand () {
	global Class old_classes [] = Classes;
	char old_directory_pathes [][] = DirectoryPathes;
	ClassPart old_class_parts [] = ClassParts;
	unsigned int i;

	length Classes *= 2;
	length DirectoryPathes *= 2;
	length ClassParts *= 2;

	for (i = 0; i < Capacity; i ++) {
	    old_directory_pathes [i] = 0;
	    old_class_parts [i] = 0;
	}
	Capacity *= 2;
	inline "C" {
	    OzExecFree ((OZ_Pointer)old_classes);
	    OzExecFree ((OZ_Pointer)old_directory_pathes);
	    OzExecFree ((OZ_Pointer)old_class_parts);
	}
    }

    global Class GetClass (unsigned int index) {return Classes [index];}

    ClassPart GetClassPart (unsigned int index) {return ClassParts [index];}

    char GetDirectoryPath (unsigned int index)[] {
	return DirectoryPathes [index];
    }

    unsigned int Size () {return Numbers;}
}
