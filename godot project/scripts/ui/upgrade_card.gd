class_name UpgradeCard
extends Button

const GameText = preload("res://scripts/ui/game_text.gd")

var option: UpgradeOptionData
var max_module_count: int = 0

@onready var _source_label: Label = %SourceLabel
@onready var _rarity_label: Label = %RarityLabel
@onready var _title_label: Label = %TitleLabel
@onready var _description_label: Label = %DescriptionLabel


func _ready() -> void:
	_render()


func set_option(upgrade_option: UpgradeOptionData, module_limit: int = 0) -> void:
	option = upgrade_option
	max_module_count = module_limit
	if is_node_ready():
		_render()


func _render() -> void:
	text = ""
	tooltip_text = GameText.upgrade_card(option, max_module_count)
	_source_label.text = GameText.upgrade_card_source(option, max_module_count)
	_rarity_label.text = GameText.upgrade_card_rarity(option)
	_title_label.text = GameText.upgrade_card_title(option)
	_description_label.text = GameText.upgrade_card_description(option)
