extends Node

# Overall game settings
var window_width_px = 1920
var window_height_px = 1080

# World inch-to-pixel mappings
const PIXELS_PER_INCH: int = 30
const STAND_DIM_PX: int = 78
var board_width_px: int = 72*PIXELS_PER_INCH
var board_height_px: int = 48*PIXELS_PER_INCH 

var regiment_ui_button_size = 0.5*PIXELS_PER_INCH

# Camera settings
var min_zoom := 0.7
var max_zoom := 3.0
var zoom_factor := 0.1
var zoom_duration := 0.2

# UI Settings
var sidebar_width_px = 300
