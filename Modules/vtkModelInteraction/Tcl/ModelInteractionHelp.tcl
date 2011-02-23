
proc ModelInteractionHelpBuildGUI {} {
    global Gui ModelInteraction Module Volume Model
    
    
    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    #-------------------------------------------

    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    
    # Write the "help" in the form of psuedo-html.  
    # Refer to the documentation for details on the syntax.
    #
    set help "
    The ModelInteraction module enables 3D picking of models for building model hierarchies, and coloring any model by any volume in slicer.
    <P>
    Description by tab:
    <BR>
    <UL>
    <LI><B>Select:</B> This tab is for selecting models using the mouse, and grouping them to form a model hierarchy. Hit the s key to select the model under the mouse cursor.  The model will then turn red in color, showing it is selected. Hit the d key to deselect the model under the cursor.
The selected models are added to the current group and their ID numbers are shown in the box.  Name the group by clicking the Name button.  Create a new group by hitting the New button.  
The Show/Hide button toggles visibility of the current group of models.
The Show/Hide All button cycles through the display. It shows all models, then only those which have not been put in a group, and finally hides all models. Use this button to see which models have not yet been assigned a group.
The Highlight On/Off button turns on and off the red color for the current group.
The Clear button clears the current group.
The Export to Scene button puts all the groups into the MRML scene as a ModelHierarchy. (This removes any existing hierarchy first.)
The Import from Scene button creates groups using the ModelHierarchy in your MRML scene.

ISSUES: Currently this module only supports one level of groups (no groups of groups).  When exporting to scene, the interaction with the Models tab GUI is not ideal. To refresh this GUI it may be necessary to enter the ModelHierarchy module, then enter the Models tab.

    "
    regsub -all "\n" $help {} help
    MainHelpApplyTags ModelInteraction $help
    MainHelpBuildGUI ModelInteraction

}

