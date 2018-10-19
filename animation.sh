#!/bin/bash

gmt makecpt -Cbcyr2 -T0.0/1.0/10+ > ThesisFig.cpt
awk -F',' '{if (NR > 1) print $0}' RosyFinch_WGS84.csv > temp4

#REGION1='160/290/30/80g'
#REGION2='-163/23/-82/72r' #Full distribution
REGION2='-116/36.5/-103/45r'   #Utah focused
#PROJ='B-120/45/20/60/6i' #Full distribution
PROJ='B-109/41/34/48/6i' # Utah focused projection

#Inset_region='-163/23/-82/72r'
#Inset_proj='B-120/45/20/60/2.5i'


filename="*grd"

for file in $filename
do
    gmt psbasemap -R$REGION2 -J$PROJ -BwEsN -Bpa20f10 -Bsa0f0 -K > $file\_tmp.ps
    gmt grdimage $file -R -J -CThesisFig.cpt -fg -K -O >> $file\_tmp.ps
    gmt pscoast -R -J -S230/239/255 -W1/thinnest -Di -A0/0/1 -N1 -N2 -O >> $file\_tmp.ps
    #gmt psscale -D3i/-0.35i/5i/0.1ih -CThesisFig.cpt -A -Np -B0.2 -K -O >> $file\_tmp.ps
    #gmt psbasemap -R$Inset_region -J$Inset_proj -BwEsN -Bsa0f0 -P -K -O >> $file\_tmp.ps
    #gmt pscoast -R$Inset_region -J$Inset_proj -S230/239/255 -G255/255/255 -Bwesn -Wthinnest -Di -A0/0/1 -N1 -N2 -L-140/36/50/1000 -T-160/30/1 --FONT=10p -K -O >> $file\_tmp.ps
    #gmt psxy temp4 -R -J -Sc0.02c -Gblue -Wblue -O >> $file\_tmp.ps
    gmt ps2raster -A0.1 -Tg $file\_tmp.ps
done

convert -delay 150 -loop 0 *_tmp.ps RosyFinch_Distribution.pdf     #-loop 0 means repeat infinite times


#convert -delay 200 -loop 0 *_tmp.ps RosyFinch_Distribution.gif      #-loop 0 means repeat infinite times

