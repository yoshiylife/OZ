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
 * time.oz
 *
 * time in h/m/s. 
 */

class Time {
  constructor: New, NewFromClock, NewFromTime;
  public:
    Add, Clock, Compare, EarlierThan, Equal, LaterThan, Revert,
    Subtract, Sign, Hour, Minute, Second,
    Set, SetSign, SetHour, SetMinute, SetSecond, Copy;

/* instance variables */
  protected: theClock;
    int theClock;

/* method implementations */
    void New () {Set (0, 0, 0);}

    void NewFromClock (int clock) {theClock = clock;}

    void NewFromTime (int hour, int minute, int second) {
	Set (hour, minute, second);
    }

    /* Increase contents by an argument */
    Time Add (Time t) {
	theClock += t->Clock ();
	return self;
    }

    int Clock () {return theClock;}

    /* return negative if earlier than argument;
       zero if equal; and
       positive if later than argument */
    int Compare (Time t) {return theClock - t->Clock ();}

    Time Copy () {
	Time c=>NewFromClock (theClock);

	return c;
    }

    int EarlierThan (Time t) {return Compare (t) < 0;}
    int Equal (Time t) {return Compare (t) == 0;}
    int LaterThan (Time t) {return Compare (t) > 0;}

    Time Revert () {
	theClock = -theClock;
	return self;
    }

    Time Subtract (Time t) {
	theClock -= t->Clock ();
	return self;
    }

    int Sign () {return (theClock < 0) ? -1 : 1;}

    int Hour () {
	int hour = theClock / 3600;

	if (hour < 0) {
	    --hour;
	}
	return hour;
    }

    int Minute () {
	int sec = theClock % 3600;

	if (sec < 0) {
	    sec = sec + 3600;
	}
	return sec / 60;
    }

    int Second () {
	return (theClock < 0) ? theClock % 60 + 60 : theClock % 60;
    }

    Time Set (int hour, int minute, int second) {
	theClock = hour * 3600 + minute * 60 + second;
	return self;
    }

    Time SetSign (int sign) {
	if (theClock * sign < 0) {
	    theClock = -theClock;
	}
	return self;
    }

    Time SetHour (int hour) {
	int min = Minute ();
	int sec = Second ();

	return Set (hour, min, sec);
    }

    Time SetMinute (int minute) {
	int hour = Hour ();
	int sec = Second ();

	return Set (hour, minute, sec);
    }

    Time SetSecond (int second) {
	int hour = Hour ();
	int min = Minute ();

	return Set (hour, min, second);
    }
}
