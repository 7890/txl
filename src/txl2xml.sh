#!/bin/bash

#//tb/140629
#txl parser - create xml from simpler text markup
#see https://github.com/7890/txl

#namespaces aren't supported

#predefined XML entities:
#    &lt; represents "<"
#    &gt; represents ">"
#    &amp; represents "&"
#    &apos; represents '
#    &quot; represents "
# -> escaped for attribute and element values

#tag names cannot contain any of the characters:
#!"#$%&'()*+,/;<=>?@[\]^`{|}~

#reserved tag name: 'attributes__'

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -e $DIR/txlparser ]
then
	echo "txlparser not found!" >&2
	echo "<error>txlparser not found!</error>"

	exit 1
fi

if [ ! -e $DIR/compact_attributes.xsl ]
then
	echo "compact_attributes.xsl not found!" >&2
	echo "<error>compact_attributes.xsl not found!</error>"

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

#process input and pipe through post process
#===========================================

cat - | $DIR/txlparser \
	| xmlstarlet tr $DIR/compact_attributes.xsl 2>/dev/null \
	| xmlstarlet ed -d "//attributes__" 2>/dev/null \
	| xmlstarlet fo -e UTF-8 - 2>/dev/null

ret=$?
if [ $ret -ne 0 ]
then
	echo "the txl document could not be parsed, it seems invalid." >&2
	echo "<error>the txl document could not be parsed, it seems invalid.</error>" | xmlstarlet fo
fi

#make sure the input has an empty line before EOF!

#post process: move attributes__/a to parent nodes, 
#remove helper elements attributes__
