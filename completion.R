library(dplyr)

# ============================================================
# 1. LOAD DATA
# ============================================================
full <- read.csv("data/full_predictions.csv")
supp <- read.csv("data/supplementary_data.csv")

# Make IDs character to avoid join problems
full <- full %>% mutate(
  game_id = as.character(game_id),
  play_id = as.character(play_id),
  nfl_id  = as.character(nfl_id)
)

supp <- supp %>% mutate(
  game_id = as.character(game_id),
  play_id = as.character(play_id)
)

# Keep only play-level fields we need
supp_small <- supp %>%
  select(game_id, play_id, pass_result)


# ============================================================
# 2. ADD PASS RESULT LABEL
# ============================================================
full <- full %>%
  left_join(supp_small, by = c("game_id","play_id"))

# Convert to binary (corrected column name: pass_result.y)
full <- full %>%
  mutate(
    pass_result_bin = ifelse(pass_result.y == "C", 1L, 0L)
  )


# ============================================================
# 3. EXTRACT WR-TARGETED FINAL PRE-CATCH FRAME
# ============================================================
wr_frames <- full %>%
  filter(player_role == "Targeted Receiver",
         player_position == "WR") %>%
  group_by(game_id, play_id) %>%
  slice_max(frame_id) %>%        # last pre-ball frame
  ungroup()


# ============================================================
# 4. FEATURE ENGINEERING
# ============================================================
wr_frames <- wr_frames %>%
  mutate(
    dist_to_sideline = pmin(y, 53.3 - y),
    is_slot = if_else(y > 15 & y < (53.3 - 15), 1L, 0L)
  )

# Tracking-only feature list
tracking_features <- c(
  "nearest_defender_dist",
  "nearest_def_s",
  "rel_speed",
  "rel_dir",
  "defender_angle",
  "ball_angle",
  "s","a","dx","dy",
  "ball_land_x","ball_land_y",
  "dist_to_sideline","is_slot"
)


# ============================================================
# 5. REMOVE NA/INF IN FEATURES
# ============================================================
wr_frames[tracking_features] <- lapply(
  wr_frames[tracking_features],
  function(col) {
    col[!is.finite(col)] <- NA
    col[is.na(col)] <- 0
    col
  }
)


# ============================================================
# 6. FIT LOGISTIC MODEL (tracking only)
# ============================================================
catch_model <- glm(
  pass_result_bin ~ .,
  data = wr_frames[, c("pass_result_bin", tracking_features)],
  family = binomial()
)

summary(catch_model)


# ============================================================
# 7. GENERATE CATCH PROBABILITIES FOR ALL WR FRAMES
# ============================================================
wr_frames$catch_prob <- predict(
  catch_model,
  newdata = wr_frames,
  type = "response"
)


# ============================================================
# 8. OUTPUT CLEAN CATCH PROBABILITY FILE
# ============================================================
# ============================================================
# 8A. KEEP ONLY COLUMNS USED IN MODEL + IDs
# ============================================================

keep_cols <- c(
  "game_id","play_id","nfl_id","frame_id",
  "player_name","player_position","player_role","player_side",
  "pass_result_bin","catch_prob",
  tracking_features
)

wr_frames_clean <- wr_frames[, keep_cols]

write.csv(wr_frames_clean, "data/catch_probability.csv", row.names = FALSE)

cat("Catch probability file saved as data/catch_probability.csv\n")

catch_probs <- wr_frames %>%
  dplyr::select(game_id, play_id, nfl_id, catch_prob)
