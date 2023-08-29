extends RichTextLabel

var tgui = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _meta_clicked(meta):
	tgui.Trace[tgui.TActive].index = int(meta)
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
				var funcname = "Core: " + str(core) + "    [ No entry ]\n"
				var glob_index = -1
				if findex > 0:
					if findex >= len(tgui.Trace[tgui.TActive].FTree[core]) || ts != tgui.Trace[tgui.TActive].FTree[core][findex].tstart:
						findex -= 1
					funcname = tgui.Trace[tgui.TActive].FTree[core][findex].pathfunc + " " + tgui.Trace[tgui.TActive].FTree[core][findex].linenbr
					glob_index = tgui.Trace[tgui.TActive].TimeLineTS.bsearch(tgui.Trace[tgui.TActive].FTree[core][findex].tstart)
				if glob_index == -1:
					buf += funcname
				else:
					buf += "[url=" + str(glob_index) + "]Core: " + str(core) + "    " + str(glob_index) + " " + funcname + "[/url]\n"
		self.text = buf
