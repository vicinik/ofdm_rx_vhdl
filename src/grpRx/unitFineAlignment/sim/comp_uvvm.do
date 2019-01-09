#----------------------------------*-tcl-*-

##--------------------------------------
## Compilation of UVVM started
##--------------------------------------

if {[file exists uvvm_util] == 0} {
	echo "Create library uvvm_util"
	vlib uvvm_util
    vmap uvvm_util uvvm_util
}

vcom -suppress 1346,1236 -2008 -work uvvm_util ../src/UVVM/uvvm_util/src/types_pkg.vhd
vcom -suppress 1346,1236 -2008 -work uvvm_util ../src/UVVM//uvvm_util/src/adaptations_pkg.vhd
vcom -suppress 1346,1236 -2008 -work uvvm_util ../src/UVVM//uvvm_util/src/string_methods_pkg.vhd
vcom -suppress 1346,1236 -2008 -work uvvm_util ../src/UVVM//uvvm_util/src/protected_types_pkg.vhd
vcom -suppress 1346,1236 -2008 -work uvvm_util ../src/UVVM//uvvm_util/src/global_signals_and_shared_variables_pkg.vhd
vcom -suppress 1346,1236 -2008 -work uvvm_util ../src/UVVM//uvvm_util/src/hierarchy_linked_list_pkg.vhd
vcom -suppress 1346,1236 -2008 -work uvvm_util ../src/UVVM//uvvm_util/src/alert_hierarchy_pkg.vhd
vcom -suppress 1346,1236 -2008 -work uvvm_util ../src/UVVM//uvvm_util/src/license_pkg.vhd
vcom -suppress 1346,1236 -2008 -work uvvm_util ../src/UVVM//uvvm_util/src/methods_pkg.vhd
vcom -suppress 1346,1236 -2008 -work uvvm_util ../src/UVVM//uvvm_util/src/bfm_common_pkg.vhd
vcom -suppress 1346,1236 -2008 -work uvvm_util ../src/UVVM//uvvm_util/src/uvvm_util_context.vhd

if {[file exists uvvm_vvc_framework] == 0} {
	echo "Create library uvvm_vvc_framework"
	vlib uvvm_vvc_framework
    vmap uvvm_vvc_framework uvvm_vvc_framework
}

vcom -2008 -work uvvm_vvc_framework ../src/UVVM//uvvm_vvc_framework/src/ti_vvc_framework_support_pkg.vhd
vcom -2008 -work uvvm_vvc_framework ../src/UVVM//uvvm_vvc_framework/src/ti_generic_queue_pkg.vhd
vcom -2008 -work uvvm_vvc_framework ../src/UVVM//uvvm_vvc_framework/src/ti_data_queue_pkg.vhd
vcom -2008 -work uvvm_vvc_framework ../src/UVVM//uvvm_vvc_framework/src/ti_data_fifo_pkg.vhd
vcom -2008 -work uvvm_vvc_framework ../src/UVVM//uvvm_vvc_framework/src/ti_data_stack_pkg.vhd
vcom -2008 -work uvvm_vvc_framework ../src/UVVM//uvvm_vvc_framework/src/ti_uvvm_engine.vhd