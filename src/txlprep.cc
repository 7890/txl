//preprocess .txl files, output txl
//tb/140804
//g++ -o txlprep txlprep -std=gnu++0x

/*
convert multiline text to txl multilines |foo

=a start \\
next
another\\.

->

=a start \\
|next
|another\\.

this allow more free multiline texting

*/

float version=0.1;

using namespace std;

#include <cstdlib>
#include <iostream>
#include <fstream>
#include <string.h>
#include <regex.h>

//variable containing current line
string LINE="";
int MULTILINE_=0;
int MULTILINE_START_=0;

//match regular expression
int re(string s,string pattern)
{
	regex_t regex;
	int reti;

	reti = regcomp(&regex, pattern.c_str(), 0);
	if (reti) 
	{
		fprintf(stderr, "Could not compile regex\n");
		exit(1);
	}

	//execute regular expression
	reti = regexec(&regex, s.c_str(), 0, NULL, 0);

	//match
	if (!reti) 
	{
		;;
	}
	//no match
	else if (reti == REG_NOMATCH) 
	{
		;;
	}
	else 
	{
		char msgbuf[100];
		regerror(reti, &regex, msgbuf, sizeof(msgbuf));
		fprintf(stderr, "Regex match failed: %s\n", msgbuf);
		exit(1);
	}

	//free compiled regular expression if you want to use the regex_t again
	regfree(&regex);

	if(!reti)
	{
		return 0;
	}
	else
	{
		return 1;
	}
}//end re

int main (int argc, char *argv[]) 
{
	if(argc==2)
	{
		if( ! strcmp(argv[1],"-h") 
			|| ! strcmp(argv[1],"--help"))
		{
			printf("txlprep help:\n");
			printf("cat txlfile | txlprep\n");
			printf("preprocess multiline text\n");
			exit(0);
		}
		if( ! strcmp(argv[1],"-v") 
			|| ! strcmp(argv[1],"--version"))
		{
			printf("%.2f\n",version);
			exit(0);
		}
	}

/*
=============================================================
MAIN LOOP
=============================================================
*/
	while (getline(cin, LINE))
	{
		//line ends with '\\' -> start of multiline
		if(! re(LINE,"[\\][\\]$"))
		{
			MULTILINE_START_=1;
			MULTILINE_=1;
			//unchanged start
			printf("%s\n",LINE.c_str());
		}
		else
		{
			MULTILINE_START_=0;
		}

		//when inside a multiline block
		if(MULTILINE_==1 && MULTILINE_START_==0)
		{
			//prepend |
			printf("|%s\n",LINE.c_str());
		}

		//line ends with '\\.' -> end of multiline
		if(! re(LINE,"[\\][\\][.]$"))
		{
			MULTILINE_=0;
		}
		else if(MULTILINE_START_==0 && MULTILINE_==0)
		{
			//not a multiline, unchanged
			printf("%s\n",LINE.c_str());
		}

	} //end while read line from file

	return 0;
}//end main
