extends Node2D

var tgui
var scrollbar
var infolabel
var chartoffset = 0
var width = 10
var numprobes = 0
var visibleprobes = 0
var Height = 0
var Width = 0
var inited = false

func Init(node):
	tgui = node
	inited = true

func Update():
	if not inited || len(tgui.Trace) == 0:
		return

	Height = tgui.MovieChartContainer.size.y
	Width = tgui.MovieChartContainer.size.x
	numprobes = len(tgui.Trace[tgui.TActive].ProbeHistogram)
	visibleprobes = int(Width / width)
	if  numprobes <= visibleprobes:
		scrollbar.visible = false
	else:
		scrollbar.visible = true
		scrollbar.max_value = numprobes - visibleprobes
	queue_redraw()

# Called when the node enters the scene tree for the first time.
func _ready():
	scrollbar = get_node("../../MovieHScrollBar")
	infolabel = get_node("../../ProbeInfoLabel")
	scrollbar.value_changed.connect(self._value_changed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func SetActiveProbe(probenbr):
	var ind = tgui.Trace[tgui.TActive].UniqueProbeList.find(probenbr)
	if ind != -1:
		infolabel.text = tgui.Trace[tgui.TActive].LinePathFunc[ind]

func MouseLeftPressed():
	tgui.FindLineEdit.text = infolabel.text
	var tmpindex = tgui.Trace[tgui.TActive].index
	tgui._find_next_button_pressed()
	if tmpindex == tgui.Trace[tgui.TActive].index:
		tgui._find_prev_button_pressed()

func MouseMoved():
	var probenbr = tgui.Trace[tgui.TActive].UniqueProbeList[int( self.get_local_mouse_position().x / width) + chartoffset]
	SetActiveProbe(probenbr)

func _value_changed(val):
	chartoffset = val
	Update()

func log10(value):
	return log(value) / log(10)

func _draw():
	if not inited || len(tgui.Trace) == 0:
		return

	var height
	var hmax = log10(tgui.Trace[tgui.TActive].ProbeHistogram.max())

	for i in range (chartoffset, len(tgui.Trace[tgui.TActive].ProbeHistogram)):
		height = (log10(tgui.Trace[tgui.TActive].ProbeHistogram[i]) / hmax) * Height
		if height < 2:
			height = 2
		draw_rect(Rect2((i - chartoffset) * width, Height, width - 2, - height), Color.DARK_BLUE, true)
