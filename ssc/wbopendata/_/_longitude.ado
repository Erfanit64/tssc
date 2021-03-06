*! _longitude <3 Mar 2019 : 20:52:10>                 by João Pedro Azevedo
*                 auto generated and updated using _update_countrymetadata.ado 
  
 program define _longitude 
  
     syntax , match(varname) 
  
  
  
         gen  double longitude = .  
         replace longitude = real("-70.0167")    if `match' == "ABW"  
         replace longitude = real("69.1761")    if `match' == "AFG"  
         replace longitude = real("13.242")    if `match' == "AGO"  
         replace longitude = real("19.8172")    if `match' == "ALB"  
         replace longitude = real("1.5218")    if `match' == "AND"  
         replace longitude = real("54.3705")    if `match' == "ARE"  
         replace longitude = real("-58.4173")    if `match' == "ARG"  
         replace longitude = real("44.509")    if `match' == "ARM"  
         replace longitude = real("-170.691")    if `match' == "ASM"  
         replace longitude = real("-61.8456")    if `match' == "ATG"  
         replace longitude = real("149.129")    if `match' == "AUS"  
         replace longitude = real("16.3798")    if `match' == "AUT"  
         replace longitude = real("49.8932")    if `match' == "AZE"  
         replace longitude = real("29.3639")    if `match' == "BDI"  
         replace longitude = real("4.36761")    if `match' == "BEL"  
         replace longitude = real("2.6323")    if `match' == "BEN"  
         replace longitude = real("-1.53395")    if `match' == "BFA"  
         replace longitude = real("90.4113")    if `match' == "BGD"  
         replace longitude = real("23.3238")    if `match' == "BGR"  
         replace longitude = real("50.5354")    if `match' == "BHR"  
         replace longitude = real("-77.339")    if `match' == "BHS"  
         replace longitude = real("18.4214")    if `match' == "BIH"  
         replace longitude = real("27.5766")    if `match' == "BLR"  
         replace longitude = real("-88.7713")    if `match' == "BLZ"  
         replace longitude = real("-64.706")    if `match' == "BMU"  
         replace longitude = real("-66.1936")    if `match' == "BOL"  
         replace longitude = real("-47.9292")    if `match' == "BRA"  
         replace longitude = real("-59.6105")    if `match' == "BRB"  
         replace longitude = real("114.946")    if `match' == "BRN"  
         replace longitude = real("89.6177")    if `match' == "BTN"  
         replace longitude = real("25.9201")    if `match' == "BWA"  
         replace longitude = real("21.6407")    if `match' == "CAF"  
         replace longitude = real("-75.6919")    if `match' == "CAN"  
         replace longitude = real("7.44821")    if `match' == "CHE"  
         replace longitude = real(".")    if `match' == "CHI"  
         replace longitude = real("-70.6475")    if `match' == "CHL"  
         replace longitude = real("116.286")    if `match' == "CHN"  
         replace longitude = real("-4.0305")    if `match' == "CIV"  
         replace longitude = real("11.5174")    if `match' == "CMR"  
         replace longitude = real("15.3222")    if `match' == "COD"  
         replace longitude = real("15.2662")    if `match' == "COG"  
         replace longitude = real("-74.082")    if `match' == "COL"  
         replace longitude = real("43.2418")    if `match' == "COM"  
         replace longitude = real("-23.5087")    if `match' == "CPV"  
         replace longitude = real("-84.0089")    if `match' == "CRI"  
         replace longitude = real("-82.3667")    if `match' == "CUB"  
         replace longitude = real(".")    if `match' == "CUW"  
         replace longitude = real("-81.3857")    if `match' == "CYM"  
         replace longitude = real("33.3736")    if `match' == "CYP"  
         replace longitude = real("14.4205")    if `match' == "CZE"  
         replace longitude = real("13.4115")    if `match' == "DEU"  
         replace longitude = real("43.1425")    if `match' == "DJI"  
         replace longitude = real("-61.39")    if `match' == "DMA"  
         replace longitude = real("12.5681")    if `match' == "DNK"  
         replace longitude = real("-69.8908")    if `match' == "DOM"  
         replace longitude = real("3.05097")    if `match' == "DZA"  
         replace longitude = real("-78.5243")    if `match' == "ECU"  
         replace longitude = real("31.2461")    if `match' == "EGY"  
         replace longitude = real("38.9183")    if `match' == "ERI"  
         replace longitude = real("-3.70327")    if `match' == "ESP"  
         replace longitude = real("24.7586")    if `match' == "EST"  
         replace longitude = real("38.7468")    if `match' == "ETH"  
         replace longitude = real("24.9525")    if `match' == "FIN"  
         replace longitude = real("178.399")    if `match' == "FJI"  
         replace longitude = real("2.35097")    if `match' == "FRA"  
         replace longitude = real("-6.91181")    if `match' == "FRO"  
         replace longitude = real("158.185")    if `match' == "FSM"  
         replace longitude = real("9.45162")    if `match' == "GAB"  
         replace longitude = real("-0.126236")    if `match' == "GBR"  
         replace longitude = real("44.793")    if `match' == "GEO"  
         replace longitude = real("-0.20795")    if `match' == "GHA"  
         replace longitude = real(".")    if `match' == "GIB"  
         replace longitude = real("-13.7")    if `match' == "GIN"  
         replace longitude = real("-16.5885")    if `match' == "GMB"  
         replace longitude = real("-15.1804")    if `match' == "GNB"  
         replace longitude = real("8.7741")    if `match' == "GNQ"  
         replace longitude = real("23.7166")    if `match' == "GRC"  
         replace longitude = real("-61.7449")    if `match' == "GRD"  
         replace longitude = real("-51.7214")    if `match' == "GRL"  
         replace longitude = real("-90.5328")    if `match' == "GTM"  
         replace longitude = real("144.794")    if `match' == "GUM"  
         replace longitude = real("-58.1548")    if `match' == "GUY"  
         replace longitude = real("114.109")    if `match' == "HKG"  
         replace longitude = real("-87.4667")    if `match' == "HND"  
         replace longitude = real("15.9614")    if `match' == "HRV"  
         replace longitude = real("-72.3288")    if `match' == "HTI"  
         replace longitude = real("19.0408")    if `match' == "HUN"  
         replace longitude = real("106.83")    if `match' == "IDN"  
         replace longitude = real("-4.47928")    if `match' == "IMN"  
         replace longitude = real("77.225")    if `match' == "IND"  
         replace longitude = real("-6.26749")    if `match' == "IRL"  
         replace longitude = real("51.4447")    if `match' == "IRN"  
         replace longitude = real("44.394")    if `match' == "IRQ"  
         replace longitude = real("-21.8952")    if `match' == "ISL"  
         replace longitude = real("35.2035")    if `match' == "ISR"  
         replace longitude = real("12.4823")    if `match' == "ITA"  
         replace longitude = real("-76.792")    if `match' == "JAM"  
         replace longitude = real("35.9263")    if `match' == "JOR"  
         replace longitude = real("139.77")    if `match' == "JPN"  
         replace longitude = real("71.4382")    if `match' == "KAZ"  
         replace longitude = real("36.8126")    if `match' == "KEN"  
         replace longitude = real("74.6057")    if `match' == "KGZ"  
         replace longitude = real("104.874")    if `match' == "KHM"  
         replace longitude = real("172.979")    if `match' == "KIR"  
         replace longitude = real("-62.7309")    if `match' == "KNA"  
         replace longitude = real("126.957")    if `match' == "KOR"  
         replace longitude = real("47.9824")    if `match' == "KWT"  
         replace longitude = real("102.177")    if `match' == "LAO"  
         replace longitude = real("35.5134")    if `match' == "LBN"  
         replace longitude = real("-10.7957")    if `match' == "LBR"  
         replace longitude = real("13.1072")    if `match' == "LBY"  
         replace longitude = real("-60.9832")    if `match' == "LCA"  
         replace longitude = real("9.52148")    if `match' == "LIE"  
         replace longitude = real("79.8528")    if `match' == "LKA"  
         replace longitude = real("27.7167")    if `match' == "LSO"  
         replace longitude = real("25.2799")    if `match' == "LTU"  
         replace longitude = real("6.1296")    if `match' == "LUX"  
         replace longitude = real("24.1048")    if `match' == "LVA"  
         replace longitude = real("113.55")    if `match' == "MAC"  
         replace longitude = real(".")    if `match' == "MAF"  
         replace longitude = real("-6.8704")    if `match' == "MAR"  
         replace longitude = real("7.41891")    if `match' == "MCO"  
         replace longitude = real("28.8497")    if `match' == "MDA"  
         replace longitude = real("45.7167")    if `match' == "MDG"  
         replace longitude = real("73.5109")    if `match' == "MDV"  
         replace longitude = real("-99.1276")    if `match' == "MEX"  
         replace longitude = real("171.135")    if `match' == "MHL"  
         replace longitude = real("21.4361")    if `match' == "MKD"  
         replace longitude = real("-7.50034")    if `match' == "MLI"  
         replace longitude = real("14.5189")    if `match' == "MLT"  
         replace longitude = real("95.9562")    if `match' == "MMR"  
         replace longitude = real("19.2595")    if `match' == "MNE"  
         replace longitude = real("106.937")    if `match' == "MNG"  
         replace longitude = real("145.765")    if `match' == "MNP"  
         replace longitude = real("32.5713")    if `match' == "MOZ"  
         replace longitude = real("-15.9824")    if `match' == "MRT"  
         replace longitude = real("57.4977")    if `match' == "MUS"  
         replace longitude = real("33.7703")    if `match' == "MWI"  
         replace longitude = real("101.684")    if `match' == "MYS"  
         replace longitude = real("17.0931")    if `match' == "NAM"  
         replace longitude = real("166.464")    if `match' == "NCL"  
         replace longitude = real("2.1073")    if `match' == "NER"  
         replace longitude = real("7.48906")    if `match' == "NGA"  
         replace longitude = real("-86.2734")    if `match' == "NIC"  
         replace longitude = real("4.89095")    if `match' == "NLD"  
         replace longitude = real("10.7387")    if `match' == "NOR"  
         replace longitude = real("85.3157")    if `match' == "NPL"  
         replace longitude = real("166.920867")    if `match' == "NRU"  
         replace longitude = real("174.776")    if `match' == "NZL"  
         replace longitude = real("58.5874")    if `match' == "OMN"  
         replace longitude = real("72.8")    if `match' == "PAK"  
         replace longitude = real("-79.5188")    if `match' == "PAN"  
         replace longitude = real("-77.0465")    if `match' == "PER"  
         replace longitude = real("121.035")    if `match' == "PHL"  
         replace longitude = real("134.479")    if `match' == "PLW"  
         replace longitude = real("147.194")    if `match' == "PNG"  
         replace longitude = real("21.02")    if `match' == "POL"  
         replace longitude = real("-66")    if `match' == "PRI"  
         replace longitude = real("125.754")    if `match' == "PRK"  
         replace longitude = real("-9.13552")    if `match' == "PRT"  
         replace longitude = real("-57.6362")    if `match' == "PRY"  
         replace longitude = real(".")    if `match' == "PSE"  
         replace longitude = real("-149.57")    if `match' == "PYF"  
         replace longitude = real("51.5082")    if `match' == "QAT"  
         replace longitude = real("26.0979")    if `match' == "ROU"  
         replace longitude = real("37.6176")    if `match' == "RUS"  
         replace longitude = real("30.0587")    if `match' == "RWA"  
         replace longitude = real("46.6977")    if `match' == "SAU"  
         replace longitude = real("32.5363")    if `match' == "SDN"  
         replace longitude = real("-17.4734")    if `match' == "SEN"  
         replace longitude = real("103.85")    if `match' == "SGP"  
         replace longitude = real("159.949")    if `match' == "SLB"  
         replace longitude = real("-13.2134")    if `match' == "SLE"  
         replace longitude = real("-89.2073")    if `match' == "SLV"  
         replace longitude = real("12.4486")    if `match' == "SMR"  
         replace longitude = real("45.3254")    if `match' == "SOM"  
         replace longitude = real("20.4656")    if `match' == "SRB"  
         replace longitude = real("31.6")    if `match' == "SSD"  
         replace longitude = real("6.6071")    if `match' == "STP"  
         replace longitude = real("-55.1679")    if `match' == "SUR"  
         replace longitude = real("17.1073")    if `match' == "SVK"  
         replace longitude = real("14.5044")    if `match' == "SVN"  
         replace longitude = real("18.0645")    if `match' == "SWE"  
         replace longitude = real("31.4659")    if `match' == "SWZ"  
         replace longitude = real(".")    if `match' == "SXM"  
         replace longitude = real("55.4466")    if `match' == "SYC"  
         replace longitude = real("36.3119")    if `match' == "SYR"  
         replace longitude = real("-71.141389")    if `match' == "TCA"  
         replace longitude = real("15.0445")    if `match' == "TCD"  
         replace longitude = real("1.2255")    if `match' == "TGO"  
         replace longitude = real("100.521")    if `match' == "THA"  
         replace longitude = real("68.7864")    if `match' == "TJK"  
         replace longitude = real("58.3794")    if `match' == "TKM"  
         replace longitude = real("125.567")    if `match' == "TLS"  
         replace longitude = real("-175.216")    if `match' == "TON"  
         replace longitude = real("-61.4789")    if `match' == "TTO"  
         replace longitude = real("10.21")    if `match' == "TUN"  
         replace longitude = real("32.3606")    if `match' == "TUR"  
         replace longitude = real("179.089567")    if `match' == "TUV"  
         replace longitude = real(".")    if `match' == "TWN"  
         replace longitude = real("35.7382")    if `match' == "TZA"  
         replace longitude = real("32.5729")    if `match' == "UGA"  
         replace longitude = real("30.5038")    if `match' == "UKR"  
         replace longitude = real("-56.0675")    if `match' == "URY"  
         replace longitude = real("-77.032")    if `match' == "USA"  
         replace longitude = real("69.269")    if `match' == "UZB"  
         replace longitude = real("-61.2653")    if `match' == "VCT"  
         replace longitude = real("-69.8371")    if `match' == "VEN"  
         replace longitude = real("-64.623056")    if `match' == "VGB"  
         replace longitude = real("-64.8963")    if `match' == "VIR"  
         replace longitude = real("105.825")    if `match' == "VNM"  
         replace longitude = real("168.321")    if `match' == "VUT"  
         replace longitude = real("-171.752")    if `match' == "WSM"  
         replace longitude = real("20.926")    if `match' == "XKX"  
         replace longitude = real("44.2075")    if `match' == "YEM"  
         replace longitude = real("28.1871")    if `match' == "ZAF"  
         replace longitude = real("28.2937")    if `match' == "ZMB"  
         replace longitude = real("31.0672")    if `match' == "ZWE"  
  
*********************
  
 lab var longitude               "Capital Longitude" 
  
*********************
  
 end 
