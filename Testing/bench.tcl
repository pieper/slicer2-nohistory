
#
# utility code for running benchmarks
#

proc bench_init {} {

    package require vtk

    catch "bench_mt Delete"
    vtkMultiThreader bench_mt

    set ::BENCH($::env(HOST),numThreads) [bench_mt GetNumberOfThreads]
    set ::BENCH(benchmarks) [glob -nocomplain $::env(SLICER_HOME)/Testing/Benchmarks/*.tcl]

    puts "will use up to $::BENCH($::env(HOST),numThreads) threads"
}


proc bench_run {} {

    bench_init

    foreach benchmark [lsort -dictionary $::BENCH(benchmarks)] {
        set bench [file root [file tail $benchmark]]
        
        for {set memMultiple 1} {$memMultiple < 3} {incr memMultiple} {

            catch "iss Delete"
            vtkImageSinusoidSource iss
            set dim [expr $memMultiple * 400]
            iss SetWholeExtent 0 200 0 200 0 $dim
            [iss GetOutput] Update 
            set id [iss GetOutput]

            set ::BENCH($::env(HOST),$bench,imageSizeInKBytes,$memMultiple) [$id GetActualMemorySize]

            for {set nthreads 1} {$nthreads <= $::BENCH($::env(HOST),numThreads)} {incr nthreads} {

                bench_mt SetGlobalMaximumNumberOfThreads $nthreads

                puts "running $bench on $nthreads at memory multiple $memMultiple"; update

                source $benchmark
                set ret [catch {time "${bench}_run $id"} res]

                if { $ret } {
                    puts "failed: $res"; update
                    set ::BENCH($::env(HOST),$bench,$nthreads,$memMultiple) "failed"
                    break
                } else {
                    puts $res; update
                    set ::BENCH($::env(HOST),$bench,$nthreads,$memMultiple) [expr [lindex $res 0] / 1000000.]
                }

            }
            set percent [expr 100. * $::BENCH($::env(HOST),$bench,$::BENCH($::env(HOST),numThreads),$memMultiple) / (1. * $::BENCH($::env(HOST),$bench,1,$memMultiple))]
            if { $::BENCH($::env(HOST),numThreads) > 1 } {
                set percent2 [expr 100. * $::BENCH($::env(HOST),$bench,2,$memMultiple) / (1. * $::BENCH($::env(HOST),$bench,1,$memMultiple))]
            } else {
                set percent2 100
            }
            set ::BENCH($::env(HOST),$bench,percent) $percent
            set ::BENCH($::env(HOST),$bench,percent2) $percent2

            puts "--> $::BENCH($::env(HOST),numThreads) threads is $percent % of the speed of 1 thread"
            puts "--> 2 threads is $percent2 % of the speed of 1 thread"
            puts ""

            update
        }
    }

    parray ::BENCH

    set fp [open "bench-$::env(HOST)" "w"]
    puts $fp [array get ::BENCH]
    close $fp

}

proc bench_summarize { dir } {

    set files [glob $dir/bench-*]

    set hosts ""
    foreach f $files {
        scan [file tail $f] "bench-%s" host
        lappend hosts $host
        set fp [open $f "r"]
        gets $fp line
        array set $host $line
        close $fp
    }

    array set host0 [array get [lindex $hosts 0]]

    foreach bench $host0(benchmarks) {
        set bench [file root [file tail $bench]]

        puts "== $bench == "

        puts "{| border=\"2\" "
        puts "|+ $bench"
        puts "|- "
        puts -nonewline "! " 
        
        for {set i 1} {$i <= 10} {incr i} {
            puts -nonewline " !! $i " 
        }
        puts -nonewline " !! % 2 Threads !! % Max Threads " 
        puts ""
        puts "|- "
        foreach host $hosts {
            array set h [array get $host]
            puts "|- align=\"right\" "
            puts "! $host"
            puts -nonewline "| "
            for {set t 1} {$t <= 10} {incr t} {
                if {$t <= $h($host,numThreads)} {
                    puts -nonewline "[format %3.2f $h($host,$bench,$t,2)] || "
                } else {
                    puts -nonewline " || "
                }
            }
            puts " [format %3.2f $h($host,$bench,percent2)] || [format %3.2f $h($host,$bench,percent)] "
               
        }
        puts "|}"
        puts ""
    }



}

