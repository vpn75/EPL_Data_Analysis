#Load Dependencies
library(tidyverse)
library(stringr)
library(lubridate)
library(rvest)

#Set URL from where we will scrape our player URLs
source_url <- "https://www.whoscored.com/Players/73078/Fixtures/Alexandre-Lacazette"

player_urls <- read_html(source_url) %>% 
  html_nodes("table") %>% 
  magrittr::extract2(2) %>% 
  html_nodes("a") %>% 
  html_attr("href") %>% 
  str_replace("Show", "Fixtures")

player_urls <- paste0("https://www.whoscored.com", player_urls)

#List that will hold our player_ratings collection
mytab <- list()

#Loop through our player_urls to populate our list with player_ratings

#NOTE: Had some issues with this loop where it would error out after processing a few players.
#Seems that the site was flagging us as a bot and blocking access temporarily so I had to 
#run this FOR loop in batches incrementing the i counter each time. 
for (i in 1:length(player_urls)) {
  
  #Generate script feedback
  message(player_urls[i])
  
  df <- read_html(URLencode(player_urls[i])) %>% 
    html_nodes("table") %>% 
    magrittr::extract2(1) %>% 
    html_table(fill = TRUE)
  
  #Parse player-name from URL and add it as new column. Replace "-" with space in name.
  name <- strsplit(player_urls[i], "/") %>% unlist %>% .[7] %>% sub("-"," ", .)
  df$player_name <- name

  #Assign our column names
  names(df) <- c("comp","match_date","home_team","score","away_team","drop1","drop2","minutes_played","rating","player_name")
  
  mytab[[i]] <- df
 
}

#Combine all ratings into one dataframe
temp <- bind_rows(mytab)

#Function to determine result based on scoreline. We'll use this in our pipeline below.
get_result <- function(home, away, home_score, away_score) {
  case_when(
    home == "Arsenal" & home_score > away_score ~ "W",
    home == "Arsenal" & home_score == away_score ~ "D",
    home == "Arsenal" & home_score < away_score ~ "L",
    away == "Arsenal" & away_score > home_score ~"W",
    away == "Arsenal" & home_score == away_score ~ "D",
    away == "Arsenal" & home_score > away_score ~ "L"
  )
}

#Pipeline to select columns of interest and split out score_result into separate columns as well as omit incomplete rows
gunners <- temp %>% 
  filter(comp == "EPL") %>%
  separate(score, into = c("home_score","away_score")) %>%
  mutate(minutes_played = sub("'","", minutes_played)) %>% 
  mutate_at(c("home_score","away_score","minutes_played"), as.integer) %>% 
  mutate_at(c("rating"), as.numeric) %>% 
  mutate(opponent = ifelse(home_team == 'Arsenal', away_team, home_team)) %>% 
  mutate(match_date = dmy(match_date)) %>% 
  mutate(match_location = ifelse(home_team == "Arsenal", "Home","Away")) %>% 
  mutate(match_location = factor(match_location, levels = c("Home","Away"))) %>%
  mutate(result = get_result(home_team, away_team, home_score, away_score)) %>%
  mutate(result = factor(result, levels = c("W","L","D"))) %>% 
  select(-contains('drop'))  %>%
  select(-contains("team")) %>% 
  select(player_name, match_date, match_location, opponent, result, minutes_played, rating)
  na.omit


#Save our resulting dataframe as RDS object for future analysis
saveRDS(arsenal, file = "Arsenal_EPL_player_ratings_2018-19.rds")
