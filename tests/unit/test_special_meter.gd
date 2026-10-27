extends GutTest

var meter: SpecialMeter


func before_each():
	meter = SpecialMeter.new(5.0, 1.0)


func test_charges_over_time():
	meter.tick(2.0)
	assert_almost_eq(meter.value, 10.0, 0.001)


func test_charges_with_damage():
	meter.add_damage(30)
	assert_almost_eq(meter.value, 30.0, 0.001)


func test_caps_at_max():
	meter.add_damage(500)
	meter.tick(10.0)
	assert_eq(meter.value, SpecialMeter.MAX)
	assert_true(meter.is_full())


func test_cannot_consume_when_not_full():
	meter.add_damage(99)
	assert_false(meter.consume())
	assert_almost_eq(meter.value, 99.0, 0.001)


func test_consume_when_full_empties():
	meter.add_damage(100)
	assert_true(meter.consume())
	assert_eq(meter.value, 0.0)
