## ------------------------------------------------------------
## File    : compile.tcl
## Author  : jin820
## Created : 2026-01-01
## Updated :
## History:
## 2026-01-01  Initial version
## 2026-01-05  Added scoreboard compilation
## 2026-01-06  Added guard processing
## ------------------------------------------------------------

puts "=== compile.tcl start ==="

set DUT_ROOT        $::CFG(DUT_ROOT)
set MDL_ROOTS [split $::CFG(MDL_ROOTS) ";"]
set SRCLIST         $::CFG(SRCLIST)
set BOARD_DIR       $::CFG(BOARD_DIR)
set SCENARIO        $::CFG(SCENARIO) 
set SCENARIO_DIR    $::CFG(SCENARIO_DIR)

# --------------------------------------------------
# Optional config defaults (avoid missing CFG(*) errors)
# --------------------------------------------------
if {![info exists ::CFG(SCOREBOARD_DIR)]} { set ::CFG(SCOREBOARD_DIR) "" }
if {![info exists ::CFG(SVA_DIR)]}        { set ::CFG(SVA_DIR) "" }

# Optional feature switches (default: enabled for backward compatibility)
if {![info exists ::CFG(ENABLE_SCB)]} { set ::CFG(ENABLE_SCB) 1 }
if {![info exists ::CFG(ENABLE_SVA)]} { set ::CFG(ENABLE_SVA) 1 }

# clean
set TMP_DIR  [file normalize "tmp"]
set LIB_DIR  "$TMP_DIR/lib"

# clean (delete only build artifacts, keep tmp/.gitkeep)
if {[file exists $LIB_DIR] && [file isdirectory $LIB_DIR]} {
    if {[file tail $LIB_DIR] eq "lib" && [file tail [file dirname $LIB_DIR]] eq "tmp"} {
        puts "INFO: clean lib directory ($LIB_DIR)"
        file delete -force $LIB_DIR
    } else {
        error "Refuse to delete unexpected directory: $LIB_DIR"
    }
}
if {![file exists $TMP_DIR]} {
    puts "INFO: tmp directory not found, skip clean"
}
file mkdir $LIB_DIR

# helper
proc make_lib {libname} {
    global LIB_DIR
    set libpath "$LIB_DIR/$libname"

    if {![file exists $libpath]} {
        vlib $libpath
    }
    vmap $libname $libpath
}

proc is_directory_empty {dir_path} {
    set file_list [glob -nocomplain "$dir_path/*"]

    if {[llength $file_list] == 0} {
        return 1 ;# empty (True)
    } else {
        return 0 ;# not empty (False)
    }
}

# create libraries
make_lib work

## Compile order ##
## ① interface
## ② package（task / class）
## ③ DUT（RTL）
## ④ test_scenario（class / module）
## ⑤ System Verilog Assertion
## ⑥ board_top

## models
foreach mdl_root $MDL_ROOTS {
    set MDL_SRC "${mdl_root}/src"
    set MDL_LIB "${mdl_root}/lib"
    set incdirs "+incdir+${MDL_SRC},+incdir+${MDL_LIB}"

    vlog -sv \
         -work work \
         $incdirs \
         "${MDL_SRC}/*.sv"
}

set INCD_MDL_LIBS ""
foreach mdl_root $MDL_ROOTS {
    append INCD_MDL_LIBS +incdir+${mdl_root}/lib \\
}

# DUT
set SRC_ROOT "${DUT_ROOT}/src"
set fp [open "${DUT_ROOT}/${SRCLIST}" r]
while {[gets $fp line] >= 0} {
    if {$line eq ""} { continue }
    vlog \
        -work work \
        "${SRC_ROOT}/${line}" \
        -cover bcst +define+SIM
}
close $fp

# scenario
vlog -sv \
     -work work \
     ${INCD_MDL_LIBS} \
     "${DUT_ROOT}/${SCENARIO_DIR}/${SCENARIO}.sv"

# SVA
if {$::CFG(ENABLE_SVA)} {
    if { [file isdirectory ${DUT_ROOT}/$::CFG(SVA_DIR)] } {
        if {[is_directory_empty ${DUT_ROOT}/$::CFG(SVA_DIR)]} {
            puts "INFO: ENABLE_SVA=1 but SVA_DIR is empty. Skip SVA compile."
        } else {
            vlog -sv \
                 -mfcu \
                 -cuname work \
                 -work work \
                 "${DUT_ROOT}/$::CFG(SVA_DIR)/*.sv"
        }
    }
} else {
    puts "INFO: SVA compile disabled (ENABLE_SVA=0)"
}

# Scoreboard
if {$::CFG(ENABLE_SCB)} {
    if { [file isdirectory ${DUT_ROOT}/$::CFG(SCOREBOARD_DIR)] } {
        if {[is_directory_empty ${DUT_ROOT}/$::CFG(SCOREBOARD_DIR)]} {
            puts "INFO: ENABLE_SCB=1 but SCOREBOARD_DIR is empty. Skip SCB compile."
        } else {
            vlog -sv \
                 -work work \
                "${DUT_ROOT}/$$::CFG(SCOREBOARD_DIR)/*.sv"
        }
    }
} else {
    puts "INFO: Scoreboard compile disabled (ENABLE_SCB=0)"
}

# board
vlog \
    -sv \
    -work work \
    ${INCD_MDL_LIBS} \
    "${DUT_ROOT}/${BOARD_DIR}/*.sv"

puts "=== compile.tcl end ==="

