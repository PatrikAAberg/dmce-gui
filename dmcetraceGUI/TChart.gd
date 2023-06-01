extends Node2D

var tgui
var _timeline_inited = false
var Box
var TMarkers
var debug = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	TMarkers = get_node("../TMarkers")
	print("TChart ready")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _draw():
	if _timeline_inited:
		var Width = _box_size_x()
		for i in range(len(tgui.Trace[tgui.TActive].TimeLineTS)):
			if tgui.Trace[tgui.TActive].TimeLineTS[i] >= tgui.Trace[tgui.TActive].TimeSpanStart and tgui.Trace[tgui.TActive].TimeLineTS[i] <= tgui.Trace[tgui.TActive].TimeSpanEnd:
				var x =  tgui.TChartXOffset + (tgui.Trace[tgui.TActive].TimeLineTS[i] - tgui.Trace[tgui.TActive].TimeSpanStart) * ( Width / tgui.Trace[tgui.TActive].TimeSpan)
				var y = tgui.CORE_KORV_HEIGHT * tgui.Trace[tgui.TActive].TimeLineCore[i]
				draw_line(Vector2(x, y + 0), Vector2(x, y + tgui.CORE_KORV_HEIGHT), Color.DARK_OLIVE_GREEN, 1)
		if tgui.ShowCoreChartGrid:
			for i in range(tgui.Trace[tgui.TActive].CoreMax + 1):
				draw_rect(Rect2(0, tgui.CORE_KORV_HEIGHT * i, Box.size.x, tgui.CORE_KORV_HEIGHT), Color.DARK_SEA_GREEN / 2, false)

func _box_size_x():
	return Box.size.x - tgui.TChartXOffset

func _box_local_mouse_position():
	return {"x":get_local_mouse_position().x - tgui.TChartXOffset}

func InitTimeLine(node, box):
	tgui = node
	Box = box
	_timeline_inited = true

func UpdateTimeLine():
	if _timeline_inited:
		queue_redraw()

func _get_index_from_time_left(time):
	# replace with interval halfing if it gets too slow
	for i in range(tgui.Trace[tgui.TActive].INDEX_MAX):
		if tgui.Trace[tgui.TActive].TimeLineTS[i] >= time:
			return i
	return tgui.Trace[tgui.TActive].INDEX_MAX

func _get_index_from_time_right(time):
	print("Searching for " + str(time) + " from the right")
	print("Starting at " +str(tgui.Trace[tgui.TActive].TimeLineTS[tgui.Trace[tgui.TActive].INDEX_MAX - 0]))
	# replace with interval halfing if it gets too slow
	for i in range(tgui.Trace[tgui.TActive].INDEX_MAX):
		if tgui.Trace[tgui.TActive].TimeLineTS[tgui.Trace[tgui.TActive].INDEX_MAX - i] <= time:
			print("...found it at: " + str(tgui.Trace[tgui.TActive].INDEX_MAX - i))
			return tgui.Trace[tgui.TActive].INDEX_MAX - i
	print("did not find it, returning 0")
	return 0

func _get_time_from_xpos(xpos):
	var time = xpos * (tgui.Trace[tgui.TActive].TimeSpan / _box_size_x()) + tgui.Trace[tgui.TActive].TimeSpanStart
	print("_box_size_x: " + str(_box_size_x()))
	print("Span: " + str(tgui.Trace[tgui.TActive].TimeSpan) + " xpos: " + str(xpos) + " SpanStart: " + str(tgui.Trace[tgui.TActive].TimeSpanStart))
	print("rerturned time: " + str(time))
	return  time

func _update_index(xpos):
	var mtime = _get_time_from_xpos(xpos)
	print("mtime: " + str(mtime) + "   xpos: " + str(xpos))
	tgui.Trace[tgui.TActive].index = _get_index_from_time_left(mtime)
	if tgui.Trace[tgui.TActive].index < 0:
		tgui.Trace[tgui.TActive].index = 0
	if tgui.Trace[tgui.TActive].index >= tgui.Trace[tgui.TActive].INDEX_MAX:
		tgui.Trace[tgui.TActive].index = tgui.Trace[tgui.TActive].INDEX_MAX
	tgui.TraceViewScrollTop = tgui.Trace[tgui.TActive].index - int(tgui.TraceViewVisibleLines / 2)
	tgui.PopulateViews(tgui.TRACE | tgui.SRC | tgui.INFO)

func UpdateMarkers():
	var xpos
	xpos = (tgui.Trace[tgui.TActive].TimeLineTS[tgui.Trace[tgui.TActive].index] - tgui.Trace[tgui.TActive].TimeSpanStart) * (_box_size_x() / tgui.Trace[tgui.TActive].TimeSpan)
	TMarkers.UpdateMarkers(xpos, tgui.TChartXOffset)

func MouseLeftPressed():
	_update_index(_box_local_mouse_position().x)
	tgui.UpdateMarkers()

func MouseLeftReleased():
	pass

func MouseRightPressed():
	TMarkers.ActivateDrawZoom(_box_local_mouse_position().x)

# This happens when a new zoom window is created
func MouseRightReleased():
	print("TCHart set zoom")
	TMarkers.DeactivateDrawZoom()
	var tmpstart = _get_time_from_xpos(TMarkers.GetZoomWindow().start)
	var tmpend = _get_time_from_xpos(TMarkers.GetZoomWindow().end)

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
	TMarkers.UpdateZoomWindow(_box_local_mouse_position().x)
	UpdateMarkers()

# Zoom in
func MouseWheelUp():

	var ts = tgui.Trace[tgui.TActive].TimeSpan
	var curtime = tgui.Trace[tgui.TActive].TimeLineTS[tgui.Trace[tgui.TActive].index]
	var shrink = tgui.ZOOM_SHRINK * ts
	var tmpstart = tgui.Trace[tgui.TActive].TimeSpanStart
	var tmpend = tgui.Trace[tgui.TActive].TimeSpanEnd

	# center around marker
	tmpstart = curtime - (ts / 2)
	tmpend = curtime + (ts / 2)

	# decrease timespan
	tmpstart += shrink
	tmpend -= shrink

	if tmpstart < tgui.Trace[tgui.TActive].TimeStart:
		tmpstart = tgui.Trace[tgui.TActive].TimeStart

	if tmpend > tgui.Trace[tgui.TActive].TimeEnd:
		tmpend = tgui.Trace[tgui.TActive].TimeEnd

	var tmpspan = tmpend - tmpstart
	if ((tmpend - tmpstart) > tgui.ZOOM_SHRINK_MIN) and (curtime > tmpstart and curtime < tmpend):
		tgui.Trace[tgui.TActive].TimeSpanStart = int(tmpstart)
		tgui.Trace[tgui.TActive].TimeSpanEnd = int(tmpend)
		tgui.Trace[tgui.TActive].TimeSpan = int(tmpspan)
	else:
		return
	print("zoom in, start: " + str(tmpstart) + "  end: " + str(tmpend) + "  span:" + str(tmpspan))
	tgui.UpdateTimeLine()
	tgui.UpdateMarkers()

# Zoom out
func MouseWheelDown():

	var ts = tgui.Trace[tgui.TActive].TimeSpan
	var curtime = tgui.Trace[tgui.TActive].TimeLineTS[tgui.Trace[tgui.TActive].index]
	var grow = tgui.ZOOM_SHRINK * ts
	var tmpstart = tgui.Trace[tgui.TActive].TimeSpanStart
	var tmpend = tgui.Trace[tgui.TActive].TimeSpanEnd

	# center around marker
	tmpstart = curtime - (ts / 2)
	tmpend = curtime + (ts / 2)

	# increase timespan
	tmpstart -= grow
	tmpend += grow

	if tmpstart < tgui.Trace[tgui.TActive].TimeStart:
		tmpend += (tgui.Trace[tgui.TActive].TimeStart - tmpstart)
		tmpstart = tgui.Trace[tgui.TActive].TimeStart

	if tmpend > tgui.Trace[tgui.TActive].TimeEnd:
		tmpstart -= (tmpend - tgui.Trace[tgui.TActive].TimeStart)
		tmpend = tgui.Trace[tgui.TActive].TimeEnd

	# if span larger than entire trace, reset to edges
	if (tmpend - tmpstart) > (tgui.Trace[tgui.TActive].TimeEnd - tgui.Trace[tgui.TActive].TimeStart):
		tmpstart = tgui.Trace[tgui.TActive].TimeStart
		tmpend = tgui.Trace[tgui.TActive].TimeEnd

	var tmpspan = (tmpend - tmpstart)

	tgui.Trace[tgui.TActive].TimeSpanStart = int(tmpstart)
	tgui.Trace[tgui.TActive].TimeSpanEnd = int(tmpend)
	tgui.Trace[tgui.TActive].TimeSpan = int(tmpspan)

	print("grow: " + str(grow) + "  zoom out, start: " + str(tmpstart) + "  end: " + str(tmpend) + "  span:" + str(tmpspan) + " curtime: " + str(curtime))

	tgui.UpdateTimeLine()
	tgui.UpdateMarkers()