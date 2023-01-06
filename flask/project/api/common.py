"""
Here we define common utilities used in all the API versions
"""
import random


def plausible_random(start_value, start, end):
    """
    A generator that chooses a random number and generates random numbers around it
    :param start_value: The starting value
    :param start: The start number
    :param end: The end number
    """
    # Choose a random number
    if start_value == 0:
        number = random.randint(start, end)
    else:
        number = start_value
    rng = (end - start) // 40
    while True:
        if (end - start) // 2 < number:
            # 51% of chance to generate a positive number
            if random.randint(0, 100) > 60:
                number += random.randint(0, rng)
            else:
                number -= random.randint(0, rng)
        else:
            # 51% of chance to generate a negative number
            if random.randint(0, 100) > 60:
                number -= random.randint(0, rng)
            else:
                number += random.randint(0, rng)

        # If the number is out of bounds, clamp it
        if number < start:
            number = start
        elif number > end:
            number = end
        yield number
