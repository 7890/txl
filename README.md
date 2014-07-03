txl - write plain text, get XML
===============================

```
#quick test
$ cat test_data/a.txl | src/txl2xml.sh
```

Anatomy of a txl file
---------------------

```
//comments start with '//'
//empty lines are ignored
//whitespace and tabs at the beginning of a line are removed

//root element
myroot::
//attribute
a 1

//an element with children: =name
=first-child

//a leaf element: .name
.myleaf hi

//a attr="val" to myleaf
attr val


..//navigate up one level (now again at myroot/)

.another-child
=and_another
with attr
.and leaf
.* //navigate up to root

=x
=y
=z
.a b

//navigate back to x
_x
.y 2

/-======== unprocessed comment
//close document (navigate all up, close root)
::

document should have at least one newline after last command
comments after document close are ignored
see examples in test_data

```

```
$ cat /tmp/foo | src/txl2xml.sh #0 <- no comments when called with any param
<?xml version="1.0" encoding="utf-8"?>
<!-- comments start with '//' -->
<!-- empty lines are ignored -->
<!-- whitespace and tabs at the beginning of a line are removed -->
<!-- root element -->
<myroot a="1">
  <!-- attribute -->
  <!-- an element with children: =name -->
  <first-child>
    <!-- a leaf element: .name -->
    <myleaf attr="val">hi</myleaf>
    <!-- a attr="val" to myleaf -->
  </first-child>
  <another-child/>
  <and_another with="attr">
    <and>leaf</and>
  </and_another>
  <x>
    <y>
      <z>
        <a>b</a>
        <!-- navigate back to x -->
      </z>
    </y>
    <y>2</y>
    <!-- close document (navigate all up, close root) -->
  </x>
</myroot>


#"on-the-fly" creation

printf "root::\n=meta\n.special └\nattr val\n::\n" | src/txl2xml.sh
<?xml version="1.0" encoding="utf-8"?>
<root>
  <meta>
    <special attr="val">└</special>
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
<?xml version="1.0" encoding="utf-8"?>
<anode>
  <child1 attr1="a" attr2="b">
    <leaf>3.2.0-39-lowlatency</leaf>
  </child1>
  <child2>
    <date>Sun Jun 29 17:34:06 CEST 2014</date>
  </child2>
</anode>

```
