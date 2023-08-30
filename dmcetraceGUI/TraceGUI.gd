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
var MAX_NUM_CORES = 512

# gloabls
var CurrentTime = 0
var ShowCoreChartGrid = true
var TChartXOffset = 20
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
var TopVBoxContainer
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
var MovieChart
var MovieContainer
var FChart
var HSplitFNameFChart
var FChartBox
var FMarkers
var FTab
var FuncVScrollBar
var TChartVScrollBar
var FNameText
var MenuFile
var MenuView
var MenuSearch
var MenuHelp
var FindLineEdit
var OpenTraceDialog
var ShowCurrentTraceInfoDialog
var SettingsConfirmationDialog
var GenericAcceptDialog
var AskForConfirmationDialog
var CurrentTraceInfoLabel
var StatusLabel
var AllCoresButton
var FindNextButton
var FindPrevButton
var TraceInfoButton
var ShowSrcButton
var re_remove_probe
var re_get_probenbr
var TraceViewStart
var TraceViewEnd
var TraceViewScrollTop = 999999999
var TraceViewVisibleLines = 0
var SrcViewVisibleLines = 0
var SrcCache = {}
var ShowProbes = false
var PrevSrcView = ""
var ShowRuler = true
var ShowFullPath = true
var time_start
var timercnt = 0
var	LineEditBasePath
var	LineEditPathFind
var	LineEditPathReplace
var Dragged = false
var DraggedFrameCount = 0
var DraggedOffsetAll = ""
var MovieChartContainer
var TCMovieHSplitContainer
var LossLess = true
var CoreActivity
var MainExtas

func TimerStart():
	time_start = Time.get_ticks_msec()

func TimerEnd():
	var total_time = Time.get_ticks_msec() - time_start
	print(str(timercnt) + " Time elapsed: " + str(total_time))
	timercnt +=1

func RemoveProbe(tstr):
	if ShowProbes:
		pass
	else:
		tstr = re_remove_probe.sub(tstr,"")
		var pcnt = 0
		var found = -1
		for pos in range(len(tstr)):
			if tstr[pos] == '(':
				pcnt += 1
			elif tstr[pos] == ')':
				pcnt -=1
			if pcnt < 0:
				found = pos
				break
		if found != -1:
			tstr = tstr.left(found) + tstr.right(len(tstr) - found - 1)
	return tstr

func ReadSrc(filename):
	var line
	var sourcelines = PackedStringArray([])
	var f
	if filename in SrcCache:
		return SrcCache[filename]

	if Trace[TActive].load_mode == "file":
		f = FileAccess.open(filename, FileAccess.READ)
		if f == null:
			sourcelines.append("Unable to load " + filename + " from host filesystem")
		else:
			while not f.eof_reached(): # iterate through all lines until the end of file is reached
				line = f.get_line()
				sourcelines.append(line.replace("[", "[lb]")) # escape bbcode on the fly
			f.close()
	elif Trace[TActive].load_mode == "bundle":
		var reader = ZIPReader.new()
		var err = reader.open(Trace[TActive].filename)
		if err == OK:
			var rawfile = reader.read_file(filename)
			sourcelines = rawfile.get_string_from_ascii().replace("[", "[lb]").split("\n")
		reader.close()
		if len(sourcelines) == 1 and sourcelines[0] == "":
			sourcelines[0] = "Unable to load " + filename + " from bundle " + Trace[TActive].filename
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
			#TraceView.append_text(tracebuffer[i]_trace_info_button_pressed + "\n")
			D = SplitTraceLine(Trace[TActive].tracebuffer[i])
			D.path = TransformPath(D.path)
			if not ShowFullPath:
				D.path = D.path.replace(Trace[TActive].CommonSourcePath, "")
			var out = str(i) + " " + D.core + " " + D.ts + " " + D.path + " " + D.fun + " " + D.line + " " + D.src
			if i == Trace[TActive].index:
				#TraceView.append_text("[bgcolor=#208bb5][url={\"data\"=\"" + str(i) + "\"}]" + out + "[/url][/bgcolor]\n")
#				tracetext += "[bgcolor=#208bb5][url={\"data\"=\"" + str(i) + "\"}]" + out + "[/url][/bgcolor]\n"
				tracetext += "[bgcolor=#208bb5][url=" + str(i) + "]" + out + "[/url][/bgcolor]\n"
			else:
#				tracetext += "[url={\"data\"=\"" + str(i) + "\"}]" + out + "[/url]\n"
				tracetext += "[url=" + str(i) + "]" + out + "[/url]\n"

		if CurrentSearchString in tracetext:
			tracetext = tracetext.replace(CurrentSearchString, "[bgcolor=#546358]" + CurrentSearchString + "[/bgcolor]")
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
		var srctop = srclnbr - SrcViewVisibleLines / 2 + 2
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

func FTreeInsert(trace, core, ts, pathfunc, linenbr):
	# Keep global index for all functions
	var ind
	if not pathfunc in trace.FList:
		trace.FList.append(pathfunc)
		ind = len(trace.FList) - 1
	else:
		ind = trace.FList.find(pathfunc,0)

	if trace.FTree[core] == null:
		# First entry
		trace.FTree[core] = [{"tstart"=ts, "tend"=ts, "pathfunc"=pathfunc, "index"=ind, "linenbr"=linenbr}]
	else:
		# Check if we switch function
		if trace.FTree[core][len(trace.FTree[core]) - 1].pathfunc == pathfunc:
			trace.FTree[core][len(trace.FTree[core]) - 1].tend = ts
		else:
			trace.FTree[core].append({"tstart"=ts, "tend"=ts, "pathfunc"=pathfunc, "index"=ind, "linenbr"=linenbr})
	return trace

func TransformPath(path):
	return Trace[TActive].base_path + path.replace(Trace[TActive].path_find, Trace[TActive].path_replace)

func _read_trace_from_file(file):
	var f = FileAccess.open(file, FileAccess.READ)
	var trace = []
	while not f.eof_reached():
		trace.append(f.get_line())
	f.close()
	return trace

func _read_trace_from_bundle(bundle):
		print("Extracting .zip file: " + bundle)
		var reader = ZIPReader.new()
		var err = reader.open(bundle)
		var rawtrace = null
		if err != OK:
			print("Error " + str(err) + " when opening .zip file!")
			return

		var zippedfiles = reader.get_files()
		print(zippedfiles)

		var fulltrace = PackedStringArray([])
		var fragcount = 0
		for f in zippedfiles:
			if ".dmcetracefrag-" in f:
				print("Reading file:" + f)
				rawtrace = reader.read_file(f)
				var nexttrace = rawtrace.get_string_from_ascii().split("\n")
				print("Trace fragment " + str(fragcount) + ": Read " + str(len(nexttrace)) + " entries")
				fulltrace += nexttrace
				fragcount += 1
		reader.close()
		print("Total number of trace entries found: " + str(len(fulltrace)))
		return fulltrace

func LoadTrace(path, mode):
	var file = path
	var clist = []
	var record = 0
	var tracetmp = {}
	var filebuf = []

	tracetmp.TraceInfo = PackedStringArray([])
	tracetmp.tracebuffer = PackedStringArray([])
	tracetmp.TimestampsPerCore = []

	for i in range(MAX_NUM_CORES):
		tracetmp.TimestampsPerCore.append([])

	tracetmp.TimeLineTS = []
	tracetmp.TraceEntry2ProbeListIndex = []
	tracetmp.UniqueProbeList = [] 			# probe numbers found in the trace
	tracetmp.ProbeHistogram = []			# Number of hits per unique probe above
	tracetmp.LinePathFunc = []
	tracetmp = FTreeInit(tracetmp)
	print("Loading trace, mode: " + mode)

	if mode == "bundle":
		filebuf = _read_trace_from_bundle(file)
	elif mode == "file":
		filebuf = _read_trace_from_file(file)

	tracetmp.load_mode = mode
	tracetmp.filename = file
	tracetmp.TraceInfo.append("Filename: " + file)

	print("Creating data structures...")
	var prefix
	var first = true
	var count = 0
	for line in filebuf:
		count += 1
		if count % 100000 == 0:
			print("Processed trace lines: " + str(count) + " ( " +  str(100 * (float(count) / len(filebuf))) + "% )")
		if record and line.count("@") > 5: # make sure all fields are there
			var core = int(line.split("@")[0])
			var ts = int(line.split("@")[1])
			var srcpath = line.split("@")[2]
			var function = line.split("@")[4]
			var pathfunc = srcpath + ":" + function
			var linenbr = line.split("@")[3]
			var m = re_get_probenbr.search(line)

			tracetmp.TimestampsPerCore[core].append(ts)

			if m:
				var pnum = int(m.get_string(1))
				var index = tracetmp.UniqueProbeList.find(pnum)
				if index == -1:
					tracetmp.UniqueProbeList.append(pnum)
					tracetmp.ProbeHistogram.append(1)
					tracetmp.LinePathFunc.append(srcpath + "@" + linenbr + "@" + function)
				else:
					tracetmp.ProbeHistogram[index] += 1

			tracetmp.tracebuffer.append(line.replace("[", "[lb]")) # escape bbcode on the fly
			tracetmp.TimeLineTS.append(ts)
			tracetmp = FTreeInsert(tracetmp, core, ts, pathfunc, linenbr)
			if core not in clist:
				clist.append(core)
			if first:
				first = false
				prefix = srcpath
			else:
				while not srcpath.begins_with(prefix):
					prefix = prefix.left(-1)

		if "- - - - -" in line:
			record = 1
		elif not record:
			tracetmp.TraceInfo.append(line)

	tracetmp.ProbedTree = false
	for info in tracetmp.TraceInfo:
		if "Probed code tree: yes" in info:
			tracetmp.ProbedTree = true
			break

	print("Processed trace lines: " + str(count) + " ( 100% )")
	print("Largest common src path: " + prefix)
	clist.sort()
	tracetmp.CommonSourcePath = prefix
	tracetmp.NumCores = len(clist)
	tracetmp.CoreMax = clist.max()
	tracetmp.CoreList = clist
	tracetmp.INDEX_MAX = len(tracetmp.tracebuffer) - 1
	tracetmp.TimeStart = tracetmp.TimeLineTS[0]
	tracetmp.TimeEnd = tracetmp.TimeLineTS[tracetmp.INDEX_MAX]
	tracetmp.index = tracetmp.INDEX_MAX
	tracetmp.rulerstart = 0
	tracetmp.rulerend = 0
	tracetmp.base_path = ""
	tracetmp.path_find = ""
	tracetmp.path_replace = ""
	tracetmp.FuncVScrollBarIndex = 0
	tracetmp.TChartVScrollBarIndex = 0
	TraceViewEnd = tracetmp.index
	if tracetmp.index > TRACE_VIEW_HEIGHT:
		TraceViewStart = tracetmp.index - TRACE_VIEW_HEIGHT
	else:
		TraceViewStart = 0

	# Additional trace info
	tracetmp.TraceInfo.append("Number of trace entries: " + str(len(tracetmp.tracebuffer)))
	tracetmp.TraceInfo.append("Earliest timestamp: " + str(tracetmp.TimeStart))
	tracetmp.TraceInfo.append("Latest timestamp: " + str(tracetmp.TimeEnd))
	tracetmp.TraceInfo.append("Total time: " + str(tracetmp.TimeEnd - tracetmp.TimeStart))

	Trace.append(tracetmp)
	print("...finnished creating data structures")

	TActive = len(Trace) - 1
	file  = file.get_file().get_basename()
	file = file + "  "
	var tabtmp = TraceView.duplicate()
	tabtmp.name = file
	tabtmp.visible = true
	tabtmp.meta_clicked.connect(self._trace_view_meta_clicked)
	TraceViews.append(tabtmp)
	TraceTab.add_child(tabtmp)
	TraceTab.current_tab = TActive
	print("Loaded trace in tab " + str(len(TraceViews) - 1 ))
	print("Initial gfx setup...")
	ResetTimespan()
	InitTimeLine()
	InitMarkers()
	PopulateViews(TRACE | INFO | SRC)
	TCoreLabels.Init(self)
	_show_all_cores(TActive)
	print("...Initial gfx setup done")

func ResetTimespan():
	Trace[TActive].TimeSpanStart = Trace[TActive].TimeStart
	Trace[TActive].TimeSpanEnd = Trace[TActive].TimeLineTS[len(Trace[TActive].TimeLineTS) - 1]
	Trace[TActive].TimeSpan = Trace[TActive].TimeSpanEnd - Trace[TActive].TimeSpanStart

func _ready():

	# Node handles
	VSplitCTop 			= get_node("Background/VSplitTop")
	HSplitCTop 			= get_node("Background/VSplitTop/VBoxContainer/myHSplitContainerTop")
	VSplitCBot			= get_node("Background/VSplitTop/VSplitBot")
	TopVBoxContainer 	= get_node("Background/VSplitTop/VBoxContainer")
	TChart 				= get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/TChartTab/TChartHBoxContainer/TChartPanel/TChart")
	TMarkers 			= get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/TChartTab/TChartHBoxContainer/TChartPanel/TMarkers")
	TChartBox 			= get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/TChartTab/TChartHBoxContainer/TChartPanel")
	TCoreLabels			= get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/TChartTab/TChartHBoxContainer/TCoreLabelsPanelContainer/TCoreLabels")
	TChartVScrollBar	= get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/TChartTab/TChartHBoxContainer/TChartVScrollBar")
	TChartTab			= get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/TChartTab")
	MovieContainer		= get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/HistoCoreActivityHSplitContainer/MovieContainer")
	MovieChart			= get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/HistoCoreActivityHSplitContainer/MovieContainer/MovieChartContainer/MovieChart")
	MovieChartContainer	= get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/HistoCoreActivityHSplitContainer/MovieContainer/MovieChartContainer")
	CoreActivity		= get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/HistoCoreActivityHSplitContainer/CoreActivityRichTextLabel")
	MainExtas			= get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/HistoCoreActivityHSplitContainer")
	FChart 				= get_node("Background/VSplitTop/VSplitBot/FuncTab/FuncContainer/FuncHBoxContainer/HSplitFNameFChart/FChartPanelTop/FChartPanel/FChart")
	FMarkers 			= get_node("Background/VSplitTop/VSplitBot/FuncTab/FuncContainer/FuncHBoxContainer/HSplitFNameFChart/FChartPanelTop/FChartPanel/FMarkers")
	FChartBox 			= get_node("Background/VSplitTop/VSplitBot/FuncTab/FuncContainer/FuncHBoxContainer/HSplitFNameFChart/FChartPanelTop/FChartPanel")
	FTab 				= get_node("Background/VSplitTop/VSplitBot/FuncTab")
	FuncVScrollBar 		= get_node("Background/VSplitTop/VSplitBot/FuncTab/FuncContainer/FuncHBoxContainer/FuncVScrollBar")
	HSplitFNameFChart 	= get_node("Background/VSplitTop/VSplitBot/FuncTab/FuncContainer/FuncHBoxContainer/HSplitFNameFChart")
	FNameText			= get_node("Background/VSplitTop/VSplitBot/FuncTab/FuncContainer/FuncHBoxContainer/HSplitFNameFChart/FNameText")
	Background 			= get_node("Background")
	TraceTab			= get_node("Background/VSplitTop/VBoxContainer/myHSplitContainerTop/TraceTab")
	TraceView 			= get_node("TraceView")
	SrcView 			= get_node("Background/VSplitTop/VBoxContainer/myHSplitContainerTop/HSplitSrcVars/SrcTab/SrcView")
	VarsView 			= get_node("Background/VSplitTop/VBoxContainer/myHSplitContainerTop/HSplitSrcVars/VarsTab/VarsView")
	SrcTab 				= get_node("Background/VSplitTop/VBoxContainer/myHSplitContainerTop/HSplitSrcVars/SrcTab")
	VarsTab 			= get_node("Background/VSplitTop/VBoxContainer/myHSplitContainerTop/HSplitSrcVars/VarsTab")
	MenuFile 			= get_node("MenuBar/PopupMenuFile")
	MenuView 			= get_node("MenuBar/PopupMenuView")
	MenuSearch 			= get_node("MenuBar/PopupMenuSearch")
	MenuHelp 			= get_node("MenuBar/PopupMenuHelp")
	OpenTraceDialog 	= get_node("OpenTraceDialog")
	FindLineEdit		= get_node("FindLineEdit")
	FindNextButton		= get_node("FindNextButton")
	FindPrevButton		= get_node("FindPrevButton")
	TraceInfoButton 	= get_node("TraceInfoButton")
	ShowSrcButton		= get_node("ShowSrcButton")
	GenericAcceptDialog	= get_node("GenericAcceptDialog")
	ShowCurrentTraceInfoDialog = get_node("ShowCurrentTraceInfoDialog")
	AskForConfirmationDialog = get_node("AskForConfirmationDialog")
	SettingsConfirmationDialog = get_node("SettingsConfirmationDialog")
	CurrentTraceInfoLabel = get_node("ShowCurrentTraceInfoDialog/CurrentTraceInfoLabel")
	StatusLabel = get_node("Background/VSplitTop/VBoxContainer/StatusLabel")
	LineEditBasePath = get_node("SettingsConfirmationDialog/HBoxContainerSettings/VBoxContainerLeft/LineEditBasePath")
	LineEditPathFind = get_node("SettingsConfirmationDialog/HBoxContainerSettings/VBoxContainerLeft/LineEditPathFind")
	LineEditPathReplace = get_node("SettingsConfirmationDialog/HBoxContainerSettings/VBoxContainerLeft/LineEditPathReplace")
	TCMovieHSplitContainer = get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer")

	re_remove_probe = RegEx.new()
	re_remove_probe.compile("\\(DMCE_PROBE.*?\\),")      #\d*(.*?),")
	re_get_probenbr = RegEx.new()
	re_get_probenbr.compile("DMCE_PROBE\\d*\\((\\d*)")

	print("Control root started")
	MovieChart.Init(self)
	CoreActivity.Init(self)

	# Debug
	# get_tree().quit()
	# signals
	VSplitCTop.dragged.connect(self._dragged)
	HSplitCTop.dragged.connect(self._dragged)
	VSplitCBot.dragged.connect(self._dragged)
	TCMovieHSplitContainer.dragged.connect(self._dragged)
#	Background.resized.connect(self._resized)
	MenuFile.id_pressed.connect(self._menu_file_pressed)
	MenuView.id_pressed.connect(self._menu_view_pressed)
	MenuSearch.id_pressed.connect(self._menu_search_pressed)
	MenuHelp.id_pressed.connect(self._menu_help_pressed)
	FuncVScrollBar.value_changed.connect(self._funcvscrollbar_value_changed)
	TChartVScrollBar.value_changed.connect(self._tchartvscrollbar_value_changed)
	TraceTab.tab_changed.connect(self._trace_tab_changed)
	OpenTraceDialog.file_selected.connect(self._open_trace_selected)
	FindLineEdit.text_submitted.connect(self._find_text_submitted)
	FindNextButton.pressed.connect(self._find_next_button_pressed)
	FindPrevButton.pressed.connect(self._find_prev_button_pressed)
	TraceInfoButton.pressed.connect(self._trace_info_button_pressed)
	ShowSrcButton.pressed.connect(self._show_src_button_pressed)
	SettingsConfirmationDialog.confirmed.connect(self._settings_confirmation_dialog_confirmed)

	# Initial state
	print("dmce-wgui: started with args: " + str(OS.get_cmdline_args()))

	if len(OS.get_cmdline_args()) > 0 and OS.get_cmdline_args()[0] != "res://TraceGUI.tscn":
		var file = OS.get_cmdline_args()[0]
		if not FileAccess.file_exists(file):
			print("dmce-wgui: Could not open " + str(file))
		else:
			LoadTrace(file, "file")
			_show_all_cores(0)
	else:
		print("dmce-wgui: No trace loaded from args")
		# dev state, uncomment for release:
		if len(OS.get_cmdline_args()) == 2 and OS.get_cmdline_args()[1] == "--dev":
			print("dmce-wgui: development mode")
#			LoadTrace('/home/pat/agtrace/dmce-trace-ag.7649.zip', "bundle")
#			_show_all_cores(0)

	TChartTab.set_tab_title(0, "Cores")
	FTab.set_tab_title(0, "Functions")
	SrcTab.set_tab_title(0, "Source")
	VarsTab.set_tab_title(0, "Variables")

	MovieChart.Update()

	$MenuBar/PopupMenuFile.name = " File "
	$MenuBar/PopupMenuView.name = " View "
	$MenuBar/PopupMenuSearch.name = " Search "
	$MenuBar/PopupMenuHelp.name = " Help "

func _show_src_button_pressed():
	ShowSrcButton.release_focus()
	if TopVBoxContainer.visible == false:
		TopVBoxContainer.visible = true
	else:
		TopVBoxContainer.visible = false

func _trace_info_button_pressed():
	TraceInfoButton.release_focus()
	CurrentTraceInfoLabel.text = str("\n".join(Trace[TActive].TraceInfo))
	ShowCurrentTraceInfoDialog.popup_centered()

func _find_next(searchstr):
	if Trace[TActive].index < Trace[TActive].INDEX_MAX:
		for i in range(Trace[TActive].index + 1, len(Trace[TActive].tracebuffer)):
			if searchstr in Trace[TActive].tracebuffer[i]:
				Trace[TActive].index = i
				if Trace[TActive].index > (TraceViewScrollTop + TraceViewVisibleLines - 2):
					TraceViewScrollTop = Trace[TActive].index - TraceViewVisibleLines + 2
				UpdateTimeLine()
				UpdateMarkers()
				PopulateViews(TRACE | INFO | SRC)
				break

func _find_prev(searchstr):
	if Trace[TActive].index > 0:
		for i in range(Trace[TActive].index - 1, -1, -1):
			if searchstr in Trace[TActive].tracebuffer[i]:
				Trace[TActive].index = i
				if Trace[TActive].index < TraceViewScrollTop:
					TraceViewScrollTop = Trace[TActive].index
				UpdateTimeLine()
				UpdateMarkers()
				PopulateViews(TRACE | INFO | SRC)
				break

func _find_next_button_pressed():
	FindNextButton.release_focus()
	_find_next(FindLineEdit.text)
	PopulateViews(SRC | INFO | TRACE)
	UpdateTimeLine()
	UpdateMarkers()

func _find_prev_button_pressed():
	FindPrevButton.release_focus()
	_find_prev(FindLineEdit.text)
	PopulateViews(SRC | INFO | TRACE)
	UpdateTimeLine()
	UpdateMarkers()

var CurrentSearchString = ""
func _find_text_submitted(text):
	FindLineEdit.release_focus()
	CurrentSearchString = FindLineEdit.text
	_find_next(FindLineEdit.text)
	PopulateViews(SRC | INFO | TRACE)
	UpdateTimeLine()
	UpdateMarkers()


func _settings_confirmation_dialog_confirmed():
	Trace[TActive].base_path = LineEditBasePath.text
	Trace[TActive].path_find = LineEditPathFind.text
	Trace[TActive].path_replace = LineEditPathReplace.text
	SetActiveTrace(TActive)

func _show_all_cores(ind):
	FChart.ClearCores(ind)
	for core in Trace[TActive].CoreList:
		FChart.AddCore(core, ind)
	UpdateTimeLine()

func _hide_all_cores(ind):
	FChart.ClearCores(ind)
	UpdateTimeLine()

func _trace_tab_changed(tab):
		SetActiveTrace(tab)

func _dragged(_offset):
	Dragged = true

func _resized():
	# Top "pane"
	FindLineEdit.size.x =  Background.size.x / 4
	FindLineEdit.position.x =  Background.size.x - (Background.size.x / 4) - (FindNextButton.size.x * 2 + 5 + 5 + 8)

	FindNextButton.position.x =  FindLineEdit.position.x + FindLineEdit.size.x + 5
	FindPrevButton.position.x =  FindNextButton.position.x + FindNextButton.size.x + 5
	FindNextButton.position.y =  3
	FindPrevButton.position.y =  3

	TraceInfoButton.position.x = FindLineEdit.position.x - 100
	TraceInfoButton.position.y = 3

	ShowSrcButton.position.x = TraceInfoButton.position.x - 100
	ShowSrcButton.position.y = 3

	VSplitCTop.split_offset = VSplitCTop.size.y * VSplitTop
	HSplitCTop.split_offset = HSplitCTop.size.x * HSplitTop
	VSplitCBot.split_offset = VSplitCBot.size.y * VSplitBot

	if len(Trace) > 0:
		UpdateTimeLine()
		UpdateMarkers()
		MovieChart.Update()
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

func val2commastr(val):
	var s = str(int(val))
	if len(s) > 3:
		s = s.insert(len(s) - 3, ",")
	if len(s) > 7:
		s = s.insert(len(s) - 7, ",")
	if len(s) > 11:
		s = s.insert(len(s) - 11, ",")
	return s

func _process(_delta):
	# Initial setup
	if not InitDone:
		InitDone = true

	# Periodical update of state

	if Dragged:
		var DraggedOffsetAllNow = str(VSplitCTop.split_offset) + str(HSplitCTop.split_offset) + str(VSplitCBot.split_offset) + str(TCMovieHSplitContainer.split_offset)
		if DraggedOffsetAll == DraggedOffsetAllNow:
			DraggedFrameCount += 1
			if DraggedFrameCount > 60:
				VSplitTop =  VSplitCTop.split_offset / VSplitCTop.size.y
				HSplitTop = HSplitCTop.split_offset / HSplitCTop.size.x
				VSplitBot = VSplitCBot.split_offset / VSplitCBot.size.y
				if len(Trace) > 0:
					UpdateTimeLine()
					UpdateMarkers()
					MovieChart.Update()
				Dragged = false
		else:
			DraggedFrameCount = 0
		DraggedOffsetAll = DraggedOffsetAllNow

	if len(TraceViews) > 0:
		TraceViewVisibleLines  = TraceViews[TActive].get_visible_line_count()
		var s = "Time: " + val2commastr(CurrentTime) + "ns"
		if TMarkers.ZoomActive():
			s = s + "    Start: " + val2commastr(TChart.ZoomStart) + "ns"
			s = s + "    End: " + val2commastr(TChart.ZoomEnd) + "ns"
			s = s + "    Diff: " + val2commastr(TChart.ZoomEnd - TChart.ZoomStart) + "ns"
		elif FMarkers.ZoomActive():
			s = s + "    Start: " + val2commastr(FChart.ZoomStart) + "ns"
			s = s + "    End: " + val2commastr(FChart.ZoomEnd) + "ns"
			s = s + "    Diff: " + val2commastr(FChart.ZoomEnd - FChart.ZoomStart) + "ns"
		else:
			s = s + "    Start: " + val2commastr(Trace[TActive].TimeSpanStart) + "ns"
			s = s + "    End: " + val2commastr(Trace[TActive].TimeSpanEnd) + "ns"
			s = s + "    Diff: " + val2commastr(Trace[TActive].TimeSpan) + "ns"
		StatusLabel.text = s

	SrcViewVisibleLines  = SrcView.get_visible_line_count()

	if _get_resize_state() == 2 and not Dragged:
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
	CoreActivity.Update()

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

func _in_tchart(_pos):
	if TChartBox.get_local_mouse_position().y  > 0 and TChartBox.get_local_mouse_position().y < TChartBox.size.y:
		if TChartBox.get_local_mouse_position().x > 0 and TChartBox.get_local_mouse_position().x < TChartBox.size.x:
			return true
	return false

func _in_moviebox():
	if MovieContainer.visible == false:
		return false
	if MovieChartContainer.get_local_mouse_position().y  > 0 and MovieChartContainer.get_local_mouse_position().y < MovieChartContainer.size.y:
		if MovieChartContainer.get_local_mouse_position().x > 0 and MovieChartContainer.get_local_mouse_position().x < MovieChartContainer.size.x:
			return true
	return false

func _in_corelist(_pos):
	if TChartBox.get_local_mouse_position().y  > 0 and TChartBox.get_local_mouse_position().x < TChartXOffset - 10:
		return true
	return false

func _in_fchart(_pos):
	if FChartBox.get_local_mouse_position().y  > 0 and FChartBox.get_local_mouse_position().y < FChartBox.size.y:
		if FChartBox.get_local_mouse_position().x > 0 and FChartBox.get_local_mouse_position().x < FChartBox.size.x:
			return true
	return false

func _in_fnames(_pos):
	if FChartBox.get_local_mouse_position().y  > 0 and FChartBox.get_local_mouse_position().y < FChartBox.size.y:
		if FChartBox.get_local_mouse_position().x < 0:
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
			if FindLineEdit.has_focus():
				if ev.keycode == KEY_ESCAPE:
					FindLineEdit.release_focus()
			else:
				if ev.keycode == KEY_P:
					if ShowProbes == false:
						ShowProbes = true
					else:
						ShowProbes = false
					PopulateViews(TRACE | SRC)
				if ev.keycode == KEY_G:
					if Input.is_physical_key_pressed(KEY_SHIFT):
						Trace[TActive].index = Trace[TActive].INDEX_MAX
					else:
						Trace[TActive].index = 0
					ResetTimespan()
					InitTimeLine()
					InitMarkers()
					UpdateTimeLine()
					PopulateViews(TRACE | SRC | INFO)
					UpdateMarkers()
				elif ev.keycode == KEY_Z:
					ResetTimespan()
					InitTimeLine()
					InitMarkers()
					UpdateTimeLine()
					PopulateViews(TRACE | SRC | INFO)
					UpdateMarkers()
				elif ev.keycode == KEY_SPACE:
					deb_func()
		else:
			PopulateViews(SRC | INFO)
			UpdateMarkers()

	if ev is InputEventMouseButton and (_in_tchart(ev.position) or _in_fchart(ev.position) ):
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP and ev.pressed:
			TChart.MouseWheelUp()
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN and ev.pressed:
			TChart.MouseWheelDown()

	if ev is InputEventMouseButton and (_in_fnames(ev.position)):
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP and ev.pressed:
			FChart.MouseWheelUp()
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN and ev.pressed:
			FChart.MouseWheelDown()

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

	if ev is InputEventMouseMotion and _in_moviebox():
		MovieChart.MouseMoved()

	if ev is InputEventMouseButton and _in_moviebox():
		if ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			MovieChart.MouseLeftPressed()

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
	UpdateTimeLine()
	UpdateMarkers()

var _open_trace_mode

func _open_trace():
	_open_trace_mode = "file"
	OpenTraceDialog.title = "Open trace file"
	OpenTraceDialog.visible = true

func _import_trace_bundle():
	_open_trace_mode = "bundle"
	OpenTraceDialog.title = "Import trace bundle"
	OpenTraceDialog.visible = true

func _close_trace():
	if len(Trace) > 0:
		var tmpTActive = TActive
		if TActive > 0:
			TActive -= 1
		_hide_all_cores(tmpTActive)
		TraceViews[tmpTActive].free()
		Trace.remove_at(tmpTActive)
		TraceViews.remove_at(tmpTActive)
		SrcView.text = "No source code available"
		VarsView.text = ""
		FNameText.text = ""
		if len(Trace) > 0:
			SetActiveTrace(TActive)

func _confirm_close_trace():
	_close_trace()

func _confirm_quit():
	get_tree().quit()

func _menu_file_pressed(id):
	if id == 0:
		_open_trace()
	elif id == 1:
		AskForConfirmationDialog.dialog_text = "Do you really want to close active trace?"
		AskForConfirmationDialog.confirmed.connect(self._confirm_close_trace)
		AskForConfirmationDialog.popup_centered()
	elif id == 2:
		SettingsConfirmationDialog.dialog_text = ""
		SettingsConfirmationDialog.popup_centered()
	elif id == 3:
		AskForConfirmationDialog.dialog_text = "Do you really want to quit?"
		AskForConfirmationDialog.confirmed.connect(self._confirm_quit)
		AskForConfirmationDialog.popup_centered()
	elif id == 4:
		_import_trace_bundle()

func _toggle_show_ruler():
	if ShowRuler == true:
		ShowRuler = false
	else:
		ShowRuler = true
	UpdateMarkers()

func _toggle_show_original_src_path():
	if ShowFullPath == true:
		ShowFullPath = false
	else:
		ShowFullPath = true
	PopulateViews(TRACE)

func _toggle_show_histogram():
	if MovieContainer.visible == true:
		MovieContainer.visible = false
	else:
		MovieContainer.visible = true

func _toggle_core_activity():
	if CoreActivity.visible == true:
		CoreActivity.visible = false
	else:
		CoreActivity.visible = true

func _toggle_lossless():
	if LossLess == false:
		LossLess = true
	else:
		LossLess = false

func _menu_view_pressed(id):
	if len(Trace) == 0:
		return
	if id == 0:
		_show_all_cores(TActive)
	elif id == 1:
		_hide_all_cores(TActive)
	elif id == 2:
		ToggleShowCoreChartGrid()
		MenuView.set_item_checked( 2, not MenuView.is_item_checked(2))
	elif id == 3:
		if not Trace[TActive].ProbedTree:
			GenericAcceptDialog.dialog_text = "No histogram view available for non-probed code tree bundles!"
			GenericAcceptDialog.popup_centered()
			return
		_toggle_show_histogram()
		MenuView.set_item_checked( 3, not MenuView.is_item_checked(3))
	elif id == 4:
		_trace_info_button_pressed()
	elif id == 5:
		_toggle_show_original_src_path()
	elif id == 6:
		_toggle_lossless()
		MenuView.set_item_checked( 6, not MenuView.is_item_checked(6))
	elif id == 7:
		_toggle_core_activity()
		MenuView.set_item_checked( 7, not MenuView.is_item_checked(7))

	# Some final common stuff
	if CoreActivity.visible || MovieContainer.visible:
		MainExtas.visible = true
	else:
		MainExtas.visible = false

func _menu_search_pressed(id):
	if len(Trace) == 0:
		return
	if id == 0:
		print("Find!")
	elif id == 1:
		_find_next(FindLineEdit.text)
	elif id == 2:
		_find_prev(FindLineEdit.text)
	elif id == 3:
		print("Advanced search!")

func _menu_help_pressed(id):
	print("Help: " + str(id))

func _funcvscrollbar_value_changed(val):
	Trace[TActive].FuncVScrollBarIndex = FuncVScrollBar.value
	FChart.UpdateScrollPosition()

func _tchartvscrollbar_value_changed(val):
	Trace[TActive].TChartVScrollBarIndex = TChartVScrollBar.value
	TChart.UpdateScrollPosition()
	TCoreLabels.Init(self)

func _open_trace_selected(file):
	if _open_trace_mode == "file":
		LoadTrace(file, _open_trace_mode)
		SetActiveTrace(TActive)
	elif _open_trace_mode == "bundle":
		LoadTrace(file, _open_trace_mode)
		SetActiveTrace(TActive)

func SetActiveTrace(trace):
	TActive = trace
	print("Active trace set to " + str(TActive))
	ResetTimespan()
	InitTimeLine()
	InitMarkers()
	UpdateTimeLine()
	UpdateMarkers()
	MovieChart.Update()
	CoreActivity.Update()
	PopulateViews(SRC | INFO | TRACE)
	TCoreLabels.Init(self)
	FuncVScrollBar.value = Trace[TActive].FuncVScrollBarIndex

##########################
# Scratch space
func deb_func():
	print("DEB " + str(debcnt))
	debcnt += 1
##########################
