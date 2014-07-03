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
#test_data/d.txl 1 2 3 | src/txl2xml.sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -e $DIR/../lib/stack.sh ]
then
	. $DIR/../lib/stack.sh
else
	echo "stack.sh lib not found!" >&2
	echo "<error>stack.sh lib not found!</error>"

	exit 1
fi

checkAvail()
{
	which "$1" >/dev/null 2>&1
	ret=$?
	if [ $ret -ne 0 ]
	then
		echo "tool \"$1\" not found. please install" >&2
		echo "<error>tool \"$1\" not found. please install</error>"
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

#=========================================================

#using stack.sh
stack_new EL_STACK

STARTING=1

#status
S_STARTED=1
S_EMPTY=2
S_COMMENT=3
S_CHILDREN=4
S_LEAF=5
S_NAVIG_UP=6
S_NAVIG_EL=61
S_NAVIG_ROOT=7
S_NAVIG_CLOSE=8
S_NAVIG_EL=9
S_ATTRIBUTE=10

#current status
STAT=0
#prev status
STAT_PREV=0

#root element
ROOT_EL=""

#variable containing current line, unchanged
LINE=""

#variable containing current line, processed
LINE_=""

MULTILINE=0
MULTILINE_PREV=0
MULTILINE_START=0

#return value of last method call to do_test
RET=0

#=============================================================

#$1 prev
check_open_attrs()
{
		if [ $STAT_PREV -ne $S_ATTRIBUTE ]
		then
			echo "<attributes__>"
		fi
}

#$1 current $2 prev
check_close_attrs()
{
		if [ $STAT_PREV -eq $S_ATTRIBUTE ]
		then
			if [ $STAT -ne $S_ATTRIBUTE ]
			then
				echo "</attributes__>"
			fi
		fi
}

do_test()
{
	test=`echo "$LINE_" | egrep "$1"`
	RET=$?
}

handle_empty_line()
{
	do_test "^$"
	if [ $RET -eq 0 ]
	then
		STAT=$S_EMPTY

		check_close_attrs
	fi
	return $RET
}

handle_comment()
{
	#comment:    //comment
	do_test "^//"
	if [ $RET -eq 0 ]
	then
		STAT=$S_COMMENT

		check_close_attrs

		if [ x"$ENABLE_COMMENTS" = "x1" ]
		then
			#strip off //
			# -- inside xml comment not allowed
			comment=`echo "$LINE_" | sed 's/^\/\///g' | sed 's/--/==/g'`

			echo "<!-- $comment -->"
		fi
	fi

	do_test "^/-"
	if [ $RET -eq 0 ]
	then
		STAT=$S_COMMENT

		check_close_attrs
	fi

	return $RET
} #end handle_comment


find_root()
{
	#root tag:   name::
	if [ $STARTING -eq 1 ]
	then
		do_test ".::$"
		if [ $RET -eq 0 ]
		then
			STAT=$S_STARTED
			STARTING=0

			ROOT_EL=`echo "$LINE_" | rev | cut -d":" -f3- | rev`
			echo "<$ROOT_EL>"
			#===
			stack_push EL_STACK "$ROOT_EL"
		else
			#allow comments before start
			if [ $STAT -ne $S_COMMENT ]
			then
				#allow empty lines before start
				if [ $STAT -ne $S_EMPTY ]
				then
					echo "root element not found!" >&2
					echo "<error>root element not found!</error>"
					exit 1
				fi
			fi
		fi
	fi
} #end find_root


handle_children()
{
	#new element with children:    =name (optional mixed content)
	do_test "^[=]"
	if [ $RET -eq 0 ]
	then
		STAT=$S_CHILDREN

		check_close_attrs

		elem=`echo "$LINE_" | sed 's/^=//' | cut -d" " -f1`
		text=`echo "$LINE_" | cut -d" " -f2- | sed 's/&/\&amp;/g' | sed 's/</\&lt;/g' | sed 's/>/\&gt;/g'`
		#===
		stack_push EL_STACK "$elem"

		if [ x"$text" != x"$LINE_" ]
		then
			echo -n "<$elem>${text}"
		else
			echo "<$elem>"
		fi
		#stack_print EL_STACK
	fi

	return $RET
} #end handle_children


handle_leaf()
{
	#leaf element:    .name (content)
	do_test "^\.[^.\*]"
	if [ $RET -eq 0 ]
	then
		STAT=$S_LEAF

		check_close_attrs

		elem=`echo "$LINE_" | sed 's/\.//' | cut -d" " -f1`
		text=`echo "$LINE_" | cut -d" " -f2- | sed 's/&/\&amp;/g' | sed 's/</\&lt;/g' | sed 's/>/\&gt;/g'`

		if [ x"$text" != x"$LINE_" ]
		then

			if [ "$MULTILINE_START" -ne 1 ]
			then
				if [ "$MULTILINE" -ne 1 ]
				then
					echo "<$elem>${text}</$elem>"
				fi
			else
				#===
				stack_push EL_STACK "$elem"

				echo "<$elem>${text}"
			fi

		else
			echo "<$elem></$elem>"
		fi
	fi

	return $RET
} #end handle_leaf


handle_nav_up()
{
	#navigate one level up:    ..
	do_test "^\.\."
	if [ $RET -eq 0 ]
	then
		STAT=$S_NAVIG_UP

		check_close_attrs

		#===
		stack_pop EL_STACK elem

		#close element
		echo "</$elem>"
	fi

	return $RET
} #end handle_nav_up


handle_nav_element()
{
	#navigate levels up to element:    _name
	do_test "^_."
	if [ $RET -eq 0 ]
	then
		STAT=$S_NAVIG_EL

		check_close_attrs

		target=`echo "$LINE_" | cut -d"_" -f2-`

		#===
		stack_size EL_STACK left_on_stack

		while [ $left_on_stack -gt 0 ]
		do
			stack_pop EL_STACK elem

			if [ x"$elem" = x"$target" ]
			then
				#push back and return
				stack_push EL_STACK "$elem"
				return 0
			fi

			if [ x"$elem" != x"$target" ]
			then
				#close element
				echo "</$elem>"
				stack_size EL_STACK left_on_stack
			fi
		done
	fi

	return $RET
} #end handle_nav_up

handle_nav_root()
{
	#navigate up to root:    .*
	do_test "^\.\*"
	if [ $RET -eq 0 ]
	then
		STAT=$S_NAVIG_ROOT
		check_close_attrs

		#===
		stack_size EL_STACK left_on_stack

		while [ $left_on_stack -gt 1 ]
		do
			stack_pop EL_STACK elem
			#close element
			echo "</$elem>"
			stack_size EL_STACK left_on_stack
		done
	fi

	return $RET
} #end handle_nav_root


handle_nav_close()
{
	#navigate all up (close document with </$ROOT_EL>):    ::
	do_test "^::"
	if [ $RET -eq 0 ]
	then
		STAT=$S_NAVIG_CLOSE
		check_close_attrs

		#===
		stack_size EL_STACK left_on_stack

		while [ $left_on_stack -gt 0 ]
		do
			stack_pop EL_STACK elem
			#close element
			echo "</$elem>"
			stack_size EL_STACK left_on_stack
		done
		#if nothing more on stack, no need to continue
		#=======
		exit
	fi

	return $RET
} #end handle_nav_close


handle_attribute()
{
	#if no other type matched, it must be an attribute:    name value
	if [ $STAT -eq 0 ]
	then
		if [ $MULTILINE -eq 0 ]
		then
			STAT=$S_ATTRIBUTE

			check_open_attrs

			attr=`echo "$LINE_" | cut -d" " -f1`
			val=`echo "$LINE_" | cut -d" " -f2- | sed 's/&/\&amp;/g' | sed 's/</\&lt;/g' | sed 's/>/\&gt;/g'`

			#if empty value 
			if [ x"$LINE_" = x"$attr" ]
			then
				val=""
			fi	

			echo "<a name=\"$attr\">$val</a>"
		fi
	fi
} #end handle_attribute


handle_closing_tag_same_line()
{

	#end tag on the same line
	test=`echo "$LINE_" | egrep '[\][\][.]$'`
	ret=$?
	if [ $ret -eq 0 ]
	then
		MULTILINE=0
		#===

		#cut trailing \\.
		LINE_=`echo "$LINE_" | rev | cut -b 4- | rev`

		stack_pop EL_STACK elem
		echo "$LINE_""</$elem>"
	else
		echo "$LINE_"
	fi
} #end handle_closing_tag_same_line

handle_multiline_start()
{
	#multiline start:    (any command with text) \\
	#                    | next line
	test=`echo "$LINE_" | egrep '[\][\]$'`
	ret=$?
	if [ $ret -eq 0 ]
	then
		STAT=21

		MULTILINE_START=1
#		check_close_attrs
		#remove trailing \ on first multitext line
		LINE_=`echo "$LINE_" | rev | cut -b 3- | rev`
	else
		MULTILINE_START=0
	fi
}

handle_multiline_text()
{

	handle_multiline_start

	#multiline text:    |foo bar
	test=`echo "$LINE_" | egrep '^[|]'`
	ret=$?
	if [ $ret -eq 0 ]
	then

		STAT=22

		MULTILINE=1
#		check_close_attrs

		#cut leading | from txl multiline text
		LINE_=`echo "$LINE_" | cut -b 2- | sed 's/&/\&amp;/g' | sed 's/</\&lt;/g' | sed 's/>/\&gt;/g'`

		#==
		handle_closing_tag_same_line
	else
		#if changed, need to close element
		if [ $MULTILINE_PREV -eq 1 ]
		then
			#===
			stack_pop EL_STACK elem
			echo "</$elem>"
		fi
			MULTILINE=0
	fi
} #end handle_multiline_text

#=============================================================
#  MAIN LOOP
#=============================================================

#need to preserve leading / trailing whitespace
#http://wiki.bash-hackers.org/commands/builtin/read

while IFS= read -r; do
	LINE=$REPLY

	STAT_PREV=$STAT
	STAT=0
	MULTILINE_PREV=$MULTILINE
	MULTILINE=0


#per line:

#strip off leading spaces and tabs
	LINE_=`echo "$LINE" | sed 's/^[ \t]*//'`

#handle empty line
	handle_empty_line
	r=$?
	if [ $r -eq 0 ]
	then
		continue
	fi

#handle comment: //comment
	handle_comment
	r=$?
	if [ $r -eq 0 ]
	then
		continue
	fi

#look for ROOT_EL tag: name::
	find_root

#multiline start:    .el 1st line\\
#multiline text:    |foo bar
#end tag on the same line: aaa\\.
	handle_multiline_text
 
#handle new element with children: =name (optional mixed content)
	handle_children
	r=$?
	if [ $r -eq 0 ]
	then
		continue
	fi

#handle leaf element: .name (content)
	handle_leaf
	r=$?
	if [ $r -eq 0 ]
	then
		continue
	fi

#navigate: one level up: ..
	handle_nav_up
	r=$?
	if [ $r -eq 0 ]
	then
		continue
	fi

#navigate: levels up to element: _name
	handle_nav_element
	r=$?
	if [ $r -eq 0 ]
	then
		continue
	fi

#navigate: up to root: .*
	handle_nav_root
	r=$?
	if [ $r -eq 0 ]
	then
		continue
	fi


#navigate: close document with all needed closing tags incl. </$ROOT_EL>): ::
	handle_nav_close

#handle attributes (if no other type matched) it must be an attribute: name value
	handle_attribute

#pipe through post process
#=============================================================

done \
	| xmlstarlet tr $DIR/compact_attributes.xsl - 2>/dev/null \
	| xmlstarlet ed -d "//attributes__" - 2>/dev/null | xmlstarlet fo -e utf-8 - 2>/dev/null
ret=$?

if [ $ret -ne 0 ]
then
	echo "the txl document could not be parsed, it seems invalid." >&2
	echo "<error>the txl document could not be parsed, it seems invalid.</error>" | xmlstarlet fo
fi

#make sure the input has an empty line before EOF!

#post process: move attributes__/a to parent nodes, 
#remove helper elements attributes__

#clean up
stack_destroy EL_STACK
