#Load Dependencies
library(tidyverse)
library(stringr)
library(lubridate)
library(rvest)
library(magrittr)

#Set URL from where we will scrape our player URLs
source_url <- "https://www.whoscored.com/Players/73078/Fixtures/Alexandre-Lacazette"

player_urls <- read_html(source_url) %>% 
  html_nodes("table") %>% 
  .[[2]] %>% 
  html_nodes("a") %>% 
  html_attr("href") %>% 
  str_replace(., "Show", "Fixtures")

player_urls <- paste0("https://www.whoscored.com", player_urls)

#List that will hold our player_ratings collection
mytab <- list()

#Loop through our player_urls to populate our list with player_ratings
for (i in 1:length(player_urls)) {
  #print(player_urls[i])
  #Assign our column names
  names(tf[[i]]) <- c("comp","match_date","home_team","score","away_team","drop1","drop2","minutes_played","rating","player_name")
  
  df <- read_html(URLencode(player_urls[i])) %>% 
    html_nodes("table") %>% 
    extract2(1) %>% 
    html_table(fill = TRUE)
  
  #Parse player-name from URL and add it as new column. Replace "-" with space in name.
  name <- strsplit(player_urls[i], "/") %>% unlist %>% .[7] %>% sub("-"," ", .)
  df$player_name <- name

  mytab[[i]] <- df
 
}

#Combine all ratings into one dataframe
temp <- bind_rows(mytab)

#Pipeline to select columns of interest and split out score_result into separate columns as well as omit incomplete rows
arsenal <- temp %>% filter(comp == 'EPL') %>%  separate(score, c('home_score','away_score'), sep=':') %>% select(-contains('drop'),-minutes_played)  %>% na.omit

#Function to determine result based on scoreline
get_result <- function(home_team,home_goals,away_team,away_goals) {
  
  if (home_team == 'Arsenal') {
    if (home_goals > away_goals) {
      result = 'W'
    }
    else if (home_goals == away_goals) {
      result = 'D'
    }
    else result = 'L'
  }
  
  else if (away_team == 'Arsenal') {
    if (away_goals > home_goals) {
      result = 'W'
    }
    else if (away_goals == home_goals) {
      result = 'D'
    }
    else result = 'L'
  }
  return(result)
}

#Add new results column using our get_result() function
arsenal$result <- mapply(get_result, arsenal$home_team, arsenal$home_score, arsenal$away_team, arsenal$away_score)  

#Save our resulting dataframe as RDS object for future analysis
saveRDS(arsenal, file = "Arsenal_EPL_player_ratings_2018-19.rds")



