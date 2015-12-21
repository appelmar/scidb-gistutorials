# SRTM Tutorial
This tutorial demonstrates how to load and analyze small tiled SRTM elevation data in SciDB. 

## Step 1: Download the data
`download.sh` provides a shell script to download a couple of SRTM3 tiles with spatial resolution of 3 arc seconds.

1. Create a directory where to store TRMM data, e.g `mkdir ~/SRTM`
2. Copy the download script to that directory `cp download.sh ~/SRTM/`
3. Start the download with `nohup ~/SRTM/download.sh &`

Once the process has finished, unzip and remove all archive files by running `cd ~/SRTM && unzip \*.hgt.zip
rm *.hgt.zip && rm *.hgt.zip`.

## Step 2: Ingest the data to SciDB
Luckily, GDAL can read SRTM files in HGT format. In this example we merge tiles first using `gdal_merge` to simplify the loading procedure. However, latest developments of the [GDAL driver implementation for SciDB array](https://github.com/mappl/scidb4gdal) also support automatical tiled array insertion based on spatial location such that merging is done automatically in the database. To load the data we simply run the following commands at the command line:


```
# Set SciDB connection parameters
export SCIDB4GDAL_HOST=https://localhost
export SCIDB4GDAL_PORT=8083
export SCIDB4GDAL_USER=scidb
export SCIDB4GDAL_PASSWD=xxxxxxxxx

gdal_merge.py -o srtm.tif *.hgt
gdal_translate -of SciDB srtm.tif "SCIDB:array=srtm"
```

After successful ingestion, the SRTM array in SciDB is spatially referenced, which you can check by running
`iquery -aq "eo_extent(srtm)"`or `iquery -aq "eo_getsrs(srtm)"`.


## Step 3: Data analysis

The following commands demonstrate very basic processing of the SRTM array. All the commands are given in AFL language, which can be executed by any SciDB client.

```
# 1. Compute elevation difference in x and y differences
set no fetch;
store(attribute_rename(build(srtm,iif((x+y) % 2 = 0, 1, -1)), band1, sgn), dummy);
store(join(apply(join(join(dummy,window(apply(join(srtm, dummy), d, band1*sgn), 0,1,0,0,sum(d) as xsum)),window(apply(join(srtm, dummy), d, band1*sgn), 0,0,0,1,sum(d) as ysum)), dx, xsum*sgn, dy, ysum*sgn),srtm),srtm_dif); # Bounary pixels must be ignored

# 2. Apply a 5x5 mean filter
set no fetch;
store(window(srtm_small,2,2,2,2,avg(band1)));
```

In this example, we used the SciDB command line cliente iquery. You can also run the same queries using the scidb R package and its `iquery()` function to access the database from remote. Python clients work similarly.

----

### Author(s)
Marius Appel - marius.appel@uni-muenster.de

