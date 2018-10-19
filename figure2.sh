#!/bin/bash
# Author: Ed Conrad
# Date: October 23, 2016
# Purpose: This script creates Figure 2a-d used in Western North American Naturalist Article
######################################################################################################################
# GRASS GIS commands: ################################################################################################
######################################################################################################################
#Unnecessary here, just a code reminder.
#r.out.gdal input=elevation_fix format=GTiff type=Float32 nodata=-9999 output=Elevation2.tif

# This command must be run with GRASS GIS open in correct map location. In terminal, change the directory to the one holding figure1.sh script. This command writes data to a table to be used as input for the 'gmt nearneighbor' command. (print one cell range/line, printing grid coordinates (E & W); pipe output - if third column doesn't contain *, print the whole#line.; pipe output reproject the file from projected to latlong; pipe output, if the longitude is negative, add 360, else print the whole line as is; redirect output to the *.ll file.)
MOD=MaxEnt_current # BRT_current, GAM_current, MaxEnt_current, RF_current
MODEL='MaxEnt_mod' # BRT_mod, GAM_mod, MaxEnt_mod, RF_mod  # Specify the input raster in GRASS
r.mapcalc "$MODEL=if($MOD<=0.06,null(),$MOD)"  # Set values less than 0.06 to null (will be helpful for map display).

r.stats -1g $MODEL | awk '{if ($3 != "*") print $0}' |cs2cs +proj=aea +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +GRS80 +units=m +to +proj=longlat +ellps=WGS84 -f "%.4f" | awk '{if ($1< 0) print 360+$1, $2, $3; else print $1, $2, $3}' > $MODEL.ll

#######################################################################################################################
# GMT v5.0 Commands: ##################################################################################################
#######################################################################################################################
# View Defaults 'gmtdefaults'  # Original Default values below after comment
gmt gmtset COLOR_NAN 255  #127.5
gmt gmtset FONT_ANNOT_PRIMARY 6p #12p,Helvetica,black
gmt gmtset FONT_ANNOT_SECONDARY=8p #14p,Helvetica,black
gmt gmtset MAP_TICK_LENGTH_PRIMARY=2.5p/1.5p #5p/2.5p
#gmt gmtset MAP_ANNOT_MIN_ANGLE 20 #20
#gmt gmtset MAP_ANNOT_OBLIQUE 1 #1
#gmt gmtset MAP_ANNOT_OFFSET_PRIMARY	= 3p # 5p
#gmt gmtset MAP_TICK_LENGTH_SECONDARY=10p/3.75p #15p/3.75p


# Grid table (.ll file) using "Nearest neighbor" algorithm. -I829e = 829meter resolution, -fg = geographical units
# -N4/1 = quadrant search with at least one sector to be filled # -S2k = only consider points within 2km of cell.
# -Rg is a shortcut for setting region to -R0/360/-90/90 and -Rd sets it to -R-180/180/-90/90
#REGION1fif='160/290/30/80g'
gmt nearneighbor $MODEL.ll -G$MODEL.grd -I1k -Rg -N4 -S2k   #-I829e -N4/3 -Rg -S2k -fg

# Found out info about the netCDF file created
# gmt grdinfo $MODEL.grd


#################
# Set Variables##
#################
REGION='-163/23/-82/72r'  # Use this region AFTER running nearest neighbor algorithm.
PROJ='B-120/45/20/60/2.5i'
#Inset_region='-163/23/-82/72r'
#Inset_proj='B-120/45/20/60/1.2i'
FILE='Fig.2d_Current_MaxEnt.ps'

#####################
# Hillshade Commands#
#####################
#MODEL='elevation_fix'

## Create Illumination grid (-GHillshade.grad), with two aziumuth 0 degrees (-A0), and normalized to one (-Nt), -fg converts
## geographic coordinates to meters using a "Flat Earth" approximation
#gmt grdgradient elevation_fix.grd -GHillshade.grad -Rg -A0 -Nt -fg
#gmt grdgradient elevation_fix.grd -GHillshade2.grad -A345 -Ne0.6

## Ensure that the shaded relief map is reasonably balanced by normalizing it again along a Gaussian distribution
#gmt grdhisteq Hillshade2.grad -GHillshade-hist.nc -N -V

## Check to see that values are between -1 and 1. Divide by a value just larger than the range of values in the histogram
## equalized grid file. Find range by running 'gmt grdinfo' command.
#gmt grdinfo Hillshade-hist.nc  # running this command shows that z_min and z_max are -5.37 and 5.37
#gmt grdmath Hillshade-hist.nc 6 DIV = Hillshade-int.nc  # Running gmt grdinfo again shows that the values are now btw -1 & 1.


#####################
#Build Color Palette#
#####################
#gmt makecpt -Cbcyr -N -Z > probability.cpt
# '-D'sets back- and foreground color to match top/bottom cpt limits; '-G0.06/1' truncates cpt file z-values to 0.06 thru 1; '-N' prevents writing back-, foreground, and NaN z-values; '-L' limits the range of the data (values outside set to NaN).
#gmt grd2cpt elevation_fix.grd -D -Cgrayscale02 > gray_ed.cpt
#gmt grd2cpt $MODEL.grd -Cbcyr -G0.06/1 -L0.06/1 -V > probability.cpt


# Make linear/histogram-equalized color palette from grid. (-N) prevents writing back-,fore-, and NA value colors. Use GMT defaults instead (-M)
#gmt grd2cpt elevation_fix.grd -Cdem1 -M > dem1_ed.cpt     #Don't like
#gmt grd2cpt elevation_fix.grd -Cdem2 -M > dem2_ed.cpt     #Don't like
#gmt grd2cpt elevation_fix.grd -Cdem3 -M > dem3_ed.cpt     #Good - but not gray hillshade.
#gmt grd2cpt elevation_fix.grd -Cdem4 -M > dem4_ed.cpt     #Don't like

#################
# Build Map #####
#################

# Create the Basemap defining region, projection,portrait layout ('-P') and allow more code to be appended later ('-K);
# -B = basemap info, '-Bp' selects primary annotation. '-Bs' secondary annotation,'-Baf = the 'a' indicates annotation and
# major tick level, the 'f' indicates minor tick level
gmt psbasemap -R$REGION -J$PROJ -BwEsN -Bp20f10 -P -K > $FILE  # -Bsa0f0

# Project the grid and put it on the map. # '-I' = illuminate with the following file. '-t' sets transparency '-Q' NaN z nodes transparent.
#gmt grdimage elevation_fix.grd -R -J -Crelief_ed.cpt -IHillshade.grad -K -O >> $FILE  #
#gmt grdimage elevation_fix.grd -R -J -Cgray_ed.cpt -fg -Q -K -O >> $FILE  #-IHillshade.grad
gmt grdimage $MODEL.grd -R -J -Cprobability.cpt -fg -K -O >> $FILE  #

# Draw National boundaries (-N1), state/province boundaries (-N2), shorelines (-W), North arrow (-T-162/25/1),
# Map scale (-L-154/28/50/1000), land color (-G255/255/255), water color (-Sx/x/x), data resolution (-D). --FONT=11p (this is the font for scale bar); '-A' Place the desired annotations/labels on the other side of the colorscale instead.
gmt pscoast -R$REGION -J$PROJ -L-130/34.6/35/500 --FONT=5p -S230/239/255 -Wthinnest -Di -A0/0/1 -N1 -N2 -N3 -K -O >> $FILE
gmt psscale -D1.25i/-0.2i/2.5i/0.1ih -Cprobability.cpt -A -B0.1 -K -O >> $FILE  # -D.....h forces scale to be horizontal rather vs vert

# Inset Map -L-140/36/50/1000 -T-160/30/1 --FONT=10p
#gmt psbasemap -R$Inset_region -J$Inset_proj -BwEsN -Bsa0f0 -P -K -O >> $FILE
#gmt pscoast -R$Inset_region -J$Inset_proj -S230/239/255 -G255/255/255 -Bwesn -Wthinnest -Dl -A0/0/1 -N1 -N2 -K -O  >> $FILE #-Tf-160/45/1/3:n:
#awk -F',' '{if (NR > 1) print $0}' RosyFinch_WGS84.csv > temp4
#gmt psxy temp4 -R -J -Sc0.015c -Gblue -Wblue -K -O >> $FILE


# Add text - Albers Equal Area projection to lower left corner of map via standard input method (<<END>> followed by another END. ( ) = long/lat
#gmt pstext -R$REGION -J$PROJ -F+f4p,Helvetica,black -K -O <<END>> $FILE
#-158.5 31 Points used to train model
#END

gmt pstext -R$REGION -J$PROJ -F+f4p,Helvetica,black -O <<END>> $FILE
-155.3 27 Albers Equal Area Projection
END

## Save File to PDF with '-Tf' flag. Set raster resolution in dpi with -E flag. (720 dpi default for pdf).
# -A0.4i have a space of 0.04 inches around edge of image.
gmt ps2raster -A.04i -Tf -E720 $FILE

############################################################################
############################################################################
############################################################################
# Reminders:
# To change permissions to a script type, 'chmod u+x figure1.sh'
# To save changes to a script, type ':wq'
# To run script from terminal, type './figure1.sh
# Note that when adding to a postscript file, the inital command using a single '>' $FILE. Subsequent commands use
# two '>>' $FILE.
# ctrl + z stops a script from running in the terminal
#-F',' = field separator is comma; NR=ordinal number of current record; $1 and $2 equal the first and 2nd fields respectively.