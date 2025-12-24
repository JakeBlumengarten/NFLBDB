library(dplyr)
library(ggplot2)
library(gganimate)
library(grid)

# ======================================================================
# Get Supplementary Data
# ======================================================================
get_supp <- function(supp, game_id, play_id) {
  out <- supp %>%
    dplyr::filter(game_id == game_id,
                  play_id == play_id)
  
  if (nrow(out) == 0)
    stop("Supplemental row not found for this play.")
  
  # Convert the single row to a simple named list
  as.list(out[1, ])
}


# ======================================================================
# FIELD DRAWING
# ======================================================================
draw_field <- function() {
  list(
    geom_rect(aes(xmin = 0, xmax = 120, ymin = 0, ymax = 53.3),
              fill = "#A5D6A7", alpha = 0.25),
    geom_rect(aes(xmin = 0, xmax = 10, ymin = 0, ymax = 53.3),
              fill = "#66BB6A", alpha = 0.35),
    geom_rect(aes(xmin = 110, xmax = 120, ymin = 0, ymax = 53.3),
              fill = "#66BB6A", alpha = 0.35),
    geom_segment(
      data = data.frame(x = seq(10, 110, 5)),
      aes(x = x, xend = x, y = 0, yend = 53.3),
      color = "white", alpha = 0.25
    )
  )
}

# ======================================================================
# SAFELY GET SUPPLEMENTAL ROW
# ======================================================================
get_supp <- function(supp, gid, pid) {
  supp %>%
    dplyr::filter(game_id == gid, play_id == pid) %>%
    dplyr::slice(1)
}

# ======================================================================
# FIRST DOWN MARKER
# ======================================================================
compute_first_down <- function(los, yards_to_go, play_direction) {
  fd_raw <- if (tolower(play_direction) == "left") {
    los - yards_to_go
  } else {
    los + yards_to_go
  }
  max(0, min(120, fd_raw))
}

# ======================================================================
# ORIGINAL CLEAN MOVEMENT / ORIENTATION ARROWS
# ======================================================================

geom_original_movement_arrows <- function(df) {
  geom_segment(
    data = df,
    aes(
      x = x + cos(dir_rad) * 0.10,
      y = y + sin(dir_rad) * 0.10,
      xend = x + cos(dir_rad) * 0.25,
      yend = y + sin(dir_rad) * 0.25,
      color = "Movement direction"
    ),
    arrow = arrow(type = "closed", length = unit(0.35, "cm"), angle = 15),
    size = 0.2,
    lineend = "round"
  )
}

geom_original_orientation_arrows <- function(df) {
  geom_segment(
    data = df,
    aes(
      x = x + cos(o_rad) * 0.10,
      y = y + sin(o_rad) * 0.10,
      xend = x + cos(o_rad) * 0.20,
      yend = y + sin(o_rad) * 0.20,
      color = "Orientation"
    ),
    arrow = arrow(type = "closed", length = unit(0.35, "cm"), angle = 15),
    size = 0.05,
    lineend = "round"
  )
}

# ======================================================================
# ANIMATE PLAY
# ======================================================================

animate_play <- function(game_id_val, play_id_val,
                         df, supp,
                         save_path = "play_animation.gif",
                         fps = 10, duration = 8) {
  
  df <- dplyr::as_tibble(df)
  supp <- dplyr::as_tibble(supp)
  
  play_df <- df %>%
    dplyr::filter(game_id == game_id_val,
                  play_id == play_id_val) %>%
    mutate(
      dir_rad = dir * pi/180,
      o_rad   = o   * pi/180
    )
  
  s <- get_supp(supp, game_id_val, play_id_val)
  los <- unique(play_df$absolute_yardline_number)[1]
  
  fd <- compute_first_down(
    los,
    s$yards_to_go,
    play_df$play_direction[1]
  )
  
  title_text <- paste0(
    "Season: ", s$season, " Week: ", s$week, " | ", s$possession_team, " vs ", s$defensive_team,
    " — Q", s$quarter,
    " | ", s$game_clock,
    " | ", s$down, " & ", s$yards_to_go
  )
  
  p <- ggplot() +
    draw_field() +
    geom_vline(aes(xintercept = los), linewidth = 0.9) +
    geom_vline(aes(xintercept = fd), color = "gold",
               linetype = "dashed", linewidth = 0.9) +
    
    # Team-colored dots
    geom_point(
      data = play_df,
      aes(x = x, y = y, fill = player_side),
      size = 4, shape = 21
    ) +
    
    # ORIGINAL CLEAN ARROWS
    geom_original_movement_arrows(play_df) +
    geom_original_orientation_arrows(play_df) +
    
    # Jersey numbers LAST (so readable)
    geom_text(
      data = play_df,
      aes(x, y, label = jersey_number),
      size = 3, color = "white", fontface = "bold"
    ) +
    
    scale_fill_manual(
      values = c(
        Offense = "red",
        Defense = "blue"
      ),
      labels = c(
        Offense = s$possession_team,
        Defense = s$defensive_team
      )
    ) +
    scale_color_manual(
      name = "Arrows",
      values = c(
        `Movement direction` = "#FFD700",
        Orientation = "#4CAF50"
      )
    ) +
    
    coord_fixed(xlim = c(0,120), ylim = c(0,53.3)) +
    labs(title = title_text) +
    theme_minimal() +
    theme(
      legend.position = "bottom",
      plot.title = element_text(hjust = 0.5, face = "bold", size = 13)
    ) +
    
    transition_states(frame_id, transition_length = 1, state_length = 0) +
    ease_aes("linear")
  
  anim <- animate(p, width = 900, height = 550,
                  fps = fps, duration = duration)
  anim_save(save_path, animation = anim)
  anim
}

# ======================================================================
# FREEZE FRAME (ACTUAL VS PRED MOVEMENT)
# ======================================================================
plot_play_freeze <- function(game_id_val, play_id_val,
                             df_pred, full_df, supp) {
  
  # ------------------------------------------------------------
  # 1. Last frame with predicted movement (from full_predictions)
  # ------------------------------------------------------------
  last_frame <- df_pred %>%
    dplyr::filter(
      game_id == game_id_val,
      play_id == play_id_val,
      !is.na(dx_pred)
    ) %>%
    dplyr::summarise(frame_id = max(frame_id)) %>%
    dplyr::pull()
  
  if (length(last_frame) == 0) stop("No dx_pred frames found.")
  
  # ------------------------------------------------------------
  # 2. Use df_pred directly for that frame
  # ------------------------------------------------------------
  merged <- df_pred %>%
    dplyr::filter(
      game_id == game_id_val,
      play_id == play_id_val,
      frame_id == last_frame
    ) %>%
    dplyr::mutate(
      side = ifelse(player_side == "Offense", "Offense", "Defense")
    )
  
  # ------------------------------------------------------------
  # 3. Supplemental info
  # ------------------------------------------------------------
  s <- supp %>%
    dplyr::filter(
      game_id == game_id_val,
      play_id == play_id_val
    ) %>%
    dplyr::slice(1)
  
  # ------------------------------------------------------------
  # 4. LOS + First Down
  # ------------------------------------------------------------
  los <- unique(merged$absolute_yardline_number)[1]
  
  fd <- compute_first_down(
    los,
    s$yards_to_go,
    merged$play_direction[1]
  )
  
  # ------------------------------------------------------------
  # 5. Extract catch probability for title
  # ------------------------------------------------------------
  cp <- merged %>%
    dplyr::filter(player_role == "Targeted Receiver") %>%
    dplyr::pull(catch_prob)
  
  catch_prob_str <- ifelse(length(cp) == 0 || is.na(cp),
                           "NA",
                           sprintf("%.2f", cp))
  
  # ------------------------------------------------------------
  # 6. Plot
  # ------------------------------------------------------------
  ggplot() +
    draw_field() +
    
    geom_vline(aes(xintercept = los), linewidth = 1) +
    geom_vline(
      aes(xintercept = fd),
      color = "gold",
      linetype = "dashed",
      linewidth = 1
    ) +
    
    # Offense / Defense dots
    geom_point(
      data = merged,
      aes(x = x, y = y, color = side),
      size = 5
    ) +
    
    # Actual movement vectors
    geom_segment(
      data = merged %>% dplyr::filter(!is.na(dx)),
      aes(x = x, y = y, xend = x + dx, yend = y + dy, color = "Actual"),
      arrow = arrow(length = unit(0.25, "cm")),
      alpha = 0.8
    ) +
    
    # Predicted movement vectors
    geom_segment(
      data = merged %>% dplyr::filter(!is.na(dx_pred)),
      aes(x = x, y = y, xend = x + dx_pred, yend = y + dy_pred, color = "Predicted"),
      arrow = arrow(length = unit(0.25, "cm")),
      alpha = 0.8
    ) +
    
    # Jersey numbers
    geom_text(
      data = merged,
      aes(x = x, y = y, label = jersey_number),
      color = "white",
      size = 3,
      fontface = "bold"
    ) +
    
    scale_color_manual(
      name   = "Legend",
      values = c(
        "Actual"    = "green3",
        "Predicted" = "red3",
        "Offense"   = "red",
        "Defense"   = "blue"
      ),
      breaks = c("Actual", "Defense", "Offense", "Predicted")
    ) +
    
    coord_fixed(xlim = c(0, 120), ylim = c(0, 53.3)) +
    
    labs(
      title = paste0(
        "Freeze-Frame Prediction — Game ", game_id_val,
        " | Play ", play_id_val,
        " | Catch Prob: ", catch_prob_str
      ),
      subtitle = paste0(
        "Q", s$quarter, " | ", s$game_clock, " | ",
        s$home_team_abbr, " vs ", s$visitor_team_abbr,
        " | ", s$down, " & ", s$yards_to_go,
        " | Score: ", s$home_team_abbr, " ", s$pre_snap_home_score,
        " - ", s$visitor_team_abbr, " ", s$pre_snap_visitor_score
      ),
      x = "Field X (yards)",
      y = "Field Y (yards)"
    ) +
    
    theme_minimal() +
    theme(
      legend.position = "bottom",
      plot.title = element_text(size = 14, face = "bold")
    )
}
