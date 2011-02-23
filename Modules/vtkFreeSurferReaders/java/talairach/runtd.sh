#!/bin/sh
# talairach demon server
java  -classpath $1/build/classes:. RegionsServer 19000 $1/database.dat $1/database.txt
