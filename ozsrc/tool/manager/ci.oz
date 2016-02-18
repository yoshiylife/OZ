/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

// we don't use record

//#define NORECORDACOPS

// we flush objects
//#define NOFLUSH

// we are debugging
//#define NDEBUG

// we have no bug in remote instantiation
//#define NOREMOTEINSTANTIATION

// we lookup configuration table for configured class ID


// we don't list directory by unix 'ls' command, but opendir library
//#define LISTBYLS

// we need change directory to $OZHOME before OzRead and OzSpawn


// we don't use OzRemoveCode
//#define USEOZREMOVECODE

// we don't read parents version IDs from private.i.
//#define READPARENTSFROMPRIVATEDOTI

// we have no executor who recognize relative path from OZHOME


// we have OzCopy
//#define NOOZCOPY

// we don't have OzRename


// we have no bug in class StreamBuffer
//#define STREAMBUFFERBUG

// we have no support for getting executor ID


// we use Object::GetPropertyPathName
//#define NOGETPROPERTYPATHNAME

// we have a bug in reference counter treatment when forking private thread
//#define NOFORKBUG

// we have a bug in OzOmObjectTableRemove
//#define NOBUGINOZOMOBJECTTABLEREMOVE

// we have no account directory


// boot classes are modifiable


// when object manager is started, its configuration cache won't be cleared
//#define CLEARCONFIGURATIONCACHEATSTART

// the executor doesn't expect a class cannot be found


// now, creating Feb.1 sources


// Executing Plan Plum: compressing the size of class object

/*
 * ci.oz
 *
 * Command interpreter
 */

abstract class CommandInterpreter
  : LaunchableWithKterm (alias Initialize SuperInitialize;)
{
  protected: /* for override, if needed */
    Initialize, Launch, New, SetHelpMessages, SetInitialVariables,
    SetOneLineHelp, Start;

  protected: /* for use */
    AddCommand, AddHelp, AddOneLineHelp, BreakScroll, CheckArgSize,
    GetVariable, IsAlphabet, IsAlphanumeric, IsDigit, IsWhite, NotSupported,
    Read, ReadYN, ReadYNFromConsole, SetPrompt, SetVariable, StringToOID, Trim,
    TooFewArguments, TooManyArguments, TypeChar, TypeIndentedString, TypeInt,
    TypeOID, TypeReturn, TypeSpaces, TypeStr, TypeString, WriteStr;

  protected: /* commands */
    Alias, Help, NOP, Quit, SetCommandHash, SetVar, Show, Unalias;

  protected: Dispatch, SetInitialPrompt, Title; /* abstract */

/* instance variables */
  protected: CommandHash, Prompt, Aliases, Variables;

    Dictionary <String, int> CommandHash;
    String Prompt;
    Dictionary <String, String> Aliases; /* currently not supported */
    Dictionary <String, String> Variables;
    Dictionary <String, String> HelpMessages;
    OrderedCollection <Assoc <String, String>> OneLineHelp;
    unsigned int LongestCommandNameLength;

/* abstract methods */

    void Dispatch (OrderedCollection <String>) : abstract;
    void SetInitialPrompt () : abstract;
    String Title () : abstract;

/* method implementations */
    void Initialize () {
	SuperInitialize ();
	SetCommandHash ();
	SetOneLineHelp ();
	SetHelpMessages ();
	SetInitialVariables ();
    }

    void AddCommand (char command_name [], int command_number) {
	String com;

	CommandHash->AddAssoc (com=>NewFromArrayOfChar (command_name),
			       command_number);
    }
 
    void AddHelp (char com [], char mes []) {
	String command=>NewFromArrayOfChar (com);
	String message;
	Assoc <String, String> assoc;

	if (HelpMessages->IncludesKey (command)) {
	    assoc = HelpMessages->RemoveKey (command);
	    message = assoc->Value ()->ConcatenateWithArrayOfChar (mes);
	} else {
	    message=>NewFromArrayOfChar (mes);
	}
	HelpMessages->AddAssoc (command, message);
    }

    void AddOneLineHelp (char command [], char message []) {
	String key, value;
	Assoc <String, String> assoc;
	unsigned int len;

	key=>NewFromArrayOfChar (command);
	value=>NewFromArrayOfChar (message);
	assoc=>New (key, value);
	OneLineHelp->Add (assoc);
	len = key->Length ();
	if (len > LongestCommandNameLength) {
	    LongestCommandNameLength = len;
	}
    }

    void CheckArgSize (int size, int minimum, int maximum) {
	if (minimum != 0 && size < minimum) {
	    TooFewArguments ();
	    raise Abort;
	} else if (maximum != 0 && size > maximum) {
	    TooManyArguments ();
	    raise Abort;
	}
    }

    String GetVariable (char var []) {
	String variable=>NewFromArrayOfChar (var);

	if (Variables->IncludesKey (variable)) {
	    return Variables->AtKey (variable);
	} else {
	    raise CommandInterpreterExceptions::UnknownVariable (variable);
	}
    }

    OrderedCollection <String> ProcessAlias (OrderedCollection <String> argv) {
	/* currently, not supported */
	return argv;
    }

    String ProcessControlH (String command) {
	String st;
	char c [] = command->Content ();
	int i;
	unsigned int j, k, f = 0, len = command->Length ();

	for (i = 0; i < len; i ++) {
	    if (c [i] == '\b') {
		f ++;
	    } else {
		if (f > 0) {
		    k = i;
		    if ((i -= 2 * f) < 0) {
			i = 0;
		    }
		    j = i;
		    f = 0;
		    for (; k < len; k ++, j ++) {
			c [j] = c [k];
		    }
		    c [j] = 0;
		    len -= k - j;
		}
	    }
	}
	return st=>NewFromArrayOfChar (c);
    }

    String ProcessVariableSubstitution (String command) {
	String st;
	char c [] = command->Content ();
	unsigned int i, p = 0, f = 0;
	unsigned int len = command->Length ();
	unsigned int capa = length c;
	int d;

	for (i = 0; i < len; i ++) {
	    switch (c [i]) {
	      case '$':
		if (f == 0) {
		    if (p > 0) {
			d = Replace (c, len, capa, p - 1, i);
			len += d;
			i += d;
			capa = length c;
		    }
		    if (IsWhite (c [i + 1])) {
			p = 0;
		    } else {
			p = i + 1;
			f = (c [p] == '{');
		    }
		}
		break;
	      case '}':
		if (p > 0 && f == 1) {
		    d = Replace (c, len, capa, p - 1, i + 1);
		    len += d;
		    i += d;
		    capa = length c;
		    p = 0;
		}
		break;
	      default:
		if (p > 0 && f == 0 && ! IsAlphanumeric (c [i])) {
		    d = Replace (c, len, capa, p - 1, i);
		    len += d;
		    i += d;
		    capa = length c;
		    p = 0;
		}
		break;
	    }
	}
	return st=>NewFromArrayOfChar (c);
    }

    int Replace (char c [], unsigned int len, unsigned int capa,
		 unsigned int from, unsigned int to) {
	String var, val;
	int b = (c [from + 1] == '{');
	char t [];
	unsigned int j, k, tlen = to - from - 1 - (b ? 2 : 0);
	int d;

	length t = tlen + 1;
	for (j = 0, k = from + 1 + (b ? 1 : 0); j < tlen; j ++, k ++) {
	    t [j] = c [k + j];
	}
	t [j] = 0;
	var=>NewFromArrayOfChar (t);
	if (Variables->IncludesKey (var)) {
	    unsigned int vallen;

	    val = Variables->AtKey (var);
	    vallen = val->Length ();
	    d = vallen - (to - from);
	    if (d > 0) {
		if (capa < len + d + 1) {
		    length c += d;
		    capa += d;
		}
		for (j = len + 1; j >= to; j --) {
		    c [j + d] = c [j];
		}
	    } else if (d < 0) {
		for (j = to; j <= len; j ++) {
		    c [j + d] = c [j];
		}
	    }
	    len += d;
	    for (j = 0; j < vallen; j ++) {
		c [from + j] = val->At (j);
	    }
	} else {
	    raise CommandInterpreterExceptions::UnknownVariable (var);
	}
	return d;
    }

    void SetCommandHash () {
	/* Subclasses should alias and expand this method. */

	CommandHash=>New ();
	AddCommand ("NOP", CommandInterpreterCommands::NOP);
	AddCommand ("help", CommandInterpreterCommands::Help);
	AddCommand ("alias", CommandInterpreterCommands::Alias);
	AddCommand ("unalias", CommandInterpreterCommands::Unalias);
	AddCommand ("set", CommandInterpreterCommands::SetVar);
	AddCommand ("show", CommandInterpreterCommands::Show);
	AddCommand ("quit", CommandInterpreterCommands::Quit);
    }

    void SetHelpMessages () {
	/* Subclasses should alias and expand this method. */

	HelpMessages=>New ();
	AddHelp ("NOP", "NOP\n\n");
	AddHelp ("NOP", "NOP does nothing.  An empty line executes NOP.\n");

	AddHelp ("help", "help [<command>]\n\n");
	AddHelp ("help", "help shows a list of available commands.  ");
	AddHelp ("help", "If an argument <command> is supplied, ");
	AddHelp ("help", "it shows more detailed information ");
	AddHelp ("help", "about the command.  ");
	AddHelp ("help", "An expressions like <xxx> appeared in the help ");
	AddHelp ("help", "text represents that the user should replace ");
	AddHelp ("help", "the <xxx> by an appropriate argument.");

	AddHelp ("alias", "alias [<Alias> [<String>]]\n\n");
	AddHelp ("alias", "alias sets command alias <Alias> to be ");
	AddHelp ("alias", "<String>.  If argument <String> isn't supplied, ");
	AddHelp ("alias", "alias shows the current interpretation of ");
	AddHelp ("alias", "<Alias>.  With no argument, alias shows a list ");
	AddHelp ("alias", "of currently available aliases.");

	AddHelp ("unalias", "unalias [<Alias>]\n\n");
	AddHelp ("unalias", "unalias unsets command alias <Alias>.  ");
	AddHelp ("unalias", "With no argument, unalias unsets ");
	AddHelp ("unalias", "all command aliases.");

	AddHelp ("set", "set [<Variable> <Value>]\n\n");
	AddHelp ("set", "set sets <Variable> to be <Value>.  ");
	AddHelp ("set", "Variables can be referred by $<Variable> in ");
	AddHelp ("set", "command line.  ");
	AddHelp ("set", "There are some variables interpreted in special ");
	AddHelp ("set", "way:\n\n");
	AddHelp ("set", "  Rows    ... Rows in 1 screen\n");
	AddHelp ("set", "  Columns ... Columns in 1 Row\n");

	AddHelp ("show", "show <Variable>\n\n");
	AddHelp ("show", "show shows the value of a variable <Variable>.  ");
	AddHelp ("show", "With no arguments, show shows the values of ");
	AddHelp ("show", "all variables.");

	AddHelp ("quit", "quit\n\n");
	AddHelp ("quit", "quit terminates this interface.");
    }

    void SetInitialVariables () {
	String var, val;

	Variables=>New ();
	SetVariable ("Rows", "24");
	SetVariable ("Columns", "80");
    }

    void SetVariable (char var [], char val []) {
	String variable=>NewFromArrayOfChar (var);
	String value=>NewFromArrayOfChar (val);

	if (Variables->IncludesKey (variable)) {
	    Variables->SetAtKey (variable, value);
	} else {
	    Variables->AddAssoc (variable, value);
	}
    }

    void SetOneLineHelp () {
	/* Subclasses should alias and expand this method. */

	OneLineHelp=>New ();
	AddOneLineHelp ("NOP", "Do nothing.");
	AddOneLineHelp ("help", "This command.");
	AddOneLineHelp ("alias", "Set command aliases.");
	AddOneLineHelp ("unalias", "Unset command aliases.");
	AddOneLineHelp ("set", "Set variables.");
	AddOneLineHelp ("show", "Show variables.");
	AddOneLineHelp ("quit", "Quit this service interface.");
    }

    OrderedCollection <String> Split (String command) {
	/* currently, variable substitution is not supported */
	int c;
	unsigned int i, p = 0, len = command->Length ();
	OrderedCollection <String> oc=>New ();

	for (i = 0; i < len; i ++) {
	    c = command->At (i);
	    if (! IsWhite (c)) {
		break;
	    }
	}
	if (i == len) {
	    String st=>NewFromArrayOfChar ("NOP");

	    oc->Add (st);
	    return oc;
	}
	p = i;
	for (; i < len; i ++) {
	    c = command->At (i);
	    if (IsWhite (c)) {
		oc->Add (command->GetSubString (p, i - p));
		for (; i < len; i ++) {
		    if (! IsWhite (command->At (i))) {
			p = i;
			break;
		    }
		}
	    } else if (c == '\'') {
		for (; i < len; i ++) {
		    if (c == '\'') {
			break;
		    }
		}
		if (i == len) {
		    raise CommandInterpreterExceptions::Unmatch ('\'');
		}
	    } else if (c == '\"') {
		for (; i < len; i ++) {
		    if (c == '\"') {
			break;
		    }
		}
		if (i == len) {
		    raise CommandInterpreterExceptions::Unmatch ('\"');
		}
	    }
	}
	return oc;
    }

    void NotSupported () {
	TypeStr ("Sorry, this command is currently not supported.\n");
    }

    void Start () {
	String command, key, var;

	SetCommandHash ();
	SetInitialPrompt ();
	while (1) {
	    OrderedCollection <String> argv;

	    TypeString (Prompt);
	    command = Read ();
	    try {

		command = ProcessControlH (command);
		command = ProcessVariableSubstitution (command);
		argv = Split (command);
		argv = ProcessAlias (argv);
		Dispatch (argv);
	    } except {
	      CommandInterpreterExceptions::Unmatch (c) {
		  TypeStr ("Unmatched ");
		  TypeChar (c);
		  TypeStr (".\n");
	      }
	      CommandInterpreterExceptions::SyntaxError {
		  TypeStr ("Syntax error.\n");
	      }
	      CommandInterpreterExceptions::Quit {
		  return;
	      }
	      CommandInterpreterExceptions::UnknownVariable (var) {
		  TypeStr ("Unknown variable ");
		  TypeString (var);
		  TypeStr (".\n");
	      }
		default {
		    TypeStr ("Command failed.\n");
		}
	    }
	}
    }
    
    global Object StringToOID (String arg) {
	global Object o;

	o = arg->Str2OID ();
	if (o == 0) {
	    TypeStr ("16 hex-decimal digits ([0-9a-fA-F]) are ");
	    TypeStr ("needed to represent global Object ID.\n");
	    raise CommandInterpreterExceptions::SyntaxError;
	}
	return o;
    }



    void TooFewArguments () {TypeStr ("Too few arguments.  Try help.\n");}
    void TooManyArguments () {TypeStr ("Too may arguments.  Try help.\n");}

    void TypeIndentedString (String s, unsigned int indent) {
	char buf [];
	unsigned int max_column = GetVariable ("Columns")->AtoI ();
	unsigned int column = 0, s_len = s->Length (), p = 0, i;
	unsigned int max_row = GetVariable ("Rows")->AtoI ();
	unsigned int row = 0;

	if (max_column < indent * 10) {
	    indent = max_column / 10;
	}
	buf = s->Content ();
	while (p < s_len) {
	    int state = 0;
	    unsigned int in_mark = p, out_mark = p, new_p;

	    for (i = p; i < s_len && i < p + max_column - column ; i ++) {
		if (IsWhite (buf [i])) {
		    if (state) {
			state = 0;
			out_mark = i;
		    }
		    if (buf [i] == '\n') {
			break;
		    }
		} else {
		    if (! state) {
			state = 1;
			in_mark = i;
		    }
		}
	    }
	    if (i == s_len) {
		new_p = s_len;
	    } else if (IsWhite (buf [i])) {
		new_p = i;
		if (IsWhite (buf [i - 1])) {
		    i = out_mark;
		}
	    } else {
		if (IsWhite (buf [i - 1])) {
		    new_p = i;
		} else {
		    new_p = in_mark;
		}
		i = out_mark;
	    }
	    if (i == p) {
		for (; i < s_len; i ++) {
		    if (! IsWhite (buf [i]) || buf [i] == '\n') {
			break;
		    }
		}
		for (; i < s_len; i ++) {
		    if (IsWhite (buf [i])) {
			break;
		    }
		}
		new_p = i;
	    }
	    TypeSpaces (column);
	    if (i > p) {
		TypeString (s->GetSubString (p, i - p));
	    }
	    if (column + i - p != max_column) {
		TypeReturn ();
	    }
	    if (++ row == max_row - 1) {
		if (BreakScroll ()) {
		    return;
		} else {
		    row = 0;
		}
	    }
	    column = indent;
	    for (p = new_p; p < s_len; p ++) {
		if (! IsWhite (buf [p])) {
		    break;
		} else if (buf [p] == '\n') {
		    p ++;
		    break;
		}
	    }
	}
    }

    /* commands */

    void NOP (OrderedCollection <String> argv) {}

    void Help (OrderedCollection <String> argv) {
	String arg;
	int arg_size = argv->Size ();
	unsigned int i, len;

	CheckArgSize (arg_size, 1, 2);
	switch (arg_size) {
	  case 1:
	    len = OneLineHelp->Size ();
	    for (i = 0; i < len; i ++) {
		Assoc <String, String> assoc = OneLineHelp->At (i);
		String command = assoc->Key ();

		TypeString (command);
		TypeSpaces (LongestCommandNameLength - command->Length ());
		TypeStr (" ... ");
		TypeIndentedString (assoc->Value (),
				    LongestCommandNameLength + 5);
	    }
	    TypeStr ("Try help help for more information.\n");
	    break;
	  case 2:
	    argv->RemoveFirst ();
	    arg = argv->RemoveFirst ();
	    if (HelpMessages->IncludesKey (arg)) {
		TypeIndentedString (HelpMessages->AtKey (arg), 8);
	    } else {
		TypeStr ("I don't know the command `");
		TypeString (arg);
		TypeStr ("'.\n");
	    }
	    break;
	}
    }

    void Alias (OrderedCollection <String> argv) {NotSupported ();}

    void Unalias (OrderedCollection <String> argv) {NotSupported ();}

    void SetVar (OrderedCollection <String> argv) {NotSupported ();}

    void Show (OrderedCollection <String> argv) {
	Iterator <Assoc <String, String>> i;
	Assoc <String, String> assoc;
	String var;
	int arg_size = argv->Size ();

	CheckArgSize (arg_size, 1, 2);
	switch (arg_size) {
	  case 1:
	    for (i=>New (Variables); (assoc = i->PostIncrement ()) != 0;) {
		TypeString (assoc->Key ());
		TypeStr ("\t");
		TypeString (assoc->Value ());
		TypeReturn ();
	    }
	    break;
	  case 2:
	    var = argv->RemoveLast ();
	    TypeString (var);
	    TypeStr ("\t");
	    TypeString (GetVariable (var->Content ()));
	    TypeReturn ();
	    break;
	}
    }

    void Quit (OrderedCollection <String> argv) {
	raise CommandInterpreterExceptions::Quit;
    }
}
