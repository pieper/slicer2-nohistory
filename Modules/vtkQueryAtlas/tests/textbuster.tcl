
proc sometext {} {

    catch "tt Delete"
    vtkTextureText tt
    set ::fm [tt GetFontParameters]
    [tt GetFontParameters] SetFontFileName "SHOWG.TTF"
    [tt GetFontParameters] SetFontDirectory c:/WINDOWS/Fonts/
    [tt GetFontParameters] SetBlur 2
    [tt GetFontParameters] SetStyle 2
    tt SetText "this is *some* text"
    tt CreateTextureText

    catch "follower Delete"
    vtkFollower follower
    follower SetMapper [[tt GetFollower] GetMapper]
    follower SetTexture [tt GetTexture]
    follower SetCamera [viewRen GetActiveCamera]
    viewRen AddActor follower
}


proc lotsofonts {} {
    set pt [lindex [vtkTextureText ListInstances] 0]

    # NOTE - Kinematics.tcl might change the default font dir to something else!
    set fonts [glob c:/WINDOWS/Fonts/*.ttf]

    foreach font $fonts {
        puts [file tail $font]
        update
        [$pt GetFontParameters] SetFontFileName [file tail $font]
        Render3D
    }
}

proc lotsotext {} {
    set pt [lindex [vtkTextureText ListInstances] 0]

    set files [glob Base/tcl/tcl-main/*.tcl]
    foreach file $files {
        set fp [open $file]
        while { ![eof $fp] } {
            gets $fp line    
            puts $line  
            $pt SetText $line
            Render3D
            update
        }
    }
}

