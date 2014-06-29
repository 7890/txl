myxml::

//this is a comment
//empty lines are ignored
//whitespace and tabs at the beginning of a line are removed

=meta
.leaf gugus hallo
a b
c d e f g
//end meta
..
.hallo super
x y

=new
x y
.leaf super duper
=nested
.leaf x
attr for leaf
.second leaf
//end nested
..
  //test indented (should make no difference)
  =another
  .xxx yyy
  //end another
  ..
  //end new
  ..
		//end myxml
		..

//must have empty line at end!