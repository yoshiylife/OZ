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
 * propagator.oz
 *
 * propagate changes of class interface
 */

/*
 * How to propagate?
 *
 * 1. Collect classes to be propagated.
 * 2. Give new IDs to the classes.
 * 3. Compile them in order.
 *
 * How to collect classes to be propagated?
 *
 * 1. Collect subclasses of the change classes.
 *   1.1 For each class in the school,
 *   1.2 Collect the IDs of superclasses from the public.h.
 *   1.3 Lookup the names of the superclasses in the public.t.
 *   1.4 Compare the collected names to the changed classes and the classes
 *       whose protected I/F is found to be compiled.
 * 2. Collect classes whose public I/F uses the changed classes.
 *   2.1 For each class in the school,
 *   2.2 Search the names of the changed classes and the classes whose public
 *       I/F is found to be compiled in the public.t.  If found and the public
 *       ID of the class in the public.t is not the new version, pick the class
 *       up as the class whose public and protected I/F and implementation are
 *       to be compiled.
 * 3. Collect classes whose protected I/F uses the changed classes.
 *   3.1 For each class in the school,
 *   3.2 Search the names of the changed classes and the classes whose public
 *       I/F is found to be compiled in the protected.t.  If found and the
 *       public ID of the class in the protected.t is not the new version, pick
 *       the class up as the class whose protected I/F and implementation are
 *       to be compiled.
 * 4. Iterate 1, 2, and 3 until no new class was found.
 *    (Don't warry about hidden superclasses: ancestor classes not appeared in
 *    the public.t.  If such a class has changed, direct subclasses of such a
 *    class must be picked up as the classes whose public I/F should be
 *    compiled.)
 * 5. Collect classes which uses the public I/Fs of the changed classes in
 *    their implementation.
 *   5.1 Search the names of the changed classes and the classes whose public
 *       I/F should be compiled in the private.t.  If found and the public ID
 *       of the class in the private.t is not the new version, pick the class
 *       up as the class whose implementation should be compiled.  (Don't warry
 *       about an anonymously accessed classes: used classes not appeared as
 *       typeface (and thus, not in private.t).  Such a class must be appeared
 *       in a public I/F of the other class also used in the class.  Thus,
 *       changing public I/F of such a class cause a compilation of the other
 *       class and eventually some classes in the private.t will be picked up
 *       as the classes whose public I/F must be compiled.  What if the
 *       intermediate classes are not on the school?  Do not configure your
 *       school in such a way!)
 */

class Propagator : CatalogTool (alias Initialize SuperInitialize;) {

/* instance variables */
    SimpleStringTable <PropagatorTableEntry> Table;
    String NamesInTable [];
    char SedCommand [];
    String WorkingDirectory;

/* method implementations */
    /*
     * to do
     *
     * What if some of the compilation or the configuration was failed?
     */

    void Initialize () {
	ArrayOfCharOperators acops;
	FileOperators fops;

	SuperInitialize ();
	Table = 0;
/*
	SedCommand
	  = acops.Concatenate ("../../../",
			       GetPropertyPathName ("read_superclasses"));
*/
	WorkingDirectory=>NewFromArrayOfChar ("propagator-work");
	if (! fops.IsExists (WorkingDirectory)) {
	    fops.MakeDirectory (WorkingDirectory);
	}
    }

    School CollectSubClasses (School school, Set <String> names) {
	School s=>New ();
	unsigned int i, len = length NamesInTable;



	inline "C" {
	    _oz_debug_flag = 1;
	}


	debug {
	    Iterator <String> j;
	    String name;

	    debug (0, "Propagator::CollectSubClasses: names ...\n");
	    for (j=>New (names); (name = j->PostIncrement ());) {
		debug (0, "  %S\n", name->Content ());
	    }
	}

	for (i = 0; i < len; i ++) {
	    String names_in_table = NamesInTable [i];
	    PropagatorTableEntry pte = Table->AtKey (names_in_table);
	    int kind = pte->KindOf ();

	    if ((kind == KindOfClassPart::anOrdinaryClass ||
		 kind == KindOfClassPart::anAbstractClass) &&
		! pte->IsPickedAsPublic ()) {
		String superclasses [] = pte->SuperclassesOf ();
		unsigned int j, len2 = length superclasses;

		for (j = 0; j < len2; j ++) {
		    String name = superclasses [j];

		    debug (0, "Propagator::CollectSubClasses: searching "
			   "%S in %S ... ", name->Content (),
			   names_in_table->Content ());
		    if (names->Includes (name)) {
			if (Table->AtKey (name)->IsPickedAsProtected () ||
			    (pte->PublicTOf ()->ProtectedIDOf (name) !=
			     school->ProtectedIDOf (name))) {
			    pte->PickAsPublic ();
			    SchoolCopy (s, school, names_in_table);
			    debug (0, "found\n");
			    break;
			}
		    }
		    debug (0, "not found\n");
		}
	    }
	}
	return s;
    }

    School CollectPublics (School school, Set <String> names)[] {
	School s [];
	unsigned int i, len = length NamesInTable;

	length s = 2;
	s [0]=>New (); /* for classes */
	s [1]=>New (); /* for records and shares */
	for (i = 0; i < len; i ++) {
	    String names_in_table = NamesInTable [i];
	    PropagatorTableEntry pte = Table->AtKey (names_in_table);

	    if (! pte->IsPickedAsPublic ()) {
		School pubt = pte->PublicTOf ();
		Set <String> set = pubt->ListNames ();
		unsigned int len2 = set->Size ();
		Iterator <String> j;
		String name;

		for (j=>New (set); (name = j->PostIncrement ()) != 0;) {
		    if (names->Includes (name)) {
			if (Table->AtKey (name)->IsPickedAsPublic () ||
			    (pubt->PublicIDOf (name)
			     != school->PublicIDOf (name))) {
			    int kind = pte->KindOf ();

			    pte->PickAsPublic ();

			    if (kind == KindOfClassPart::anOrdinaryClass ||
				kind == KindOfClassPart::anAbstractClass) {
				SchoolCopy (s [0], school, names_in_table);
			    } else {
				SchoolCopy (s [1], school, names_in_table);
			    }
			    break;
			}
		    }
		}
	    }
	}
	return s;
    }

    School CollectProtected (School school, Set <String> names) {
	School s=>New ();
	unsigned int i, len = length NamesInTable;

	for (i = 0; i < len; i ++) {
	    String names_in_table = NamesInTable [i];
	    PropagatorTableEntry pte = Table->AtKey (names_in_table);
	    int kind = pte->KindOf ();

	    if ((kind == KindOfClassPart::anOrdinaryClass ||
		 kind == KindOfClassPart::anAbstractClass) &&
		! pte->IsPickedAsProtected ()) {
		School prott = pte->ProtectedTOf ();
		Set <String> set = prott->ListNames ();
		unsigned int len2 = set->Size ();
		Iterator <String> j;
		String name;

		for (j=>New (set); (name = j->PostIncrement ()) != 0;) {
		    if (names->Includes (name)) {
			if (Table->AtKey (name)->IsPickedAsPublic () ||
			    (prott->PublicIDOf (name) !=
			     school->PublicIDOf (name))) {
			    pte->PickAsProtected ();
			    SchoolCopy (s, school, names_in_table);
			    break;
			}
		    }
		}
	    }
	}
	return s;
    }

    School CollectImplementation (School school, global Class c,
				  Set <String> names) {
	School s=>New ();
	unsigned int i, len = length NamesInTable;

	for (i = 0; i < len; i ++) {
	    String names_in_table = NamesInTable [i];
	    PropagatorTableEntry pte = Table->AtKey (names_in_table);
	    int kind = pte->KindOf ();

	    if ((kind == KindOfClassPart::anOrdinaryClass ||
		 kind == KindOfClassPart::anAbstractClass) &&
		! pte->IsPickedAsImplementation ()) {
		School privt
		  = LoadDotT (c, school->ImplementationIDOf (names_in_table),
			      "private.t");
		Set <String> set = privt->ListNames ();
		unsigned int len2 = set->Size ();
		Iterator <String> j;
		String name;

		for (j=>New (set); (name = j->PostIncrement ()) != 0;) {
		    if (names->Includes (name)) {
			if (Table->AtKey (name)->IsPickedAsPublic () ||
			    (privt->PublicIDOf (name) !=
			     school->PublicIDOf (name))) {
			    pte->PickAsImplementation ();
			    SchoolCopy (s, school, names_in_table);
			    break;
			}
		    }
		}
	    }
	}
	return s;
    }

    School Calculate (School school, global Class c,
		      Set <String> public_names, Set <String> prot_names)
      [] {
	  School compilee [], new [], tmp [];
	  SimpleArray <global VersionID> oldpubs, oldprots;
	  char exp [];
	  int flag = 0;
	  Set <String> names [];

	  public_names->AddContentsTo (prot_names);

	  length compilee = 4;
	  compilee [0]=>New (); /* for public (class) */
	  compilee [1]=>New (); /* for protected */
	  compilee [3]=>New (); /* for public (records and shares) */
	  length new = 3;
	  length names = 3;

	  new [0] = CollectSubClasses (school, prot_names);
	  tmp = CollectPublics (school, public_names);
	  SchoolAdd (new [0], tmp [0]);
	  new [2] = tmp [1];
	  new [1] = CollectProtected (school, public_names);
	  flag
	    = (new [0]->Size () > 0) || (new [1]->Size () > 0) ||
	      (new [2]->Size () > 0);

	  while (flag) {
	      flag = 0;

	      names [0] = new [0]->ListNames ();
	      names [1] = new [1]->ListNames ();
	      names [2] = new [2]->ListNames ();
	      names [0]->AddContentsTo (names [1]);
	      names [2]->AddContentsTo (names [0]);
	      SchoolAdd (compilee [0], new [0]);
	      SchoolAdd (compilee [1], new [1]);
	      SchoolAdd (compilee [3], new [2]);
	      new [0] = CollectSubClasses (school, names [1]);
	      tmp = CollectPublics (school, names [0]);
	      SchoolAdd (new [0], tmp [0]);
	      new [2] = tmp [1];
	      new [1] = CollectProtected (school, names [0]);
	      flag
		= (new [0]->Size () > 0) || (new [1]->Size () > 0) ||
		  (new [2]->Size () > 0);
	  }
	  compilee [0]->ListNames ()->AddContentsTo (public_names);
	  compilee [3]->ListNames ()->AddContentsTo (public_names);

	  compilee [2] = CollectImplementation (school, c, public_names);
	  return compilee;
      }

    SimpleArray <global VersionID>
      CollectProtectedID (global Class c, global VersionID rootid) {
	  SimpleArray <global VersionID> vids=>New ();

	  global VersionID pubids [] = c->GetLowerVersions (rootid);
	  unsigned int i, len = length pubids;

	  for (i = 0; i < len; i ++) {
	      global VersionID protids [] = c->GetLowerVersions (pubids [i]);
	      unsigned int j, len2 = length protids;

	      for (j = 0; j < len2; j ++) {
		  vids->Add (protids [j]);
	      }
	  }
	  return vids;
      }

    int CanCompilePublic (String name, School compilee) {
	/*
	 * If one of ancestor classes of the class "name" appears in
	 * compilee, "name" cannot be compiled.
	 */
	String superclasses [] = Table->AtKey (name)->SuperclassesOf ();
	unsigned int i, len = length superclasses;

	for (i = 0; i < len; i ++) {
	    if (compilee->Includes (superclasses [i])) {
		return 0;
	    }
	}
	return 1;
    }

    int CompareFromTo (char s1 [], unsigned int from1,
		       char s2 [], unsigned int from2, int len) {
	unsigned int len1 = length s1, len2 = length s2, p1, p2;

	for (p1 = from1, p2 = from2;
	     p1 < len1 && p2 < len2 && p1 - from1 < len; p1 ++, p2 ++) {
	    int result = s1 [p1] - s2 [p2];

	    if (result != 0) {
		return result;
	    }
	}
	if (p1 - from1 == len) {
	    return 0;
	} else if (p1 < len1) {
	    return -1;
	} else {
	    return 1;
	}
    }

    void Compile (School compilee [], School school, global Class c) {
	char path [] = PrintSchoolFile (school);
	UnixIO cfed;
	Set <String> names;
	Iterator <String> i;
	String name;



	inline "C" {
	    _oz_debug_flag = 1;
	}


	SchoolDelete (compilee [1], compilee [0]);
	SchoolDelete (compilee [2], compilee [0]);
	SchoolDelete (compilee [2], compilee [1]);
	try {
	    cfed = SpawnCFED (c, path);
	    while (compilee [0]->Size () > 0 || compilee [1]->Size () > 0) {
		if (compilee [1]->Size () > 0) {
		    names = compilee [1]->ListNames ();
		    for (i=>New (names); (name = i->PostIncrement ()) != 0;) {
			debug (0, "Propagator::Compile: protected of %S\n",
			       name->Content ());
			CompileOne (compilee [1]->ImplementationIDOf (name),
				    school->ProtectedIDOf (name), "protected",
				    c, cfed);
			SchoolMove (compilee [2], compilee [1], name);
		    }
		}
		if (compilee [0]->Size () > 0) {
		    names = compilee [0]->ListNames ();
		    for (i=>New (names); (name = i->PostIncrement ()) != 0;) {
			if (CanCompilePublic (name, compilee [0])) {
			    debug (0, "Propagator::Compile: public of %S\n",
				   name->Content ());
			    CompileOne (compilee[0]->ImplementationIDOf (name),
					school->PublicIDOf (name), "public",
					c, cfed);
			    SchoolMove (compilee [1], compilee [0], name);
			}
		    }
		}
	    }
	    CompileRecordsAndShares (compilee [3], school, c, cfed);
	    CompileImplementations (compilee [2], school, c, cfed);
	    Configure (compilee, school, c, cfed);
	    cfed->PutStr ("quit\n");
	    cfed->Close ();
	} except {
	    default {
		cfed->PutStr ("quit\n");
		cfed->Close ();
		raise;
	    }
	}
    }

    void CompileImplementations (School compilee, School school,
				 global Class c, UnixIO cfed) {
	Set <String> names = compilee->ListNames ();
	Iterator <String> i;
	String name;



	inline "C" {
	    _oz_debug_flag = 1;
	}


	for (i=>New (names); (name = i->PostIncrement ()) != 0;) {
	    global VersionID implid = compilee->ImplementationIDOf (name);

	    debug (0, "Propagator::CompileImplementations: %S\n",
		   name->Content ());
	    CompileOne (implid, school->ImplementationIDOf (name), "private",
			c, cfed);
	}
    }

    void CompileOne (global VersionID implid, global VersionID target,
		     char part [], global Class c, UnixIO cfed) {
	char path [] = CopySourceFile (implid)->Content ();
	ArrayOfCharOperators acops;

	cfed
	  ->PutStr ("compile ")
	    ->PutStr (acops.Concatenate ("../../../", path))
	      ->PutStr (" ")->PutStr (part)->PutReturn ();
	ReadAnswer (cfed);
	c->RegisterClassInformations (target);
    }

    void CompileRecordsAndShares (School compilee, School school,
				  global Class c, UnixIO cfed) {
	Set <String> names = compilee->ListNames ();
	Iterator <String> i;
	String name;



	inline "C" {
	    _oz_debug_flag = 1;
	}


	for (i=>New (names); (name = i->PostIncrement ()) != 0;) {
	    global VersionID implid = compilee->PublicIDOf (name);

	    debug (0, "Propagator::CompileRecordsAndShares: %S (%O)\n",
		   name->Content (), implid);
	    CompileOne (implid, school->PublicIDOf (name), "all", c, cfed);
	}
    }

    void Configure (School compilee [], School school,
		    global Class c,UnixIO cfed) {
	ConfigureEach (compilee [0], school, c, cfed);
	ConfigureEach (compilee [1], school, c, cfed);
	ConfigureEach (compilee [2], school, c, cfed);
    }

    void ConfigureEach (School compilee, School school, global Class c,
			UnixIO cfed) {
	Set <String> names = compilee->ListNames ();
	Iterator <String> i;
	String name;
	global VersionID pubid;
	global ConfiguredClassID new_ccid;
	global ObjectManager om = Where ();



	inline "C" {
	    _oz_debug_flag = 1;
	}


	for (i=>New (names); (name = i->PostIncrement ()) != 0;) {
	    int kind = compilee->KindOf (name);

	    if (kind == KindOfClassPart::anOrdinaryClass ||
		kind == KindOfClassPart::anAbstractClass) {
		pubid = school->PublicIDOf (name);
		new_ccid = c->CreateNewConfiguredClass (pubid);
		debug (0, "Propagator::Configure: %S:(%O %O)=>(%O %O)\n",
		       name->Content (), pubid,
		       c->GetDefaultConfiguredClassID (pubid), pubid,new_ccid);
		cfed->PutStr ("sb ")->PutString (name)
		  ->PutStr (" 9 ")->PutOID (new_ccid)->PutReturn ();
		ReadAnswer (cfed);
		cfed->PutStr ("config ")->PutString (name)->PutReturn ();
		ReadAnswer (cfed);
		c->RegisterClassInformations (new_ccid);
		c->SetDefaultConfiguredClassID (pubid, new_ccid);
		om->ChangeConfigurationCache (pubid, new_ccid);
	    }
	}
    }

    String CopySourceFile (global VersionID implid) {
	FileOperators fops;
	String vid_str=>OIDtoHexa (implid);
	String orig_path, to_path;

	orig_path=>NewFromArrayOfChar ("../classes/");
	orig_path = orig_path->Concatenate (vid_str);
	orig_path = orig_path->ConcatenateWithArrayOfChar ("/private.oz");

	to_path = WorkingDirectory;
	to_path = to_path->ConcatenateWithArrayOfChar ("/");
	to_path = to_path->Concatenate (vid_str);
	to_path = to_path->ConcatenateWithArrayOfChar (".oz");

	fops.Copy (orig_path, to_path);
	return to_path;
    }

    void CreateNewParts (School compilee [], global Class c, School school) {
	CreatePublicParts (compilee [0], c, school);
	CreateProtectedParts (compilee [1], c, school);
	CreateImplementationParts (compilee [2], c, school);
	CreateRecordsAndShares (compilee [3], c, school);
    }

    void CreateImplementationParts (School set, global Class c, School school){
	Set <String> names = set->ListNames ();
	Iterator <String> i;
	String name;



	inline "C" {
	    _oz_debug_flag = 1;
	}


	for (i=>New (names); (name = i->PostIncrement ()) != 0;) {
	    int kind = set->KindOf (name);
	    global VersionID pubid = set->PublicIDOf (name);
	    global VersionID protid = set->ProtectedIDOf (name);
	    global VersionID new_implid = c->CreateNewPart (protid);

	    school->ChangeValue (name, kind, pubid, protid, new_implid);
	    debug {
		global VersionID implid = set->ImplementationIDOf (name);
		debug (0, "Propagator::CreateImplementationParts "
		       "%S %d %O %O:(%O)=>(%O)\n",
		       name->Content (), kind, pubid, protid, implid,
		       new_implid);
	    }
	}
    }

    void CreateProtectedParts (School set, global Class c, School school){
	Set <String> names = set->ListNames ();
	Iterator <String> i;
	String name;



	inline "C" {
	    _oz_debug_flag = 1;
	}


	for (i=>New (names); (name = i->PostIncrement ()) != 0;) {
	    int kind = set->KindOf (name);
	    global VersionID pubid = set->PublicIDOf (name);
	    global VersionID new_protid = c->CreateNewPart (pubid);
	    global VersionID new_implid = c->CreateNewPart (new_protid);

	    school->ChangeValue (name, kind, pubid, new_protid, new_implid);
	    debug {
		global VersionID protid = set->ProtectedIDOf (name);
		global VersionID implid = set->ImplementationIDOf (name);
		debug (0, "Propagator::CreateProtectedParts "
		       "%S %d %O:(%O %O)=>(%O %O)\n",
		       name->Content (), kind, pubid, protid, implid,
		       new_protid, new_implid);
	    }
	}
    }

    void CreatePublicParts (School set, global Class c, School school) {
	Set <String> names = set->ListNames ();
	Iterator <String> i;
	String name;



	inline "C" {
	    _oz_debug_flag = 1;
	}


	for (i=>New (names); (name = i->PostIncrement ()) != 0;) {
	    int kind = set->KindOf (name);
	    global VersionID pubid = set->PublicIDOf (name);
	    global VersionID rootid = c->GetRootPart (pubid);
	    global VersionID new_pubid = c->CreateNewPart (rootid);
	    global VersionID new_protid = c->CreateNewPart (new_pubid);
	    global VersionID new_implid = c->CreateNewPart (new_protid);

	    school->ChangeValue (name, kind, new_pubid, new_protid,new_implid);
	    debug {
		global VersionID protid = set->ProtectedIDOf (name);
		global VersionID implid = set->ImplementationIDOf (name);
		debug (0, "Propagator::CreatePublicParts "
		       "%S %d %O:(%O %O %O)=>(%O %O %O)\n",
		       name->Content (), kind, rootid, pubid, protid, implid,
		       new_pubid, new_protid, new_implid);
	    }
	}
    }

    void CreateRecordsAndShares (School set, global Class c, School school) {
	Set <String> names = set->ListNames ();
	Iterator <String> i;
	String name;



	inline "C" {
	    _oz_debug_flag = 1;
	}


	for (i=>New (names); (name = i->PostIncrement ()) != 0;) {
	    int kind = set->KindOf (name);
	    global VersionID pubid = set->PublicIDOf (name);
	    global VersionID rootid = c->GetRootPart (pubid);
	    global VersionID new_pubid = c->CreateNewPart (rootid);

	    school->ChangeValue (name, kind, new_pubid, 0, 0);
	    debug {
		global VersionID protid = set->ProtectedIDOf (name);
		global VersionID implid = set->ImplementationIDOf (name);
		debug (0, "Propagator::CreateRecordsAndShares "
		       "%S %d %O:(%O)=>(%O)\n",
		       name->Content (), kind, rootid, pubid, new_pubid);
	    }
	}
    }

    void Do (School school, global Class c) {
	Set <String> public_names, protected_names;
	School compilee [];

	TypeStr ("Which classes did you changed ?\n");
	TypeStr ("    Enter class names deliminating with blank.\n");
	TypeStr ("    Quote by a pair of `\"'s ");
	TypeStr ("if the class name includes blanks.\n");
	TypeStr ("    Any number of class names can be written in 1 line.\n");
	TypeStr ("    Type empty line to stop input.\n");
	public_names
	  = ReadNames ("  Classes changed in their public interface: ");
	protected_names
	  = ReadNames ("  Classes changed in their protected interface: ");
	if (public_names->Size () == 0 && protected_names->Size () == 0) {
	    TypeStr ("No class has changed.\n");
	} else {
	    SetupTable (school, c);
	    compilee = Calculate (school, c, public_names, protected_names);
	    PrintCompileSet (compilee);
	    if (MakeConfirm ()) {
		CreateNewParts (compilee, c, school);
		Compile (compilee, school, c);
		ExportToCatalog (school);
	    }
	    Table = 0;
	}
    }

    void ExportToCatalog (School school) {
	global Catalog catalog = GetCatalog ();
	Package package=>New ();
	String ans;
	int finished = 0;

	package->SetSchool (school);
	while (! finished) {
	    TypeStr ("Enter the package name to export new package: ");
	    ans = Trim (Read ());
	    try {
		if (ans == 0 || ans->Length () == 0) {
		    TypeStr ("Abort this procedure? (y/n) [y] ");
		    if (ReadYN (1)) {
			finished = 1;
		    }
		} else if (catalog->IsaDirectory (ans)) {
		    TypeStr ("Cannot override a directory.\n");
		} else if (catalog->ListPackage (ans)->Size () > 0) {
		    TypeStr ("Package ");
		    TypeStr (ans->Content ());
		    TypeStr (" exists.  Override? (y/n) [y] ");
		    if (ReadYN (1)) {
			catalog->Remove (ans);
			catalog->Register (ans, package);
			finished = 1;
		    }
		} else {
		    catalog->Register (ans, package);
		    finished = 1;
		}
	    } except {
		default {
		    TypeStr ("Some error was occurred during registration ");
		    TypeStr ("to catalog.  Try again? (y/n) [y] ");
		    if (! ReadYN (1)) {
			finished = 1;
		    }
		}
	    }
	}
    }

    School LoadDotT (global Class c, global VersionID pubid, char name []) {
	String path=>NewFromArrayOfChar (c->GetClassInformations (pubid));
	School s;

	path = path->ConcatenateWithArrayOfChar ("/");
	path = path->ConcatenateWithArrayOfChar (name);
	return s=>Load (path);
    }

    String LoadSuperclasses (global Class c, global VersionID pubid,
			     School pubt)
      [] {
	  String path=>NewFromArrayOfChar (c->GetClassInformations (pubid));
	  Stream file;
	  String ans []; /* For performance, we don't use container class. */
	  unsigned int ansp = 0, ansmax = 2;
	  ArrayOfCharOperators acops;
	  Set <String> names = pubt->ListNames ();

	  length ans = ansmax;
	  path = path->ConcatenateWithArrayOfChar ("/public.h");
	  file=>New (path);
	  while (! file->IsEndOfFile ()) {
	      if (acops.IsEqual (file->GetS (), "/* inherited classes\n")) {
		  break;
	      }
	  }
	  if (file->IsEndOfFile ()) {
	      EOFToken token=>New ();

	      raise FileReaderExceptions::SyntaxError (token);
	  }
	  while (! file->IsEndOfFile ()) {
	      char buf [];
	      global VersionID vid;
	      Iterator <String> i;
	      String name;

	      buf = file->GetS ();
	      if (acops.IsEqual (buf, "*/\n")) {
		  break;
	      }
	      buf [length buf - 2] = 0;
	      vid = narrow (VersionID, acops.Str2OID (buf));
	      if (vid == 0) {
		  OIDToken token=>New (0LL);

		  raise FileReaderExceptions::SyntaxError (token);
	      }

	      for (i=>New (names); (name = i->PostIncrement ()) != 0;) {
		  if (pubt->ProtectedIDOf (name) == vid) {
		      if (ansp == ansmax) {
			  ansmax *= 2;
			  length ans = ansmax;
		      }
		      ans [ansp ++] = name;
		      break;
		  }
	      }
	  }
	  if (file->IsEndOfFile ()) {
	      EOFToken token=>New ();

	      raise FileReaderExceptions::SyntaxError (token);
	  }
	  length ans = ansp;
	  return ans;
      }

/*
    String LoadSuperclasses (global Class c, global VersionID pubid,
			     School pubt)
      [] {
	  UnixIO sed = SpawnSedScript (c, pubid);
	  SimpleArray <global VersionID> vids
	    = ReadObjectIDsFromSedScript (sed);
	  unsigned int i, len = vids->Size ();
	  Set <String> names = pubt->ListNames ();
	  SimpleArray <String> ans=>New ();

	  sed->Close ();
	  for (i = 0; i < len; i ++) {
	      global VersionID vid = vids->At (i);
	      Iterator <String> j;
	      String name;

	      for (j=>New (names); (name = j->PostIncrement ()) != 0;) {
		  if (pubt->ProtectedIDOf (name) == vid) {
		      ans->Add (name);
		      break;
		  }
	      }
	  }
	  return ans->AsArray ();
      }
*/

    int MakeConfirm () {
	TypeStr ("Continue ? (y/n) [y] ");
	return ReadYN (1);
    }

    void PrintClassNameList (School school) {
	Set <String> set = school->ListNames ();
	Iterator <String> i;
	String st;

	for (i=>New (set); (st = i->PostIncrement ());) {
	    TypeString (st);
	    TypeReturn ();
	}
    }

    void PrintCompileSet (School compilee []) {
	TypeStr ("To be compiled from new public version:\n");
	PrintClassNameList (compilee [0]);
	TypeReturn ();
	TypeStr ("To be compiled from new protected version:\n");
	PrintClassNameList (compilee [1]);
	TypeReturn ();
	TypeStr ("To be compiled from new implementation version:\n");
	PrintClassNameList (compilee [2]);
	TypeReturn ();
	TypeStr ("Records and Shares To be compiled:\n");
	PrintClassNameList (compilee [3]);
	TypeReturn ();
    }

    char PrintSchoolFile (School school)[] {
	String st;
	char path [];

	length path = 11;
	inline "C" {
	    OzSprintf (OZ_ArrayElement (path, char), "sf%x", self);
	}
	school->PrintIt (st=>NewFromArrayOfChar (path));
	return path;
    }

    void ReadAnswer (UnixIO cfed) {
	char buf [];
	ArrayOfCharOperators acops;

	length buf = 0;
	while (1) {
	    char tmp [] = cfed->Read (1023);
	    if (tmp == 0) {
		return;
	    }
	    if (tmp [1022] != 0) {
		length tmp = 1024;
	    }
	    buf = acops.Concatenate (buf, tmp);
	    if (acops.Length (buf) >= 14) {
		break;
	    }
	}
	if (acops.Compare (buf, "TCL:Success:1\n")) {
	    return;
	} else {
	    unsigned int bufp = 0;

	    while (CompareFromTo (buf, bufp, "TCL:Success:", 0, 12) !=0){
		while (buf [bufp ++] != '\n') {
		    if (buf [bufp] == 0) {
			TypeStr (buf);
			buf = cfed->Read (1023);
			bufp = 0;
			if (buf [1022] != 0) {
			    length buf = 1024;
			}
			break;
		    }
		}
	    }
	    TypeStr (buf);
	    raise Abort;
	}
    }

    char ReadFromSedScript (UnixIO sed, int len)[] {
	char buf [];
	int n;
	ArrayOfCharOperators acops;

	buf = sed->Read (len);
	if (buf != 0) {
	    length buf = len + 1;
	    n = acops.Length (buf);
	} else {
	    return 0;
	}
	while (n < len) {
	    char tmp [];

	    tmp = sed->Read (len - n);
	    length tmp = len - n + 1;
	    if (acops.Length (tmp) == 0) {
		break;
	    } else {
		buf = acops.Concatenate (buf, tmp);
		n = acops.Length (buf);
	    }
	}
	if (n != len) {
	    length buf = n + 1;
	}
	return buf;
    }

    Set <String> ReadNames (char msg []) {
	String st;
	unsigned int i, len, angle;
	Set <String> set=>New ();
	int finished = 0, start, initial, quoted, state;



	inline "C" {
	    _oz_debug_flag = 1;
	}


	while (! finished) {
	    try {
		TypeStr (msg);
		st = Read ();
		len = st->Length ();

		initial = 1;
		state = 0;
		quoted = 0;
		angle = 0;
		for (start = 0, i = 0; i < len; i ++) {
		    char c = st->At (i);

		    if (state) {
			switch (c) {
			  case ' ':
			  case '\t':
			  case '\n':
			    if (quoted) {
				if (c == '\n') {
				    raise Abort;
				}
			    } else {
				if (angle == 0) {
				    set->Add (st->GetSubString (start,
								i - start));
				    debug (0, "Propagator::ReadNames: "
					   "Adding %S\n",
					   st->GetSubString (start,
							     i - start)
					   ->Content ());
				    state = 0;
				} else {
				    raise Abort;
				}
			    }
			    break;
			  case '\"':
			    if (quoted) {
				if (angle == 0) {
				    set->Add (st->GetSubString (start,
								i - start));
				    debug (0, "Propagator::ReadNames: "
					   "Adding %S\n",
					   st->GetSubString (start,
							     i - start)
					   ->Content ());
				    quoted = 0;
				    state = 0;
				} else {
				    raise Abort;
				}
			    } else {
				raise Abort;
			    }
			    break;
			  case '<':
			    ++ angle;
			    break;
			  case '>':
			    -- angle;
			    break;
			  default:
			    if (! quoted && ! IsAlphanumeric (c) && c != ':') {
				raise Abort;
			    }
			    break;
			}
		    } else {
			switch (c) {
			  case ' ':
			  case '\t':
			    if (quoted) {
				start = i;
				state = 1;
				initial = 0;
			    }
			    break;
			  case '\n':
			    if (quoted) {
				raise Abort;
			    } else if (initial) {
				finished = 1;
			    }
			    break;
			  case '\"':
			    if (quoted) {
				raise Abort;
			    } else {
				quoted = 1;
			    }
			    break;
			  default:
			    if (quoted || IsAlphabet (c)) {
				start = i;
				state = 1;
				initial = 0;
			    } else {
				raise Abort;
			    }
			    break;
			}
		    }
		}
	    } except {
		Abort {
		    TypeStr ("Invalid character at ");
		    TypeInt (i);
		    TypeReturn ();
		}
		default {
		    raise;
		}
	    }
	}
	return set;
    }

    SimpleArray <global VersionID> ReadObjectIDsFromSedScript (UnixIO sed) {
	SimpleArray <global VersionID> ans=>NewWithSize (2);
	unsigned int n;
	char buf [];

	inline "C" {
	    _oz_debug_flag = 1;
	}

	while (((buf = ReadFromSedScript (sed, 17)), (n = length buf) > 0)) {
	    global VersionID vid;
	    ArrayOfCharOperators acops;

	    if (n < 18) {
		break;
	    }
	    buf [16] = 0;
	    vid = narrow (VersionID, acops.Str2OID (buf));
	    if (vid == 0) {
		debug (0,
		       "Propagator::ReadObjectIDsFromSedScript "
		       "illegal OID from script `%S'\n", buf);
		raise Abort;
	    }
	    ans->Add (vid);
	}
	if (n > 0) {
	    debug (0,
		   "Propagator::ReadObjectIDsFromSedScript: "
		   "extra output from script \"%S\"\n", buf);
	    raise Abort;
	}
	return ans;
    }

    void SchoolAdd (School s1, School s2) {
	Set <String> names;
	Iterator <String> i;
	String name;

	if (s2 == 0 || s2->Size () == 0) {
	    return;
	}

	names = s2->ListNames ();
	for (i=>New (names); (name = i->PostIncrement ()) != 0;) {
	    SchoolCopy (s1, s2, name);
	}
    }

    void SchoolCopy (School to, School from, String key) {
	if (to->Includes (key)) {
	    to->Remove (key);
	} 
	{
	    unsigned int kind = from->KindOf (key);
	    global VersionID pubid = from->PublicIDOf (key);
	    global VersionID protid = from->ProtectedIDOf (key);
	    global VersionID implid = from->ImplementationIDOf (key);

	    to->NewEntry (key->Content (), kind, pubid, protid, implid);
	}
    }

    void SchoolDelete (School from, School school) {
	Set <String> names = school->ListNames ();
	Iterator <String> i;
	String name;

	for (i=>New (names); (name = i->PostIncrement ()) != 0;) {
	    if (from->Includes (name)) {
		from->Remove (name);
	    }
	}
    }

    void SchoolMove (School to, School from, String key) {
	SchoolCopy (to, from, key);
	from->Remove (key);
    }

    void SetupTable (School school, global Class c) {
	unsigned int i, len = school->Size ();

	inline "C" {
	    _oz_debug_flag = 1;
	}

	Table=>NewWithSize (len);
	NamesInTable = school->ListNames ()->AsArray ();

	for (i = 0; i < len; i ++) {
	    String name = NamesInTable [i];
	    PropagatorTableEntry pte=>New (name);
	    int kind = school->KindOf (name);
	    global VersionID pubid = school->PublicIDOf (name);
	    School s;

	    debug (0, "Propagator::SetupTable: name = %S\n", name->Content ());
	    pte->SetKind (kind);
	    s = LoadDotT (c, pubid, "public.t");
	    pte->SetPublicT (s);
	    if (kind == KindOfClassPart::anOrdinaryClass ||
		kind == KindOfClassPart::anAbstractClass) {
		pte->SetSuperclasses (LoadSuperclasses (c, pubid, s));
		pte->SetProtectedT (LoadDotT (c, school->ProtectedIDOf (name),
					      "protected.t"));
	    }
	    Table->Add (name, pte);
	}
    }

    UnixIO SpawnCFED (global Class c, char path []) {
	UnixIO cfed;
	char argv [][];

	length argv = 6;
	argv [0] = "cfed";
	argv [1] = "-at";
	argv [2] = "-c";
	argv [3] = c->GetClassDirectoryPath ();
	argv [4] = "-s";
	argv [5] = path;
	cfed=>Spawn (argv);
	return cfed;
    }

    UnixIO SpawnSedScript (global Class c, global VersionID pubid) {
	UnixIO sed;
	char argv [][];
	ArrayOfCharOperators acops;

	length argv = 2;
	argv [0] = SedCommand;
	argv [1] = acops.Concatenate ("../../../",
				      c->GetClassInformations (pubid));
	sed=>Spawn (argv);
	return sed;
    }

    String Title () {
	String title=>NewFromArrayOfChar ("Automatic Version-up Propagator");

	return title;
    }
}
