extends SceneTree
## Smoke unit test runner for starter projects scaffolded via `gu init`.

var _failures: Array[String] = []
var _passed: int = 0
var _ran: bool = false


func _process(_delta: float) -> bool:
	if _ran:
		return true
	_ran = true
	_run_all()
	if _failures.is_empty():
		print("[PASS] Starter skeleton tests passed (%d assertions)." % _passed)
		quit(0)
	else:
		for f in _failures:
			push_error("[FAIL] " + f)
		quit(1)
	return true


func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
	else:
		_failures.append(msg)


func _run_all() -> void:
	for name in ["SettingsStore", "InputRouter", "AudioManager", "SaveService", "UIRouter", "GameFlow", "GameClock", "WorldTime", "EventBus", "PoolService", "DevConsole", "PlatformService"]:
		_assert(get_root().get_node_or_null(name) != null, "Autoload %s present" % name)

	var world_time := get_root().get_node_or_null("WorldTime")
	if world_time != null:
		_assert(str(world_time.call("format_clock", 0.0)) == "06:00", "WorldTime starts at 06:00")
		_assert(int(world_time.call("day_for", 0.0)) == 1, "WorldTime starts on day 1")
		_assert(str(world_time.call("format_clock", 1800.0)) == "06:00", "WorldTime rolls a 30-minute day")
		_assert(int(world_time.call("day_for", 1800.0)) == 2, "WorldTime day rolls after 30 real minutes")
		_assert(str(world_time.call("format_day", 3)) == "DAY 003", "WorldTime formats day labels")
		_assert(StringName(world_time.call("phase_for_hour", 4)) == &"night", "WorldTime phase: 04:00 night")
		_assert(StringName(world_time.call("phase_for_hour", 5)) == &"dawn", "WorldTime phase: 05:00 dawn")
		_assert(StringName(world_time.call("phase_for_hour", 7)) == &"day", "WorldTime phase: 07:00 day")
		_assert(StringName(world_time.call("phase_for_hour", 17)) == &"dusk", "WorldTime phase: 17:00 dusk")
		_assert(StringName(world_time.call("phase_for_hour", 19)) == &"night", "WorldTime phase: 19:00 night")
		var clock := get_root().get_node_or_null("GameClock")
		if clock != null:
			var previous := float(clock.get("world_seconds"))
			clock.set("world_seconds", 0.0)
			world_time.call("refresh_now")
			_assert(is_equal_approx(float(world_time.call("sleep_until", 19)), 975.0), "WorldTime sleeps from 06:00 to 19:00")
			_assert(str(world_time.call("get_clock_text")) == "19:00", "WorldTime sleep advances the clock")
			clock.set("world_seconds", previous)
			world_time.call("refresh_now")

	var console := get_root().get_node_or_null("DevConsole")
	if console != null:
		_assert(str(console.call("execute", "echo hello")) == "hello", "DevConsole executes built-in echo")

	var bus := get_root().get_node_or_null("EventBus")
	if bus != null:
		var hits := [0]
		var cb := func(_p: Dictionary) -> void: hits[0] += 1
		bus.call("subscribe", &"starter_ping", cb)
		bus.call("emit_event", &"starter_ping", {})
		bus.call("unsubscribe", &"starter_ping", cb)
		_assert(hits[0] == 1, "EventBus delivers and unsubscribes events")

	var am := get_root().get_node_or_null("AudioManager")
	if am != null:
		var stream := AudioStreamWAV.new()
		var p3d := am.call("play_sfx_at", Vector3(2.0, 1.0, -3.0), stream, -3.0) as AudioStreamPlayer3D
		_assert(p3d != null and p3d.stream == stream, "AudioManager.play_sfx_at allocates 3D player")

	var ui := get_root().get_node_or_null("UIRouter")
	var ir := get_root().get_node_or_null("InputRouter")
	if ui != null and ir != null:
		ui.call("show_toast", "Starter smoke toast", 0.5, &"info")
		_assert(int(ui.call("get_active_toast_count")) >= 1, "UIRouter.show_toast activates banner")
		ui.call("clear_toasts")

		var dlg := ui.call("show_confirm", "Confirm", "Proceed?", Callable()) as Control
		_assert(dlg != null, "UIRouter.show_confirm creates dialog")
		_assert(not bool(ir.call("allow_debug")), "Modal confirm pushes MODAL input context")
		dlg.call("cancel")
		_assert(bool(ir.call("allow_debug")), "Cancelling modal restores previous input context")

		ui.call("fade_out", 0.0)
		_assert(is_equal_approx(float(ui.call("get_transition_alpha")), 1.0), "UIRouter.fade_out reaches opaque")
		ui.call("fade_in", 0.0)
		_assert(is_equal_approx(float(ui.call("get_transition_alpha")), 0.0), "UIRouter.fade_in returns transparent")

	var ctrl := CharacterActionController.new()
	_assert(ctrl.try_start(&"gather", {"swim_amt": 0.0}), "CharacterActionController works in starter without CharacterLocomotion")

	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	_assert(packed_scene != null, "Starter main scene loads")
	if packed_scene != null:
		var scene := packed_scene.instantiate()
		var player := scene.get_node_or_null("Player")
		_assert(player is GuPlayer, "Starter main scene contains a GuPlayer")
		_assert(scene.get_node_or_null("CameraPivot") != null, "Starter main scene contains a camera rig")
		_assert(scene.get_node_or_null("Landscape") is SeedLandscape, "Starter main scene contains the procedural landscape")
		_assert(scene.get_node_or_null("WorldArt") != null, "Starter main scene contains the set dressing layer")
		_assert(scene.get_node_or_null("SeedEnvironment") != null, "Starter main scene contains the dawn environment")
		if player is GuPlayer:
			_assert((player as GuPlayer).animated_model_path != "", "GuPlayer has an animated art model configured")
		_assert(ResourceLoader.exists("res://assets/art/title_key_art.svg"), "Title key art asset exists")
		var boot_probe := scene.get_node_or_null("Player") as GuPlayer
		if boot_probe != null:
			scene.remove_child(boot_probe)
			get_root().add_child(boot_probe)
			_assert(boot_probe.get_locomotion() != null, "GuPlayer boots its locomotion state")
			_assert(InputMap.has_action("move_forward"), "GuPlayer registers movement actions")
			get_root().remove_child(boot_probe)
			boot_probe.free()
		scene.free()

	var content_quests := GameContent.quests()
	_assert(content_quests.size() == 1 and content_quests[0].id == &"meet_guide", "Starter content defines the sample quest")
	var guide_def := GameContent.dialogue(&"guide_intro")
	_assert(guide_def != null and guide_def.is_valid(), "Starter guide dialogue loads")
	for pod_id in [&"pod_07", &"pod_07_after_power", &"pod_07_chip_log"]:
		var pod_def := GameContent.dialogue(pod_id)
		_assert(pod_def != null and pod_def.is_valid(), "Pod 07 dialogue loads: %s" % pod_id)
	var chip_found := false
	for item_def in GameContent.items():
		if item_def.id == &"data_chip_07":
			chip_found = true
	_assert(chip_found, "Pod 07 data chip item loads")
	var berry_item_found := false
	for item_def in GameContent.items():
		if item_def.id == &"wild_berry":
			berry_item_found = true
	_assert(berry_item_found, "Wild berry item loads")
	_assert(ItemIcons.icon_for(&"wood").get_width() == 256, "Authored wood icon loads")
	_assert(ItemIcons.icon_for(&"stone_axe", [&"tool"]).get_width() == 64, "Fallback tool icon generates")
	var catalog := TranslationCatalog.new()
	_assert(catalog.load_dir("res://data") == OK, "Starter localization loads")
	_assert(catalog.message("zh", "Meet the Guide") == "与向导会面", "Starter content has a zh translation")
	catalog.unload()

	var full_scene := packed_scene.instantiate()
	get_root().add_child(full_scene)
	_assert(full_scene.get_node_or_null("Guide") != null, "Starter scene spawns the guide NPC")
	var ship_entry := full_scene.get_node_or_null("ShipEntry") as ShipTransition
	_assert(ship_entry != null and ship_entry.target_scene.contains("ship_preview"), "Landing site has a ship blockout entry")
	var seed_hud := full_scene.get_node_or_null("SeedHud") as SeedHud
	_assert(seed_hud != null, "Starter scene spawns the Seed HUD")
	if seed_hud != null:
		_assert(seed_hud.get_clock_text().length() == 5, "Seed HUD shows HH:MM")
		_assert(seed_hud.get_day_text().begins_with("DAY "), "Seed HUD shows the day label")
		_assert(seed_hud.get_vital_text(&"hunger") != "", "Seed HUD binds hunger")
		_assert(seed_hud.get_hotbar() != null and seed_hud.get_hotbar().get_slot_texts().size() == Hotbar.SLOT_COUNT, "Seed HUD has six hotbar slots")
		_assert(seed_hud.get_resources() != null and seed_hud.get_resources().get_chip_text(&"wood") != "", "Seed HUD has pinned resource chips")
		_assert(seed_hud.get_resources().get_chip_icon(&"wood") != null, "Pinned resource chips render item icons")
	var flow := get_root().get_node_or_null("GameFlow")
	var ui_router := get_root().get_node_or_null("UIRouter")
	var game_clock := get_root().get_node_or_null("GameClock")
	if flow != null and ui_router != null and game_clock != null:
		flow.set("state", 3)
		game_clock.call("set_gameplay_running", true)
		var wrist_player := full_scene.get_node_or_null("Player") as GuPlayer
		if wrist_player != null:
			wrist_player.get_inventory().add_item(&"wood", 1)
		var wrist := ui_router.call("push_screen", &"wrist", {"tab": &"pack"}, 1) as Control
		_assert(wrist != null, "Wrist screen opens")
		_assert(paused, "Opening the wrist pauses gameplay")
		if wrist != null:
			_assert(StringName(wrist.call("get_active_tab")) == &"pack", "Wrist opens on PACK")
			_assert(str(wrist.call("get_title_text")).contains("PACK"), "Wrist title follows the active tab")
			_assert(int(wrist.call("get_archive_count")) >= 6, "Wrist archive lists factory tech fragments")
			_assert(int(wrist.call("get_visible_icon_count")) > 0, "Wrist PACK renders item icons")
			ui_router.call("pop_screen")
		_assert(not paused, "Closing the wrist unpauses gameplay")
		flow.set("state", 1)
		game_clock.call("set_gameplay_running", false)
	var pod := full_scene.get_node_or_null("Pod07") as DialogueInteractable
	_assert(pod != null, "Starter scene spawns Pod 07")
	if pod != null:
		_assert(pod.interact(full_scene.get_node("Player")), "Pod 07 interaction opens dialogue")
	var player := full_scene.get_node("Player") as GuPlayer
	var bush := full_scene.get_node_or_null("BerryBushA") as Interactable
	_assert(bush != null, "Starter scene spawns a berry bush")
	if bush != null and player != null:
		_assert(bush.interact(player), "Berry bush interaction works")
	var inventory: InventoryContainer = null
	if player != null:
		inventory = player.get_inventory()
	_assert(inventory != null and inventory.count_item(&"wild_berry") >= 3, "Berry harvest adds wild berries")
	var hunger := full_scene.get_node_or_null("HungerController") as HungerController
	_assert(hunger != null, "HungerController is present")
	if hunger != null and player != null:
		var pstats := player.get_stats()
		_assert(pstats.has_stat(&"hunger") and pstats.get_value(&"hunger") <= 65.0 and pstats.get_value(&"hunger") > 60.0, "Hunger starts near 65")
		pstats.set_value(&"hunger", 50.0)
		var before_eat := pstats.get_value(&"hunger")
		_assert(hunger.eat_berry(), "Eating a wild berry works")
		_assert(pstats.get_value(&"hunger") > before_eat, "Eating restores hunger")

	var hotbar_control := full_scene.get_node_or_null("HotbarController") as HotbarController
	_assert(hotbar_control != null, "HotbarController is present")
	_assert(InputMap.has_action("hotbar_1") and InputMap.has_action("use_selected"), "Hotbar/use actions are registered")
	_assert(InputMap.action_get_events("action_gather").is_empty(), "Legacy gather key is released for the hotbar")
	if hotbar_control != null and inventory != null and seed_hud != null:
		full_scene.call("_give_starting_kit")
		_assert(inventory.count_item(&"emergency_knife") >= 1, "Starting kit gives an emergency knife")
		_assert(seed_hud.get_hotbar().get_slot_icon(0) != null, "Hotbar renders item icons")
		inventory.add_item(&"stone_axe", 1)
		var ids := seed_hud.get_hotbar().get_slot_item_ids()
		var knife_index := ids.find(&"emergency_knife")
		hotbar_control.select_slot(knife_index)
		_assert(hotbar_control.get_selected_item_id() == &"emergency_knife", "Hotbar selects the knife")
		_assert(hotbar_control.get_action_for_item(&"emergency_knife") == &"gather", "Knife maps to gather")
		_assert(hotbar_control.get_selected_hint().contains("Knife") and hotbar_control.get_selected_hint().contains("Gather"), "Selected hint shows the tool verb")
		_assert(seed_hud.get_selected_text().contains("Knife"), "HUD selected hint follows the hotbar")
		_assert(hotbar_control.get_action_for_item(&"stone_axe") == &"chop", "Axe maps to chop")
		var berry_index := seed_hud.get_hotbar().get_slot_item_ids().find(&"wild_berry")
		hotbar_control.select_slot(berry_index)
		player.get_stats().set_value(&"hunger", 50.0)
		var before_use := player.get_stats().get_value(&"hunger")
		_assert(hotbar_control.use_selected(), "Using a selected berry works")
		_assert(player.get_stats().get_value(&"hunger") > before_use, "Selected food restores hunger")
		var bush_b := full_scene.get_node_or_null("BerryBushB") as Interactable
		if bush_b != null and player.get_interactor() != null:
			player.get_interactor().set("_focused", bush_b)
			hotbar_control.select_slot(seed_hud.get_hotbar().get_slot_item_ids().find(&"emergency_knife"))
			var berries_before := inventory.count_item(&"wild_berry")
			_assert(hotbar_control.use_selected(), "Knife use harvests the focused bush")
			_assert(inventory.count_item(&"wild_berry") > berries_before, "Focused harvest adds berries")
	var gen_pod := full_scene.get_node_or_null("GeneticistPod") as ColonistPod
	_assert(gen_pod != null, "Starter scene spawns the geneticist pod")
	if gen_pod != null:
		_assert(not gen_pod.can_wake(), "Geneticist wake is locked initially")
	var scene_flags := full_scene.get("_flags") as FlagStore
	var shelter := full_scene.get_node_or_null("ShelterSite") as BuildSite
	var generator := full_scene.get_node_or_null("ThermalGeneratorSite") as BuildSite
	_assert(shelter != null and generator != null, "Starter scene spawns build sites")
	if shelter != null:
		_assert(not shelter.can_build(), "Shelter is locked without materials")
		inventory.add_item(&"wood", 5)
		inventory.add_item(&"fiber", 3)
		_assert(shelter.can_build(), "Shelter can be built with materials")
		_assert(shelter.interact(player), "Shelter build interaction works")
		_assert(scene_flags.get_bool(&"shelter_built"), "Shelter sets its flag")
	if generator != null:
		inventory.add_item(&"wood", 8)
		inventory.add_item(&"fiber", 4)
		_assert(generator.can_build(), "Generator can be built with materials")
		_assert(generator.interact(player), "Generator build interaction works")
		_assert(scene_flags.get_bool(&"thermal_generator_built") and float(scene_flags.get_flag(&"power_capacity", 0.0)) >= 20.0 and scene_flags.get_bool(&"medbay_online"), "Generator powers the ship")
	if gen_pod != null:
		while inventory.count_item(&"wild_berry") < 10:
			inventory.add_item(&"wild_berry", 1)
		_assert(gen_pod.can_wake(), "Geneticist wake unlocks after the build chain")
	var tracker := full_scene.get("_quests") as QuestTracker
	_assert(tracker != null and tracker.is_active(&"meet_guide"), "Starter starts the sample quest")
	var guide := full_scene.get_node_or_null("Guide") as DialogueInteractable
	_assert(guide != null and guide.interact(full_scene.get_node("Player")), "Guide interaction opens dialogue")
	_assert(tracker != null and tracker.is_completed(&"meet_guide"), "Guide dialogue completes the sample quest")
	get_root().remove_child(full_scene)
	full_scene.free()

	var stats := StatSet.new()
	stats.define_stat(&"hp", 100.0)
	_assert(stats.spend(&"hp", 25.0) and is_equal_approx(stats.get_value(&"hp"), 75.0), "StatSet works in starter")

	var inv := InventoryContainer.new()
	_assert(inv.add_item(&"coin", 10) == 0 and inv.count_item(&"coin") == 10, "InventoryContainer works in starter")

	var flags := FlagStore.new()
	var qt := QuestTracker.new()
	qt.bind(bus, flags, inv)
	qt.register_quest(QuestDef.from_dict({
		"id": "q_start",
		"objectives": [{"id": "ping", "type": "event", "event": "starter_ping", "target": 1}],
		"rewards": [{"type": "flag", "id": "q_done", "value": true}],
	}))
	qt.start_quest(&"q_start")
	if bus != null:
		bus.call("emit_event", &"starter_ping", {})
	_assert(qt.is_completed(&"q_start") and flags.get_bool(&"q_done"), "QuestTracker + FlagStore work in starter")
	qt.unbind()

	var talk_flags := FlagStore.new()
	var talk := DialogueRunner.new()
	talk.bind(talk_flags, null, null, null)
	var talk_view := talk.start(DialogueDef.from_dict({
		"id": "hi",
		"start": "a",
		"nodes": [{
			"id": "a",
			"text": "Hello",
			"effects": [{"type": "set_flag", "id": "spoke", "value": true}],
		}],
	}))
	_assert(bool(talk_view.get("ok", false)) and talk_flags.get_bool(&"spoke"), "DialogueRunner sets a flag")
	if ir != null:
		var was_gameplay := bool(ir.call("is_gameplay_active"))
		var box := DialogueBox.new()
		get_root().add_child(box)
		box.bind(talk_flags, null, null, null)
		_assert(box.start(DialogueDef.from_dict({
			"id": "box",
			"start": "a",
			"nodes": [{"id": "a", "speaker": "Guide", "text": "Ready"}],
		})), "DialogueBox opens")
		_assert(box.is_open() and not bool(ir.call("is_gameplay_active")), "DialogueBox pushes UI input context")
		var close_btn := box.find_child("CloseButton", true, false) as Button
		_assert(close_btn != null, "DialogueBox shows Close on a terminal line")
		if close_btn != null:
			close_btn.pressed.emit()
		_assert(not box.is_open() and bool(ir.call("is_gameplay_active")) == was_gameplay, "Closing DialogueBox restores gameplay input")
		box.free()

	var hc := HealthComponent.new()
	hc.max_hp = 30.0
	_assert(is_equal_approx(hc.apply_damage(12.0), 12.0) and is_equal_approx(hc.get_hp(), 18.0), "HealthComponent works in starter")
	var health_bar := StatBar.new()
	health_bar.bind_health(hc, "Health")
	_assert(health_bar.get_value_text() == "18 / 30", "StatBar follows HealthComponent in starter")
	health_bar.free()
	hc.free()

	var stats_bar := StatBar.new()
	stats_bar.bind_stat(stats, &"hp", "HP")
	_assert(stats_bar.get_value_text() == "75 / 100", "StatBar follows StatSet in starter")
	stats_bar.free()

	if ir != null:
		var stack_before := int(ir.call("get_stack_size"))
		var panel := InventoryPanel.new()
		get_root().add_child(panel)
		panel.bind_inventory(inv)
		var slot_rows := panel.get_row_texts()
		_assert(slot_rows.size() == 1 and slot_rows[0] == "Coin x10", "InventoryPanel renders slot rows in starter")
		panel.set_open(true)
		_assert(int(ir.call("get_active_context")) == 1, "InventoryPanel pushes UI input context")
		panel.set_open(false)
		_assert(int(ir.call("get_stack_size")) == stack_before, "InventoryPanel pops UI input context")
		get_root().remove_child(panel)
		panel.free()

	var quest_hud := QuestHud.new()
	get_root().add_child(quest_hud)
	var quest_tracker := QuestTracker.new()
	quest_hud.bind_tracker(quest_tracker)
	quest_tracker.register_quest(QuestDef.from_dict({
		"id": "q_hud",
		"title": "Starter Quest",
		"objectives": [{"id": "step", "type": "event", "event": "starter_ping", "description": "Ping", "target": 1}],
	}))
	quest_tracker.start_quest(&"q_hud")
	_assert("Ping 0/1" in "\n".join(quest_hud.get_row_texts()), "QuestHud shows objective progress")
	quest_tracker.handle_event(&"starter_ping", {})
	_assert("COMPLETE" in "\n".join(quest_hud.get_row_texts()), "QuestHud shows completion text")
	quest_hud.acknowledge_completion(&"q_hud")
	_assert(not ("COMPLETE" in "\n".join(quest_hud.get_row_texts())), "QuestHud completion can be acknowledged")
	quest_tracker.unbind()
	get_root().remove_child(quest_hud)
	quest_hud.free()

	var table_path := "user://starter_table.json"
	var tf := FileAccess.open(table_path, FileAccess.WRITE)
	tf.store_string('{"rows":[{"id":"potion","val":20}]}')
	tf.close()
	var rows := DataTableLoader.load_table(table_path)
	_assert(rows.size() == 1 and int(DataTableLoader.find_by_id(rows, "potion").get("val", 0)) == 20, "DataTableLoader works in starter")
	DirAccess.remove_absolute(table_path)

	var main_scene := load("res://scenes/main.tscn") as PackedScene
	_assert(main_scene != null, "Starter main.tscn loads")
	for ui_path in [
		"res://scenes/ui/title_screen.tscn",
		"res://scenes/ui/pause_menu.tscn",
		"res://scenes/ui/settings_panel.tscn",
		"res://addons/gu_core/ui/save_slots_panel.tscn",
	]:
		var packed := load(ui_path) as PackedScene
		_assert(packed is PackedScene, "Starter UI loads: %s" % ui_path)
		if packed != null:
			var ui_inst := packed.instantiate() as Control
			_assert(ui_inst != null and ui_inst.get_node_or_null("%Panel") != null, "Starter UI exposes %%Panel: %s" % ui_path)
			ui_inst.free()

	_test_factory()
	_test_logistics()


func _test_factory() -> void:
	var factory_item_ids := [
		"stone", "iron_ore", "copper_ore", "coal",
		"iron_plate", "copper", "mechanical_part", "electrical_part",
	]
	var item_ids: Dictionary = {}
	for def in GameContent.items():
		item_ids[String(def.id)] = true
	for item_id in factory_item_ids:
		_assert(item_ids.has(item_id), "Factory item loads: %s" % item_id)

	var recipes := FactoryContent.recipes()
	_assert(recipes.size() >= 4, "Factory recipes load")
	var techs := FactoryContent.techs()
	_assert(techs.size() >= 6, "Factory tech table has at least 6 nodes")
	var automation := FactoryContent.tech(&"basic_automation")
	_assert(not automation.is_empty() and int((automation.get("costs", {}) as Dictionary).get("mechanical_part", 0)) == 10, "Basic Automation costs 10 mechanical parts")

	var state := FactoryState.new()
	var grid := PowerGrid.new()
	var smelter := FactoryMachine.new()
	smelter.auto_tick = false
	smelter.allowed_station = &"smelter"
	smelter.power_draw = 5.0
	smelter.setup(FactoryContent.recipes(), state, grid)
	_assert(smelter.insert_item(&"iron_ore", 2) == 2 and smelter.insert_item(&"coal", 1) == 1, "Smelter accepts ore and coal")
	_assert(not smelter.can_start(), "Smelter cannot start without power")
	grid.set_supply(20.0)
	_assert(smelter.can_start(), "Smelter can start with power and inputs")
	smelter.tick(0.1)
	_assert(smelter.is_running(), "Smelter starts its recipe")
	smelter.tick(4.0)
	_assert(smelter.get_output_count(&"iron_plate") == 1, "Smelter produces an iron plate")
	_assert(smelter.take_output(&"iron_plate", 1) == 1, "Smelter output can be collected")

	var workbench := FactoryMachine.new()
	workbench.auto_tick = false
	workbench.allowed_station = &"workbench"
	workbench.power_draw = 3.0
	workbench.setup(FactoryContent.recipes(), state, grid)
	workbench.insert_item(&"iron_plate", 2)
	workbench.tick(0.1)
	workbench.tick(3.0)
	_assert(workbench.get_output_count(&"mechanical_part") == 1, "Workbench produces a mechanical part")

	var locked_recipe := FactoryContent.recipe(&"smelt_copper")
	_assert(not locked_recipe.is_empty() and str(locked_recipe.get("requires_tech", "")) == "copper_working", "Copper smelting is tech-gated")
	var research := ResearchBench.new()
	research.auto_tick = false
	research.setup_research(FactoryContent.techs(), state, grid)
	_assert(research.insert_item(&"mechanical_part", 10) == 10, "Research bench accepts 10 mechanical parts")
	research.tick(0.1)
	_assert(research.is_running(), "Research starts Basic Automation")
	research.tick(15.0)
	_assert(state.is_unlocked(&"basic_automation"), "Research unlocks Basic Automation")
	_assert(state.unlock(&"copper_working"), "Copper Working can be unlocked for the gating check")
	_assert(research.get_available_recipes().any(func(row: Dictionary) -> bool: return StringName(str(row.get("id", ""))) == &"electrical_engineering"), "Research lists Electrical Engineering after Copper Working")

	var generator := ThermalGenerator.new()
	generator.auto_tick = false
	var gen_grid := PowerGrid.new()
	generator.setup(gen_grid)
	_assert(generator.add_fuel(&"coal", 1) == 1, "Generator accepts coal")
	generator.tick(1.0)
	_assert(is_equal_approx(gen_grid.supply, 20.0), "Coal generator supplies 20 power")
	generator.tick(40.0)
	_assert(is_equal_approx(gen_grid.supply, 0.0), "Generator stops when fuel runs out")

	smelter.free()
	workbench.free()
	research.free()
	generator.free()

	var factory_world := load("res://scenes/factory/factory_lab.tscn") as PackedScene
	_assert(factory_world != null, "Factory lab scene loads")


	var wrist_scene := load("res://scenes/ui/wrist_computer.tscn") as PackedScene
	_assert(wrist_scene != null, "Wrist computer scene loads")
	if wrist_scene != null:
		var wrist_inst := wrist_scene.instantiate() as Control
		_assert(wrist_inst != null, "Wrist computer instantiates")
		if wrist_inst != null:
			get_root().add_child(wrist_inst)
			_assert(str(wrist_inst.call("get_title_text")).contains("PACK"), "Wrist computer starts on PACK")
			get_root().remove_child(wrist_inst)
			wrist_inst.free()

	var ship_interior_scene := load("res://scenes/ship/ship_interior.tscn") as PackedScene
	_assert(ship_interior_scene != null, "Ship interior scene loads")
	if ship_interior_scene != null:
		var ship := ship_interior_scene.instantiate()
		_assert(ship.get_node_or_null("CryoBay") != null, "Ship interior has a cryo bay")
		_assert(ship.get_node_or_null("MedBay") != null, "Ship interior has a med bay")
		_assert(ship.get_node_or_null("SpineCorridor") != null, "Ship interior has a spine corridor")
		var cryo := ship.get_node_or_null("CryoBay")
		if cryo != null:
			_assert(cryo.get_node_or_null("Pod07") != null, "Cryo bay contains Pod 07")
			_assert(cryo.get_node_or_null("Pod07Interact") is Interactable, "Pod 07 has an inspection point")
			var pod_count := 0
			for child in cryo.get_children():
				if str(child.name).begins_with("Pod"):
					pod_count += 1
			_assert(pod_count >= 24, "Cryo bay has at least 24 pod instances")
		var spine := ship.get_node_or_null("SpineCorridor")
		if spine != null:
			_assert(spine.get_node_or_null("SealedDoorBlock") is StaticBody3D, "Spine corridor seals the energy bay")
			_assert(spine.get_node_or_null("SealedDoorInteract") is Interactable, "Sealed door has an inspection point")
			var airlock := spine.get_node_or_null("AirlockInteract") as ShipTransition
			_assert(airlock != null and airlock.target_scene.contains("ship_exterior_preview"), "Airlock transitions to the exterior preview")
		ship.free()

	var ship_preview_scene := load("res://scenes/ship/ship_preview.tscn") as PackedScene
	_assert(ship_preview_scene != null, "Ship interior preview loads")
	if ship_preview_scene != null:
		var preview := ship_preview_scene.instantiate()
		_assert(preview.get_node_or_null("Player") is CharacterBody3D, "Ship preview has a walkable player")
		_assert(preview.get_node_or_null("CameraPivot/Camera3D") is Camera3D, "Ship preview has a third-person camera")
		preview.free()

	var ship_exterior_scene := load("res://scenes/ship/ship_exterior.tscn") as PackedScene
	_assert(ship_exterior_scene != null, "Ship exterior scene loads")
	if ship_exterior_scene != null:
		var exterior := ship_exterior_scene.instantiate()
		_assert(exterior.get_node_or_null("Hull") != null, "Ship exterior has the giant hull")
		_assert(exterior.get_node_or_null("BreachRamp") != null, "Ship exterior has a breach ramp")
		_assert(exterior.get_node_or_null("HullBody") is StaticBody3D, "Ship exterior has hull collision")
		_assert(exterior.get_node_or_null("RampBody") is StaticBody3D, "Ship exterior has ramp collision")
		var breach := exterior.get_node_or_null("InteriorEntryInteract") as ShipTransition
		_assert(breach != null and breach.target_scene.contains("ship_preview"), "Breach transitions to the interior preview")
		var hull_mesh := _first_mesh(exterior.get_node_or_null("Hull"))
		_assert(hull_mesh != null and hull_mesh.get_aabb().size.z > 1000.0, "Ship hull is over 1 km long")
		exterior.free()


func _first_mesh(node: Node) -> MeshInstance3D:
	if node == null:
		return null
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var found := _first_mesh(child)
		if found != null:
			return found
	return null


func _test_logistics() -> void:
	var road := RoadNetwork.new()
	road.add_road(Vector3.ZERO, Vector3(6.0, 0.0, 4.0))
	var cells := road.find_path_cells(Vector2i(0, 0), Vector2i(3, 2))
	_assert(cells.size() == 6, "Road BFS finds a 6-cell path")
	_assert(cells[0] == Vector2i(0, 0) and cells[cells.size() - 1] == Vector2i(3, 2), "Road path starts and ends at the requested cells")
	var turns := 0
	for i in range(1, cells.size() - 1):
		var a := cells[i] - cells[i - 1]
		var b := cells[i + 1] - cells[i]
		if a != b:
			turns += 1
	_assert(turns >= 1, "Road path contains at least one 90-degree turn")

	var state := FactoryState.new()
	var grid := PowerGrid.new()
	grid.set_supply(100.0)

	var producer := FactoryMachine.new()
	producer.auto_tick = false
	producer.allowed_station = &"smelter"
	producer.power_draw = 5.0
	producer.setup(FactoryContent.recipes(), state, grid)
	producer.insert_item(&"iron_ore", 2)
	producer.insert_item(&"coal", 1)
	producer.tick(0.1)
	producer.tick(4.0)
	_assert(producer.get_output_count(&"iron_plate") == 1, "Station producer made an iron plate")

	var station := LogisticsStation.new()
	station.auto_tick = false
	station.position = Vector3.ZERO
	station.setup(&"test_station", "Test Station", road, grid)
	station.bind_producer(producer)
	station.tick(1.0)
	_assert(station.get_output_count(&"iron_plate") == 1, "Station pulls the producer output")

	var consumer := FactoryMachine.new()
	consumer.auto_tick = false
	consumer.allowed_station = &"workbench"
	consumer.power_draw = 3.0
	consumer.setup(FactoryContent.recipes(), state, grid)
	station.bind_consumer(consumer)
	station.add_input(&"iron_plate", 1)
	station.tick(1.0)
	_assert(consumer.get_input_count(&"iron_plate") == 1, "Station pushes input into the consumer machine")

	var pickup := LogisticsStation.new()
	pickup.auto_tick = false
	pickup.position = Vector3.ZERO
	pickup.setup(&"pickup", "Pickup", road, grid)
	var dropoff := LogisticsStation.new()
	dropoff.auto_tick = false
	dropoff.position = Vector3(6.0, 0.0, 4.0)
	dropoff.setup(&"dropoff", "Dropoff", road, grid)
	pickup.add_output(&"iron_ore", 5)
	pickup.add_fuel(&"coal", 5)

	var truck := SteamTruck.new()
	truck.auto_tick = false
	truck.display_name = "Test Truck"
	_assert(truck.assign_route(pickup, dropoff, &"iron_ore", road), "Truck accepts a route")
	for i in range(400):
		truck.tick(0.1)
	_assert(dropoff.get_input_count(&"iron_ore") == 5, "Truck delivers all cargo to the dropoff")
	_assert(pickup.get_fuel_count(&"coal") < 5, "Truck consumes station fuel")

	var miner := Miner.new()
	miner.auto_tick = false
	miner.setup_miner(&"coal", "Coal Miner", 1.0, state, grid)
	miner.tick(0.1)
	miner.tick(1.0)
	_assert(miner.get_output_count(&"coal") == 1, "Miner produces coal")

	producer.free()
	consumer.free()
	station.free()
	pickup.free()
	dropoff.free()
	truck.free()
	miner.free()

	var packed := load("res://scenes/factory/factory_logistics_lab.tscn") as PackedScene
	_assert(packed != null, "F2 logistics lab scene loads")
	if packed != null:
		var lab := packed.instantiate()
		get_root().add_child(lab)
		var demo := lab.get_node_or_null("Main/FactoryDemo")
		_assert(demo != null and bool(demo.get("enable_logistics")), "F2 lab enables logistics")
		var site := demo.get_node_or_null("FactorySite") if demo != null else null
		_assert(site != null and site.get_node_or_null("IronMiner") != null, "F2 lab spawns the iron miner")
		var f2_state = demo.get("_state") if demo != null else null
		if site != null:
			for i in range(3000):
				for node in site.get_children():
					if node.has_method("tick"):
						node.tick(0.1)
		_assert(f2_state != null and f2_state.is_unlocked(&"copper_working"), "F2 auto line unlocks Copper Working")
		get_root().remove_child(lab)
		lab.free()
