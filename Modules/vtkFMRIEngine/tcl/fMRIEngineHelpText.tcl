#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: fMRIEngineHelpText.tcl,v $
#   Date:      $Date: 2006/05/30 19:45:57 $
#   Version:   $Revision: 1.25 $
# 
#===============================================================================
# FILE:        fMRIEngineHelpText.tcl
# PROCEDURES:  
#   fMRIEngineHelpLoadSequence
#   fMRIEngineHelpLoadVolumeAdjust
#   fMRIEngineHelpSetupChooseDetector
#   fMRIEngineHelpSetup
#   fMRIEngineHelpSetupBlockEventMixed
#   fMRIEngineHelpSetupWaveform
#   fMRIEngineHelpSetupHRFConvolution
#   fMRIEngineHelpSetupTempDerivative
#   fMRIEngineHelpSetupHighpassFilter
#   fMRIEngineHelpSelectHighpassCutoff
#   fMRIEngineHelpSetupLowpassFilter
#   fMRIEngineHelpSetupGlobalMeanFX
#   fMRIEngineHelpSetupGrandMeanFX
#   fMRIEngineHelpPreWhitenData
#   fMRIEngineHelpSetupCustomFX
#   fMRIENgineHelpEstimateWhichRun
#   fMRIEngineHelpSetupEstimate
#   fMRIEngineHelpSetupContrasts
#   fMRIEngineHelpComputeActivationVolume
#   fMRIEngineHelpViewActivationThreshold
#   fMRIEngineHelpViewHighPassFiltering
#   fMRIEngineHelpViewPlotting
#   fMRIEngineHelpSelectLabels  
#   fMRIEngineHelpPriorsLoadLabelmap
#   fMRIEngineHelpPriorsDensityEstimation
#   fMRIEngineHelpPriorsProbability
#   fMRIEngineHelpPriorsTransitionMatrix
#   fMRIEngineHelpPriorsMeanfieldApproximation
#==========================================================================auto=

proc fMRIEngineGetHelpWinID { } {
    if {! [info exists ::fMRIEngine(newID) ]} {
        set ::fMRIEngine(newID) 0
    }
    incr ::fMRIEngine(newID)
    return $::fMRIEngine(newID)
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpLoadSequence
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpLoadSequence { } {
    #--- Sequence->Load
    #--- loading sequences
    set i [ fMRIEngineGetHelpWinID ]
    set txt "<H3>Loading sequences</H3>
 <P> A single file may be loaded by selecting the <I> single file </I> radio button within the Load GUI, and either typing the filename (including its complete path) or using the <I> Browse </I> button to select the file.
<P> A sequence of files may be loaded by selecting the <I> multiple files </I> radio button and specifying an appropriate file filter in the Load GUI, and then using the <I> Browse </I> button to select one of the files.
<P><B>Supported file formats</B>
<P> Currently the fMRIEngine supports the loading of Analyze, DICOM and BXH single- and multi-volume sequences."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 18 $txt
}

#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpLoadVolumeAdjust
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpLoadVolumeAdjust { } {
    #--- Sequence->Select
    #--- applying window/level/threshold.
    set i [ fMRIEngineGetHelpWinID ]
    set txt "<H3>Window-Level-Threshold</H3>
<P> To adjust the window, level or threshold of an entire sequence, view one of its volumes in Slicer's main Viewer, go to the Volumes module's <I>Display</I< tab. There, the volume's window, level, threshold and palette may be adjusted. To apply these adjustments to the entire sequence, go immediately back to the fMRIEngine's Sequence->Select tab and use the <I>Select Window/Level/Threshold </I> button.
<P><B>Brain masking</B>
<P> The non-brain background in a sequence may be masked by thresholding the sequence in the manner described above. This action prevents spurious activations outside the brain from being computed.
<P><B>Color-coded display of activation</B>
<P> To use color to represent different p-values in the computed activation volume, go to the Volumes module's Display tab and choose the <I>Rainbow</I> or <I>Iron</I> palettes."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt
}

#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpSetupChooseDetector
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpSetupChooseDetector { } {
    #--- Setup
    #--- Choose a method of activation detection
    set i [ fMRIEngineGetHelpWinID ]    
    set txt "<H3>Methods of activation detection</H3>
<P> The fMRIEngine is being developed to offer different methods of computing brain activations from fMRI data, and to act as a platform for comparing their performance. Currently this module only supports the commonly used general linear model approach to fMRI analysis {1,2,3}. An activation detector based on Mutual Information, and the ability to incorporate spatial priors into either detection method are currently being developed. Once multiple detectors become available, the Setup tab's GUI will present different and appropriate input options for each.
<P><B>Linear modeling</B>
<P> This method fits a linear model, consisting of both active responses to the stimulus paradigm and noise from various sources, to the observed voxel timecourse data. To build the model, a paradigm is specified in the <I>Paradigm specification</I> GUI, and a corresponding collection of variables representing the BOLD signal and some added noise are designed in the <I>Signal Modeling</I> GUI. This approach relies on the assumption that the observed data's underlying distribution is Gaussian, and independent and identically distributed (i.i.d).
<P><B>1.</B> K.J. Friston, P. Jezzard, and R. Turner, 'The analysis of functional MRI time-series,' <I>Human Brain Mapping,</I> vol. 1, pp. 153-171, 1994.
<P><B>2.</B> K.J. Friston, A.P. Holmes, K.J. Worsley, J.P. Poline, C.D. Frith, and R.S.J. Frackowiak, 'Statistical parametric maps in functional imaging: A general linear approach,' <I>Human Brain Mapping,</I> vol. 2, pp. 189-210, 1995.
<P><B>3.</B> K.J.Friston, 'Statistical parametric mapping and other analysis of functional imaging data,' in <I>Brain Mapping: The Methods,</I> pp. 363-385. Academic Press, 1996."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt
}

#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpSetup
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpSetup { } {
    #--- Setup ->Specify [paradigm design, signal modeling, contrasts ]
    #--- Explain what we are specifying
    set i [ fMRIEngineGetHelpWinID ]    
    set txt "<H3>Specifying the model and contrasts</H3>
<P> Three steps are grouped together in this GUI panel: paradigm design, signal modeling and contrast specification. Each of these steps is described below.
<P><B>1. Paradigm design</B>
<P> In this step, the stimulus protocol for an experiment is described. Whether the design is a <I>blocked, event-related or mixed</I> design is chosen. The first volume of the loaded sequence to be used in the analysis (to eliminate any dummy scans) and the repetition time TR are specified. The <I>number of runs</I> to be included in the analysis is entered and, if more than one run will be used, whether the conditions in each are <I>identical</I> is noted. If all runs are identical, then each condition can be entered once and will be duplicated across runs. If runs do not contain the same conditions with identical timing parameters, then all conditions for each must be individually specified.
<P> Then, for each experimental condition, a <I>name</I> for the condition is entered along with a number of vectors that describe it: a vector of stimulus <I>onsets</I> is entered, in which each element indicates the number of TRs at which each stimulus presentation was initiated; a vector of <I>durations</I> is entered, in which each element indicates the number of TRs that the stimulus persists for each presentation (for event-related designs, this vector should contain a '1' for each presentation); and a vector of <I>intensities</I> is entered, in which each element indicates the intensity of the stimulus at each presentation. By default, this vector contains '1's, and currently the fMRIEngine does not include linear, exponential or polynomial changes over the course of the experiment; so changes to this vector currently have no effect.
<P> Once data has been entered for a condition, the <I>OK</I> button will add that condition to a list displayed at the bottom of the GUI panel. Any condition in this list may be selected and either edited or deleted using the associated <I>edit</I> and <I>delete</I> buttons. Once all conditions for all runs have been specified, both their representation and that of nuisance signals can be modeled in the next step.
<P><B>2. Signal modeling</B>
<P> For the linear modeling approach to activation detection, signal modeling uses conditions from the paradigm specification as a basis to model the physiological response to them that an experimenter expects to observe. The modeling options provided here attempt to simulate a signal that more closely resembles the hemodyanamic response than does the raw paradigm alone. The raw paradigm can still be used by simply making sure the boxcar waveform and no other modeling option is selected. Once conditions have been modeled, they are referred to as <I>explanatory variables</I> (or EV's), since they are intended to explain different processes resident in the data. Each EV is represented as a column in the design matrix, which can be displayed using the <I>Show model</I> button.
<P><I>2a. Stimulus modeling options</I>
<P> Modeling options include the specification of a stimulus function, which is a basic signal waveform meant to correspond to a stimulus time-course. Selecting the <I>boxcar</I> function produces an EV with a sharp 'on-and-off' signal describing each stimulus presentation, and the <I>half-sine</I> function produces an EV signal with a smoother and symmetric shape during each stimulus presentation. Each stimulus function may next be convolved with the <I>hemodynamic response function</I> (HRF). This option is intended to simulate the brain's BOLD response to the input stimulus. In the fMRIEngine, the HRF is modeled as a difference of two gamma functions:
<P> h(t) = (t/d1)^d1 exp(-(t-d1)/b1)   -  c(t/d2)^d1 exp(-(t-d2)b2)
<P>with d1,d2,b1,b2, and c as specified in {1}. The result of convolving the stimulus function with the HRF yields an EV signal with a slight delay at stimulus onset, blur, and an undershoot at the end of each stimulus presentation. Adding temporal derivatives is a another way of creating an EV with a small onset delay for each stimulus presentation.
<P><I>2b. Noise modeling options</I>
<P> Low frequency scanner drift is often observable in the voxel timecourse as slow changes in intensity. Various methods of modeling drift components exist, though it remains difficult to specify a drift model that is equally valid for every fMRI dataset. The fMRIEngine currently provides a set of commonly used Discrete Cosine Transform basis functions to model this low frequency noise. Choosing to high-pass filter the data with the default <I>DCbasis</I> automatically generates additional explanatory variables to capture frequency variations in the observed data, which exist below the frequency corresponding to twice the longest epoch spacing within any of the conditions.
<P> Once a condition has been modeled, clicking the <I>OK</I> button will add the resulting EV to a list displayed at the bottom of the GUI panel. Any EV in this list may be selected and either edited or deleted using the associated <I>edit</I> and <I>delete</I> buttons. Once all conditions have been modeled and any EVs for noise modeling have been specified, the model can be estimated by clicking the <I>estimate</I> button.
<P><B>3. Contrast specification</B>
<P> In this step, scientific questions about the data are specified. Detecting evidence of an effect by looking for significant differences between conditions is accomplished by performing a T-test. This statistical test computes the ratio of the effect to its standard error; large values of T indicate evidence of an effect. The particular differences among parameters that describe the effect in question are specified by a <I>contrast</I> vector. Individual contrasts can be defined by entering a name and a vector whose number of elements equals the number of columns in the design matrix, and whose individual elements describe the comparison among its columns. The fMRIEngine will automatically add any non-specified trailing zeros to a contrast vector, so only the elements up to and including the last non-zero element need to be entered.
<P> Once each contrast has been named and defined, clicking the <I>OK</I> button will add the resulting contrast to a list displayed at the bottom of the GUI panel. Any contrast in this list may be selected and either edited or deleted using the associated <I>edit</I> or <I>delete</I> buttons. It is useful to use the design matrix as visual reference (by clicking the <I>Show model</I> button) while specifying each contrast vector. As contrasts are specified, clicking the <I>update</I> button on the popup model view window will visually display all defined contrast below the design matrix.
<P> After these three steps have been completed, the fMRIEngine's <I>Compute</I> tab GUI permits individual brain activation volumes that correspond to each defined T-test to be computed. 

<P><B>1.</B> G.H.Glover, 'Deconvolution of impulse response in event-related BOLD fMRI,' <I>Neuroimage,</I> vol. 9, pp. 416-20, 1999."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt
}

#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpSetupBlockEventMixed
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpSetupBlockEventMixed { } {
    #--- Setup->Paradigm
    #--- Design type: blocked/event-related/mixed
    set i [ fMRIEngineGetHelpWinID ]
    set txt "<H3>Experimental paradigms</H3>
<P><B>Blocked design </B>
<P> In a <I>blocked</I> task paragidm, a given condition may consist of a series of stimulus presentations, each of which persists for a discrete epoch of time. Here, block paradigms are specified by entering the number of the first volume to be included in the analysis (to eliminate dummy scans) the scan repetition time TR, a vector of stimulus presentation onsets (in multples of TR), a vector of epoch durations (in multiples of TR), and a vector of intensities (currently unimplemented, so no temporal intensity changes can be modeled).
<P><B>Event-related design </B>
<P> In a <I>event-related</I> task paradigm, individual stimulus presentations -- or even different components of an individual stimulus presentation -- are measured at an instant in time, rather than as persisting through some finite duration. Event-related paradigms are specified by entering the
number of the first volume to be included in the analysis (to eliminate dummy scans), the scan repetition time TR, a vector of stimulus presentation onsets (in multiples of TR), and a vector of stimulus intensities (currently unimplemented, so no temporal intensity changes can be modeled), In
event-reltaed designs, each stimulus duration is presumably modeled by a delta function, assumed to be of duration '0' TRs. In practical terms, we model the event duration as the smallest unit of time represented in the signal (currently 0.1 second). If no vector is typed into the durations entry widget for event-related designs, the fMRIEngine will model each onset in this fashion by default.
<P><B>Mixed design </B>
<P> In <I>mixed</I> task paradigms, the conventions for blocked and event-related paradigms described above are followed, with each event-related stimulus presentation having a duration of 0 TR, and blocked presentations having a longer duration. Unlike in a purely event-related design, the duration vector must be user-specified, with events explicitly represented as having duration = 0."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt
}

#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpSetupWaveform
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpSetupWaveform { } {
    #--- Setup->Signal
    #--- What is waveform?
    set i [ fMRIEngineGetHelpWinID ]
    set txt "<H3>Stimulus function</H3>
<P> Modeling options include the specification of a stimulus function, which is a basic signal waveform meant to correspond to a stimulus time-course. The <I>boxcar</I> function is selected by default, and produces an EV with a sharp 'on-and-off' signal describing each stimulus presentation. The <I>half-sine</I> function may be selected instead; it produces an EV signal with a smoother and symmetric shape during each stimulus presentation.
<P> Once a waveform has been selected, additional modeling options may be applied. When signal modeling is complete, clicking the <I>OK</I> button will add the resulting EV to a list displayed at the bottom of the GUI panel. Any EV in this list may be selected and either edited or deleted using the associated <I>edit</I> and <I>delete</I> buttons. By default, an EV that represents the <I>baseline</I> for every run will be automatically added to this list. If this EV is not desireable, it may be selected and deleted.
<P>When all conditions have been modeled and any EVs for noise modeling have been specified, the model can be estimated by clicking the <I>estimate</I> button."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt
}

#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpSetupHRFConvolution
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpSetupHRFConvolution { } {
    #--- Setup->Signal
    #--- What is HRF convolution?
    set i [ fMRIEngineGetHelpWinID ]
    set txt "<H3>Hemodynamic response</H3>
<P> Any stimulus function may be convolved with the <I>hemodynamic response function</I> (HRF). This option is intended to simulate the brain's BOLD response to the input stimulus, and to therefore better fit the observed voxel timecourse data. A BOLD response resident within a particular voxel timecourse usually occurs between 3 and 10 seconds after the stimulus onset, peaking at about 6 seconds. In the fMRIEngine, the HRF is modeled as a difference of two gamma functions:
<P> h(t) = (t/d1)^d1 exp(-(t-d1)/b1)   -  c(t/d2)^d1 exp(-(t-d2)b2)
<P>with d1,d2,b1,b2, and c as specified in {1}. The result of convolving the stimulus function with the HRF yields an EV signal with a slight delay at stimulus onset, blur, and an undershoot at the end of each stimulus presentation.
<P> Once all signal modeling for an EV has been completed, clicking the <I>OK</I> button will add the resulting EV to a list displayed at the bottom of the GUI panel. Any EV in this list may be selected and either edited or deleted using the associated <I>edit</I> and <I>delete</I> buttons. When all conditions have been modeled and any EVs for noise modeling have been specified, the model can be estimated by clicking the <I>estimate</I> button."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpSetupTempDerivative
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpSetupTempDerivative { } {
    #--- Setup->Signal
    #--- What is adding temporal derivatives?
    set i [ fMRIEngineGetHelpWinID ]
    set txt "<H3>Temporal derivatives</H3>
<P> Adding temporal derivatives to a stimulus function, or a stimulus function convolved with the HRF is a way to account for a small onset delay in the response to each stimulus presentation, in effort to better fit the observed voxel timecourse data. In this interface, you can choose to add the first, or the first and second derivatives of the stimulus waveform to the model.
<P> Once all signal modeling for an EV has been completed, clicking the <I>add to model</I> button will add the resulting EV to a list displayed at the bottom of the GUI panel. Any EV in this list may be selected and either edited or deleted using the associated <I>edit</I> and <I>delete</I> buttons. When all conditions have been modeled and any EVs for noise modeling have been specified, the model can be estimated by proceeding to the <I>estimate</I> step."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt
}

#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpSetupHighpassFilter
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpSetupHighpassFilter { } {
    #--- Setup->Signal
    #--- What is highpass filtering?
    set i [ fMRIEngineGetHelpWinID ]
    set txt "<H3>Nuissance signal modeling</H3>
<P> In fMRI data, the voxel timecourse may contain drift that manifests as a slow intensity variation over time. One way to remove this nuisance signal is to introduce low frequency EVs into the linear model which will capture slowly varying processes in the data. Cosines, polynomials, splines or exploratory functions are often used for this purpose, though it remains difficult to specify a drift model that is equally valid for every fMRI dataset.
<P> The fMRIEngine currently provides a set of commonly used Discrete Cosine Transform basis functions to model drift. Modeling slow intensity variation with the default <I>DCbasis</I> generates an appropriate set of additional explanatory variables that separate low frequencies (below the frequency corresponding to the lowest rate of stimuli presentation in the entire paradigm) from the signal of interest in the observed data. These additional EVs will show up as extra columns in the design matrix, for each run to which they're applied. A conservative cutoff period, which is lower than the longest period in the current run's paradigm is chosen by default. A custom cutoff period (specified as a multiple of TR) may be chosen as well.
<P> Once a condition has been modeled, clicking the <I>OK</I> button will add the resulting EV to a list displayed at the bottom of the GUI panel. Any EV in this list may be selected and either edited or deleted using the associated <I>edit</I> and <I>delete</I> buttons. Once all conditions have been modeled and any EVs for noise modeling have been specified, the model can be estimated by clicking the <I>estimate</I> button."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt

}



#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpSelectHighpassCutoff
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpSelectHighpassCutoff { } {
    set i [ fMRIEngineGetHelpWinID ]
    set txt "<H3>Nuissance signal frequency characteristics</H3>
<P> The default cutoff period for nuissance signal modeling is set (as recommended in S.M. Smith, 'Preparing fMRI data for statistical analysis', in <I>Functional MRI, an introduction to methods</I>, P. Jezzard, P.M. Matthews, and S.M. Smith, Eds., 2002, Oxford University Press) at 1.5 times the maximum time interval between the most infrequently occuring event or epoch in the paradigm, multiplied by TR. (The reciprocal of this value represents the cutoff frequency in Hz.)
<P> Use of this default cutoff period is selected by default in the interface, and also by clicking the 'use default' button 
in  the GUI panel. The computed default period (in seconds) for a run is displayed in the entry widget once the full model is computed and any EV in that run is selected for editing; otherwise, the text 'default' will be shown in the widget.  The user may also specify a different (custom) cutoff period instead by typing that value (in seconds) directly into the entry widget and hitting 'enter'."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpSetupLowpassFilter
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpSetupLowpassFilter { } {
    #--- Setup->Signal
    #--- What is Lowpass filter?
    set i [ fMRIEngineGetHelpWinID ]
    set txt "<H3>Low-pass filtering</H3>
<P> Lowpass temporal filtering can be used to reduce high frequency noise, like physiological oscillations due to heart beat or respiration, in each voxel's timecourse. Commonly, the lowpass filtering is accomplished using a simple linear convolution with a Gaussian filter kernel. This operation effectively blurs the values contained in the voxel timecourse. In order to limit the amount of blurring, a fairly narrow Gaussian kernel is used; each sample in the timecourse will be replaced with its original value plus a small fraction of the values of its immediate temporal neighbors.
<P> As noted in S.M Smith, 'Preparing fMRI data for statistical analysis', in <I>Funtional MRI, an introduction to methods</I>, P. Jezzard, P.M. Matthews, and S.M Smith, Eds., 2002, Oxford University Press, care should be taken when using temporal lowpass filtering since the operation can have undesired consequences in later stages of analysis. 
<P><B>When to use temporal lowpass filtering </B>
<P> A lowpass filter can be applied to the voxel timecourse in order to minimize its colored autocorrelation structure, by overwhelming it with a new and know structure. If the resulting noise is white and Gaussian distributed, the embedded signal of interest may be optimally detected in a known fashion. This approach to noise modeling may be described as a 'coloring' approach (see Friston et al., 2000, 'To smooth or not to smooth? Bias and efficiency in fMRItime-series analysis. <I>NeuroImage</I> 12(4):466-477), and distinguished from a 'whitening' approach (see Worsely et al. 2002, A general statistical analysis for fMRI data. <I>NeuroImage</I>, 15(1):1-15). The whitening approach attempts to turn the original colored autocorrelation structure into a white form.
<P> In event-related experiments with rapidly changing signals of interest, blurring may surpress narrow peaks present in the timecourse due to brief stimulation periods. Blurring also increases data smoothness (temporal autocorrelation, or correlation of the errors separated by a fixed time lag). Even without blurring, errors in the estimates of the regression weights are not independent in time. Using the least squares estimate of the regression weights without modeling the temporal correlation structure can cause biases in the estimated error of the regression weight estimates (PEs).
<P> Lowpass filtering should not be used if the data is pre-whitened during statistical analysis. Currently, no pre-whitening options are present in the fMRIEngine, but these are being developed. Once they are available, the lowpass filtering option will be eliminated.
<P> The default lowpass filter full-width half-maxium (FWHM) is given as the TR for the run being modeled, but a narrower or wider filter kernel can be configured using the entry widget."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpSetupGlobalMeanFX
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpSetupGlobalMeanFX { } {
    #--- Setup->Signal
    #--- What is global mean scaling?
    set i [ fMRIEngineGetHelpWinID ]
    set txt "<H3>Global mean scaling</H3>
<P> Part of what is commonly called 'global effects scaling', global mean scaling multiplies all voxels within a scan by N divided by the mean intensity value for that particular scan. (The fMRIEngine uses N=100.0).
<P> A particular problem with global scaling is that a true global mean is not often known; if a large signal increase or decrease is present over many voxels in a given scan, the computed global mean will be increased or decreased respectively and the scaling operation may consequently produce artificial deactivations or activations in other brain regions. Thus, using grand mean scaling in combination with a trend model to capture low frequency temporal variations may yield better results."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpSetupGrandMeanFX
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpSetupGrandMeanFX { } {
    #--- Setup->Signal
    #--- What is grand mean scaling?
    set i [ fMRIEngineGetHelpWinID ]
    set txt "<H3>Grand mean scaling</H3>
<P> As part of what is commonly called 'global effects scaling', grand mean scaling normalizes the entire 4D dataset by a single scaling factor (the mean of the global means). In this normalization, all voxels in all scans are mulitiplied by N divided by the mean intensity value over all scans. (The fMRIEngine uses N=100.0).
<P> Grand mean normalization will not effect statistical results for single subject analysis, but is recommended in order to make subsequent higher-level analysis valid (though these analyses are not yet part of fMRIEngine's functionality)."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpPreWhitenData
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpPreWhitenData { } {
    #--- ROI->Stats
    #--- Select labels for region analysis 
    set i [ fMRIEngineGetHelpWinID ]
    set txt "<H3>Temporal correlation in the timecourse.</H3>
<P> In order for the linear modeling to work properly, the residuals corresponding to any pair of data points within a voxel timecourse should be uncorrelated; however, since the serial samples within each voxel timecourse are themselves likely to be correlated, the errors will probably not be independent in time either. Correlation between scans three seconds apart can be quite high.
<P> Using least squares during model fitting to estimate regression weights without accounting for this temporal correlation can lead to biases in the residuals. To model the temporal correlation structure, we use the first order autoregressive model as described in Worsely et al. 2002, 'A general statistical analysis for fMRI data.' <I>NeuroImage</I>, 15(1):1-15. Using this method, the GLM is fitted first and residals are computed from this first estimate of the regression weights (by subtracting the model from the data). Their temporal correlation structure of the residuals is analyzed by computing the one-lag autocorrelation AR(1). The data are then 'pre-whitened'  and the model is re-fit. The final parameter estimates are used in all subsequent statistical testing of the associated model.
<P> Because the model fitting step is performed twice in this process, the estimation step requires more time to execute when pre-whitening is selected."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpSetupCustomFX
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpSetupCustomFX { } {
    #--- Setup->Signal
    #--- What are custom regresssors?
    set i [ fMRIEngineGetHelpWinID ]
    set txt "<H3>Specifying Custom Regressors</H3>
<P> Not yet available."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt
}


#-------------------------------------------------------------------------------
# .PROC fMRIENgineHelpEstimateWhichRun
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIENgineHelpEstimateWhichRun { } {
    set i [ fMRIEngineGetHelpWinID ]
    set txt "<H3>Select single or concatenated runs</H3>
<P> Select the run for which the model should be estimated. If multiple runs are specified, each can be estimated individually. If a least squares fit to a GLM (y = XB + e) with AR(1) error modeling has been computed for each run, and regression weights appear appropriate to compare across runs, multiple runs may be concatenated together in a single analysis. This concatenated-run analysis can be accomplished by selecting 'concatenated' from the pull down menu.<P> In a concatenated analysis, <B> it's important that signal modeling and contrast vectors be specified accurately </B>, or the 
analysis may fail or produce incorrect results: when concatenating runs, only the explanatory variables (EVs) which represent or are derived from the stimulus schedule (condition-related EVs) are concatenated -- baselines for each run, and EVs that capture nuissance signals for each run are not concatenated. So, to concatenate runs properly, <B>(1)</B> each run should have the same set of condition-related EVs; <B>(2)</B> corresponding condition-related EVs across runs should have the same name; <B>(3)</B> the previous requirements imply that, if derivatives are being used to model latency, each corresponding stimulus signal across runs should have the same number of derivatives; <B>(4)</B> and identical contrast weights should be specified for corresponding condition-related EVs across runs. If these conditions are not met, the analysis will fail."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt    
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpSetupEstimate
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpSetupEstimate { } {
    #--- Setup->Signal
    #--- Estimate the model's fit to the data.
    set i [ fMRIEngineGetHelpWinID ]
    set txt "<H3>Model estimation</H3>
<P> Estimating the model computes the best fit of the design matrix to the observed data, determining the amount that each column in the design matrix contributes to the overall observed voxel timecourse, and accounting for the colored autocorrelation structure of the timecourse data. Currently, the fMRIEngine uses multi-parameter fitting functionality provided by the Gnu Scientific Library (www.gnu.org) to perform a least-squares fit to a general linear model y = XB + e at each voxel.
<P> In this equation, y is the observed voxel timecourse; X is the matrix of explanatory variables and B are the unknown best-fit parameters to be estimated. GSL finds the best fit by minimizing the sum of squared residuals, chi^2, with respect to the parameters B. The result is a set estimated parameters B^ which represent the experimental effect for each column of the design matrix.
<P> In order for the GLM to work properly, the residuals of any pair of data points within a voxel timecourse should be uncorrelated; however, serial samples within each voxel timecourse are likely to be correlated. To remove temporal correlations in the data, the GLM is fitted first without considering them. Residals are then computed in this first pass (by subtracting the model from the data) and their autocorrelation structure is analyzed by computing the one-lag autocorrelation AR(1). The data are then 'whitened' (see Worsely et al. 2002, A general statistical analysis for fMRI data. <I>NeuroImage</I>, 15(1):1-15) and the model is re-fit. These final parameter estimates are used in all subsequent statistical testing of the associated model.
<P> The model may be estimated after signal modeling is complete and either before or after specifying contrasts; but estimation must occur before any activation volumes can be generated."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt    
}

#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpSetupContrasts
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpSetupContrasts { } {
    #--- Setup->Contrasts
    #--- Number of elements = columns in design matrix
    #--- and autofill with zeros
    set i [ fMRIEngineGetHelpWinID ]
    set txt "<H3>Contrast specification</H3>
<P> To determine whether one EV is more related to the data than another, known as <I>contrasting</I> EVs, a <I>contrast vector</I> containing one element for every EV in the design matrix is used to describe which EVs to compare.
<P> For instance, a contrast vector that compares one stimulus type (e.g. EV1) to the baseline uses '1' for the vector element representing the design matrix column in which EV1 appears, and '0' for vector elements representing every other column. To compare EV1 to another stimulus type (e.g. EV2), EV1's contrast value may be specified as '-1', EV2's contrast value as '1', and all vector elements representing other columns of the design matrix are specified as '0'.
<P> All contrasts are given a name and a vector specification (elements separated by spaces) in the Contrasts GUI panel; the fMRIEngine will automatically add any non-specified trailing zeros to a contrast vector, so only the elements up to and including the last non-zero element need to be entered.
<P> Once each contrast has been named and defined, clicking the <I>OK</I> button will add the resulting contrast to a list displayed at the bottom of the GUI panel. Any contrast in this list may be selected and either edited or deleted using the associated <I>edit</I> or <I>delete</I> buttons. It is useful to use the design matrix as visual reference (by clicking the <I>Show model</I> button) while specifying each contrast vector. As contrasts are specified, clicking the <I>update</I> button on the popup model view window will visually display all defined contrasts below the design matrix.
<P> All defined contrasts are used to determine evidence of effects in the <I>Compute</I> tab's GUI panel."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt    
}

#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpComputeActivationVolume
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpComputeActivationVolume { } {
    #--- Compute->computing
    #--- How to threshold activation?
    #--- Relationship between p-value, t-value
    #--- what is activation scale?
    set i [ fMRIEngineGetHelpWinID ]
    set txt "<H3>Computing an activation volume</H3>
<P> After both estimating the model (computing the parameters B^) and defining contrasts, a two-sided T-test can be computed to test for evidence of each effect of interest. The output of each statistical test is a volume of T-statistics that represent the probability of brain activation at individual voxels.
<P> To produce a statistical map from the fMRIEngine's <I>Compute</I> GUI, a contrast is selected and an associated output activation volume is named. The <I>compute</I> button generates the named volume of statistics and displays it in Slicer's main Viewer using a rainbow color palette; blue color indicates voxels with a lower T-score and red color indicates voxels with a high T-score. To view brain activation in the context of the subject's anatomy, this volume may be overlayed onto a co-registered high resolution structural scan in Slicer's Viewer. For display purposes, the window, level and threshold of the activation volume may be adjusted -- without altering the underlying T-statistics -- using the sliders in the <I>Display</I> tab of the Volumes module.
<P>In the fMRIEngine's <I>View</I> panel, the p-values may be thresholded to an appropriate significance level."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt    
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpViewActivationThreshold
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpViewActivationThreshold { } {
    #--- View 
    #--- How to threshold activation?
    #--- Relationship between p-value, t-value
    #--- what is activation scale?
    set i [ fMRIEngineGetHelpWinID ]
    set txt "<H3>Activation thresholding</H3>
<P> Once a statistical map of t-values has been generated, the volume may be thresholded to determine, at a given level of significance, which voxels in the brain were activated. Thresholding may be applied to corrected or uncorrected p-values.
<P> If <I>uncorrected p-values</I> is selected, the chosen threshold is applied to every voxel in the map and uncorrected p-values above the threshold are reported. Uncorrected p-values are likely to include family-wise type I errors, or false positives, given the large number of voxels being tested.
<P> The other two <I> corrected p-values</I> options use the False Discovery Rate (FDR) algorithm for determining suprathreshold p-values (Genovese, C.R., Lazar, N.A., Nichols, T.E., 'Thresholding of Statistical Maps in Functional Neuroimaging Using the False Discovery Rate.', NeuroImage 15:870-878, 2002). Unlike Bonferroni and random field methods which control the chance of <I>any</I> false positives, FDR controls the expected proportion of false positives relative to the number of detections. FDR iuses a more lenient metric for false positives than traditional methods. 
<P> Two options for FDR correction are provided: <I>CIND</I> and <I>CDEP</I>. The <I>CIND</I> option assumes the p-values are independent across voxels while the <I>CDEP</I> option assumes an arbitrary distribution of the p-values across voxels.
<P> Note: adjusting the window, level and threshold of this volume for display purposes (using the <I>Display</I> tab of the Volumes module) has no numerical effect on the underlying t-statistics represented in the volume."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt    

}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpViewHighPassFiltering
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpViewHighPassFiltering { } {
    #--- View 
    #--- Default cutoff frequency
    set i [ fMRIEngineGetHelpWinID ]
    set txt "<H3>Default cutoff frequency</H3>
<P> If high pass filtering is turned on but the cutoff frequency is not valid, a default frequency will be provided. The following steps describe how this value is computed:<BR><BR>
<B>1.</B> From the paradigm design, find the minimum interval (<B>mi</B>) between consecutive presentation of trials of the same type<BR>
<B>2.</B> Cutoff period (<B>cp</B>) = 2 * <B>mi</B> (seconds) <BR>
<B>3.</B> Cutoff frequency (<B>cf</B>) = 1 / <B>cp</B> (cycles per second) <BR>"
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt    
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpViewPlotting
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpViewPlotting { } {
    #--- View 
    #--- Types of plotting
    set i [ fMRIEngineGetHelpWinID ]
    set txt "<H3>Voxel timecourse plotting</H3>
<P> Sometimes visual inspection of the voxel timecourse can reveal trends in the data that may not be well represented by an activation detection algorithm; looking at an individual voxel's response, or the collective response of a cluster of voxels in the form of a timecourse plot might help to disambiguate false positives from actual brain activations, for instance. Several modes of voxel timecourse plotting are available: <I>timecourse</I>, <I>peristimulus historgram</I>, and <I>ROI</I>.
<P><B>Timecourse plot</B>
<P> In this plotting mode (previously called <I>voxel-natural</I>), the observed timecourse of a selected voxel is plotted horizontally along the time axis, and superimposed on a plot of the paradigm signal as reference. Different stimulus conditions within the paradigm are represented by different colors in the plot. Clicking on the voxel timecourse plot itself reveals the numerical voxel values at that timepoint.
<P><B>Peristimulus histogram plot</B>
<P> In this plotting mode, samples from the timecourse of a selected voxel are divided into bins representing each stimulus condition in the paradigm. Each bin contains the combined spans of time during which a stimulus condition of one type was presented. The values of samples spanning the timecourse of each bin are averaged together to depict an average response to the associated stimulus, and response maximum and minimum values are plotted around the average for each sample point."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt    
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpSelectLabels  
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpSelectLabels { } {
    #--- ROI->Stats
    #--- Select labels for region analysis 
    set i [ fMRIEngineGetHelpWinID ]
    set txt "<H3>Label selections</H3>
<P> For fMRI region analysis, a label map has to be created or loaded into Slicer and displayed in the foreground.
<P> To select a label, click a region in any of the slice windows. All labels are originally displayed in white color; clicked labels are turned into green. Multiple selections may be done by clicking multiple labels. If a mistake has been made, click <B>Clear selections</B> button and all current selections will be cleared; green labels will change back to white. Repeat the above procedure to get right selection(s)."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpSetDOF
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpSetDOF { } {
    #--- View 
    #--- How to set the degree of freedom for thresholding activation 
    set i [ fMRIEngineGetHelpWinID ]
    set txt "<H3>Degree of freedom</H3>
<P> The value of degree of freedom (DOF) is calculated by subtracting one (1) from the number of volumes in the fMRI sequence, from which the activation has been computed. The DOF is a required parameter for thresholding the activation volume."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt
}

#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpPriorsLoadLabelmap
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpPriorsLoadLabelmap { } {
    #--- Priors ->Anatomical label map
    set i [ fMRIEngineGetHelpWinID ]    
    set txt "<H3>Loading anatomical label maps</H3>
<P> Bla."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt


}

#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpPriorsDensityEstimation
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpPriorsDensityEstimation { } {
    #--- Priors ->Density estimation
    set i [ fMRIEngineGetHelpWinID ]    
    set txt "<H3>Choosing a density estimation</H3>
<P> Bla."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt
}

#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpPriorsProbability
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpPriorsProbability { } {
    #--- Priors ->Meanfield p(class|label)
    set i [ fMRIEngineGetHelpWinID ]    
    set txt "<H3>Loading p(class|label)</H3>
<P><B>Creating a p(class|label) text file</B>
<P> Bla.
<P><B>Loading a p(class|label) text file</B>
<P> Bla."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt
}

#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpPriorsTransitionMatrix
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpPriorsTransitionMatrix { } {
    #--- Priors ->Meanfield transition matrix
    set i [ fMRIEngineGetHelpWinID ]    
    set txt "<H3>Loading a transition matrix</H3>
<P><B>Creating a transition matrix text file</B>
<P> Bla.
<P><B>Loading a transition matrix text file</B>
<P> Bla."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt
}

#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpPriorsMeanfieldApproximation
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpPriorsMeanfieldApproximation { } {
    #--- Priors ->Meanfield approximation
    set i [ fMRIEngineGetHelpWinID ]    
    set txt "<H3>The meanfield algorithm</H3>
<P><B>Choosing a number of iterations</B>
<P> Bla."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 25 $txt
}
