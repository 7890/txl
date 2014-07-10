root::

=a/b/c
.d
e f
.*

//include test
&test_data/a.txl
&test_data/b.txl
&test_data/c.txl
&not_existing.txl

//arbitrary command, must deliver xml
%test_data/template.sh 1 2 3 | txlparser

//start xml comment
<-
/-comments inside xml comment are not allowed
/-double dash -- inside xml comment are not allowed
%echo ls -ltr
%ls -ltr | sed 's/--/==/g'
/-end xml comment
->

::

