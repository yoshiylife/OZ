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
