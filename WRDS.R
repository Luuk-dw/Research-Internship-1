library(dplyr)
library(RPostgres)
library(highfrequency)

wrds <- dbConnect(Postgres(), host = 'wrds-pgdata.wharton.upenn.edu', 
                  port = 9737, dbname = 'wrds', sslmode = 'require', 
                  user = 'luukdw', password='Viewsfromthe6')
res <- dbSendQuery(wrds, "select distinct table_name from 
                   information_schema.columns where table_schema='taqmsec' order
                   by table_name")
df_dates <- dbFetch(res, n = -1)
dbClearResult(res)

dates_trades <-
  df_dates %>%
  filter(grepl("ctm",table_name), !grepl("ix_ctm",table_name)) %>%
  mutate(table_name = substr(table_name, 5, 12)) %>%
  unlist()
dds <- dates_trades[4125:4882]

stocks <- c("MMM", "AXP", "AMGN", "AAPL", "BA", "CAT", "CVX", "CSCO", "KO",
            "DOW", "GS", "HD", "HON", "INTC", "IBM", "JNJ", "JPM", "MCD", "MRK",
            "MSFT", "NKE", "PG", "CRM", "TRV", "UNH", "VZ", "V", "WBA", "WMT",
            "DIS")

df <- data.frame()
for (stock in stocks) {
  print(stock)
  for (dd in dds) {
    res <- 
      dbSendQuery(wrds,
                  paste0("select concat(date, ' ',time_m) as DT,", 
                         " ex, sym_root, sym_suffix, price, size, tr_scond",
                         " from taqmsec.ctm_", dd,
                         " where (ex = 'N' or ex = 'T' or ex = 'Q' or ex = 'A')",
                         " and sym_root = '", stock, "'",
                         " and price != 0 and tr_corr = '00'"))
    df_stock <- dbFetch(res, n = -1)
    dbClearResult(res)
    
    dt_stock <- 
      df_stock %>%
      rename(DT = dt, PRICE = price, SYM_ROOT = sym_root, SYM_SUFFIX = sym_suffix, 
             SIZE = size, EX = ex, COND = tr_scond) %>%
      mutate(DT = lubridate::ymd_hms(DT, tz = "UTC")) %>%
      data.table::as.data.table() %>%
      exchangeHoursOnly() %>% # only observations from 9:30 to 16:00
      tradesCondition() %>% # from highfrequency package
      mergeTradesSameTimestamp() %>% # merge trades frhom same time stamp
      rmOutliersTrades()
    
    dt_stock_fifteen_minutes <-
      dt_stock %>%
      aggregatePrice(alignPeriod = 15)
    
    df <- rbind(df, dt_stock_fifteen_minutes)
  }
}

df
