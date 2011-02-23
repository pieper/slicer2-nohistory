
proc testRigidRegistration {} {
    MainMrmlRead "Testing/TestData/imagetest/nrrd/reg.xml"
    MainUpdateMRML
    AffineMattesMIRegistrationGSlowParam
    set ::RigidIntensityRegistration(sourceId) 1
    set ::RigidIntensityRegistration(targetId) 2
    set ::Matrix(volume) 2
    set ::Matrix(refVolume) 1
    AffineMattesMIRegistrationAutoRun
    set tran   [::Matrix(0,node) GetTransform]
    set matrix [$tran GetMatrix]
    vtkMatrix4x4 regMatrix
    regMatrix DeepCopy $matrix

    if {[testMatrix regMatrix]} {
        exit 1
    } else {
        exit 0
    }
}

proc testAffineRegistration {} {
    MainMrmlRead "Testing/TestData/imagetest/nrrd/reg.xml"
    MainUpdateMRML
    VersorMattesMIRegistrationGSlowParam
    set ::RigidIntensityRegistration(sourceId) 1
    set ::RigidIntensityRegistration(targetId) 2
    set ::Matrix(volume) 2
    set ::Matrix(refVolume) 1
    VersorMattesMIRegistrationAutoRun
    set tran   [::Matrix(0,node) GetTransform]
    set matrix [$tran GetMatrix]
    vtkMatrix4x4 regMatrix
    regMatrix DeepCopy $matrix

    if {[testMatrix regMatrix]} {
        exit 1
    } else {
        exit 0
    }
}

proc testMatrix {matrix} {
    set tolR 0.1
    set tolT 0.2
    
    if {[expr abs([$matrix GetElement 0 0] - 1.0)] > $tolR} {
        return true
    }
    if {[expr abs([$matrix GetElement 0 1] - 0.0)] > $tolR} {
        return true
    }
    if {[expr abs([$matrix GetElement 0 2] - 0.0)] > $tolR} {
        return true
    }
    if {[expr abs([$matrix GetElement 0 3] - 5.0)] > $tolT} {
        return true
    }


    if {[expr abs([$matrix GetElement 1 0] - 0.0)] > $tolR} {
        return true
    }
    if {[expr abs([$matrix GetElement 1 1] - 0.9396)] > $tolR} {
        return true
    }
    if {[expr abs([$matrix GetElement 1 2] + 0.342)] > $tolR} {
        return true
    }
    if {[expr abs([$matrix GetElement 1 3] + 10.0)] > $tolT} {
        return true
    }


    if {[expr abs([$matrix GetElement 2 0] - 0.0)] > $tolR} {
        return true
    }
    if {[expr abs([$matrix GetElement 2 1] - 0.342)] > $tolR} {
        return true
    }
    if {[expr abs([$matrix GetElement 2 2] - 0.9396)] > $tolR} {
        return true
    }
    if {[expr abs([$matrix GetElement 2 3] - 15.0)] > $tolT} {
        return true
    }

    return false
}
