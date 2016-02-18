/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef	_EXEC_EXECUTOR_H_
#define	_EXEC_EXECUTOR_H_

#include "oz++/object-type.h"
#include "oz++/class-type.h"

#define	SITE_MASK	0xffff000000000000LL
#define	EXECUTOR_MASK	0x0000ffffff000000LL

inline	extern OID
OzExecObjectManagerOf(OID o)
{
	return((o & (SITE_MASK|EXECUTOR_MASK)) | 1);
}

typedef char (*OZ_FunctionPtr)(); /* to be casted */

typedef struct OZ_FunctionPtrTableRec {
  unsigned int number_of_entry;
  OZ_FunctionPtr functions[1];
} OZ_FunctionPtrTableRec, *OZ_FunctionPtrTable;

typedef struct OZ_ImportedCodeEntryRec {
  OZ_ClassID impl_vid; /* decided and set in compilation */
  void	*code; /* executor set here the pointer to 'ClassCodeRec' */
} OZ_ImportedCodeEntryRec, *OZ_ImportedCodeEntry;

/* Assumed : Compiler embeds(emits) this data as _OZ_ImportedCodeRec */
typedef struct OZ_ImportedCodesRec {
  int number;
  OZ_ImportedCodeEntryRec entry[1];
} OZ_ImportedCodesRec, *OZ_ImportedCodes;

typedef struct OZ_ExportedFunctionsRec {
  int number;
  struct {
    char *function_name;
    OZ_FunctionPtr function;
  } entry[1];
} OZ_ExportedFunctionsRec, *OZ_ExportedFunctions;

#endif	_EXEC_EXECUTOR_H_
