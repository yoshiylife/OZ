#define _OZ000100000200009cP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200009b 1
#define OZClassPart0001000002fffffe_0_in_000100000200009b 1
#define OZClassPart0001000002000187_0_in_000100000200009b -2
#define OZClassPart0001000002000188_0_in_000100000200009b -2
#define OZClassPart00010000020008cb_0_in_000100000200009b -1
#define OZClassPart00010000020008cc_0_in_000100000200009b -1
#define OZClassPart000100000200009b_0_in_000100000200009b 0

typedef struct OZ000100000200009cPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozClassTable;
  OZ_Object ozLocalClassTable;
  OZ_Array ozPendingCalls;
  OZ_Array ozPendingCallTimeouts;
  OZ_Object ozRemoteClassNames;
  OZ_Object ozaTimer;

  /* protected (data) */
  unsigned int ozInitialCapacityOfClassTable;
  unsigned int ozInitialCapacityOfLocalClassTable;
  unsigned int ozInitialCapacityOfPendingCalls;
  unsigned int ozInitialCapacityOfRemoteClassNames;
  unsigned int ozPendingCallCount;

  /* protected (zero) */
} OZ000100000200009cPart_Rec, *OZ000100000200009cPart;

#ifdef OZ_ObjectPart_ClassLookupper
#undef OZ_ObjectPart_ClassLookupper
#endif
#define OZ_ObjectPart_ClassLookupper OZ000100000200009cPart

#endif _OZ000100000200009cP_H_
