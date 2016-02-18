#ifndef _OZ000100000200079dP_H_
#define _OZ000100000200079dP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200079c 1
#define OZClassPart0001000002fffffe_0_in_000100000200079c 1
#define OZClassPart000100000200079c_0_in_000100000200079c 0

typedef struct OZ000100000200079dPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object oztheTimeofDay;
  int pad0;

  /* protected (data) */
  int oztheYear;
  int oztheMonth;
  int oztheDay;
  int oztheDayoftheWeek;
  int oztheClock;

  /* protected (zero) */
} OZ000100000200079dPart_Rec, *OZ000100000200079dPart;

#ifdef OZ_ObjectPart_Date
#undef OZ_ObjectPart_Date
#endif
#define OZ_ObjectPart_Date OZ000100000200079dPart

#endif _OZ000100000200079dP_H_
