from knowledge.tools.calculator import calculate


def test_calculate():
    assert calculate("25 * 4 + 10") == 110


def test_division():
    assert calculate("100 / 4") == 25.0