#!/bin/bash

# This script will read the file contents.
# This example is for testing nested double quotes.Check below command for example of nested double quotes.
# In case if the document to be read has space character in the name and if cat command argument not double quoted , cat command will fail to execute.

DOC_CONT="$(cat "$1")";
#DOC_CONT="$(cat $1)";

echo "$DOC_CONT";

exit 0;


