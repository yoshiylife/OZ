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
 * dnsstarter.oz
 *
 * DNS start up configurer
 */

/*
 * 1. Get a domain name from the object manager.
 * 2. Get the domain's root NameDirectory.
 * 3. Get a setup file name (if exists) from console.
 * 4. If not exist, or, not accesible, start a DNS resolver.
 * 5. Set the domain name to the DNS resolver.
 * 6. If exists, setup the DNS resolver by a domain file, otherwise,
 *    set the domain name and the root name directory to the DNS resolver.
 * 7. Add the DNS resolver to the domain's name directory system.
 */

class DNSResolverStarter : LaunchableWithKterm {
  public: Launch;

  protected: IsReady;


    String GetDomainName () {
	String st=>NewFromArrayOfChar (Where ()->WhichDomain ());

	TypeStr ("The domain name of this executor is ");
	TypeString (st);
	TypeReturn ();
	return st;
    }

    global NameDirectory GetRootNameDirectory () {
	global NameDirectory nd = Where ()->GetNameDirectory ();
	String null=>NewFromArrayOfChar ("");

	nd = narrow (NameDirectory, nd->ResponsibleResolver (null));
	TypeStr ("The root name directory of this domain is ");
	TypeOID (nd);
	TypeReturn ();
	return nd;
    }

    String ReadSetupFileName () {
	TypeStr ("If there is a setup file, give me the name.  "
		 "Otherwise, input empty line: ");
	return Trim (Read ());
    }

    void IsReady (global DNSResolver dns, Waiter w) {
	dns->IsReady ();
	w->Done ();
    }

    global DNSResolver SearchDNSResolver (global NameDirectory nd) {
	global DNSResolver dns;
	String dns_name=>NewFromArrayOfChar (":DNS-resolver");

	dns = narrow (DNSResolver, nd->Resolve (dns_name));
	if (dns != 0) {
	    try {
		Waiter w=>New ();

		detach fork IsReady (dns, w);
		detach fork w->Timer (10);
		if (! w->WaitAndTest ()) {
		    nd->RemoveObjectWithName (dns_name);
		    nd->Exclude (dns);
		    dns = 0;
		}
	    } except {
		default {
		    dns = 0;
		}
	    }
	}
	return dns;
    }

    void SetDomainName (global DNSResolver dns, String domain_name) {
	TypeStr ("Setting the domain name of the DNS resolver as ");
	TypeString (domain_name);
	TypeStr (" ... ");
	dns->SetDomainName (domain_name);
	TypeStr ("done.\n");
    }

    global DNSResolver CreateNewDNSResolver (global NameDirectory nd,
					     String domain_name,
					     String setup_file_name) {
	global DNSResolver dns;

	TypeStr ("Creating a new DNS resolver ... ");
	dns=>New ();
	TypeStr ("done.\n");
	SetDomainName (dns, domain_name);
	if (setup_file_name->Length () > 0) {
	    TypeStr ("Reading the setup file ... ");
	    dns->Setup (setup_file_name);
	    TypeStr ("done.\n");
	} else {
	    TypeStr ("Registering the root name directory as this domain's "
		     "NameDirectory ... ");
	    dns->RegisterDomain (domain_name, nd);
	    TypeStr ("done.\n");
	}
	Where ()->PermanentizeObject (dns);
	return dns;
    }

    void Start () {
	try {
	    String domain_name = GetDomainName ();
	    global NameDirectory nd = GetRootNameDirectory ();
	    String setup_file_name = ReadSetupFileName ();
	    global DNSResolver dns = SearchDNSResolver (nd);

	    if (dns == 0) {
		dns = CreateNewDNSResolver (nd, domain_name, setup_file_name);
	    }
	    TypeStr ("A DNS resolver ");
	    TypeOID (dns);
	    TypeStr (" is ready for service.\n");
	} except {
	    default {
		TypeStr ("End with an exception.\n");
	    }
	}
	TypeStr ("Type return to close.\n");
	Read ();
    }

    String Title () {
	String title=>NewFromArrayOfChar ("DNS Resolver Starter");

	return title;
    }
}
