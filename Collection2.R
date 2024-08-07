## Load packages
library(dplyr)

## Initialization
# Define path to files
taq <- "/Users/luuk/Documenten/School/Master/Research Assistantship/Data/10 Years"
files <- list.files(path=taq, pattern="\\.rds", full.names=TRUE)

# Define PERMNOs and tickers of the considered stocks, DOW is not included as it is only available from 2019 onward
permnos <- c(22592, 59176, 14008, 14593, 19561, 18542, 14541, 76076, 11308, 86868,
             66181, 10145, 59328, 12490, 22111, 47896,  43449, 22752, 10107, 57665,
             18163, 90215, 59459, 92655, 65875, 92611, 19502, 55976, 26403)
stocks <- c("MMM", "AXP", "AMGN", "AAPL", "BA", "CAT", "CVX", "CSCO", "KO", "GS",
            "HD", "HON", "INTC", "IBM", "JNJ", "JPM", "MCD", "MRK", "MSFT", "NKE",
            "PG", "CRM", "TRV", "UNH", "VZ", "V", "WBA", "WMT", "DIS")

## Construct a dataframe consisting of the prices for the stocks at 5 minute frequency
# Initialize an empty dataframe
df <- data.frame()

filename_length <- nchar(files[1])
# Loop over all files, i.e. the different dates
for (file in files) {
  date <- substring(file, filename_length - 13, filename_length - 4)
  
  # Print the date to indicate how fast the process is going
  print(date)         
  
  # Read the file corresponding to the particular date
  data <- readRDS(file)
  
  for (i in 1:length(stocks)) {
    # Extract the row in the file that corresponds to either the PERMNO of a stock or the ticker of the stock
    row <- subset(data, permno == permnos[i] | sym_root == stocks[i])
    # Extract the 5-minute returns from the row
    returns <- row$returns_5m[[1]]
    
    # Construct a dataframe consisting of the 5-minute returns for the stock
    df_stock_date <- data.frame(SYMBOL = stocks[i], DATE = date, RETURN=returns)
    
    # Add the dataframe of the particular stock on the particular date to the dataframe of all stocks for all dates
    df <- bind_rows(df, df_stock_date)
  }
}


# Create a .csv file from the dataframe
write.csv(df, file="HFData5DJIA10Y.csv", row.names=FALSE)
