onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider TopLevel
add wave -noupdate /top/tbd_ofdm_rx/sys_clk_i
add wave -noupdate /top/tbd_ofdm_rx/sys_rstn_i
add wave -noupdate /top/tbd_ofdm_rx/sys_init_i
add wave -noupdate /top/tbd_ofdm_rx/min_level_i
add wave -noupdate /top/tbd_ofdm_rx/rx_data_i_i
add wave -noupdate /top/tbd_ofdm_rx/rx_data_q_i
add wave -noupdate /top/tbd_ofdm_rx/rx_data_valid_i
add wave -noupdate /top/tbd_ofdm_rx/rx_rcv_data_o
add wave -noupdate /top/tbd_ofdm_rx/rx_rcv_data_valid_o
add wave -noupdate /top/tbd_ofdm_rx/rx_rcv_data_start_o
add wave -noupdate /top/tb_tbd_ofdm_rx/rx_data_strobe
add wave -noupdate /top/tb_tbd_ofdm_rx/rx_data_strobe_cnt
add wave -noupdate /top/tb_tbd_ofdm_rx/rx_data_input_idx
add wave -noupdate /top/tb_tbd_ofdm_rx/rx_data_output_idx
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1706457 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
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
WaveRestoreZoom {0 ps} {2195456 ps}
