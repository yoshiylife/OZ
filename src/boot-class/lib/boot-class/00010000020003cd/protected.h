#define _OZ00010000020003cdP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020003cc 1
#define OZClassPart0001000002fffffe_0_in_00010000020003cc 1
#define OZClassPart00010000020003cc_0_in_00010000020003cc 0

typedef struct OZ00010000020003cdPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  int ozStatus;

  /* protected (zero) */
  OZ_ConditionRec ozSuspensionComplete;
  OZ_ConditionRec ozResumptionComplete;
} OZ00010000020003cdPart_Rec, *OZ00010000020003cdPart;

#ifdef OZ_ObjectPart_SuspensionStateTransition
#undef OZ_ObjectPart_SuspensionStateTransition
#endif
#define OZ_ObjectPart_SuspensionStateTransition OZ00010000020003cdPart

#endif _OZ00010000020003cdP_H_
