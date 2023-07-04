extends Node2D

var tgui

func Init(node):
	tgui = node

func Update():
	queue_redraw()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _draw():
	var Width = tgui.MovieChartContainer.size.x
	var Height = tgui.MovieChartContainer.size.y
	var width = Width / 2

	for i in range (10):
		draw_rect(Rect2(i * 15, Height, 10, -i * 5), Color.CADET_BLUE, true)
