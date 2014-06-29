txl - write plain text, get XML
===============================

```
#quick test
$ cat test_data/a.txl | src/txl2xml.sh
```

Anatomy of a txl file
---------------------

```
myroot::

//first line specifies root element: name::
//comments start with '//'
//empty lines are ignored
//whitespace and tabs at the beginning of a line are removed

=first-child
//an element with children: =name (mixed content)

.myleaf hi
//a leaf element: .name (text content)

attr val
//a simple attr="val"

..
//navigate up one level (now again at myroot/)

.another-child
=and_another
with attr
.and leaf
..
..

//end
//see examples in test_data
```

```
$ cat /tmp/foo | src/txl2xml.sh #0 <- no comments when called with any param
<?xml version="1.0"?>
<myroot>
  <!-- //first line specifies root element: name:: -->
  <!-- //comments start with '//' -->
  <!-- //empty lines are ignored -->
  <!-- //whitespace and tabs at the beginning of a line are removed -->
  <first-child>
    <!-- //an element with children: =name (mixed content) -->
    <myleaf attr="val">hi</myleaf>
    <!-- //a leaf element: .name (text content) -->
    <!-- //a simple attr="val" -->
  </first-child>
  <!-- //navigate up one level (now again at myroot/) -->
  <another-child/>
  <and_another with="attr">
    <and>leaf</and>
  </and_another>
  <!-- //see examples in test_data -->
</myroot>


#"on-the-fly" creation

$ printf "root::\n=meta\n.name here we go\nattr val\n..\n..\.." | src/txl2xml.sh 
<?xml version="1.0"?>
<root>
  <meta>
    <name attr="val">here we go</name>
  </meta>
</root>

#templating

$ cat test_data/d.txl 
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

$ test_data/d.txl a b "`uname --kernel-release`" | src/txl2xml.sh 
<?xml version="1.0"?>
<anode>
  <child1 attr1="a" attr2="b">
    <leaf>3.2.0-39-lowlatency</leaf>
  </child1>
  <child2>
    <date>Sun Jun 29 17:34:06 CEST 2014</date>
  </child2>
</anode>

```
