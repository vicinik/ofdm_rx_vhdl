onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tbfft/sys_clk_i
add wave -noupdate /tbfft/sys_rstn_i
add wave -noupdate -format Analog-Step -height 74 -max 254.0 -radix unsigned /tbfft/rx_data_q_fft_i
add wave -noupdate /tbfft/rx_data_i_fft_i
add wave -noupdate /tbfft/DUV/FFTInstance/sink_imag
add wave -noupdate /tbfft/DUV/FFTInstance/sink_real
add wave -noupdate -divider Register
add wave -noupdate -childformat {{/tbfft/DUV/Reg.SampleCounter -radix unsigned} {/tbfft/DUV/Reg.TransferCounter -radix unsigned}} -subitemconfig {/tbfft/DUV/Reg.SampleCounter {-color yellow -height 15 -itemcolor yellow -radix unsigned} /tbfft/DUV/Reg.TransferCounter {-height 15 -radix unsigned}} /tbfft/DUV/Reg
add wave -noupdate /tbfft/DUV/NxrReg
add wave -noupdate -divider Sink
add wave -noupdate /tbfft/DUV/sink_ready
add wave -noupdate -color Red -itemcolor red /tbfft/DUV/sink_valid
add wave -noupdate -color blue -itemcolor blue /tbfft/DUV/sink_sop
add wave -noupdate -color magenta -itemcolor magenta /tbfft/DUV/sink_eop
add wave -noupdate /tbfft/DUV/sink_error
add wave -noupdate -divider Source
add wave -noupdate /tbfft/DUV/source_error
add wave -noupdate /tbfft/DUV/source_ready
add wave -noupdate -color magenta -itemcolor magenta /tbfft/DUV/source_valid
add wave -noupdate -color gold -itemcolor gold /tbfft/DUV/source_sop
add wave -noupdate /tbfft/DUV/source_eop
add wave -noupdate /tbfft/DUV/source_exp
add wave -noupdate /tbfft/DUV/source_imag
add wave -noupdate /tbfft/DUV/source_real
add wave -noupdate -divider Output
add wave -noupdate -color {Medium Spring Green} -itemcolor {Medium Spring Green} /tbfft/DUV/rx_symbols_i_fft_o
add wave -noupdate -color {Medium Spring Green} -itemcolor {Medium Spring Green} /tbfft/DUV/rx_symbols_q_fft_o
add wave -noupdate /tbfft/DUV/rx_symbols_fft_valid_o
add wave -noupdate /tbfft/DUV/rx_symbols_fft_start_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {76322074 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 225
configure wave -valuecolwidth 145
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1000
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {57108480 ps} {95180800 ps}
