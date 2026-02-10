import json
import os

# File where habits will be stored
DATA_FILE = "habits.json"

def load_habits():
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE, "r") as f:
            return json.load(f)
    return {}

def save_habits(habits):
    with open(DATA_FILE, "w") as f:
        json.dump(habits, f, indent=4)

def display_habits(habits):
    print("\n--- Your Habits ---")
    if not habits:
        print("No habits added yet!")
    for habit, status in habits.items():
        mark = "✓" if status else "✗"
        print(f"[{mark}] {habit}")
    print("-------------------\n")

def main():
    habits = load_habits()
    
    while True:
        display_habits(habits)
        print("1. Add Habit  2. Check/Uncheck Habit  3. Reset All  4. Exit")
        choice = input("Choose an option: ")

        if choice == "1":
            name = input("Enter habit name: ")
            habits[name] = False
        elif choice == "2":
            name = input("Enter the habit name to toggle: ")
            if name in habits:
                habits[name] = not habits[name]
            else:
                print("Habit not found!")
        elif choice == "3":
            for habit in habits:
                habits[habit] = False
            print("All habits reset.")
        elif choice == "4":
            save_habits(habits)
            print("Progress saved. Goodbye!")
            break
        else:
            print("Invalid choice.")
        
        save_habits(habits)

if __name__ == "__main__":
    main()
