onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider -height 20 {Clk and Reset}
add wave -noupdate /tbcoarsealignment/sysClk
add wave -noupdate /tbcoarsealignment/reset_n
add wave -noupdate /tbcoarsealignment/init
add wave -noupdate -divider -height 20 {Coarse Alignment I/Os}
add wave -noupdate -radix decimal /tbcoarsealignment/DUV/rx_data_i_osr_i
add wave -noupdate -radix decimal /tbcoarsealignment/DUV/rx_data_q_osr_i
add wave -noupdate /tbcoarsealignment/DUV/rx_data_osr_valid_i
add wave -noupdate /tbcoarsealignment/DUV/offset_inc_i
add wave -noupdate /tbcoarsealignment/DUV/offset_dec_i
add wave -noupdate -radix unsigned /tbcoarsealignment/DUV/min_level_i
add wave -noupdate -radix decimal /tbcoarsealignment/DUV/rx_data_i_coarse_o
add wave -noupdate -radix decimal /tbcoarsealignment/DUV/rx_data_q_coarse_o
add wave -noupdate /tbcoarsealignment/DUV/rx_data_coarse_start_o
add wave -noupdate /tbcoarsealignment/DUV/rx_data_coarse_valid_o
add wave -noupdate -divider -height 20 {Coarse Alignment internals}
add wave -noupdate -childformat {{/tbcoarsealignment/DUV/regCoarse.PrevPValue -radix decimal} {/tbcoarsealignment/DUV/regCoarse.Threshold -radix decimal} {/tbcoarsealignment/DUV/regCoarse.SampleCounter -radix unsigned} {/tbcoarsealignment/DUV/regCoarse.OffsetCounter -radix unsigned} {/tbcoarsealignment/DUV/regCoarse.WriteIdx -radix unsigned} {/tbcoarsealignment/DUV/regCoarse.ReadIdx -radix unsigned}} -expand -subitemconfig {/tbcoarsealignment/DUV/regCoarse.PrevPValue {-radix decimal} /tbcoarsealignment/DUV/regCoarse.Threshold {-height 15 -radix decimal} /tbcoarsealignment/DUV/regCoarse.SampleCounter {-height 15 -radix unsigned} /tbcoarsealignment/DUV/regCoarse.OffsetCounter {-height 15 -radix unsigned} /tbcoarsealignment/DUV/regCoarse.WriteIdx {-radix unsigned} /tbcoarsealignment/DUV/regCoarse.ReadIdx {-radix unsigned}} /tbcoarsealignment/DUV/regCoarse
add wave -noupdate -radix decimal /tbcoarsealignment/DUV/sampleBuffer
add wave -noupdate -radix decimal /tbcoarsealignment/DUV/correlationBuffer
add wave -noupdate -radix decimal /tbcoarsealignment/DUV/regPValue
add wave -noupdate /tbcoarsealignment/DUV/regValid
add wave -noupdate -radix unsigned /tbcoarsealignment/DUV/regWriteIdxSamples
add wave -noupdate -radix unsigned /tbcoarsealignment/DUV/regReadIdxSamples
add wave -noupdate -radix unsigned /tbcoarsealignment/DUV/regWriteIdxCorrelation
add wave -noupdate -radix unsigned /tbcoarsealignment/DUV/regReadIdxCorrelation
add wave -noupdate -radix decimal -childformat {{/tbcoarsealignment/DUV/regPValue.I -radix decimal}} -expand -subitemconfig {/tbcoarsealignment/DUV/regPValue.I {-clampanalog 1 -format Analog-Interpolated -height 200 -max 500000000.0 -min -500000000.0 -radix decimal}} /tbcoarsealignment/DUV/regPValue
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {239683349 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 318
configure wave -valuecolwidth 100
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
WaveRestoreZoom {238978166 ps} {239961230 ps}
