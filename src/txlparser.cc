//parse .txl files, create xml
//output needs to be tranformed with compact_attributes.xsl, remove attributes__
//tb/140705
//g++ -o txlparser txlparser.cc -std=gnu++0x

float version=0.1;

using namespace std;

#include <iostream>
#include <fstream>
#include <stack>
#include <iostream>
#include <string.h>
#include <regex.h>


stack <string> elements;

//output comments in xml
int ENABLE_COMMENTS_=1;

//status
#define S_STARTED 1
#define S_EMPTY 2
#define S_COMMENT 3
#define S_CHILDREN 4
#define S_LEAF 5
#define S_NAVIG_UP 6
#define S_NAVIG_ROOT 7
#define S_NAVIG_CLOSE 8
#define S_NAVIG_EL 9
#define S_ATTRIBUTE 10
#define S_MULTILINE_START 11
#define S_MULTILINE 12

//string INFILE_="../test_data/a.txl";

int STARTING_=1;

//current status
int STAT_=0;
//prev status
int STAT_PREV_=0;

//root element
string ROOT_EL_="";

//variable containing current line
string LINE="";

int MULTILINE_=0;
int MULTILINE_PREV_=0;
int MULTILINE_START_=0;

void trim_leading(string& s)
{
	size_t p = s.find_first_not_of(" \t");
	s.erase(0, p);
}

//escape text for xml
//http://stackoverflow.com/questions/5665231/most-efficient-way-to-escape-xml-html-in-c-string
void encode(string& data) 
{
	string buffer;
	buffer.reserve(data.size());
	for(size_t pos = 0; pos != data.size(); ++pos) 
	{
		switch(data[pos])
		{
			case '&':	buffer.append("&amp;");		break;
			case '\"':	buffer.append("&quot;");	break;
			case '\'':	buffer.append("&apos;");	break;
			case '<':	buffer.append("&lt;");		break;
			case '>':	buffer.append("&gt;");		break;
			default:	buffer.append(&data[pos], 1);	break;
		}
	}
	data.swap(buffer);
}//end encode

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

void check_open_attrs()
{
	if(STAT_PREV_!=S_ATTRIBUTE)
	{
		printf("<attributes__>\n");
	}
}

void check_close_attrs()
{
	if(STAT_PREV_==S_ATTRIBUTE
		&& STAT_!=S_ATTRIBUTE)
	{
		printf("</attributes__>\n");
	}
}

int handle_empty_line()
{
	if(! re(LINE,"^$"))
	{
		STAT_=S_EMPTY;
		check_close_attrs();
		return 0;
	}
	return 1;
}

int handle_comment()
{
	//comment line
	if (! re(LINE,"^//"))
	{
		STAT_=S_COMMENT;

		check_close_attrs();
		if(ENABLE_COMMENTS_==1)
		{
			int pos=LINE.find("/");
			string comment=LINE.substr(pos+2);

			//strip off //
			//-- inside xml comment not allowed
			//needs replace --/==
			printf("<!--%s-->\n",comment.c_str());
		}
		return 0;
	}
	else if (! re(LINE,"^/-"))
	{
		STAT_=S_COMMENT;
		check_close_attrs();
		return 0;
	}
	return 1;
}//end handle_comment

int find_root()
{
	if(STARTING_==1)
	{
		if(! re(LINE,"[:][:]$"))
		{
			STAT_=S_STARTED;
			STARTING_=0;

			int pos=LINE.find("::");
			ROOT_EL_=LINE.substr(0,pos);

			printf("<%s>\n",ROOT_EL_.c_str());

			elements.push(ROOT_EL_);

			return 0;
		}
		else
		{
			//allow comments, empty lines before root element
			if(STAT_!=S_COMMENT && STAT_!=S_EMPTY)
			{
				printf("root element not found!\n");
				exit(1);
			}
		}
	}
	return 1;
}//end find_root

//&myfile.txl
int handle_include()
{
	if(! re(LINE,"^[&].*"))
	{
		string file=LINE.substr(1,LINE.length());

		printf("<!-- include file %s -->\n",file.c_str());

		ifstream ifile(file);
		if (!ifile) 
		{
			printf("<!-- file %s does not exist! -->\n",file.c_str());
			//ignore the line, don't look further
			return 0;
		}

		string cmd_string="cat "+file+" | txlparser";

		FILE *cmd;

		if((cmd= popen(cmd_string.c_str(),"r")) == NULL) 
		{
			printf("<!-- include file %s failed! -->\n",file.c_str());
		}
		else
		{
			char buffer[1024];
			char * line = NULL;
			while ((line = fgets(buffer, sizeof buffer, cmd)) != NULL) 
			{
				printf("%s",line);
			}
		}
		return 0;
	}
	else
	{
		return 1;
	}
}//end handle_include

//=a/b/c/d
int handle_children()
{
	//=nested
	if(! re(LINE,"^=.*"))
	{
		STAT_=S_CHILDREN;
		check_close_attrs();

		//cut leading =
		LINE=LINE.substr(1,LINE.length());

		int pos=0;

		while(pos>=0)
		{
			pos=LINE.find("/");

			if(pos>=0)
			{
				string el=LINE.substr(0,pos);
				elements.push(el);
				printf("<%s>\n",el.c_str());
				LINE=LINE.substr(pos+1,LINE.length());
			}
		}//end while

		//mixed
		pos=LINE.find(" ");

		string el="";
		if(pos>=0)
		{
			el=LINE.substr(0,pos);
			string text=LINE.substr(pos+1,LINE.length());

			encode(text);
			printf("<%s>%s",el.c_str(),text.c_str());
		}
		else
		{
			el=LINE.substr(0,LINE.length());
			printf("<%s>\n",el.c_str());
		}
		elements.push(el);
	}
	return 1;
}//end handle_children

int handle_leaf()
{
	//.leaf
	if(! re(LINE,"^[.][^.*].*"))
	{
		STAT_=S_LEAF;
		check_close_attrs();

		int pos=LINE.find(" ");

		if(pos>1)
		{
			string el=LINE.substr(1,pos-1);
			string text=LINE.substr(pos+1,LINE.length());

			encode(text);

			if(MULTILINE_START_!=1 && MULTILINE_!=1)
			{
				printf("<%s>%s</%s>\n",el.c_str(),text.c_str(),el.c_str());
			}
			else
			{
				elements.push(el);
				printf("<%s>%s\n",el.c_str(),text.c_str());
			}
		}
		else
		{	
			string el=LINE.substr(1,LINE.length());
			printf("<%s></%s>\n",el.c_str(),el.c_str());
		}
		return 0;
	}
	return 1;
}//handle_leaf

int handle_nav_up()
{
	if(! re(LINE,"^[.][.].*"))
	{
		STAT_=S_NAVIG_UP;
		check_close_attrs();

		string el=elements.top();
		elements.pop();

		//close element
		printf("</%s>\n",el.c_str());

		return 0;
	}
	return 1;
}

int handle_nav_element()
{
	if(! re(LINE,"^_.*"))
	{
		STAT_=S_NAVIG_EL;

		check_close_attrs();

		string target=LINE.substr(1,LINE.length());

		string from_stack="";

		while(elements.size()>0)
		{
			from_stack=elements.top();
			elements.pop();

			if(target.compare(from_stack)==0)
			{
				//match, push back and return
				elements.push(from_stack);
				return 0;
			}
			else
			{
				//close element
				printf("</%s>\n",from_stack.c_str());
			}
		}
		return 0;
	}
	return 1;
}//end handle_nav_element

int handle_nav_root()
{
	if(! re(LINE,"^[.][*]"))
	{
		STAT_=S_NAVIG_ROOT;
		check_close_attrs();

		string from_stack="";

		while(elements.size()>1)
		{
			from_stack=elements.top();
			elements.pop();

			//close element
			printf("</%s>\n",from_stack.c_str());
		}
		return 0;
	}
	return 1;
}

int handle_nav_close()
{
	if(! re(LINE,"^::"))
	{
		STAT_=S_NAVIG_CLOSE;
		check_close_attrs();

		string from_stack="";

		while(elements.size()>0)
		{
			from_stack=elements.top();
			elements.pop();

			//close element
			printf("</%s>\n",from_stack.c_str());
		}

		exit(0);
		return 0;
	}
	return 1;
}

int handle_attribute()
{
	if(STAT_==0 && MULTILINE_==0)
	{
		STAT_=S_ATTRIBUTE;
		check_open_attrs();

		int pos=LINE.find(" ");

		if(pos>0)
		{
			string attr=LINE.substr(0,pos);
			string val=LINE.substr(pos+1,LINE.length());

			encode(val);

			printf("<a name=\"%s\">%s</a>\n",attr.c_str(),val.c_str());
		}
		else
		{
			printf("<a name=\"%s\"></a>\n",LINE.c_str());
		}
		return 0;
	}
	return 1;
}

int handle_closing_tag_same_line()
{
	//end tag on the same line
	if(! re(LINE,"[\\][\\][.]$"))
	{
		MULTILINE_=0;

		//cut trailing \\.
		LINE=LINE.substr(0,LINE.length()-3);

		string el=elements.top();
		elements.pop();

		printf("%s</%s>\n",LINE.c_str(),el.c_str());
	} 
	else
	{
		printf("%s\n",LINE.c_str());
	}
}

int handle_multiline_start()
{
	if(! re(LINE,"[\\][\\]$"))
	{
		STAT_=S_MULTILINE_START;

		MULTILINE_START_=1;

		//remove trailing \\ on first multitext line
		int pos=LINE.find("\\\\");

		LINE=LINE.substr(0,pos);
	}
	else
	{
		MULTILINE_START_=0;
	}
}

int handle_multiline_text()
{
	handle_multiline_start();

	if(! re(LINE,"^[|]"))
	{
		STAT_=S_MULTILINE;
		MULTILINE_=1;

		//cut leading | from txl multiline text
		LINE=LINE.substr(1,LINE.length());

		encode(LINE);

		handle_closing_tag_same_line();
	}
	else if(MULTILINE_PREV_==1)
	{
		string el=elements.top();
		elements.pop();
		printf("</%s>\n",el.c_str());
		MULTILINE_=0;		
	}
}

int main (int argc, char *argv[]) 
{
	if(argc==2)
	{
		if( ! strcmp(argv[1],"-h") 
			|| ! strcmp(argv[1],"--help"))
		{
			printf("txlparser help:\n");
			printf("n/a\n");
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

	//string line;
	while (getline(cin, LINE))
	{

		STAT_PREV_=STAT_;
		STAT_=0;
		MULTILINE_PREV_=MULTILINE_;
		MULTILINE_=0;

		trim_leading(LINE);

		if(! handle_empty_line()){continue;}

		if(! handle_comment()){continue;}

		if(! find_root()){continue;}

if(! handle_include()){continue;}

		//
		handle_multiline_text();

		if(! handle_children()){continue;}

		if(! handle_leaf()){continue;}

		if(! handle_nav_up()){continue;}

		if(! handle_nav_element()){continue;}

		if(! handle_nav_root()){continue;}

		if(! handle_nav_close()){continue;}

		if(! handle_attribute()){continue;}

		//cout << line << endl;

	} //end while read line from file

	return 0;
}//end main
