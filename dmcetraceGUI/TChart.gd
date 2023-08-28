extends Node2D

var tgui
var _timeline_inited = false
var Box
var TMarkers
var debug = 0
var ZoomStart = 0
var ZoomEnd = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	TMarkers = get_node("../TMarkers")
	print("TChart ready")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _draw():
	if _timeline_inited and len(tgui.Trace) > 0:
		var Width = _box_size_x()
		var ratio =  Width / tgui.Trace[tgui.TActive].TimeSpan
		var oldx = 0
		for i in range(len(tgui.Trace[tgui.TActive].CoreList)):
			var y = int(tgui.CORE_KORV_HEIGHT * i)
			var core = tgui.Trace[tgui.TActive].CoreList[i]
			var j = tgui.Trace[tgui.TActive].TimestampsPerCore[core].bsearch(tgui.Trace[tgui.TActive].TimeSpanStart)
			while j < len(tgui.Trace[tgui.TActive].TimestampsPerCore[core]) && tgui.Trace[tgui.TActive].TimestampsPerCore[core][j] < tgui.Trace[tgui.TActive].TimeSpanEnd:
				var x =  int((tgui.Trace[tgui.TActive].TimestampsPerCore[core][j] - tgui.Trace[tgui.TActive].TimeSpanStart) * ratio)
				if x != oldx:
					draw_line(Vector2(x + int(tgui.TChartXOffset), y + 0), Vector2(int(tgui.TChartXOffset + x), y + tgui.CORE_KORV_HEIGHT), Color.DARK_OLIVE_GREEN, 1)
					oldx = x
					# time border to next pixel
					var fictive = (x + 1) / ratio + tgui.Trace[tgui.TActive].TimeSpanStart
					var fictive_index = tgui.Trace[tgui.TActive].TimestampsPerCore[core].bsearch(fictive)
					j = fictive_index
				else:
					# if we end up with next timestamp being the same as the last, lets look at next entry
					j = j + 1

		if tgui.ShowCoreChartGrid:
			for i in range(len(tgui.Trace[tgui.TActive].CoreList)):
				draw_rect(Rect2(0, tgui.CORE_KORV_HEIGHT * i, Box.size.x, tgui.CORE_KORV_HEIGHT), Color.DARK_SEA_GREEN / 2, false)

func _box_size_x():
	return Box.size.x - tgui.TChartXOffset

func _box_local_mouse_position():
	return {"x":get_local_mouse_position().x - tgui.TChartXOffset}

func InitTimeLine(node, box):
	tgui = node
	Box = box
	_timeline_inited = true
	tgui.TChartVScrollBar.max_value = len(tgui.Trace[tgui.TActive].CoreList)

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
	# replace with interval halfing if it gets too slow
	for i in range(tgui.Trace[tgui.TActive].INDEX_MAX):
		if tgui.Trace[tgui.TActive].TimeLineTS[tgui.Trace[tgui.TActive].INDEX_MAX - i] <= time:
			return tgui.Trace[tgui.TActive].INDEX_MAX - i
	return 0

func _get_time_from_xpos(xpos):
	var time = xpos * (tgui.Trace[tgui.TActive].TimeSpan / _box_size_x()) + tgui.Trace[tgui.TActive].TimeSpanStart
	return  time

func GetXposFromTime(time):
	return (time - tgui.Trace[tgui.TActive].TimeSpanStart) * (_box_size_x() / tgui.Trace[tgui.TActive].TimeSpan)

func _update_index(xpos):
	var mtime = _get_time_from_xpos(xpos)
	tgui.Trace[tgui.TActive].index = _get_index_from_time_left(mtime)
	if tgui.Trace[tgui.TActive].index < 0:
		tgui.Trace[tgui.TActive].index = 0
	if tgui.Trace[tgui.TActive].index >= tgui.Trace[tgui.TActive].INDEX_MAX:
		tgui.Trace[tgui.TActive].index = tgui.Trace[tgui.TActive].INDEX_MAX
	tgui.TraceViewScrollTop = tgui.Trace[tgui.TActive].index - int(tgui.TraceViewVisibleLines / 2)
	tgui.PopulateViews(tgui.TRACE | tgui.SRC | tgui.INFO)

func UpdateMarkers():
	var xpos
	xpos = GetXposFromTime(tgui.Trace[tgui.TActive].TimeLineTS[tgui.Trace[tgui.TActive].index])
	TMarkers.UpdateMarkers(xpos, tgui.TChartXOffset)

func UpdateScrollPosition():
	if _timeline_inited:
		var line_height = tgui.CORE_KORV_HEIGHT
		tgui.TChart.position.y = 0 - tgui.Trace[tgui.TActive].TChartVScrollBarIndex * line_height


func MouseLeftPressed():
	_update_index(_box_local_mouse_position().x)
	tgui.UpdateMarkers()

func MouseLeftReleased():
	pass

func MouseRightPressed():
	var start = _box_local_mouse_position().x
	TMarkers.ActivateDrawZoom(start)
	ZoomStart = _get_time_from_xpos(start)
	ZoomEnd = _get_time_from_xpos(start)

# This happens when a new zoom window is created
func MouseRightReleased():
	TMarkers.DeactivateDrawZoom()
	var tmpstart = _get_time_from_xpos(TMarkers.GetZoomWindow().start)
	var tmpend = _get_time_from_xpos(TMarkers.GetZoomWindow().end)

	ZoomStart = tmpstart
	ZoomEnd = tmpend

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
	if TMarkers.ZoomActive():
		tgui.CurrentTime = int(_get_time_from_xpos(_box_local_mouse_position().x))
		TMarkers.UpdateZoomWindow(_box_local_mouse_position().x)
		ZoomEnd = tgui.CurrentTime
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

	tgui.UpdateTimeLine()
	tgui.UpdateMarkers()
