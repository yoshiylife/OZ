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
class ComImport : LauncherCommand{
 constructor:
  New;
 public:
  Execute;

  char MyName()[]{ return "Import"; }

  int Execute( SList args ){
    LauncherEvaluator le = MyEvaluator();
    global ObjectManager om = Where();
    String s, pack_name;
    School aSchool;
    ConfigurationTable aConfigurationTable;
    Package aPackage;
    global VersionID  vid;
    global ConfiguredClassID conf_id;

    try{
      pack_name = args -> Car() -> AsString();
      aPackage = narrow( Catalog, om -> GetNameDirectory() -> Resolve( s => NewFromArrayOfChar( "catalog" ))) -> Retrieve( pack_name );
      aSchool = aPackage -> GetSchool();
      aConfigurationTable = aPackage -> GetConfigurationTable();

      vid = aSchool -> VersionIDOf( (aSchool -> ListNames() -> AsArray())[ 0 ]);
/*      conf_id = ( aConfigurationTable != 0 ) ? aConfigurationTable -> Lookup( vid ) : 0;
      if( conf_id == 0 ){
        conf_id = om -> GetConfiguredClassID( vid, 0 );
      }
*/
      le -> SendEvent( s => OIDtoHexa( vid ));
    }
    except{
      default{
        le -> SendEvent( s => OIDtoHexa( 0 ));
      } 
    }
    return 0;
  }
}
