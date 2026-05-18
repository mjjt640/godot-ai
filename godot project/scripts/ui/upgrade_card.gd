class_name UpgradeCard
extends Button

var option: UpgradeOptionData


func set_option(upgrade_option: UpgradeOptionData) -> void:
	option = upgrade_option
	text = "%s\n%s" % [option.display_name, option.description]
