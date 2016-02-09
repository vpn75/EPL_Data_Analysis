# EPL_Data_Analysis

##Overview
This is a little project to practice some data analysis techniques using historical English Premier League table data. 

The ```r{epl_data_scrape.R}``` script in this repository was written to scrape Wikipedia for EPL table data from its inception in 1992 through 2015 and consolidate into one large dataframe for analysis. The script saves the dataframe as a csv file for easy import/export by others.

This was my first attempt at web-scraping using R and I was very impressed with how easy the <a href="https://github.com/hadley/rvest package">Rvest package</a> made the whole process!

The CSV output has the following columns:
* **Pos** - Table position
* **Team** - Team Name
*  **Pld** - Games Played
*  **W** - Wins (3 pts)
*  **D** - Draws (1 pt)
*  **L** - Losses
*  **GF** - Goals For
*  **GA** - Goals Conceded
*  **GD** - Goal Differential (*May exclude in future as this is easily calculated*)
*  **Year** - Beginning year of EPL season
