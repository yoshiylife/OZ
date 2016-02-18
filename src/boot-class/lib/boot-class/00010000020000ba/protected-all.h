#define _PROTECTED_ALL_00010000020000ba_H

#ifndef _PROTECTED_ALL_0001000002000221_H
#define _PROTECTED_ALL_0001000002000221_H

#ifndef _PROTECTED_ALL_00010000020000ec_H
#define _PROTECTED_ALL_00010000020000ec_H

#ifndef _PROTECTED_ALL_0001000002000440_H
#define _PROTECTED_ALL_0001000002000440_H

#ifndef _OZ0001000002000440P_H_
#define _OZ0001000002000440P_H_


#define OZClassPart0001000002fffffd_0_in_000100000200043f 1
#define OZClassPart0001000002fffffe_0_in_000100000200043f 1
#define OZClassPart000100000200043f_0_in_000100000200043f 0

typedef struct OZ0001000002000440Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ0001000002000440Part_Rec, *OZ0001000002000440Part;

#ifdef OZ_ObjectPart_Collectable_Command_
#undef OZ_ObjectPart_Collectable_Command_
#endif
#define OZ_ObjectPart_Collectable_Command_ OZ0001000002000440Part

#endif _OZ0001000002000440P_H_


#endif _PROTECTED_ALL_0001000002000440_H
#ifndef _OZ00010000020000ecP_H_
#define _OZ00010000020000ecP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020000eb 1
#define OZClassPart0001000002fffffe_0_in_00010000020000eb 1
#define OZClassPart000100000200043f_0_in_00010000020000eb -1
#define OZClassPart0001000002000440_0_in_00010000020000eb -1
#define OZClassPart00010000020000eb_0_in_00010000020000eb 0

typedef struct OZ00010000020000ecPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozName;
  int pad0;

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020000ecPart_Rec, *OZ00010000020000ecPart;

#ifdef OZ_ObjectPart_Command
#undef OZ_ObjectPart_Command
#endif
#define OZ_ObjectPart_Command OZ00010000020000ecPart

#endif _OZ00010000020000ecP_H_


#endif _PROTECTED_ALL_00010000020000ec_H
#ifndef _OZ0001000002000221P_H_
#define _OZ0001000002000221P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000220 1
#define OZClassPart0001000002fffffe_0_in_0001000002000220 1
#define OZClassPart000100000200043f_0_in_0001000002000220 -2
#define OZClassPart0001000002000440_0_in_0001000002000220 -2
#define OZClassPart00010000020000eb_0_in_0001000002000220 -1
#define OZClassPart00010000020000ec_0_in_0001000002000220 -1
#define OZClassPart0001000002000220_0_in_0001000002000220 0

typedef struct OZ0001000002000221Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ0001000002000221Part_Rec, *OZ0001000002000221Part;

#ifdef OZ_ObjectPart_LauncherCommand
#undef OZ_ObjectPart_LauncherCommand
#endif
#define OZ_ObjectPart_LauncherCommand OZ0001000002000221Part

#endif _OZ0001000002000221P_H_


#endif _PROTECTED_ALL_0001000002000221_H
#ifndef _OZ00010000020000baP_H_
#define _OZ00010000020000baP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020000b9 1
#define OZClassPart0001000002fffffe_0_in_00010000020000b9 1
#define OZClassPart000100000200043f_0_in_00010000020000b9 -3
#define OZClassPart0001000002000440_0_in_00010000020000b9 -3
#define OZClassPart00010000020000eb_0_in_00010000020000b9 -2
#define OZClassPart00010000020000ec_0_in_00010000020000b9 -2
#define OZClassPart0001000002000220_0_in_00010000020000b9 -1
#define OZClassPart0001000002000221_0_in_00010000020000b9 -1
#define OZClassPart00010000020000b9_0_in_00010000020000b9 0

typedef struct OZ00010000020000baPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020000baPart_Rec, *OZ00010000020000baPart;

#ifdef OZ_ObjectPart_ComChange
#undef OZ_ObjectPart_ComChange
#endif
#define OZ_ObjectPart_ComChange OZ00010000020000baPart

#endif _OZ00010000020000baP_H_


#endif _PROTECTED_ALL_00010000020000ba_H
