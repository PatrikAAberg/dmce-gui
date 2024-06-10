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
var ZoomStart = 0
var ZoomEnd = 0
var mutex
var FChartPanel
var FuncFont:Font
var FuncFontMinWidth
var FuncFontCharWidth

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

	FChartPanel = get_node("../../FChartPanel")
	TitleText = get_node("../../FChartBar/TitleText")
	TitleText.position.x = 0
	TitleText.position.y = -40
	FMarkers = get_node("../FMarkers")
	mutex = Mutex.new()

#	FuncFont =  ThemeDB.fallback_font;
	FuncFont = load("res://FiraCode-Medium.ttf")

# Lets hard code size to 10 for now
#	FuncFontMinWidth = FuncFont.get_string_size("                    ").x
#	FuncFontCharWidth = int(FuncFontMinWidth / 20)
#	FuncFontMinWidth = FuncFontCharWidth * 8
	FuncFontMinWidth = 10 * 8
	FuncFontCharWidth = 8

	# Set the desired font size
#	FuncFont.size = 10
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

func _compare_end(a,b):
	return a.tend <= b.tend

func _worker(thread_id, indstart, indend):
#	print("Starting thread " + str(thread_id) + "  Interval: " + str(indstart) + "-" + str(indend))
	_draw_from_func_list_interval(indstart, indend)

func _worker_cores(thread_id, indstart, indend):
#	print("Starting thread " + str(thread_id) + "  Interval: " + str(indstart) + "-" + str(indend))
	_draw_from_core_list_interval(indstart, indend)

func _find_all_marker_in_sight(ts):
	if (ts > tgui.Trace[tgui.TActive].TimeSpanStart) and (ts < tgui.Trace[tgui.TActive].TimeSpanEnd):
		return true

func _draw_from_func_list():
	if _timeline_inited:
		var num_cores = OS.get_processor_count() - 2
		var num_funcs = len(tgui.Trace[tgui.TActive].FDrawList)
		var funcs_per_core = num_funcs / num_cores
		if funcs_per_core == 0:
			funcs_per_core = num_funcs
		var thread_count = 0
		var threadlist = []
		var func_count = 0

		# Set vscroll size
		var page = int(FChartPanel.size.y / tgui.FNameText.get_line_offset(1))
		tgui.FuncVScrollBar.max_value = num_funcs
		tgui.FuncVScrollBar.page = page

#		print("num_cores: " + str(num_cores))
#		print("num_funcs: " + str(num_funcs))
#		print("funcs per core: " + str(funcs_per_core))
#		print("thread_count: " + str(thread_count))
#		print("func_count: " + str(func_count))
		while func_count < num_funcs:
			var thread = Thread.new()
			if (num_funcs - func_count) < funcs_per_core:
				thread.start(_worker.bind(thread_count, func_count, num_funcs ))
#				_worker(thread_count, func_count, num_funcs )
			else:
				thread.start(_worker.bind(thread_count, func_count, func_count + funcs_per_core))
#				_worker(thread_count, func_count, func_count + funcs_per_core)
			thread_count += 1
			func_count += funcs_per_core
			threadlist.append(thread)
		for t in threadlist:
			t.wait_to_finish()

		if tgui.SearchShowAll:
			var count = tgui.Trace[tgui.TActive].FindAllMarkers.bsearch(tgui.Trace[tgui.TActive].TimeSpanStart) - 1
			if count < 0:
				count = 0
			while count < len(tgui.Trace[tgui.TActive].FindAllMarkers):
				var ts = tgui.Trace[tgui.TActive].FindAllMarkers[count]
				if ts > tgui.Trace[tgui.TActive].TimeSpanEnd:
					break
				var Width = float(Box.size.x)
				if _find_all_marker_in_sight(ts):
					var xpos = (ts - tgui.Trace[tgui.TActive].TimeSpanStart) * ( Width / tgui.Trace[tgui.TActive].TimeSpan)
					draw_rect(Rect2(xpos, 0, 1, Box.size.y), Color("208bb5"), false)
				count += 1

func _draw_from_func_list_interval(indstart, indend):
	if _timeline_inited:
		# Prevent from getting to a state we cant zoom out from
		if tgui.Trace[tgui.TActive].TimeSpan < 10:
			tgui.Trace[tgui.TActive].TimeSpanStart = tgui.Trace[tgui.TActive].TimeSpanEnd - 10
			if tgui.Trace[tgui.TActive].TimeSpanStart < tgui.Trace[tgui.TActive].TimeStart:
				tgui.Trace[tgui.TActive].TimeSpanStart += 10
				tgui.Trace[tgui.TActive].TimeSpanEnd += 10
			tgui.Trace[tgui.TActive].TimeSpan = 10

		var Width = float(Box.size.x)
		var line_height = tgui.FNameText.get_line_offset(1)
		var func_count = indstart
		var rect_count = 0
		var korv_count = 0
		var box_list = []
		var dubbla = 0
		for klistindex in range(indstart, indend):
			if klistindex > len(tgui.Trace[tgui.TActive].FDrawList) - 1:
				break
			var klist = tgui.Trace[tgui.TActive].FDrawList[klistindex]
			korv_count += len(klist)
			if len(klist) > 0:
					var length = len (klist)
					var step = 1
					if not tgui.LossLess:
						step = 3
					# Skip entries to the left
					var j = 0
					var fictive = {tend = tgui.Trace[tgui.TActive].TimeSpanStart}
					j = klist.bsearch_custom(fictive, _compare_end)
					while j < length:
						var korv = klist[j]
						var core = int(korv.core)
						var color
						# Show this core?
						if core not in Cores[tgui.TActive]:
							j += 1
							continue
						else:
							color = Colors[core]

						# skip entries to the right
						if korv.tstart > tgui.Trace[tgui.TActive].TimeSpanEnd:
							break
						if _in_sight(korv):
							var ratio = float(Width / tgui.Trace[tgui.TActive].TimeSpan)
							var x_start = int((korv.tstart - tgui.Trace[tgui.TActive].TimeSpanStart) * ratio)
							if x_start < 0:
								x_start = 0
							var width = int((korv.tend - tgui.Trace[tgui.TActive].TimeSpanStart) * ratio - x_start)
							if width > Width:
								width = Width
							var y_start = int(line_height * func_count + 3)
							mutex.lock()
							draw_rect(Rect2(x_start, y_start, width, line_height - 6), color, false)
							mutex.unlock()
							rect_count += 1
							# Find next entry for this function that shall be drawn in next x position
							var next_pix_time = int((float(x_start) + step) / ratio + tgui.Trace[tgui.TActive].TimeSpanStart)
							fictive = {tend = next_pix_time}
							var tmpj = klist.bsearch_custom(fictive, _compare_end)
							if tmpj > j:
								j = tmpj
								continue
						j += 1
			func_count += 1

func _draw_from_core_list():
	if _timeline_inited:
		var num_draw_cores = OS.get_processor_count() - 2
		var num_trace_cores = len(Cores[tgui.TActive])
		var trace_cores_per_draw_core = num_trace_cores / num_draw_cores
		if trace_cores_per_draw_core == 0:
			trace_cores_per_draw_core = num_trace_cores
		var thread_count = 0
		var threadlist = []
		var trace_core_count = 0

		# Set vscroll size
		var page = int(FChartPanel.size.y / tgui.FNameText.get_line_offset(1))
		tgui.FuncVScrollBar.max_value = num_trace_cores
		tgui.FuncVScrollBar.page = page

		print("num_draw_cores			: " + str(num_draw_cores))
		print("num_trace_cores			: " + str(num_trace_cores))
		print("trace_cores_per_draw_core: " + str(trace_cores_per_draw_core))
		print("thread_count				: " + str(thread_count))
		print("trace_core_count			: " + str(trace_core_count))

		while trace_core_count < num_trace_cores:
			var thread = Thread.new()
			if (num_trace_cores - trace_core_count) < trace_cores_per_draw_core:
				thread.start(_worker_cores.bind(thread_count, trace_core_count, num_trace_cores ))
#				_worker(thread_count, func_count, num_funcs )
			else:
				thread.start(_worker_cores.bind(thread_count, trace_core_count, trace_core_count + trace_cores_per_draw_core))
#				_worker(thread_count, func_count, func_count + funcs_per_core)
			thread_count += 1
			trace_core_count += trace_cores_per_draw_core
			threadlist.append(thread)
		for t in threadlist:
			t.wait_to_finish()

		if tgui.SearchShowAll:
			var count = tgui.Trace[tgui.TActive].FindAllMarkers.bsearch(tgui.Trace[tgui.TActive].TimeSpanStart) - 1
			if count < 0:
				count = 0
			while count < len(tgui.Trace[tgui.TActive].FindAllMarkers):
				var ts = tgui.Trace[tgui.TActive].FindAllMarkers[count]
				if ts > tgui.Trace[tgui.TActive].TimeSpanEnd:
					break
				var Width = float(Box.size.x)
				if _find_all_marker_in_sight(ts):
					var xpos = (ts - tgui.Trace[tgui.TActive].TimeSpanStart) * ( Width / tgui.Trace[tgui.TActive].TimeSpan)
					draw_rect(Rect2(xpos, 0, 1, Box.size.y), Color("208bb5"), false)
				count += 1

func _draw_from_core_list_interval(indstart, indend):
	if _timeline_inited:
		# Prevent from getting to a state we cant zoom out from
		if tgui.Trace[tgui.TActive].TimeSpan < 10:
			tgui.Trace[tgui.TActive].TimeSpanStart = tgui.Trace[tgui.TActive].TimeSpanEnd - 10
			if tgui.Trace[tgui.TActive].TimeSpanStart < tgui.Trace[tgui.TActive].TimeStart:
				tgui.Trace[tgui.TActive].TimeSpanStart += 10
				tgui.Trace[tgui.TActive].TimeSpanEnd += 10
			tgui.Trace[tgui.TActive].TimeSpan = 10

		var Width = float(Box.size.x)
		var line_height = tgui.FNameText.get_line_offset(1)
		var trace_core_count = indstart
		var rect_count = 0
		var box_list = []
		var dubbla = 0
		for klistindex in range(indstart, indend):
			if klistindex > len(tgui.Trace[tgui.TActive].FTree) - 1:
				break
			var klist = tgui.Trace[tgui.TActive].FTree[klistindex]
			if len(klist) > 0:
					var length = len (klist)
					var step = 1
					if not tgui.LossLess:
						step = 3
					# Skip entries to the left
					var j = 0
					var fictive = {tend = tgui.Trace[tgui.TActive].TimeSpanStart}
					j = klist.bsearch_custom(fictive, _compare_end)
					while j < length:
						var korv = klist[j]
						var core = klistindex
						var color
						# Show this core?
						if core not in Cores[tgui.TActive]:
							j += 1
							continue
						else:
							color = Colors[korv.index % 256]

						# skip entries to the right
						if korv.tstart > tgui.Trace[tgui.TActive].TimeSpanEnd:
							break
						if _in_sight(korv):
							var ratio = float(Width / tgui.Trace[tgui.TActive].TimeSpan)
							var x_start = int((korv.tstart - tgui.Trace[tgui.TActive].TimeSpanStart) * ratio)
							if x_start < 0:
								x_start = 0
							var width = int((korv.tend - tgui.Trace[tgui.TActive].TimeSpanStart) * ratio - x_start)
							if width > Width:
								width = Width
							var y_start = int(line_height * core + 3)
							var stringwidth = int(width / FuncFontCharWidth)
							var korvstring = tgui.Trace[tgui.TActive].FList[korv.index].substr(0, stringwidth)
							mutex.lock()
							draw_rect(Rect2(x_start, y_start, width, line_height - 6), color, false)
							if width > FuncFontMinWidth:
								draw_string(FuncFont, Vector2(x_start, y_start + 12), korvstring, 0, -1, 10)
							mutex.unlock()
							rect_count += 1
							# Find next entry for this function that shall be drawn in next x position
							var next_pix_time = int((float(x_start) + step) / ratio + tgui.Trace[tgui.TActive].TimeSpanStart)
							fictive = {tend = next_pix_time}
							var tmpj = klist.bsearch_custom(fictive, _compare_end)
							if tmpj > j:
								j = tmpj
								continue
						j += 1

func _old_draw_from_core_list():
	if _timeline_inited:
		var box_list = []
		var Width = Box.size.x
		var line_height = tgui.FNameText.get_line_offset(1)
		for i in len(Cores[tgui.TActive]):
			var core = Cores[tgui.TActive][i]
			var color = Colors[Cores[tgui.TActive][i]]
			if tgui.Trace[tgui.TActive].FTree[core] != null:
					var length = len (tgui.Trace[tgui.TActive].FTree[core])
					var step
					if tgui.LossLess:
						step = 1
					else:
						# Downsampling for large traces
						var zoom = float(tgui.Trace[tgui.TActive].TimeSpan) /  (tgui.Trace[tgui.TActive].TimeEnd - tgui.Trace[tgui.TActive].TimeStart)
						step = int((length * zoom * 10) / (Width))
						if step < 1:
							step = 1
					# Skip entries to the left
					var j = 0
					var fictive = {tend = tgui.Trace[tgui.TActive].TimeSpanStart}
					j = tgui.Trace[tgui.TActive].FTree[core].bsearch_custom(fictive, _compare_end)
					while j < length:
						var korv = tgui.Trace[tgui.TActive].FTree[core][j]
						# skip entries to the right
						if korv.tstart > tgui.Trace[tgui.TActive].TimeSpanEnd:
							break
						if _in_sight(korv):
							var x_start = (korv.tstart - tgui.Trace[tgui.TActive].TimeSpanStart) * ( Width / tgui.Trace[tgui.TActive].TimeSpan)
							if x_start < 0:
								x_start = 0
							var width = (korv.tend - tgui.Trace[tgui.TActive].TimeSpanStart) * ( Width / tgui.Trace[tgui.TActive].TimeSpan) - x_start
							if width > Width:
								width = Width
							var y_start = line_height * (korv.index) + 3
							x_start = int(x_start)
							y_start = int(y_start)
							width = int(width)
							var box_id = x_start + 1000000 * y_start + 2000000 * width
							if not box_id in box_list:
								draw_rect(Rect2(x_start, y_start, width, line_height - 6), color, false)
								box_list.append(box_id)
						j += step

func _draw():
	if _timeline_inited and len(tgui.Trace) > 0:
#		tgui.TimerStart()

		if not tgui.Trace[tgui.TActive].FuncPerCore:
			_draw_from_func_list()
		else:
			_draw_from_core_list()

# Other ways to draw fchart single-core
#		_draw_from_func_list_interval(0, len(tgui.Trace[tgui.TActive].FDrawList))
#	_draw_from_core_list()
#		tgui.TimerEnd()

func InitTimeLine(node, box):
	print("FCHart init timeline")
	if tgui == null:
		tgui = node
	if Box == null:
		Box = box

	tgui.FNameText.text = ""
	if not tgui.Trace[tgui.TActive].FuncPerCore:
		for i in range(len(tgui.Trace[tgui.TActive].FList)):
			tgui.FNameText.text += tgui.Trace[tgui.TActive].FList[i] + "\n"
	else:
		for i in range(len(tgui.Trace[tgui.TActive].CoreList)):
			tgui.FNameText.text += "Core " + str(tgui.Trace[tgui.TActive].CoreList[i]) + "\n"

	_timeline_inited = true
	print("FCHart init timeline done")

func UpdateTimeLine():
	if _timeline_inited:
		tgui.FNameText.scroll_to_line(tgui.Trace[tgui.TActive].FuncVScrollBarIndex)
		var title = "Visible cores: "
		if not tgui.Trace[tgui.TActive].FuncPerCore:
			for i in len(Cores[tgui.TActive]):
				title = title + "  " + TextColor[Cores[tgui.TActive][i]] + str(Cores[tgui.TActive][i])
		else:
			for i in len(Cores[tgui.TActive]):
				title = title + " " + str(Cores[tgui.TActive][i])

		TitleText.text = title
		queue_redraw()

func UpdateScrollPosition():
	if _timeline_inited:
		var line_height = tgui.FNameText.get_line_offset(1)
		tgui.FNameText.scroll_to_line(tgui.Trace[tgui.TActive].FuncVScrollBarIndex)

		# Function or core centric view?
		if not tgui.Trace[tgui.TActive].FuncPerCore:
			if len(tgui.Trace[tgui.TActive].FList) >= (tgui.Trace[tgui.TActive].FuncVScrollBarIndex + tgui.FNameText.get_visible_line_count()):
				tgui.FChart.position.y = 0 - tgui.Trace[tgui.TActive].FuncVScrollBarIndex * line_height
		else:
			if tgui.Trace[tgui.TActive].NumCores >= (tgui.Trace[tgui.TActive].FuncVScrollBarIndex + tgui.FNameText.get_visible_line_count()):
				tgui.FChart.position.y = 0 - tgui.Trace[tgui.TActive].FuncVScrollBarIndex * line_height

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
	if Input.is_physical_key_pressed(KEY_CTRL):
		tgui.RulerActive = true
	FMarkers.ActivateDrawZoom(get_local_mouse_position().x)
	ZoomStart = _get_time_from_xpos(FMarkers.GetZoomWindow().start)
	ZoomEnd = ZoomStart

# This happens when a new zoom window is created
func MouseRightReleased():

	print("FCHart set zoom")
	FMarkers.DeactivateDrawZoom()

	# Only ruler?
	if tgui.RulerActive == true:
		tgui.RulerActive = false
		return

	var tmpstart = _get_time_from_xpos(FMarkers.GetZoomWindow().start)
	var tmpend = _get_time_from_xpos(FMarkers.GetZoomWindow().end)

	if tmpstart < tgui.Trace[tgui.TActive].TimeStart:
		tmpstart = tgui.Trace[tgui.TActive].TimeStart

	if tmpend > tgui.Trace[tgui.TActive].TimeEnd:
		tmpend = tgui.Trace[tgui.TActive].TimeEnd

	tgui.StoreTimespan()

	tgui.Trace[tgui.TActive].TimeSpanStart = int(tmpstart)
	tgui.Trace[tgui.TActive].TimeSpanEnd = int(tmpend)
	tgui.Trace[tgui.TActive].TimeSpan = int(tmpend - tmpstart)

	tgui.UpdateTimeLine()
	tgui.UpdateMarkers()

func MouseMoved():
	var pos = get_local_mouse_position().x
	FMarkers.UpdateZoomWindow(pos)
	ZoomEnd = _get_time_from_xpos(pos)
	UpdateMarkers()

func MouseWheelUp():
	if tgui.FuncVScrollBar.value > tgui.FuncVScrollBar.min_value:
		tgui.FuncVScrollBar.value -= 1

func MouseWheelDown():
	if tgui.FuncVScrollBar.value < tgui.FuncVScrollBar.max_value:
		tgui.FuncVScrollBar.value += 1
