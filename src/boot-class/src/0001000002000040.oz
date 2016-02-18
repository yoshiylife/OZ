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
// we don't use record

//#define NORECORDACOPS

// we flush objects
//#define NOFLUSH

// we don't test flush
//#define FLUSHTESTATSTARTING

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


// we have no str[fp]time


// boot classes are modifiable


// when object manager is started, its configuration cache won't be cleared
//#define CLEARCONFIGURATIONCACHEATSTART

// the executor doesn't expect a class cannot be found

/*
 * cbcmng.oz
 *
 * BroadcastManager for class
 */

class ClassBroadcastManager : Alarmable {
  constructor: New;
  public: Broadcast, Reply;
  protected: Expand, FindIndexOf, SetInitialTableSize;
  public: Alarm, Hash, IsEqual;

/* instance variables */
  protected:
    ConditionIndex, CountTable, anExecutor, InitialTableSize, KeyTable, Mask,
    Nbits, AnswerTable, Written, Size;

    unsigned int InitialTableSize; /* = 32; */
    global ClassID KeyTable [];
    unsigned int ConditionIndex [];
    condition Written [][];
    AnswersOfClassBroadcast AnswerTable [];
    unsigned int CountTable [];
    Executor anExecutor;
    unsigned int Size;
    unsigned int Mask;
    unsigned int Nbits;
    Timer aTimer;

/* method implementations */

    void New (Timer timer, Executor e) {

	SetInitialTableSize ();
	length KeyTable = InitialTableSize;
	length Written = 1;
	length Written [0] = InitialTableSize;
	length ConditionIndex = InitialTableSize;
	length AnswerTable = InitialTableSize;
	length CountTable = InitialTableSize;

	anExecutor = e;

	Size = 0;
	for (Mask = 1, Nbits = 1; Mask < InitialTableSize - 1;) {
	    Mask = (Mask << 1) | 1;
	    Nbits ++;
	}
	aTimer = timer;
    }

    /* send broadcast message */
    AnswersOfClassBroadcast Broadcast (global ObjectManager sender,
				       global ClassID cid, ArchitectureID aid)
      : locked {
	  AnswersOfClassBroadcast ans;
	  unsigned int i;




	  debug (0, "ClassBroadcastManager::Broadcast: Searching %O ...\n",
		 cid);
	  i = FindIndexOf (cid);
	  if (KeyTable [i] == 0) {
	      if (Size == 0) {
		  aTimer->Add (2, self);    /* alarmed once per 20 seconds */
	      }
	      ++ Size;
	      KeyTable [i] = cid;
	      AnswerTable [i] = 0;
	      ConditionIndex [i] = Size;
	      CountTable [i] = 2;	/* valid at least in 20 seconds */
	      debug (0, "ClassBroadcastManager::Broadcast: "
		     "Issuing Broadcast %O ...\n", cid);

	      anExecutor->Broadcast (sender, i, cid, aid);

	  }
	  if (AnswerTable [i] == 0) {
	      condition c = Written [ConditionIndex [i] / InitialTableSize]
		                    [ConditionIndex [i] % InitialTableSize];
	      debug (0, "ClassBroadcastManager::Broadcast: "
		     "waiting up %O ...\n", cid);
	      wait c;
	      i = FindIndexOf (cid);
	      if (KeyTable [i] != cid || AnswerTable [i] == 0) {
		  debug (0, "ClassBroadcastManager::Broadcast: "
			 "no answer returning %O ...\n", cid);
		  return 0;
	      }
	  }
	  debug (0, "ClassBroadcastManager::Broadcast: "
		 "answer returning %O ...\n", cid);
	  ans = AnswerTable [i];
	  return ans;
      }

    void Alarm (unsigned int tick) : locked {
	unsigned int i;

	for (i = 0; i < length KeyTable; i ++) {
	    if (KeyTable [i] != 0) {
		if (-- CountTable [i] == 0) {
		    unsigned int ci = Collector (i);

		    signalall
		      Written [ci / InitialTableSize] [ci % InitialTableSize];
		}
	    }
	}
    }

    unsigned int Collector (unsigned int i) {
	global ClassID cid = KeyTable [i];
	AnswersOfClassBroadcast ans = AnswerTable [i];
	unsigned int ci = ConditionIndex [i], j;

	KeyTable [i] = 0;
	AnswerTable [i] = 0;
	-- Size;
	if (Size == 0) {
	    aTimer->Delete (self);
	}
	for (j = (i - 1) & Mask; KeyTable [j] != 0;
	     i = j, j = (i - 1) & Mask) {
	    if (FindIndexOf (KeyTable [j]) == i) {
		KeyTable [i] = KeyTable [j];
		KeyTable [j] = 0;
		ConditionIndex [i] = ConditionIndex [j];
		ConditionIndex [j] = 0;
		AnswerTable [i] = AnswerTable [j];
		AnswerTable [j] = 0;
	    } else {
		break;
	    }
	}
	return ci;
    }

    void Expand () {
	unsigned int len = length KeyTable, new_len = len * 2;
	/* 2 is a table expansion factor */
	global ClassID old_keytable [] = KeyTable;
	condition old_written [][] = Written;
	unsigned int old_condition_index [] = ConditionIndex;
	AnswersOfClassBroadcast old_answer_table [] = AnswerTable;
	unsigned int old_count_table [] = CountTable;
	unsigned int i;

	length KeyTable = 0;
	length ConditionIndex = 0;
	length AnswerTable = 0;
	length CountTable = 0;
	Mask = (Mask << 1) | 1;
	Nbits ++;
	length KeyTable = new_len;
	length Written *= 2;
	for (i = length Written / 2; i < length Written; i ++) {
	    length Written [i] = InitialTableSize;
	}
	length ConditionIndex = Mask + 1;
	length AnswerTable = Mask + 1;
	length CountTable = Mask + 1;
	for (i = 0; i <= Mask/2; i ++) {
	    if (old_keytable [i] != 0) {
		unsigned int id = FindIndexOf (old_keytable [i]);

		KeyTable [id] = old_keytable [i];
		ConditionIndex [id] = old_condition_index [i];
		AnswerTable [id] = old_answer_table [i];
		CountTable [id] = old_count_table [i];
	    }
	}
	for (i = 0 ; i < length old_written ; ++i) {
	    old_written [i] = 0;
	}
    }

    unsigned int FindIndexOf (global ClassID cid) {
	unsigned int i;

	for (i = H (cid); KeyTable [i] != 0; i = (i-1) & Mask) {
	    if (KeyTable [i] == cid)
	      return i;
	}
	if (Size > length KeyTable / 3) {
	    Expand ();
	    i = FindIndexOf (cid);
	}
	return i;
    }

    unsigned int H (global ClassID cid) {
	/* mjs:	unsigned long Aw = 2654435769UL; */
	unsigned int Aw = 0x9E3779B9;
	unsigned int key;
	/*      unsigned long Aw = 40503;
		use for 16 bit machines? */

	inline "C" {
	    key = (unsigned int) cid;
	}
	return ((Aw * key) >> (32 - Nbits)) & Mask;
	/* Implementation Dependent:
	   32 is a bit length of unsigned int */
    }

    /* reply of broadcast */
    void Reply (global ClassID cid, global Class c, char dir [], ClassPart cp)
      : locked {
	  unsigned int i = FindIndexOf (cid);

	  if (KeyTable [i] == cid) {
	      if (AnswerTable [i] == 0) {
		  AnswerTable [i]=>New ();
	      }
	      AnswerTable [i]->Add (c, dir, cp);
	      signalall Written [ConditionIndex [i] / InitialTableSize]
		                [ConditionIndex [i] % InitialTableSize];
	  } /* else -- too late.  Cell has been already reused. */
      }

    void SetInitialTableSize () {InitialTableSize = 32;}

    unsigned int Hash () {return 1;}
    int IsEqual (Alarmable another) {return another == self;}
}
