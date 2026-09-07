def calculate(expression):
    allowed = "0123456789+-*/(). "

    if any(char not in allowed for char in expression):
        raise ValueError("Invalid characters in expression")

    return eval(expression, {"__builtins__": None}, {})