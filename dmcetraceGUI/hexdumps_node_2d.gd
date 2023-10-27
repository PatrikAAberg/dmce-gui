extends Node2D

var DataNode2D
var MainWindowSize
var MainVBoxContainer
var DiffPrevButton
var DiffAllButton

func _diff_prev_button_pressed():
	DataNode2D.ShowDiffPrev = not DataNode2D.ShowDiffPrev
	DataNode2D.queue_redraw()
	DiffPrevButton.release_focus()

func _diff_all_button_pressed():
	DataNode2D.ShowDiffAll = not DataNode2D.ShowDiffAll
	DataNode2D.queue_redraw()
	DiffAllButton.release_focus()

func _ready():
	DataNode2D = get_node("MainVBoxContainer/DataPanelContainer/DataNode2D")
	MainVBoxContainer = get_node("MainVBoxContainer")
	DiffPrevButton = get_node("MainVBoxContainer/ControlButtonsHBoxContainer/ButtonsPanelContainer/VBoxContainer/DiffPrevCheckButton")
	DiffAllButton = get_node("MainVBoxContainer/ControlButtonsHBoxContainer/ButtonsPanelContainer/VBoxContainer/DiffAllCheckButton")

	DiffPrevButton.pressed.connect(self._diff_prev_button_pressed)
	DiffAllButton.pressed.connect(self._diff_all_button_pressed)

func init(node):
	DataNode2D.init(node)

func Load():
	DataNode2D.Load()

func Activate():
	DataNode2D.Activate()

func _process(delta):
	MainWindowSize = get_tree().root.size
	if MainWindowSize.x != MainVBoxContainer.size.x or MainWindowSize.y != MainVBoxContainer.size.y:
		MainVBoxContainer.size.x = MainWindowSize.x
		MainVBoxContainer.size.y = MainWindowSize.y

