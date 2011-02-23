vtkCustomModule -- a system for creating new VTK Modules

Michael Halle and Steve Pieper 
mhalle@bwh.harvard.edu, pieper@bwh.harvard.edu
Neuroimage Analysis Center/BIRN (an NCRR National Resource Center)
Surgical Planning Lab, Brigham and Women's Hospital

Quick notes for creating your own custom VTK module.
Updated Steve Pieper -- 2004-12-07
Michael Halle -- 2002/05/17
Updated Steve Pieper -- 2002-05-29
Michael Halle -- 2001/01/17

* Go into the slicer2 Modules directory ; for example:

	cd /home/halazar/slicer2/Modules

* Copy the entire template directory tree with a name specific to your
  module.  In this example we'll use "Test" as the name of your
  module.

    cp -r  vtkCustomModule vtkTest
    or
    rsync -av vtkCustomModule/ vtkTest

* Change directories to your new module directory.

    cd vtkTest

* Remove *all* the CVS subdirectories in the new Module directory.
  You can either do this by hand or use:

	rm -r `find . -name CVS`
Be SURE you are in your new directory when you run this command!

* Run vtkNameModule.  This program is a simple Tcl script that
   runs through the entire directory, substituting the name of the
   module in many different locations.  By default, vtkNameModule
   will get the name of the module from the directory name.

    ./vtkNameModule

  (if tclsh isn't in your default path, you can run the filter 
   manually, for example: tclsh8.4 ./vtkNameModule )
  
  You'll notice a new set of files and directories are created that
  are specific to your module whereever the generic ones were
  (e.g. where there were .in files or files/directories with @ in the
  name).

* change to the cxx directory.
    
    cd cxx

* Put your source and header files here.  All of your header files
   should include the file of the form <vtk[ModuleName]Configure.h> .
   They should also declare your classes exported appropriately for
   Windows platforms, with a line like the following:

     class VTK_[MODULENAME]_EXPORT vtk[Modulename] : ...
     e.g.

        #include <vtkTestConfigure.h>
	  - and - 
        class VTK_TEST_EXPORT vtkTest : ...

  Note that there will be a vtk[Modulename]Configure.h.cin file in
  your directory -- the actual .h file will be created at build time.

* Copy the file CMakeListsLocal-SAMPLE.txt to CMakeListsLocal.txt

    cp CMakeListsLocal-SAMPLE.txt CMakeListsLocal.txt

* Edit CMakeListsLocal.txt to include the names of your source files.
  Change VTKMYCLASS_SOURCE_DIR to VTK[MODULENAME]_SOURCE_DIR as needed
  e.g. VTKTEST_SOURCE_DIR.
  Be sure to include suffixes (.cxx).  If you have abstract classes, put
  them in the source files area as well as the abstract files area.
  The file also includes directions for adding link libraries, and
  paths for include files and libraries. See
  http://www.cmake.org/HTML/Index.html for more information.

* In CMakeListsLocal.txt, uncomment the following lines if 
your code depends on the slicer code:

INCLUDE_DIRECTORIES( 
   ${VTKSLICERBASE_SOURCE_DIR}/cxx 
   ${VTKSLICERBASE_BUILD_DIR}
   ${VTKTENSORUTIL_SOURCE_DIR}/cxx
   ${VTKTENSORUTIL_BUILD_DIR}   

)
  
* Change to the tcl directory (e.g. /home/halazar/slicer2/Modules/vtkTest/tcl)
and put your tcl code in the skeleton file, ie Test.tcl.

* Edit the files in Wrapping/Tcl to specify the version number of your
  module.  You may also need to change the vtk<Modulename>.tcl file to
  specify a unique command that's only in your class -- by default it
  assumes there will be a class with the same name as your module.

* Add the following two lines to your Wrapping/Tcl/[ModuleName]/pkgIndex.tcl file,
if they are not already present:
    global PACKAGE_DIR_VTK[MODULENAME]
    set PACKAGE_DIR_VTK[MODULENAME] $dir
then add 
    global PACKAGE_DIR_VTK[MODULENAME]
    source  $PACKAGE_DIR_VTK[MODULENAME]/../../../tcl/<module tcl file>.tcl
in the if statement in Wrapping/Tcl/vtk[ModuleName]/vtk[ModuleName].tcl

Where vtk[ModuleName].tcl is the entry point for any tcl code associated
with your module.

* You're ready to build; you can use Scripts/cmaker.tcl to automatically 
configure and make your module.


==========================
== Steps to build manually (without cmaker.tcl):

* cd to the builds directory and make a new
directory of the same name as the Slicer build you want to link with.
For example:
    cd builds /* now you're in /home/halazar/slicer2/Modules/vtkTest/builds */
    ls /home/halazar/slicer2/Base/builds

there should be a directory for your architecture.  For example, if
it's called "solaris8" then make a new build dir for your module
called solaris8.  Then go into that new dir.

    mkdir solaris8; cd solaris8



* Run CMake, using your toplevel module directory as the target.  To
  work with the curses interface, use:

    ccmake ../..

You can avoid curses by using the shortcut below to fill in the
location of your VTK build on the command line.  The example uses the
built VTK tree, but you could instead use the installed tree by
changing the variable to be VTK_INSTALL_PATH.

    ccmake -DVTK_BINARY_PATH:PATH=/local/os/src/vtk-4.0 ../..

* Configure your module.  Hopefully, all you'll have to do is type "c"
   a couple of times until the "g" option becomes available, then type
   "g" and files will generate and the program will complete.

* Make.

    make

* If all went well, your libraries will now be in the bin subdirectory.
	e.g. in

    /home/halazar/slicer2/Modules/vtkRegistration/bin/
     will be
    libvtkRegistration.so
    libvtkRegistrationTCL.so
    libvtkRegistrationPython.so (if Python was enabled in the vtk build)
