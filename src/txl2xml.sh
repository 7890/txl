#!/bin/bash

#//tb/140629
#txl parser - create xml from simpler text markup
#see https://github.com/7890/txl

#this "parser" is very slow
#namespaces aren't supported

#predefined XML entities:
#    &lt; represents "<" *
#    &gt; represents ">" *
#    &amp; represents "&" *
#    &apos; represents '
#    &quot; represents "
#*) escaped for attribute and element values

#tag names cannot contain any of the characters:
#!"#$%&'()*+,/;<=>?@[\]^`{|}~

#reserved tag name: 'attributes__'

#ls -1 test_data/*.txl | grep -v d.txl | while read line; \
#do echo $line; echo "============"; cat $line | src/txl2xml.sh; done; \
#cat test_data/d.txl 1 2 3 | src/txl2xml.sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -e $DIR/../lib/stack.sh ]
then
	. $DIR/../lib/stack.sh
else
	echo "stack.sh lib not found!"
	exit 1
fi

checkAvail()
{
	which "$1" >/dev/null 2>&1
	ret=$?
	if [ $ret -ne 0 ]
	then
		echo "tool \"$1\" not found. please install"
		exit 1
	fi
}

for tool in {xmlstarlet,sed,cut,egrep,rev}; \
	do checkAvail "$tool"; done

ENABLE_COMMENTS="1"
if [ $# -eq 1 ]
then
	ENABLE_COMMENTS="0"
fi

#$1 prev
check_open_attrs()
{
		if [ $1 -ne 6 ]
		then
			echo "<attributes__>"
		fi
}

#$1 current $2 prev
check_close_attrs()
{
		if [ $2 -eq 6 ]
		then
			if [ $1 -ne 6 ]
			then
				echo "</attributes__>"
			fi
		fi
}

#using stack.sh
stack_new stack

START=1
ROOT=""
TYPE=0
TYPE_PREV=0

#TEMP=`mktemp`

#====================================

while read line
do
	TYPE_PREV=$TYPE
	TYPE=0

	#remove leading whitespace, tab
	line_=`echo "$line" | sed -e 's/^[ \t]*//'`

	#root tag:   name::
	if [ $START -eq 1 ]
	then
		test=`echo "$line_" | egrep "::$"`
		ret=$?
		if [ $ret -eq 0 ]
		then
			TYPE=1
			START=0
			#echo "aaa:sss::" | rev | cut -d":" -f3- | rev
			ROOT=`echo "$line_" | rev | cut -d":" -f3- | rev`
			echo "<$ROOT>"
			#===
			stack_push stack "$ROOT"
		else
			echo "root element not found!"
			exit 1
		fi
	fi

	#empty line
	test=`echo "$line_" | egrep "^$"`
	ret=$?
	if [ $ret -eq 0 ]
	then
		TYPE=2
		check_close_attrs $TYPE $TYPE_PREV
	fi

	#new element with children:    =name (optional mixed content)
	test=`echo "$line_" | egrep "^[=]"`
	ret=$?
	if [ $ret -eq 0 ]
	then
		TYPE=3
		check_close_attrs $TYPE $TYPE_PREV

		elem=`echo "$line_" | sed -e 's/^=//' | cut -d" " -f1`
		text=`echo "$line_" | cut -d" " -f2- | sed 's/&/\&amp;/g' | sed 's/</\&lt;/g' | sed 's/>/\&gt;/g'`
		#===
		stack_push stack "$elem"

		if [ x"$text" != x"$line_" ]
		then
			echo -n "<$elem>${text}"
		else
			echo "<$elem>"
		fi
		#stack_print stack
	fi

	#leaf element:    .name (content)
	test=`echo "$line_" | egrep "^\.[^.]"`
	ret=$?
	if [ $ret -eq 0 ]
	then
		TYPE=4
		check_close_attrs $TYPE $TYPE_PREV

		elem=`echo "$line_" | sed -e 's/\.//' | cut -d" " -f1`
		text=`echo "$line_" | cut -d" " -f2- | sed 's/&/\&amp;/g' | sed 's/</\&lt;/g' | sed 's/>/\&gt;/g'`

		if [ x"$text" != x"$line_" ]
		then
			echo "<$elem>${text}</$elem>"
		else
			echo "<$elem></$elem>"
		fi
	fi

	#navigate one level up:    ..
	test=`echo "$line_" | egrep "^\.\."`
	ret=$?
	if [ $ret -eq 0 ]
	then
		TYPE=5
		check_close_attrs $TYPE $TYPE_PREV

		#===
		stack_pop stack elem

		#close element
		echo "</$elem>"
	fi

	#comment:    //comment
	test=`echo "$line_" | egrep "^//"`
	ret=$?
	if [ $ret -eq 0 ]
	then
		TYPE=5
		check_close_attrs $TYPE $TYPE_PREV

		if [ x"$ENABLE_COMMENTS" = "x1" ]
		then
			echo "<!-- $line_ -->"
		fi
	fi

	#if no other type matched, it must be an attribute:    name value
	if [ $TYPE -eq 0 ]
	then
		TYPE=6
		check_open_attrs $TYPE_PREV

		attr=`echo "$line_" | cut -d" " -f1`
		val=`echo "$line_" | cut -d" " -f2- | sed 's/&/\&amp;/g' | sed 's/</\&lt;/g' | sed 's/>/\&gt;/g'`

		echo "<a name=\"$attr\">$val</a>"
	fi
done \
	| xmlstarlet tr $DIR/compact_attributes.xsl - \
	| xmlstarlet ed -d "//attributes__" | xmlstarlet fo

#end while read line
#make sure the input has an empty line before EOF!

#post process: move attributes__/a to parent nodes, 
#remove helper elements attributes__

#clean up
stack_destroy stack
#rm -f "$TEMP"
