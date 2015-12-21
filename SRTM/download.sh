#!/bin/bash

export SCIDB4GDAL_HOST=https://localhost
export SCIDB4GDAL_PORT=8083
export SCIDB4GDAL_USER=scidb
export SCIDB4GDAL_PASSWD=xxxxxxxxx

cd ~/SRTM

wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S01E032.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S02E032.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S03E032.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S04E032.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S05E032.hgt.zip


wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S01E033.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S02E033.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S03E033.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S04E033.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S05E033.hgt.zip


wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S01E034.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S02E034.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S03E034.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S04E034.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S05E034.hgt.zip

wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S01E035.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S02E035.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S03E035.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S04E035.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S05E035.hgt.zip

wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S01E036.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S02E036.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S03E036.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S04E036.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S05E036.hgt.zip

wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S01E037.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S02E037.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S03E037.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S04E037.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S05E037.hgt.zip

wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S01E038.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S02E038.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S03E038.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S04E038.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S05E038.hgt.zip

wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S01E039.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S02E039.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S03E039.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S04E039.hgt.zip
wget https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/Africa/S05E039.hgt.zip

unzip \*.hgt.zip
rm *.hgt.zip

gdal_merge.py -o srtm.tif *.hgt

gdal_translate -of SciDB srtm.tif "SCIDB:array=srtm host=${SCIDB4GDAL_HOST} port=${SCIDB4GDAL_PORT} user=${SCIDB4GDAL_USER} password=${SCIDB4GDAL_PASSWD}"

