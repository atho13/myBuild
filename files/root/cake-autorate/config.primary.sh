#!/usr/bin/env bash
# shellcheck disable=SC2034
# for FRDMX-Wrt Community

ul_if="TEMPLATE_WAN"
dl_if="lo"

adjust_dl_shaper_rate=1 
adjust_ul_shaper_rate=1 

min_dl_shaper_rate_kbps=3000
min_ul_shaper_rate_kbps=1000

base_dl_shaper_rate_kbps=15000
base_ul_shaper_rate_kbps=5000

max_dl_shaper_rate_kbps=1000000
max_ul_shaper_rate_kbps=300000

connection_active_thr_kbps=10

# Catatan: Pengguna bisa menyelipkan IP Gateway Modem mereka di urutan paling depan
reflectors=(8.8.8.8 1.1.1.1 9.9.9.9 208.67.222.222 1.0.0.1 8.8.4.4)

output_processing_stats=0 
output_load_stats=0       
output_reflector_stats=0  
output_summary_stats=0
output_cpu_stats=0       
output_cpu_raw_stats=0
