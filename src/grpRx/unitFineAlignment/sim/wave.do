onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tbcoarsealignment/DUV/sys_clk_i
add wave -noupdate /tbcoarsealignment/DUV/sys_rstn_i
add wave -noupdate /tbcoarsealignment/DUV/sys_init_i
add wave -noupdate -radix decimal /tbcoarsealignment/DUV/rx_symbols_i_fft_i
add wave -noupdate -radix decimal /tbcoarsealignment/DUV/rx_symbols_q_fft_i
add wave -noupdate /tbcoarsealignment/DUV/rx_symbols_fft_valid_i
add wave -noupdate /tbcoarsealignment/DUV/rx_symbols_fft_start_i
add wave -noupdate -childformat {{/tbcoarsealignment/DUV/R.SumReal -radix decimal} {/tbcoarsealignment/DUV/R.SumImag -radix decimal} {/tbcoarsealignment/DUV/R.SymbolCounter -radix decimal}} -expand -subitemconfig {/tbcoarsealignment/DUV/R.SumReal {-radix decimal} /tbcoarsealignment/DUV/R.SumImag {-radix decimal} /tbcoarsealignment/DUV/R.SymbolCounter {-radix decimal}} /tbcoarsealignment/DUV/R
add wave -noupdate -radix decimal /tbcoarsealignment/DUV/sPhase
add wave -noupdate /tbcoarsealignment/offset_inc
add wave -noupdate /tbcoarsealignment/offset_dec
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {250000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 263
configure wave -valuecolwidth 144
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
WaveRestoreZoom {0 ps} {576450 ps}
