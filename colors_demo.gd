extends Node



func show_off_all_the_pretty_colors():
	Color("#ffbb00")							# hex colors
	Color("#9f4", 0.8)							# short hex, with alpha
	Color("gold")								# named colors
	Color('aqua')								# different quotes
	Color.DEEP_SKY_BLUE							# named with constants
	Color(Color.DEEP_SKY_BLUE, 0.6)				# and alpha
	Color(1, 0.2, 0.5)							# rgb
	Color(1, 0.2, 0.5, 0.6)						# rgba
	Color(Color("medium spring green"))			# nesting
	Color(Color("#ff0000"), 0.5) 				# with alpha
	Color(Color(Color(Color.DARK_ORANGE, 0.8))) # even this here
	Color(1, 1, 1, 1)
	Color.WHITE
	Color.BLACK


	Color.DARK_TURQUOISE						# click the preview
	Color(0.9727, 0.019, 0.4229, 0.9255)		# to get a color picker
	Color(0.9297, 0.852, 0.0254, 1)				# and change colors directly

