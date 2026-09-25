#!/usr/bin/env bash
# shellcheck disable=SC2034
# for FRDMX-Wrt Community

ul_if="TEMPLATE_WAN"
dl_if="lo" 

adjust_dl_shaper_rate=1 
adjust_ul_shaper_rate=1 

min_dl_shaper_rate_kbps=10000
base_dl_shaper_rate_kbps=200000
max_dl_shaper_rate_kbps=400000

min_ul_shaper_rate_kbps=5000
base_ul_shaper_rate_kbps=80000
max_ul_shaper_rate_kbps=150000

connection_active_thr_kbps=3000

reflectors=(8.8.8.8 1.1.1.1 9.9.9.9 208.67.222.222 1.0.0.1 8.8.4.4)

output_processing_stats=0 
output_load_stats=0       
output_reflector_stats=0  
output_summary_stats=0
output_cpu_stats=0       
output_cpu_raw_stats=0
