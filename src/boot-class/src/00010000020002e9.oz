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

// we use broadcast
//#define NOBROADCAST

// we flush objects
//#define NOFLUSH

// we don't test flush
//#define FLUSHTESTATSTARTING

// we are debugging
//#define NDEBUG

// we have a bug in remote instantiation


// we lookup configuration table for configured class ID


// we don't list directory by unix 'ls' command, but opendir library
//#define LISTBYLS

// we need change directory to $OZHOME before OzRead and OzSpawn


// we don't use OzRemoveCode
//#define USEOZREMOVECODE

// we don't read parents version IDs from private.i.
//#define READPARENTSFROMPRIVATEDOTI

// we have bug in alias


// we have no executor who recognize relative path from OZHOME


// we have OzCopy
//#define NOOZCOPY

// we don't have OzRename


// we distribute class not by tar'ed directory


// we have bug in StreamBuffer


// we have no support for getting executor ID


// we don't use Object::GetPropertyPathName
//#define NOGETPROPERTYPATHNAME

// we have a bug in gen-spec-src


// we have a bug in reference counter treatment when forking private thread
//#define NOFORKBUG
/*
 * package.oz
 *
 * Package - A school and a configuration set.
 *           This is a naive implementation.
 *           A-Package (application package) and C-Package (class
 *           library package) should be distinguished in future releases.
 */

class Package {
/* method interface */
  constructor: New;
  public: GetConfigurationTable, GetSchool, SetConfigurationTable, SetSchool;

/* instance variables */
    School aSchool;
    ConfigurationTable aConfigurationSet;

/* method implementations */
    void New () {
	aSchool = 0;
	aConfigurationSet = 0;
    }

    ConfigurationTable GetConfigurationTable () {return aConfigurationSet;}
    School GetSchool () {return aSchool;}
    void SetConfigurationTable (ConfigurationTable conf_table) {
	aConfigurationSet = conf_table;
    }
    void SetSchool (School school) {aSchool = school;}
}
