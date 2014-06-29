#!/bin/bash

#//tb/140629
#txl parser - create xml from simpler text markup

#this "parser" is very slow

#predefined XML entities:
#    &lt; represents "<"
#    &gt; represents ">"
#    &amp; represents "&"
#    &apos; represents '
#    &quot; represents "

#tag names cannot contain any of the characters:
#!"#$%&'()*+,/;<=>?@[\]^`{|}~

#reserved tag name: 'attributes__'


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. $DIR/../lib/stack.sh

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

stack_new stack

START=1
ROOT=""
TYPE=0
TYPE_PREV=0

TEMP=`mktemp`

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
			ROOT=`echo "$line_" | cut -d":" -f1`
			echo "<$ROOT>"
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

		echo "<!-- $line_ -->"
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
done > "$TEMP"
#end while read line
#make sure the input has an empty line before EOF!

#close root tag
echo "</$ROOT>" >> "$TEMP"

#post process: move attributes__/a to parent nodes, 
#remove helper elements attributes__
cat "$TEMP" | xmlstarlet tr $DIR/compact_attributes.xsl - \
        | xmlstarlet ed -d "//attributes__" | xmlstarlet fo

#clean up
stack_destroy stack
rm -f "$TEMP"
