
proc LaurenThesisTractInfoInit {} {

    global LaurenThesis Volume


    set LaurenThesis(mTract)  ""

}


proc LaurenThesisTractInfoBuildGUI {} {

    global Gui LaurenThesis Module Volume Model

    #-------------------------------------------
    # TractInfo frame
    #-------------------------------------------
    set fTractInfo $Module(LaurenThesis,fTractInfo)
    set f $fTractInfo
    
    foreach frame "Top Middle Bottom" {
    frame $f.f$frame -bg $Gui(activeWorkspace)
    pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }
    
    #-------------------------------------------
    # TractInfo->Top frame
    #-------------------------------------------
    set f $fTractInfo.fTop
    DevAddLabel $f.lHelp "Count lines (fibers) and points in a tract model"
    pack $f.lHelp -side top -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # TractInfo->Middle frame
    #-------------------------------------------
    set f $fTractInfo.fMiddle
    foreach frame "Model" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    }

    #-------------------------------------------
    # TractInfo->Middle->Model frame
    #-------------------------------------------
    set f $fTractInfo.fMiddle.fModel

    # menu to select a volume: will set LaurenThesis(vROI)
    # works with DevUpdateNodeSelectButton in UpdateMRML
    set name mTract
    DevAddSelectButton  LaurenThesis $f $name "Tract Model:" Pack \
        "Tract model in which to count lines and points."\
        25

    #-------------------------------------------
    # TractInfo->Bottom frame
    #-------------------------------------------
    set f $fTractInfo.fBottom

    DevAddButton $f.bApply "Apply" \
        LaurenThesisTractInfoValidateParametersAndApply
    pack $f.bApply -side top -padx $Gui(pad) -pady $Gui(pad)
    TooltipAdd  $f.bApply "Label voxels with cluster ID."

}


proc LaurenThesisTractInfoUpdateMRML {} {

    global LaurenThesis

    # Update volume selection widgets if the MRML tree has changed
    # the one at the end allows labelmaps too
    DevUpdateNodeSelectButton Model LaurenThesis mTract mTract

}






proc LaurenThesisTractInfoValidateParametersAndApply {} {
    global LaurenThesis Volume

    puts "----------------------------------------------"    

    puts "Tract model ID: $LaurenThesis(mTract)"   

    if { $LaurenThesis(mTract) == ""} {
        puts "Please choose tract model."
        return
    }

    LaurenThesisTractInfo $LaurenThesis(mTract) 

}

proc LaurenThesisTractInfo {mTract} {

    global Model LaurenThesis

    puts "Model Name: [Model($mTract,node) GetName]"
    puts "Total Lines: [$Model($mTract,polyData) GetNumberOfLines]"
    puts "Total Points: [$Model($mTract,polyData) GetNumberOfPoints]"


}





