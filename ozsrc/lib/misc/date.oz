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
 * date.oz
 *
 * Date
 */

class Date {
  constructor: Current, NewFromString, NewFromClock;
  public:
    Add, Compare, Difference, Hash, IsEarlierThan, IsEqual, IsEqualTo,
    IsLaterThan, PrintIt, Year, Month, Day, DayoftheWeek, TimeofDay, Clock;

/* instance variables */
  protected:
    theYear, theMonth, theDay, theDayoftheWeek, theTimeofDay, theClock;
    int theYear;
    int theMonth;
    int theDay;
    int theDayoftheWeek;
    Time theTimeofDay;
    int theClock;

/* method implementations */
    void Current () {
	int the_time;

	inline "C" {
	    time_t t = OzTime (0);
	    the_time = (long) t;
	}
	Initialize (the_time);
    }

    void NewFromString (String date) {
	char p [] = date->Content ();
	int the_time;

	inline "C" {
	    char *buf = OZ_ArrayElement (p, char);
	    char zone [4];
	    struct tm aTM;
	    time_t t;

	    if (OzStrncmp (buf, "Sun", 3) == 0) {
		aTM.tm_wday = 0;
	    } else if (OzStrncmp (buf, "Mon", 3) == 0) {
		aTM.tm_wday = 1;
	    } else if (OzStrncmp (buf, "Tue", 3) == 0) {
		aTM.tm_wday = 2;
	    } else if (OzStrncmp (buf, "Wed", 3) == 0) {
		aTM.tm_wday = 3;
	    } else if (OzStrncmp (buf, "Thu", 3) == 0) {
		aTM.tm_wday = 4;
	    } else if (OzStrncmp (buf, "Fri", 3) == 0) {
		aTM.tm_wday = 5;
	    } else if (OzStrncmp (buf, "Sat", 3) == 0) {
		aTM.tm_wday = 6;
	    }
	    if (OzStrncmp (buf + 4, "Jan", 3) == 0) {
		aTM.tm_mon = 0;
	    } else if (OzStrncmp (buf + 4, "Feb", 3) == 0) {
		aTM.tm_mon = 1;
	    } else if (OzStrncmp (buf + 4, "Mar", 3) == 0) {
		aTM.tm_mon = 2;
	    } else if (OzStrncmp (buf + 4, "Apr", 3) == 0) {
		aTM.tm_mon = 3;
	    } else if (OzStrncmp (buf + 4, "May", 3) == 0) {
		aTM.tm_mon = 4;
	    } else if (OzStrncmp (buf + 4, "Jun", 3) == 0) {
		aTM.tm_mon = 5;
	    } else if (OzStrncmp (buf + 4, "Jul", 3) == 0) {
		aTM.tm_mon = 6;
	    } else if (OzStrncmp (buf + 4, "Aug", 3) == 0) {
		aTM.tm_mon = 7;
	    } else if (OzStrncmp (buf + 4, "Sep", 3) == 0) {
		aTM.tm_mon = 8;
	    } else if (OzStrncmp (buf + 4, "Oct", 3) == 0) {
		aTM.tm_mon = 9;
	    } else if (OzStrncmp (buf + 4, "Nov", 3) == 0) {
		aTM.tm_mon = 10;
	    } else if (OzStrncmp (buf + 4, "Dec", 3) == 0) {
		aTM.tm_mon = 11;
	    }
	    if (buf [8] == ' ') {
		aTM.tm_mday = buf [9] - '0';
	    } else {
		aTM.tm_mday = (buf [8] - '0') * 10 + buf [9] - '0';
	    }
	    aTM.tm_hour = (buf [11] - '0') * 10 + buf [12] - '0';
	    aTM.tm_min = (buf [14] - '0') * 10 + buf [15] - '0';
	    aTM.tm_sec = (buf [17] - '0') * 10 + buf [18] - '0';
	    OzStrncpy (zone, buf + 20, 3);
	    aTM.tm_zone = zone;
	    aTM.tm_year
	      = (buf [24] - '0') * 1000 + (buf [25] - '0') * 100 +
		(buf [26] - '0') * 10 + (buf [27] - '0');
	    t = OzMktime (&aTM);
	    the_time = (long) t;
	}
	Initialize (the_time);
    }

    void NewFromClock (int the_time) {
	Initialize (the_time);
    }

    void Initialize (int the_time) {
	int year, month, day, dayoftheweek, hour, minute, second;

	inline "C" {
	    time_t t = (time_t) the_time;
	    struct tm aTM;

	    OzDate (&t, &aTM);
	    year = aTM.tm_year + 1900;
	    month = aTM.tm_mon + 1;
	    day = aTM.tm_mday;
	    dayoftheweek = aTM.tm_wday; /* Sunday = 0 */
	    hour = aTM.tm_hour; /* in 24 */
	    minute = aTM.tm_min;
	    second = aTM.tm_sec;
	    the_time = (long) t;
	}
	theYear = year;
	theMonth = month;
	theDay = day;
	theDayoftheWeek = dayoftheweek;
	theTimeofDay=>NewFromTime (hour, minute, second);
	theClock = the_time;
    }

    Date Add (Time time) {
	Initialize (theClock + time->Clock ());
    }

    Time Difference (Date other_date) {
	Time t=>NewFromClock (theClock - other_date->Clock ());

	return t;
    }

    int Compare (Date date) {return theClock - date->Clock ();}
    unsigned int Hash () {return theClock;}
    int IsEarlierThan (Date date) {return Compare (date) < 0;}
    int IsEqual (Date date) {return IsEqualTo (date);}
    int IsEqualTo (Date date) {return Compare (date) == 0;}
    int IsLaterThan (Date date) {return Compare (date) > 0;}

    String PrintIt () {
	String result;
	char p [];
	int res;
	int the_time = theClock;
	int bufsize = 100;

	length p = bufsize;
	inline "C" {
	    time_t t = (time_t) the_time;
	    char *buf = OZ_ArrayElement (p, char);
	    struct tm aTM;

	    OzDate (&t, &aTM);

	    /*
	     * print date and time in format:
	     *   "%a %h %e %T %Z %Y"
	     */
	    switch (aTM.tm_wday) {
	      case 0: OzStrcpy (buf, "Sun "); break;
	      case 1: OzStrcpy (buf, "Mon "); break;
	      case 2: OzStrcpy (buf, "Tue "); break;
	      case 3: OzStrcpy (buf, "Wed "); break;
	      case 4: OzStrcpy (buf, "Thu "); break;
	      case 5: OzStrcpy (buf, "Fri "); break;
	      case 6: OzStrcpy (buf, "Sat "); break;
	    }
	    switch (aTM.tm_mon) {
	      case 0: OzStrcat (buf, "Jan "); break;
	      case 1: OzStrcat (buf, "Feb "); break;
	      case 2: OzStrcat (buf, "Mar "); break;
	      case 3: OzStrcat (buf, "Apr "); break;
	      case 4: OzStrcat (buf, "May "); break;
	      case 5: OzStrcat (buf, "Jun "); break;
	      case 6: OzStrcat (buf, "Jul "); break;
	      case 7: OzStrcat (buf, "Aug "); break;
	      case 8: OzStrcat (buf, "Sep "); break;
	      case 9: OzStrcat (buf, "Oct "); break;
	      case 10: OzStrcat (buf, "Nov "); break;
	      case 11: OzStrcat (buf, "Dec "); break;
	    }
	    OzSprintf (buf + 8, "%2d %0d:%0d:%0d %s %4d",
		       aTM.tm_mday, aTM.tm_hour, aTM.tm_min, aTM.tm_sec,
		       aTM.tm_zone, aTM.tm_year);
	}
	if (res == 0) {
	    return 0;
	} else {
	    result=>NewFromArrayOfChar (p);
	}
    }

    int Year () {return theYear;}
    int Month () {return theMonth;}
    int Day () {return theDay;}
    int DayoftheWeek () {return theDayoftheWeek;}
    Time TimeofDay () {return theTimeofDay;}
    int Clock () {return theClock;}
}
