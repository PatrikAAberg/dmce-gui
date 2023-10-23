extends Node2D

var DataNode2D
var MainWindowSize
var MainVBoxContainer

func _ready():
	DataNode2D = get_node("MainVBoxContainer/DataPanelContainer/DataNode2D")
	MainVBoxContainer = get_node("MainVBoxContainer")

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
