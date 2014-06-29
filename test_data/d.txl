#!/bin/bash
#example for a simle template
#./d.txl foo bar baz | txl2xml.sh

if [ $# -ne 3 ]
then
	echo "need 3 params."
	exit
fi

cat - << _EOF_
anode::
=child1
attr1 $1
attr2 $2
.leaf $3
..
=child2
.date `date`
..
..

_EOF_
