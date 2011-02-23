#!/bin/sh
# talairach demon server
java  -classpath build/classes:. RegionsServer 19000 database.dat database.txt
