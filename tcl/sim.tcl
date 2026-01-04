## ------------------------------------------------------------
## File    : sim.tcl
## Author  : jin820
## Created : 2026-01-01
## Updated :
## History:
## 2026-01-01  Initial version
## ------------------------------------------------------------

puts "=== sim.tcl start ==="

# default values
set MDL_ROOTS   $::CFG(MDL_ROOTS)
set BOARD_NAME  $::CFG(BOARD_NAME)
set BOARD_TOP   work.${BOARD_NAME}
set SEED        $::CFG(SEED)
set SCENARIO    $::CFG(SCENARIO) 
set ENABLE_GUI  $::CFG(ENABLE_GUI)
set ENABLE_WAVE $::CFG(ENABLE_WAVE)
set ENABLE_COV  $::CFG(ENABLE_COV)

set WAVE_DIR "./result/wave"
set COV_DIR "./result/cov"
file mkdir ${WAVE_DIR}
file mkdir ${COV_DIR}

set WLF_FILE  "${WAVE_DIR}/${SCENARIO}.wlf"
set UCDB_FILE "${COV_DIR}/${SCENARIO}.ucdb"

set vsim_opt {}
if {$ENABLE_GUI} {
    lappend vsim_opt -voptargs=+acc

} else {
    lappend vsim_opt -c -voptargs=+acc
}
if {$ENABLE_WAVE} {
    lappend vsim_opt -wlf ${WLF_FILE}
}
if {$ENABLE_COV} {
    lappend vsim_opt -coverage
}

puts "INFO: CONFIG"
puts "  TB        = ${BOARD_TOP}"
puts "  SCENARIO  = ${SCENARIO}"
puts "  SEED      = ${SEED}"
puts "  WLF       = ${WLF_FILE}"
puts "  UCDB      = ${UCDB_FILE}"
puts "  vsim_opt  = ${vsim_opt}"

# run simulation
eval vsim ${vsim_opt} \
     -L work \
     +SCENARIO=${SCENARIO} \
     ${BOARD_TOP} \
     -do "tcl/dumpmisc.tcl"

run 1ms

# save coverage
if {$ENABLE_COV} {
    coverage save ${UCDB_FILE}
}

puts "=== sim.tcl end ==="

