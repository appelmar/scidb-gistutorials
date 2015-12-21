# TRMM3B42 Tutorial
This tutorial demonstrates how to load and analyze time series of 
three hourly precipitation measurements from the Tropical Rainfall Measaurement Mission (TRMM3B42).

## Step 1: Download the data
`download.sh` provides a shell script to download three hourly data from 2005 to 2015. Notice that the full download might take some time and needs a couple of Gigabytes of disk space.

1. Create a directory where to store TRMM data, e.g `mkdir ~/TRMM3B42`
2. Copy the download script to that directory `cp download.sh ~/TRMM3B42/`
3. Start the download with `nohup ~/TRMM3B42/download.sh &`

Once the process has finished, unzip all archives by running `cd ~/TRMM3B42 && gunzip *.nc.gz`.


## Step 2: Ingest the data to SciDB

To ingest the data to SciDB, we need to create a three-dimensional target array first. The target array must be large enough to hold all TRMM3B42 images.
We thus chose the dimensionality $(\textrm{lat},\textrm{lon}, \textrm{t}) = (400,1440,29226)$.
The following R snippet illustrates how to create the array from R using the scidb package.

```
libraray(scidb)

SCIDB_TARGETARRAAYNAME = "TRMM3B42DEMO"
SCIDB_HOST = "localhost"
SCIDB_PORT = 8083 # We assume shim to run on port 8083
SCIDB_USER = "scidb"
SCIDB_PW = "scidb" # Change this accordingly
SCIDB_SSL = TRUE  # Use SSL to connect to Shim
SCIDB_CHUNKSIZE_YXT = c(256,256,64) # Chunk size of the target array
SCIDB_CHUNKOVERLAP_YXT = c(0,0,0)
SCIDB_COMPRESSION = "bzlib"

TRMM_WIDTH = 1440
TRMM_HEIGHT = 400

TRMM_WIDTH = 1440
TRMM_HEIGHT = 400
TRMM_NT = 29226
scidbconnect(host = SCIDB_HOST,port = SCIDB_PORT,username = SCIDB_USER,password = SCIDB_PW, protocol = ifelse(SCIDB_SSL,"https","https"))

TARGETARRAYSCHEMA = 
  paste("<pcp:float", ifelse(is.null(SCIDB_COMPRESSION) || SCIDB_COMPRESSION =="", "", paste(" compression '", SCIDB_COMPRESSION, "'", sep="")), ">", 
        "[y=0:", TRMM_HEIGHT-1, ",", SCIDB_CHUNKSIZE_YXT[1], ",",  SCIDB_CHUNKOVERLAP_YXT[1], ",", 
        "x=0:", TRMM_WIDTH-1, ",", SCIDB_CHUNKSIZE_YXT[2], ",",  SCIDB_CHUNKOVERLAP_YXT[2] , ",", 
        "t=0:", TRMM_NT-1, ",", SCIDB_CHUNKSIZE_YXT[3], ",",  SCIDB_CHUNKOVERLAP_YXT[3],"]" ,  sep="")
		
cat(paste("Trying to create array:",  SCIDB_TARGETARRAAYNAME,  TARGETARRAYSCHEMA, "...\n"))
iquery(paste("CREATE ARRAY ", SCIDB_TARGETARRAAYNAME,  TARGETARRAYSCHEMA, sep=""))
```

Now we are ready to load the data to the target array file by file. To do that, we first upload single files as individual two-dimensional arrays using our [GDAL driver implementation](https://github.com/mappl/scidb4gdal) and use AFL queries to reshape and insert this array to the target array afterwards.


```
TRMMDIR = "~/TRMM3B42/"
FILEPATTERN = "3B42.*\\.nc$"
files = data.frame(name=list.files(TRMMDIR,pattern = FILEPATTERN, recursive = F), stringsAsFactors = FALSE)
files = files[order(files$name),]
for (i in 1:nrow(files)) {
  # 1. build connection string for gdal driver
  outDS = paste("\"SCIDB:array=", "temp", " host=", ifelse(SCIDB_SSL,"https","https"), "://", SCIDB_HOST, " port=", SCIDB_PORT, " user=", SCIDB_USER, " password=", SCIDB_PW,  "\"", sep="")
  inDS = paste("NETCDF:", TRMMDIR, "/", files$name[i], ":", pcp,  sep="")
  
  # 2. Run gdal_translate to upload image to SciDB
  cmd = paste("./gdal_translate -of SciDB", inDS, outDS)
  system(cmd)
  
  # 3. Reshape array and insert to target array
  afl_post = paste("insert(redimension(apply(attribute_rename(temp,band1,pcp),t," , i, ")," , SCIDB_TARGETARRAAYNAME, "),", SCIDB_TARGETARRAAYNAME , ")", sep="")
  iquery(query = afl_post,return=F, n=0)
  
  # 4. Remove temporary two-dimensional array
  scidbremove("temp", force = T)
}
```


## Step 3: Clean up and add geographic reference
Since each insert creates a new array version we might save some disk space by removing old versions. The most effective way to do that is
to copy the array and store is under a different name by `store(A,B)`, remove the original array with `remove(A)` and finally rename the copy running `rename(B,A)`.
Additionally we now manually set the spatial and temporal reference of the target array.

```
iquery(paste("store(", SCIDB_TARGETARRAAYNAME, ",",  "temp2", ");", sep=""),return = F,n = 0)
iquery(paste("remove(", SCIDB_TARGETARRAAYNAME, ");", sep=""),return = F,n = 0)
iquery(paste("rename(temp2,", SCIDB_TARGETARRAAYNAME , ");", sep=""),return = F,n = 0)

# Set spatial and temporal reference
iquery(paste("eo_setsrs(", SCIDB_TARGETARRAAYNAME, ",'x','y','EPSG', 4326, 'x0=-180.0 y0=50.0 a11=0.25 a22=-0.25');", sep=""),return = F,n = 0)
iquery(paste("eo_settrs(", SCIDB_TARGETARRAAYNAME, ",'t','2005-01-01 00:00:00', 'PT3H');" , sep=""),return = F,n = 0)
```


## Step 4: Data analysis
The TRMM array is now ready for some analyses:

```
# 1. Compute aggregation over space
TRMM = scidb(SCIDB_TARGETARRAAYNAME)
TRMM.summary = aggregate(Filter("pcp >= 0", TRMM), by=list("y","x"), "avg(pcp),count(pcp),min(pcp),max(pcp),var(pcp)")
image(project(TRMM.summary,"pcp_avg"))

# 2. Compute yearly rainfall rate average
TRMM.yearly = regrid(Filter("pcp >= 0", TRMM), grid=c(1,1,2922), expr="avg(pcp)")
```

### Author(s)
Marius Appel - marius.appel@uni-muenster.de

