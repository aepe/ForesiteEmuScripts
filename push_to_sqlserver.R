# Assumes samples are already stored in some folder.
# These samples should have been created by running sample_from_design.R first.
# Do not improvise much as the number of checks this scripts runs is minimal.

library(data.table)
library(DBI)

# Script setup ------------------------------------------------------------
sqlDbName <- readline(prompt = "SQL DB Name : ")
sqlHost   <- readline(prompt = "SQL DB Host : ")
sqlPort   <- readline(prompt = "SQL DB Port : ")
sqlUser   <- readline(prompt = "SQL Username: ")
sqlPass   <- readline(prompt = "SQL Password: ")

# Connect -----------------------------------------------------------------
con <- dbConnect(
  drv      = RPostgres::Postgres(),
  dbname   = sqlDbName,
  host     = sqlHost,
  port     = sqlPort,
  user     = sqlUser,
  password = sqlPass
)

if (!dbIsValid(con))
  stop("Couldn't connect to SQL Server: check script settings.")

# Read & prepare data -----------------------------------------------------
basePath = "./out/"

# Soil samples
soilPath       <- file.path(basePath, "soil_samples.csv")
soilSamples    <- fread(file = soilPath)

# Weather samples
weatherPath    <- file.path(basePath, "weather_samples.csv")
weatherSamples <- fread(file = weatherPath)
# weatherVars    <- colnames(weatherSamples)[2:8]
# weatherSamples <- dcast(
#   data      = weatherSamples,
#   formula   = weather_sample_id ~ yday,
#   value.var = weatherVars
# )

# Management samples
mgmtPath       <- file.path(basePath, "mgmt_samples.csv")
mgmtSamples    <- fread(file = mgmtPath)

# Reformat dates from YYYY-MM-DD to dd-mmm (e.g. 2020-10-15 to 15-oct)
format_date    <- function(x) { tolower(strftime(x, "%d-%b")) }
for (j in grep(glob2rx("*date*"), colnames(mgmtSamples), value = TRUE))
  set(mgmtSamples, j = j, value = format_date(mgmtSamples[[j]]))

# Sample plan index
runsPath       <- file.path(basePath, "run_samples.csv")
runsSamples    <- fread(file = runsPath)
runsSamples$y  <- -99.9
runsSamples$N  <- -99.9

# Push data to the SQL Server ---------------------------------------------
# Set up connection

# Push soil samples
print("Pushing soil samples to SQL Server.")
dbWriteTable(
  conn      = con,
  name      = 'soil_samples',
  value     = soilSamples,
  overwrite = TRUE
)

# Push weather samples
print("Pushing weather samples to SQL Server.")
dbWriteTable(
  conn      = con,
  name      = 'weather_samples',
  value     = weatherSamples,
  overwrite = TRUE
)

# Push management samples
print("Pushing management samples to SQL Server.")
dbWriteTable(
  conn      = con,
  name      = 'mgmt_samples',
  value     = mgmtSamples,
  overwrite = TRUE
)

# Push runs
print("Pushing runs to SQL Server.")
dbWriteTable(
  conn      = con,
  name      = 'runs_samples',
  value     = runsSamples,
  overwrite = TRUE
)

print("Closing connection.")
dbDisconnect(con)

print("All done, good bye o/")
