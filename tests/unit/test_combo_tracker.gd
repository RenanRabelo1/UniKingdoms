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


func test_unfinished_sequence_stays_bounded_and_still_closes_combo():
	for i in 100:
		tracker.register(&"basic", i * 0.1)
	assert_lte(tracker._sequence.size(), 3, "histórico só precisa guardar o maior combo")
	assert_not_null(tracker.register(&"heavy", 10.0), "limitar memória preserva o sufixo do combo")


func test_progress_exposes_finisher_without_consuming_sequence():
	tracker.register(&"basic", 0.0)
	tracker.register(&"basic", 0.3)
	var progress := tracker.progress(0.5)
	assert_eq(progress.steps, 2)
	assert_eq(progress.next_attack, &"heavy")
	assert_almost_eq(progress.time_left, 0.6, 0.001)
	assert_not_null(tracker.register(&"heavy", 0.6), "leitura do HUD preserva o combo")
	assert_true(tracker.progress(0.6).is_empty())


func test_progress_expires_without_a_new_attack():
	tracker.register(&"heavy", 1.0)
	assert_false(tracker.progress(1.5).is_empty())
	assert_true(tracker.progress(1.0 + WINDOW + 0.01).is_empty())


func test_empty_combo_never_matches():
	var empty_combo := ComboData.new()
	var empty_tracker := ComboTracker.new([empty_combo], WINDOW)
	assert_null(empty_tracker.register(&"basic", 0.0))
	assert_true(empty_tracker.progress(0.1).is_empty())
