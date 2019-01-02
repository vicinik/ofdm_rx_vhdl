# File:			clean_all.do
# Description:	This script removes all compiled libraries.

echo "------------------------------------------------"
echo "Remove all libraries"
echo "------------------------------------------------"
echo "Delete old libraries when they exist"

if {[file exists uvvm_util] == 1} {
	echo "Delete library uvvm_util"
	vdel -all -lib uvvm_util
}

if {[file exists uvvm_vvc_framework] == 1} {
	echo "Delete library uvvm_vvc_framework"
	vdel -all -lib uvvm_vvc_framework
}

if {[file exists work] == 1} {
	echo "Delete library work"
	vdel -all -lib work
}