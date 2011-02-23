#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: EMAtlasBrainClassifier.tcl,v $
#   Date:      $Date: 2008/07/18 05:25:53 $
#   Version:   $Revision: 1.50 $
# 
#===============================================================================
# FILE:        EMAtlasBrainClassifier.tcl
# PROCEDURES:  
#   EMAtlasBrainClassifierInit
#   EMAtlasBrainClassifierBuildGUI
#   EMAtlasBrainClassifierBuildVTK
#   EMAtlasBrainClassifierEnter
#   EMAtlasBrainClassifierExit
#   EMAtlasBrainClassifierUpdateMRML
#   EMAtlasBrainClassifierDefineNodeAttributeList MrmlNodeType
#   EMAtlasBrainClassifierChangeAlgorithm 
#   EMAtlasBrainClassifierDefineWorkingDirectory
#   EMAtlasBrainClassifierDefineAtlasDir
#   EMAtlasBrainClassifierDefineXMLTemplate
#   EMAtlasBrainClassifierCreateClasses   class
#   EMAtlasBrainClassifierVolumeWriter VolID
#   EMAtlasBrainClassifierLoadAtlasVolume GeneralDir AtlasDir AtlasName
#   EMAtlasBrainClassifierResetEMSegment
#   EMAtlasBrainClassifierDeleteAllVolumeNodesButSPGRAndT2W
#   EMAtlasBrainClassifier_InitilizePipeline 
#   EMAtlasBrainClassifierReadXMLFile FileName
#   EMAtlasBrainClassifierGrepLine input search_string
#   EMAtlasBrainClassifierReadNextKey input
#   EMAtlasBrainClassifier_Normalize VolIDInput VolIDOutput Mode
#   EMAtlasBrainClassifier_NormalizeVolume vol out Mode
#   EMAtlasBrainClassifier_AtlasList 
#   EMAtlasBrainClassifier_GetNumberOfTrainingSamples 
#   EMAtlasBrainClassifier_RegistrationInitialize  RegisterAtlasDirList
#   EMAtlasBrainClassifier_AtlasRegistration  RegisterAtlasDirList RegisterAtlasNameList
#   EMAtlasBrainClassifier_LoadAtlas RegisterAtlasDirList RegisterAtlasNameList
#   EMAtlasBrainClassifierDownloadAtlas
#   EMAtlasBrainClassifierRegistration inTarget inSource
#   EMAtlasBrainClassifierWriteTransformation
#   EMAtlasBrainClassifierResample inTarget inSource outResampled
#   EMAtlasBrainClassifier_GenerateModels
#   EMAtlasBrainClassifier_InitilizeSegmentation
#   EMAtlasBrainClassifierDeleteClasses   class
#   EMAtlasBrainClassifierInitializeValues 
#   EMAtlasBrainClassifier_StartEM 
#   EMAtlasBrainClassifier_StartEM
#   EMAtlasBrainClassifier_SetVtkGenericClassSetting vtkGenericClass Sclass
#   EMAtlasBrainClassifier_SetVtkAtlasSuperClassSetting SuperClass
#   EMAtlasBrainClassifier_AlgorithmStart
#   EMAtlasBrainClassifier_DeleteVtkEMSuperClass Superclass
#   EMAtlasBrainClassifier_DeleteVtkEMAtlasBrainClassifier
#   EMAtlasBrainClassifier_SaveSegmentation
#   EMAtlasBrainClassifierStartSegmentation
#   EMAtlasBrainClassifier_BatchMode 
#==========================================================================auto=

##################
# Gui - Slicer 
##################

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierInit {} {
    global EMAtlasBrainClassifier Module Volume env Mrml tcl_platform 

    set m EMAtlasBrainClassifier

    set Module($m,overview) "Easy to use segmentation tool for brain MRIs"
    set Module($m,author)   "Kilian, Pohl, MIT, pohl@csail.mit.edu"
    set Module($m,category) "Segmentation"

    set Module($m,row1List) "Help Segmentation Advanced"
    set Module($m,row1Name) "{Help} {Segmentation} {Advanced}"
    set Module($m,row1,tab) Segmentation

    #   procStorePresets  = Called when the user holds down one of the Presets
    #               buttons.
    #               
    #   Note: if you use presets, make sure to give a preset defaults
    #   string in your init function, of the form: 
    #   set Module($m,presets) "key1='val1' key2='val2' ..."
    #   
    set Module($m,procGUI)   EMAtlasBrainClassifierBuildGUI
    set Module($m,procVTK)   EMAtlasBrainClassifierBuildVTK
    set Module($m,procEnter) EMAtlasBrainClassifierEnter
    set Module($m,procExit)  EMAtlasBrainClassifierExit
    set Module($m,procMRML)  EMAtlasBrainClassifierUpdateMRML

    # Define Dependencies
    #------------------------------------
    # Description:
    #   Record any other modules that this one depends on.  This is used 
    #   to check that all necessary modules are loaded when Slicer runs.
    #   
    # Kilian: I  currently deactivated it so I wont get nestay error messages 
    set Module($m,depend) ""

    lappend Module(versions) [ParseCVSInfo $m \
                                  {$Revision: 1.50 $} {$Date: 2008/07/18 05:25:53 $}]


    set EMAtlasBrainClassifier(Volume,SPGR) $Volume(idNone)
    set EMAtlasBrainClassifier(Volume,T2W)  $Volume(idNone)
    set EMAtlasBrainClassifier(Save,AlignedT2) 1 
    set EMAtlasBrainClassifier(Save,SPGR)    0
    set EMAtlasBrainClassifier(Save,T2W)     0
    set EMAtlasBrainClassifier(Save,Atlas)   1
    set EMAtlasBrainClassifier(Save,Segmentation) 1
    set EMAtlasBrainClassifier(Save,XMLFile) 1
    set EMAtlasBrainClassifier(Save,Models) 1


    set EMAtlasBrainClassifier(GenerateModels) 1
    set EMAtlasBrainClassifier(SegmentIndex) 0
    set EMAtlasBrainClassifier(MaxInputChannelDef) 0
    set EMAtlasBrainClassifier(CIMList) {West North Up East South Down}
    
    set EMAtlasBrainClassifier(AlignInput) 0
    
    # Debug 
    set EMAtlasBrainClassifier(WorkingDirectory) "$Mrml(dir)/EMSeg"    
    set EMAtlasBrainClassifier(DefaultAtlasDir)  "$env(SLICER_HOME)/Modules/vtkEMAtlasBrainClassifier/atlas"   
    set EMAtlasBrainClassifier(AtlasDir)         $EMAtlasBrainClassifier(DefaultAtlasDir)  
    set EMAtlasBrainClassifier(XMLTemplate)      "$env(SLICER_HOME)/Modules/vtkEMAtlasBrainClassifier/data/template5_c2.xml"     
    
    # Variables for normalization ! 
    set EMAtlasBrainClassifier(Normalize,SPGR) "90"
    # For some images you need to adjust filter width to detect changes as the second and first peak in the intensity histogram are too close together 
    # The smaller the value the larger the initial width of the filter
    # Carefull - changing the width scale will impact the calculation of the expected value and therefore will normalize it slightly differntly 
    # Kilian: Change it by having the x value at the middle of the filter width and not begining - how it is right now     
    set EMAtlasBrainClassifier(InitialWidthScale,SPGR) 5
    set EMAtlasBrainClassifier(Normalize,T2W)  "310"
    set EMAtlasBrainClassifier(InitialWidthScale,T2W) 5
    # Alternative Setting with similar scaling factor 
    # set EMAtlasBrainClassifier(Normalize,T2W)  "329"
    # set EMAtlasBrainClassifier(InitialWidthScale,T2W) 10
   
    set EMAtlasBrainClassifier(MultiThreading) 0 
    set EMAtlasBrainClassifier(AlgorithmVersion) "Standard" 
    set EMAtlasBrainClassifier(NonRigidRegistrationFlag) 1
    
    set EMAtlasBrainClassifier(LatestLabelMap) $Volume(idNone)
    
    if {$tcl_platform(byteOrder) == "littleEndian"} {
        set EMAtlasBrainClassifier(LittleEndian) 1
    } else {
        set EMAtlasBrainClassifier(LittleEndian) 0 
    }
    
    # Initialize values 
    set EMAtlasBrainClassifier(MrmlNode,TypeList) "Segmenter SegmenterInput SegmenterSuperClass SegmenterClass SegmenterCIM"
    
    foreach NodeType "$EMAtlasBrainClassifier(MrmlNode,TypeList) SegmenterGenericClass" {
        set blubList [EMAtlasBrainClassifierDefineNodeAttributeList $NodeType]
        set EMAtlasBrainClassifier(MrmlNode,$NodeType,SetList)       [lindex $blubList 0]
        set EMAtlasBrainClassifier(MrmlNode,$NodeType,SetListLower)  [lindex $blubList 1]
        set EMAtlasBrainClassifier(MrmlNode,$NodeType,AttributeList) [lindex $blubList 2]
        set EMAtlasBrainClassifier(MrmlNode,$NodeType,InitValueList) [lindex $blubList 3]
    }
    
    set EMAtlasBrainClassifier(MrmlNode,JointSegmenterSuperClassAndClass,AttributeList) "$EMAtlasBrainClassifier(MrmlNode,SegmenterGenericClass,AttributeList) $EMAtlasBrainClassifier(MrmlNode,SegmenterSuperClass,AttributeList) $EMAtlasBrainClassifier(MrmlNode,SegmenterClass,AttributeList)"
    set EMAtlasBrainClassifier(MrmlNode,JointSegmenterSuperClassAndClass,InitValueList) "$EMAtlasBrainClassifier(MrmlNode,SegmenterGenericClass,InitValueList) $EMAtlasBrainClassifier(MrmlNode,SegmenterSuperClass,InitValueList) $EMAtlasBrainClassifier(MrmlNode,SegmenterClass,InitValueList)"
    
    foreach ListType "SetList SetListLower AttributeList InitValueList" {
        set EMAtlasBrainClassifier(MrmlNode,SegmenterSuperClass,$ListType) "$EMAtlasBrainClassifier(MrmlNode,SegmenterGenericClass,$ListType) $EMAtlasBrainClassifier(MrmlNode,SegmenterSuperClass,$ListType)"
        set EMAtlasBrainClassifier(MrmlNode,SegmenterClass,$ListType) "$EMAtlasBrainClassifier(MrmlNode,SegmenterGenericClass,$ListType) $EMAtlasBrainClassifier(MrmlNode,SegmenterClass,$ListType)"
    }
    
    
    
    # The second time around it is not deleted              
    set EMAtlasBrainClassifier(Cattrib,-1,ClassList) ""
    set EMAtlasBrainClassifier(SuperClass) -1
    set EMAtlasBrainClassifier(ClassIndex) 0
    set EMAtlasBrainClassifier(SelVolList,VolumeList) ""        
    EMAtlasBrainClassifierCreateClasses -1 1 
    
    set EMAtlasBrainClassifier(SuperClass) 0 
    set EMAtlasBrainClassifier(Cattrib,0,IsSuperClass) 1
    set EMAtlasBrainClassifier(Cattrib,0,Name) "Head"
    set EMAtlasBrainClassifier(Cattrib,0,Label) $EMAtlasBrainClassifier(Cattrib,0,Name)
    set EMAtlasBrainClassifier(BatchMode) 0
    set EMAtlasBrainClassifier(SegmentationMode) EMAtlasBrainClassifier
    
    set EMAtlasBrainClassifier(eventManager) {}
    set EMAtlasBrainClassifier(fileformat) "nhdr"
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierBuildGUI
# Build Gui
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierBuildGUI {} {
    global Gui EMAtlasBrainClassifier Module Volume 
    
    set help "The module automatically segments brain MRIs into the tissue classes (white matter, gray matter, and cortical spinal fluid). In order to run the module the following steps have to be completed :"
    set help "$help<BR><B>1. Step: Select Input channels</B>"
    set help "$help<BR>- Select the volumes (T1 with corresponding T2), which the module should segment."
    set help "$help<BR>- Select the \"on\" button if the T2 volume is not aligned with the T1 volume." 
    set help "$help<BR><B>2. Step: Define Parameter</B>"
    set help "$help<BR>- Select the \"on\" button if the segmentation results should be saved to a file" 
    set help "$help<BR>- Select the \"on\" button if 3D models of the segmentations should be generated"
    set help "$help<BR>- Define the (working) directory, in which the results of this module should be saved to" 
    set help "$help<BR><B>Press the \"Start Segmentation\" to generate the automatic segmentations</B>"
    set help "$help<BR><P><B>Warning:</B>: this process might take longer because we first have to non-rigidly register the atlas to the patient. It may not be possible to run this process to completion on Windows, due to memory allocation constraints." 
    set help "$help<BR><P><B>Note:</B>: The approach was originally defined for a protocol generating SPGR (Dim: 0.9375x0.9375x1.5 Scan Order: PA) and T2 (Dim: 0.9375x0.9375x3 Scan Order: PA). For further information please read:
 K.M. Pohl, S. Bouix, M.E. Shenton, W.E.L. Grimson, R. Kikinis,\" Automatic Segmentation Using Non-Rigid Registration\" In short communications of MICCAI 2005: Eigth International Conference on Medical Image Computing and Computer Assisted Intervention, Palm Springs, CA, USA, 2005 "

    regsub -all "\n" $help {} help
    MainHelpApplyTags EMAtlasBrainClassifier $help
    MainHelpBuildGUI EMAtlasBrainClassifier
    
    #-------------------------------------------
    # Segementation frame
    #-------------------------------------------
    set fSeg $Module(EMAtlasBrainClassifier,fSegmentation)
    set f $fSeg
    
    foreach frame "Step1 Step2" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }
    
    #-------------------------------------------
    # 1. Step 
    #-------------------------------------------
    set f $fSeg.fStep1
    
    DevAddLabel $f.lTitle "1. Select Input Channels: " WTA
    pack $f.lTitle -side top -padx $Gui(pad) -pady 1 -anchor w
    
    
    frame $f.fInput -bg $Gui(activeWorkspace)
    pack $f.fInput -side top -padx 0 -pady 0  -anchor w
    
    foreach frame "Left Right" {
        frame $f.fInput.f$frame -bg $Gui(activeWorkspace)
        pack $f.fInput.f$frame -side left -padx 0 -pady $Gui(pad)
    }
    

    foreach LABEL "T1 T2" Input "SPGR T2W" {
        DevAddLabel $f.fInput.fLeft.l$Input "  ${LABEL}:"
        pack $f.fInput.fLeft.l$Input -side top -padx $Gui(pad) -pady 1 -anchor w

        
        set menubutton   $f.fInput.fRight.m${Input}Select 
        set menu        $f.fInput.fRight.m${Input}Select.m
        
        eval {menubutton $menubutton -text [Volume($EMAtlasBrainClassifier(Volume,${Input}),node) GetName] -relief raised -bd 2 -width 9 -menu $menu} $Gui(WMBA)
        eval {menu $menu} $Gui(WMA)
        TooltipAdd $menubutton "Select Volume defining ${Input}" 
        set EMAtlasBrainClassifier(mbSeg-${Input}Select) $menubutton
        set EMAtlasBrainClassifier(mSeg-${Input}Select) $menu
        # Have to update at UpdateMRML too 
        DevUpdateNodeSelectButton Volume EMAtlasBrainClassifier Seg-${Input}Select Volume,$Input
        
        pack $menubutton -side top  -padx $Gui(pad) -pady 1 -anchor w
    }


    frame $f.fAlign -bg $Gui(activeWorkspace)
    TooltipAdd  $f.fAlign "If the input T1 and T2 are not aligned with each other set flag here" 
    pack $f.fAlign -side top -padx 0 -pady 2  -padx $Gui(pad) -anchor w
    
    
    DevAddLabel $f.fAlign.lAlign "Align T2 to T1? "
    pack $f.fAlign.lAlign -side left -padx $Gui(pad) -pady 1 -anchor w
    
    foreach value "1 0" text "On Off" width "4 4" {
        eval {radiobutton $f.fAlign.r$value -width $width -indicatoron 0\
                  -text "$text" -value "$value" -variable EMAtlasBrainClassifier(AlignInput) } $Gui(WCA)
        pack $f.fAlign.r$value -side left -padx 0 -pady 0 
    }
    
    #-------------------------------------------
    # 2. Step 
    #-------------------------------------------
    set f $fSeg.fStep2

    DevAddLabel $f.lTitle "2. Define Parameter Settings: " WTA
    pack $f.lTitle -side top -padx $Gui(pad) -pady 0 -anchor w

    foreach frame "Left Right" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side left -padx 0 -pady $Gui(pad)
    }

    DevAddLabel $f.fLeft.lModels "  Generate 3D Models:" 
    pack $f.fLeft.lModels -side top -padx $Gui(pad) -pady 2  -anchor w

    frame $f.fRight.fModels -bg $Gui(activeWorkspace)
    TooltipAdd  $f.fRight.fModels "Automatically generate 3D Models of the segmentations" 

    pack $f.fRight.fModels -side top -padx 0 -pady 2  -anchor w
    
    foreach value "1 0" text "On Off" width "4 4" {
        eval {radiobutton $f.fRight.fModels.r$value -width $width -indicatoron 0\
                  -text "$text" -value "$value" -variable EMAtlasBrainClassifier(GenerateModels) } $Gui(WCA)
        pack $f.fRight.fModels.r$value -side left -padx 0 -pady 0 
    }
    
    # Now define working directory
    DevAddLabel $f.fLeft.lWorking "  Working Directory:" 
    pack $f.fLeft.lWorking -side top -padx $Gui(pad) -pady 2  -anchor w
    
    frame $f.fRight.fWorking -bg $Gui(activeWorkspace)
    TooltipAdd  $f.fRight.fWorking "Working directory in which any results of the segmentations should be saved in" 
    pack $f.fRight.fWorking -side top -padx 0 -pady 2 -anchor w
    
    eval {entry  $f.fRight.fWorking.eDir   -width 15 -textvariable EMAtlasBrainClassifier(WorkingDirectory) } $Gui(WEA)
    eval {button $f.fRight.fWorking.bSelect -text "..." -width 2 -command "EMAtlasBrainClassifierDefineWorkingDirectory"} $Gui(WBA)     
    pack $f.fRight.fWorking.eDir  $f.fRight.fWorking.bSelect -side left -padx 0 -pady 0  
    
    DevAddLabel $f.fLeft.lOutput "  Save Segmentation:" 
    pack $f.fLeft.lOutput -side top -padx $Gui(pad) -pady 2  -anchor w

    frame $f.fRight.fOutput -bg $Gui(activeWorkspace)
    TooltipAdd  $f.fRight.fOutput "Automatically save the segmentation results to the working directory" 

    pack $f.fRight.fOutput -side top -padx 0 -pady 2  -anchor w

    foreach value "1 0" text "On Off" width "4 4" {
        eval {radiobutton $f.fRight.fOutput.r$value -width $width -indicatoron 0\
                  -text "$text" -value "$value" -variable EMAtlasBrainClassifier(Save,Segmentation) } $Gui(WCA)
        pack $f.fRight.fOutput.r$value -side left -padx 0 -pady 0 
    }


    #-------------------------------------------
    # Run Algorithm
    #------------------------------------------
    eval {button $fSeg.bRun -text "Start Segmentation" -width 20 -command "EMAtlasBrainClassifierStartSegmentation"} $Gui(WBA) 
    $fSeg.bRun configure -font {helvetica 8 bold}  
    pack $fSeg.bRun -side top -padx 2 -pady 2  

    #-------------------------------------------
    # Segementation frame
    #-------------------------------------------
    set fSeg $Module(EMAtlasBrainClassifier,fAdvanced)
    set f $fSeg

    foreach frame "Save Algo Misc" {
        frame $f.f$frame -bg $Gui(activeWorkspace) -relief sunken -bd 2
        pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }

    DevAddLabel $f.fSave.lTitle "Save"  
    pack $f.fSave.lTitle -side top -padx $Gui(pad) -pady 2 

    foreach Att "AlignedT2 SPGR T2W Atlas XMLFile Models"  Text "{Aligned T2} {Normalized T1} {Normalized T2} {Aligned Atlas} {XML-File} {3D Models}" {
        eval {checkbutton  $f.fSave.c$Att -text "$Text" -variable EMAtlasBrainClassifier(Save,$Att) -indicatoron 1} $Gui(WCA)
        pack $f.fSave.c$Att  -side top -padx $Gui(pad) -pady 0 -anchor w 
    }

    frame $f.fSave.fFileType -bg $Gui(activeWorkspace)
    pack $f.fSave.fFileType -side top -padx 0 -pady $Gui(pad) -fill x
    
    DevAddLabel $f.fSave.fFileType.lFileType "  Select File Type:"
    pack $f.fSave.fFileType.lFileType -side left -padx 0 -pady 0  -anchor w
    frame $f.fSave.fFileType.fFileType -bg $Gui(activeWorkspace)
    
    eval {menubutton $f.fSave.fFileType.mbType -text "NRRD(.nhdr)    " \
              -relief raised -bd 2 -width 20 \
              -menu $f.fSave.fFileType.mbType.m} $Gui(WMBA)
    eval {menu $f.fSave.fFileType.mbType.m} $Gui(WMA)
    pack  $f.fSave.fFileType.mbType -side left -padx 2 -pady 0  -anchor w
    
    #  Add menu items
    foreach FileType {{Standard} {hdr} {nrrd} {nhdr} {mhd} {mha} {nii} {img} {img.gz} {vtk}} \
        name {{"Headerless"} {"Analyze (.hdr)"} {"NRRD(.nrrd)"} {"NRRD(.nhdr)"} {"Meta (.mhd)"} {"Meta (.mha)"} {"Nifti (.nii)"} {"Nifti (.img)"} {"Nifti (.img.gz)"} {"VTK (.vtk)"}} {
            set Editor($FileType) $name
            $f.fSave.fFileType.mbType.m add command -label $name \
                -command "EMAtlasBrainClassifierVolumesSetFileType $FileType"
        }
    
    # save menubutton for config
    set Volume(gui,mbSaveEMAtlasFileType) $f.fSave.fFileType.mbType
    # put a tooltip over the menu
    TooltipAdd $f.fSave.fFileType.mbType \
        "Choose file type."
    
    frame $f.fSave.fCompression -bg $Gui(activeWorkspace)
    pack $f.fSave.fCompression -side top -padx 0 -pady 0 -fill x
    
    DevAddLabel $f.fSave.fCompression.lCompr "  Use Compression:"
    pack $f.fSave.fCompression.lCompr -side left -padx 0 -pady 0  -anchor w
    
    frame $f.fSave.fCompression.fCompr -bg $Gui(activeWorkspace)
    
    foreach value "1 0" text "On Off" width "4 4" {
        eval {radiobutton $f.fSave.fCompression.fCompr.rComp$value -width $width -indicatoron 0\
                  -text "$text" -value "$value" -variable Volume(UseCompression) \
              } $Gui(WCA)
        pack $f.fSave.fCompression.fCompr.rComp$value -side left -fill x
    }
    TooltipAdd $f.fSave.fCompression.fCompr.rComp1 \
        "Suggest to the Writer to compress the file if the format supports it."
    TooltipAdd $f.fSave.fCompression.fCompr.rComp0 \
        "Don't compress the file, even if the format supports it."
    pack $f.fSave.fCompression.fCompr -side left -padx 2 -pady 0  -anchor w


    DevAddLabel $f.fAlgo.lTitle "Segmentation Algorithm"  
    pack $f.fAlgo.lTitle -side top -padx $Gui(pad) -pady 2 
    set Tip(Standard) "Validated version using non-rigid registration for the atlas alignment.\nThis method is computationally expensive."  
    set Tip(Rigid) "Like Standard but uses an affine registration for the atlas alignment.\nThis method is generally more robust then Standard but often achieves a lower\nquality when Standard converges."
    set Tip(RegSeg) "Performs registration and segmentation jointly. This method generally achieves very good results but is very slow." 

    foreach Value "Standard Rigid RegSeg"  Text "{Standard} {Standard with Affine Registration} {Joint Registration and Segmentation}" {
        frame $f.fAlgo.f$Value -bg $Gui(activeWorkspace) 
        pack $f.fAlgo.f$Value  -side top -padx $Gui(pad) -pady 0 -fill x
        TooltipAdd $f.fAlgo.f$Value "$Tip($Value)"
        eval {radiobutton $f.fAlgo.f$Value.rbutton -variable EMAtlasBrainClassifier(AlgorithmVersion) -command EMAtlasBrainClassifierChangeAlgorithm -value $Value -indicatoron 1} $Gui(WCA)
        DevAddLabel $f.fAlgo.f$Value.lText "$Text"

        pack $f.fAlgo.f$Value.rbutton $f.fAlgo.f$Value.lText -side left -padx 0 -pady 0 
    }


    DevAddLabel $f.fMisc.lTitle "Miscellaneous"  
    pack  $f.fMisc.lTitle -side top -padx $Gui(pad) -pady 2 

    
    foreach frame "Left Right" {
        frame $f.fMisc.f$frame -bg $Gui(activeWorkspace)
        pack $f.fMisc.f$frame -side left -padx 0 -pady $Gui(pad)
    }

    DevAddLabel $f.fMisc.fLeft.lMultiThread "Multi Threading:"
    pack $f.fMisc.fLeft.lMultiThread  -side top -padx $Gui(pad) -pady 2 -anchor w 
    frame  $f.fMisc.fRight.fMultiThread -bg $Gui(activeWorkspace)
    pack $f.fMisc.fRight.fMultiThread -side top -padx 2 -pady 2  -anchor w 
    foreach value "1 0" text "On Off" width "4 4" {
        eval {radiobutton $f.fMisc.fRight.fMultiThread.r$value -width $width -indicatoron 0\
                  -text "$text" -value "$value" -variable  EMAtlasBrainClassifier(MultiThreading) } $Gui(WCA)
    }
    pack $f.fMisc.fRight.fMultiThread.r0 $f.fMisc.fRight.fMultiThread.r1 -side left -fill x

    foreach Att "XMLTemplate AtlasDir" Text "{XML-Template File} {Atlas Directory}" Help "{XML Template file to be used for the segmentation} {Location of the atlases which define spatial distribtution}" {
        DevAddLabel $f.fMisc.fLeft.l$Att "${Text}:"  
        pack $f.fMisc.fLeft.l$Att -side top -padx 2 -pady 2  -anchor w 
        
        frame $f.fMisc.fRight.f$Att  -bg $Gui(activeWorkspace)
        pack $f.fMisc.fRight.f$Att -side top -padx 2 -pady 2  
        
        eval {entry  $f.fMisc.fRight.f$Att.eFile   -width 15 -textvariable EMAtlasBrainClassifier($Att) } $Gui(WEA)
        eval {button $f.fMisc.fRight.f$Att.bSelect -text "..." -width 2 -command "EMAtlasBrainClassifierDefine$Att"} $Gui(WBA)     
        pack $f.fMisc.fRight.f$Att.eFile  $f.fMisc.fRight.f$Att.bSelect -side left -padx 0 -pady 0 
        TooltipAdd  $f.fMisc.fRight.f$Att  "$Help" 
    }
}
#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierBuildVTK
# Build any vtk objects you wish here
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierBuildVTK {} {

}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierEnter
# Called when this module is entered by the user.  Pushes the event manager
# for this module. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierEnter {} {
    global EMAtlasBrainClassifier

    # Push event manager
    #------------------------------------
    # Description:
    #   So that this module's event bindings don't conflict with other 
    #   modules, use our bindings only when the user is in this module.
    #   The pushEventManager routine saves the previous bindings on 
    #   a stack and binds our new ones.
    #   (See slicer/program/tcl-shared/Events.tcl for more details.)
    pushEventManager $EMAtlasBrainClassifier(eventManager)
    set WarningMsg ""
    if {[catch "package require vtkAG"]} {
        set WarningMsg "${WarningMsg}- vtkAG" 
    }

    if {$WarningMsg != ""} {DevWarningWindow "Please install the following modules before working with this module: \n$WarningMsg"}
}


#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierExit
# Called when this module is exited by the user.  Pops the event manager
# for this module.  
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierExit {} {

    # Pop event manager
    #------------------------------------
    # Description:
    #   Use this with pushEventManager.  popEventManager removes our 
    #   bindings when the user exits the module, and replaces the 
    #   previous ones.
    #
    popEventManager
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierUpdateMRML
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierUpdateMRML { } { 
    global EMAtlasBrainClassifier
    DevUpdateNodeSelectButton Volume EMAtlasBrainClassifier Seg-SPGRSelect Volume,SPGR
    DevUpdateNodeSelectButton Volume EMAtlasBrainClassifier Seg-T2WSelect  Volume,T2W
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierDefineNodeAttributeList
# Filters out all the SetCommands of a node 
# .ARGS
# string MrmlNodeType
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierDefineNodeAttributeList {MrmlNodeType} {
    set SetList ""          
    set SetListLower ""
    set AttributeList ""
    set InitList ""

    if {[info command vtkMrml${MrmlNodeType}Node] == ""} {
        DevErrorWindow "EMAtlasBrainClassifier: error, no node of type vtkMrml${MrmlNodeType}Node defined.\nModule vtkEMLocalSegment may not have loaded properly."
        return ""
    }

    vtkMrml${MrmlNodeType}Node blub
    set nMethods [blub ListMethods]

    set MrmlAtlasNodeType vtkMrmlSegmenterAtlas[string range $MrmlNodeType 9 end]Node:
    if {([lsearch $nMethods $MrmlAtlasNodeType] > -1)} {
        set StartSearch $MrmlAtlasNodeType
    } else {
        set StartSearch vtkMrml${MrmlNodeType}Node:
    }

    set nMethods "[lrange $nMethods [expr [lsearch $nMethods $StartSearch]+ 1] end]"

    foreach index [lsearch -glob -all $nMethods  Set*] {
        set SetCommand  [lindex $nMethods $index]
        if {[lsearch -exact $SetList $SetCommand] < 0} {
            lappend SetList $SetCommand
            lappend SetListLower [string tolower $SetCommand] 
            set Attribute [string range $SetCommand 3 end] 
            lappend AttributeList $Attribute
            lappend InitList "[blub Get$Attribute]" 
        }
    }
    blub Delete

    return "{$SetList} {$SetListLower} {$AttributeList} {$InitList}" 
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierChangeAlgorithm 
# Sets the flags correctly for the different algorithm versions
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierChangeAlgorithm { } { 
    global EMAtlasBrainClassifier env
    
    switch $EMAtlasBrainClassifier(AlgorithmVersion) {
        "Standard" { set EMAtlasBrainClassifier(NonRigidRegistrationFlag)  1
            set EMAtlasBrainClassifier(SegmentationMode) "EMAtlasBrainClassifier"
            set EMAtlasBrainClassifier(XMLTemplate)      "$env(SLICER_HOME)/Modules/vtkEMAtlasBrainClassifier/data/template5_c2.xml"


        }
        "Rigid"    { set EMAtlasBrainClassifier(NonRigidRegistrationFlag)  0
            set EMAtlasBrainClassifier(SegmentationMode) "EMAtlasBrainClassifier"
            set EMAtlasBrainClassifier(XMLTemplate)      "$env(SLICER_HOME)/Modules/vtkEMAtlasBrainClassifier/data/template5_c2.xml"

        }
        "RegSeg"   { 
            set EMAtlasBrainClassifier(NonRigidRegistrationFlag)  0
            if { $EMAtlasBrainClassifier(SegmentationMode) == "EMAtlasBrainClassifier" } {
                set EMAtlasBrainClassifier(SegmentationMode)     "EMLocalSegment"
            }
            set EMAtlasBrainClassifier(XMLTemplate)      "$env(SLICER_HOME)/Modules/vtkEMAtlasBrainClassifier/data/template5_c2-regseg.xml"
        }
        default {
            DevErrorWindow "Do not understand EMAtlasBrainClassifier(AlgorithmVersion) with value $EMAtlasBrainClassifier(AlgorithmVersion)" 
            return 
        }
    }
}





#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierDefineWorkingDirectory
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierDefineWorkingDirectory {} {
    global EMAtlasBrainClassifier
    set dir [tk_chooseDirectory -initialdir $EMAtlasBrainClassifier(WorkingDirectory)]
    if { $dir == "" } {
        return
    }
    set EMAtlasBrainClassifier(WorkingDirectory) "$dir"    
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierDefineAtlasDir
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierDefineAtlasDir {} {
    global EMAtlasBrainClassifier
    set dir [tk_chooseDirectory -initialdir $EMAtlasBrainClassifier(AtlasDir) -title "Atlas Directory"]
    if { $dir == "" } {
        return
    }
    set EMAtlasBrainClassifier(AtlasDir) "$dir"    
}


#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierDefineXMLTemplate
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierDefineXMLTemplate {} {
    global EMAtlasBrainClassifier
    set file [tk_getOpenFile -title "XML Template File" -filetypes {{XML {.xml} }} -defaultextension .xml -initialdir [file dirname $EMAtlasBrainClassifier(XMLTemplate)]]
    if { $file == "" } {
        return
    }
    set EMAtlasBrainClassifier(XMLTemplate) "$file"    
}



##################
# Miscelaneous 
##################

#-------------------------------------------------------------------------------
# .PROC  EMAtlasBrainClassifierCreateClasses  
# Create classes
# .ARGS
# SuperClass class to start with 
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierCreateClasses {SuperClass Number} {
    global EMAtlasBrainClassifier Volume

    set Cstart $EMAtlasBrainClassifier(ClassIndex)
    incr EMAtlasBrainClassifier(ClassIndex) $Number 
    for {set i $Cstart} {$i < $EMAtlasBrainClassifier(ClassIndex) } {incr i 1} {
        lappend EMAtlasBrainClassifier(Cattrib,$SuperClass,ClassList) $i 
        foreach NodeAttribute "$EMAtlasBrainClassifier(MrmlNode,JointSegmenterSuperClassAndClass,AttributeList)" InitValue "$EMAtlasBrainClassifier(MrmlNode,JointSegmenterSuperClassAndClass,InitValueList)" {
            set EMAtlasBrainClassifier(Cattrib,$i,$NodeAttribute) "$InitValue"  
        }
        set EMAtlasBrainClassifier(Cattrib,$i,Prob) 0.0 
        set EMAtlasBrainClassifier(Cattrib,$i,ClassList) ""
        set EMAtlasBrainClassifier(Cattrib,$i,IsSuperClass) 0

        for {set y 0} {$y <  $EMAtlasBrainClassifier(MaxInputChannelDef)} {incr y} {
            set  EMAtlasBrainClassifier(Cattrib,$i,LogMean,$y) -1
            for {set x 0} {$x <  $EMAtlasBrainClassifier(MaxInputChannelDef)} {incr x} { 
                set EMAtlasBrainClassifier(Cattrib,$i,LogCovariance,$y,$x) 0.0
            }
        }
        set EMAtlasBrainClassifier(Cattrib,$i,ProbabilityData) $Volume(idNone)
        set EMAtlasBrainClassifier(Cattrib,$i,ReferenceStandardData) $Volume(idNone)
        for {set j $Cstart} {$j < $EMAtlasBrainClassifier(ClassIndex) } {incr j 1} {
            foreach k $EMAtlasBrainClassifier(CIMList) {
                if {$i == $j} {set EMAtlasBrainClassifier(Cattrib,$SuperClass,CIMMatrix,$i,$j,$k) 1
                } else {set EMAtlasBrainClassifier(Cattrib,$SuperClass,CIMMatrix,$i,$j,$k) 0}
            }
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierVolumeWriter
# 
# .ARGS
# int VolID volume id specifying what to write out
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierVolumeWriter {VolID} {
    global EMAtlasBrainClassifier Volume Editor 

    set prefix [MainFileGetRelativePrefix [Volume($VolID,node) GetFilePrefix]]
    
    # Note : I changed vtkMrmlDataVolume.cxx so that MainVolumeWrite also works for 
    #        for volumes that do not start at slice 1. If it does not get checked into 
    #        the general version just do the following to overcome the problem after
    #        executing MainVolumesWrite:
    #        - Check if largest slice m is present 
    #        - if not => slices start at 1 .. n => move everything to m -n + 1 ,..., m 

    #Katharina 08/25/06: commented in order to enable saving in different file formats
    #set FileFormat $EMAtlasBrainClassifier(fileformat)
    #set EMAtlasBrainClassifier(fileformat) "Standard" 

    set Name [Volume($VolID,node) GetName]

    #Katharina 08/25/06: MainVolumesWrite determines the fileformat by 
    #the value of Editor(fileformat)
    set Editor(fileformat) $EMAtlasBrainClassifier(fileformat)
    MainVolumesWrite $VolID $prefix 
    
    # Kilian: MainVolumesWrite changes name 
    Volume($VolID,node) SetName "$Name"
    
    #Katharina 08/25/06: commented in order to enable saving in different file formats
    #set EMAtlasBrainClassifier(fileformat) $FileFormat
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierVolumesSetFileType
# Set EMAtlasBrainClassifier(fileformat) and update the save file type menu.
# .ARGS
# str fileType the type for the file
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierVolumesSetFileType {fileType} {
    global EMAtlasBrainClassifier Volume Editor
    set EMAtlasBrainClassifier(fileformat) $fileType
    $Volume(gui,mbSaveEMAtlasFileType) config -text $Editor($fileType)
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierLoadAtlasVolume
# In the future should probably be more independent but should work for right now 
# .ARGS
# path GeneralDir
# path AtlasDir
# string AtlasName
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierLoadAtlasVolume {GeneralDir AtlasDir AtlasName XMLAtlasKey} {
    global Volume EMAtlasBrainClassifier

    # Create Node 
    MainMrmlBuildTreesVersion2.0 "$XMLAtlasKey"
    set VolID [expr $Volume(nextID) -1]

    # Replace key values
    Volume($VolID,node) SetFilePrefix "$GeneralDir/$AtlasDir/I"
    Volume($VolID,node) SetFullPrefix "$GeneralDir/$AtlasDir/I"
    Volume($VolID,node) SetName       $AtlasName

    # Read in Volume
    MainVolumesUpdateMRML
    MainUpdateMRML

    return $VolID 
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierResetEMSegment
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierResetEMSegment { } {
    global EMSegment 
    eval {global} $EMSegment(MrmlNode,TypeList) 

    EMSegmentChangeClass 0
    set EMSegment(NumClassesNew) 0
    EMSegmentCreateDeleteClasses 1 1 0
    # now delete Nodes of Superclass 0
    if {$EMSegment(Cattrib,0,Node) != ""} { 
        if { [catch {set ID [$EMSegment(Cattrib,0,Node) GetID]}] == 0} {
            MainMrmlDeleteNode SegmenterSuperClass $ID 
        }
        set EMSegment(Cattrib,0,Node) ""
    }

    foreach dir $EMSegment(CIMList) {
        if {$EMSegment(Cattrib,0,CIMMatrix,$dir,Node) != ""}  {
            if { [catch {set ID [$EMSegment(Cattrib,0,CIMMatrix,$dir,Node) GetID]}] == 0 } {
                MainMrmlDeleteNode SegmenterCIM $ID 
            }
            set EMSegment(Cattrib,0,CIMMatrix,$dir,Node) ""
        }
    } 

    if {$EMSegment(Cattrib,0,EndNode) != ""} {
        if { [catch {set ID [$EMSegment(Cattrib,0,EndNode) GetID]}] == 0 } {
            lappend  MrmlNodeDeleteList "EndSegmenterSuperClass $ID"
        } 
        set EMSegment(Cattrib,0,EndNode) ""
    }

    # Delete All Remaining Segmenter Nodes that we might have forgotten 
    # Should only be node Segmenter and InputImages 
    set EMSegment(SegmenterNode) ""

    foreach node $EMSegment(MrmlNode,TypeList) {
        upvar #0 $node Array    
        foreach id $Array(idList) {
            # Add to the deleteList
            lappend Array(idListDelete) $id

            # Remove from the idList
            set i [lsearch $Array(idList) $id]
            set Array(idList) [lreplace $Array(idList) $i $i]

            # Remove node from tree, and delete it
            Mrml(dataTree) RemoveItem ${node}($id,node)
            ${node}($id,node) Delete
        }
    }
    MainUpdateMRML
    foreach node $EMSegment(MrmlNode,TypeList) {set ${node}(idListDelete) "" }
    MainMrmlUpdateIdLists "$EMSegment(MrmlNode,TypeList)"

}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierDeleteAllVolumeNodesButSPGRAndT2W
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierDeleteAllVolumeNodesButSPGRAndT2W { } {
    global  EMAtlasBrainClassifier Volume Mrml 

    foreach id $Volume(idList) {
        if {($id != $Volume(idNone)) && ($id != $EMAtlasBrainClassifier(Volume,SPGR)) && ($id != $EMAtlasBrainClassifier(Volume,T2W)) } {
            # Add to the deleteList
            lappend Volume(idListDelete) $id

            # Remove from the idList
            set i [lsearch $Volume(idList) $id]
            set Volume(idList) [lreplace $Volume(idList) $i $i]

            # Remove node from tree, and delete it
            Mrml(dataTree) RemoveItem Volume($id,node)
            Volume($id,node) Delete
        }
    }
    MainUpdateMRML
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_InitilizePipeline 
# Checks parameters and sets up Mrml Tree
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_InitilizePipeline { } {
    global EMAtlasBrainClassifier Volume Mrml 

    if {($EMAtlasBrainClassifier(Volume,SPGR) == $Volume(idNone)) || ($EMAtlasBrainClassifier(Volume,T2W) == $Volume(idNone))} {
        DevErrorWindow "Please define both SPGR and T2W before starting the segmentation" 
        return 0
    } 

    if {([Volume($EMAtlasBrainClassifier(Volume,SPGR),node) GetName] == "NormedSPGR") || ([Volume($EMAtlasBrainClassifier(Volume,T2W),node) GetName] == "NormedT2W") } {
        DevErrorWindow "Please rename the SPGR and T2W Volume. They cannot be named NormedSPGR or NormedT2W" 
        return 0
    }

    if {[EMAtlasBrainClassifierReadXMLFile $EMAtlasBrainClassifier(XMLTemplate)] == "" } {
        DevErrorWindow "Could not read template file $EMAtlasBrainClassifier(XMLTemplate) or it was empty!" 
        return 0
    }
    
    # check if the input is positive
    foreach input "SPGR T2W" {
        set VolIDInput $EMAtlasBrainClassifier(Volume,${input})        
        vtkImageAccumulate ia
        ia SetInput [Volume($VolIDInput,vol) GetOutput]
        ia Update
        if {[lindex [ia GetMin] 0] < 0} {
            DevErrorWindow "The volume assigned to input ${input} has negative values. The segmentation method only works for input with non-negtive values!" 
            ia Delete 
            return 0
        } 
        ia Delete
    }

    set EMAtlasBrainClassifier(WorkingDirectory) [file normalize $EMAtlasBrainClassifier(WorkingDirectory)]

    set Mrml(dir) $EMAtlasBrainClassifier(WorkingDirectory)/EMSegmentation
    catch {exec mkdir $EMAtlasBrainClassifier(WorkingDirectory)} 
    catch {exec mkdir $EMAtlasBrainClassifier(WorkingDirectory)/EMSegmentation} 
    # Make sure the MRML directory cooresponds to the actual directory  
    catch {eval cd $Mrml(dir)}

    EMAtlasBrainClassifierDeleteAllVolumeNodesButSPGRAndT2W
    EMAtlasBrainClassifierResetEMSegment 

    return 1
}

##################
# XML 
##################

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierReadXMLFile
# 
# .ARGS
# path FileName
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierReadXMLFile { FileName } {
    global EMAtlasBrainClassifier
    if {[catch {set fid [open $FileName r]} errmsg] == 1} {
        puts $errmsg
        return ""
    }

    set file [read $fid]

    if {[catch {close $fid} errorMessage]} {
        puts "Could not close file : ${errorMessage}"
        return ""
    }
    return $file 
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierGrepLine
# 
# .ARGS
# string input
# string search_string
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierGrepLine {input search_string} {
    set foundIndex [string first $search_string  $input]
    if {$foundIndex < 0} {
        return "-1 -1"
    }

    set start [expr [string last "\n" [string range $input 0 [expr $foundIndex -1]]] +1]
    set last  [string first "\n" [string range  $input $start end]]

    if  {$last < 0} { set last  [expr [string length $input] -1] 
    } else { incr last $start}
    return "$start $last"
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierReadNextKey
# 
# .ARGS
# string input
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierReadNextKey {input} {
    if {([regexp "^(\[^=\]*)\[\n\t \]*=\[\n\t \]*\['\"\](\[^'\"\]*)\['\"\](.*)$" \
              $input match key value input] != 0) && ([string equal -length 1 $input "/"] == 0)} {
        return "$key $value "
    }
    return "" 
}

##################
# Normalize
##################

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_Normalize
# 
# .ARGS
# int VolIDInput input volume id
# int VolIDOutput output volume id
# string Mode
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_Normalize { Mode } {
    global Volume EMAtlasBrainClassifier

    # Initialize Normalization 
    set VolIDInput $EMAtlasBrainClassifier(Volume,${Mode}) 

    set VolIDOutput [DevCreateNewCopiedVolume $VolIDInput "" "Normed$Mode"]
    
    # set Prefix $EMAtlasBrainClassifier(WorkingDirectory)/[string tolower $Mode]/[file tail [Volume($VolIDInput,node) GetFilePrefix]]norm
    #kquintus: generalize to other file types. Depending on what file format the input volumes have you might get weird 
    # prefixes like "case.nhdrnorm" with the old version. That's why the prefix should be built with [Volume($VolIDInput,node) GetName]
    set Prefix $EMAtlasBrainClassifier(WorkingDirectory)/[string tolower $Mode]/[Volume($VolIDInput,node) GetName]_norm
    
    Volume($VolIDOutput,node) SetFilePrefix "$Prefix"
    
    #katharina 08/25/06: file pattern depends on file format the user has chosen. MainVolumesWrite takes care of that 
    #Volume($VolIDOutput,node) SetFilePattern "%s.%03d"
    
    Volume($VolIDOutput,node) SetLittleEndian $EMAtlasBrainClassifier(LittleEndian)

    #katharina 08/25/06: in order to check if the normed file already exists in the selected file format search for different file pattern
    if {$EMAtlasBrainClassifier(fileformat) == "Standard"} {    
        set selectedExtention [format "%03d" [lindex [Volume($EMAtlasBrainClassifier(Volume,$Mode),node) GetImageRange] 0]]
        Volume($VolIDOutput,node) SetFullPrefix "$Prefix" 
    } else {
        set selectedExtention $EMAtlasBrainClassifier(fileformat)
        Volume($VolIDOutput,node) SetFullPrefix "$Prefix.$EMAtlasBrainClassifier(fileformat)"  
    }
    # Jump over Normalization if normed images already exists - only in batch mode
    if {$EMAtlasBrainClassifier(BatchMode) && [file exists $Prefix.$selectedExtention] } {
        puts "=========== Load Normalized Input $Mode  ============ "
        MainVolumesRead $VolIDOutput
        set CalculatedFlag 0
    }  else {
        vtkImageData outData 
        EMAtlasBrainClassifier_NormalizeVolume [Volume($VolIDInput,vol) GetOutput] outData $Mode
        Volume($VolIDOutput,vol) SetImageData outData 
        outData Delete
        set CalculatedFlag 1 
    }

    # Clean Up 
    set EMAtlasBrainClassifier(Volume,Normalized${Mode}) $VolIDOutput
    MainUpdateMRML
    RenderAll
    
    if {$EMAtlasBrainClassifier(Save,$Mode) && ($CalculatedFlag)} {
        
        EMAtlasBrainClassifierVolumeWriter $VolIDOutput 
    }
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_NormalizeVolume
# 
# .ARGS
# vtkImageData vol 
# vtkImageData out
# string Mode
# .END
#-------------------------------------------------------------------------------
# Kilian: I need this so I can also run it without MRML structure 
# Calling this function recursively does not greatly improve the accuracy of the normalization.
# From my experiment, the expected intensity of the normalized image is within 1% of the 
# target expected intensity defined by EMAtlasBrainClassifier(Normalize,*). The error is mostly due 
# computational inaccuracy caused by the data format short. 

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_NormalizeVolume
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_NormalizeVolume {Vol OutVol Mode} {
    global Volume Matrix EMAtlasBrainClassifier
    vtkImageData hist

    vtkImageAccumulate ia
    ia SetInput $Vol
    ia SetComponentSpacing 1 1 1
    ia SetComponentOrigin 0 0 0
    ia Update

    # Get maximum image value 
    set origMin [lindex [ia GetMin] 0]
    set max [lindex [ia GetMax] 0]
    set origMax $max

    puts "Histogram Parameters:"
    puts "  Image Intensity Min: $origMin Max: $max"
    puts "  Initial Filter Scaling: $EMAtlasBrainClassifier(InitialWidthScale,$Mode)"
    puts "  Expected Target Value:  $EMAtlasBrainClassifier(Normalize,$Mode) "

    ia SetComponentExtent 0 $max 0 0 0 0
    ia Update
    hist DeepCopy [ia GetOutput]
    
    set count 0
    set i 0

    # Find out the intensity value which is an uppwer bound for 99% of the voxels 
    # => Cut of the tail of the the histogram
    # Kilian Nov-06: In the future set it to 95% bc otherwise maybe fails on T2 images that have a large bump at the end from the ventricles 
    #                => large filter width => smoothes over bump in the beginning 
    set Extent [$Vol GetExtent]
    set Boundary [expr ([lindex $Extent 1] - [lindex $Extent 0] +1) * ([lindex $Extent 3] - [lindex $Extent 2] +1) * ([lindex $Extent 5] - [lindex $Extent 4] +1) * 0.99]
    while {$i < $max && $count < $Boundary} {    
        set val [hist GetScalarComponentAsFloat $i 0 0 0]
        set count [expr $count + $val]
        incr i
    }

    # max is now the upper bound intensity value for 99% of the voxels  
    set max $i 
    set min 0

    set UnDetectedPeakFlag 1
    set WidthScale [expr $EMAtlasBrainClassifier(InitialWidthScale,$Mode) - 1 ]
    set MaxItarations 6
    set iter 0

    # Kilian - Nov 06 In some images the second peak is too close to the first so that the smoothing width is too large and smoothes over the drop 
    #                 => the peak is not found 
    
    while {$iter < $MaxItarations && $UnDetectedPeakFlag } {
    # Smooth histogram by applying a window of width with 20% of the intensity value 
    incr WidthScale
    set width [expr $max / $WidthScale]
        
    set fwidth [expr 1.0 / $width ]  
    set sHistMax  [expr ($max - $min) - $width]

    # For debugging purposes
    set IndexList ""
    set ValList ""

    incr iter
    puts "  ${iter}. Histogram Smoothing"
    puts "     Width:         $width"
    puts "     Max Intensity: [expr $sHistMax + $min]"

        for {set x $min} {$x <= $sHistMax } {incr x} { 
          set sHist($x) 0
          for {set k 0} {$k <= $width} {incr k} {
              set sHist($x) [expr [hist GetScalarComponentAsFloat [expr $x + $k] 0 0 0] + $sHist($x)]
          }
          set sHist($x) [expr $sHist($x) * $fwidth]
 
          # For Debugging
          lappend IndexList $x
          lappend ValList $sHist($x)
        }
    
        # Define the lower intensity value for calculating the mean of the historgram
        # - When noise is set to 0 then we reached the first peak in the smoothed out histogram
        #   We considere this area noise (or background) and therefore exclude it for the definition of the normalization factor  
        # - When through is set we reached the first minimum after the first peak which defines the lower bound of the intensity 
        #   value considered for calculating the Expected value of the histogram 
        set x [expr $min + 1]
        set noise 1
        incr  sHistMax -2 
        set trough [expr $min - 1]
        while {$x < $sHistMax && $UnDetectedPeakFlag} {
          if {$noise == 1 && $sHist($x) > $sHist([expr $x + 1]) && $x > $min} {
              set noise 0
          # puts "End Of Noise $x"
          } elseif { $sHist($x) < $sHist([expr $x + 1]) && $sHist([expr $x + 1]) < $sHist([expr $x + 2]) && $sHist([expr $x +2]) < $sHist([expr $x + 3]) } {
              set trough $x
          # puts "Peak $x"
          set UnDetectedPeakFlag 0
          }
          incr x
        }
    }
    if {$UnDetectedPeakFlag } {
    puts "Warning: Intensity normalization filter could not detect first hump => Probably did not normalize images correctly"  
    }

    puts "Bounds for Expected Value Calculation:"
    puts "  Lower Bound: $trough"
    puts "  Upper Bound: $max"

    # Calculate the mean intensity value of the voxels with range [trough, max]  
    vtkImageAccumulate ia2
    ia2 SetInput $Vol
    ia2 SetComponentSpacing 1 1 1
    ia2 SetComponentOrigin $trough 0 0
    ia2 SetComponentExtent 0 [expr $max - $trough] 0 0 0 0
    ia2 Update
    hist DeepCopy [ia2 GetOutput]

    set total 0
    set num 0
    set MaxIndex [expr $width * $WidthScale] 

    set i $trough
    while {$i < $MaxIndex} {    
        set val [hist GetScalarComponentAsFloat [expr $i - $trough] 0 0 0]
        set total [expr $total + ($i * $val)]
        set num [expr $num + $val]
        incr i
    }

    # Normalize image by factor ExpValue which is the expect value in this range 
    set ExpValue [expr $total * 1.0 / $num]
    set IntensityMul  [expr $EMAtlasBrainClassifier(Normalize,$Mode) / $ExpValue]
    puts "Results of Filter:"
    puts "  Expect Image Intensity: $ExpValue"
    puts "  Normalization Factor:   $IntensityMul"

    vtkImageMathematics im
    im SetInput1 $Vol
    im SetConstantK $IntensityMul 
    
    im SetOperationToMultiplyByK
    im Update 
    $OutVol DeepCopy [im GetOutput]


    ia Delete
    im Delete
    ia2 Delete
    hist Delete

    puts "=========== Normalization Completed ============ "
    # Kilian: Debugging parameters 
    # Filter: Did Filter detect first valley - Width Scaler - Smoothing Width 
    # Expected Value Calucultation: min - max 
    # Filter Result: Intesity Normalization Factor 
    # Smoothed Histogram" Intensity - Histogram Value  
    return "$origMin $origMax [expr 1 - $UnDetectedPeakFlag] $WidthScale $width  $trough $max  $IntensityMul {$IndexList} {$ValList}" 
}


##################
# Registration
##################

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_AtlasList 
# Defines list of atlases to be registered 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_AtlasList { XMLTemplate } {
    global  EMAtlasBrainClassifier  

    set XMLTemplateTextOrig [EMAtlasBrainClassifierReadXMLFile $XMLTemplate] 
    set XMLTemplateText  "$XMLTemplateTextOrig"

    set RegisterAtlasDirList "" 
    set RegisterAtlasNameList "" 
    
    # ----------------------------------------------------------
    # Determine Spatial Prior to be loaded 
    set NextLineIndex [EMAtlasBrainClassifierGrepLine "$XMLTemplateText" "<SegmenterClass"] 

    while {$NextLineIndex != "-1 -1"} {
        set Line [string range "$XMLTemplateText" [lindex $NextLineIndex 0] [lindex $NextLineIndex 1]]
        set PriorPrefixIndex [string first "LocalPriorPrefix"  "$Line"]
        set PriorNameIndex   [string first "LocalPriorName"  "$Line"]
        
        if {($PriorPrefixIndex > -1) && ($PriorNameIndex > -1)} {
            set ResultPrefix [lindex [EMAtlasBrainClassifierReadNextKey  "[string range \"$Line\" $PriorPrefixIndex end]"] 1]
            set AtlasDir [file tail [file dirname $ResultPrefix]]
            set AtlasName   [lindex [EMAtlasBrainClassifierReadNextKey  "[string range \"$Line\" $PriorNameIndex end]"] 1]
            
            if {($ResultPrefix != "") && ($AtlasName != "") && ([lsearch $RegisterAtlasNameList "$AtlasName"] < 0) && ($AtlasDir != "") } {
                lappend  RegisterAtlasDirList "$AtlasDir"
                lappend  RegisterAtlasNameList "$AtlasName"
            }
            
        }
        set XMLTemplateText  [string range "$XMLTemplateText" [expr [lindex $NextLineIndex 1] +1] end]
        set NextLineIndex [EMAtlasBrainClassifierGrepLine "$XMLTemplateText" "<SegmenterClass"] 
    }
    return "{$RegisterAtlasDirList} {$RegisterAtlasNameList}" 
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_GetNumberOfTrainingSamples 
# Returns the number of training samples as defined by the xml file 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_NumberOfTrainingSamples { } {
    global  EMAtlasBrainClassifier   
    set XMLTemplateText [EMAtlasBrainClassifierReadXMLFile $EMAtlasBrainClassifier(XMLTemplate)]
    set LineIndex [EMAtlasBrainClassifierGrepLine "$XMLTemplateText" "<Segmenter "] 
    if  {$LineIndex != "-1 -1"} {
        set Line [string range "$XMLTemplateText" [lindex $LineIndex 0] [lindex $LineIndex 1]]
        set Index [string first "NumberOfTrainingSamples"  "$Line"]
        if {$Index  > -1 } {
            return  [lindex [EMAtlasBrainClassifierReadNextKey  "[string range \"$Line\" $Index end]"] 1]
        }
    }
    return 0
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_RegistrationInitialize 
# Checks if atlas has to be downloaded and if registration is necessary. Return values 
# -1 Atlas does not exist and could not be downloaded
#  0 Registered Atlas exists 
#  1 Atlas exists but has to be registered 
# .ARGS
# string RegisterAtlasDirList List of Atlases to be loaded
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_RegistrationInitialize {RegisterAtlasDirList} {
    global EMAtlasBrainClassifier

    # ---------------------------------------------------------------
    # Check if we load the module for the first time 
    if {$EMAtlasBrainClassifier(AtlasDir) == $EMAtlasBrainClassifier(DefaultAtlasDir)} {
        set UploadNeeded 0 
        foreach atlas "spgr $RegisterAtlasDirList" {
            if {[file exists [file join $EMAtlasBrainClassifier(AtlasDir) $atlas I.001]] == 0} {
                set UploadNeeded 1
                break
            }
        }  
        if {$UploadNeeded && ([EMAtlasBrainClassifierDownloadAtlas] == 0)} { return -1}
    }

    # ---------------------------------------------------------------
    # Check if we need to run registration
    puts "=========== Initilize Registration of Atlas to Case  ============ "

    set RunRegistrationFlag 0 
    
    #Katharina 08/25/06: generalize to other file formats. Atlas has to exist in the selected file format, otherwise registration is executed.
    #set StartSlice [format "%03d" [lindex [Volume($EMAtlasBrainClassifier(Volume,NormalizedSPGR),node) GetImageRange] 0]]    
    if {$EMAtlasBrainClassifier(fileformat) == "Standard"} {    
        set selectedExtention [format "%03d" [lindex [Volume($EMAtlasBrainClassifier(Volume,NormalizedSPGR),node) GetImageRange] 0]] 
    } else {
        set selectedExtention $EMAtlasBrainClassifier(fileformat) 
    }
    
    foreach Dir "$RegisterAtlasDirList" {
        if {[file exists $EMAtlasBrainClassifier(WorkingDirectory)/atlas/$Dir/I.$selectedExtention] == 0  } {
            set RunRegistrationFlag 1 
            break 
        }
    }
    
    if {$RunRegistrationFlag == 0 && ($EMAtlasBrainClassifier(BatchMode) == 0)} {
        if {[DevYesNo "We found already an atlas in $EMAtlasBrainClassifier(WorkingDirectory)/atlas. Do you still want to register ? " ] == "yes" } {
            set RunRegistrationFlag 1
        }
    } 
    # ---------------------------------------------------------------
    # Check if proper template file exist
    if {$RunRegistrationFlag == 1} {
        set XMLAtlasTemplateFile $EMAtlasBrainClassifier(AtlasDir)/template_atlas.xml
        if {[EMAtlasBrainClassifierReadXMLFile $XMLAtlasTemplateFile] == "" } {
            DevErrorWindow "Could not read template file $XMLAtlasTemplateFile or it was empty!" 
            return -1
        }
        
        set XMLAtlasKey [MainMrmlReadVersion2.x $XMLAtlasTemplateFile]
        if {$XMLAtlasKey == 0 } {return -1}
        
        if {[lindex [lindex $XMLAtlasKey 0] 0] != "Volume"} {
            DevErrorWindow "Template file $XMLAtlasTemplateFile is not of the correct format!" 
            return -1
        }
    }

    return $RunRegistrationFlag
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_AtlasRegistration 
# Registers MRI of atlas and resamles atlas volume 
# .ARGS
# string  RegisterAtlasDirList  List of atlas directories to be loaded
# string  RegisterAtlasNameList List of atlas names to be loaded
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_AtlasRegistration {RegisterAtlasDirList RegisterAtlasNameList } {
    global EMAtlasBrainClassifier Volume  AG

    # ---------------------------------------------------------------
    # Set up Registration 

    # Read Atlas Parameters from XML file (how to load volumes)
    set XMLAtlasKey [MainMrmlReadVersion2.x $EMAtlasBrainClassifier(AtlasDir)/template_atlas.xml] 
    
    # Load Atlas SPGR 
    set TemplateIDInput $EMAtlasBrainClassifier(Volume,NormalizedSPGR)
    set VolIDSource      [EMAtlasBrainClassifierLoadAtlasVolume $EMAtlasBrainClassifier(AtlasDir) spgr  AtlasSPGR "$XMLAtlasKey"]
    if {$VolIDSource == "" } {return}
    set EMAtlasBrainClassifier(Volume,AtlasSPGR) $VolIDSource
    
    # Target file is the normalized SPGR
    set VolIDTarget $EMAtlasBrainClassifier(Volume,NormalizedSPGR)
    if {$VolIDTarget == "" } {return}
    
    # ---------------------------------------------------------------
    # Register Atlas SPGR to Normalized SPGR 
    puts "============= Start registeration"  
    
    # Kilian April 06 - produce qubic interpolation
    set AG(Interpolation) 1
    
    EMAtlasBrainClassifierRegistration $VolIDTarget $VolIDSource $EMAtlasBrainClassifier(NonRigidRegistrationFlag)
    puts "EMAtlasBrainClassifierRegistration END"
    
    # Define Registration output volume 
    set VolIDOutput [DevCreateNewCopiedVolume $TemplateIDInput "" "RegisteredSPGR"]

    # Resample the Atlas SPGR
    EMAtlasBrainClassifierResample  $VolIDTarget $VolIDSource $VolIDOutput 0 

    # Clean up 
    if {$EMAtlasBrainClassifier(Save,Atlas)} {
        set Prefix "$EMAtlasBrainClassifier(WorkingDirectory)/atlas/spgr/I"
        Volume($VolIDOutput,node) SetFilePrefix "$Prefix"
        Volume($VolIDOutput,node) SetFullPrefix "$Prefix" 
        Volume($VolIDOutput,node) SetLittleEndian $EMAtlasBrainClassifier(LittleEndian)
        
        EMAtlasBrainClassifierVolumeWriter $VolIDOutput
        # Write Transformation To File
        EMAtlasBrainClassifierWriteTransformation

    }
    MainMrmlDeleteNode Volume $VolIDSource 
    MainUpdateMRML
    RenderAll
    
    # ---------------------------------------------------------------
    # Resample atlas files

    # The first LocalPriorPrefix in the xml file has to define the spatial prior of the background. This is necessary as the resampling function assigns the value  
    # NumberOfTrainingSamples( = 100% prior probability) to voxels outside the resampling space for the first spatial prior only. 
    # The other spatial priors are characterized by
    # 0  (= 0% prior probability) to voxels outside the resampling space. 
    # 
    # This rule ensures that the resampling does not causes voxels to assign 0 probability to each structure. When the EM algorithm encounters voxels with 
    # zero prior probability then the segmentation without prior information. This can produce segmentation with almost random assignment patters especially 
    # when segmenting structures with very similar intensity patterns

    set BackgroundValue [EMAtlasBrainClassifier_NumberOfTrainingSamples]
    puts "BackgroundValue $BackgroundValue"

    foreach Dir "$RegisterAtlasDirList" Name "$RegisterAtlasNameList" {
        puts "=========== Resample Atlas $Name  ============ "
        # Load In the New Atlases
        set VolIDInput [EMAtlasBrainClassifierLoadAtlasVolume $EMAtlasBrainClassifier(AtlasDir) $Dir Atlas_$Name "$XMLAtlasKey"]
        # Define Registration output volumes
        set VolIDOutput [DevCreateNewCopiedVolume $TemplateIDInput "" "$Name"]
        set Prefix "$EMAtlasBrainClassifier(WorkingDirectory)/atlas/$Dir/I"
        Volume($VolIDOutput,node) SetFilePrefix "$Prefix"
        Volume($VolIDOutput,node) SetFullPrefix "$Prefix" 
        Volume($VolIDOutput,node) SetLittleEndian $EMAtlasBrainClassifier(LittleEndian)
        
        # Resample the Atlas
        EMAtlasBrainClassifierResample  $VolIDTarget $VolIDInput $VolIDOutput $BackgroundValue

        # Clean up 
        if {$EMAtlasBrainClassifier(Save,Atlas)} {EMAtlasBrainClassifierVolumeWriter $VolIDOutput}
        MainMrmlDeleteNode Volume $VolIDInput 
        MainUpdateMRML
        RenderAll
        set BackgroundValue 0
    }
}


#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_LoadAtlas
# Load the alredy registered atlas 
# .ARGS
# string  RegisterAtlasDirList  List of atlas directories to be loaded
# string  RegisterAtlasNameList List of atlas names to be loaded
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_LoadAtlas {RegisterAtlasDirList RegisterAtlasNameList } {
    global EMAtlasBrainClassifier Volume
    set VolIDInput $EMAtlasBrainClassifier(Volume,SPGR)
    foreach Dir "$RegisterAtlasDirList" Name "$RegisterAtlasNameList" {
        puts "=========== Load Atlas $Name  ============ "
        set VolIDOutput [DevCreateNewCopiedVolume $VolIDInput "" "$Name"]
        Volume($VolIDOutput,node) SetFilePrefix "$EMAtlasBrainClassifier(WorkingDirectory)/atlas/$Dir/I"
        
        #Katharina 08/25/06: depending on the selected file format setFullPrefix differently
        if {$EMAtlasBrainClassifier(fileformat) == "Standard"} {    
            Volume($VolIDOutput,node) SetFullPrefix "$EMAtlasBrainClassifier(WorkingDirectory)/atlas/$Dir/I" 
        } else {
            Volume($VolIDOutput,node) SetFullPrefix "$EMAtlasBrainClassifier(WorkingDirectory)/atlas/$Dir/I.$EMAtlasBrainClassifier(fileformat)"     
        }
        Volume($VolIDOutput,node) SetLittleEndian $EMAtlasBrainClassifier(LittleEndian)
        MainVolumesRead $VolIDOutput
        RenderAll
    }      
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierDownloadAtlas
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierDownloadAtlas { } {
    global EMAtlasBrainClassifier tcl_platform

    if {$tcl_platform(os) == "Linux" || 
        $tcl_platform(os) == "SunOS" ||
        $tcl_platform(os) == "Darwin"} { 
        set urlAddress "http://na-mic.org/Wiki/images/8/8d/VtkEMAtlasBrainClassifier_AtlasDefault.tar.gz" 
        set outputFile "[file dirname $EMAtlasBrainClassifier(AtlasDir)]/atlas.tar.gz"
    } else {
        set urlAddress "http://na-mic.org/Wiki/images/5/57/VtkEMAtlasBrainClassifier_AtlasDefault.zip"
        set outputFile "[file dirname $EMAtlasBrainClassifier(AtlasDir)]/atlas.zip"
    }

    # temporary message to prompt the user to download and extract the file themselves.
    set text "The module did not detect an atlas at the default location. An atlas can be"
    set text "$text\ndownloaded from:\n$urlAddress\nand saved to:\n$outputFile"
    set text "$text\nThen extract the atlas directory as\n${EMAtlasBrainClassifier(AtlasDir)}"
    set text "$text\nand restart the segmentation."

    if {$EMAtlasBrainClassifier(BatchMode)} {
        puts "================== Warning ==============="
        puts "$text"
        puts "=========================================="

        return 0
    }


    if {[info command .topAtlas] != ""} {
        wm deiconify .topAtlas
        return 0
    }
    # otherwise build a frame with the info in it
    global Gui
    toplevel .topAtlas
    wm title .topAtlas "Atlas not found"
    frame .topAtlas.f1 -bg $::Gui(activeWorkspace)
    pack .topAtlas.f1 -side top -padx $::Gui(pad) -pady $::Gui(pad) -fill x
    set f .topAtlas.f1
    eval {label $f.l -text $text} $::Gui(WLA)
    DevAddButton $f.bClose "Close" "wm withdraw .topAtlas"
    pack $f.l $f.bClose -side top -pady $::Gui(pad) -expand 1

    # -------------------------------------------------
    # Disabled bc it does not work on all platforms 
    return 0

    set text "The module did not detect an atlas at the default location. An atlas can be"
    set text "$text\ndownloaded by pressing the \"\OK\" button. This might take a while! "
    set text "$text\nIf you want to continue and you have PROBLEMS downloading the data please do the following:"
    set text "$text\nDownload the data from http://na-mic.org/Wiki/index.php/Slicer:Data_EMAtlas"
    set text "$text\nto [file dirname $EMAtlasBrainClassifier(AtlasDir)]"
    set text "$text\nand uncompress the file.\n"      
    set text "$text\nBy pressing the \"OK\" button I agree with the copyright restriction explained in further "
    set text "${text}detail at http://na-mic.org/Wiki/index.php/Slicer:Data_EMAtlas."

    if {$EMAtlasBrainClassifier(BatchMode)} {
        puts "$text"
    } else {
        if {[DevOKCancel "$text" ] != "ok"} { return 0}
    }

    DownloadInit

    if {$tcl_platform(os) == "Linux"} { 
        set urlAddress "http://na-mic.org/Wiki/images/8/8d/VtkEMAtlasBrainClassifier_AtlasDefault.tar.gz" 
        set outputFile "[file dirname $EMAtlasBrainClassifier(AtlasDir)]/atlas.tar.gz"
    } else {
        set urlAddress "http://na-mic.org/Wiki/images/5/57/VtkEMAtlasBrainClassifier_AtlasDefault.zip"
        set outputFile "[file dirname $EMAtlasBrainClassifier(AtlasDir)]/atlas.zip"
    }

    catch {exec rm -f $outputFile}
    catch {exec rm -rf $EMAtlasBrainClassifier(AtlasDir)}

    if {[DownloadFile "$urlAddress" "$outputFile"] == 0} {
        return 0
    }

    puts "Start extracting $outputFile ...." 
    if {$tcl_platform(os) == "Linux" || 
        $tcl_platform(os) == "SunOS" ||
        $tcl_platform(os) == "Darwin"} { 
        catch {exec rm -f [file rootname $outputFile]}
        puts "exec gunzip $outputFile"
        set OKFlag [catch {exec gunzip -f $outputFile} errormsg]
        if {$OKFlag == 0} {
            catch {exec rm -f atlas}
            puts "exec tar xf [file rootname $outputFile]]"
            set OKFlag [catch {exec tar xf [file rootname $outputFile]} errormsg]
            if {$OKFlag == 0} {
                puts "exec mv atlas ${EMAtlasBrainClassifier(AtlasDir)}/"
                set OKFlag [catch {exec mv atlas ${EMAtlasBrainClassifier(AtlasDir)}/}  errormsg]
            }
        }
        set RMFile [file rootname $outputFile]
    } else {
        set OKFlag [catch {exec unzip -o -qq $outputFile}  errormsg] 
        set RMFile $outputFile
    } 
    puts "... finished extracting"
    if {$OKFlag == 1} {
        DevErrorWindow "Could not uncompress $outputFile because of the following error message:\n$errormsg\nPlease manually uncompress the file."
        return 0
    } 
    
    if {$EMAtlasBrainClassifier(BatchMode)} {
        puts "Atlas installation completed!" 
    } else {
        DevInfoWindow "Atlas installation completed!" 
    }
    
    catch {exec rm -f $RMFile} 
    return 1
}


#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierRegistration
# 
# .ARGS
# int inTarget input target volume id
# int inSource
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierRegistration {inTarget inSource NonRigidRegistrationFlag {LinearRegistrationType 2} } {
    global EMAtlasBrainClassifier Volume AG 
    
    
    catch "Target Delete"
    catch "Source Delete"
    vtkImageData Target
    vtkImageData Source
    
    # set AG(Debug) 1
    puts "Initialize Source and Target"
    #If source and target have two channels, combine them into one vtkImageData object 
    Target DeepCopy  [ Volume($inTarget,vol) GetOutput]
    Source DeepCopy  [ Volume($inSource,vol) GetOutput]

    # Initial transform stuff
    catch "TransformEMAtlasBrainClassifier Delete"
    vtkGeneralTransform TransformEMAtlasBrainClassifier
    puts "No initial transform"
    TransformEMAtlasBrainClassifier PostMultiply 

    ## to be changed to EMAtlaspreprocess
    AGPreprocess Source Target $inSource $inTarget


    if { [info commands __dummy_transform] == ""} {
        vtkTransform __dummy_transform
    }

    puts -nonewline "Start the linear registration with MI criterion and type "
    switch  $LinearRegistrationType {
        -1 { puts "translation." }
        0 { puts "rigid." }
        1 { puts "similarity." }
        2 { puts "affine." }
        default {puts "Do not know type   $LinearRegistrationType" ; return}

    }

    ###### Linear Tfm ######
    catch "GCR Delete"
    vtkImageGCR GCR
    GCR SetVerbose 0

    # Set i/o
    GCR SetTarget Target
    GCR SetSource Source
    GCR PostMultiply 
    
    # Set parameters
    GCR SetInput  __dummy_transform  
    [GCR GetGeneralTransform] SetInput TransformEMAtlasBrainClassifier
    ## Metric: 1=GCR-L1,2=GCR-L2,3=Correlation,4=MI
    GCR SetCriterion       4 
    ## Tfm type: -1=translation, 0=rigid, 1=similarity, 2=affine
    GCR SetTransformDomain $LinearRegistrationType
    
    ## 2D registration only?
    GCR SetTwoD 0
    
    # Do it!
    GCR Update     
    TransformEMAtlasBrainClassifier Concatenate [[GCR GetGeneralTransform] GetConcatenatedTransform 1]

    if {$NonRigidRegistrationFlag} {
        ###### Warp #######
        catch "warp Delete"
        vtkImageWarp warp
        
        # Set i/o
        warp SetSource Source
        warp SetTarget Target 
        
        # Set the parameters
        warp SetVerbose 0
        [warp GetGeneralTransform] SetInput TransformEMAtlasBrainClassifier
        ## do tensor registration?
        warp SetResliceTensors 0 
        ## 1=demon, 2=optical flow 
        warp SetForceType 1          
        warp SetMinimumIterations  0 
        warp SetMaximumIterations  50
        ## What does it mean?
        warp SetMinimumLevel -1  
        warp SetMaximumLevel -1  
        ## Use SSD? 1 or 0 
        warp SetUseSSD 1
        warp SetSSDEpsilon  1e-3    
        warp SetMinimumStandardDeviation 0.85 
        warp SetMaximumStandardDeviation 1.25     

        ## Kilian: April 06 Activate Intensity transformation to increase robustness of Pipeline
        ##         Intensity transformation is only used for registration but not resampling
        set AG(Intensity_tfm) "mono-functional"
        set AG(Degree)           1
        set AG(Ratio)            1
        set AG(Use_bias)         0
        set AG(Nb_of_functions)  1
        if { [AGIntensityTransform Source] == 0 } {
            puts "Intensity transform activated" 
            warp SetIntensityTransform $AG(tfm)
        }

        # Do it!
        warp Update

        TransformEMAtlasBrainClassifier Concatenate warp
    }
    # save the transform
    set EMAtlasBrainClassifier(Transform) TransformEMAtlasBrainClassifier
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierWriteTransformation
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierWriteTransformation { } { 
    global AG  EMAtlasBrainClassifier

    if {![info exist EMAtlasBrainClassifier(Transform)]} {
        DevErrorWindow "No transformation available, grid-file not saved."
        return
    }
    
    set gt  $EMAtlasBrainClassifier(Transform)
    if { ($gt == 0 ) } {return}
    
    set n [$gt GetNumberOfConcatenatedTransforms]
    puts " There are $n concatenated transforms"
    
    set linearDone 0
    set nonliearDOne 0
    for {set  i  0}  {$i < $n} {incr i } {
        set t [$gt GetConcatenatedTransform $i]
        set int_H [$t IsA vtkHomogeneousTransform]
        set int_G [$t IsA vtkGridTransform]
        if { ($int_H != 0)&& ($linearDone == 0) } {
            set fname $EMAtlasBrainClassifier(WorkingDirectory)/atlas/LinearAtlasToSubject.txt
            set fileid [ open $fname w ]
            puts "Writing transformation to $EMAtlasBrainClassifier(WorkingDirectory)/atlas/LinearAtlasToSubject.txt"

            AGWriteHomogeneousOriginal $t $i  $fileid
            set linearDone 1

            
        } 
        if { ($int_G != 0) && ($nonliearDOne == 0) } {  

            set g [$t GetDisplacementGrid]        
            if { $g == 0}  return

            puts "Writing warping grid to $EMAtlasBrainClassifier(WorkingDirectory)/atlas/WarpAtlasToSubject.vtk"
            
            set fname $EMAtlasBrainClassifier(WorkingDirectory)/atlas/WarpAtlasToSubject.vtk
            AGWritevtkImageData $g  $fname

            set nonliearDOne 1
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierResample
# 
# .ARGS
# int inTarget input target volume id
# int inSource volume id
# vtkImageData outResampled
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierResample {inTarget inSource outResampled bgValue {OutImageDataFlag 0}} {
    global EMAtlasBrainClassifier Volume Gui
    
    catch "Source Delete"
    vtkImageData Source  
    Source DeepCopy  [ Volume($inSource,vol) GetOutput]
    catch "Target Delete"
    vtkImageData Target
    Target DeepCopy  [ Volume($inTarget,vol) GetOutput]
    AGPreprocess Source Target $inSource $inTarget
    
    catch "Cast Delete"
    vtkImageCast Cast
    Cast SetInput Source
    Cast SetOutputScalarType [Target GetScalarType] 

    catch "Reslicer Delete"
    vtkImageReslice Reslicer
    Reslicer SetInput [Cast  GetOutput]
    # Kilian April 05: Changed it Cubic interpolation to be consistent with AGNormalize 
    # Reslicer SetInterpolationMode 1
    Reslicer SetInterpolationModeToCubic 
    
    # We have to invers the transform before we reslice the grid.     
    Reslicer SetResliceTransform [$EMAtlasBrainClassifier(Transform)  GetInverse]
    
    # Reslicer SetInformationInput Target
    Reslicer SetInformationInput Target

    # Make sure the background is set correctly 
    Reslicer SetBackgroundLevel $bgValue

    # Do it!
    Reslicer Update

    # Make sure that no values are negative - should only happen with cubic interpolation
    # catch "Threshold Delete"
    # vtkImageThreshold Threshold
    #     Threshold SetInput [Reslicer GetOutput] 
    # Threshold ThresholdByLower 0
    #     Threshold ReplaceOutOff
    #  Threshold SetInValue 0 
    #    Threshold SetOutputScalarType [Target GetScalarType]
    # Threshold Update
    
    if {$OutImageDataFlag } {
        # outResampled represents a data volume
        AGThresholdedOutput [Cast GetOutput] [Reslicer GetOutput] $outResampled 
        $outResampled SetOrigin 0 0 0
    } else { 
        catch "Resampled Delete"
        vtkImageData Resampled
        AGThresholdedOutput [Cast GetOutput] [Reslicer GetOutput] Resampled
        Resampled SetOrigin 0 0 0
        Volume($outResampled,vol) SetImageData  Resampled 
    }
    Source Delete
    Target Delete
    Cast Delete
    Reslicer Delete
    # Threshold Delete
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_GenerateModels
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_GenerateModels { } {  
    global EMAtlasBrainClassifier ModelMaker Volume 

    if {$EMAtlasBrainClassifier(LatestLabelMap) == $Volume(idNone)} {
        return
    }

    # Initiliaze method 
    set ModelMaker(smooth) 20 
    set ModelMaker(decimate) 0
    set ModelMaker(jointSmooth) 1
    set ModelMaker(SplitNormals) Off
    set ModelMaker(PointNormals) Off
    set ModelMaker(idVolume) $EMAtlasBrainClassifier(LatestLabelMap) 

    # Figure out all labels 
    vtkImageAccumulate histo
    histo  SetInput [Volume($EMAtlasBrainClassifier(LatestLabelMap),vol) GetOutput]
    histo Update
    set min [lindex [histo GetMin] 0]
    set max [lindex [histo GetMax] 0]
    if {$min < 1} {
        set ModelMaker(startLabel) 1
    } else {
        set ModelMaker(startLabel) $min
    }

    set ModelMaker(endLabel) $max
    histo Delete

    # Create modeles
    ModelMakerCreateAll 0 

    if {$EMAtlasBrainClassifier(Save,Models)} { 
        set dir $EMAtlasBrainClassifier(WorkingDirectory)/Models 
        catch {exec mkdir $dir}
        ModelMakerWriteAll $dir
    }
}




##################
# EM Segmeneter 
##################

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_InitilizeSegmentation
# Initilizes parameters for Segmentation with EMAtlasClassifier 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_InitilizeSegmentation {ValueFlag} {
    global EMAtlasBrainClassifier Volume EMSegment

    # Read XML File  
    set tags [MainMrmlReadVersion2.x $EMAtlasBrainClassifier(XMLTemplate)]
    set tags [MainMrmlAddColors $tags]
    MainMrmlBuildTreesVersion2.0 $tags
    MainUpdateMRML

    if {$ValueFlag } {EMAtlasBrainClassifierInitializeValues }

    # Set Segmentation Boundary  so that if you have images of other dimension it will segment them correctly
    set VolID $EMAtlasBrainClassifier(Volume,SPGR)
    set Range [Volume($VolID,node) GetImageRange]

    set EMSegment(SegmentationBoundaryMax,0) [lindex [Volume($VolID,node) GetDimensions] 0]
    set EMSegment(SegmentationBoundaryMax,1) [lindex [Volume($VolID,node) GetDimensions] 1]
    set EMSegment(SegmentationBoundaryMax,2) [expr [lindex $Range 1] - [lindex $Range 0] + 1] 

    set EMAtlasBrainClassifier(SegmentationBoundaryMax,0) $EMSegment(SegmentationBoundaryMax,0) 
    set EMAtlasBrainClassifier(SegmentationBoundaryMax,1) $EMSegment(SegmentationBoundaryMax,1) 
    set EMAtlasBrainClassifier(SegmentationBoundaryMax,2) $EMSegment(SegmentationBoundaryMax,2) 

    if {$ValueFlag } { 
        set pid $EMAtlasBrainClassifier(vtkMrmlSegmenterNode)
        eval Segmenter($pid,node) SetSegmentationBoundaryMin "1 1 1"
        eval Segmenter($pid,node) SetSegmentationBoundaryMax "$EMAtlasBrainClassifier(SegmentationBoundaryMax,0) $EMAtlasBrainClassifier(SegmentationBoundaryMax,1) $EMAtlasBrainClassifier(SegmentationBoundaryMax,2)"
    }
}



#-------------------------------------------------------------------------------
# .PROC  EMAtlasBrainClassifierDeleteClasses  
# Deletes all classes
# .ARGS
# SuperClass class to start with 
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierDeleteClasses {SuperClass} {
    global EMAtlasBrainClassifier
    # Initialize 

    set NumClasses [llength $EMAtlasBrainClassifier(Cattrib,$SuperClass,ClassList)] 
    if {$NumClasses == 0} { return }
    foreach i $EMAtlasBrainClassifier(Cattrib,$SuperClass,ClassList) {
        # It is a super class => destroy also all sub classes
        if {$EMAtlasBrainClassifier(Cattrib,$i,IsSuperClass)} {
            # -----------------------------
            # Delete all Subclasses
            EMAtlasBrainClassifierDeleteClasses $i
        }
        array unset EMAtlasBrainClassifier Cattrib,$SuperClass,CIMMatrix,$i,*
        array unset EMAtlasBrainClassifier Cattrib,$i,* 
    }
    set EMAtlasBrainClassifier(Cattrib,$SuperClass,ClassList) ""
    if {$SuperClass == 0} {set EMAtlasBrainClassifier(ClassIndex) 1}
}


#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierInitializeValues 
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierInitializeValues { } { 
    global EMAtlasBrainClassifier Mrml Volume Gui env
    # Current Desing of Node structure : (order is important !) 
    # Segmenter
    # -> SegmenterInput
    # -> SegmenterClass 
    # -> SegmenterCIM 
    # -> SegmenterSuperClass
    #    -> SegmenterClass 
    #    -> SegmenterCIM 

    set EMAtlasBrainClassifier(MaxInputChannelDef) 0
    # Current Number of Input Channels
    set EMAtlasBrainClassifier(NumInputChannel) 0

    set EMAtlasBrainClassifier(EMShapeIter)    1
    set EMAtlasBrainClassifier(Alpha)          0.7 
    set EMAtlasBrainClassifier(SmWidth)        11
    set EMAtlasBrainClassifier(SmSigma)        5 

    set EMAtlasBrainClassifier(SegmentationBoundaryMin,0) 1
    set EMAtlasBrainClassifier(SegmentationBoundaryMin,1) 1
    set EMAtlasBrainClassifier(SegmentationBoundaryMin,2) 1

    set EMAtlasBrainClassifier(SegmentationBoundaryMax,0) 256
    set EMAtlasBrainClassifier(SegmentationBoundaryMax,1) 256
    set EMAtlasBrainClassifier(SegmentationBoundaryMax,2) -1

    # How did I come up with the number 82 ? It is a long story ....
    set EMAtlasBrainClassifier(NumberOfTrainingSamples) 82

    EMAtlasBrainClassifierDeleteClasses 0
    set EMAtlasBrainClassifier(SelVolList,VolumeList) { }

    set SclassMemory ""

    Mrml(dataTree) ComputeTransforms
    Mrml(dataTree) InitTraversal
    set item [Mrml(dataTree) GetNextItem]
    while { $item != "" } {
        set ClassName [$item GetClassName]

        if { $ClassName == "vtkMrmlSegmenterNode" } {
            # --------------------------------------------------
            # 2.) Check if we already work on this Segmenter
            #     => if yes , do not do anything
            # -------------------------------------------------
            set pid [$item GetID]
            set EMAtlasBrainClassifier(vtkMrmlSegmenterNode) $pid
            set VolumeNameList ""
            foreach VolID $Volume(idList) {
                lappend VolumeNameList "[Volume($VolID,node) GetName]"
            }
            
            # --------------------------------------------------
            # 3.) Update variables 
            # -------------------------------------------------
            set EMAtlasBrainClassifier(MaxInputChannelDef)         [Segmenter($pid,node) GetMaxInputChannelDef]
            set BoundaryMin                                        [Segmenter($pid,node) GetSegmentationBoundaryMin]
            set BoundaryMax                                        [Segmenter($pid,node) GetSegmentationBoundaryMax]

            for {set i 0} {$i < 3} {incr i} { 
                set EMAtlasBrainClassifier(SegmentationBoundaryMin,$i) [lindex $BoundaryMin $i]
                set EMAtlasBrainClassifier(SegmentationBoundaryMax,$i) [lindex $BoundaryMax $i]
            }      
            
            # If the path is not the same, define all Segmenter variables
            # Delete old values Kilian: Could do it but would cost to much time 
            # This is more efficient - but theoretically could also start from stretch bc I 
            # only get this far when a new XML file is read ! If you get in problems just do the 
            # following (deletes everything) 
            set  NumClasses [Segmenter($pid,node) GetNumClasses]
            if {$NumClasses} { 
                EMAtlasBrainClassifierCreateClasses 0 $NumClasses
                set CurrentClassList $EMAtlasBrainClassifier(Cattrib,0,ClassList)       
            } else {
                set CurrentClassList 0
            }
            
            # Define all parameters without special consideration
            set EMiteration 0 
            set MFAiteration 0 
            
            foreach NodeAttribute $EMAtlasBrainClassifier(MrmlNode,Segmenter,AttributeList) { 
                switch $NodeAttribute {
                    EMiteration { set EMiteration [Segmenter($pid,node) GetEMiteration] }
                    MFAiteration { set MFAiteration [Segmenter($pid,node) GetMFAiteration]}
                    default { set EMAtlasBrainClassifier($NodeAttribute)     [Segmenter($pid,node) Get${NodeAttribute}]}
                }
            }
            # Legacy purposes 
            if {$NumClasses} { 
                set EMAtlasBrainClassifier(Cattrib,0,StopEMMaxIter) $EMiteration
                set EMAtlasBrainClassifier(Cattrib,0,StopMFAMaxIter) $MFAiteration
            } 
        } elseif {$ClassName == "vtkMrmlSegmenterInputNode" } {
            # --------------------------------------------------
            # 5.) Update selected Input List 
            # -------------------------------------------------
            # find out the Volume correspnding to the following description
            set pid [$item GetID]        
            set FileName [SegmenterInput($pid,node) GetFileName]
            set VolIndex [lsearch $VolumeNameList $FileName]
            if {($VolIndex > -1) && ($FileName != "") } {  
                lappend EMAtlasBrainClassifier(SelVolList,VolumeList) [lindex $Volume(idList) $VolIndex] 
                incr EMAtlasBrainClassifier(NumInputChannel)
            }
        } elseif {$ClassName == "vtkMrmlSegmenterSuperClassNode" } {
            # puts "Start vtkMrmlSegmenterSuperClassNode"
            # --------------------------------------------------
            # 6.) Update variables for SuperClass 
            # -------------------------------------------------
            set pid [$item GetID]
            # If you get an error mesaage in the follwoing lines then CurrentClassList to short
            set NumClass [lindex $CurrentClassList 0]
            if {$NumClass == ""} { DevErrorWindow "Error in XML File : Super class $EMAtlasBrainClassifier(SuperClass)  has not enough sub-classes defined" }

            # Check If we initialize the head class 
            if {$NumClass == 0} {set InitiHeadClassFlag 1
            } else {set InitiHeadClassFlag 0}

            set EMAtlasBrainClassifier(Class) $NumClass 

            # Save status when returning to parent of this class 
            if {$InitiHeadClassFlag} {
                set SclassMemory ""
                set EMAtlasBrainClassifier(SuperClass) $NumClass
            } else  { 
                lappend SclassMemory [list "$EMAtlasBrainClassifier(SuperClass)" "[lrange $CurrentClassList 1 end]"] 
                # Transfer from Class to SuperClass
                set EMAtlasBrainClassifier(Cattrib,$NumClass,IsSuperClass) 1
                set EMAtlasBrainClassifier(SuperClass) $NumClass
            }
            set VolumeName  [SegmenterSuperClass($pid,node) GetLocalPriorName]
            set VolumeIndex [lsearch $VolumeNameList $VolumeName]
            if {($VolumeName != "") && ($VolumeIndex > -1) } { set EMAtlasBrainClassifier(Cattrib,$NumClass,ProbabilityData) [lindex $Volume(idList) $VolumeIndex]
            } else { set EMAtlasBrainClassifier(Cattrib,$NumClass,ProbabilityData) $Volume(idNone) }

            set InputChannelWeights [SegmenterSuperClass($pid,node) GetInputChannelWeights]
            for {set y 0} {$y < $EMAtlasBrainClassifier(MaxInputChannelDef)} {incr y} {
                if {[lindex $InputChannelWeights $y] == ""} {set EMAtlasBrainClassifier(Cattrib,$NumClass,InputChannelWeights,$y) 1.0
                } else {
                    set EMAtlasBrainClassifier(Cattrib,$NumClass,InputChannelWeights,$y) [lindex $InputChannelWeights $y]
                }
            }

            # Create Sub Classes
            EMAtlasBrainClassifierCreateClasses $NumClass [SegmenterSuperClass($pid,node) GetNumClasses]
            set CurrentClassList $EMAtlasBrainClassifier(Cattrib,$EMAtlasBrainClassifier(SuperClass),ClassList)

            # Define all parameters without special consideration
            foreach NodeAttribute $EMAtlasBrainClassifier(MrmlNode,SegmenterSuperClass,AttributeList) { 
                set EMAtlasBrainClassifier(Cattrib,$NumClass,$NodeAttribute)     [SegmenterSuperClass($pid,node) Get${NodeAttribute}]
            }
            # For legacy purposes 
            if {$EMAtlasBrainClassifier(Cattrib,$NumClass,StopEMMaxIter) == 0} {set EMAtlasBrainClassifier(Cattrib,$NumClass,StopEMMaxIter) $EMiteration}
            if {$EMAtlasBrainClassifier(Cattrib,$NumClass,StopMFAMaxIter) == 0} {set EMAtlasBrainClassifier(Cattrib,$NumClass,StopMFAMaxIter) $MFAiteration}

        } elseif {$ClassName == "vtkMrmlSegmenterClassNode" } {
            # --------------------------------------------------
            # 7.) Update selected Class List 
            # -------------------------------------------------
            # If you get an error mesaage in the follwoing lines then CurrentClassList to short       
            set NumClass [lindex $CurrentClassList 0]
            if {$NumClass == ""} { DevErrorWindow "Error in XML File : Super class $EMAtlasBrainClassifier(SuperClass)  has not enough sub-classes defined" }
            set CurrentClassList [lrange $CurrentClassList 1 end]

            set EMAtlasBrainClassifier(Class) $NumClass
            set pid [$item GetID]
            set EMAtlasBrainClassifier(Cattrib,$NumClass,Label) [SegmenterClass($pid,node) GetLabel] 
            # Define all parameters that do not be specially considered
            foreach NodeAttribute $EMAtlasBrainClassifier(MrmlNode,SegmenterClass,AttributeList) { 
                set EMAtlasBrainClassifier(Cattrib,$NumClass,$NodeAttribute)     [SegmenterClass($pid,node) Get${NodeAttribute}]
            }

            set VolumeName  [SegmenterClass($pid,node) GetLocalPriorName]
            set VolumeIndex [lsearch $VolumeNameList $VolumeName]
            if {($VolumeName != "") && ($VolumeIndex > -1) } { set EMAtlasBrainClassifier(Cattrib,$NumClass,ProbabilityData) [lindex $Volume(idList) $VolumeIndex]
            } else { set EMAtlasBrainClassifier(Cattrib,$NumClass,ProbabilityData) $Volume(idNone) }

            set VolumeName  [SegmenterClass($pid,node) GetReferenceStandardFileName]
            set VolumeIndex [lsearch $VolumeNameList $VolumeName]
            if {($VolumeName != "") && ($VolumeIndex > -1) } { set EMAtlasBrainClassifier(Cattrib,$NumClass,ReferenceStandardData) [lindex $Volume(idList) $VolumeIndex]
            } else { set EMAtlasBrainClassifier(Cattrib,$NumClass,ReferenceStandardData) $Volume(idNone) }

            set index 0
            set LogCovariance  [SegmenterClass($pid,node) GetLogCovariance]
            set LogMean [SegmenterClass($pid,node) GetLogMean]
            set InputChannelWeights [SegmenterClass($pid,node) GetInputChannelWeights]
            for {set y 0} {$y < $EMAtlasBrainClassifier(MaxInputChannelDef)} {incr y} {
                set EMAtlasBrainClassifier(Cattrib,$NumClass,LogMean,$y) [lindex $LogMean $y]
                if {[lindex $InputChannelWeights $y] == ""} {set EMAtlasBrainClassifier(Cattrib,$NumClass,InputChannelWeights,$y) 1.0
                } else {
                    set EMAtlasBrainClassifier(Cattrib,$NumClass,InputChannelWeights,$y) [lindex $InputChannelWeights $y]
                }
                for {set x 0} {$x < $EMAtlasBrainClassifier(MaxInputChannelDef)} {incr x} {
                    set EMAtlasBrainClassifier(Cattrib,$NumClass,LogCovariance,$y,$x)  [lindex $LogCovariance $index]
                    incr index
                }
                # This is for the extra character at the end of the line (';')
                incr index
            }
        } elseif {$ClassName == "vtkMrmlSegmenterCIMNode" } {
            # --------------------------------------------------
            # 8.) Update selected CIM List 
            # -------------------------------------------------
            set pid [$item GetID]        
            set dir [SegmenterCIM($pid,node) GetName]
            if {[lsearch $EMAtlasBrainClassifier(CIMList) $dir] > -1} { 
                set i 0
                set CIMMatrix [SegmenterCIM($pid,node) GetCIMMatrix]
                set EMAtlasBrainClassifier(Cattrib,$EMAtlasBrainClassifier(SuperClass),CIMMatrix,$dir,Node) $item
                foreach y $EMAtlasBrainClassifier(Cattrib,$EMAtlasBrainClassifier(SuperClass),ClassList) {
                    foreach x $EMAtlasBrainClassifier(Cattrib,$EMAtlasBrainClassifier(SuperClass),ClassList) {
                        set EMAtlasBrainClassifier(Cattrib,$EMAtlasBrainClassifier(SuperClass),CIMMatrix,$x,$y,$dir) [lindex $CIMMatrix $i]
                        incr i
                    }
                    incr i
                }
            }
        } elseif {$ClassName == "vtkMrmlEndSegmenterSuperClassNode" } {
            # --------------------------------------------------
            # 11.) End of super class 
            # -------------------------------------------------
            # Pop the last parent from the Stack
            set temp [lindex $SclassMemory end]
            set SclassMemory [lreplace $SclassMemory end end]
            set CurrentClassList [lindex $temp 1] 
            set EMAtlasBrainClassifier(SuperClass) [lindex $temp 0] 
        } elseif {$ClassName == "vtkMrmlEndSegmenterNode" } {
            # --------------------------------------------------
            # 12.) End of Segmenter
            # -------------------------------------------------
            # if there is no EndSegmenterNode yet and we are reading one, and set
            # the EMAtlasBrainClassifier(EndSegmenterNode) variable
            if {[llength $EMAtlasBrainClassifier(Cattrib,0,ClassList)]} { set EMAtlasBrainClassifier(Class) [lindex $EMAtlasBrainClassifier(Cattrib,0,ClassList) 0]
            } else { set EMAtlasBrainClassifier(Class) 0 }
        }    
        set item [Mrml(dataTree) GetNextItem]
    }
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_StartEM 
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_StartEM
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_StartEM { } {
    global EMAtlasBrainClassifier Volume Mrml env tcl_platform EMSegment
    # ----------------------------------------------
    # 2. Check Values and Update MRML Tree
    # ----------------------------------------------
    if {$EMAtlasBrainClassifier(NumInputChannel)  == 0} {
        DevErrorWindow "Please load a volume before starting the segmentation algorithm!"
        return
    }
    
    if {$EMAtlasBrainClassifier(Cattrib,0,StopEMMaxIter) <= 0} {
        DevErrorWindow "Please select a positive number of iterations (Step 2)"
        return
    }

    if {($EMAtlasBrainClassifier(SegmentationBoundaryMin,0) < 1) ||  ($EMAtlasBrainClassifier(SegmentationBoundaryMin,1) < 1) || ($EMAtlasBrainClassifier(SegmentationBoundaryMin,2) < 1)} {
        DevErrorWindow "Boundary box must be greater than 0 !" 
        return
    }
    # ----------------------------------------------
    # 3. Call Algorithm
    # ----------------------------------------------
    set ErrorFlag 0
    set WarningFlag 0
    set VolIndex [lindex $EMAtlasBrainClassifier(SelVolList,VolumeList) 0]

    set EMAtlasBrainClassifier(VolumeNameList) ""
    foreach v $Volume(idList) {
        lappend EMAtlasBrainClassifier(VolumeNameList)  [Volume($v,node) GetName]
    }
    set NumInputImagesSet [EMAtlasBrainClassifier_AlgorithmStart EMAtlasBrainClassifier] 

    EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) Update

    if {[EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) GetErrorFlag]} {
        set ErrorFlag 1
        DevErrorWindow "Error Report: \n[EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) GetErrorMessages]Fix errors before resegmenting !"
        RenderAll
    }
    if {[EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) GetWarningFlag]} {
        set WarningFlag 1
        puts "================================================"
        puts "Warning Report:"
        puts "[EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) GetWarningMessages]"
        puts "================================================"
    }
    
    # ----------------------------------------------
    # 4. Write Back Results - or print our error messages
    # ----------------------------------------------
    if {$ErrorFlag} {
        $EMSegment(MA-lRun) configure -text "Error occured during Segmentation"
    } else {
        if {$WarningFlag} {
            if {$EMAtlasBrainClassifier(BatchMode)} {
                puts "Segmentation compledted sucessfull with warnings! Please read report!"
            } else { 
                $EMSegment(MA-lRun) configure -text "Segmentation compledted sucessfull\n with warnings! Please read report!"
            }
        } else {
            if {$EMAtlasBrainClassifier(BatchMode)} {
                puts "Segmentation completed sucessfull"
            } else {
                $EMSegment(MA-lRun) configure -text "Segmentation completed sucessfull"
            }
        }
        incr EMAtlasBrainClassifier(SegmentIndex)

        set result [DevCreateNewCopiedVolume $VolIndex "" "EMAtlasSegResult$EMAtlasBrainClassifier(SegmentIndex)" ]
        set node [Volume($result,vol) GetMrmlNode]
        $node SetLabelMap 1
        Mrml(dataTree) RemoveItem $node 
        set nodeBefore [Volume($VolIndex,vol) GetMrmlNode]
        Mrml(dataTree) InsertAfterItem $nodeBefore $node

        # Display Result in label mode 
        Volume($result,vol) UseLabelIndirectLUTOn
        Volume($result,vol) Update
        Volume($result,node) SetLUTName -1
        Volume($result,node) SetInterpolate 0
        #  Write Solution to new Volume  -> Here the thread is called
        Volume($result,vol) SetImageData [EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) GetOutput]
        EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) Update
        # ----------------------------------------------
        # 5. Recover Values 
        # ----------------------------------------------
        MainUpdateMRML
        
        # This is necessary so that the data is updated correctly.
        # If the programmers forgets to call it, it looks like nothing
        # happened
        MainVolumesUpdate $result

        # Display segmentation in window . can also be set to Back 
        MainSlicesSetVolumeAll Fore $result
        MainVolumesRender
    }
    # ----------------------------------------------
    # 6. Clean up mess 
    # ----------------------------------------------
    # This is done so the vtk instance won't be called again when saving the model
    # if it does not work also do the same to the input of all the subclasses - should be fine 
    while {$NumInputImagesSet > 0} {
        incr NumInputImagesSet -1
        EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) SetImageInput $NumInputImagesSet "" 
    }
    
    if {[EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) GetErrorFlag] == 0} { 
        Volume($result,vol) SetImageData [EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) GetOutput]
    }
    EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) SetOutput ""
    
    EMAtlasBrainClassifier_DeleteVtkEMAtlasBrainClassifier EMAtlasBrainClassifier
    MainUpdateMRML
    RenderAll
    
    # ----------------------------------------------
    # 7. Run Dice measure if necessary 
    # ----------------------------------------------
    if {$ErrorFlag == 0} { set EMAtlasBrainClassifier(LatestLabelMap) $result }
}


#-------------------------------------------------------------------------------
# .PROC  EMAtlasBrainClassifier_SetVtkGenericClassSetting
# Settings defined by vtkImageEMGenericClass, i.e. variables that have to be set for both CLASS and SUPERCLASS 
# Only loaded for private version 
# .ARGS
# string vtkGenericClass
# string Sclass
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_SetVtkGenericClassSetting {EMVersionVariable vtkGenericClass Sclass} {
    global Volume

    # Kilian Jan 06 : Changed this here so that I could also call the functions from EMLocalSegment
    # So now we link the variable with the name $EMVersionVariable to EMArray
    upvar #0 $EMVersionVariable EMArray

    $vtkGenericClass SetNumInputImages $EMArray(NumInputChannel) 
    eval $vtkGenericClass SetSegmentationBoundaryMin $EMArray(SegmentationBoundaryMin,0) $EMArray(SegmentationBoundaryMin,1) $EMArray(SegmentationBoundaryMin,2)
    eval $vtkGenericClass SetSegmentationBoundaryMax $EMArray(SegmentationBoundaryMax,0) $EMArray(SegmentationBoundaryMax,1) $EMArray(SegmentationBoundaryMax,2)

    $vtkGenericClass SetProbDataWeight $EMArray(Cattrib,$Sclass,LocalPriorWeight)

    $vtkGenericClass SetTissueProbability $EMArray(Cattrib,$Sclass,Prob)
    $vtkGenericClass SetPrintWeights $EMArray(Cattrib,$Sclass,PrintWeights)

    for {set y 0} {$y < $EMArray(NumInputChannel)} {incr y} {
        if {[info exists EMArray(Cattrib,$Sclass,InputChannelWeights,$y)]} {$vtkGenericClass SetInputChannelWeights $EMArray(Cattrib,$Sclass,InputChannelWeights,$y) $y}
    }
}


#-------------------------------------------------------------------------------
# .PROC  EMAtlasBrainClassifier_SetVtkAtlasSuperClassSetting
# Setting up everything for the super classes  
# Only loaded for private version 
# .ARGS
# string SuperClass
# .END
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_SetVtkAtlasSuperClassSetting
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_SetVtkAtlasSuperClassSetting {EMVersionVariable SuperClass} {
    global Volume
    
    # Kilian Jan 06 : Changed this here so that I could also call the functions from EMLocalSegment
    # So now we link the variable with the name $EMVersionVariable to EMArray
    upvar #0 $EMVersionVariable EMArray

    catch { EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) Delete}
    vtkImageEMAtlasSuperClass EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass)      

    # Define SuperClass specific parameters
    EMAtlasBrainClassifier_SetVtkGenericClassSetting $EMVersionVariable EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) $SuperClass

    EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) SetPrintFrequency $EMArray(Cattrib,$SuperClass,PrintFrequency)
    EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) SetPrintBias      $EMArray(Cattrib,$SuperClass,PrintBias)
    EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) SetPrintLabelMap  $EMArray(Cattrib,$SuperClass,PrintLabelMap)
    EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) SetProbDataWeight $EMArray(Cattrib,$SuperClass,LocalPriorWeight)
    # Kilian Jan 06: Wont change anything bc currently the template file is defined in such a way that it is the same accross superclasses 
    EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) SetStopEMMaxIter  $EMArray(Cattrib,$SuperClass,StopEMMaxIter)
    EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) SetStopMFAMaxIter $EMArray(Cattrib,$SuperClass,StopMFAMaxIter)

    # Kilian : Jan06 Added new parameters to simplify debuging
    if {$EMArray(Cattrib,$SuperClass,InitialBiasFilePrefix) != "" } {
        puts "SuperClass $SuperClass: Activated initial Bias setting with $EMArray(Cattrib,$SuperClass,InitialBiasFilePrefix) " 
        EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) SetInitialBiasFilePrefix     $EMArray(Cattrib,$SuperClass,InitialBiasFilePrefix)
    }
    if {$EMArray(Cattrib,$SuperClass,PredefinedLabelMapPrefix)  != "" } {
        puts "SuperClass $SuperClass: Activated predefined labelmap with $EMArray(Cattrib,$SuperClass,PredefinedLabelMapPrefix)" 
        EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) SetPredefinedLabelMapPrefix  $EMArray(Cattrib,$SuperClass,PredefinedLabelMapPrefix) 
    }

    set ClassIndex 0
    foreach i $EMArray(Cattrib,$SuperClass,ClassList) {
        if {$EMArray(Cattrib,$i,IsSuperClass)} {
            if {[EMAtlasBrainClassifier_SetVtkAtlasSuperClassSetting  $EMVersionVariable $i]} {return [EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMSuperClass) GetErrorFlag]}
            EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) AddSubClass EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMSuperClass) $ClassIndex
        } else {
            catch {EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMClass) destroy}
            vtkImageEMAtlasClass EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMClass)      
            EMAtlasBrainClassifier_SetVtkGenericClassSetting $EMVersionVariable EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMClass) $i

            EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMClass) SetLabel             $EMArray(Cattrib,$i,Label) 

            if {$EMArray(Cattrib,$i,ProbabilityData) != $Volume(idNone)} {
                # Pipeline does not automatically update volumes bc of fake first input  
                Volume($EMArray(Cattrib,$i,ProbabilityData),vol) Update
                EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMClass) SetProbDataPtr [Volume($EMArray(Cattrib,$i,ProbabilityData),vol) GetOutput]
                
            } else {
                set EMArray(Cattrib,$i,LocalPriorWeight) 0.0
            }
            EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMClass) SetProbDataWeight $EMArray(Cattrib,$i,LocalPriorWeight)

            for {set y 0} {$y < $EMArray(NumInputChannel)} {incr y} {
                EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMClass) SetLogMu $EMArray(Cattrib,$i,LogMean,$y) $y
                for {set x 0} {$x < $EMArray(NumInputChannel)} {incr x} {
                    EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMClass) SetLogCovariance $EMArray(Cattrib,$i,LogCovariance,$y,$x) $y $x
                }
            }

            # Setup Quality Related information
            if {($EMArray(Cattrib,$i,ReferenceStandardData) !=  $Volume(idNone)) && $EMArray(Cattrib,$i,PrintQuality) } {
                EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMClass) SetReferenceStandard [Volume($EMArray(Cattrib,$i,ReferenceStandardData),vol) GetOutput]
            } 

            EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMClass) SetPrintQuality $EMArray(Cattrib,$i,PrintQuality)
            # After everything is defined add CLASS to its SUPERCLASS
            EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) AddSubClass EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMClass) $ClassIndex
        }
        incr ClassIndex
    }

    # After attaching all the classes we can defineMRF parameters
    set x 0  

    foreach i $EMArray(Cattrib,$SuperClass,ClassList) {
        set y 0

        foreach j $EMArray(Cattrib,$SuperClass,ClassList) {
            for {set k 0} { $k < 6} {incr k} {
                EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) SetMarkovMatrix $EMArray(Cattrib,$SuperClass,CIMMatrix,$i,$j,[lindex $EMArray(CIMList) $k]) $k $y $x
            }
            incr y
        }
        incr x
    }
    # Automatically all the subclass are updated too and checked if values are set correctly 
    EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) Update
    return [EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) GetErrorFlag] 
}


#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_AlgorithmStart
# Sets up the segmentation algorithm
# Returns 0 if an Error Occured and 1 if it was successfull 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_AlgorithmStart {EMVersionVariable } {
    global Volume 
    # puts "Start EMAtlasBrainClassifier_AlgorithmStart"

    # Kilian Jan 06 : Changed this here so that I could also call the functions from EMLocalSegment
    # So now we link the variable with the name $EMVersionVariable to EMArray
    upvar #0 $EMVersionVariable EMArray

    set NumInputImagesSet 0
    vtkImageEMAtlasSegmenter EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier)
    
    # How many input images do you have
    EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) SetNumInputImages $EMArray(NumInputChannel) 
    EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) SetNumberOfTrainingSamples $EMArray(NumberOfTrainingSamples)
    if {[EMAtlasBrainClassifier_SetVtkAtlasSuperClassSetting $EMVersionVariable 0]} { return 0 }
    # Transfer image information
    set NumInputImagesSet 0
    foreach v $EMArray(SelVolList,VolumeList) {       
        EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) SetImageInput $NumInputImagesSet [Volume($v,vol) GetOutput]
        incr NumInputImagesSet
    }
    # Transfer Bias Print out Information
    EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) SetPrintDir     $EMArray(PrintDir)
    EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) SetHeadClass    EMAtlasBrainClassifier(Cattrib,0,vtkImageEMSuperClass)

    #----------------------------------------------------------------------------
    # Transfering General Information
    #----------------------------------------------------------------------------
    EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) SetAlpha           $EMArray(Alpha) 

    EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) SetSmoothingWidth  $EMArray(SmWidth)    
    EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) SetSmoothingSigma  $EMArray(SmSigma)      

    EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) SetNumIter         $EMArray(Cattrib,0,StopEMMaxIter) 
    EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) SetNumRegIter      $EMArray(Cattrib,0,StopMFAMaxIter) 

    return  $EMArray(NumInputChannel) 
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_DeleteVtkEMSuperClass
# Delete vtkImageEMSuperClass and children attached to it 
# .ARGS
# string Superclass
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_DeleteVtkEMSuperClass { EMVersionVariable SuperClass } {
    # Kilian Jan 06 : Changed this here so that I could also call the functions from EMLocalSegment
    # So now we link the variable with the name $EMVersionVariable to EMArray
    upvar #0 $EMVersionVariable EMArray

    EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) Delete
    foreach i $EMArray(Cattrib,$SuperClass,ClassList) {
        if {$EMArray(Cattrib,$i,IsSuperClass)} {
            EMAtlasBrainClassifier_DeleteVtkEMSuperClass $EMVersionVariable $i
        } else {
            EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMClass) Delete
        }
    }  
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_DeleteVtkEMAtlasBrainClassifier
# Delete vtkEMAtlasBrainClassifier related parameters 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_DeleteVtkEMAtlasBrainClassifier {EMVersionVariable } {
    EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) Delete
    EMAtlasBrainClassifier_DeleteVtkEMSuperClass $EMVersionVariable 0
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_SaveSegmentation
# Saves segmentation results 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_SaveSegmentation { } {
    global EMAtlasBrainClassifier Volume 
    if {$EMAtlasBrainClassifier(LatestLabelMap) == $Volume(idNone)} { 
        DevErrorWindow "Error: Could not segment subject"
    } else {
        set Prefix "$EMAtlasBrainClassifier(WorkingDirectory)/EMSegmentation/EMResult"
        puts ""
        puts "Write results to $Prefix"
        set VolIDOutput $EMAtlasBrainClassifier(LatestLabelMap)
        Volume($VolIDOutput,node) SetFilePrefix "$Prefix"
        Volume($VolIDOutput,node) SetFullPrefix "$Prefix" 
        EMAtlasBrainClassifierVolumeWriter $VolIDOutput
    }
    # Change xml directory
    if {$EMAtlasBrainClassifier(Save,XMLFile)}      {MainMrmlWrite  $EMAtlasBrainClassifier(WorkingDirectory)/EMSegmentation/segmentation.xml}
}


##################
# Core Functions 
##################

#-------------------------------------------------------------------------------
# .PROC EAtlasBrainClassifierStartSegmentation
# This defines the segmentation pipeline
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierStartSegmentation { } {
    global EMAtlasBrainClassifier EMSegment env Mrml

    #kquintus: EMAtlasBrainClassifier produces different atlases and EMResults depending
    #          on how many processors a machine has. Set to single-threaded to produce the
    #          same output always
    
    # Initialization only
    set EMAtlasBrainClassifier(InitialNumberOfThreads) -1
    
    if {$EMAtlasBrainClassifier(MultiThreading) == 0 } {
        catch " vtkMultiThreader tempMultiThreader"
        set EMAtlasBrainClassifier(InitialNumberOfThreads) [tempMultiThreader GetGlobalDefaultNumberOfThreads]
        tempMultiThreader SetGlobalDefaultNumberOfThreads 1
        tempMultiThreader Delete
    }
    
    # ---------------------------------------------------------------
    # Setup Pipeline
    if {[EMAtlasBrainClassifier_InitilizePipeline] == 0} { return 0}  

    # ---------------------------------------------------------------
    # Align T2 to T1 
    if {$EMAtlasBrainClassifier(AlignInput) } {
        # Just perform rigid registration
        EMAtlasBrainClassifierRegistration $EMAtlasBrainClassifier(Volume,SPGR) $EMAtlasBrainClassifier(Volume,T2W) 0 0 
        set VolIDOutput [DevCreateNewCopiedVolume $EMAtlasBrainClassifier(Volume,SPGR) "" "AlignedT2W"]

        # Resample the Atlas SPGR
        EMAtlasBrainClassifierResample   $EMAtlasBrainClassifier(Volume,SPGR) $EMAtlasBrainClassifier(Volume,T2W) $VolIDOutput 0 
        
        set Prefix "$EMAtlasBrainClassifier(WorkingDirectory)/t2w-aligned/I"
        Volume($VolIDOutput,node) SetFilePrefix "$Prefix"
        Volume($VolIDOutput,node) SetFullPrefix "$Prefix" 
        Volume($VolIDOutput,node) SetLittleEndian $EMAtlasBrainClassifier(LittleEndian)
        if {$EMAtlasBrainClassifier(Save,AlignedT2)} {
            EMAtlasBrainClassifierVolumeWriter $VolIDOutput
        }
        set EMAtlasBrainClassifier(Volume,T2W) $VolIDOutput
    }
    
    # ---------------------------------------------------------------
    # Normalize images
    foreach input "SPGR T2W" {
        EMAtlasBrainClassifier_Normalize $input
    }

    # ---------------------------------------------------------------
    # Determine list of atlas 
    # (to be registered and resampled from template file)
    set Result [EMAtlasBrainClassifier_AtlasList $EMAtlasBrainClassifier(XMLTemplate)]
    set RegisterAtlasDirList [lindex $Result 0]
    set RegisterAtlasNameList [lindex $Result 1]
    
    # ---------------------------------------------------------------
    # Register Atlases 
    if {$RegisterAtlasDirList != "" } {
        set RunRegistrationFlag [EMAtlasBrainClassifier_RegistrationInitialize "$RegisterAtlasDirList" ] 
        if {$RunRegistrationFlag < 0} {return 0} 
        if {$RunRegistrationFlag} { 
            EMAtlasBrainClassifier_AtlasRegistration "$RegisterAtlasDirList" "$RegisterAtlasNameList"
        } else {
            puts "============= Skip registration - For Debugging - Only works if little endian of machine is the same as when the atlas was resampled" 
            EMAtlasBrainClassifier_LoadAtlas "$RegisterAtlasDirList" "$RegisterAtlasNameList"
        }
    }


    # ---------------------------------------------------------------------- 
    # Segment Image 

    puts "=========== Segment Image ============ "
    puts "Version of Algorithm: $EMAtlasBrainClassifier(SegmentationMode)"
    # Start algorithm
    # If you want to run the segmentatition pipeline with other EM Segmentation versions just added it here 
    switch $EMAtlasBrainClassifier(SegmentationMode) {
        "EMLocalSegment"         {  EMAtlasBrainClassifier_InitilizeSegmentation  0
            EMSegmentStartEM 
            set EMAtlasBrainClassifier(LatestLabelMap) $EMSegment(LatestLabelMap) 
            EMAtlasBrainClassifier_SaveSegmentation  
        }
        "EMPrivateSegment"       {  
            EMAtlasBrainClassifier_InitilizeSegmentation  1
            set XMLFile $EMAtlasBrainClassifier(WorkingDirectory)/EMSegmentation/segmentation.xml
            set EMSegment(PrintDir) $EMAtlasBrainClassifier(WorkingDirectory)/EMSegmentation
            MainMrmlWrite $XMLFile
            MainMrmlDeleteAll 
            MainVolumesUpdateMRML
            set EMSegment(VolNumber) 0
            set DoNotStart 1 
            if {[catch {source [file join $env(SLICER_HOME) Modules/vtkEMPrivateSegment/tcl/EMSegmentBatch.tcl]} ErrorMsg]} {
                DevErrorWindow "Cannot source EMSegmentBatch. Error: $ErrorMsg"
                return 0
            }
            
            Segmentation $XMLFile 
        }
        "EMAtlasBrainClassifier" {  EMAtlasBrainClassifier_InitilizeSegmentation  1
            EMAtlasBrainClassifier_StartEM 
            EMAtlasBrainClassifier_SaveSegmentation  
        }
        default   {DevErrorWindow "Error: Segmentation mode $EMAtlasBrainClassifier(SegmentationMode) is unknown"; return 0}
    }

    # ---------------------------------------------------------------------- 
    # Generate 3D Models 
    if {$EMAtlasBrainClassifier(GenerateModels) } {
        EMAtlasBrainClassifier_GenerateModels
    }

    puts "=========== Finished  ============ "
    
    # kquintus: set number of threads used back to what it was before EMAtlasBrainClassifierStartSegmentation was executed
    if {$EMAtlasBrainClassifier(MultiThreading) == 0} {
        catch "vtkMultiThreader tempMultiThreader"
        tempMultiThreader SetGlobalDefaultNumberOfThreads $EMAtlasBrainClassifier(InitialNumberOfThreads)
        tempMultiThreader Delete
    }
    
    return 1
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_BatchMode 
# Run it from batch mode 
# The function automatically segments MR images into background, skin, CSF, white matter, and gray matter"
# Execute: slicer2-... <XML-File> --exec "EMAtlasBrainClassifier_BatchMode"
# <XML-File> = The first volume defines the spgr image and the second volume defines the aligned t2w images"
#             The directory of the XML-File defines the working directory" 
# <AlgorithmVersion>  = Optional - the pipeline can be run in different version. Look at EMAtlasBrainClassifierChangeAlgorithm 
#                       for the different settings
# <SegmmentationMode> = Optional - you can run a variaty of different versions, such as EMLocalSegment
#                       which is the version defined in vtkEMLocalSegment
# <TemplateXMLFile>   = Optional - if the pipeline should use an xml file other then the default - please make sure to define AtlasDir 
#                       if structures are included that are not in the default atlas - otherwise the default atlas will be deleted and re-downloaded
# <AtlasDir>          = Optional - Location of atlas directory   
# <FileFormat>        = Optional - file format in which segmentation result, atlas and normed imgages will be stored
# <GenerateModels>    = Optional - default "0" will not generate models. In the end of the model generating process the user currently
#                       gets informed about which models were created and this involves confirming a pop up window with "ok". This is
#                       inconvenient for batch processing.
# .ARGS
# 
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_BatchMode {{AlgorithmVersion Standard} {SegmentationMode ""} \
                       {TemplateXMLFile ""} {AtlasDir "" } {SPGRVolID 1} \
                       {T2VolID 2} {ExitFlag 1} {FileFormat "nhdr"} \
                       {GenerateModels 0} } {
    global Mrml EMAtlasBrainClassifier Volume
    
    set EMAtlasBrainClassifier(WorkingDirectory) $Mrml(dir)

    set EMAtlasBrainClassifier(Volume,SPGR) [Volume($SPGRVolID,node) GetID]
    set EMAtlasBrainClassifier(Volume,T2W)  [Volume($T2VolID,node) GetID]

    # If you set EMAtlasBrainClassifier(BatchMode) to 1 also 
    # set EMAtlasBrainClassifier(Save,*) otherwise when saving xml file 
    # warning window comes up 
    set EMAtlasBrainClassifier(Save,SPGR) 1
    set EMAtlasBrainClassifier(Save,T2W)  1
    set EMAtlasBrainClassifier(BatchMode) 1
    
    set EMAtlasBrainClassifier(AlgorithmVersion) $AlgorithmVersion
   
    EMAtlasBrainClassifierChangeAlgorithm 

    if {$SegmentationMode != "" } {
        set EMAtlasBrainClassifier(SegmentationMode) $SegmentationMode
    }

    if {$TemplateXMLFile != "" } {
        set EMAtlasBrainClassifier(XMLTemplate) $TemplateXMLFile
    }

    if {$AtlasDir != "" } {
        set EMAtlasBrainClassifier(AtlasDir) $AtlasDir
    }

    #kquintus: added option to select different file formats in batch mode
    set EMAtlasBrainClassifier(fileformat) $FileFormat

    set EMAtlasBrainClassifier(GenerateModels) $GenerateModels
   
    #kquintus: locally modified to enable full output for ctest:
    puts "CTEST_FULL_OUTPUT"
    puts ""
    puts "Run segmentation with the following options:"
    puts "Algorithm: $EMAtlasBrainClassifier(AlgorithmVersion)"
    puts "Mode:      $EMAtlasBrainClassifier(SegmentationMode)"
    puts "Template:  $EMAtlasBrainClassifier(XMLTemplate)"
    puts "AtlasDir:  $EMAtlasBrainClassifier(AtlasDir)"

    SplashKill
    
    set SucessFlag [EMAtlasBrainClassifierStartSegmentation]
    if {$ExitFlag} {MainExitProgram [expr 1 - $SucessFlag ] }
    return $SucessFlag
}

