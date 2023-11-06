extends Node2D

var SCROLL_VISIBLE_HEXDUMPS = 10
var SLIDER_VISIBLE_HEXDUMPS = 3
var HEXDUMP_WIDTH = 80
var HexdumpWidthPixels
var tgui
var hexdump
var HDLabels = []
var HDLabelsText = []
var lsettings = []
var count = 0
var HexdumpsPanelContainer
var HDLabelTemplate
var HDRichTextLabelTemplate
var TraceGUI_scene
var Active = false
var Inited = false
var MainWindowSize
var index
var indexwanted
var yoffset = 0
var xscrolloffset = 0
var FontHeight
var FontWidth
var NumHexdumps = 0
var HexDumpMaxLines
var HexdumpScrollBar
var RightPos
var LeftPos
var ShowDiffPrev = false
var ShowDiffAll = false
var StatusNode2d
var KEY_CTRL = 4194326
var NextButton
var PrevButton
var HexdumpFindLineEdit

func get_diff_positions_prev():
	var difflist = []
	if index < NumHexdumps - 1:
		var left = tgui.Trace[tgui.TActive].HexDumpRaw[tgui.Trace[tgui.TActive].HexDumpTraceEntryIndex[index]]
		var right = tgui.Trace[tgui.TActive].HexDumpRaw[tgui.Trace[tgui.TActive].HexDumpTraceEntryIndex[index + 1]]
		left = left.split(" ")
		right = right.split(" ")
		var i = 1 					# first element is name of the hexdump, skip it
		while i < len(left) and i < len(right):
			if left[i] != right[i]:
				difflist.append(i - 1)
			i += 1
	return difflist

func get_diff_all_positions_prev():
	var difflist = []
	if index < NumHexdumps - 1:
		for dindex in range(0, index):
			var left = tgui.Trace[tgui.TActive].HexDumpRaw[tgui.Trace[tgui.TActive].HexDumpTraceEntryIndex[dindex]]
			var right = tgui.Trace[tgui.TActive].HexDumpRaw[tgui.Trace[tgui.TActive].HexDumpTraceEntryIndex[index + 1]]
			left = left.split(" ")
			right = right.split(" ")
			var i = 1 					# first element is name of the hexdump, skip it
			while i < len(left) and i < len(right):
				if left[i] != right[i]:
					difflist.append(i - 1)
				i += 1
	return difflist

func get_search_positions(sindex):
	var content = HDLabelsText[sindex]
	var dindex = 0
	var result = []
	if SearchText != "":
		while true:
			var bytepos = content.find(SearchText, dindex)
			if bytepos == -1:
				break
			else:
				var pos = bytepos
				for a in range(len(SearchText)):
					result.append(a + pos)
			dindex = bytepos + 1
	return result

func _draw():
	if Inited and Active:
		MainWindowSize = hexdump.MainWindowSize
		draw_rect(Rect2(-MainWindowSize.x, 0, MainWindowSize.x * 3, MainWindowSize.y * 10), Color(0.1, 0.1, 0.1, 1.0), true)

		if ShowDiffAll:
			for imarker in get_diff_all_positions_prev():
				var ypos = (imarker / 16) * FontHeight + FontHeight * 8 + RightPos.y
				var xpos = 7 * FontWidth + (imarker % 16) * 3 * FontWidth + RightPos.x
				draw_rect(Rect2(xpos, ypos, FontWidth * 2, FontHeight), Color(0.1, 0.1, 0.5, 1.0), true)

		if ShowDiffPrev:
			for imarker in get_diff_positions_prev():
				var ypos = (imarker / 16) * FontHeight + FontHeight * 8 + RightPos.y
				var xpos = 7 * FontWidth + (imarker % 16) * 3 * FontWidth + RightPos.x
				draw_rect(Rect2(xpos, ypos, FontWidth * 2, FontHeight), Color(0.2, 0.2, 0.9, 1.0), true)

		if SearchText != "":
			var offset = LeftPos
			var sindex = index

			for imarker in get_search_positions(sindex):
				var linewidth = 7 + 16 * 4 + 1 # including end of line character
				var ypos = (imarker / linewidth) * FontHeight + offset.y
				var xpos = (imarker % linewidth) * FontWidth + offset.x
				draw_rect(Rect2(xpos, ypos, FontWidth, FontHeight), Color(0.5, 0.5, 0.5, 1.0), true)

			if NumHexdumps > 1:
				offset = RightPos
				for imarker in get_search_positions(index + 1):
					var linewidth = 7 + 16 * 4 + 1 # including end of line character
					var ypos = (imarker / linewidth) * FontHeight + offset.y
					var xpos = (imarker % linewidth) * FontWidth + offset.x
					draw_rect(Rect2(xpos, ypos, FontWidth, FontHeight), Color(0.5, 0.5, 0.5, 1.0), true)

func scroll_set():
	if yoffset < -((HexDumpMaxLines) * FontHeight):
		yoffset = -(HexDumpMaxLines) * FontHeight
	elif yoffset > 0:
		yoffset = 0
	self.position.y = yoffset
#	for hdl in HDLabels:
#		hdl.position.y = yoffset

func scroll_up():
	yoffset -= FontHeight
	scroll_set()

func scroll_down():
	yoffset += FontHeight
	scroll_set()

func scroll_page_up():
	yoffset -= FontHeight * 20
	scroll_set()

func scroll_page_down():
	yoffset += FontHeight * 20
	scroll_set()

func PopulateScreen():
	for i in range(SLIDER_VISIBLE_HEXDUMPS):
		if (index - 1 + i < 0) or (index - 1 + i) > (NumHexdumps - 1):
			HDLabels[i].text = HDLabelsText[0] # If first index, fill both with same
		else:
			HDLabels[i].text = HDLabelsText[index - 1 + i]
		RightPos = HDLabels[2].position
		LeftPos = HDLabels[1].position
#	print("Index: " + str(index) + "X, Y: " + str(RightPos))
	StatusNode2d.Update()
	queue_redraw()

func _value_changed(val):
	if val > NumHexdumps - 1:
		val = NumHexdumps - 1
	indexwanted = val
	index = indexwanted
	HexdumpScrollBar.value = indexwanted
	PopulateScreen()

# Called when the node enters the scene tree for the first time.
func _ready():
	HDLabelTemplate = get_node("../../../HDLabelTemplate")
	HDRichTextLabelTemplate = get_node("../../../HDRichTextLabelTemplate")
	HexdumpScrollBar = get_node("../../ControlButtonsHBoxContainer/ScrollSearchVBoxContainer/ControlPanelContainer/HexdumpHScrollBar")
	HexdumpScrollBar.value_changed.connect(self._value_changed)
	StatusNode2d = get_node("../../ControlButtonsHBoxContainer/ScrollSearchVBoxContainer/ControlPanelContainer/StatusNode2D")
	NextButton = get_node("../../ControlButtonsHBoxContainer/ScrollSearchVBoxContainer/SearchPanelContainer/VBoxContainer/HBoxContainer/NextButton")
	PrevButton = get_node("../../ControlButtonsHBoxContainer/ScrollSearchVBoxContainer/SearchPanelContainer/VBoxContainer/HBoxContainer/PrevButton")
	HexdumpFindLineEdit = get_node("../../ControlButtonsHBoxContainer/ScrollSearchVBoxContainer/SearchPanelContainer/VBoxContainer/HBoxContainer/HexdumpFindLineEdit")

	NextButton.pressed.connect(self._next_button_pressed)
	PrevButton.pressed.connect(self._prev_button_pressed)
	HexdumpFindLineEdit.text_submitted.connect(self._find_text_submitted)

	FontHeight = HDRichTextLabelTemplate.get_content_height()
	FontWidth = HDRichTextLabelTemplate.size.x / 10

	var lsetmain = LabelSettings.new()
	lsetmain.font_color = Color(0.9, 0.9, 0.9, 1.0)

	HexdumpWidthPixels = FontWidth * HEXDUMP_WIDTH

	var xpos = 80 - HexdumpWidthPixels
	for i in range(SLIDER_VISIBLE_HEXDUMPS):
		var hdtmp = HDRichTextLabelTemplate.duplicate()
		hdtmp.position.x = xpos
		hdtmp.visible = true
		hdtmp.selection_enabled = true
#		hdtmp.label_settings = lsetmain
		xpos += HexdumpWidthPixels
		add_child(hdtmp)
		HDLabels.append(hdtmp)

	for i in range (SCROLL_VISIBLE_HEXDUMPS):
		var lset = LabelSettings.new()
		lset.font_size = 32 - i
		lset.font_color = Color(1,1,1,float(1) / ((float(i) / 2) + 1))
		lsettings.append(lset)

	print("Hexdump viewer ready")

var SearchText = ""

func _find_text_submitted(text):
	HexdumpFindLineEdit.release_focus()
	SearchText = text

	# Search from start to the right
	var i = 0
	while i < NumHexdumps:
		if SearchText in HDLabelsText[i]:
			if i >= NumHexdumps - 2:
				i = NumHexdumps - 2
			indexwanted = i
			index = i
			HexdumpScrollBar.set_value_no_signal(indexwanted)
			PopulateScreen()
			break
		i += 1

func _next_button_pressed():
	NextButton.release_focus()
	SearchText = HexdumpFindLineEdit.text

	# Search from index + 1 to the right
	var i = index + 1
	while i < NumHexdumps:
		if SearchText in HDLabelsText[i]:
			if i >= NumHexdumps - 2:
				i = NumHexdumps - 2
			indexwanted = i
			index = i
			HexdumpScrollBar.set_value_no_signal(indexwanted)
			PopulateScreen()
			break
		i += 1


func _prev_button_pressed():
	NextButton.release_focus()
	SearchText = HexdumpFindLineEdit.text

	# Search from index - 1 to the left
	var i = index - 1
	while i >= 0:
		if SearchText in HDLabelsText[i]:
			indexwanted = i
			index = i
			HexdumpScrollBar.set_value_no_signal(indexwanted)
			PopulateScreen()
			break
		i -= 1

func Load():
	NumHexdumps = len(tgui.Trace[tgui.TActive].HexDumpTraceEntryIndex)
	HexDumpMaxLines = 0
	HDLabelsText = []

	for i in range(NumHexdumps):
		var hdtmp = HDRichTextLabelTemplate.duplicate()
		hdtmp.visible = false
		var pad = 7 + 16 * 4
		var tl = tgui.Trace[tgui.TActive].HexDumpTraceEntry[tgui.Trace[tgui.TActive].HexDumpTraceEntryIndex[i]]
		var s =  ("Hexdump:    " + str(i)).rpad(pad, " ") + "\n"
		s += ("Core:       " + str(tl[0])).rpad(pad, " ") + "\n"
		s += ("Timestamp:  " + str(tl[1])).rpad(pad, " ") + "\n"
		s += ("File/line:  " + (str(tl[2]) + " " + str(tl[3]))).rpad(pad, " ") + "\n"
		s += ("Function:   " + str(tl[4])).rpad(pad, " ") + "\n"
		s += ("").rpad(pad, " ") + "\n"
		var actualdump = (tgui.Trace[tgui.TActive].HexDump[tgui.Trace[tgui.TActive].HexDumpTraceEntryIndex[i]])
		actualdump = actualdump.split("\n")
		actualdump = actualdump.slice(2)
		actualdump = "\n".join(actualdump)
		s += actualdump
		HDLabelsText.append(s)
		if HexDumpMaxLines < s.count("\n"):
			HexDumpMaxLines = s.count("\n")

	index = 0
	indexwanted = index
	HexdumpScrollBar.max_value = NumHexdumps - 1
	HexdumpScrollBar.page = 1

	PopulateScreen()
	print("Loaded hexdump for trace " + str(tgui.TActive))

func init(node):
	tgui = node.TraceGuiSceneRef
	hexdump = node.HexdumpSceneRef
	Inited = true
	StatusNode2d.Init(self)
	print("Hexdump support init done")

func Activate():
	Active = true
	PopulateScreen()

func _input(ev):
	if Inited and Active:
		if ev is InputEventKey:
			if ev.pressed:
				if ev.keycode == KEY_ESCAPE:
					tgui.visible = true
					Active = false
					tgui.Activate()
					return
				if ev.keycode == KEY_C and Input.is_physical_key_pressed(KEY_CTRL):
					for i in range(SLIDER_VISIBLE_HEXDUMPS):
						if HDLabels[i].get_selected_text() != "":
							DisplayServer.clipboard_set(HDLabels[i].get_selected_text())
					return
				if ev.keycode == KEY_UP:
					scroll_down()
					return
				if ev.keycode == KEY_DOWN:
					scroll_up()
					return
				if ev.keycode == KEY_PAGEUP:
					scroll_page_down()
					return
				if ev.keycode == KEY_PAGEDOWN:
					scroll_page_up()
					return
				if ev.keycode == KEY_LEFT:
					indexwanted -= 1
					if indexwanted < 0:
						indexwanted = 0
					HexdumpScrollBar.set_value_no_signal(indexwanted)
					return
				if ev.keycode == KEY_RIGHT:
					indexwanted += 1
					if indexwanted >= NumHexdumps - 2:
						indexwanted = NumHexdumps - 2
					if indexwanted < 0:
						indexwanted = 0
					HexdumpScrollBar.set_value_no_signal(indexwanted)
					return

var _process_first_time = true
func _process(delta):
	if Inited and Active:
		# Some brute pushback of side effects not handled
		for l in HDLabels:
			l.release_focus()

		if _process_first_time:
			queue_redraw()
			_process_first_time = false
		if index != indexwanted:
			if indexwanted > index:
				# scrolling right
				if xscrolloffset <= 0:
					xscrolloffset = HexdumpWidthPixels
				xscrolloffset -= FontWidth * 8
				if xscrolloffset <= 0:
					index += 1
					PopulateScreen()
					xscrolloffset = 0
					self.position.x = xscrolloffset
				else:
					self.position.x = 0 - (HexdumpWidthPixels - xscrolloffset)
			else:
				# scrolling left
				if xscrolloffset <= 0:
					xscrolloffset = HexdumpWidthPixels
				xscrolloffset -= FontWidth * 8
				if xscrolloffset <= 0:
					index -= 1
					PopulateScreen()
					xscrolloffset = 0
					self.position.x = -xscrolloffset
				else:
					self.position.x = 0 + (HexdumpWidthPixels - xscrolloffset)

func _processflash(delta):
		if Inited and Active:
#			OS.delay_msec(100)
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
