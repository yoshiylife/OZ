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
class LauncherSS{
 constructor:
  New;
 public:
  Start, OpenCatalogBrowser, ImportPackage, CatalogBrowserQuited;

  /* instance variables */
  LauncherEvaluator LE;
  CatalogBrowserForLauncher   Catalog;

  /* constructors */
  void New() : global{}

  /* public methods */
  void Go() : global{ detach fork Start(); }

  void Start() : global{
    String path, com;
    OText sock;
    char ozroot[];

    if( LE == 0 )
      LE => New();
    if( Catalog == 0 ){
      Catalog => New( oid, ":catalog" );
    }

    path => NewFromArrayOfChar( "wish" );
    LE -> Spawn( path, 0 );
    sock = LE -> GetOText();
    com => NewFromArrayOfChar( "source " );

    length ozroot = 1024;
    inline "C" {
      OzStrcpy( OZ_ArrayElement( ozroot, char ), OzGetenv( "OZROOT" ));
    }
    com = com -> ConcatenateWithArrayOfChar( ozroot );
    com = com -> ConcatenateWithArrayOfChar( "/lib/gui/launcher/launcher4.tcl" );

    sock -> PutLine( com );
    sock -> FlushBuf();
    LE -> EventLoop();
  }

  void ImportPackage( String names[], Package packs[] ) : global {
    School aSchool = packs[ 0 ] -> GetSchool();
//    ConfigurationTable aConfigurationTable = packs[ 0 ] -> GetConfigurationTable();
    global VersionID vid = aSchool -> VersionIDOf( (aSchool -> ListNames() -> AsArray())[ 0 ]);
    ProjectLinkSS current = LE -> GetCurrentProject();
    CIDHolderSS new_class;

    try{
//      String refresh => NewFromArrayOfChar( "refresh_right" );
      new_class => NewFromVid( vid );
      current -> PutLink( names[ 0 ], new_class );
//      LE -> SendEvent( refresh );
      Catalog -> Quit();
    }
    except{
      LauncherExceptions::Duplicate{
        String err => NewFromArrayOfChar( "#This name is already used." );
        LE -> SendEvent( err );
      }
    }        
  }

  void CatalogBrowserQuited() : global{
    String done => NewFromArrayOfChar( "done" );
    LE -> SendEvent( done );
  }

  void OpenCatalogBrowser() : global{
    Catalog -> Launch();
  }
}
