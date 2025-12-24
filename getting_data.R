library(dplyr)
library(nflreadr)

# ----------------------------------------------------------
# Combining Data Before the Ball is Thrown
# ----------------------------------------------------------
all_weeks <- list()

for (wk in 1:18) {
  message("Loading week ", wk, " ...")
  
  file_path <- sprintf("data/input_2023_w%02d.csv", wk)
  all_weeks[[wk]] <- read.csv(file_path)
}

pre_ball <- do.call(rbind, all_weeks)

# ----------------------------------------------------------
# Combining Data After the Ball is Thrown
# ----------------------------------------------------------
all_weeks <- list()

for (wk in 1:18) {
  message("Loading week ", wk, " ...")
  
  file_path <- sprintf("data/output_2023_w%02d.csv", wk)
  all_weeks[[wk]] <- read.csv(file_path)
}

post_ball <- do.call(rbind, all_weeks)

# ----------------------------------------------------------
# Getting NFL Roster Data and Adding it to the Play Data
# ----------------------------------------------------------

roster_2023 <- load_rosters(seasons = 2023)%>%
  mutate(gsis_it_id = as.integer(gsis_it_id)) %>%   # convert to integer
  select(gsis_it_id, full_name, jersey_number)

pre_ball <- pre_ball %>%
  left_join(roster_2023, by = c("nfl_id" = "gsis_it_id"))
write.csv(pre_ball, file = "data/pre_ball.csv")

post_ball <- post_ball %>%
  left_join(roster_2023, by = c("nfl_id" = "gsis_it_id"))

supplementary <- read.csv('data/supplementary_data.csv')

supplementary <- supplementary%>%
  select(game_id, play_id, home_team_abbr, visitor_team_abbr, quarter, game_clock, down, yards_to_go, 
         possession_team, defensive_team, yardline_side, yardline_number, pass_result, pass_length, 
         offense_formation, route_of_targeted_receiver, team_coverage_type, yards_gained, expected_points)

pre_ball <- pre_ball%>%
  left_join(supplementary, by = c("game_id" = "game_id", "play_id" = "play_id"))
write.csv(pre_ball, file = "data/pre_ball.csv")

post_ball <- post_ball%>%
  left_join(supplementary, by = c("game_id" = "game_id", "play_id" = "play_id"))
write.csv(post_ball, file = "data/post_ball.csv")
