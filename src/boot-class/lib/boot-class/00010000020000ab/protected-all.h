#define _PROTECTED_ALL_00010000020000ab_H

#ifndef _PROTECTED_ALL_0001000002000143_H
#define _PROTECTED_ALL_0001000002000143_H

#ifndef _PROTECTED_ALL_000100000200013e_H
#define _PROTECTED_ALL_000100000200013e_H

#ifndef _OZ000100000200013eP_H_
#define _OZ000100000200013eP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200013d 1
#define OZClassPart0001000002fffffe_0_in_000100000200013d 1
#define OZClassPart000100000200013d_0_in_000100000200013d 0

typedef struct OZ000100000200013ePart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozOM;
  OZ_Object ozanExecutor;

  /* protected (data) */
  unsigned int ozNumberOfProcesses;

  /* protected (zero) */
} OZ000100000200013ePart_Rec, *OZ000100000200013ePart;

#ifdef OZ_ObjectPart_Daemon
#undef OZ_ObjectPart_Daemon
#endif
#define OZ_ObjectPart_Daemon OZ000100000200013ePart

#endif _OZ000100000200013eP_H_


#endif _PROTECTED_ALL_000100000200013e_H
#ifndef _OZ0001000002000143P_H_
#define _OZ0001000002000143P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000142 1
#define OZClassPart0001000002fffffe_0_in_0001000002000142 1
#define OZClassPart000100000200013d_0_in_0001000002000142 -1
#define OZClassPart000100000200013e_0_in_0001000002000142 -1
#define OZClassPart0001000002000142_0_in_0001000002000142 0

typedef struct OZ0001000002000143Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozAID;
  OZ_Object ozClassDirectoryPath;

  /* protected (data) */
  int ozStandAlone;

  /* protected (zero) */
} OZ0001000002000143Part_Rec, *OZ0001000002000143Part;

#ifdef OZ_ObjectPart_DaemonForClass
#undef OZ_ObjectPart_DaemonForClass
#endif
#define OZ_ObjectPart_DaemonForClass OZ0001000002000143Part

#endif _OZ0001000002000143P_H_


#endif _PROTECTED_ALL_0001000002000143_H
#ifndef _OZ00010000020000abP_H_
#define _OZ00010000020000abP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020000aa 1
#define OZClassPart0001000002fffffe_0_in_00010000020000aa 1
#define OZClassPart000100000200013d_0_in_00010000020000aa -2
#define OZClassPart000100000200013e_0_in_00010000020000aa -2
#define OZClassPart0001000002000142_0_in_00010000020000aa -1
#define OZClassPart0001000002000143_0_in_00010000020000aa -1
#define OZClassPart00010000020000aa_0_in_00010000020000aa 0

typedef struct OZ00010000020000abPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020000abPart_Rec, *OZ00010000020000abPart;

#ifdef OZ_ObjectPart_CodeFaultDaemon
#undef OZ_ObjectPart_CodeFaultDaemon
#endif
#define OZ_ObjectPart_CodeFaultDaemon OZ00010000020000abPart

#endif _OZ00010000020000abP_H_


#endif _PROTECTED_ALL_00010000020000ab_H
