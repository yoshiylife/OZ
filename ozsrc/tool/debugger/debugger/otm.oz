/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//
//
class DebuggerObjectTableManager
{
	char	ClassName[] ;

	/* Object Table Manager */
	char	CmdFlushObject[] ;
	char	CmdFlushObjectWaitingObjectManager[] ;
	char	CmdIsPermanentObject[] ;
	char	CmdIsSuspendedObject[] ;
	char	CmdListObjects[] ;
	char	CmdListObjectsOfStatus[] ;
	char	CmdListLoadedObjects[] ;
	char	CmdListReadyObjects[] ;
	char	CmdListSuspendedObjects[] ;
	char	CmdListSwappedOutObjects[] ;
	char	CmdLoadObject[] ;
	char	CmdLookupObject[] ;
	char	CmdNewObject[] ;
	char	CmdPermanentizeObject[] ;
	char	CmdQueuedInvocation[] ;
	char	CmdRemoveMe[] ;
	char	CmdRemoveObject[] ;
	char	CmdRestoreObject[] ;
	char	CmdSize[] ;
	char	CmdStopObject[] ;
	char	CmdSuspendObject[] ;
	char	CmdResumeObject[] ;
	char	CmdTransientizeObject[] ;
	char	CmdWasSafelyShutdown[] ;
	char	CmdWhichStatus[] ;

void
New()
{
	ClassName = "DebugerObjectTableManager" ;
	CmdFlushObject = "FlushObject" ;
	CmdFlushObjectWaitingObjectManager = "FlushObjectWaitingObjectManager" ;
	CmdIsPermanentObject = "IsPermanentObject" ;
	CmdIsSuspendedObject = "IsSuspendedObject" ;
	CmdListObjects = "ListObjects" ;
	CmdListObjectsOfStatus = "ListObjectsOfStatus" ;
	CmdListLoadedObjects = "ListLoadedObjects" ;
	CmdListReadyObjects = "ListReadyObjects" ;
	CmdListSuspendedObjects = "ListSuspendedObjects" ;
	CmdListSwappedOutObjects = "ListSwappedOutObjects" ;
	CmdLoadObject = "LoadObject" ;
	CmdLookupObject = "LookupObject" ;
	CmdNewObject = "NewObject" ;
	CmdPermanentizeObject = "PermanentizeObject" ;
	CmdQueuedInvocation = "QueuedInvocation" ;
	CmdRemoveMe = "RemoveMe" ;
	CmdRemoveObject = "RemoveObject" ;
	CmdRestoreObject = "RestoreObject" ;
	CmdSize = "Size" ;
	CmdStopObject = "StopObject" ;
	CmdSuspendObject = "SuspendObject" ;
	CmdResumeObject = "ResumeObject" ;
	CmdTransientizeObject = "TransientizeObject" ;
	CmdWasSafelyShutdown = "WasSafelyShutdown" ;
	CmdWhichStatus = "WhichStatus" ;
}

int
Invoke( GUI gui, String rArgs[] )
{
	global ObjectManager	om ;
	char	sArgs[][] ;									// Send arguments
	char	cwin[] ;									// A current window path
	int		i, n ;

	debug( 0, "%S::Invoke()\n", ClassName ) ;
	om = Where() ;

	if ( rArgs ) cwin = rArgs[0]->Content() ;
	else cwin = 0 ;

	if ( gui->CommandIs(CmdFlushObject) ) {
		global Object	obj ;
		if ( length rArgs < 2 ) return( -1 ) ;
		obj = ToOID( rArgs[1] ) ;
		om->FlushObject( obj ) ;
		return( 0 ) ;
	}
	if ( gui->CommandIs(CmdFlushObjectWaitingObjectManager) ) {
		global Object	obj ;
		if ( length rArgs < 2 ) return( -1 ) ;
		obj = ToOID( rArgs[1] ) ;
		om->FlushObjectWaitingObjectManager( obj ) ;
		return( 0 ) ;
	}
	if ( gui->CommandIs(CmdIsPermanentObject) ) {
		global Object	obj ;
		if ( length rArgs < 2 ) return( -1 ) ;
		obj = ToOID( rArgs[1] ) ;
		om->FlushObjectWaitingObjectManager( obj ) ;
		return( 0 ) ;
	}
	if ( gui->CommandIs(CmdIsSuspendedObject) ) {
		return( 1 ) ;
	}
	if ( gui->CommandIs(CmdListObjects) ) {
		return( 1 ) ;
	}
	if ( gui->CommandIs(CmdListObjectsOfStatus) ) {
		return( 1 ) ;
	}
	if ( gui->CommandIs(CmdListLoadedObjects) ) {
		return( 1 ) ;
	}
	if ( gui->CommandIs(CmdListReadyObjects) ) {
		return( 1 ) ;
	}
	if ( gui->CommandIs(CmdListSuspendedObjects) ) {
		return( 1 ) ;
	}
	if ( gui->CommandIs(CmdListSwappedOutObjects) ) {
		return( 1 ) ;
	}
	if ( gui->CommandIs(CmdLoadObject) ) {
		return( 1 ) ;
	}
	if ( gui->CommandIs(CmdLookupObject) ) {
		return( 1 ) ;
	}
	if ( gui->CommandIs(CmdNewObject) ) {
		return( 1 ) ;
	}
	if ( gui->CommandIs(CmdPermanentizeObject) ) {
		return( 1 ) ;
	}
	if ( gui->CommandIs(CmdQueuedInvocation) ) {
		return( 1 ) ;
	}
	if ( gui->CommandIs(CmdRemoveMe) ) {
		return( 1 ) ;
	}
	if ( gui->CommandIs(CmdRemoveObject) ) {
		return( 1 ) ;
	}
	if ( gui->CommandIs(CmdRestoreObject) ) {
		return( 1 ) ;
	}
	if ( gui->CommandIs(CmdSize) ) {
		return( 1 ) ;
	}
	if ( gui->CommandIs(CmdStopObject) ) {
		return( 1 ) ;
	}
	if ( gui->CommandIs(CmdSuspendObject) ) {
		return( 1 ) ;
	}
	if ( gui->CommandIs(CmdResumeObject) ) {
		return( 1 ) ;
	}
	if ( gui->CommandIs(CmdTransientizeObject) ) {
		return( 1 ) ;
	}
	if ( gui->CommandIs(CmdWasSafelyShutdown) ) {
		return( 1 ) ;
	}
	if ( gui->CommandIs(CmdWhichStatus) ) {
		return( 1 ) ;
	}
	return( 1 ) ;
}

} // class DebugerObjectTableManager [otm.oz]
