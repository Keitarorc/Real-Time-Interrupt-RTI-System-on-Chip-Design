# PMOD JA – Used by PMOD ALS 
set_property PACKAGE_PIN N15  [get_ports {cs_n_0}]   ;# JA0 (CS) 
set_property PACKAGE_PIN L14  [get_ports {mosi_0}]   ;# JA1 (NC) 
set_property PACKAGE_PIN K16  [get_ports {miso_0}]   ;# JA2 (SDO) 
set_property PACKAGE_PIN K14  [get_ports {sclk_0}]   ;# JA3 (SCK) 
set_property IOSTANDARD LVCMOS33 [get_ports {cs_n_0 mosi_0 miso_0 sclk_0}] 