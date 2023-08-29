extends RichTextLabel

var tgui = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func Init(node):
	print("CoreActivty init")
	tgui = node

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
				var funcname = "[ No entry ]"
				var glob_index = ""
				if findex > 0:
					if findex >= len(tgui.Trace[tgui.TActive].FTree[core]) || ts != tgui.Trace[tgui.TActive].FTree[core][findex].tstart:
						findex -= 1
					funcname = tgui.Trace[tgui.TActive].FTree[core][findex].pathfunc + " " + tgui.Trace[tgui.TActive].FTree[core][findex].linenbr
					glob_index = str(tgui.Trace[tgui.TActive].FTree[core][findex].index)
				buf += "Core: " + str(core) + "    " + glob_index + " "+ funcname + "\n"
		self.text = buf
