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
 * uds.oz
 *
 * Datagram Socket of Unix Domain
 */

inline "C" {
#include <sys/socket.h>
#include <sys/un.h>
}

class UnixDomainDatagramSocket : UnixDomainUnconnectedSocket {
  constructor: New;
  public: Bind, Close, ReceiveFrom, SendTo;

    void New (char path []) {
	int socket_type;

	inline "C" {
	    socket_type = SOCK_DGRAM;
	}
	CreateSocket (path, socket_type);
    }

    char ReceiveFrom (SocketAddress peer)[] {
	int s = Socket;
	int n;
	char message [], from_addr [];
	int addrlen, sockaddr_len;
	ArrayOfCharOperators acops;

	length message = 1024;
	inline "C" {
	    sockaddr_len = sizeof (struct sockaddr_un);
	}
	length from_addr = sockaddr_len;
	inline "C" {
	    struct sockaddr_un from;

	    addrlen = sockaddr_len;
	    from.sun_family = AF_UNIX;
	    OzRecvfrom (s, OZ_ArrayElement (message, char), 1024, 0,
			(struct sockaddr*)&from, &addrlen);
	    OzMemcpy (OZ_ArrayElement (from_addr, char), &from, addrlen);


	    OzDebugf ("UnixDomainDatagramSocket::ReceiveFrom: "
		      "addrlen = %d, "
		      "from [0] = %x, from [1] = %x, "
		      "from [2] = %x, from [addrlen-1] = %x\n",
		      addrlen, ((unsigned*)&from)[0], ((unsigned*)&from)[1],
		      ((unsigned*)&from)[2], ((unsigned*)&from)[addrlen-1]);


	}
	peer->Set (from_addr, addrlen);
	n = acops.Length (message);
	message [n - 1] = 0;
	return message;
    }

    char SendTo (char message [], SocketAddress peer) {
	int s = Socket;
	char from_addr [] = peer->Address ();
	int addrlen = peer->Length ();
	int res;

	inline "C" {
	    struct sockaddr_un from;
	    char *m = OZ_ArrayElement (message, char);
	    char *p = OZ_ArrayElement (from_addr, char);

	    OzMemcpy (&from, p, addrlen);


	    OzDebugf ("UnixDomainDatagramSocket::SendTo: "
		      "addrlen = %d, "
		      "from [0] = %x, from [1] = %x, "
		      "from [2] = %x, from [addrlen-1] = %x\n",
		      addrlen, ((unsigned*)&from)[0], ((unsigned*)&from)[1],
		      ((unsigned*)&from)[2], ((unsigned*)&from)[addrlen-1]);


	    res = OzSendto (s, m, OzStrlen (m), 0,
			    (struct sockaddr *)&from, addrlen);
	}
	if (res == -1) {
	    raise SocketExceptions::CantSendToSocket (peer);
	}
    }
}
