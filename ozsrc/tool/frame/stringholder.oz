/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class StringHolder : Holder, String{
 constructor:
  New, NewFromArrayOfChar;
  public:
    Assign, AssignFromArrayOfChar, At, AtoI, Capacity,
    Compare, CompareToArrayOfChar,
    Concatenate, ConcatenateWithArrayOfChar,
    Content, Duplicate, GetSubString, GetSubStringByRange, Hash,
    IsEqual, IsEqualTo, IsEqualToArrayOfChar, IsGreaterThan,
    IsGreaterThanArrayOfChar, IsGreaterThanOrEqualTo,
    IsGreaterThanOrEqualToArrayOfChar, IsLessThan, IsLessThanArrayOfChar,
    IsLessThanOrEqualTo, IsLessThanOrEqualToArrayOfChar, IsNotEqualTo,
    IsNotEqualToArrayOfChar,
    Length, NCompare, NCompareToArrayOfChar, SetAt, SetCapacity,
    ToLower, ToUpper,

    Str2OID,

    StrChr, StrRChr, DebugPrint;

 public:
  Get;

  /* public methods */
  String Get(){ return self; }
}
