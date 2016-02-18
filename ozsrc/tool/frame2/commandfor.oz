/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/Frame 2 >>>
//
//  type: abstract class
//  name: FCommandFor
//


abstract class FCommandFor<T> : Command
(alias New SuperNew;)
{
constructor:
    New;

protected:
    MyName, Execute;

protected:  // variables
    Client;


// Instance Variabels ............................................... //

    T   Client;


// Constructor Implementation ....................................... //

    void New(T client)
    {
	Client = client;
	SuperNew();
    }
}

