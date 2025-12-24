# NFL Big Data Bowl 2025 - Player Movement Prediction

This project was a submission to the **NFL's Big Data Bowl 2025 - Prediction Competition**. The goal was to predict player movements after the football is thrown, using tracking data from the 2023 NFL season.

## 📊 Project Overview

The project uses machine learning (XGBoost) to predict the next position (dx, dy) of players on the field during passing plays. The models are trained on pre-throw player tracking data and predict post-throw movement patterns.

## 🎯 Key Features

- **Player Movement Prediction**: XGBoost models trained to predict x and y displacement for all players
- **Catch Probability Model**: Logistic regression model to estimate catch probability for targeted receivers
- **Play Visualization**:  Animated and static visualizations of player routes and predicted movements
- **Feature Engineering**: Comprehensive set of tracking, temporal, and contextual features

## 📁 Repository Structure

```
NFLBDB/
├── data/                          # Data directory
│   ├── pre_ball. csv              # Pre-throw tracking data
│   ├── post_ball.csv             # Post-throw tracking data
│   ├── supplementary_data.csv    # Game and play context
│   ├── catch_probability.csv     # Catch probability predictions
│   └── full_predictions.csv      # All player predictions
├── train_data/                    # Training data by week
│   ├── input_2023_w*. csv         # Weekly pre-throw data
│   └── output_2023_w*.csv        # Weekly post-throw data
├── models/                        # Trained models
│   ├── model_dx.json             # X-displacement model
│   └── model_dy.json             # Y-displacement model
├── animations/                    # Generated visualizations
├── training. ipynb                 # Model training notebook
├── getting_data.R                # Data loading and preparation
├── functions.R                    # Visualization helper functions
├── running_functions.R           # Script to generate visualizations
├── completion. R                  # Catch probability modeling
└── Slideshow#1.pptx              # Project presentation
```

## 🛠️ Technology Stack

**Python (88. 8%)**
- `pandas` - Data manipulation
- `numpy` - Numerical computing
- `xgboost` - Gradient boosting models
- `scikit-learn` - Train/test splitting
- `matplotlib` - Static visualizations

**R (11.2%)**
- `dplyr` - Data wrangling
- `ggplot2` - Static plotting
- `gganimate` - Animated visualizations
- `nflreadr` - NFL roster data

## 🚀 Getting Started

### Prerequisites

**Python:**
```bash
pip install pandas numpy xgboost scikit-learn matplotlib jupyter
```

**R:**
```r
install.packages(c("dplyr", "ggplot2", "gganimate", "nflreadr"))
```

### Running the Pipeline

1. **Data Preparation** (R):
```r
source("getting_data.R")
```
This combines weekly tracking data and adds NFL roster information.

2. **Model Training** (Python):
```bash
jupyter notebook training.ipynb
```
Trains XGBoost models for player movement prediction.

3. **Catch Probability** (R):
```r
source("completion.R")
```
Fits logistic regression model for catch probability. 

4. **Generate Visualizations** (R):
```r
source("running_functions.R")
```
Creates animated plays and freeze-frame comparisons.

## 📈 Model Architecture

### Movement Prediction Models
- **Algorithm**: XGBoost (Gradient Boosting)
- **Objective**: Regression (squared error)
- **Target Variables**: 
  - `dx`: X-coordinate displacement to next frame
  - `dy`: Y-coordinate displacement to next frame
- **Features** (32 total):
  - Position & motion:  x, y, speed, acceleration, direction, orientation
  - Temporal: frame_id (normalized), game_clock
  - Physical: player height, weight, position
  - Contextual: ball landing location, distance to ball, down, yards to go
  - Strategic: offense formation, coverage type, route type
  
### Catch Probability Model
- **Algorithm**: Logistic Regression
- **Target**:  Binary pass result (Complete/Incomplete)
- **Features**:  Tracking-based metrics for targeted receivers
  - Nearest defender distance and speed
  - Relative speed and direction
  - Ball landing location
  - Distance to sideline

## 📊 Model Performance

**Movement Prediction (RMSE)**:
- **dx model**: 0.01523 (validation)
- **dy model**: 0.01608 (validation)

These low RMSE values indicate high accuracy in predicting player positions frame-to-frame.

## 🎨 Visualizations

The project includes two types of visualizations:

1. **Animated Plays** (`animations/play_test.gif`):
   - Shows player movement throughout the play
   - Color-coded by offense/defense
   - Displays jersey numbers and field markings

2. **Freeze-Frame Analysis** (`animations/play_*. png`):
   - Compares actual vs predicted next positions
   - Highlights targeted receiver routes
   - Shows first-down markers and end zones

Example usage:
```r
animate_play(
  game_id_val = 2023091100,
  play_id_val = 3214,
  df = pre_ball,
  supp = supplementary,
  save_path = "animations/play_test.gif"
)
```

## 📝 Key Insights

- **Movement patterns** are highly predictable from tracking data
- **Contextual features** (formation, coverage) significantly improve predictions
- **Targeted receivers** show distinct movement patterns compared to other players
- **Catch probability** is influenced by defender proximity and ball trajectory

## 🏆 Competition Context

This project was submitted to the **NFL Big Data Bowl 2025**, an annual analytics competition where participants analyze NFL's Next Gen Stats data to generate actionable insights.

## 📧 Contact

**Jake Blumengarten**
- GitHub: [@JakeBlumengarten](https://github.com/JakeBlumengarten)

## 📄 License

This project uses publicly available NFL Big Data Bowl data. Please refer to the NFL's data usage policies for terms and conditions.

---

*Last Updated: December 2025*
