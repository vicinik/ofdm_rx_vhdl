onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tbinterpolation/sys_clk
add wave -noupdate /tbinterpolation/DUV/rx_data_valid_i
add wave -noupdate -radix decimal /tbinterpolation/DUV/rx_data_i_i
add wave -noupdate /tbinterpolation/DUV/rx_data_q_i
add wave -noupdate /tbinterpolation/DUV/rx_data_i_osr_o
add wave -noupdate -radix decimal /tbinterpolation/DUV/rx_data_q_osr_o
add wave -noupdate /tbinterpolation/DUV/rx_data_i_i
add wave -noupdate /tbinterpolation/DUV/rx_data_q_i
add wave -noupdate -expand -subitemconfig {/tbinterpolation/DUV/Reg.Derives {-height 15 -childformat {{/tbinterpolation/DUV/Reg.Derives.Q -radix decimal} {/tbinterpolation/DUV/Reg.Derives.Q_i -radix decimal} {/tbinterpolation/DUV/Reg.Derives.Q_ii -radix decimal}} -expand} /tbinterpolation/DUV/Reg.Derives.Q {-height 15 -radix decimal} /tbinterpolation/DUV/Reg.Derives.Q_i {-height 15 -radix decimal} /tbinterpolation/DUV/Reg.Derives.Q_ii {-height 15 -radix decimal} /tbinterpolation/DUV/Reg.Data -expand} /tbinterpolation/DUV/Reg
add wave -noupdate /tbinterpolation/DUV/NxrReg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1959669 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 270
configure wave -valuecolwidth 174
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {1749407 ps} {2012165 ps}
