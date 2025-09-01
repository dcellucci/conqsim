extends Polygon2D

func update_dims():
	var board_dims = [
		Vector2(-GameSettings.board_width_px/2., -GameSettings.board_height_px/2.)
	  , Vector2( GameSettings.board_width_px/2., -GameSettings.board_height_px/2.)
	  , Vector2( GameSettings.board_width_px/2.,  GameSettings.board_height_px/2.)
	  , Vector2(-GameSettings.board_width_px/2.,  GameSettings.board_height_px/2.)
	]
	set_polygon(PackedVector2Array(board_dims))


# Create a barrage hud manager
# create N lines for each stand wide
