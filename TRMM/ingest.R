
SCIDB_TARGETARRAAYNAME = "TRMM2014DEMO"

TRMMDIR = "~/TRMM3B42/"
FILEPATTERN = "3B42.*\\.nc$"

SUBDATASET = "pcp"
SCIDB_DATATYPE = "float"
PREFIX = "NETCDF:"

VERBOSE = TRUE

TRMM_WIDTH = 1440
TRMM_HEIGHT = 400

SCIDB_HOST = "localhost"
SCIDB_PORT = 8083
SCIDB_USER = "scidb"
SCIDB_PW = "scidb"
SCIDB_SSL = TRUE
SCIDB_CHUNKSIZE_YXT = c(256,256,64)
SCIDB_CHUNKOVERLAP_YXT = c(0,0,0)
SCIDB_COMPRESSION = "bzlib"


GDAL_PATH = "/home/m_appe01/Desktop/scidb4gdal/gdal-2.0.1/apps/"


getDaytimeFromFilename <- function(f) {
  YYYY = substr(f,6,9)
  MM = substr(f,10,11)
  DD = substr(f,12,13)
  hh = substr(f,15,16) 
  mm = "00"
  ss = "00"
  return(as.POSIXct(paste(YYYY,"-",MM,"-",DD," ", hh,  ":" , mm, ":" , ss, sep=""),tz = "GMT"))
}





## Get list of files
files = data.frame(name=list.files(TRMMDIR,pattern = FILEPATTERN, recursive = F), stringsAsFactors = FALSE)

# TEST SUBSET
#files = data.frame(name=files$name[1:10])

## Get date and time of all files and derive temporal resolution 
files$dt = getDaytimeFromFilename(files$name)
alldt = unique(diff(files$dt[order(files$dt)]))


if (any(alldt %% min(alldt) != 0)) {
  stop(paste("Irregular time intervals detected:" , alldt))
}
if (length(alldt) > 1) {
  cat("INFO: Detected some temporal gaps in the data...")
}  

dt = min(diff(files$dt[order(files$dt)]))
dtiso = switch(units(dt), 
  hours = {paste("PT", as.double(dt), "H", sep="")},
  secs = {paste("PT", as.double(dt), "S", sep="")},
  mins = {paste("PT", as.double(dt), "M", sep="")},
  days = {paste("P", as.double(dt), "D", sep="")},
  weeks = {paste("P", as.double(dt), "W", sep="")}
)

t0 = min(files$dt)
t1 = max(files$dt)
nt = as.integer(as.numeric(difftime(t1,t0, units = units(dt))) / as.numeric(dt) + 1) 
t0iso = format(t0)


cat(paste("Using t0=", t0iso," and dt=", dtiso  ,  "\n",sep=""))


require(scidb)
scidbconnect(host = SCIDB_HOST,port = SCIDB_PORT,username = SCIDB_USER,password = SCIDB_PW, protocol = ifelse(SCIDB_SSL,"https","https"))

TARGETARRAYSCHEMA = 
  paste("<", SUBDATASET, ":", SCIDB_DATATYPE, ifelse(is.null(SCIDB_COMPRESSION) || SCIDB_COMPRESSION =="", "", paste(" compression '", SCIDB_COMPRESSION, "'", sep="")), ">", 
        "[y=0:", TRMM_HEIGHT-1, ",", SCIDB_CHUNKSIZE_YXT[1], ",",  SCIDB_CHUNKOVERLAP_YXT[1], ",", 
        "x=0:", TRMM_WIDTH-1, ",", SCIDB_CHUNKSIZE_YXT[2], ",",  SCIDB_CHUNKOVERLAP_YXT[2] , ",", 
        "t=0:", nt, ",", SCIDB_CHUNKSIZE_YXT[3], ",",  SCIDB_CHUNKOVERLAP_YXT[3],"]" ,  sep="")

# if already exists this leads to an error which is ok but might be worth a warning 
cat(paste("Trying to create array:",  SCIDB_TARGETARRAAYNAME,  TARGETARRAYSCHEMA, "...\n"))
tryCatch(iquery(
  paste("CREATE ARRAY ", SCIDB_TARGETARRAAYNAME,  TARGETARRAYSCHEMA, sep="")
  ,return = F,n = 0), error=function(e) {warning(e)})

#scidbremove(SCIDB_TARGETARRAAYNAME, force = T)

temp_array = paste(SCIDB_TARGETARRAAYNAME, "_temp", sep="")
scidbremove(temp_array, force = T) # Make sure that temporary array does not exist

START=1
END = nrow(files)

args = commandArgs(trailingOnly = TRUE)
if (length(args > 0)) {
  START = as.integer(args[1])
}
if (length(args > 1)) {
  END = as.integer(args[2])
}

for (i in START:min(nrow(files),END)) {
  
  outDS = paste("\"SCIDB:array=", temp_array, " host=", ifelse(SCIDB_SSL,"https","https"), "://", SCIDB_HOST, " port=", SCIDB_PORT, " user=", SCIDB_USER, " password=", SCIDB_PW,  "\"", sep="")
  inDS = paste(PREFIX, TRMMDIR, "/", files$name[i], ":", SUBDATASET,  sep="")
  cmd = paste(GDAL_PATH, "/gdal_translate -of SciDB ", inDS, " ", outDS , sep="")
  system(command = cmd,ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
  
  tIndex = as.integer(as.numeric(difftime(files$dt[i],t0, units = units(dt))) / as.numeric(dt)) 
  afl_post = paste("insert(redimension(apply(attribute_rename(" , temp_array, ",band1,", SUBDATASET  , "),t," , tIndex, ")," , SCIDB_TARGETARRAAYNAME, "),", SCIDB_TARGETARRAAYNAME , ")", sep="")
  tryCatch(iquery(query = afl_post,return=F, n=0), error=function(e) {warning(e)})
  
  
  if (i %% 250 == 0) {
    temp_array2 = paste(SCIDB_TARGETARRAAYNAME, "_NOVERSIONS", sep="")
    #tryCatch(remove_old_versions(scidb(SCIDB_TARGETARRAAYNAME)), error=function(e) {warning(e)})
    tryCatch(iquery(
      paste("store(", SCIDB_TARGETARRAAYNAME, ",",  temp_array2, ");", sep="")
      ,return = F,n = 0), error=function(e) {warning(e)})
    tryCatch(iquery(
      paste("remove(", SCIDB_TARGETARRAAYNAME, ");", sep="")
      ,return = F,n = 0), error=function(e) {warning(e)})
    tryCatch(iquery(
      paste("rename(", temp_array2, ",", SCIDB_TARGETARRAAYNAME , ");", sep="")
      ,return = F,n = 0), error=function(e) {warning(e)})
    
  }
  

  
  scidbremove(temp_array, force = T)
  
  cat(paste("FINISHED ", i, "OF", nrow(files), ": ", round(100*i/nrow(files)) , "%: " , files$name[i] , "\n"))
  
  
  
}



# Finally again remove all versions
temp_array2 = paste(SCIDB_TARGETARRAAYNAME, "_NOVERSIONS", sep="")
tryCatch(iquery(
  paste("store(", SCIDB_TARGETARRAAYNAME, ",",  temp_array2, ");", sep="")
  ,return = F,n = 0), error=function(e) {warning(e)})
tryCatch(iquery(
  paste("remove(", SCIDB_TARGETARRAAYNAME, ");", sep="")
  ,return = F,n = 0), error=function(e) {warning(e)})
tryCatch(iquery(
  paste("rename(", temp_array2, ",", SCIDB_TARGETARRAAYNAME , ");", sep="")
  ,return = F,n = 0), error=function(e) {warning(e)})





# Set spatial and temporal reference
tryCatch(iquery(
  paste("eo_setsrs(", SCIDB_TARGETARRAAYNAME, ",'x','y','EPSG', 4326, 'x0=-180.0 y0=50.0 a11=0.25 a22=-0.25');", sep="")
  ,return = F,n = 0), error=function(e) {warning(e)})

tryCatch(iquery(
  paste("eo_settrs(", SCIDB_TARGETARRAAYNAME, ",'t','" , t0iso, "','", dtiso , "');" , sep="")
  ,return = F,n = 0), error=function(e) {warning(e)})



scidbdisconnect()

cat("DONE.")


