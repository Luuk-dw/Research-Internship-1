## Load packages
library(dplyr)
library(RPostgres)
library(highfrequency)

## Establish connection to WRDS
# Fill in username and password
wrds <- dbConnect(Postgres(), host = 'wrds-pgdata.wharton.upenn.edu', 
                  port = 9737, dbname = 'wrds', sslmode = 'require', 
                  user = 'luukdw', password='')
res <- dbSendQuery(wrds, "select distinct table_name from 
                   information_schema.columns where table_schema='taqmsec' order
                   by table_name")
df_dates <- dbFetch(res, n = -1)
dbClearResult(res)

## Initialization
# Construct a dataframe consisting of the trading dates
dates_trades <-
  df_dates %>%
  filter(grepl("ctm",table_name), !grepl("ix_ctm",table_name)) %>%
  mutate(table_name = substr(table_name, 5, 12)) %>%
  unlist()
# Extract the dates that we are interested in (02/01/2020-30/12/2022)
dds <- dates_trades[4125:4882]

# Initialize a vector of tickers of the stocks on the DJIA Index
stocks <- c("MMM", "AXP", "AMGN", "AAPL", "BA", "CAT", "CVX", "CSCO", "KO",
            "DOW", "GS", "HD", "HON", "INTC", "IBM", "JNJ", "JPM", "MCD", "MRK",
            "MSFT", "NKE", "PG", "CRM", "TRV", "UNH", "VZ", "V", "WBA", "WMT",
            "DIS")

## Construct a dataframe consisting of the prices for the stocks at 5 minute frequency
# Initialize an empty dataframe
df <- data.frame()

# Loop over the stocks
for (stock in stocks) {
  # Print the ticker of the current stock to indicate how fast the process is going
  print(stock)
  
  # Loop over the trading days
  for (dd in dds) {
    # Fetch the data for the particular stock on the particular date
    res <- 
      dbSendQuery(wrds,
                  paste0("select concat(date, ' ',time_m) as DT,", 
                         " ex, sym_root, sym_suffix, price, size, tr_scond",
                         " from taqmsec.ctm_", dd,
                         " where (ex = 'N' or ex = 'T' or ex = 'Q' or ex = 'A')",
                         " and sym_root = '", stock, "'",
                         " and price != 0 and tr_corr = '00'"))      # consider NYSE, AMEX, and NASDAQ
    df_stock <- dbFetch(res, n = -1)
    dbClearResult(res)
    
    # Rename data for use in highfrequency package and clean the data
    dt_stock <- 
      df_stock %>%
      rename(DT = dt, PRICE = price, SYM_ROOT = sym_root, SYM_SUFFIX = sym_suffix, 
             SIZE = size, EX = ex, COND = tr_scond) %>%
      mutate(DT = lubridate::ymd_hms(DT, tz = "UTC")) %>%
      data.table::as.data.table() %>%
      exchangeHoursOnly() %>%      # only observations from 9:30 to 16:00
      tradesCondition() %>%      # from highfrequency package
      mergeTradesSameTimestamp() %>%      # merge trades from same time stamp
      rmOutliersTrades()
    
    dt_stock_five_minutes <-
      dt_stock %>%
      aggregatePrice(alignPeriod = 5)       # adjust here for a different frequency 
    
    # Add the dataframe of the particular stock on the particular date to the dataframe of all stocks for all dates
    df <- rbind(df, dt_stock_five_minutes)
  }
}

# Create a .csv file from the dataframe
write.csv(df, file="HFData5DJIA3Y.csv", row.names=FALSE)
