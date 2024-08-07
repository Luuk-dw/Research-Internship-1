rm(list=ls())

library(dplyr)

#Set working directory to source file location
taq <- "/Users/luuk/Documenten/School/Master/Research Assistantship/Code/10 Years"
files <- list.files(path=taq, pattern="\\.rds", full.names=TRUE)

permnos <- c(22592, 59176, 14008, 14593, 19561, 18542, 14541, 76076, 11308, 86868,
             66181, 10145, 59328, 12490, 22111, 47896,  43449, 22752, 10107, 57665,
             18163, 90215, 59459, 92655, 65875, 92611, 19502, 55976, 26403)
stocks <- c("MMM", "AXP", "AMGN", "AAPL", "BA", "CAT", "CVX", "CSCO", "KO", "GS",
            "HD", "HON", "INTC", "IBM", "JNJ", "JPM", "MCD", "MRK", "MSFT", "NKE",
            "PG", "CRM", "TRV", "UNH", "VZ", "V", "WBA", "WMT", "DIS")

df <- data.frame()

filename_length <- nchar(files[1])
for (file in files) {
  date <- substring(file, filename_length - 13, filename_length - 4)
  print(date)
  
  data <- readRDS(file)
  
  for (i in 1:length(stocks)) {
    row <- subset(data, permno == permnos[i] | sym_root == stocks[i])
    returns <- row$returns_5m[[1]]
    
    df_stock_date <- data.frame(SYMBOL = stocks[i], DATE = date, RETURN=returns)
    
    df <- bind_rows(df, df_stock_date)
  }
}


df