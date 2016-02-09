#Load libraries
library(rvest)

#Parse EPL table links from Wikipedia page
links <- read_html("https://en.wikipedia.org/wiki/Premier_League") %>% html_nodes("table") %>% .[[3]] %>%
  html_nodes("a") %>% html_attr("href") %>% .[grepl("/wiki/\\d+", .)]

#Define regex pattern to parse date from link to use later as factor
pattern <- gregexpr("/\\d{4}", links)
years <- regmatches(links, pattern) %>% unlist %>% sub("/", "", .)

links <- paste("https://en.wikipedia.org",links, sep = "")

tables <- list()

for (i in 1:length(links)) {
  #Record of non-uniform EPL table position on wiki page
  tpos <- c(2,2,2,2,3,3,2,2,2,3,4,2,2,2,1,1,1,5,5,4,4,4,4)
  
  df <- read_html(links[i]) %>% html_nodes(".wikitable") %>% .[[tpos[i]]] %>% html_table(fill = TRUE)
  names(df) <- c("Pos", "Team", "Pld", "W", "D", "L", "GF", "GA", "GD", "Pts")
 
   #Remove champion/relegation text and trailing-whitespace from Team column
  df$Team <- gsub("\\(.\\)", "", df$Team) %>% gsub("!.*$", "", .) %>% gsub("\\s+$", "", .) %>% gsub("^\\s+", "", .)
  
  #Subset on columns of interest
  df <- df[,1:10]

  #Append EPL year column to dataframe
  df$Year <- years[i]
  
  #Append dataframe to tables list()
  tables[[i]] <- df
}

#Merge individual tables into one large dataframe
megatable <- do.call(rbind, tables)

#Perform final cleanup on our dataframe removing junk rows
megatable$Pos <- as.numeric(megatable$Pos)
megatable <- subset(megatable, !is.na(megatable$Pos))

write.table(megatable, file = "EPL_historical_table.csv", sep=",", row.names = FALSE)

