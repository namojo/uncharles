## Proves the gdUnit4 runner discovers and executes suites under tests/unit/.
## A run that reports "No test cases found" exits 0 too, so this suite is the
## evidence that a green run actually ran something.
extends GdUnitTestSuite


func test_integer_addition_returns_expected_sum() -> void:
	# Arrange
	var left := 2
	var right := 3

	# Act
	var total := left + right

	# Assert
	assert_int(total).is_equal(5)
