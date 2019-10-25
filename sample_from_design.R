# Draw soil, weather, and management decision samples and write them
# to csv files stored in a folder called 'out'.

library(ForesiteEmu)

# Use data.table under the hook for performance as the mgmt dataset is large.
fread       <- data.table::fread
fwrite      <- data.table::fwrite

# Settings
seed        <- 9000
nSoilLHSs   <- 200
nWeatherLHS <- 30
nMgmtLHSs   <- 50000

# Create output folder
dir.create("out")

# Soil sampling -----------------------------------------------------------
# Prepare empirical data
ssurgoPath  <- system.file("extdata", "ssurgo_ia169.txt", package = "ForesiteEmu")
ssurgoData  <- read.table(ssurgoPath, sep = "\t", header = TRUE)
ssurgoCols  <- c(
  "cokey", "hzdept_r", "hzdepb_r", "slope", "kffact", "dbthirdbar_r",
  "ph1to1h2o_r", "wthirdbar_r", "wfifteenbar_r", "awc_r", "claytotal_r",
  "sandtotal_r", "ksat_r", "om_r", "ll_r"
)

x           <- na.omit(ssurgoData[, ssurgoCols])

# Sampling settings
unitKey     <- "cokey" # Variable identifying
soilLayers  <- c(20, 40, 60, 80, 100, 150, 200)
soilLHSs    <- lhs_soil(x, unitKey, soilLayers, nSoilLHSs, seed)

fwrite(x = soilLHSs, file = "./out/soil_samples.csv")

# Weather sampling --------------------------------------------------------
# Prepare empirical data
weatherPath <- system.file(
  "extdata", "weather_ia169_1980_2018.txt", package = "ForesiteEmu"
)
weatherData <- read.table(file = weatherPath, sep = "\t", header = TRUE)[-1]
weatherCols <-
  c("year", "yday", "dayl", "prcp", "srad", "swe", "tmax", "tmin", "vp")

colnames(weatherData) <- weatherCols
x           <- na.omit(weatherData)

# Sampling settings
weatherLHSs <- lhs_weather(x, nWeatherLHS, seed)
fwrite(x = weatherLHSs, file = "./out/weather_samples.csv")

# Management sampling -----------------------------------------------------
# Simulate empirical data (we save it to a file for future use)
mgmtPath    <- "./out/mgmt_population.csv"

if (!file.exists(mgmtPath))
  fwrite(management_population(m = 2), mgmtPath)

x           <- fread(mgmtPath)

# Sampling settings
mgmtLHSs    <- lhs_management(x, nMgmtLHSs, seed)

fwrite(x = mgmtLHSs, file = "./out/mgmt_samples.csv")

# Generate runs -----------------------------------------------------------
set.seed(seed)

nRuns       <- max(nSoilLHSs, nWeatherLHS, nMgmtLHSs)
runs        <- data.frame(
  run_id               = 1:nRuns,
  soil_sample_id       = sample(rep(1:nSoilLHSs, len = nRuns)),
  weather_sample_id    = sample(rep(1:nWeatherLHS, len = nRuns)),
  management_sample_id = sample(rep(1:nMgmtLHSs, len = nRuns))
)

fwrite(x = runs, file = "./out/run_samples.csv")
