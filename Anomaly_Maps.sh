#!/bin/bash

MODEL='Anomaly_RCP85_bio1'

# GRASS GIS commands; must open GRASS GIS and run this script in the folder with these files (e.g. GCRFwgs84.csv).
#r.stats -1g $MODEL | awk '{if ($3 != "*") print $0}' |cs2cs +proj=aea +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +GRS80 +units=m +to +proj=longlat +ellps=WGS84 -f "%.4f" | awk '{if ($1< 0) print 360+$1, $2, $3; else print $1, $2, $3}' > $MODEL.ll

REGION='160/290/30/80g'
gmt nearneighbor $MODEL.ll -G$MODEL.grd -I828.29e -fg -R$REGION -N1 -S5k -V

# MAKE MAP
REGION='-163/23/-82/72r'
PROJ='B-120/45/20/60/6i'
FILE='Anomaly_RCP85.ps'  # Anomal_RoysyFinch26.ps

gmt makecpt -I -F -Chot -T-.5/10.05/0.25 > anomaly.cpt   # -T// RCP2.6: -0.3843975 -- 4.911701; RCP8.5: 1.91 -- 10.0317; -F force cpt to write out RGB codes; -Z continous colors rather than discontinuous
#gmt grd2cpt $MODEL.grd -Cbcyr2 > anomaly.cpt

gmt psbasemap -R$REGION -J$PROJ -BwEsN -Bpa20f10 -Bsa0f0 -P -K > $FILE
gmt grdimage $MODEL.grd -R -J -Canomaly.cpt -fg -K -O >> $FILE
gmt pscoast -R -J -S230/239/255 -W1/thinnest -Di -A0/0/1 -N1 -N2 -L-150/31/50/1000 -T-160/28/1 --FONT=10p -K -O >> $FILE
gmt psscale -D3i/-0.35i/5i/0.1ih -Canomaly.cpt -A -E+n -B2 -O >> $FILE     # -Np   makes discrete color changes.
#awk -F',' '{if (NR > 1) print $0}' GCRFwgs84.csv > temp1
#awk -F',' '{if (NR > 1) print $0}' BLRFwgs84.csv > temp2
#awk -F',' '{if (NR > 1) print $0}' BCRFwgs84.csv > temp3
#gmt psxy temp1 -R -J -Sd0.06c -Gblack -Wthinnest -K -O >> $FILE
#gmt psxy temp2 -R -J -Sc0.07c -Gblue -Wblue -K -O >> $FILE
#gmt psxy temp3 -R -J -St0.05c -Gorange -Worange -K -O >> $FILE
#gmt pslegend rosyfinch.txt -Dx0.1i/0.8i/3.5i/0.8i/BL -F+gwhite -O >> $FILE
gmt ps2raster -A0.1 -Tf $FILE





#Inset_region='-163/23/-82/72r'                       #'-124/35/-100/48r'
#Inset_proj='B-120/45/20/60/2.5i'                         #'B-120/45/20/60/2.5i'


#gmt psbasemap -R$Inset_region -J$Inset_proj -BwEsN -Bsa0f0 -P -K -O >> $FILE
#gmt pscoast -R$Inset_region -J$Inset_proj -S230/239/255 -G255/255/255 -Bwesn -Wthinnest -Di -A0/0/1 -N1 -N2 -L-140/36/50/1000 -T-160/30/1 --FONT=10p -K -O >> $FILE
