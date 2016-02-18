/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _EXEC_FUNCTION_NAME_H_
#define _EXEC_FUNCTION_NAME_H_

#ifdef OLD_EXEC_IF
#define ALLOCATE_LOCAL_OBJECT "OzExecAllocateLocalObject"
#define GET_OID "OzGetOID"

#define EID_CMP "OZEidcmp"
#define INITIALIZE_EXCEPTION_HANDLER "OzInitializeExceptionHandler"
#define REGISTER_EXCEPTION_HANDLER_FOR "OzExecRegisterExceptionHandlerFor"
#define UNREGISTER_EXCEPTION_HANDLER "OzExecUnregisterExceptionHandler"
#define RAISE "OzExecRaise"
#define RE_RAISE "OzExecReRaise"
#define HANDLING_EXCEPTION "OzHandlingException"

#define GLOBAL_INVOKE "OzGlobalInvoke"

#define GET_METHOD_IMPLEMENTATION "OzExecGetMethodImplementation"
#define FIND_METHOD_IMPLEMENTATION "OzExecFindMethodImplementation"
#define FREE_METHOD_IMPLEMENTATION "OzExecFreeMethodImplementation"

#define INITIALIZE_CONDITION "OzInitializeCondition"
#define ENTER_MONITOR "OzEnterMonitor"
#define EXIT_MONITOR "OzExitMonitor"
#define WAIT_CONDITION "OzWaitCondition"
#define WAIT_CONDITION_WITH_TIMEOUT "OzWaitConditionWithTimeout"
#define SIGNAL_CONDITION "OzSignalCondition"
#define SIGNAL_CONDITION_ALL "OzSignalConditionAll"

#define FORK_PROCESS "OzForkProcess"
#define DETACH_PROCESS "OzDetachProcess"
#define JOIN_PROCESS "OzJoinProcess"
#define ABORT_PROCESS "OzAbortProcess"

#define THREAD_SHOULD_BE_ABORTED "OzThreadShouldBeAborted"
#else
#define ALLOCATE_STATIC_OBJECT "OzExecAllocateStaticObject"
#define ALLOCATE_RE_ALLOCATE_ARRAY "OzExecReAllocateArray"
#define ALLOCATE_LOCAL_OBJECT "OzExecAllocateLocalObject"
#define GET_DEFAULT_CONFIGURATION "OzExecGetConfigID"
#define GET_OID "OzExecGetOID"

#define EID_CMP "OzExecEidcmp"
#define INITIALIZE_EXCEPTION_HANDLER "OzExecInitializeExceptionHandler"
#define REGISTER_EXCEPTION_HANDLER_FOR "OzExecRegisterExceptionHandlerFor"
#define UNREGISTER_EXCEPTION_HANDLER "OzExecUnregisterExceptionHandler"
#define RAISE "OzExecRaise"
#define RE_RAISE "OzExecReRaise"
#define HANDLING_EXCEPTION "OzExecHandlingException"
#define PUT_EID_INTO_CATCH_TABLE "OzExecPutEidIntoCatchTable"

#define GLOBAL_INVOKE "OzExecGlobalInvoke"

#define GET_METHOD_IMPLEMENTATION "OzExecGetMethodImplementation"
#define FIND_METHOD_IMPLEMENTATION "OzExecFindMethodImplementation"
#define FREE_METHOD_IMPLEMENTATION "OzExecFreeMethodImplementation"

#define INITIALIZE_CONDITION "OzExecInitializeCondition"
#define ENTER_MONITOR "OzExecEnterMonitor"
#define EXIT_MONITOR "OzExecExitMonitor"
#define WAIT_CONDITION "OzExecWaitCondition"
#define WAIT_CONDITION_WITH_TIMEOUT "OzExecWaitConditionWithTimeout"
#define SIGNAL_CONDITION "OzExecSignalCondition"
#define SIGNAL_CONDITION_ALL "OzExecSignalConditionAll"

#define FORK_PROCESS "OzExecForkProcess"
#define DETACH_PROCESS "OzExecDetachProcess"
#define JOIN_PROCESS "OzExecJoinProcess"
#define ABORT_PROCESS "OzExecAbortProcess"

#define THREAD_SHOULD_BE_ABORTED "OzExecThreadShouldBeAborted"

#define DEBUG_MESSAGE "OzExecDebugMessage"
#endif

#endif _EXEC_FUNCTION_NAME_H_
