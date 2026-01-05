## ------------------------------------------------------------
## File    : compile.tcl
## Author  : jin820
## Created : 2026-01-01
## Updated :
## History:
## 2026-01-01  Initial version
## 2026-01-05  Added scoreboard compilation
## ------------------------------------------------------------

puts "=== compile.tcl start ==="

set DUT_ROOT        $::CFG(DUT_ROOT)
set MDL_ROOTS [split $::CFG(MDL_ROOTS) ";"]
set SRCLIST         $::CFG(SRCLIST)
set BOARD_DIR       $::CFG(BOARD_DIR)
set SCENARIO        $::CFG(SCENARIO) 
set SCENARIO_DIR    $::CFG(SCENARIO_DIR)
set SCOREBOARD_DIR  $::CFG(SCOREBOARD_DIR)
set SVA_DIR         $::CFG(SVA_DIR)

set TMP_DIR  [file normalize "tmp"]
set LIB_DIR  "$TMP_DIR/lib"
file mkdir $LIB_DIR

# library helper
proc make_lib {libname} {
    global LIB_DIR
    set libpath "$LIB_DIR/$libname"

    if {![file exists $libpath]} {
        vlib $libpath
    }
    vmap $libname $libpath
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
vlog -sv \
     -mfcu \
     -cuname work \
     -work work \
     "${DUT_ROOT}/${SVA_DIR}/*.sv"

# scoreboard
vlog -sv \
     -work work \
     "${DUT_ROOT}/${SCOREBOARD_DIR}/*.sv"

# board
vlog \
    -sv \
    -work work \
    ${INCD_MDL_LIBS} \
    "${DUT_ROOT}/${BOARD_DIR}/*.sv"

puts "=== compile.tcl end ==="

