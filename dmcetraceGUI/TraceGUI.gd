extends Control

var debcnt = 0

# defines
var TRACE_VIEW_HEIGHT = 100
var SRC_VIEW_BUF_HEIGHT = 1000
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
var Active = true
var SceneController
var EditorExec
var WeAreBusy = 0
var CurrentTime = 0
var ShowCoreChartGrid = true
var TChartXOffset = 20
var InitDone = false
var VSplitTop = 0.25
var HSplitTop = 0.5
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
var SearchConfirmationDialog
var GenericAcceptDialog
var AskForConfirmationDialog
var CurrentTraceInfoLabel
var StatusLabel
var AllCoresButton
var FindNextButton
var FindPrevButton
var TraceInfoButton
var ShowSrcButton
var ShowLogButton
var TogglePerFuncOrCoreButton
var re_remove_probe_type0
var re_remove_probe_type1begin
var re_remove_probe_type1end
var re_get_probenbr
var TraceViewStart
var TraceViewEnd
var TraceViewScrollTop = 999999999
var TraceViewVisibleLines = 0
var SrcViewVisibleLines = 0
var SrcCacheFileNames = []
var SrcCacheCodeLines = []
var ShowProbes = false
var PrevSrcView = ""
var RulerActive = false
var ShowFullPath = true
var time_start
var timercnt = 0
var Dragged = false
var DraggedFrameCount = 0
var DraggedOffsetAll = ""
var MovieChartContainer
var TCMovieHSplitContainer
var LossLess = true
var CoreActivity
var MainExtas
var SearchShowAll = true
var MainProgressBar
var LineEditFindAll
var LineEditFindAllProbeNumber
var FindAllProbeNumber = ""
var HexdumpSceneRef
var SrcViewScrollBar
var SrcPopOutButton
var HSplitSrcVars
var LogTabContainer
var LogRichTextLabel
var CoreActivityTabContainer
var MovieTabContainer
var LogFindLineEdit
var LogSearchNextButton
var LogSearchPrevButton

func Activate():
	Active = true

func Deactivate():
	Active = false

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
		# Probe type 0
		tstr = re_remove_probe_type0.sub(tstr,"")
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

		# Probe type 1
		if "{ do { DMCE_PROBE" in tstr:
			tstr = re_remove_probe_type1begin.sub(tstr,"")
			tstr = re_remove_probe_type1end.sub(tstr,"")

	return tstr

var LastSrcFileLookup = ""
var SrcViewOffset = 0
func ReadSrc(filename, lnbr):
	var found = false
	var line
	var sourcelines = PackedStringArray([])
	var f
	var cind = Trace[TActive].SrcCacheFileNames.find(filename)
	if cind  != -1:
		if filename != LastSrcFileLookup:
			LastSrcFileLookup = filename
			Trace[TActive].SrcStepList = [null, null, null]
		found = true
		sourcelines = Trace[TActive].SrcCacheCodeLines[cind]

	if Trace[TActive].load_mode != "bundle":
		print("Unsupported trace format")
		get_tree().quit()
	elif not found:
		var reader = ZIPReader.new()
		var err = reader.open(Trace[TActive].filename)
		if err == OK:
			var rawfile = reader.read_file(filename)
# Keep for future development of Trace-individual file cache, needs a hash key in bundles for identification
#			var tmp = filename.split("/")
#			var basename = tmp[len(tmp) - 1]
#			DirAccess.make_dir_recursive_absolute(DmceCacheDirPath + "/" + filename.get_base_dir())
#			print("Storing in cache: " + DmceCacheDirPath + "/" + filename)
#			var cachedfile = FileAccess.open(DmceCacheDirPath + "/" + basename, FileAccess.WRITE)
#			cachedfile.store_string(rawfile.get_string_from_ascii())
#			cachedfile.close()
			sourcelines = rawfile.get_string_from_ascii().replace("[", "[lb]").split("\n")
		reader.close()
		if len(sourcelines) == 1 and sourcelines[0] == "":
			sourcelines[0] = "Unable to load " + filename + " from bundle " + Trace[TActive].filename
		else:
			Trace[TActive].SrcCacheFileNames.append(filename)
			Trace[TActive].SrcCacheCodeLines.append(sourcelines)

	# Only return maximum SRC_VIEW_BUF_HEIGHT lines to keep stepping snappy
	if lnbr < SRC_VIEW_BUF_HEIGHT:
		SrcViewOffset = 0
		return sourcelines.slice(0, SRC_VIEW_BUF_HEIGHT)
	if len(sourcelines) - lnbr < SRC_VIEW_BUF_HEIGHT:
		SrcViewOffset = len(sourcelines) - SRC_VIEW_BUF_HEIGHT
		return sourcelines.slice(-SRC_VIEW_BUF_HEIGHT)

	SrcViewOffset = lnbr - SRC_VIEW_BUF_HEIGHT / 2
	return sourcelines.slice(lnbr - SRC_VIEW_BUF_HEIGHT / 2 , lnbr + SRC_VIEW_BUF_HEIGHT / 2)

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
#			D.path = TransformPath(D.path)
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

	# Source View                 .SrcStepList = [null, null, null]
	if view & SRC:
		SrcView.clear()
		D = SplitTraceLine(Trace[TActive].tracebuffer[Trace[TActive].index])

		Trace[TActive].CurrentSrcFile = D.path

		var srclnbr = int(D.line.replace("+",""))
		var slines
		if not "dmce_printf" in D.fun and not "dmce_hexdump" in D.fun:
			slines = ReadSrc(D.path, srclnbr)
		else:
			slines = ["In-band data entry, source code not applicable"]
		Trace[TActive].CurrentSrcLines = slines

		var lnbr = SrcViewOffset
		for line in slines:
			lnbr += 1
			line =  str(lnbr) + "  " + RemoveProbe(line)
			if srclnbr == lnbr:
				line = "[bgcolor=#208bb5]" + line + "[/bgcolor]"
			elif Trace[TActive].SrcStepList[0] != null and Trace[TActive].SrcStepList[0] == lnbr:
				line = "[bgcolor=#215363]" + line + "[/bgcolor]"
			elif Trace[TActive].SrcStepList[1] != null and Trace[TActive].SrcStepList[1] == lnbr:
				line = "[bgcolor=#1a404c]" + line + "[/bgcolor]"
			elif Trace[TActive].SrcStepList[2] != null and Trace[TActive].SrcStepList[2] == lnbr:
				line = "[bgcolor=#06242d]" + line + "[/bgcolor]"
			else:
				line = line.replace("[", "[lb]")
			SrcView.append_text(line + "\n")

		# Keep src browsing trail
		Trace[TActive].SrcStepList[2] = Trace[TActive].SrcStepList[1]
		Trace[TActive].SrcStepList[1] = Trace[TActive].SrcStepList[0]
		Trace[TActive].SrcStepList[0] = srclnbr

		var viewpos = SrcViewVisibleLines / 2
		var scrollto = srclnbr - SrcViewOffset - viewpos - 2

#		print("----")
#		print("viewpos: " + str(viewpos))
#		print("scrollto: " + str(scrollto))
#		print("SrcViewOffset: " + str(SrcViewOffset))

		SrcView.scroll_to_line(scrollto)

		# Variables View
		VarsView.clear()
		if "dmce_hexdump" in D.fun:
			VarsView.append_text(Trace[TActive].HexDump[Trace[TActive].index])
		else:
			for v in D.vars:
				if CurrentSearchString in v:
					VarsView.append_text(v.replace("[", "[lb]").replace(CurrentSearchString, "[bgcolor=#546358]" + CurrentSearchString + "[/bgcolor]"))
				else:
					VarsView.append_text(v.replace("[", "[lb]"))
				if not "dmce_printf" in D.fun:
					VarsView.append_text("\n")
				else:
					VarsView.append_text(" ")

func FTreeInit(trace):
	trace.FTree = []
	trace.FList = []
	trace.FDrawList = []

	for i in range(512):
		trace.FTree.append(null)
	return trace

func _compare_end(a,b):
	return a.tend < b.tend

func FTreeInsert(trace, core, ts, pathfunc, linenbr):
	# Keep global index for all functions
	var ind
	if not pathfunc in trace.FList:
		trace.FList.append(pathfunc)
		trace.FDrawList.append([])
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
			# Save the old one in draw list, init the new one
			# Place it sorted
			var sind = trace.FDrawList[trace.FTree[core][len(trace.FTree[core]) - 1].index].bsearch_custom(trace.FTree[core][len(trace.FTree[core]) - 1], _compare_end)
			trace.FDrawList[trace.FTree[core][len(trace.FTree[core]) - 1].index].insert(sind, {"tstart"=trace.FTree[core][len(trace.FTree[core]) - 1].tstart, "tend"=trace.FTree[core][len(trace.FTree[core]) - 1].tend, "core"=core})
			trace.FTree[core].append({"tstart"=ts, "tend"=ts, "pathfunc"=pathfunc, "index"=ind, "linenbr"=linenbr})
	return trace

func FDrawListInsertLast(trace):
	var core = 0
	while core < len(trace.FTree):
		if trace.FTree[core] != null:
			trace.FDrawList[trace.FTree[core][len(trace.FTree[core]) - 1].index].append({"tstart"=trace.FTree[core][len(trace.FTree[core]) - 1].tstart, "tend"=trace.FTree[core][len(trace.FTree[core]) - 1].tend, "core"=core})
		core += 1
	return trace

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
			return null

		var zippedfiles = reader.get_files()

		var fulltrace = PackedStringArray([])
		var fragcount = 0
		MainProgressBar.visible = true
		for f in zippedfiles:
			MainProgressBar.value = float((fragcount * 2) % 100)
			if ".dmcetracefrag-" in f:
				print("Reading file:" + f)
				rawtrace = reader.read_file(f)
				var nexttrace = rawtrace.get_string_from_ascii().split("\n")
				print("Trace fragment " + str(fragcount) + ": Read " + str(len(nexttrace)) + " entries")
				fulltrace += nexttrace
				fragcount += 1
				if fragcount > 50:
					print("Trace fragment limit reached, data at the end will be lost")
					break
		reader.close()
		MainProgressBar.visible = false
		print("Total number of trace entries found: " + str(len(fulltrace)))
		return fulltrace

func _get_hexdump(vars):
	vars = vars.split(" ")
	var varstmp = vars[0] + "\n\n"
	varstmp += "000000 "
	var ascii = ""
	var varstmplist = []
	for i in range (1, len(vars)):
		if i % 16 == 0:
			varstmp += vars[i] + " "
			if vars[i].hex_to_int() > 31 and vars[i].hex_to_int() < 127:
				ascii += char(vars[i].hex_to_int())
			else:
				ascii += "."

			varstmp += ascii + "\n" + "%06x" % i + " "
			ascii = ""
			varstmplist.append(varstmp)
			varstmp = ""
		else:
			varstmp += vars[i]
			varstmp += " "
			if vars[i].hex_to_int() > 31 and vars[i].hex_to_int() < 127:
				ascii += char(vars[i].hex_to_int())
			else:
				ascii += "."
	return "".join(varstmplist)

func LoadTrace(path, mode):
	var file = path
	var clist = []
	var record = 0
	var tracetmp = {}
	var filebuf = []

	tracetmp.TraceInfo = PackedStringArray([])
	tracetmp.tracebuffer = PackedStringArray([])
	tracetmp.TimestampsPerCore = []
	tracetmp.SrcCacheFileNames = []
	tracetmp.SrcCacheCodeLines = []
	tracetmp.CurrentSrcFile = ""
	tracetmp.CurrentSrcLines = [""]

	for i in range(MAX_NUM_CORES):
		tracetmp.TimestampsPerCore.append([])

	tracetmp.FuncPerCore = false
	tracetmp.TimeLineTS = []
	tracetmp.TraceEntry2ProbeListIndex = []
	tracetmp.UniqueProbeList = [] 			# probe numbers found in the trace
	tracetmp.ProbeHistogram = []			# Number of hits per unique probe above
	tracetmp.LinePathFunc = []
	tracetmp = FTreeInit(tracetmp)
	tracetmp.SrcStepList = [null, null, null]
	tracetmp.FindAllMarkers = []
	tracetmp.HexDump = []
	tracetmp.LogPrintf = ""
	tracetmp.LogPrintfLines = []
	tracetmp.LogSearchIndex = 0
	tracetmp.HexDumpRaw = []
	tracetmp.HexDumpTraceEntry = []
	tracetmp.HexDumpTraceEntryIndex = []

	print("Loading trace, mode: " + mode)

	if mode == "bundle":
		filebuf = _read_trace_from_bundle(file)
	elif mode == "file":
		filebuf = _read_trace_from_file(file)

	if filebuf == null:
		LoaderFilename = ""
		return

	tracetmp.load_mode = mode
	tracetmp.filename = file
	tracetmp.TraceInfo.append("Filename: " + file)

	print("Creating data structures...")
	var prefix
	var first = true
	var count = 0
	var hexdumpcount = 0
	MainProgressBar.visible = true
	var printf_last_ts = 0
	while count < len(filebuf):

		var line = filebuf[count]
		if count % 100000 == 0:
			print("Processed trace lines: " + str(count) + " ( " +  str(100 * (float(count) / len(filebuf))) + "% )")
		if count % 10000 == 0:
			MainProgressBar.value = 100 * (float(count) / len(filebuf))
		if record and line.count("@") > 5: # make sure all fields are there
			var sline = line.split("@")
			var core = int(sline[0])
			var ts = int(sline[1])
			var srcpath = sline[2]
			var function = sline[4]
			var pathfunc = srcpath + ":" + function
			var linenbr = sline[3]

			if "dmce_hexdump" in function:
				var backwardindex = count - 1
				var psline = filebuf[backwardindex].split("@")
				backwardindex -= 1
				# In case some other core trace entry got in between,
				# look backwards max 100 steps
				while int(psline[0]) != core and backwardindex > 0:
					psline = filebuf[backwardindex].split("@")
					backwardindex -= 1
				srcpath = psline[2]
				linenbr = psline[3]
				sline[2] = psline[2]
				sline[3] = psline[3]
				line = "@".join(sline)
				var encodedhexdump = _get_hexdump(sline[6])
				tracetmp.HexDump.append(encodedhexdump)
				tracetmp.HexDumpRaw.append(sline[6])
				tracetmp.HexDumpTraceEntry.append(sline)
				tracetmp.HexDumpTraceEntryIndex.append(len(tracetmp.HexDumpTraceEntry) - 1)
				hexdumpcount += 1
				if hexdumpcount % 100 == 0:
					print("Got hexdump entry " + str(hexdumpcount) + " at entry: " + str(count))
			else:
				tracetmp.HexDump.append(null)
				tracetmp.HexDumpRaw.append(null)
				tracetmp.HexDumpTraceEntry.append(null)
			if "dmce_printf" in function:
				if printf_last_ts == 0:
					printf_last_ts = ts
				var printf_diff = ts - printf_last_ts
				printf_last_ts = ts
				var out = str(ts) + ":" + "+" + str(printf_diff) + ":" + str(core) + ":" + sline[6].rstrip("\n")
				tracetmp.LogPrintf += "[url=" + str(len(tracetmp.tracebuffer)) + "]" + out + "[/url]\n"
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
		count += 1

		if not record and "- - - - -" in line:
			record = 1
		elif not record:
			tracetmp.TraceInfo.append(line)

	tracetmp.LogPrintfLines = tracetmp.LogPrintf.split("\n")

	tracetmp = FDrawListInsertLast(tracetmp)
	tracetmp.ProbedTree = false
	for info in tracetmp.TraceInfo:
		if "Probed code tree: yes" in info:
			tracetmp.ProbedTree = true
			break

	MainProgressBar.visible = false
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
	print("...finished creating data structures")

	# TraceViews will be increased in add_tab
	print("Loaded trace in tab " + str(len(TraceViews) - 1  + 1))
	return 0

#	print("Initial gfx setup...")
#	ResetTimespan()
#	StoreTimespan()
#	InitTimeLine()
#	InitMarkers()
#	PopulateViews(TRACE | INFO | SRC)
#	TCoreLabels.Init(self)
#	_show_all_cores(TActive)
#	print("...Initial gfx setup done")

func add_tab(file):
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

func ResetTimespan():
	Trace[TActive].TimeSpanStart = Trace[TActive].TimeStart
	Trace[TActive].TimeSpanEnd = Trace[TActive].TimeLineTS[len(Trace[TActive].TimeLineTS) - 1]
	Trace[TActive].TimeSpan = Trace[TActive].TimeSpanEnd - Trace[TActive].TimeSpanStart

func StoreTimespan():
	Trace[TActive].TimeSpanStartStored = Trace[TActive].TimeSpanStart
	Trace[TActive].TimeSpanEndStored = Trace[TActive].TimeSpanEnd
	Trace[TActive].TimeSpanStored = Trace[TActive].TimeSpan

func UndoTimespan():
	Trace[TActive].TimeSpanStart = Trace[TActive].TimeSpanStartStored
	Trace[TActive].TimeSpanEnd = Trace[TActive].TimeSpanEndStored
	Trace[TActive].TimeSpan = Trace[TActive].TimeSpanStored
	InitTimeLine()
	InitMarkers()
	UpdateTimeLine()
	PopulateViews(TRACE | SRC | INFO)
	UpdateMarkers()

func init(node):
	SceneController = node
	HexdumpSceneRef = SceneController.HexdumpSceneRef

	# Initial state
	print("dmce-wgui: started with args: " + str(OS.get_cmdline_args()))

	if len(OS.get_cmdline_args()) > 0 and OS.get_cmdline_args()[0] != "res://scene_controller.tscn":
		var file = OS.get_cmdline_args()[0]
		print("Loading " + file)

		if not FileAccess.file_exists(file):
			print("dmce-wgui: Could not open " + str(file))
		else:
			if file.ends_with(".zip"):
				LoadTrace(file, "bundle")
				print("Adding new tab: ", file)
				add_tab(file)
				SetActiveTrace(TActive)
				_show_all_cores(0)
			else:
				print("Unsupported file extension, please provide a .zip file.")
				# Here we come from prompt, so just exit
				get_tree().quit()
	else:
		print("dmce-wgui: No trace loaded from args")
		# dev state, uncomment for release:
		if len(OS.get_cmdline_args()) == 2 and OS.get_cmdline_args()[1] == "--dev":
			print("dmce-wgui: development mode")
			#var file = 'Path-to-default-trace'
			#LoadTrace(file, "bundle")
			#print("Adding new tab: ", file)
			#add_tab(file)
			#SetActiveTrace(TActive)
			#_show_all_cores(0)

	print("Rendering additional scenes")
	HexdumpSceneRef.visible = true

var a= 1
var b= 0
var DmceCacheDir
var DmceCacheDirPath
func _ready():
	print("OS: " + OS.get_distribution_name ())

	if OS.get_distribution_name() == "Windows":
		EditorExec = "notepad"
	else:
		EditorExec = "gvim"

	DmceCacheDirPath = OS.get_cache_dir() + "/dmce"
	DirAccess.make_dir_absolute(DmceCacheDirPath)
	DmceCacheDir = DirAccess.open(DmceCacheDirPath)
	DmceCacheDir.remove("*.*")

	# Node handles
	VSplitCTop 			= get_node("Background/VSplitTop")
	HSplitCTop 			= get_node("Background/VSplitTop/VBoxContainer/myHSplitContainerTop")
	HSplitSrcVars 		= get_node("Background/VSplitTop/VBoxContainer/myHSplitContainerTop/HSplitSrcVars")
	VSplitCBot			= get_node("Background/VSplitTop/VSplitBot")
	TopVBoxContainer 	= get_node("Background/VSplitTop/VBoxContainer")
	TChart 				= get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/TChartTab/TChartHBoxContainer/TChartPanel/TChart")
	TMarkers 			= get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/TChartTab/TChartHBoxContainer/TChartPanel/TMarkers")
	TChartBox 			= get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/TChartTab/TChartHBoxContainer/TChartPanel")
	TCoreLabels			= get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/TChartTab/TChartHBoxContainer/TCoreLabelsPanelContainer/TCoreLabels")
	TChartVScrollBar	= get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/TChartTab/TChartHBoxContainer/TChartVScrollBar")
	TChartTab			= get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/TChartTab")
	MovieContainer		= get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/HistoCoreActivityHSplitContainer/MovieTabContainer/MovieContainer")
	MovieChart			= get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/HistoCoreActivityHSplitContainer/MovieTabContainer/MovieContainer/MovieChartContainer/MovieChart")
	MovieChartContainer	= get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/HistoCoreActivityHSplitContainer/MovieTabContainer/MovieContainer/MovieChartContainer")
	CoreActivity		= get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/HistoCoreActivityHSplitContainer/LogCoreActivityHSplitContainer/CoreActivityTabContainer/CoreActivityRichTextLabel")
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
	SrcPopOutButton		= get_node("SrcPopOutButton")
	ShowLogButton		= get_node("ShowLogButton")
	TogglePerFuncOrCoreButton	= get_node("TogglePerFuncOrCoreButton")
	GenericAcceptDialog	= get_node("GenericAcceptDialog")
	ShowCurrentTraceInfoDialog = get_node("ShowCurrentTraceInfoDialog")
	AskForConfirmationDialog = get_node("AskForConfirmationDialog")
	SearchConfirmationDialog = get_node("SearchConfirmationDialog")
	CurrentTraceInfoLabel = get_node("ShowCurrentTraceInfoDialog/CurrentTraceInfoLabel")
	StatusLabel = get_node("Background/VSplitTop/VBoxContainer/StatusLabel")
	LineEditFindAll = get_node("SearchConfirmationDialog/VBoxContainerFindAll/LineEditFindAllSearchString")
	LineEditFindAllProbeNumber = get_node("SearchConfirmationDialog/VBoxContainerFindAll/LineEditFindAllProbenumber")
	TCMovieHSplitContainer = get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer")
	MainProgressBar = get_node("MainProgressBar")
	LogTabContainer = get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/HistoCoreActivityHSplitContainer/LogCoreActivityHSplitContainer/LogTabContainer")
	CoreActivityTabContainer = get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/HistoCoreActivityHSplitContainer/LogCoreActivityHSplitContainer/CoreActivityTabContainer")
	SrcViewScrollBar = SrcView.get_v_scroll_bar()
	LogRichTextLabel = get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/HistoCoreActivityHSplitContainer/LogCoreActivityHSplitContainer/LogTabContainer/LogVBoxContainer/LogRichTextLabel")
	MovieTabContainer = get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/HistoCoreActivityHSplitContainer/MovieTabContainer")
	LogFindLineEdit = get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/HistoCoreActivityHSplitContainer/LogCoreActivityHSplitContainer/LogTabContainer/LogVBoxContainer/HBoxContainer/LogSearchLineEdit")
	LogSearchNextButton = get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/HistoCoreActivityHSplitContainer/LogCoreActivityHSplitContainer/LogTabContainer/LogVBoxContainer/HBoxContainer/LogSearchNextButton")
	LogSearchPrevButton = get_node("Background/VSplitTop/VSplitBot/TCMovieHSplitContainer/HistoCoreActivityHSplitContainer/LogCoreActivityHSplitContainer/LogTabContainer/LogVBoxContainer/HBoxContainer/LogSearchPrevButton")
	re_remove_probe_type0 = RegEx.new()
	re_remove_probe_type0.compile("\\(DMCE_PROBE.*?\\),")
	re_remove_probe_type1begin = RegEx.new()
	re_remove_probe_type1begin.compile("{ do { DMCE_PROBE.*?;")
	re_remove_probe_type1end = RegEx.new()
	re_remove_probe_type1end.compile("\\} while \\(0\\);\\}")
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
	SrcPopOutButton.pressed.connect(self._src_pop_out_button_pressed)
	ShowLogButton.pressed.connect(self._show_log_button_pressed)
	TogglePerFuncOrCoreButton.pressed.connect(self._toggle_per_func_or_core_button_pressed)
	LogSearchNextButton.pressed.connect(self._log_search_next_button_pressed)
	LogSearchPrevButton.pressed.connect(self._log_search_prev_button_pressed)

	LogRichTextLabel.meta_clicked.connect(self._log_meta_clicked)
	LogFindLineEdit.text_submitted.connect(self._log_find_text_submitted)

	TChartTab.set_tab_title(0, "Cores")
	FTab.set_tab_title(0, "Functions")
	SrcTab.set_tab_title(0, "Source")
	VarsTab.set_tab_title(0, "Data")
	LogTabContainer.set_tab_title(0, "Log")
	CoreActivityTabContainer.set_tab_title(0, "Core activity")
	MovieTabContainer.set_tab_title(0, "Probe intensity")
	MovieChart.Update()

	$MenuBar/PopupMenuFile.name = " File "
	$MenuBar/PopupMenuView.name = " View "
	$MenuBar/PopupMenuSearch.name = " Search "
	$MenuBar/PopupMenuHelp.name = " Help "

	print("Rendering additional scenes")

func _src_pop_out_button_pressed():
	SrcPopOutButton.release_focus()
	if len(Trace) > 0:
		print(Trace[TActive].CurrentSrcFile)
		var reader = ZIPReader.new()
		var err = reader.open(Trace[TActive].filename)
		if err == OK:
			var rawfile = reader.read_file(Trace[TActive].CurrentSrcFile)
			reader.close()
			var tmp = Trace[TActive].CurrentSrcFile.split("/")
			var basename = tmp[len(tmp) - 1]
			var cachedfile = FileAccess.open(DmceCacheDirPath + "/" + basename, FileAccess.WRITE)
			cachedfile.store_string(rawfile.get_string_from_ascii())
			cachedfile.close()
			if EditorExec == "gvim":
				OS.create_process(EditorExec, [DmceCacheDirPath + "/" + basename, "&"])
			else:
				OS.execute(EditorExec, [DmceCacheDirPath + "/" + basename])
		else:
			print("Could not open file: " + Trace[TActive].filename)
			return

var oldVsplitTop = 0

func _show_src_button_pressed():
	ShowSrcButton.release_focus()
	if HSplitCTop.visible == false:
		HSplitCTop.visible = true
		VSplitTop = oldVsplitTop
	else:
		HSplitCTop.visible = false
		oldVsplitTop = VSplitTop
		VSplitTop = 0
	_resized()

func _show_log_button_pressed():
#	if len(Trace) > 0:
#		ShowLogButton.release_focus()
	print("Show log!")
#		self.grab_focus()
#		ShowCurrentTraceInfoDialog.popup_centered()
func _toggle_per_func_or_core_button_pressed():
	TogglePerFuncOrCoreButton.release_focus()
	if len(Trace) > 0:
		_toggle_func_per_core()

func _trace_info_button_pressed():
	if len(Trace) > 0:
		TraceInfoButton.release_focus()
		CurrentTraceInfoLabel.text = str("\n".join(Trace[TActive].TraceInfo))
		ShowCurrentTraceInfoDialog.popup_centered()
	else:
		TraceInfoButton.release_focus()
		CurrentTraceInfoLabel.text = " No trace loaded "
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

func _log_find_next(searchstr):
	CurrentLogSearchString = searchstr
	if Trace[TActive].index > 0:
		var i = Trace[TActive].LogSearchIndex
		i += 1
		if i >= len(Trace[TActive].LogPrintfLines):
			i = 0
		while true:
			if searchstr in Trace[TActive].LogPrintfLines[i]:
				LogRichTextLabel.scroll_to_line(i)
				Trace[TActive].LogSearchIndex = i
				break
			i += 1
			if i >= len(Trace[TActive].LogPrintfLines):
				i = 0
			if i == Trace[TActive].LogSearchIndex:
				break

func _log_find_prev(searchstr):
	CurrentLogSearchString = searchstr
	if Trace[TActive].index > 0:
		var i = Trace[TActive].LogSearchIndex
		i -= 1
		if i <= 0:
			i = len(Trace[TActive].LogPrintfLines) - 1
		while true:
			if searchstr in Trace[TActive].LogPrintfLines[i]:
				LogRichTextLabel.scroll_to_line(i)
				Trace[TActive].LogSearchIndex = i
				break
			i -= 1
			if i <= 0:
				i = len(Trace[TActive].LogPrintfLines) - 1
			if i == Trace[TActive].LogSearchIndex:
				break

func _log_search_next_button_pressed():
	_log_find_next(CurrentLogSearchString)
	LogSearchNextButton.release_focus()

func _log_search_prev_button_pressed():
	_log_find_prev(CurrentLogSearchString)
	LogSearchPrevButton.release_focus()

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

var CurrentLogSearchString = ""
func _log_find_text_submitted(text):
	LogFindLineEdit.release_focus()
	CurrentLogSearchString = LogFindLineEdit.text
	_log_find_next(LogFindLineEdit.text)

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

	SrcPopOutButton.position.x = ShowSrcButton.position.x - 110
	SrcPopOutButton.position.y = 3

	ShowLogButton.position.x = SrcPopOutButton.position.x - 110
	ShowLogButton.position.y = 3

	TogglePerFuncOrCoreButton.position.x = ShowLogButton.position.x - 80
	TogglePerFuncOrCoreButton.position.y = 3

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

var old_progress = 0

func _process(_delta):
	if WeAreBusy > 0:
		WeAreBusy -= 1

	# Initial setup
	if not InitDone:
		InitDone = true

	# Periodical update of state

	# Change in progress bar ?
	if int(MainProgressBar.value) != int(old_progress):
		old_progress = MainProgressBar.value
		queue_redraw()

	# Find all search ongoing?
	if FindAllSearchString != "" or FindAllProbeNumber != "":
		if FindAllThread.is_started() and not FindAllThread.is_alive():
			WeAreBusy = 10
			FindAllThread.wait_to_finish()
			FindLineEdit.text = FindAllSearchString
			CurrentSearchString = FindAllSearchString
			FindAllSearchString = ""
			FindAllProbeNumber = ""
			MainProgressBar.visible = false
			UpdateTimeLine()
			PopulateViews(SRC | TRACE)
		return

	# Trace being loaded?
	if LoaderFilename != "":
		WeAreBusy = 10
		if LoaderThread.is_started() and not LoaderThread.is_alive():
			LoaderThread.wait_to_finish()
			print("Adding new tab: ", LoaderFilename)
			# add_tab() will cause _trace_tab_changed() to be run, which will call SetActiveTrace, so no need to do that below
			add_tab(LoaderFilename)
#			print("Process():")
#			SetActiveTrace(TActive)
			_show_all_cores(TActive)
			LoaderFilename = ""
		return

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

func strafe_left():
	var speed = int(float(Trace[TActive].TimeSpan) * 0.1)
	if Trace[TActive].TimeSpanStart - speed < Trace[TActive].TimeStart:
		Trace[TActive].TimeSpanStart = Trace[TActive].TimeStart
		Trace[TActive].TimeSpanEnd = Trace[TActive].TimeStart + Trace[TActive].TimeSpan
	else:
		Trace[TActive].TimeSpanStart = Trace[TActive].TimeSpanStart - speed
		Trace[TActive].TimeSpanEnd = Trace[TActive].TimeSpanEnd - speed

	Trace[TActive].TimeSpan = Trace[TActive].TimeSpanEnd - Trace[TActive].TimeSpanStart
	UpdateTimeLine()
	UpdateMarkers()

func strafe_right():
	var speed = int(float(Trace[TActive].TimeSpan) * 0.1)
	if Trace[TActive].TimeSpanEnd + speed > Trace[TActive].TimeEnd:
		Trace[TActive].TimeSpanStart = Trace[TActive].TimeEnd - Trace[TActive].TimeSpan
		Trace[TActive].TimeSpanEnd = Trace[TActive].TimeEnd
	else:
		Trace[TActive].TimeSpanStart = Trace[TActive].TimeSpanStart + speed
		Trace[TActive].TimeSpanEnd = Trace[TActive].TimeSpanEnd + speed

	Trace[TActive].TimeSpan = Trace[TActive].TimeSpanEnd - Trace[TActive].TimeSpanStart
	UpdateTimeLine()
	UpdateMarkers()

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

func _in_tchart():
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

func _in_corelist():
	if TChartBox.get_local_mouse_position().y  > 0 and TChartBox.get_local_mouse_position().x < TChartXOffset - 10:
		return true
	return false

func _in_fchart():
	if FChartBox.get_local_mouse_position().y  > 0 and FChartBox.get_local_mouse_position().y < FChartBox.size.y:
		if FChartBox.get_local_mouse_position().x > 0 and FChartBox.get_local_mouse_position().x < FChartBox.size.x:
			return true
	return false

func _in_fnames():
	if FChartBox.get_local_mouse_position().y  > 0 and FChartBox.get_local_mouse_position().y < FChartBox.size.y:
		if FChartBox.get_local_mouse_position().x < 0:
			return true
	return false

var KEY_CTRL = 4194326

func _input(ev):
	if not Active or WeAreBusy > 0:
		return
	if  len(Trace) == 0:
		return
	if ev is InputEventKey:
		if ev.pressed:
			if FindLineEdit.has_focus():
				if ev.keycode == KEY_ESCAPE:
					FindLineEdit.release_focus()
				return
			elif LogFindLineEdit.has_focus():
				if ev.keycode == KEY_ESCAPE:
					LogFindLineEdit.release_focus()
				return
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
				if ev.keycode == KEY_LEFT or ev.keycode == KEY_A:
					strafe_left()
				elif ev.keycode == KEY_RIGHT or ev.keycode == KEY_D:
					strafe_right()
				elif ev.keycode == KEY_W:
					TChart.MouseWheelUp()
				elif ev.keycode == KEY_S:
					TChart.MouseWheelDown()
				elif ev.keycode == KEY_PAGEUP:
					trace_pup()
				elif ev.keycode == KEY_PAGEDOWN:
					trace_pdown()
				elif ev.keycode == KEY_P:
					if ShowProbes == false:
						ShowProbes = true
					else:
						ShowProbes = false
					PopulateViews(TRACE | SRC)
				elif ev.keycode == KEY_G:
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
					if Input.is_physical_key_pressed(KEY_CTRL):
						UndoTimespan()
					else:
						ResetTimespan()
						InitTimeLine()
						InitMarkers()
						UpdateTimeLine()
						PopulateViews(TRACE | SRC | INFO)
						UpdateMarkers()
				elif ev.keycode == KEY_PERIOD:
						TChart.MouseWheelUp()
				elif ev.keycode == KEY_COMMA:
						TChart.MouseWheelDown()
				elif ev.keycode == KEY_F and Input.is_physical_key_pressed(KEY_CTRL):
					FindLineEdit.grab_focus()
				elif ev.keycode == KEY_SPACE:
					deb_func()
				elif ev.keycode == KEY_H:
					if len(Trace[TActive].HexDumpTraceEntryIndex) > 0:
						HexdumpSceneRef.Activate()
						self.visible = false
						Deactivate()
					else:
						print("No hexdump available in active trace!")
		else:
			PopulateViews(SRC | INFO)
			UpdateMarkers()

	if ev is InputEventMouseButton and (_in_tchart() or _in_fchart() ):
		if (ev.button_index == MOUSE_BUTTON_WHEEL_UP) and ev.pressed:
			TChart.MouseWheelUp()
		elif (ev.button_index == MOUSE_BUTTON_WHEEL_DOWN) and ev.pressed:
			TChart.MouseWheelDown()

	if ev is InputEventMouseButton and (_in_fnames()):
		if (ev.button_index == MOUSE_BUTTON_WHEEL_UP) and ev.pressed:
			FChart.MouseWheelUp()
		elif (ev.button_index == MOUSE_BUTTON_WHEEL_DOWN) and ev.pressed:
			FChart.MouseWheelDown()

	if ev is InputEventMouseButton and _in_tchart():
		if ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			TChart.MouseLeftPressed()
		elif ev.button_index == MOUSE_BUTTON_RIGHT and ev.pressed:
			TChart.MouseRightPressed()
		elif ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed:
			TChart.MouseLeftReleased()
		elif ev.button_index == MOUSE_BUTTON_RIGHT and not ev.pressed:
			TChart.MouseRightReleased()

	if ev is InputEventMouseMotion and _in_tchart():
		TChart.MouseMoved()

	if ev is InputEventMouseMotion and _in_moviebox():
		MovieChart.MouseMoved()

	if ev is InputEventMouseButton and _in_moviebox():
		if ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			MovieChart.MouseLeftPressed()

	if ev is InputEventMouseButton and _in_corelist():
		if ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			TCoreLabels.MouseLeftPressed()

	if ev is InputEventMouseButton and _in_fchart():
		if ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			FChart.MouseLeftPressed()
		elif ev.button_index == MOUSE_BUTTON_RIGHT and ev.pressed:
			FChart.MouseRightPressed()
		elif ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed:
			FChart.MouseLeftReleased()
		elif ev.button_index == MOUSE_BUTTON_RIGHT and not ev.pressed:
			FChart.MouseRightReleased()

	if ev is InputEventMouseMotion and _in_fchart():
		FChart.MouseMoved()

func ToggleShowCoreChartGrid():
	if ShowCoreChartGrid == false:
		ShowCoreChartGrid = true
	else:
		ShowCoreChartGrid = false
	UpdateTimeLine()
	UpdateMarkers()

func _log_meta_clicked(meta):
	_trace_view_meta_clicked(meta)

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
	elif id == 1 and len(Trace) > 0:
		AskForConfirmationDialog.dialog_text = "Do you really want to close active trace?"
		AskForConfirmationDialog.confirmed.connect(self._confirm_close_trace)
		AskForConfirmationDialog.popup_centered()
	elif id == 2:
		AskForConfirmationDialog.dialog_text = "Do you really want to quit?"
		AskForConfirmationDialog.confirmed.connect(self._confirm_quit)
		AskForConfirmationDialog.popup_centered()

func _toggle_show_original_src_path():
	if ShowFullPath == true:
		ShowFullPath = false
	else:
		ShowFullPath = true
	PopulateViews(TRACE)

func _toggle_show_histogram():
	if MovieTabContainer.visible == true:
		MovieTabContainer.visible = false
	else:
		MovieTabContainer.visible = true

func _toggle_core_activity():
	if CoreActivityTabContainer.visible == true:
		CoreActivityTabContainer.visible = false
	else:
		CoreActivityTabContainer.visible = true

func _toggle_show_log():
	if LogTabContainer.visible == true:
		LogTabContainer.visible = false
	else:
		LogTabContainer.visible = true

func _toggle_lossless():
	if LossLess == false:
		LossLess = true
	else:
		LossLess = false

func _toggle_func_per_core():
	if Trace[TActive].FuncPerCore == false:
		Trace[TActive].FuncPerCore = true
		FTab.set_tab_title(0, "Cores")
	else:
		Trace[TActive].FuncPerCore = false
		FTab.set_tab_title(0, "Functions")

	PopulateViews(SRC | INFO | TRACE)
	InitTimeLine()
	UpdateTimeLine()
	UpdateMarkers()

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
	elif id == 8:
		_toggle_show_log()
		MenuView.set_item_checked( 8, not MenuView.is_item_checked(8))

	# Some final common stuff
	if CoreActivity.visible || MovieContainer.visible:
		MainExtas.visible = true
	else:
		MainExtas.visible = false

func FindAllThreadFunc(s, pnum):
	var sindex = 0
	var tmpresults = []
	var thispnum = ""
	var probestring = ""
	MainProgressBar.visible = true
	while sindex < len(Trace[TActive].tracebuffer):
		MainProgressBar.value = 100 * (float(sindex) / len(Trace[TActive].tracebuffer))
		var m = re_get_probenbr.search(Trace[TActive].tracebuffer[sindex])
		if m:
			thispnum = m.get_string(1)
		if (s in Trace[TActive].tracebuffer[sindex]) or (m and (thispnum == pnum)):
			tmpresults.append(Trace[TActive].TimeLineTS[sindex])
		sindex += 1

	Trace[TActive].FindAllMarkers = tmpresults
	MainProgressBar.visible = false

var FindAllThread = null
var FindAllSearchString = ""

func _confirm_find_all():
	FindAllThread = Thread.new()
	FindAllSearchString = LineEditFindAll.text
	FindAllProbeNumber = LineEditFindAllProbeNumber.text
	FindAllThread.start(FindAllThreadFunc.bind(FindAllSearchString, FindAllProbeNumber))

func _find_all():
	SearchConfirmationDialog.title = "Find all"
	SearchConfirmationDialog.confirmed.connect(self._confirm_find_all)
	SearchConfirmationDialog.register_text_enter(LineEditFindAll)
	SearchConfirmationDialog.register_text_enter(LineEditFindAllProbeNumber)
	SearchConfirmationDialog.popup_centered()
	LineEditFindAll.grab_focus()

func _menu_search_pressed(id):
	if len(Trace) == 0:
		return
	if id == 0:
		print("Find all")
		_find_all()
	elif id == 1:
		if SearchShowAll:
			SearchShowAll = false
		else:
			SearchShowAll = true
		MenuSearch.set_item_checked( 1, not MenuSearch.is_item_checked(1))
		UpdateTimeLine()

func _menu_help_pressed(id):
	if id == 0:
		var ht = "Mouse and keyboard\n"
		ht += "================================\n"
		ht += "UP / DOWN - Move one trace entry up / down\n"
		ht += "PAGE UP / DOWN - Move several trace entries up / down\n"
		ht += "LEFT/A / RIGHT/D - Strafe left / right\n"
		ht += "Mouse wheel forward/back or comma / period - Zoom in / out or W / S\n"
		ht += "Left-click - Set cursor\n"
		ht += "Right-click-and-hold - select zoom window\n"
		ht += "CTRL-right-click-and-hold - measure time without zooming when released\n"
		ht += "G - jump to beginning of trace\n"
		ht += "SHIFT-G - jump to end of trace\n"
		ht += "H - Enter hexviewer (hexdumps created with DMCE_HEXDUMP())\n"
		ht += "Z - Reset zoom level\n"
		ht += "CTRL-Z - Restore previous zoom level\n"
		ht += "P - Toggle inserted probes visible\n"
		ht += "\n"
		ht += "Other\n"
		ht += "================================\n"
		ht += "Select / Deselect cores by clicking on respective number in the 'Cores' view\n"
		ht += "Darker shades of blue markers in the 'Source' view indicates previously viewed lines when stepping \n"

		GenericAcceptDialog.title = "Help"
		GenericAcceptDialog.dialog_text = ht
		GenericAcceptDialog.popup_centered()
	elif id == 1:
		var ht = ""
		ht += ""
		ht += "Copyright (c) 2023 Ericsson AB\n"
		ht += "\n"
		ht += "Permission is hereby granted, free of charge, to any person obtaining a copy\n"
		ht += "of this software and associated documentation files (the \"Software\"), to deal\n"
		ht += "in the Software without restriction, including without limitation the rights\n"
		ht += "to use, copy, modify, merge, publish, distribute, sublicense, and/or sell\n"
		ht += "copies of the Software, and to permit persons to whom the Software is\n"
		ht += "furnished to do so, subject to the following conditions:\n"
		ht += "\n"
		ht += "The above copyright notice and this permission notice shall be included in all\n"
		ht += "copies or substantial portions of the Software.\n"
		ht += "\n"
		ht += "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\n"
		ht += "IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\n"
		ht += "FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\n"
		ht += "AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\n"
		ht += "LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\n"
		ht += "OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\n"
		ht += "SOFTWARE.\n"

		GenericAcceptDialog.dialog_text = ht
		GenericAcceptDialog.title = "dmce-wgui version 2.0"
		GenericAcceptDialog.popup_centered()

func _funcvscrollbar_value_changed(val):
	Trace[TActive].FuncVScrollBarIndex = FuncVScrollBar.value
	FChart.UpdateScrollPosition()

func _tchartvscrollbar_value_changed(val):
	Trace[TActive].TChartVScrollBarIndex = TChartVScrollBar.value
	TChart.UpdateScrollPosition()
	TCoreLabels.Init(self)

var LoaderThread = null
var LoaderFilename = ""

func LoaderThreadFunc(file):
	LoadTrace(file, "bundle")

func _open_trace_selected(file):
	OpenTraceDialog.visible = false
	LoaderThread = Thread.new()
	LoaderFilename = file
	LoaderThread.start(LoaderThreadFunc.bind(file))

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

	# Log view
	LogRichTextLabel.text = Trace[TActive].LogPrintf
	LogRichTextLabel.scroll_to_line(Trace[TActive].LogSearchIndex)

	TCoreLabels.Init(self)
	FuncVScrollBar.value = Trace[TActive].FuncVScrollBarIndex
	print("Hexdumps found, loading hexdump scene...")
	if len(Trace[TActive].HexDumpTraceEntryIndex) > 0:
		SceneController.HexdumpSceneRef.Load()

##########################
# Scratch space
func deb_func():
	print("DEB " + str(debcnt))
	debcnt += 1
##########################
