extends Node2D

var MarkerXPos = -1
var tgui
var Box
var FChart
var _markers_inited = false
var _draw_zoom_active = false
var _zoom_start = 0
var _zoom_end = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	FChart = get_node("../FCHart")
	print("FMarkers ready")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _draw():
	if _markers_inited:
		draw_line(Vector2(MarkerXPos, 0), Vector2(MarkerXPos, Box.size.y), Color.RED, 1)
		if _draw_zoom_active:
			draw_rect(Rect2(_zoom_start, 0, _zoom_end - _zoom_start, Box.size.y), Color(0.4, 0.4, 0.4, 0.5))

func UpdateMarkers(xpos):
	if _markers_inited:
		MarkerXPos = xpos
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
