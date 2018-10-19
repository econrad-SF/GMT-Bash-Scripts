#!/bin/bash
# Author: Ed Conrad
# Date: October 23, 2016
# Purpose: This script creates Figure 5 used in Western North American Naturalist Article
####################################################################################
# GRASS GIS commands: ##############################################################
####################################################################################
MODEL='GCM26_70_rForest_Agree'   #'GCM26_70_rForest_Agree';'GCM26_70_BRT_Agree';
#'GCM85_70_BRT_Agree';'GCM85_70_rForest_Agree'

r.stats -1g $MODEL | awk '{if ($3 != "*") print $0}' |cs2cs +proj=aea +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +GRS80 +units=m +to +proj=longlat +ellps=WGS84 -f "%.4f" | awk '{if ($1< 0) print 360+$1, $2, $3; else print $1, $2, $3}' > $MODEL.ll

####################################################################################
# GMT v5.0 Commands: ###############################################################
####################################################################################
gmt gmtset COLOR_NAN 255  #127.5
gmt gmtset FONT_ANNOT_PRIMARY 6p #12p,Helvetica,black
gmt gmtset FONT_ANNOT_SECONDARY=8p #14p,Helvetica,black
gmt gmtset MAP_TICK_LENGTH_PRIMARY=2.5p/1.5p #5p/2.5p

#################
# Set Variables##
#################
REGION='-163/23/-82/72r'  # Use this region AFTER running nearest neighbor algorithm.
PROJ='B-120/45/20/60/2.5i'
FILE='Fig.5b_RF_RCP85_GCMs.ps' #Fig.5a=BRT_RCP26_2070; Fig.5b=RF_RCP26_2070; Fig.5c=BRT_RCP85_2070; Fig.5d=RF_RCP85_2070

#################
# Build Map #####  # -R<west>/<east>/<south>/<north>[r]
#################
#REGION1='160/290/31/80'   #165/258/31/80
gmt nearneighbor $MODEL.ll -G$MODEL.grd -I829e -R$REGION -N4/1 -E0 -fg -S1k -Vl
gmt psbasemap -R$REGION -J$PROJ -BwEsN -Bp20f10 -P -K > $FILE

# AgreeRCP26.cpt or AgreeRCP85.cpt
gmt grdimage $MODEL.grd -R -J -CAgreeRCP26.cpt -nn -K -O >> $FILE
gmt pscoast -R$REGION -J$PROJ -L-130/35/35/500 --FONT=5p -S230/239/255 -Wthinnest -Di -A0/0/1 -N1 -N2 -N3 -K -O >> $FILE

# AgreeRCP26.txt or AgreeRCP85.txt
gmt pslegend AgreeRCP26.txt -R$REGION -J$PROJ -Dx0.15i/.33i/1.2i/1.05i/BL -K -O >> $FILE

gmt pstext -R$REGION -J$PROJ -F+f4p,Helvetica,black -O <<END>> $FILE
-155.3 27 Albers Equal Area Projection
END

gmt ps2raster -A.04i -Tf -E720 $FILE