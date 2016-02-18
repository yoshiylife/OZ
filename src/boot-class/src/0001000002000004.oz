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
 * acops.oz
 *
 * Operators of NULL terminating array of char.
 */

inline "C" {
#include <oz++/object-type.h>
#include <netinet/in.h>
}


record ArrayOfCharOperators {



/* no member */

/* operator implementations */


    int AtoI (char s []) {
	int sum = 0, sign = 1;
	unsigned int i = 0, len = length s;

	if (s [i] == '-') {
	    sign = -1;
	    ++ i;
	}
	for (; i < len; i ++) {
	    if (s [i] >= '0' && s [i] <= '9') {
		sum = sum * 10 + s[i] - '0';
	    } else {
		break;
	    }
	}
	return sum * sign;
    }

    int Compare (char s1 [], char s2 []) {
	int result;

	if (s1 == s2) {
	    return 0;
	} else if (s1 != 0 && s2 != 0) {
	    inline "C" {
		result = OzStrcmp (OZ_ArrayElement (s1, char),
				   OZ_ArrayElement (s2, char));
	    }
	    return result;
	} else {
	    if (s1 == 0) {
		return -1;
	    } else {
		return 1;
	    }
	}
    }

    char Concatenate (char s1 [], char s2 [])[] {
	if (s2 != 0) {
	    unsigned int total_len, s1capa = length s1;

	    inline "C" {
		total_len
		  = OzStrlen (OZ_ArrayElement (s1, char)) +
		    OzStrlen (OZ_ArrayElement (s2, char)) + 1;
		if (total_len > s1capa) {
		    OzLangArrayAlloc (&s1, (long long) OZ_CHAR, 1, total_len);
		}
		OzStrcat (OZ_ArrayElement (s1, char),
			  OZ_ArrayElement (s2, char));
	    }
	}
	return s1;
    }

    char Copy (char s1 [], char s2 [])[] {
	if (s2 != 0) {
	    unsigned int s2len, s1capa = length s1;

	    inline "C" {
		s2len = OzStrlen (OZ_ArrayElement (s2, char)) + 1;
		if (s2len > s1capa) {
		    OzLangArrayAlloc (&s1, (long long) OZ_CHAR, 1, s2len);
		}
		OzStrcpy (OZ_ArrayElement (s1, char),
			  OZ_ArrayElement (s2, char));
	    }
	    return s1;
	} else {
	    return 0;
	}
    }

    char Duplicate (char s [])[] {
	char d [] = 0;

	if (s != 0) {
	    length d = length s;
	    inline "C" {
		OzStrcpy (OZ_ArrayElement (d, char),
			  OZ_ArrayElement (s, char));
	    }
	}
	return d;
    }

    void Free (char s []) {
	if (s != 0) {
	    inline "C" {
		OzExecFree ((OZ_Pointer)s);
	    }
	}
    }

    unsigned int Hash (char s []) {
	unsigned int h;
	unsigned int len;

	if (s != 0) {
	    len = Length (s);
            inline "C" {
                int i;
                unsigned int *p = OZ_ArrayElement (s, unsigned int);

                h = len;
                i = len / (sizeof (unsigned int) / sizeof (char));
                for (; -- i >= 0;) {
		    h ^= htonl (p [i]);
		}
            }
	    debug (0, "ArrayOfCharOperators::Hash: h = %u\n", h);
	    return h;
	} else {
	    return 0;
	}
    }

    int IsEqual (char s1 [], char s2 []) {return Compare (s1, s2) == 0;}

    char ItoA (int n)[] {
	char buf [];
	unsigned int len, tmp;

	if (n < 0) {
	    tmp = -n;
	    len = 1;
	} else {
	    tmp = n;
	    len = 0;
	}
	do {
	    tmp /= 10;
	    len ++;
	} while (tmp > 0);
	length buf = len + 1;
	if (n < 0) {
	    buf [0] = '-';
	    tmp = -n;
	} else {
	    tmp = n;
	}
	buf [len] = 0;
	do {
	    buf [--len] = (tmp % 10) + '0';
	    tmp /= 10;
	} while (tmp > 0);
	return buf;
    }

    unsigned int Length (char s []) {
	unsigned int len;

	if (s != 0) {
	    inline "C" {
		len = OzStrlen (OZ_ArrayElement (s, char));
	    }
	    return len;
	} else {
	    return 0;
	}
    }

    char ToLower (char s [])[] {
	if (s != 0) {
	    inline "C" {
		char *p = OZ_ArrayElement (s, char);
		unsigned int i;

		for (i = 0; p [i]; i ++) {
		    if (OzIsupper (p [i])) {
			p [i] -= 'A' - 'a';
		    }
		}
	    }
	}
	return s;
    }

    char ToUpper (char s [])[] {
	if (s != 0) {
	    inline "C" {
		char *p = OZ_ArrayElement (s, char);
		unsigned int i;

		for (i = 0; p [i]; i ++) {
		    if (OzIslower (p [i])) {
			p [i] += 'A' - 'a';
		    }
		}
	    }
	}
	return s;
    }

    global Object Str2OID (char str []) {
	global Object o;
	long l = 0;
	unsigned int i;

	if (str != 0) {
	    if (length str < 17 || str [16] != 0) {
		return 0;
	    }

	    for (i = 0; i < 16; i ++) {
		char c = str [i];

		l <<= 4;
		if (c >= '0' && c <= '9') {
		    l |= c - '0';
		} else if (c >= 'a' && c <= 'f') {
		    l |= c - 'a' + 10;
		} else if (c >= 'A' && c <= 'F') {
		    l |= c - 'A' + 10;
		} else {
		    return 0;
		}
	    }
	    inline "C" {
		o = l;
	    }
	    return o;
	} else {
	    return 0;
	}
    }

    int StrChr (char s [], char c) {
	if (s != 0) {
	    inline "C" {
		char *p;
		char *top;

		top = OZ_ArrayElement (s, char);
		for (p = top; *p; p ++) {
		    if (*p == c)
		      return p - top;
		}
		return -1;
	    }
	} else {
	    return -1;
	}
    }

    int StrRChr (char s [], char c) {
	int r;

	if (s != 0) {
	    inline "C" {
		char *p;

		if ((p = OzStrrchr (OZ_ArrayElement (s, char), c)) != NULL) {
		    r = p - OZ_ArrayElement (s, char);
		} else {
		    r = -1;
		}
	    }
	} else {
	    r = -1;
	}
	return r;
    }
}
