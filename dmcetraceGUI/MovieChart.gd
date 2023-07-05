extends Node2D

var tgui
var scrollbar
var chartoffset = 0

func Init(node):
	tgui = node

func Update():
	var Width = tgui.MovieChartContainer.size.x
	var numprobes = len(tgui.Trace[tgui.TActive].ProbeHistogram)
	var width = 10
	var visibleprobes = int(Width / width)
	if  numprobes <= visibleprobes:
		scrollbar.visible = false
	else:
		scrollbar.visible = true
		scrollbar.max_value = numprobes - visibleprobes
	queue_redraw()

# Called when the node enters the scene tree for the first time.
func _ready():
	scrollbar = get_node("../../MovieHScrollBar")
	scrollbar.value_changed.connect(self._value_changed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _value_changed(val):
	chartoffset = val
	Update()

func log10(value):
	return log(value) / log(10)

func _draw():
	var Width = tgui.MovieChartContainer.size.x
	var Height = tgui.MovieChartContainer.size.y
	var width = 10
	var height
	var max = log10(tgui.Trace[tgui.TActive].ProbeHistogram.max())

	for i in range (chartoffset, len(tgui.Trace[tgui.TActive].ProbeHistogram)):
		height = (log10(tgui.Trace[tgui.TActive].ProbeHistogram[i]) / max) * Height
		if height < 2:
			height = 2
		draw_rect(Rect2((i - chartoffset) * width, Height, width - 2, - height), Color.DARK_BLUE, true)
