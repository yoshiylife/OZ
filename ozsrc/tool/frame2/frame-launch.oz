/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//   <<< OZ++/Frame 2 >>>
//
//  type: class
//  name: FFrameLaunchable
//


class FFrameLaunchable : Launchable
{
public:
    Initialize, Launch;

    FFrame  frame;


    void Initialize()
    {
	FTestWorker  worker;

	worker=>New();
	frame=>NewWithWorker(worker);
    }

    void Launch()
    {
	frame->Launch();
    }
}

