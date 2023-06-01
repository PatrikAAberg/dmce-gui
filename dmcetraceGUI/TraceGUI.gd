extends Control

var debcnt = 0

# defines
var TRACE_VIEW_HEIGHT = 10
var TRACE_PAGESIZE = 20
var TRACE = 1
var INFO = 2
var SRC = 4
var VARS = 8
var ZOOM_SHRINK = 0.1
var ZOOM_SHRINK_MIN = 100
var CORE_KORV_HEIGHT = 16

# gloabls
var ShowCoreChartGrid = true
var TChartXOffset = 50
var InitDone = false
var VSplitTop = 0.25
var HSplitTop = 0.8
var HSplitBot = 0.75
var VSplitBot = 0.5
var TActive = 0
var Trace = []
var TraceViews = []
var PSPACE = 10
var SSPACE = PSPACE * 2
var VSplitCTop
var HSplitCTop
var HSplitCBot
var VSplitCBot
var Background
var TraceTab
var TraceView
var TraceViewScrollBar
var SrcView
var VarsView
var SrcTab
var VarsTab
var TChart
var TChartBox
var TMarkers
var TCoreLabels
var TChartTab
var FChart
var FChartBox
var FMarkers
var FTab
var FuncVScrollBar
var FuncVScrollBarIndex = 0
var FNameText
var MenuFile
var MenuView
var MenuSearch
var MenuHelp
var FindLineEdit
var OpenTraceDialog
var AllCoresButton
var FindNextButton
var FindPrevButton
var re_remove_probe
var TraceViewStart
var TraceViewEnd
var TraceViewScrollTop = 999999999
var TraceViewVisibleLines = 0
var SrcViewVisibleLines = 0
var SrcCache = {}
var ShowProbes = false
var PrevSrcView = ""

func RemoveProbe(str):
	if ShowProbes:
		pass
	else:
		str = re_remove_probe.sub(str,"")
		var pcnt = 0
		var found = -1
		for pos in range(len(str)):
			if str[pos] == '(':
				pcnt += 1
			elif str[pos] == ')':
				pcnt -=1
			if pcnt < 0:
				found = pos
				break
		if found != -1:
			str = str.left(found) + str.right(len(str) - found - 1)
	return str

func ReadSrc(filename):
	var line
	var sourcelines = PackedStringArray([])
	var f
	if filename in SrcCache:
		return SrcCache[filename]

	f = FileAccess.open(filename, FileAccess.READ)
	if f == null:
		sourcelines.append("Unable to load " + filename)
	else:
		while not f.eof_reached(): # iterate through all lines until the end of file is reached
			line = f.get_line()
			sourcelines.append(line.replace("[", "[lb]")) # escape bbcode on the fly
		f.close()
	SrcCache["filename"] = sourcelines
	return sourcelines

func SplitTraceLine(tline):
	var a = tline.split("@")
	var core = a[0]
	var ts = a[1]
	var path = a[2]
	var line = a[3]
	var fun = a[4]
	var src = RemoveProbe(a[5])
	var vars = a[6].split(" ")
	return {"core":core, "ts":ts, "path":path, "line":line, "fun":fun, "src":src, "vars":vars}

func PopulateViews(view):
	var D
	# Trace view
	if view & TRACE:

		# Adjust sub-trace-window
		if Trace[TActive].index > TRACE_VIEW_HEIGHT:
			TraceViewStart = Trace[TActive].index - TRACE_VIEW_HEIGHT
		else:
			TraceViewStart = 0
		if Trace[TActive].index <= (Trace[TActive].INDEX_MAX - TRACE_VIEW_HEIGHT):
			TraceViewEnd = Trace[TActive].index + TRACE_VIEW_HEIGHT
		else:
			TraceViewEnd = Trace[TActive].INDEX_MAX

		TraceViews[TActive].clear()
		var tracetext = ""
		for i in range(TraceViewStart, TraceViewEnd + 1):
			#TraceView.append_text(tracebuffer[i] + "\n")
			D = SplitTraceLine(Trace[TActive].tracebuffer[i])
			var out = str(i) + " " + D.core + " " + D.ts + " " + D.path + " " + D.fun + " " + D.line + " " + D.src
			if i == Trace[TActive].index:
				#TraceView.append_text("[bgcolor=#208bb5][url={\"data\"=\"" + str(i) + "\"}]" + out + "[/url][/bgcolor]\n")
#				tracetext += "[bgcolor=#208bb5][url={\"data\"=\"" + str(i) + "\"}]" + out + "[/url][/bgcolor]\n"
				tracetext += "[bgcolor=#208bb5][url=" + str(i) + "]" + out + "[/url][/bgcolor]\n"
			else:
#				tracetext += "[url={\"data\"=\"" + str(i) + "\"}]" + out + "[/url]\n"
				tracetext += "[url=" + str(i) + "]" + out + "[/url]\n"
		TraceViews[TActive].append_text(tracetext)
		TraceViews[TActive].scroll_to_line(TraceViewScrollTop - TraceViewStart)

	# Source View
	if view & SRC:
		SrcView.clear()
		D = SplitTraceLine(Trace[TActive].tracebuffer[Trace[TActive].index])
		var slines = ReadSrc(D.path)
		var lnbr = 0
		var srclnbr = int(D.line.replace("+",""))
		for line in slines:
			lnbr += 1
			line =  str(lnbr) + "  " + RemoveProbe(line)
			if srclnbr == lnbr:
				line = "[bgcolor=#208bb5]" + line + "[/bgcolor]"
			else:
				line = line.replace("[", "[lb]")
			SrcView.append_text(line + "\n")
		var srctop = srclnbr - (SrcViewVisibleLines / 2) + 2
		if srctop < 0:
			srctop = 0
		SrcView.scroll_to_line(srctop)

	# Variables View
		VarsView.clear()
		for v in D.vars:
			VarsView.append_text(v.replace("[", "[lb]") + "\n")

func FTreeInit(trace):
	trace.FTree = []
	trace.FList = []
	for i in range(512):
		trace.FTree.append(null)
	return trace

func FTreeInsert(trace, core, ts, pathfunc):
	# Keep global index for all functions
	var ind
	if not pathfunc in trace.FList:
		trace.FList.append(pathfunc)
		ind = len(trace.FList) - 1
	else:
		ind = trace.FList.find(pathfunc,0)

	if trace.FTree[core] == null:
		# First entry
		trace.FTree[core] = [{"tstart"=ts, "tend"=ts, "pathfunc"=pathfunc, "index"=ind}]
	else:
		# Check if we switch function
		if trace.FTree[core][len(trace.FTree[core]) - 1].pathfunc == pathfunc:
			trace.FTree[core][len(trace.FTree[core]) - 1].tend = ts
		else:
			trace.FTree[core].append({"tstart"=ts, "tend"=ts, "pathfunc"=pathfunc, "index"=ind})
	return trace

func LoadTrace(path):
	var file = path
	var clist = []
	var record = 0
	var tracetmp = {}
	tracetmp.TraceInfo = PackedStringArray([])
	tracetmp.tracebuffer = PackedStringArray([])
	tracetmp.TimeLineCore = []
	tracetmp.TimeLineTS = []
	tracetmp = FTreeInit(tracetmp)

	var f = FileAccess.open(file, FileAccess.READ)
	while not f.eof_reached(): # iterate through all lines until the end of file is reached
		var line = f.get_line()
		if record and line.count("@") > 5: # make sure all fields are there
			var core = int(line.split("@")[0])
			var ts = int(line.split("@")[1])
			var pathfunc = line.split("@")[2] + ":" + line.split("@")[4]
			tracetmp.tracebuffer.append(line.replace("[", "[lb]")) # escape bbcode on the fly
			tracetmp.TimeLineCore.append(core)
			tracetmp.TimeLineTS.append(ts)
			tracetmp = FTreeInsert(tracetmp, core, ts, pathfunc)
			if core not in clist:
				clist.append(core)
		if "- - - - -" in line:
			record = 1
		elif not record:
			tracetmp.TraceInfo.append(line)
	f.close()
	tracetmp.NumCores = len(clist)
	tracetmp.CoreMax = clist.max()
	tracetmp.INDEX_MAX = len(tracetmp.tracebuffer) - 1
	tracetmp.TimeStart = tracetmp.TimeLineTS[0]
	tracetmp.TimeEnd = tracetmp.TimeLineTS[tracetmp.INDEX_MAX]
	tracetmp.index = tracetmp.INDEX_MAX
	TraceViewEnd = tracetmp.index
	if tracetmp.index > TRACE_VIEW_HEIGHT:
		TraceViewStart = tracetmp.index - TRACE_VIEW_HEIGHT
	else:
		TraceViewStart = 0
	Trace.append(tracetmp)
	TActive = len(Trace) - 1
	file  = file.replace("/", "\\")
	file  = file.replace(".", ",")
	file = file + "  "
	var tabtmp = TraceView.duplicate()
	tabtmp.name = file
	tabtmp.visible = true
	tabtmp.meta_clicked.connect(self._trace_view_meta_clicked)
	TraceViews.append(tabtmp)
	TraceTab.add_child(tabtmp)
	TraceTab.current_tab = TActive
	print("Loaded view " + str(len(TraceViews) - 1 ))
	_reset_timespan()
	InitTimeLine()
	InitMarkers()
	PopulateViews(TRACE | INFO | SRC)
	TCoreLabels.Init(self)
	_show_all_cores(TActive)

func _reset_timespan():
	Trace[TActive].TimeSpanStart = Trace[TActive].TimeStart
	Trace[TActive].TimeSpanEnd = Trace[TActive].TimeLineTS[len(Trace[TActive].TimeLineTS) - 1]
	Trace[TActive].TimeSpan = Trace[TActive].TimeSpanEnd - Trace[TActive].TimeSpanStart

func _ready():
	# Node handles
	VSplitCTop 		= get_node("Background/VSplitTop")
	HSplitCTop 		= get_node("Background/VSplitTop/myHSplitContainerTop")
	VSplitCBot		= get_node("Background/VSplitTop/VSplitBot")
	TChart 			= get_node("Background/VSplitTop/VSplitBot/TChartTab/TChartPanel/TChart")
	TMarkers 		= get_node("Background/VSplitTop/VSplitBot/TChartTab/TChartPanel/TMarkers")
	TChartBox 		= get_node("Background/VSplitTop/VSplitBot/TChartTab/TChartPanel")
	TCoreLabels		= get_node("Background/VSplitTop/VSplitBot/TChartTab/TChartPanel/TCoreLabels")
	TChartTab		= get_node("Background/VSplitTop/VSplitBot/TChartTab")
	FChart 			= get_node("Background/VSplitTop/VSplitBot/FuncTab/FuncContainer/FuncHBoxContainer/HSplitFNameFCHart/FChartPanel/FChart")
	FMarkers 		= get_node("Background/VSplitTop/VSplitBot/FuncTab/FuncContainer/FuncHBoxContainer/HSplitFNameFCHart/FChartPanel/FMarkers")
	FChartBox 		= get_node("Background/VSplitTop/VSplitBot/FuncTab/FuncContainer/FuncHBoxContainer/HSplitFNameFCHart/FChartPanel")
	FTab 			= get_node("Background/VSplitTop/VSplitBot/FuncTab")
	FuncVScrollBar 	= get_node("Background/VSplitTop/VSplitBot/FuncTab/FuncContainer/FuncHBoxContainer/FuncVScrollBar")
	FNameText		= get_node("Background/VSplitTop/VSplitBot/FuncTab/FuncContainer/FuncHBoxContainer/HSplitFNameFCHart/FNameText")
	Background 		= get_node("Background")
	TraceTab		= get_node("Background/VSplitTop/myHSplitContainerTop/TraceTab")
	TraceView 		= get_node("TraceView")
	SrcView 		= get_node("Background/VSplitTop/myHSplitContainerTop/HSplitSrcVars/SrcTab/SrcView")
	VarsView 		= get_node("Background/VSplitTop/myHSplitContainerTop/HSplitSrcVars/VarsTab/VarsView")
	SrcTab 			= get_node("Background/VSplitTop/myHSplitContainerTop/HSplitSrcVars/SrcTab")
	VarsTab 		= get_node("Background/VSplitTop/myHSplitContainerTop/HSplitSrcVars/VarsTab")
	MenuFile 		= get_node("MenuBar/PopupMenuFile")
	MenuView 		= get_node("MenuBar/PopupMenuView")
	MenuSearch 		= get_node("MenuBar/PopupMenuSearch")
	MenuHelp 		= get_node("MenuBar/PopupMenuHelp")
	OpenTraceDialog = get_node("OpenTraceDialog")
	AllCoresButton  = get_node("Background/VSplitTop/VSplitBot/VBoxContainerTchartButtons/HBoxContainerTChartButtons/AllCoresButton")
	FindLineEdit	= get_node("FindLineEdit")
	FindNextButton	= get_node("FindNextButton")
	FindPrevButton	= get_node("FindPrevButton")
	re_remove_probe = RegEx.new()
	re_remove_probe.compile("\\(DMCE_PROBE.*?\\),")      #\d*(.*?),")
	print("Control root started")

	# Debug
	# get_tree().quit()
	# signals
	VSplitCTop.dragged.connect(self._dragged)
	HSplitCTop.dragged.connect(self._dragged)
	VSplitCBot.dragged.connect(self._dragged)
#	Background.resized.connect(self._resized)
	MenuFile.id_pressed.connect(self._menu_file_pressed)
	MenuView.id_pressed.connect(self._menu_view_pressed)
	MenuSearch.id_pressed.connect(self._menu_search_pressed)
	MenuHelp.id_pressed.connect(self._menu_help_pressed)
	FuncVScrollBar.scrolling.connect(self._funcvscrollbar_scrolling)
	TraceTab.tab_changed.connect(self._trace_tab_changed)
	OpenTraceDialog.file_selected.connect(self._open_trace_selected)
	FindLineEdit.text_submitted.connect(self._find_text_submitted)
	FindNextButton.pressed.connect(self._find_next_button_pressed)
	FindPrevButton.pressed.connect(self._find_prev_button_pressed)

	# Initial state
	print(OS.get_cmdline_args())
	if len(OS.get_cmdline_args()) > 0 and OS.get_cmdline_args()[0] != "res://TraceGUI.tscn":
		LoadTrace(OS.get_cmdline_args()[0])
		_show_all_cores(0)
	else:
		print("No trace loaded from args")
#		LoadTrace('/home/patrik/agtrace/dmce-trace-ag.log')
		# dev state, uncomment for release:
		LoadTrace('/home/patrik/agtrace/dmce-trace-ex.log')
		_show_all_cores(0)

	TChartTab.set_tab_title(0, "Cores")
	FTab.set_tab_title(0, "Functions")
	SrcTab.set_tab_title(0, "Source")
	VarsTab.set_tab_title(0, "Variables")

	$MenuBar/PopupMenuFile.name = " File "
	$MenuBar/PopupMenuView.name = " View "
	$MenuBar/PopupMenuSearch.name = " Search "
	$MenuBar/PopupMenuHelp.name = " Help "

func _find_next_button_pressed():
	print("Find Next!")

func _find_prev_button_pressed():
	print("Find Prev!")

func _find_text_submitted(text):
	print(text)
	FindLineEdit.release_focus()

func _show_all_cores(ind):
	FChart.ClearCores(ind)
	for i in range(Trace[TActive].CoreMax + 1):
		FChart.AddCore(i, ind)
	UpdateTimeLine()

func _hide_all_cores(ind):
	FChart.ClearCores(ind)
	UpdateTimeLine()

func _trace_tab_changed(tab):
		SetActiveTrace(tab)

func _dragged(offset):
	VSplitTop =  VSplitCTop.split_offset / VSplitCTop.size.y
	HSplitTop = HSplitCTop.split_offset / HSplitCTop.size.x
	VSplitBot = VSplitCBot.split_offset / VSplitCBot.size.y
	if len(Trace) > 0:
		UpdateTimeLine()
		UpdateMarkers()

func _resized():
	# Top "pane"
	FindLineEdit.size.x =  Background.size.x / 4
	FindLineEdit.position.x =  Background.size.x - (Background.size.x / 4) - (FindNextButton.size.x * 2 + 5 + 5 + 8)

	FindNextButton.position.x =  FindLineEdit.position.x + FindLineEdit.size.x + 5
	FindPrevButton.position.x =  FindNextButton.position.x + FindNextButton.size.x + 5
	FindNextButton.position.y =  3
	FindPrevButton.position.y =  3

	VSplitCTop.split_offset = VSplitCTop.size.y * VSplitTop
	HSplitCTop.split_offset = HSplitCTop.size.x * HSplitTop
	VSplitCBot.split_offset = VSplitCBot.size.y * VSplitBot

	if len(Trace) > 0:
		UpdateTimeLine()
		UpdateMarkers()
		PopulateViews(TRACE | INFO | SRC)
	ResizeState = 0

# Since window class does not seem to have a resize signal
# and all underlaying box sizes seems to update at different times
# we need to keep track of changes to box sizes

var ResizeState = 0     # 0 = no change, 1 = change ongoing, 2 = change done, wait for redraw
var current_app_window_size = ""
var TChartBox_cursize = ""
var FChartBox_cursize = ""
var TraceView_cursize = ""
var SrcView_cursize = ""
var VarsView_cursize = ""

func _get_resize_state():
	# Update main panel size and position
	var appsize = get_tree().root.size
	var apppos = Vector2(0,0)
	if current_app_window_size != str(appsize):
		current_app_window_size = str(appsize)
		Background.size = appsize
		Background.position = apppos

	# Check for state changes
	var any_change = false

	if str(TChartBox.size) != TChartBox_cursize:
		TChartBox_cursize = str(TChartBox.size)
		any_change = true
	if str(FChartBox.size) != FChartBox_cursize:
		FChartBox_cursize = str(FChartBox.size)
		any_change = true
	if str(TraceView.size) != TraceView_cursize:
		TraceView_cursize = str(TraceView.size)
		any_change = true

	if ResizeState == 0 and any_change:
		ResizeState = 1
	elif ResizeState == 1 and not any_change:
		ResizeState = 2
	return ResizeState

func _process(delta):
	# Initial setup
	if not InitDone:
		InitDone = true

	# Periodical update of state
	if len(TraceViews) > 0:
		TraceViewVisibleLines  = TraceViews[TActive].get_visible_line_count()
	SrcViewVisibleLines  = SrcView.get_visible_line_count()

	if _get_resize_state() == 2:
		_resized()

func InitTimeLine():
	TChart.InitTimeLine(self, TChartBox)
	FChart.InitTimeLine(self, FChartBox)

func InitMarkers():
	TMarkers.InitMarkers(self, TChartBox)
	FMarkers.InitMarkers(self, FChartBox)

func UpdateTimeLine():
	TChart.UpdateTimeLine()
	FChart.UpdateTimeLine()

func UpdateMarkers():
	TChart.UpdateMarkers()
	FChart.UpdateMarkers()

func trace_up():
	if Trace[TActive].index > 0:
		Trace[TActive].index -= 1
		# Adjust scrollbar?
		if Trace[TActive].index < TraceViewScrollTop:
			TraceViewScrollTop = Trace[TActive].index
		PopulateViews(TRACE)

func trace_down():
	if Trace[TActive].index < Trace[TActive].INDEX_MAX:
		Trace[TActive].index += 1
		if Trace[TActive].index > (TraceViewScrollTop + TraceViewVisibleLines - 2):
			TraceViewScrollTop = Trace[TActive].index - TraceViewVisibleLines + 2
		PopulateViews(TRACE)

func trace_up_ctrl():
	if Trace[TActive].index > 0:
		# Search for same core upwards
		var D = SplitTraceLine(Trace[TActive].tracebuffer[Trace[TActive].index])
		var curcore = D.core
		var i = Trace[TActive].index - 1
		var found = false
		while i >= -1:
			D = SplitTraceLine(Trace[TActive].tracebuffer[i])
			if D.core == curcore:
				found = true
				break
			i -= 1
		if found:
			Trace[TActive].index = i
		# Adjust scrollbar?
		if Trace[TActive].index < TraceViewScrollTop:
			TraceViewScrollTop = Trace[TActive].index
		PopulateViews(TRACE)

func trace_down_ctrl():
	if Trace[TActive].index < Trace[TActive].INDEX_MAX:
		# Search for same core upwards
		var D = SplitTraceLine(Trace[TActive].tracebuffer[Trace[TActive].index])
		var curcore = D.core
		var i = Trace[TActive].index + 1
		var found = false
		while i <= Trace[TActive].INDEX_MAX:
			D = SplitTraceLine(Trace[TActive].tracebuffer[i])
			if D.core == curcore:
				found = true
				break
			i += 1
		if found:
			Trace[TActive].index = i
		# Adjust scrollbar?
		if Trace[TActive].index > (TraceViewScrollTop + TraceViewVisibleLines - 2):
			TraceViewScrollTop = Trace[TActive].index - TraceViewVisibleLines + 2
		PopulateViews(TRACE)

func trace_pup():
	if Trace[TActive].index > TRACE_PAGESIZE:
		Trace[TActive].index -= TRACE_PAGESIZE
		TraceViewScrollTop = Trace[TActive].index - int(TraceViewVisibleLines / 2)
		PopulateViews(TRACE)

func trace_pdown():
	if Trace[TActive].index < (Trace[TActive].INDEX_MAX - TRACE_PAGESIZE):
		Trace[TActive].index += TRACE_PAGESIZE
		TraceViewScrollTop = Trace[TActive].index - int(TraceViewVisibleLines / 2)
		PopulateViews(TRACE)

func _in_tchart(pos):
	if TChart.get_local_mouse_position().y  > 0 and TChart.get_local_mouse_position().x >= TChartXOffset:
		return true
	return false

func _in_corelist(pos):
	if TChartBox.get_local_mouse_position().y  > 0 and TChartBox.get_local_mouse_position().x < TChartXOffset:
		return true
	return false

func _in_fchart(pos):
	if FChartBox.get_local_mouse_position().y  > 0 and FChartBox.get_local_mouse_position().y < FChartBox.size.y:
		return true
	return false

var KEY_CTRL = 4194326

func _input(ev):
	if  len(Trace) == 0:
		return
	if ev is InputEventKey:
		if ev.pressed:
			if Input.is_physical_key_pressed(KEY_CTRL):
				if ev.keycode == KEY_UP:
					trace_up_ctrl()
				elif ev.keycode == KEY_DOWN:
					trace_down_ctrl()
				elif ev.keycode == KEY_PAGEUP:
					trace_pup()
				elif ev.keycode == KEY_PAGEDOWN:
					trace_pdown()
			else:
				if ev.keycode == KEY_UP:
					trace_up()
				elif ev.keycode == KEY_DOWN:
					trace_down()
				elif ev.keycode == KEY_PAGEUP:
					trace_pup()
				elif ev.keycode == KEY_PAGEDOWN:
					trace_pdown()

			if ev.keycode == KEY_ESCAPE:
				get_tree().quit()
			elif ev.keycode == KEY_P:
				if ShowProbes == false:
					ShowProbes = true
				else:
					ShowProbes = false
				PopulateViews(TRACE | SRC)
			elif ev.keycode == KEY_G:
				ToggleShowCoreChartGrid()
			elif ev.keycode == KEY_Z:
				_reset_timespan()
				InitTimeLine()
				InitMarkers()
				UpdateTimeLine()
				UpdateMarkers()
			elif ev.keycode == KEY_SPACE:
				print("DEB " + str(debcnt))
				debcnt += 1
				deb_func()
		else:
			PopulateViews(SRC | INFO)
			UpdateMarkers()

	if ev is InputEventMouseButton and (_in_tchart(ev.position) or _in_fchart(ev.position) ):
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP and ev.pressed:
			TChart.MouseWheelUp()
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN and ev.pressed:
			TChart.MouseWheelDown()

	if ev is InputEventMouseButton and _in_tchart(ev.position):
		if ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			TChart.MouseLeftPressed()
		elif ev.button_index == MOUSE_BUTTON_RIGHT and ev.pressed:
			TChart.MouseRightPressed()
		elif ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed:
			TChart.MouseLeftReleased()
		elif ev.button_index == MOUSE_BUTTON_RIGHT and not ev.pressed:
			TChart.MouseRightReleased()

	if ev is InputEventMouseMotion and _in_tchart(ev.position):
		TChart.MouseMoved()

	if ev is InputEventMouseButton and _in_corelist(ev.position):
		if ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			TCoreLabels.MouseLeftPressed()

	if ev is InputEventMouseButton and _in_fchart(ev.position):
		if ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			FChart.MouseLeftPressed()
		elif ev.button_index == MOUSE_BUTTON_RIGHT and ev.pressed:
			FChart.MouseRightPressed()
		elif ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed:
			FChart.MouseLeftReleased()
		elif ev.button_index == MOUSE_BUTTON_RIGHT and not ev.pressed:
			FChart.MouseRightReleased()

	if ev is InputEventMouseMotion and _in_fchart(ev.position):
		FChart.MouseMoved()

func ToggleShowCoreChartGrid():
	if ShowCoreChartGrid == false:
		ShowCoreChartGrid = true
	else:
		ShowCoreChartGrid = false
	UpdateTimeLine()
	UpdateMarkers()

func _trace_view_meta_clicked(meta):
	Trace[TActive].index = int(meta)
	TraceViewScrollTop = Trace[TActive].index - int(TraceViewVisibleLines / 2)
	PopulateViews(SRC | INFO | TRACE)

func _open_trace():
	OpenTraceDialog.visible = true

func _menu_file_pressed(id):
	if id == 0:
		_open_trace()
	elif id == 1:
		print("File: Options" + str(id))
	elif id == 2:
		get_tree().quit()

func _menu_view_pressed(id):
	print("View: " + str(id))
	if id == 0:
		_show_all_cores(TActive)
	elif id == 1:
		_hide_all_cores(TActive)
	elif id == 2:
		ToggleShowCoreChartGrid()

func _menu_search_pressed(id):
	print("View: " + str(id))
	if id == 0:
		print("Find!")
	elif id == 1:
		print("Find Next!")
	elif id == 2:
		print("Find Prev!")
	elif id == 3:
		print("Advanced search!")

func _menu_help_pressed(id):
	print("Help: " + str(id))

func _funcvscrollbar_scrolling():
	if FuncVScrollBarIndex != FuncVScrollBar.value:
		FuncVScrollBarIndex = FuncVScrollBar.value
	UpdateTimeLine()

func _open_trace_selected(file):
	print("Open: " + str(file))
	LoadTrace(file)
	SetActiveTrace(TActive)

func SetActiveTrace(trace):
	TActive = trace
	print("Active trace set to " + str(TActive))
	_reset_timespan()
	InitTimeLine()
	InitMarkers()
	UpdateTimeLine()
	UpdateMarkers()
	PopulateViews(SRC | INFO | TRACE)

##########################
# Scratch space
func deb_func():
	var tabtmp = TraceView.duplicate()
	tabtmp.set_name("Kalle" + str(debcnt))
	TraceTab.add_child(tabtmp)

##########################