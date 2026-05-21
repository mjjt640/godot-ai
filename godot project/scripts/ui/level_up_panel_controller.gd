class_name LevelUpPanelController
extends CanvasLayer

const GameText = preload("res://scripts/ui/game_text.gd")

signal upgrade_selected(option: UpgradeOptionData)

@export var upgrade_card_scene: PackedScene = preload("res://scenes/ui/upgrade_card.tscn")

@onready var _overlay: ColorRect = %Overlay
@onready var _panel: Control = %Panel
@onready var _title: Label = %Title
@onready var _options_list: VBoxContainer = %OptionsList


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_title.text = GameText.level_up_title()


func show_options(options: Array[UpgradeOptionData], max_module_count: int = 0) -> void:
	_clear_options()
	_overlay.visible = true
	_panel.visible = true

	for option in options:
		var card := upgrade_card_scene.instantiate() as UpgradeCard
		card.set_option(option, max_module_count)
		card.pressed.connect(func() -> void: upgrade_selected.emit(option))
		_options_list.add_child(card)


func hide_options() -> void:
	_overlay.visible = false
	_panel.visible = false
	_clear_options()


func _clear_options() -> void:
	for child in _options_list.get_children():
		child.queue_free()
