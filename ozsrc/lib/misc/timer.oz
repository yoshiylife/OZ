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
 * timer.oz
 *
 * Timer
 */

class Timer {
  constructor: New;
  public: Add, Delete, GetTimeQuantum, SetTimeQuantum, Start, Stop;
  protected: Alarm, DefaultTimeQuantum, Sleep;

    unsigned int TimeQuantum; // constant

    SimpleTable <unsigned int, SimpleArray <Alarmable>> Table;
    unsigned int Tick;
    unsigned int ToStop;
    condition Lock;

    void New () {
	Table=>New ();
	Tick = 0;
	TimeQuantum = DefaultTimeQuantum ();
	detach fork Start ();
    }

    void Add (unsigned int tick, Alarmable o) : locked {
	if (Table->IncludesKey (tick)) {
	    Table->AtKey (tick)->Add (o);
	} else {
	    SimpleArray <Alarmable> set=>New ();

	    set->Add (o);
	    Table->Add (tick, set);
	}
    }

    void Alarm (unsigned int tick) : locked {
	unsigned int i, j;
	unsigned int count = Table->Size ();
	unsigned int len = Table->Capacity ();

	for (i = 0; count > 0 && i < len; i ++) {
	    unsigned int key = Table->KeyAt (i);

	    if (key != 0) {
		-- count;
		if (tick % key == 0) {
		    SimpleArray <Alarmable> list = Table->At (i);
		    unsigned int size = list->Size ();
		    for (j = 0; j < size; j ++) {
			detach fork list->At (j)->Alarm (key);
		    }
		}
	    }
	}
    }

    unsigned int DefaultTimeQuantum () {return 10;} // 10 seconds

    void Delete (Alarmable o) : locked {
	unsigned int sets [] = Table->SetOfKeys ();
	unsigned int i, len = length sets;

	for (i = 0; i < len; i ++) {
	    SimpleArray <Alarmable> a = Table->AtKey (sets [i]);

	    if (a->Includes (o)) {
		a->Remove (o);
		if (a->Size () == 0) {
		    Table->RemoveKey (sets [i]);
		}
	    }
	}
    }

    unsigned int GetTimeQuantum () {return TimeQuantum;}

    void Signal () : locked {signal Lock;}

    void Sleep (unsigned int interval) {
	inline "C" {
	    OzSleep (interval);
	}
	Signal ();
    }

    void Start () : locked {
	ToStop = 0;
	while (1) {
	    detach fork Sleep (TimeQuantum);
	    wait Lock;
	    if (ToStop) {
		break;
	    }
	    ++ Tick;
	    detach fork Alarm (Tick);
	}
    }

    void SetTimeQuantum (unsigned int new_quantum) : locked {
	TimeQuantum = new_quantum;
    }

    void Stop () : global, locked {ToStop = 1; signal Lock;}
}
