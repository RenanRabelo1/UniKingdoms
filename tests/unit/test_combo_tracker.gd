extends GutTest

const WINDOW := 0.8

var tracker: ComboTracker


func before_each():
	tracker = ComboTracker.new(
		[load("res://data/combos/combo_bbp.tres"), load("res://data/combos/combo_pp.tres")],
		WINDOW)


func test_basic_basic_heavy_triggers_combo():
	assert_null(tracker.register(&"basic", 0.0))
	assert_null(tracker.register(&"basic", 0.3))
	var combo := tracker.register(&"heavy", 0.6)
	assert_not_null(combo)
	assert_eq(combo.sequence, [&"basic", &"basic", &"heavy"] as Array[StringName])
	assert_gt(combo.damage_multiplier, 1.0)


func test_heavy_heavy_triggers_combo():
	assert_null(tracker.register(&"heavy", 0.0))
	var combo := tracker.register(&"heavy", 0.5)
	assert_not_null(combo)
	assert_eq(combo.sequence, [&"heavy", &"heavy"] as Array[StringName])


func test_wrong_sequence_does_not_trigger():
	assert_null(tracker.register(&"basic", 0.0))
	assert_null(tracker.register(&"heavy", 0.3))
	assert_null(tracker.register(&"basic", 0.6))


func test_sequence_resets_after_window():
	tracker.register(&"basic", 0.0)
	tracker.register(&"basic", 0.3)
	assert_null(tracker.register(&"heavy", 0.3 + WINDOW + 0.01))


func test_sequence_clears_after_combo():
	tracker.register(&"heavy", 0.0)
	assert_not_null(tracker.register(&"heavy", 0.3))
	assert_null(tracker.register(&"heavy", 0.6), "o golpe seguinte começa uma sequência nova")
