"""
Test Python file for AI Documentation Generation Action.

This file is used to test the documentation.yml GitHub Actions workflow.
When this file is pushed to the main branch, it should trigger the 
AI Documentation Generation workflow.
"""


class Calculator:
    """A simple calculator class for basic arithmetic operations."""

    def add(self, a: float, b: float) -> float:
        """
        Add two numbers together.

        Args:
            a: The first number.
            b: The second number.

        Returns:
            The sum of a and b.
        """
        return a + b

    def subtract(self, a: float, b: float) -> float:
        """
        Subtract the second number from the first.

        Args:
            a: The first number.
            b: The second number.

        Returns:
            The difference of a and b.
        """
        return a - b

    def multiply(self, a: float, b: float) -> float:
        """
        Multiply two numbers together.

        Args:
            a: The first number.
            b: The second number.

        Returns:
            The multiplication of a and b.
        """
        return a * b

    def divide(self, a: float, b: float) -> float:
        """
        Divide the first number by the second.

        Args:
            a: The dividend.
            b: The divisor.

        Returns:
            The quotient of a divided by b.

        Raises:
            ValueError: If b is zero.
        """
        if b == 0:
            raise ValueError("Cannot divide by zero")
        return a / b


def greet(name: str) -> str:
    """
    Generate a greeting message.

    Args:
        name: The name of the person to greet.

    Returns:
        A personalized greeting string.
    """
    return f"Hello, {name}! Welcome to the Copilot CLI Automation Accelerator."


if __name__ == "__main__":
    # Test the Calculator class
    calc = Calculator()
    print(f"Addition: 5 + 3 = {calc.add(5, 3)}")
    print(f"Subtraction: 10 - 4 = {calc.subtract(10, 4)}")
    print(f"Multiplication: 6 * 7 = {calc.multiply(6, 7)}")
    print(f"Division: 20 / 4 = {calc.divide(20, 4)}")

    # Test the greet function
    print(greet("Developer"))
