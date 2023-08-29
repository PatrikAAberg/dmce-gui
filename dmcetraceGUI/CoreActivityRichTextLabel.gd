extends RichTextLabel

var tgui = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _meta_clicked(meta):
	meta = int(meta)
	if int(tgui.Trace[tgui.TActive].TimeLineTS[meta]) < tgui.Trace[tgui.TActive].TimeSpanStart or int(tgui.Trace[tgui.TActive].TimeLineTS[meta]) > tgui.Trace[tgui.TActive].TimeSpanEnd:
		tgui.ResetTimespan()
	tgui.Trace[tgui.TActive].index = meta
	tgui.TraceViewScrollTop = tgui.Trace[tgui.TActive].index - int(tgui.TraceViewVisibleLines / 2)
	tgui.PopulateViews(tgui.SRC | tgui.INFO | tgui.TRACE)
	tgui.UpdateTimeLine()
	tgui.UpdateMarkers()


func Init(node):
	print("CoreActivty init")
	tgui = node
	self.meta_clicked.connect(self._meta_clicked)

# Get index of the start to the left
func _compare_start(a,b):
	return a.tstart < b.tstart

func Update():
	if tgui != null:
		var index = tgui.Trace[tgui.TActive].index
		var ts = int(tgui.Trace[tgui.TActive].TimeLineTS[index])
		var buf = ""
		var timenow = { tstart = ts }
		for core in range(len(tgui.Trace[tgui.TActive].FTree)):
			if tgui.Trace[tgui.TActive].FTree[core] != null:
				var findex = tgui.Trace[tgui.TActive].FTree[core].bsearch_custom(timenow, _compare_start)
				var fname = "Core: " + str(core) + "    [ No entry ]\n"
				var glob_index = -1
				if findex > 0:
					if findex >= len(tgui.Trace[tgui.TActive].FTree[core]) || ts != tgui.Trace[tgui.TActive].FTree[core][findex].tstart:
						findex -= 1
					glob_index = tgui.Trace[tgui.TActive].TimeLineTS.bsearch(tgui.Trace[tgui.TActive].FTree[core][findex].tstart)
					# Check for special case where there are several entries with same timestamp, we always seem to get the top one.
					while tgui.Trace[tgui.TActive].TimeLineTS[glob_index] == tgui.Trace[tgui.TActive].TimeLineTS[glob_index + 1] && core != int(tgui.Trace[tgui.TActive].tracebuffer[glob_index].split("@")[0]):
						glob_index += 1
					fname = tgui.Trace[tgui.TActive].tracebuffer[glob_index]
					fname = fname.split("@")[2] + " " + fname.split("@")[3] + " " + fname.split("@")[4]
				if glob_index == -1:
					buf += fname
				else:
					var timediff = tgui.Trace[tgui.TActive].FTree[core][findex].tstart - ts
					buf += "[url=" + str(glob_index) + "]Core: " + str(core) + "  Index: " + str(glob_index) + "  Distance(ns): " + str(timediff) + "  " + fname + "[/url]\n"
		self.text = buf
