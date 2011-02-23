#!/usr/bin/tcsh

echo "Change file $1"

sed "s/VTK_SLICERTENSOR_EXPORT/VTK_TENSORUTIL_EXPORT/g" $1 > $1.new

#mv $1 $1.bak
#mv $1.new $1

mv -f $1.new $1
