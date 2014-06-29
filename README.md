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

//see examples in test_data
```

```
$ cat /tmp/foo | src/txl2xml.sh #0  #<- no comments when called with any param
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
```
