extends Node2D

var SCROLL_VISIBLE_HEXDUMPS = 10
var SLIDER_VISIBLE_HEXDUMPS = 3
var HEXDUMP_WIDTH = 500
var tgui
var HDLabels = []
var lsettings = []
var count = 0
var HexdumpsPanelContainer
var HDLabelTemplate
var TraceGUI_scene
var Active = false
var inited = false
#var Active = true
#var inited = true
var MainWindowSize
var index = 1

func ClearScreen():
	for hdl in HDLabels:
		hdl.visible = false
	queue_redraw()

func _draw():
	MainWindowSize = get_tree().root.size
	draw_rect(Rect2(0,0, MainWindowSize.x, MainWindowSize.y), Color(0.15, 0.15, 0.15, 1.0), true)

func PopulateScreen():
	ClearScreen()
	var sindex = index - (SLIDER_VISIBLE_HEXDUMPS / 2)
	var xpos = 100
	var ypos = 100
	for i in range(SLIDER_VISIBLE_HEXDUMPS):
		if sindex >= 0:
			HDLabels[sindex].position.x = xpos
			HDLabels[sindex].position.y = ypos
			HDLabels[sindex].visible = true
		sindex += 1
		xpos += HEXDUMP_WIDTH

# Called when the node enters the scene tree for the first time.
func _ready():
	HDLabelTemplate = get_node("HDLabelTemplate")
	for i in range (SCROLL_VISIBLE_HEXDUMPS):
		var lset = LabelSettings.new()
		lset.font_size = 32 - i
		lset.font_color = Color(1,1,1,float(1) / ((float(i) / 2) + 1))
		lsettings.append(lset)

	print("Hexdump viewer ready")

func Load():
	print(len(tgui.Trace[tgui.TActive].HexDump))
	print(len(tgui.Trace[tgui.TActive].HexDumpTraceEntry))
	print(len(tgui.Trace[tgui.TActive].HexDumpTraceEntryIndex))
	for i in range(len(tgui.Trace[tgui.TActive].HexDumpTraceEntryIndex)):
		print("te index " + str(i) + ": " + str(tgui.Trace[tgui.TActive].HexDumpTraceEntryIndex[i]))
	var debug = tgui.Trace[tgui.TActive].HexDumpTraceEntryIndex[0]
	print("Short index: " + str(debug))
	print(tgui.Trace[tgui.TActive].HexDumpTraceEntry[debug])
	for i in range(len(tgui.Trace[tgui.TActive].HexDumpTraceEntry)):
		if tgui.Trace[tgui.TActive].HexDumpTraceEntry[i] != null:
			print("Entry: " + str(i) + "   :" + " ".join(tgui.Trace[tgui.TActive].HexDumpTraceEntry[i]))
	for i in range(len(tgui.Trace[tgui.TActive].HexDumpTraceEntryIndex)):
		var hdtmp = HDLabelTemplate.duplicate()
		hdtmp.visible = false
		var s = " ".join(tgui.Trace[tgui.TActive].HexDumpTraceEntry[tgui.Trace[tgui.TActive].HexDumpTraceEntryIndex[i]])
		s += "\n" + tgui.Trace[tgui.TActive].HexDump[tgui.Trace[tgui.TActive].HexDumpTraceEntryIndex[i]]
		hdtmp.text = s
		HDLabels.append(hdtmp)
		add_child(hdtmp)
	PopulateScreen()

func init(node):
	tgui = node.TraceGuiSceneRef
	inited = true
	print("Hexdump support init done")

func Activate():
	Active = true

func _input(ev):
	if inited and Active:
		if ev is InputEventKey:
			if ev.pressed:
				if ev.keycode == KEY_ESCAPE:
					tgui.visible = true
					self.visible = false
					Active = false

func _process(delta):
	pass

func _processflash(delta):
	if inited and Active:
		MainWindowSize = get_tree().root.size
#		OS.delay_msec(100)
		count += 1
		if count == 10:
			count = 0

		self.visible = true
		HDLabels[0].visible = true
		HDLabels[0].label_settings = lsettings[count]
		HDLabels[0].text = "Hexdump!"
		HDLabels[0].position.x += count
		HDLabels[0].position.y += count
		if HDLabels[0].position.x > 1200:
			HDLabels[0].position.x = 0
			HDLabels[0].position.y = 0
