#!/bin/bash

#//tb/140701
#create txl from xml
#see https://github.com/7890/txl

#not complete!
#namespaces aren't supported
#several issues

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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

for tool in {xmlstarlet,sed}; \
	do checkAvail "$tool"; done

#ENABLE_COMMENTS="1"
#if [ $# -eq 1 ]
#then
#	ENABLE_COMMENTS="0"
#fi

cat - | xmlstarlet tr $DIR/xml2txl.xsl - 2>/dev/null

ret=$?
if [ $ret -ne 0 ]
then
	echo "the xml document could not be parsed, it seems invalid." >&2
	echo "<error>the xml document could not be parsed, it seems invalid.</error>" | xmlstarlet fo
fi

