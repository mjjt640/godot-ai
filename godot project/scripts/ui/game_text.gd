class_name GameText
extends RefCounted

const BOSS_NAME := "骸弓督军"


static func hud_level(level: int) -> String:
	return "等级 %d" % level


static func hud_xp(current_xp: int, required_xp: int) -> String:
	return "经验 %d / %d" % [current_xp, required_xp]


static func hud_health(current_health: float, max_health: float) -> String:
	return "生命 %.0f / %.0f" % [current_health, max_health]


static func hud_character(character_data: Resource) -> String:
	var display_name := "-"
	if character_data != null and not String(character_data.get("display_name")).is_empty():
		display_name = String(character_data.get("display_name"))
	return "角色：%s" % display_name


static func hud_fire_mode(module: ModuleData) -> String:
	return _hud_module("发射", module)


static func hud_payload(module: ModuleData) -> String:
	return _hud_module("枪锋", module)


static func hud_run_time(elapsed_seconds: float) -> String:
	return "时间 %s" % format_time(elapsed_seconds)


static func hud_run_objective(_objective: Resource) -> String:
	return "目标：撑到%s出现并击破它" % BOSS_NAME


static func hud_next_event(elapsed_seconds: float, objective: Resource) -> String:
	var next_event: Resource = _next_objective_event(elapsed_seconds, objective)
	if next_event != null:
		var remaining: float = max(float(next_event.get("trigger_time")) - elapsed_seconds, 0.0)
		return "%s：%s后" % [_objective_event_name(next_event), format_time(remaining)]

	var boss_event: Resource = _last_boss_event(objective)
	if boss_event != null and elapsed_seconds >= float(boss_event.get("trigger_time")):
		return "%s已出现" % BOSS_NAME
	return "目标事件已清空"


static func format_time(seconds: float) -> String:
	var whole_seconds: int = max(int(floor(seconds)), 0)
	return "%02d:%02d" % [whole_seconds / 60, whole_seconds % 60]


static func game_over() -> String:
	return "游戏结束"


static func victory() -> String:
	return "%s已击破" % BOSS_NAME


static func main_menu_title() -> String:
	return "核心突围"


static func main_menu_subtitle() -> String:
	return "模块构筑幸存者"


static func main_menu_tagline() -> String:
	return "进入赛博测试区，移动、追逐、击退、掉落、升级。"


static func main_menu_start() -> String:
	return "开始行动"


static func main_menu_quit() -> String:
	return "退出游戏"


static func main_menu_loadout_title() -> String:
	return "初始配置"


static func main_menu_mission_title() -> String:
	return "行动目标"


static func main_menu_mission_body() -> String:
	return "撑到%s出现，并在敌潮中击破它。" % BOSS_NAME


static func main_menu_controls_title() -> String:
	return "操作"


static func main_menu_controls_body() -> String:
	return "WASD 移动，武器自动锁定附近敌人。"


static func main_menu_character(character_data: Resource) -> String:
	return "角色：%s" % _resource_display_name(character_data)


static func main_menu_weapon(weapon_data: Resource) -> String:
	return "武器：%s" % _resource_display_name(weapon_data)


static func main_menu_module_pair(fire_module: ModuleData, payload_module: ModuleData) -> String:
	return "模块：%s / %s" % [module_name(fire_module), module_name(payload_module)]


static func main_menu_description(data: Resource) -> String:
	if data == null:
		return "-"
	var description := String(data.get("description"))
	if description.is_empty():
		return "-"
	return description


static func level_up_title() -> String:
	return "选择升级"


static func upgrade_card(option: UpgradeOptionData, max_module_count: int = 0) -> String:
	if option == null:
		return "-"

	return "%s\n%s · %s\n%s" % [
		upgrade_card_source(option, max_module_count),
		upgrade_card_rarity(option),
		upgrade_card_title(option),
		upgrade_card_description(option),
	]


static func upgrade_card_source(option: UpgradeOptionData, max_module_count: int = 0) -> String:
	if option == null:
		return "-"

	match option.upgrade_type:
		UpgradeOptionData.UpgradeType.MODULE:
			if max_module_count > 0:
				return "新模块 · 安装模块 · 本局上限 %d" % max_module_count
			return "新模块 · 安装模块"
		UpgradeOptionData.UpgradeType.STAT:
			return "模块强化 · 只强化当前模块"
		UpgradeOptionData.UpgradeType.GENERAL:
			return "通用技能 · 非模块强化"
	return "-"


static func upgrade_card_rarity(option: UpgradeOptionData) -> String:
	if option == null:
		return "-"
	return upgrade_rarity(option.rarity)


static func upgrade_card_title(option: UpgradeOptionData) -> String:
	if option == null:
		return "-"

	var title := option.display_name
	if title.is_empty() and option.module != null:
		title = option.module.display_name
	if title.is_empty():
		return "-"
	return title


static func upgrade_card_description(option: UpgradeOptionData) -> String:
	if option == null:
		return "-"

	match option.upgrade_type:
		UpgradeOptionData.UpgradeType.MODULE:
			if not option.description.is_empty():
				return option.description
			if option.module != null and not option.module.description.is_empty():
				return option.module.description
		UpgradeOptionData.UpgradeType.STAT:
			var stat_summary := _stat_modifier_summary(option.stat_modifiers)
			if not stat_summary.is_empty():
				return stat_summary
		UpgradeOptionData.UpgradeType.GENERAL:
			var general_summary := _general_modifier_summary(option.general_modifiers)
			if not general_summary.is_empty():
				return general_summary
	if not option.description.is_empty():
		return option.description
	return "-"


static func pickup_amount(amount: int) -> String:
	return "+%d" % amount


static func module_name(module: ModuleData) -> String:
	if module == null or module.display_name.is_empty():
		return "-"
	return module.display_name


static func upgrade_rarity(rarity: int) -> String:
	match rarity:
		UpgradeOptionData.Rarity.COMMON:
			return "普通"
		UpgradeOptionData.Rarity.RARE:
			return "稀有"
		UpgradeOptionData.Rarity.EPIC:
			return "史诗"
		UpgradeOptionData.Rarity.LEGENDARY:
			return "传说"
	return "普通"


static func _stat_modifier_summary(modifiers: Dictionary) -> String:
	var lines: Array[String] = []
	for key in [
		&"pierce_count_add",
		&"explosion_radius_add",
		&"explosion_damage_mult_add",
		&"knockback_add",
		&"luck_add",
		&"luck_mult",
		&"attack_speed_add",
		&"attack_speed_mult",
		&"attack_range_add",
		&"attack_range_mult",
		&"crit_chance_add",
		&"crit_damage_mult_add",
		&"crit_damage_mult_mult",
	]:
		if modifiers.has(key):
			lines.append(_stat_modifier_line(key, modifiers[key]))
	return "\n".join(lines)


static func _general_modifier_summary(modifiers: Dictionary) -> String:
	var lines: Array[String] = []
	for key in [
		&"xp_magnet_radius_add",
		&"xp_magnet_radius_mult",
		&"heal_add",
		&"move_speed_add",
		&"move_speed_mult",
		&"xp_gain_mult",
	]:
		if modifiers.has(key):
			lines.append(_general_modifier_line(key, modifiers[key]))
	return "\n".join(lines)


static func _stat_modifier_line(key: StringName, value: Variant) -> String:
	match key:
		&"pierce_count_add":
			return "穿透 +%s" % _format_stat_number(value)
		&"explosion_radius_add":
			return "爆炸范围 +%s" % _format_stat_number(value)
		&"explosion_damage_mult_add":
			return "溅射伤害 +%s" % _format_stat_percent(value)
		&"knockback_add":
			return "击退 +%s" % _format_stat_number(value)
		&"luck_add":
			return "幸运 +%s" % _format_stat_percent(value)
		&"luck_mult":
			return "幸运 +%s" % _format_mult_bonus_percent(value)
		&"attack_speed_add":
			return "攻速 +%s" % _format_stat_percent(value)
		&"attack_speed_mult":
			return "攻速 +%s" % _format_mult_bonus_percent(value)
		&"attack_range_add":
			return "攻击范围 +%s" % _format_stat_number(value)
		&"attack_range_mult":
			return "攻击范围 +%s" % _format_mult_bonus_percent(value)
		&"crit_chance_add":
			return "暴击率 +%s" % _format_stat_percent(value)
		&"crit_damage_mult_add":
			return "暴击伤害 +%s" % _format_stat_percent(value)
		&"crit_damage_mult_mult":
			return "暴击伤害 +%s" % _format_mult_bonus_percent(value)
	return ""


static func _general_modifier_line(key: StringName, value: Variant) -> String:
	match key:
		&"xp_magnet_radius_add":
			return "吸附范围 +%s" % _format_stat_number(value)
		&"xp_magnet_radius_mult":
			return "吸附范围 +%s" % _format_mult_bonus_percent(value)
		&"heal_add":
			return "恢复生命 +%s" % _format_stat_number(value)
		&"move_speed_add":
			return "移动速度 +%s" % _format_stat_number(value)
		&"move_speed_mult":
			return "移动速度 +%s" % _format_mult_bonus_percent(value)
		&"xp_gain_mult":
			return "经验获取 +%s" % _format_mult_bonus_percent(value)
	return ""


static func _format_stat_number(value: Variant) -> String:
	var number := float(value)
	if is_equal_approx(number, roundf(number)):
		return "%d" % int(roundf(number))
	return "%.1f" % number


static func _format_stat_percent(value: Variant) -> String:
	return "%d%%" % int(roundf(float(value) * 100.0))


static func _format_mult_bonus_percent(value: Variant) -> String:
	return "%d%%" % int(roundf((float(value) - 1.0) * 100.0))


static func _hud_module(prefix: String, module: ModuleData) -> String:
	return "%s：%s" % [prefix, module_name(module)]


static func _resource_display_name(data: Resource) -> String:
	if data == null:
		return "-"
	var display_name := String(data.get("display_name"))
	if display_name.is_empty():
		return "-"
	return display_name


static func _next_objective_event(elapsed_seconds: float, objective: Resource) -> Resource:
	if objective == null:
		return null

	var events: Array = objective.get("events")
	for event in events:
		if event != null and elapsed_seconds < float(event.get("trigger_time")):
			return event
	return null


static func _last_boss_event(objective: Resource) -> Resource:
	if objective == null:
		return null

	var boss_event: Resource
	var events: Array = objective.get("events")
	for event in events:
		if event != null and int(event.get("event_type")) == 1:
			boss_event = event
	return boss_event


static func _objective_event_name(event: Resource) -> String:
	if event == null:
		return "目标"
	match int(event.get("event_type")):
		0:
			return "精英来袭"
		1:
			return "%s来袭" % BOSS_NAME
	return "目标事件"
