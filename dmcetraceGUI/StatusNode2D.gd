extends Node2D

var DataNode2D
var inited = false
var tgui
var ControlPanelContainer

func Init(node):
	DataNode2D = node
	tgui = DataNode2D.tgui
	inited = true

func _draw():
	if inited:
		if DataNode2D.NumHexdumps > 2:
# Save this and use if we want to switch bwetween first/last hexdump timespan and the main one
#			var FirstTS = int(tgui.Trace[tgui.TActive].HexDumpTraceEntry[tgui.Trace[tgui.TActive].HexDumpTraceEntryIndex[0]][1])
#			var LastTS = int(tgui.Trace[tgui.TActive].HexDumpTraceEntry[tgui.Trace[tgui.TActive].HexDumpTraceEntryIndex[-1]][1])
#			var SpanTS = LastTS - FirstTS
#			var ratio = float(ControlPanelContainer.size.x) / float(SpanTS)

			var ratio = float(ControlPanelContainer.size.x - 20) / float(tgui.Trace[tgui.TActive].TimeSpan)
			for i in range(DataNode2D.NumHexdumps):
				var ts = int(tgui.Trace[tgui.TActive].HexDumpTraceEntry[tgui.Trace[tgui.TActive].HexDumpTraceEntryIndex[i]][1])
				ts = ts - tgui.Trace[tgui.TActive].TimeStart
				var tlx = int(ts * ratio)
				var tly = 16
				if i == DataNode2D.index:
					draw_rect(Rect2(tlx, tly, 1, 30), Color(0.2, 0.6, 0.2, 1.0), false)
				else:
					draw_rect(Rect2(tlx, tly, 1, 30), Color(0.5, 0.5, 0.5, 1.0), false)

#			draw_rect(Rect2(8, 16 - 2, ControlPanelContainer.size.x - 8, 30 + 2), Color(0.7, 0.7, 0.7, 1.0), false)

func Update():
	queue_redraw()


# Called when the node enters the scene tree for the first time.
func _ready():
	ControlPanelContainer = get_node("../../ControlPanelContainer")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
