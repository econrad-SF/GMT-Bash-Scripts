#!/bin/bash
# Author: Ed Conrad
# Date: October 23, 2016
# Purpose: This script creates Figure 1 used in Western North American Naturalist Article.



# GRASS GIS commands:
#r.out.gdal input=elevation_fix format=GTiff type=Float32 nodata=-9999 output=Elevation2.tif  #Unnecessary here, just a code reminder.

#script must be run with GRASS GIS open in correct map location. In terminal, change the directory to the one holding figure1.sh script. This command writes data to a table to be used as input for the 'gmt nearneighbor' command. (print one cell range/line, printing grid coordinates (E & W); pipe output - if third column doesn't contain *, print the whole#line.; pipe output reproject the file from projected to latlong; pipe output, if the longitude is negative, add 360, else print the whole line as is; redirect output to the *.ll file.)
#MODEL='elevation_fix'
#r.stats -1g $MODEL | awk '{if ($3 != "*") print $0}' |cs2cs +proj=aea +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +GRS80 +units=m +to +proj=longlat +ellps=WGS84 -f "%.4f" | awk '{if ($1< 0) print 360+$1, $2, $3; else print $1, $2, $3}' > $MODEL.ll


# GMT v5.0 Commands:
# View Defaults 'gmtdefaults'  # Original Default values below after comment
gmt gmtset COLOR_NAN 155  #127.5
gmt gmtset FONT_ANNOT_PRIMARY 6p #12p,Helvetica,black
gmt gmtset FONT_ANNOT_SECONDARY=8p #14p,Helvetica,black
gmt gmtset MAP_TICK_LENGTH_PRIMARY=2.5p/1.5p #5p/2.5p
gmt gmtset MAP_ANNOT_MIN_ANGLE 0 #20
gmt gmtset MAP_ANNOT_OBLIQUE 0 #1
gmt gmtset MAP_ANNOT_OFFSET_PRIMARY	= 3p # 5p


#gmt gmtset MAP_TICK_LENGTH_SECONDARY=10p/3.75p #15p/3.75p

# Set Variables
#REGION1='0/360/15/90r'  # Use this region BEFORE running nearest neighbor algorithm.
PROJ='B-120/45/20/60/2.5i'
FILE='Fig.1_Rosy-FinchPointsStudyArea.ps'


# Takes coordinates from table (.ll file) and creates a grid (-G) using "Nearest neighbor" algorithm.
# -I829e = 829meter resolution, -fg = geographical units -N4/1 = quadrant search with at least one sector to be filled
# -S2k = only consider points within 2km of cell.
#gmt nearneighbor $MODEL.ll -G$MODEL.grd -R$REGION1 -I829e -N4/1 -S2k

REGION='-163/23/-82/72r'  # Use this region AFTER running nearest neighbor algorithm.


# Generate color palette table '-N' prevents palette from writing background, foreground, and NaN color. '-Z' creates a continuous color palette.
#gmt makecpt -Crelief -N -Z > relief_ed.cpt              # Used for Fig1
#gmt makecpt -Ctopo -N -Z > topo_ed.cpt                  # cpt output files need to named differently from input!
#gmt grd2cpt elevation_fix.grd -Cdem1 -M > dem1_ed.cpt   # Don't like
#gmt grd2cpt elevation_fix.grd -Cdem2 -M > dem2_ed.cpt   # Hard to see Rosy-Finch points
#gmt grd2cpt elevation_fix.grd -Cdem3 -M > dem3_ed.cpt   # Hard to see Rosy-Finch points


# Create Illumination file (hillshade)
#gmt grdgradient elevation_fix.grd -GHillshade.grad -Rg -A0 -Nt -fg


# Create the Basemap defining region, projection,portrait layout ('-P') and allow more code
# to be appended later ('-K); -B = basemap info, '-Bp' selects primary annotation. '-Bs' secondary annotation
# '-Baf = the 'a' indicates annotation and major tick level, the 'f' indicates minor tick level
gmt psbasemap -R$REGION -J$PROJ -BwEsN -Bp20f10 -P -K > $FILE  # -Bsa0f0
gmt grdimage elevation_fix.grd -R -J -Crelief_ed.cpt -IHillshade.grad -t5 -K -O >> $FILE  #'-t' sets transparency

## Draw National boundaries (-N1), state/province boundaries (-N2), shorelines (-W), North arrow
## (-T-162/25/1), Map scale (-L-154/28/50/1000), land color (-G255/255/255), water color (-Sx/x/x), data resolution (-D). --FONT=11p (this is the font for scale bar)
gmt pscoast -R$REGION -J$PROJ -L-130/35/35/500 --FONT=5p -S230/239/255 -Wthinnest -Di -A0/0/1 -N1 -N2 -N3 -K -O >> $FILE

# This code would add a scale bar below the figure showing elevation values.
#gmt psscale -D.2i/-0.2i/1i/0.1ih -Ccolors.cpt -A -E+n -K -O >> $FILE     # -Np   makes discrete color changes.  -E+n plot triangles on either side of scale bar.

#awk -F',' '{if (NR > 1) print $0}' GCRFwgs84.csv > temp1   # Already created in Fig1 folder.
#awk -F',' '{if (NR > 1) print $0}' BLRFwgs84.csv > temp2
#awk -F',' '{if (NR > 1) print $0}' BCRFwgs84.csv > temp3
gmt psxy temp1 -R -J -Sd0.05c -G153/0/0  -K -O >> $FILE      #-Wthinnest
gmt psxy temp2 -R -J -Sc0.05c -Gblue  -K -O >> $FILE        #-Wthinnest
gmt psxy temp3 -R -J -St0.05c -G255/102/0 -K -O >> $FILE   #-Wthinnest

# Add text - Albers Equal-area projection to lower left corner of map via standard input method (<<END>> followed by another END. ( ) = long/lat
gmt pstext -R$REGION -J$PROJ -F+f4p,Helvetica,black -K -O <<END>> $FILE
-155.3 27 Albers Equal Area Projection
END

## Add legend by reading text file.  Position (-Dx0.1i/0.8i/3.5i/0.8i/BL)
gmt pslegend rosyfinch.txt -R$REGION -J$PROJ -Dx-0.05i/.7i/.15i/0.2i/BL -O >> $FILE #/BL #-F+gwhite = draw rectangular border and have white background.
## Save File to PDF with '-Tf' flag. Set raster resolution in dpi with -E flag. (720 dpi default for pdf).
# -A0.4i have a space of 0.04 inches around edge of image.
gmt ps2raster -A.04i -Tf -E720 $FILE


##-F',' = field separator is comma; NR=ordinal number of current record; $1 and $2 equal the first and 2nd fields respectively.

# Reminders:
# To change permissions to a script type, 'chmod u+x figure1.sh'
# To save changes to a script, type ':wq'
# To run script from terminal, type './figure1.sh
