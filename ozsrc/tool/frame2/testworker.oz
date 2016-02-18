/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//   <<< OZ++/Frame 2 >>>
//
//  type: class
//  name: FTestWorker
//


class FTestWorker : FWorker
{
constructor:
    New;

public:
    Do;

    void New()
    {
	inline "C" {
	    OzDebugf("\t\tTestWorker::New\n");
	}
    }

    void Do(FSeries series)
    {
	FScreen     scr1=>New();
	FSlide      slide1, slide2;
	FTestModel  model=>New();
	FComponent  c;
	FLabel      label1, label2, label3, label4;
	String      str1, str2, str3, str4, str5, str6, str7, str8;
	FButton     btn5, btn6;
	FColor      color1, color2, color3;

	series->Resize(800, 600);

	// labels
	str1=>NewFromArrayOfChar("label1");
	str2=>NewFromArrayOfChar("label2");
	str3=>NewFromArrayOfChar("label3");
	str4=>NewFromArrayOfChar("label4");
	label1=>NewWithLabel(str1);
	label2=>NewWithAlignedLabel(str2, FAlign::LEFT);
	label3=>NewWithAlignedLabel(str3, FAlign::CENTER);
	label4=>NewWithAlignedLabel(str4, FAlign::RIGHT);

	label1->Locate(100, 100);
	label2->Locate(100, 150);
	color1=>New(255, 0, 100);
	label2->SetForeground(color1);
	label3->Locate(100, 200);
	label4->Locate(100, 250);

	// buttons
	str5=>NewFromArrayOfChar("button5");
	btn5=>NewWithLabel(str5);
	btn5->Locate(200, 100);
	btn5->Resize(100, 30);
	str6=>NewFromArrayOfChar("button6");
	btn6=>NewWithLabel(str6);
	btn6->Locate(300, 100);
	btn6->Resize(100, 30);

	color2=>New(100, 100, 100);
	btn6->SetBackground(color2);
	color3=>New(200, 100, 200);
	btn6->SetForeground(color3);

	scr1->AddItem(label1);
	scr1->AddItem(label2);
	scr1->AddItem(btn5);

	c = scr1;
	c->SetModel(model);

	// slides
	slide1 = scr1->NewSlide();
	slide1->AddItem(label3);
	str7=>NewFromArrayOfChar("slideX");
	slide1->SetName(str7);

	slide2 = scr1->NewSlide();
	slide2->AddItem(label4);
	slide2->AddItem(btn6);

	series->AddSlide(slide1);
	series->AddSlide(slide2);
    }
}

