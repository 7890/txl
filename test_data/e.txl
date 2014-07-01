//pre start comments
//and empty lines

unit::

xxx 1.0
=meta
=a
=b
.x yy
.*//navigate back to root

.pre first line\\
|multiline text
|
|first line of multiline text must end with \\ 
|subsequent lines must start with |
|preserving white spaces at start and end
|indicate same line closing tag with \\. 
|
|regular lines inside multitext should not end with \\ or \\. 
|adding a space after \\ or \\. at line end is possible
     	|chunk before
|close tag on same line         \\.

.pre \\
|first line
|multiline text
|  <>&*+' trailing spaces     
|   close tag on next line

=a
=b
=c
.d hallo
..
=b
.x velo
.*//comments after navigation (same line) commands are ok

.pre    a b c\\
|//\\//\\ 
|         x y z       
        |xxx .. .* ** \\ \\. 
|d e f   \\.

=a
=b
=c

:://close document unseen of current context

anything text and comments allowed after ::

ignored by parser

