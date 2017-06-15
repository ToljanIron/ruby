#!/bin/bash

echo "nil"
sed 's/ nil}/ ""}/g' out1 > out2
cp out2 out1

echo "left brackts"
sed 's/\[/{/g' out1 > out2
cp out2 out1

echo "right brackts"
sed 's/\]/}/g' out1 > out2
cp out2 out1

echo "double qoutes"
grep -v ".*\"\"[a-zA-Z].*" out1 > out2
cp out2 out1

echo "help desk entries"
fgrep -v "helpdesk@deloitte.co.il" out1 > out2
cp out2 out1
