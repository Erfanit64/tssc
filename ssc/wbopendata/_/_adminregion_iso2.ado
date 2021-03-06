*! _adminregion_iso2 <3 Mar 2019 : 20:52:10>                 by João Pedro Azevedo
*                 auto generated and updated using _update_countrymetadata.ado 
  
 program define _adminregion_iso2 
  
     syntax , match(varname) 
  
*********************
  
         gen adminregion_iso2 = ""  
         replace adminregion_iso2 = "8S"  if `match' == "AFG"  
         replace adminregion_iso2 = "ZF"  if `match' == "AGO"  
         replace adminregion_iso2 = "7E"  if `match' == "ALB"  
         replace adminregion_iso2 = "7E"  if `match' == "ARM"  
         replace adminregion_iso2 = "4E"  if `match' == "ASM"  
         replace adminregion_iso2 = "7E"  if `match' == "AZE"  
         replace adminregion_iso2 = "ZF"  if `match' == "BDI"  
         replace adminregion_iso2 = "ZF"  if `match' == "BEN"  
         replace adminregion_iso2 = "ZF"  if `match' == "BFA"  
         replace adminregion_iso2 = "8S"  if `match' == "BGD"  
         replace adminregion_iso2 = "7E"  if `match' == "BGR"  
         replace adminregion_iso2 = "7E"  if `match' == "BIH"  
         replace adminregion_iso2 = "7E"  if `match' == "BLR"  
         replace adminregion_iso2 = "XJ"  if `match' == "BLZ"  
         replace adminregion_iso2 = "XJ"  if `match' == "BOL"  
         replace adminregion_iso2 = "XJ"  if `match' == "BRA"  
         replace adminregion_iso2 = "8S"  if `match' == "BTN"  
         replace adminregion_iso2 = "ZF"  if `match' == "BWA"  
         replace adminregion_iso2 = "ZF"  if `match' == "CAF"  
         replace adminregion_iso2 = "4E"  if `match' == "CHN"  
         replace adminregion_iso2 = "ZF"  if `match' == "CIV"  
         replace adminregion_iso2 = "ZF"  if `match' == "CMR"  
         replace adminregion_iso2 = "ZF"  if `match' == "COD"  
         replace adminregion_iso2 = "ZF"  if `match' == "COG"  
         replace adminregion_iso2 = "XJ"  if `match' == "COL"  
         replace adminregion_iso2 = "ZF"  if `match' == "COM"  
         replace adminregion_iso2 = "ZF"  if `match' == "CPV"  
         replace adminregion_iso2 = "XJ"  if `match' == "CRI"  
         replace adminregion_iso2 = "XJ"  if `match' == "CUB"  
         replace adminregion_iso2 = "XQ"  if `match' == "DJI"  
         replace adminregion_iso2 = "XJ"  if `match' == "DMA"  
         replace adminregion_iso2 = "XJ"  if `match' == "DOM"  
         replace adminregion_iso2 = "XQ"  if `match' == "DZA"  
         replace adminregion_iso2 = "XJ"  if `match' == "ECU"  
         replace adminregion_iso2 = "XQ"  if `match' == "EGY"  
         replace adminregion_iso2 = "ZF"  if `match' == "ERI"  
         replace adminregion_iso2 = "ZF"  if `match' == "ETH"  
         replace adminregion_iso2 = "4E"  if `match' == "FJI"  
         replace adminregion_iso2 = "4E"  if `match' == "FSM"  
         replace adminregion_iso2 = "ZF"  if `match' == "GAB"  
         replace adminregion_iso2 = "7E"  if `match' == "GEO"  
         replace adminregion_iso2 = "ZF"  if `match' == "GHA"  
         replace adminregion_iso2 = "ZF"  if `match' == "GIN"  
         replace adminregion_iso2 = "ZF"  if `match' == "GMB"  
         replace adminregion_iso2 = "ZF"  if `match' == "GNB"  
         replace adminregion_iso2 = "ZF"  if `match' == "GNQ"  
         replace adminregion_iso2 = "XJ"  if `match' == "GRD"  
         replace adminregion_iso2 = "XJ"  if `match' == "GTM"  
         replace adminregion_iso2 = "XJ"  if `match' == "GUY"  
         replace adminregion_iso2 = "XJ"  if `match' == "HND"  
         replace adminregion_iso2 = "XJ"  if `match' == "HTI"  
         replace adminregion_iso2 = "4E"  if `match' == "IDN"  
         replace adminregion_iso2 = "8S"  if `match' == "IND"  
         replace adminregion_iso2 = "XQ"  if `match' == "IRN"  
         replace adminregion_iso2 = "XQ"  if `match' == "IRQ"  
         replace adminregion_iso2 = "XJ"  if `match' == "JAM"  
         replace adminregion_iso2 = "XQ"  if `match' == "JOR"  
         replace adminregion_iso2 = "7E"  if `match' == "KAZ"  
         replace adminregion_iso2 = "ZF"  if `match' == "KEN"  
         replace adminregion_iso2 = "7E"  if `match' == "KGZ"  
         replace adminregion_iso2 = "4E"  if `match' == "KHM"  
         replace adminregion_iso2 = "4E"  if `match' == "KIR"  
         replace adminregion_iso2 = "4E"  if `match' == "LAO"  
         replace adminregion_iso2 = "XQ"  if `match' == "LBN"  
         replace adminregion_iso2 = "ZF"  if `match' == "LBR"  
         replace adminregion_iso2 = "XQ"  if `match' == "LBY"  
         replace adminregion_iso2 = "XJ"  if `match' == "LCA"  
         replace adminregion_iso2 = "8S"  if `match' == "LKA"  
         replace adminregion_iso2 = "ZF"  if `match' == "LSO"  
         replace adminregion_iso2 = "XQ"  if `match' == "MAR"  
         replace adminregion_iso2 = "7E"  if `match' == "MDA"  
         replace adminregion_iso2 = "ZF"  if `match' == "MDG"  
         replace adminregion_iso2 = "8S"  if `match' == "MDV"  
         replace adminregion_iso2 = "XJ"  if `match' == "MEX"  
         replace adminregion_iso2 = "4E"  if `match' == "MHL"  
         replace adminregion_iso2 = "7E"  if `match' == "MKD"  
         replace adminregion_iso2 = "ZF"  if `match' == "MLI"  
         replace adminregion_iso2 = "4E"  if `match' == "MMR"  
         replace adminregion_iso2 = "7E"  if `match' == "MNE"  
         replace adminregion_iso2 = "4E"  if `match' == "MNG"  
         replace adminregion_iso2 = "ZF"  if `match' == "MOZ"  
         replace adminregion_iso2 = "ZF"  if `match' == "MRT"  
         replace adminregion_iso2 = "ZF"  if `match' == "MUS"  
         replace adminregion_iso2 = "ZF"  if `match' == "MWI"  
         replace adminregion_iso2 = "4E"  if `match' == "MYS"  
         replace adminregion_iso2 = "ZF"  if `match' == "NAM"  
         replace adminregion_iso2 = "ZF"  if `match' == "NER"  
         replace adminregion_iso2 = "ZF"  if `match' == "NGA"  
         replace adminregion_iso2 = "XJ"  if `match' == "NIC"  
         replace adminregion_iso2 = "8S"  if `match' == "NPL"  
         replace adminregion_iso2 = "4E"  if `match' == "NRU"  
         replace adminregion_iso2 = "8S"  if `match' == "PAK"  
         replace adminregion_iso2 = "XJ"  if `match' == "PER"  
         replace adminregion_iso2 = "4E"  if `match' == "PHL"  
         replace adminregion_iso2 = "4E"  if `match' == "PNG"  
         replace adminregion_iso2 = "4E"  if `match' == "PRK"  
         replace adminregion_iso2 = "XJ"  if `match' == "PRY"  
         replace adminregion_iso2 = "XQ"  if `match' == "PSE"  
         replace adminregion_iso2 = "7E"  if `match' == "ROU"  
         replace adminregion_iso2 = "7E"  if `match' == "RUS"  
         replace adminregion_iso2 = "ZF"  if `match' == "RWA"  
         replace adminregion_iso2 = "ZF"  if `match' == "SDN"  
         replace adminregion_iso2 = "ZF"  if `match' == "SEN"  
         replace adminregion_iso2 = "4E"  if `match' == "SLB"  
         replace adminregion_iso2 = "ZF"  if `match' == "SLE"  
         replace adminregion_iso2 = "XJ"  if `match' == "SLV"  
         replace adminregion_iso2 = "ZF"  if `match' == "SOM"  
         replace adminregion_iso2 = "7E"  if `match' == "SRB"  
         replace adminregion_iso2 = "ZF"  if `match' == "SSD"  
         replace adminregion_iso2 = "ZF"  if `match' == "STP"  
         replace adminregion_iso2 = "XJ"  if `match' == "SUR"  
         replace adminregion_iso2 = "ZF"  if `match' == "SWZ"  
         replace adminregion_iso2 = "XQ"  if `match' == "SYR"  
         replace adminregion_iso2 = "ZF"  if `match' == "TCD"  
         replace adminregion_iso2 = "ZF"  if `match' == "TGO"  
         replace adminregion_iso2 = "4E"  if `match' == "THA"  
         replace adminregion_iso2 = "7E"  if `match' == "TJK"  
         replace adminregion_iso2 = "7E"  if `match' == "TKM"  
         replace adminregion_iso2 = "4E"  if `match' == "TLS"  
         replace adminregion_iso2 = "4E"  if `match' == "TON"  
         replace adminregion_iso2 = "XQ"  if `match' == "TUN"  
         replace adminregion_iso2 = "7E"  if `match' == "TUR"  
         replace adminregion_iso2 = "4E"  if `match' == "TUV"  
         replace adminregion_iso2 = "ZF"  if `match' == "TZA"  
         replace adminregion_iso2 = "ZF"  if `match' == "UGA"  
         replace adminregion_iso2 = "7E"  if `match' == "UKR"  
         replace adminregion_iso2 = "7E"  if `match' == "UZB"  
         replace adminregion_iso2 = "XJ"  if `match' == "VCT"  
         replace adminregion_iso2 = "XJ"  if `match' == "VEN"  
         replace adminregion_iso2 = "4E"  if `match' == "VNM"  
         replace adminregion_iso2 = "4E"  if `match' == "VUT"  
         replace adminregion_iso2 = "4E"  if `match' == "WSM"  
         replace adminregion_iso2 = "7E"  if `match' == "XKX"  
         replace adminregion_iso2 = "XQ"  if `match' == "YEM"  
         replace adminregion_iso2 = "ZF"  if `match' == "ZAF"  
         replace adminregion_iso2 = "ZF"  if `match' == "ZMB"  
         replace adminregion_iso2 = "ZF"  if `match' == "ZWE"  
  
*********************
  
 lab var adminregion_iso2        "Administrative Region Code (ISO 2 digits)" 
  
*********************
  
 end 
