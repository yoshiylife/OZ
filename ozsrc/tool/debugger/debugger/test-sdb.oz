/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class	TestSDB : Launchable
{
public:
	Initialize,
	Launch
;

	DebuggerSchoolDirectoryBrowser	SD ;

void
Initialize()
{
	SD => New() ;
}

void
Launch()
{
	Input	input ;
	String	path, cwd ;
	String	dirs[] ;
	School	school ;
	char	buf[] ;
	int		i, n ;

	input => New( "SchoolDirectory" ) ;

	for (;;) {
		debug( 0, "--- Loop ---\n" ) ;
		buf = input->Get( "Path:" ) ;
		if ( buf == 0 || (i=length buf) == 1 ) {
			/* finish */
			input->Delete() ;
			break ;
		} else if ( i == 2 && buf[0] == '.' ) {
			/* current */
			path => NewFromArrayOfChar( "" ) ;
		} else if ( i == 3 && buf[0] == '.' && buf[1] == '.' ) {
			/* parent */
			path = 0 ;
		} else path => NewFromArrayOfChar( buf ) ;

		try {
			dirs = SD->Chdir( path ) ;
		} except {
			default {
				debug( 0, "Not found such directory\n" ) ;
				continue ;
			}
		}
		cwd = SD->Getcwd() ;
		debug( 0, "%S\n", cwd->Content() ) ;
		if ( dirs ) n = length dirs ;
		else n = 0 ;
		for ( i = 0 ; i < n ; i ++ ) {
			debug( 0, "%S\n", dirs[i]->Content() ) ;
		}
		debug( 0, "Directory Total: %d\n", n ) ;
		try {
			dirs = SD->List() ;
			if ( dirs ) n = length dirs ;
			else n = 0 ;
			for ( i = 0 ; i < n ; i ++ ) {
				debug( 0, "%S\n", dirs[i]->Content() ) ;
			}
			debug( 0, "School Total: %d\n", n ) ;
		} except {
			default {
				input->Delete() ;
				break ;
			}
		}
		try {
			school = SD->Retrieve( path ) ;
			if ( school ) {
				path => NewFromArrayOfChar( "/tmp/school" ) ;
				school->PrintIt ( path ) ;
				debug( 0, "write school to /tmp/school\n" ) ;
			}
		} except {
			default {
				/* nothing */
			}
		}
	}
}

}
