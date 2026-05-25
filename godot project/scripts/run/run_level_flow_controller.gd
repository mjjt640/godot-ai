class_name RunLevelFlowController
extends RefCounted


func initialize(level_up_panel: LevelUpPanelController) -> void:
	if level_up_panel != null:
		level_up_panel.hide_options()


func handle_level_up_requested(tree: SceneTree, level_up_panel: LevelUpPanelController, upgrade_manager: UpgradeManager) -> void:
	if level_up_panel == null or upgrade_manager == null:
		return

	tree.paused = true
	level_up_panel.show_options(upgrade_manager.request_options(), upgrade_manager.get_module_limit())


func handle_upgrade_selected(
	tree: SceneTree,
	level_up_panel: LevelUpPanelController,
	upgrade_manager: UpgradeManager,
	xp_manager: XPManager,
	option: UpgradeOptionData
) -> void:
	if upgrade_manager != null:
		upgrade_manager.apply_upgrade(option)
	if xp_manager != null:
		xp_manager.confirm_level_up()
	if level_up_panel != null:
		level_up_panel.hide_options()
	tree.paused = false


func prepare_run_finish(level_up_panel: LevelUpPanelController) -> void:
	if level_up_panel != null:
		level_up_panel.hide_options()
