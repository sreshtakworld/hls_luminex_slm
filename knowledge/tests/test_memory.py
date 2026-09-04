from knowledge.memory.memory import save_memory, get_memory, delete_memory


def test_memory_lifecycle():
    key = "test_memory_key"
    value = "test_memory_value"

    save_memory(key, value)
    assert get_memory(key) == value

    delete_memory(key)
    assert get_memory(key) is None