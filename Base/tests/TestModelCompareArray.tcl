### This is a slicer script, to be called after the slicer boots
### It tests the "Array" viewing capabilities of the CompareModels module
### It outputs 2 images : ModelCompareArray.tif, ModelCompareNoArray.tif

###
### Read in the MRML file
###

## convert from windows slashes to regular slashes
regsub -all {\\} $env(SLICER_DATA) / slicer_data
set Mrml(dir)          "/"
set File(filePrefix)   "$slicer_data/AmygHipModels/AmygHipModels"
set File(callback)   ""
MainFileOpenApply

## To let the all the buttons form
update

###
### Set the ModelArray settings. (same as typing in the numbers)
###

### Select all the models
ModelCompareSetAll 1

### Set the spacing and the RowSize
global ModelCompare
set ModelCompare(Rowsize)  3
set ModelCompare(ColX) 20.0;
set ModelCompare(ColY) 0.0;
set ModelCompare(ColZ) 0.0;;

set ModelCompare(RowX) 0.0;
set ModelCompare(RowY) 0.0;
set ModelCompare(RowZ) 50.0;;

###
### Now form the array and snap a picture
###

ModelCompareFormArray
MainViewWriteView ModelCompareArray.tif

###
### Now undo the array and snap a picture
###

ModelCompareUndoArray
MainViewWriteView ModelCompareNoArray.tif

MainExitProgram







