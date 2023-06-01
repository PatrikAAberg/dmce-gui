extends Node2D

var MarkerXPos = -1
var tgui
var Box
var TChart
var _markers_inited = false
var _draw_zoom_active = false
var _zoom_start = 0
var _zoom_end = 0
var _x_offset = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	TChart = get_node("../TCHart")
	print("TMarkers ready")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _draw():

	if _markers_inited:
		var x = MarkerXPos + _x_offset
		draw_line(Vector2(x, 0), Vector2(x, Box.size.y), Color.GREEN_YELLOW, 1)

		if _draw_zoom_active:
			draw_rect(Rect2(_zoom_start + _x_offset, 0, _zoom_end - _zoom_start, Box.size.y), Color(0.4, 0.4, 0.4, 0.5))

func UpdateMarkers(xpos, xoff):
	if _markers_inited:
		MarkerXPos = xpos
		_x_offset = xoff
		queue_redraw()

func InitMarkers(node, box):
	tgui = node
	Box = box
	_markers_inited = true

func ActivateDrawZoom(start):
	_zoom_start = start
	_draw_zoom_active = true

func SetZoomEnd(end):
	_zoom_end = end

func DeactivateDrawZoom():
	_draw_zoom_active = false

func UpdateZoomWindow(end):
	_zoom_end = end

func GetZoomWindow():
	if _zoom_start > _zoom_end:
		var tmp = _zoom_start
		_zoom_start = _zoom_end
		_zoom_end = tmp
	return {"start" = _zoom_start, "end" = _zoom_end}
