/*
COPYRIGHT AND LICENSE NOTICE

Copyright(c) 1994-1996 Information-technology Promotion Agency, Japan (IPA)

This software and documentation is a result of the Open Fundamental Software
Technology Project of Information-technology Promotion Agency, Japan (IPA).

Permission to use, copy, modify and distribute this software and
documentation for any purpose and without fee is hereby granted in
perpetuity, provided that this COPYRIGHT AND LICENSE NOTICE appears in its
entirety in all copies of the software and supporting documentation.
Other software contained in this distribution package, terms and conditions
of each license notice of the software shall be observed.

IPA MAKES NO REPRESENTATIONS OR WARRANTIES ABOUT THE SUIT ABILITY OF THE
SOFTWARE OR DOCUMENTATION FOR ANY PURPOSE.  THEY ARE PROVIDED "AS IS"
WITHOUT EXPRESS OR IMPLIED WARRANTY OF ANY KIND INCLUDING BUT NOT LIMITED
TO FUNCTION, PERFORMANCE, AND BUG-FREE.  IPA DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE AND DOCUMENTATION,INCLUDING THE WARRANTIES OF
MERCHANTABILITY, DESIGN, FITNESS FOR A PARTICULAR PURPOSE AND NON
INFRINGEMENT OF THIRD PARTY RIGHTS.  IN NO EVENT SHALL IPA BE LIABLE FOR ANY
SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL DAMAGES, OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA, OR PROFITS, WHETHER IN ACTION
ARISING OUT OF CONTRACT, NEGLIGENCE, PRODUCT LIABILITY, OR OTHER TORTIOUS
ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
SOFTWARE OR DOCUMENTATION.

This COPYRIGHT AND LICENSE NOTICE shall be subject to the Japanese version
(language), the laws of Japan (governing law), and the Tokyo District Court
shall have exclusive primary jurisdiction.
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


// we have no str[fp]time


// boot classes are modifiable


// when object manager is started, its configuration cache won't be cleared
//#define CLEARCONFIGURATIONCACHEATSTART

// the executor doesn't expect a class cannot be found


// now, creating Feb.1 sources

/*
 * cl-exc.oz
 *
 * Exceptions from collection class library
 */

shared CollectionExceptions <Assoc<OIDAsKey<T>,T>> {
    ElementNotFound (Assoc<OIDAsKey<T>,T>  );
    Empty ();
    InternalError (Assoc<OIDAsKey<T>,T>  );
    InvalidIntParameter (int);
    InvalidParameter ();
    RedefinitionOfKey (Assoc<OIDAsKey<T>,T>  );
    UnknownKey (Assoc<OIDAsKey<T>,T>  );
}
