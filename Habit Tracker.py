import json
import os
import pandas as pd 
from tabulate import tabulate

class HabitTracker:
    def __init__(self, filename="habits.json"):
        self.filename = filename
        self.status_map = {
            "1": "🔴 Not Done",
            "2": "🟡 Did a Bit",
            "3": "🟢 Done Completely"
        }
        self.habits = self.load_data()

    def load_data(self):
        """Loads habits from a JSON file if it exists."""
        if os.path.exists(self.filename):
            with open(self.filename, 'r') as f:
                return json.load(f)
        return []

    def save_data(self):
        """Saves current habits to the JSON file."""
        with open(self.filename, 'w') as f:
            json.dump(self.habits, f, indent=4)

    def add_habit(self):
        name = input("\nEnter the habit name: ").strip()
        if name:
            self.habits.append({"Habit": name, "Status": "⚪ Not Checked"})
            self.save_data()
            print(f"✔️ Added '{name}'")

    def update_status(self):
        if not self.habits:
            print("\nNo habits to update!")
            return

        print("\n--- Daily Check-in ---")
        for idx, habit in enumerate(self.habits):
            print(f"\n[{idx + 1}] {habit['Habit']}")
            print("1: Red | 2: Yellow | 3: Green | Enter: Skip")
            choice = input("Choice: ")
            
            if choice in self.status_map:
                self.habits[idx]['Status'] = self.status_map[choice]
        
        self.save_data()
        print("\n✅ Progress saved!")

    def show_table(self):
        if not self.habits:
            print("\nYour tracker is empty.")
            return
        
        df = pd.DataFrame(self.habits)
        print("\n--- My Habit Board ---")
        # fancy_grid makes it look like a real UI table
        print(tabulate(df, headers='keys', tablefmt='fancy_grid', showindex=False))

def main():
    tracker = HabitTracker()
    
    while True:
        print("\n" + "="*25)
        print("  HABIT TRACKER MENU")
        print("="*25)
        print("1. ➕ Add New Habit")
        print("2. 📝 Update Today's Progress")
        print("3. 📊 View My Table")
        print("4. ❌ Exit")
        
        cmd = input("\nSelect an option: ")
        
        if cmd == "1":
            tracker.add_habit()
        elif cmd == "2":
            tracker.update_status()
        elif cmd == "3":
            tracker.show_table()
        elif cmd == "4":
            print("Goodbye! Stay consistent.")
            break
        else:
            print("Invalid choice. Try again.")

if __name__ == "__main__":
    main()