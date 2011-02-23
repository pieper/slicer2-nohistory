
proc TestPolyBoolean_3spheres {} {

    foreach i {1 2 3} {
        catch "sm$i Delete"
        vtkPolyDataMapper sm$i

        if {0} {
            catch "s$i Delete"
            vtkSphereSource s$i
            sm$i SetInput [s$i GetOutput]
        } else {
            catch "s$i Delete"
            vtkCubeSource s$i
            catch "tri$i Delete"
            vtkTriangleFilter tri$i 
            tri$i SetInput [s$i GetOutput]
            sm$i SetInput [tri$i GetOutput]
        }

        catch "sa$i Delete"
        vtkActor sa$i
        sa$i SetMapper sm$i

        catch "viewRen RemoveActor sa$i"
        viewRen AddActor sa$i

        catch "m$i Delete"
        vtkMatrix4x4 m$i
        for {set ii 0} {$ii < 3} {incr ii} {
            m$i SetElement $ii $ii 50
            m$i SetElement 0 3 [expr $i * 20]
            m$i SetElement 2 3 [expr $i * 20]
        }
        sa$i SetUserMatrix m$i
    }

    m$i SetElement 0 3 100

    Render3D
}

proc TestPolyBoolean_cutter {} {
    catch "pb Delete"
    vtkPolyBoolean pb
    pb SetOperation 0

    pb SetInput [tri1 GetOutput]
    pb SetXformA m1
    pb SetPolyDataB [tri2 GetOutput]
    pb SetXformB m2
    pb Update
    pb UpdateCutter

    set npts [[[pb GetOutput] GetPoints] GetNumberOfPoints]

    set ncells [[pb GetOutput] GetNumberOfCells]
    for {set cell 0} {$cell < $ncells} {incr cell} {
        set c [[pb GetOutput] GetCell $cell]
        set nids [[$c GetPointIds] GetNumberOfIds]
        for {set n 0} {$n < $nids} {incr n} {
            if { [[$c GetPointIds] GetId $n] < 0 } {
                [$c GetPointIds] SetId $n 0
                puts "bad cell neg id $cell"
            }
            if { [[$c GetPointIds] GetId $n] >= $npts } {
                [$c GetPointIds] SetId $n 0
                puts "bad cell big id $cell"
            }
        }
    }

    if {0} {
        catch "pdn Delete"
        vtkPolyDataNormals pdn 
        pdn SetInput [pb GetOutput]
        sm3 SetInput [pdn GetOutput]
    } else {
        sm3 SetInput [pb GetOutput]
    }

    Render3D
}

proc TestPolyBoolean_print {} {

    set npts [[[pb GetOutput] GetPoints] GetNumberOfPoints]

    for {set pt 0} {$pt < $npts} {incr pt} {
        puts "$pt: [[[pb GetOutput] GetPoints] GetPoint $pt]"
    }

    set ncells [[pb GetOutput] GetNumberOfCells]
    for {set cell 0} {$cell < $ncells} {incr cell} {
        set c [[pb GetOutput] GetCell $cell]
        puts "$cell: [$c GetCellType]"
        set nids [[$c GetPointIds] GetNumberOfIds]
        for {set n 0} {$n < $nids} {incr n} {
            puts -nonewline " [[$c GetPointIds] GetId $n]"
        }
        puts ""
    }
}

proc test {} {
    TestPolyBoolean_3spheres
    TestPolyBoolean_cutter
}



