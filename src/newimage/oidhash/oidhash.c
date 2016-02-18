/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <ctype.h>

void main (int argc, char **argv) {
    if (argc != 3) {
	exit (1);
    } else {
	unsigned int s, n = atoi (argv [2]);
	char* p;

	for (s = 0, p = argv[1]; *p != '\0'; p ++) {
	    s *= 16;
	    if (isdigit (*p)) {
		s += *p - '0';
	    } else if (isxdigit (*p)) {
		if (islower (*p)) {
		    s += *p - 'a' + 10;
		} else if (isupper (*p)) {
		    s += *p - 'A' + 10;
		}
	    } else {
		break;
	    }
	}
	printf ("%d\n", (0x9e3779b9 * s) >> (32 - n) & ((1 << n) - 1));
    }
}
