a::
=b
=c
=d
attribute please
x y+z
=e
.f deep
..//end e (optional comment) 
..//end d (.. is the only command that allows comments not at start of line)
..//end c
..//end b
//new b
=b
do it again
=c
=d
attribute please
x y+z
=e
=x
=y
=z
=a

//navigate back to x
_x

=y
.z

:://close document (create all necessary closing tags)

//(comments can start anywhere if // are the first printing chars on the line)
