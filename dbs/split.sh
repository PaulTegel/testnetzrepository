#!/bin/bash
IN=$(cat 1)

echo $IN

echo ""
echo ""

#Id = 
#for i in $(echo $IN | tr "**********" "\n")

for i in $(echo $IN | tr "Id\ =\ " "\n")
do
  # process
  echo $i
done





#
#new_entries=$(sqlite3 -csv -echo -nullvalue '' -newline "**********" "$LOCAL_PATH_TO_DB"/protocol_security_2.db "SELECT Id, Timestamp, Severity, Type, Code, Message, TaskGuid  FROM Protocol WHERE Id > 15860") ; echo $new_entries > 1
#
#




#	echo $new_entries | grep -o '[^**********]\+' >
