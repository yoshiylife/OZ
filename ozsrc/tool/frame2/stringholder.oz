/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/Frame 2 >>>
//
//  type: class
//  name: StringHolder
//


class FStringHolder : FHolder, String
{
constructor:
    New, NewFromArrayOfChar;

public:
    Get;

public:  // methods inherited from "String"
    Append, Assign, AssignFromArrayOfChar, At, AtoI, Capacity,
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


// Public Method Implementation ..................................... //

    String Get()
    {
	return self;
    }
}

