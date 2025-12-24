library(dplyr)
library(ggplot2)
library(gganimate)
library(ggrepel)
library(grid)
library(gridExtra)

source("functions.R")  # <-- load helpers + functions

# -------------------------------------------------------------
# Load Data
# -------------------------------------------------------------
pre_ball  <- read.csv("data/pre_ball.csv")
post_ball <- read.csv("data/post_ball.csv")
rosters   <- read.csv("data/rosters.csv")
supplementary <- read.csv("data/supplementary_data.csv")
full_predictions <- read.csv("data/full_predictions.csv")

# -------------------------------------------------------------
# Choose a Play
# -------------------------------------------------------------
game_id_val <- 2023091100
play_id_val <- 3214

# -------------------------------------------------------------
# 1. Animated Play Visualization
# -------------------------------------------------------------
animate_play(
  game_id_val = game_id_val,
  play_id_val = play_id_val,
  df = pre_ball,
  supp = supplementary,
  save_path = "animations/play_test.gif"
)

# -------------------------------------------------------------
# 2. Freeze-Frame Actual vs Predicted Movement
# -------------------------------------------------------------
full_predictions <- full_predictions %>%
  left_join(catch_probs, by = c("game_id", "play_id"))

play <- plot_play_freeze(
  game_id_val = game_id_val,
  play_id_val = play_id_val,
  df_pred = full_predictions,
  full_df = pre_ball,
  supp = supplementary
)

ggsave(
  filename = "animations/play_3214.png",
  plot = play,
  width = 12,
  height = 8,
  dpi = 300
)
