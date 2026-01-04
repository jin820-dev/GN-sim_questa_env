## ------------------------------------------------------------
## File    : default.tcl
## Author  : jin820
## Created : 2026-01-01
## Updated :
## History:
## 2026-01-01  Initial version
## ------------------------------------------------------------

puts "========= default.tcl start ========="

# Helper (env -> tcl)
proc require_env {name} {
    if {![info exists ::env($name)]} {
        error "Required env '$name' is not defined"
    }
    return $::env($name)
}

proc optional_env {name default} {
    if {[info exists ::env($name)]} {
        return $::env($name)
    }
    return $default
}

proc cfg {name {default ""}} {
    if {[info exists ::env($name)]} {
        return $::env($name)
    }
    return $default
}

set DUT_ROOT        [require_env DUT_ROOT]
set MDL_ROOTS       [optional_env MDL_ROOTS     ""]
set SEED            [optional_env SEED          ""]
set SCENARIO        [optional_env SCENARIO      ""]
set TEST_MODE       [optional_env TEST_MODE     ""]
set ENABLE_GUI      [optional_env ENABLE_GUI    ""]
set ENABLE_WAVE     [optional_env ENABLE_WAVE   ""]
set ENABLE_COV      [optional_env ENABLE_COV    ""]

# export for child tcl
set ::CFG(DUT_ROOT)         [file normalize [cfg DUT_ROOT ""]]
set ::CFG(MDL_ROOTS)        [file normalize [cfg MDL_ROOTS ""]]
set ::CFG(SEED)             [cfg SEED           "1"]
set ::CFG(SCENARIO)         [cfg SCENARIO       "scn_basic"]
set ::CFG(TEST_MODE)        [cfg TEST_MODE      "normal"]
set ::CFG(ENABLE_GUI)       [cfg ENABLE_GUI     "0"]
set ::CFG(ENABLE_WAVE)      [cfg ENABLE_WAVE    "0"]
set ::CFG(ENABLE_COV)       [cfg ENABLE_COV     "0"]

# DUT manifest
source $::CFG(DUT_ROOT)/sim/dut.manifest

## export manifest → CFG
foreach k [array names MANIFEST] {
    set ::CFG($k) $MANIFEST($k)
}

# Validation
if {$::CFG(DUT_ROOT) eq ""} {
    puts "ERROR: DUT_ROOT is not set"
    quit -f
}

puts "INFO: CONFIG"
foreach k [lsort [array names ::CFG]] {
    puts "  $k = $::CFG($k)"
}

source tcl/compile.tcl
source tcl/sim.tcl

puts "========= default.tcl end   ========="
puts ""

quit -f

