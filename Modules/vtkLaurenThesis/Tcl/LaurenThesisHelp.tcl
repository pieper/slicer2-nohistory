
proc LaurenThesisHelpBuildGUI {} {
    global Gui LaurenThesis Module Volume Model
    
    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    
    # Write the "help" in the form of psuedo-html.  
    # Refer to the documentation for details on the syntax.
    #
    set help "
    Temporary module for thesis-related code.
    <P>
    Description by tab:
    <BR>
    <UL>
    <LI><B>SeedBrain:</B> Seed tracts in a large ROI and save directly to disk for clustering in matlab.
    <BR>
    <LI><B>ProbeTensors:</B> Get tensors for each tract cluster (from matlab) for further analysis (in matlab).
    "
    regsub -all "\n" $help {} help
    MainHelpApplyTags LaurenThesis $help
    MainHelpBuildGUI LaurenThesis

}

