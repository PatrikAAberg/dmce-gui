extends Node2D

var tgui
var Box
var _timeline_inited = false
var FNameText
var Cores = []
var Colors = []
var TextColor = [] #["[color=#ff0000]", "[color=#00ff00]", "[color=#0000ff]"]
var FMarkers
var TitleText

func ClearCores(ind):
	Cores[ind] = []

func AddCore(core, ind):
	if core not in Cores[ind]:
		Cores[ind].append(core)
	else:
		Cores[ind].erase(core)
	Cores[ind].sort()

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(512):
		Cores.append([])

	var cols = [0, 0, 0]
	var steps = 10;
	var freq = 2 * PI / steps;
	for i in 256:
		cols[0] = sin(freq * i + 0) * 100 + 128
		cols[1] = sin(freq * i + 2) * 100 + 128
		cols[2] = sin(freq * i + 4) * 100 + 128

		var colstr = "%x%x%x" % cols
		Colors.append(Color(colstr))
		TextColor.append("[color=#" + colstr + "]")

	TitleText = get_node("./TitleText")
	TitleText.position.x = 0
	TitleText.position.y = -40
	FMarkers = get_node("../FMarkers")
	print("FChart ready")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _time_to_xpos():
	pass

func _in_sight(korv):
	# All within
	if korv.tstart >= tgui.Trace[tgui.TActive].TimeSpanStart and korv.tend <= tgui.Trace[tgui.TActive].TimeSpanEnd:
		return true

	# Right side in view
	if korv.tend >= tgui.Trace[tgui.TActive].TimeSpanStart and korv.tend <= tgui.Trace[tgui.TActive].TimeSpanEnd:
		return true

	# Left side in view
	if korv.tstart >= tgui.Trace[tgui.TActive].TimeSpanStart and korv.tstart <= tgui.Trace[tgui.TActive].TimeSpanEnd:
		return true

	# Both outside viwe
	if korv.tstart <= tgui.Trace[tgui.TActive].TimeSpanStart and korv.tend >= tgui.Trace[tgui.TActive].TimeSpanEnd:
		return true

	return false

func _draw():
	if _timeline_inited:
		var Width = Box.size.x
		var line_height = tgui.FNameText.get_line_offset(1)
		for i in len(Cores[tgui.TActive]):
			var core = Cores[tgui.TActive][i]
			var color = Colors[Cores[tgui.TActive][i]]
			if tgui.Trace[tgui.TActive].FTree[core] != null:
					for korv in tgui.Trace[tgui.TActive].FTree[core]:
						if _in_sight(korv):
							var x_start = (korv.tstart - tgui.Trace[tgui.TActive].TimeSpanStart) * ( Width / tgui.Trace[tgui.TActive].TimeSpan)
							var width = (korv.tend - tgui.Trace[tgui.TActive].TimeSpanStart) * ( Width / tgui.Trace[tgui.TActive].TimeSpan) - x_start
							if x_start < 0:
								x_start = 0
							if width > Width:
								width = Width
							var y_start = line_height * (korv.index) + 3
							draw_rect(Rect2(x_start, y_start, width, line_height - 6), color, false)

func InitTimeLine(node, box):
	print("FCHart init timeline")
	tgui = node
	Box = box
	tgui.FNameText.text = ""
	for i in range(len(tgui.Trace[tgui.TActive].FList)):
		tgui.FNameText.text += tgui.Trace[tgui.TActive].FList[i] + "\n"
	_timeline_inited = true
	tgui.FuncVScrollBar.max_value = len(tgui.Trace[tgui.TActive].FList)

func UpdateTimeLine():
	if _timeline_inited:
		tgui.FNameText.scroll_to_line(tgui.FuncVScrollBarIndex)
		var title = "Cores: "
		for i in len(Cores[tgui.TActive]):
			title = title + "  " + TextColor[Cores[tgui.TActive][i]] + str(Cores[tgui.TActive][i])
		TitleText.text = title
		queue_redraw()

func UpdateScrollPosition():
	if _timeline_inited:
		var line_height = tgui.FNameText.get_line_offset(1)
		tgui.FNameText.scroll_to_line(tgui.FuncVScrollBarIndex)
		if len(tgui.Trace[tgui.TActive].FList) >= (tgui.FuncVScrollBarIndex + tgui.FNameText.get_visible_line_count()):
			tgui.FChart.position.y = 0 - tgui.FuncVScrollBarIndex * line_height

func UpdateMarkers():
	var xpos
	xpos = (tgui.Trace[tgui.TActive].TimeLineTS[tgui.Trace[tgui.TActive].index] - tgui.Trace[tgui.TActive].TimeSpanStart) * (Box.size.x / tgui.Trace[tgui.TActive].TimeSpan)
	FMarkers.UpdateMarkers(xpos)

func _get_index_from_time(time):
	# replace with interval halfing if it gets too slow
	for i in range(tgui.Trace[tgui.TActive].INDEX_MAX):
		if tgui.Trace[tgui.TActive].TimeLineTS[i] > time:
			return i
	return tgui.Trace[tgui.TActive].INDEX_MAX

func _get_time_from_xpos(xpos):
	return xpos * (tgui.Trace[tgui.TActive].TimeSpan / Box.size.x) + tgui.Trace[tgui.TActive].TimeSpanStart

func _update_index(xpos):
	var mtime = _get_time_from_xpos(xpos)
	tgui.Trace[tgui.TActive].index = _get_index_from_time(mtime)
	if tgui.Trace[tgui.TActive].index < 0:
		tgui.Trace[tgui.TActive].index = 0
	if tgui.Trace[tgui.TActive].index >= tgui.Trace[tgui.TActive].INDEX_MAX:
		tgui.Trace[tgui.TActive].index = tgui.Trace[tgui.TActive].INDEX_MAX
	tgui.TraceViewScrollTop = tgui.Trace[tgui.TActive].index - int(tgui.TraceViewVisibleLines / 2)
	tgui.PopulateViews(tgui.TRACE | tgui.SRC | tgui.INFO)

func MouseLeftPressed():
	_update_index(get_local_mouse_position().x)
	tgui.UpdateMarkers()

func MouseLeftReleased():
	pass

func MouseRightPressed():
	FMarkers.ActivateDrawZoom(get_local_mouse_position().x)

# This happens when a new zoom window is created
func MouseRightReleased():
	print("TCHart set zoom")
	FMarkers.DeactivateDrawZoom()
	var tmpstart = _get_time_from_xpos(FMarkers.GetZoomWindow().start)
	var tmpend = _get_time_from_xpos(FMarkers.GetZoomWindow().end)

	if tmpstart < tgui.Trace[tgui.TActive].TimeStart:
		tmpstart = tgui.Trace[tgui.TActive].TimeStart

	if tmpend > tgui.Trace[tgui.TActive].TimeEnd:
		tmpend = tgui.Trace[tgui.TActive].TimeEnd

	tgui.Trace[tgui.TActive].TimeSpanStart = int(tmpstart)
	tgui.Trace[tgui.TActive].TimeSpanEnd = int(tmpend)
	tgui.Trace[tgui.TActive].TimeSpan = int(tmpend - tmpstart)

	tgui.UpdateTimeLine()
	tgui.UpdateMarkers()

func MouseMoved():
	FMarkers.UpdateZoomWindow(get_local_mouse_position().x)
	UpdateMarkers()

func MouseWheelUp():
	if tgui.FuncVScrollBar.value > tgui.FuncVScrollBar.min_value:
		tgui.FuncVScrollBar.value -= 1

func MouseWheelDown():
	if tgui.FuncVScrollBar.value < tgui.FuncVScrollBar.max_value:
		tgui.FuncVScrollBar.value += 1
