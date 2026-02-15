class_name QuestionDatabase
extends Node

# --- CENTRALIZED QUESTION DATA ---
# This is the single source of truth for both GlowDesk and QuizScene.
# Total: 42 Questions (14 Days x 3 Questions)

# HOW TO ADD IMAGES:
# Use preload: "q_img": preload("res://Items/Fruits/Apple.png")
# If no image, keep it null.

static var group_a: Array = [
	# --- DAYS 1-5 (Basics) ---
	{ 
		"id": "A1", 
		"q": "Which food gives you energy to run?", 
		"q_img": null,
		"ans": "Rice", "ans_img": null,
		"wrong1": "Water", "wrong1_img": null,
		"wrong2": "Spinach", "wrong2_img": null,
		"expl": "Rice is a Go Food (Carbohydrate)!" 
	},
	{ 
		"id": "A2", 
		"q": "What nutrient helps build muscles?", 
		"q_img": null,
		"ans": "Protein", "ans_img": null,
		"wrong1": "Vitamins", "wrong1_img": null,
		"wrong2": "Water", "wrong2_img": null,
		"expl": "Protein is the building block for muscles." 
	},
	{ 
		"id": "A3", 
		"q": "Which of these is a complex carbohydrate?", 
		"q_img": null,
		"ans": "Oatmeal", "ans_img": null,
		"wrong1": "Candy", "wrong1_img": null,
		"wrong2": "Soda", "wrong2_img": null,
		"expl": "Oatmeal gives long-lasting energy, unlike sugar." 
	},
	{ 
		"id": "A4", 
		"q": "Go Foods help you do what?", 
		"q_img": null,
		"ans": "Go, Run & Play", "ans_img": null,
		"wrong1": "Sleep better", "wrong1_img": null,
		"wrong2": "See in dark", "wrong2_img": null,
		"expl": "They provide fuel for movement." 
	},
	{ 
		"id": "A5", 
		"q": "Which is a healthy source of fat?", 
		"q_img": null,
		"ans": "Avocado", "ans_img": null,
		"wrong1": "French Fries", "wrong1_img": null,
		"wrong2": "Soda", "wrong2_img": null,
		"expl": "Avocados have good fats for your brain." 
	},
	# --- DAYS 6-10 (Intermediate) ---
	{ 
		"id": "A6", 
		"q": "What happens if you eat too much sugar?", 
		"q_img": null,
		"ans": "Energy Crash", "ans_img": null,
		"wrong1": "Big Muscles", "wrong1_img": null,
		"wrong2": "Better Vision", "wrong2_img": null,
		"expl": "Sugar gives fast energy but leaves you tired later." 
	},
	{ 
		"id": "A7", 
		"q": "Potatoes are a type of...", 
		"q_img": null,
		"ans": "Carbohydrate", "ans_img": null,
		"wrong1": "Protein", "wrong1_img": null,
		"wrong2": "Dairy", "wrong2_img": null,
		"expl": "They give you energy!" 
	},
	{ 
		"id": "A8", 
		"q": "Pasta belongs to which food group?", 
		"q_img": null,
		"ans": "Go Foods", "ans_img": null,
		"wrong1": "Glow Foods", "wrong1_img": null,
		"wrong2": "Grow Foods", "wrong2_img": null,
		"expl": "Pasta is made of grain and gives energy." 
	},
	{ 
		"id": "A9", 
		"q": "Butter is mainly...", 
		"q_img": null,
		"ans": "Fat", "ans_img": null,
		"wrong1": "Protein", "wrong1_img": null,
		"wrong2": "Vitamin", "wrong2_img": null,
		"expl": "Fats give stored energy." 
	},
	{ 
		"id": "A10", 
		"q": "What is the brain's main fuel?", 
		"q_img": null,
		"ans": "Glucose (Sugar)", "ans_img": null,
		"wrong1": "Iron", "wrong1_img": null,
		"wrong2": "Salt", "wrong2_img": null,
		"expl": "Your brain needs carbs to think!" 
	},
	# --- DAYS 11-14 (Advanced) ---
	{ 
		"id": "A11", 
		"q": "Why is brown rice better than white?", 
		"q_img": null,
		"ans": "More Fiber", "ans_img": null,
		"wrong1": "Sweeter", "wrong1_img": null,
		"wrong2": "Softer", "wrong2_img": null,
		"expl": "Fiber helps your tummy work better." 
	},
	{ 
		"id": "A12", 
		"q": "Which of these is a grain?", 
		"q_img": null,
		"ans": "Wheat", "ans_img": null,
		"wrong1": "Apple", "wrong1_img": null,
		"wrong2": "Beef", "wrong2_img": null,
		"expl": "Grains are Go foods like bread and rice." 
	},
	{ 
		"id": "A13", 
		"q": "Without energy foods, you feel...", 
		"q_img": null,
		"ans": "Tired/Weak", "ans_img": null,
		"wrong1": "Hyper", "wrong1_img": null,
		"wrong2": "Strong", "wrong2_img": null,
		"expl": "Just like a car needs gas, you need food." 
	},
	{ 
		"id": "A14", 
		"q": "Bread is mostly made from...", 
		"q_img": null,
		"ans": "Flour", "ans_img": null,
		"wrong1": "Milk", "wrong1_img": null,
		"wrong2": "Eggs", "wrong2_img": null,
		"expl": "Flour comes from grains like wheat." 
	}
]

static var group_b: Array = [
	# --- DAYS 1-5 ---
	{ 
		"id": "B1", 
		"q": "Which vitamin helps you see in the dark?", 
		"q_img": null,
		"ans": "Vitamin A", "ans_img": null,
		"wrong1": "Vitamin C", "wrong1_img": null,
		"wrong2": "Calcium", "wrong2_img": null,
		"expl": "Vitamin A is found in carrots and helps eyes!" 
	},
	{ 
		"id": "B2", 
		"q": "What does Vitamin C boost?", 
		"q_img": null,
		"ans": "Immune System", "ans_img": null,
		"wrong1": "Bones", "wrong1_img": null,
		"wrong2": "Muscles", "wrong2_img": null,
		"expl": "It helps fight off colds and flu." 
	},
	{ 
		"id": "B3", 
		"q": "Which mineral makes bones hard?", 
		"q_img": null,
		"ans": "Calcium", "ans_img": null,
		"wrong1": "Iron", "wrong1_img": null,
		"wrong2": "Potassium", "wrong2_img": null,
		"expl": "Calcium acts like cement for your skeleton." 
	},
	{ 
		"id": "B4", 
		"q": "Green leafy vegetables give you...", 
		"q_img": null,
		"ans": "Iron", "ans_img": null,
		"wrong1": "Sugar", "wrong1_img": null,
		"wrong2": "Fats", "wrong2_img": null,
		"expl": "Iron helps your blood carry oxygen." 
	},
	{ 
		"id": "B5", 
		"q": "Bananas are rich in...", 
		"q_img": null,
		"ans": "Potassium", "ans_img": null,
		"wrong1": "Salt", "wrong1_img": null,
		"wrong2": "Fat", "wrong2_img": null,
		"expl": "Potassium keeps muscles working well." 
	},
	# --- DAYS 6-10 ---
	{ 
		"id": "B6", 
		"q": "Glow foods help keep you...", 
		"q_img": null,
		"ans": "Healthy", "ans_img": null,
		"wrong1": "Tired", "wrong1_img": null,
		"wrong2": "Full", "wrong2_img": null,
		"expl": "They protect your body from sickness." 
	},
	{ 
		"id": "B7", 
		"q": "Which is a citrus fruit?", 
		"q_img": null,
		"ans": "Lemon", "ans_img": null,
		"wrong1": "Banana", "wrong1_img": null,
		"wrong2": "Apple", "wrong2_img": null,
		"expl": "Citrus fruits are sour and have Vitamin C." 
	},
	{ 
		"id": "B8", 
		"q": "Vegetables have fiber for...", 
		"q_img": null,
		"ans": "Digestion", "ans_img": null,
		"wrong1": "Vision", "wrong1_img": null,
		"wrong2": "Hearing", "wrong2_img": null,
		"expl": "Fiber keeps your stomach happy." 
	},
	{ 
		"id": "B9", 
		"q": "Which fruit has seeds on the outside?", 
		"q_img": null,
		"ans": "Strawberry", "ans_img": null,
		"wrong1": "Watermelon", "wrong1_img": null,
		"wrong2": "Apple", "wrong2_img": null,
		"expl": "Strawberries are special berries!" 
	},
	{ 
		"id": "B10", 
		"q": "Sunshine helps you make...", 
		"q_img": null,
		"ans": "Vitamin D", "ans_img": null,
		"wrong1": "Vitamin C", "wrong1_img": null,
		"wrong2": "Iron", "wrong2_img": null,
		"expl": "Vitamin D helps strong bones." 
	},
	# --- DAYS 11-14 ---
	{ 
		"id": "B11", 
		"q": "Dried grapes are called...", 
		"q_img": null,
		"ans": "Raisins", "ans_img": null,
		"wrong1": "Prunes", "wrong1_img": null,
		"wrong2": "Dates", "wrong2_img": null,
		"expl": "They are a sweet, healthy snack." 
	},
	{ 
		"id": "B12", 
		"q": "Eat a rainbow means...", 
		"q_img": null,
		"ans": "Colorful Veggies", "ans_img": null,
		"wrong1": "Skittles", "wrong1_img": null,
		"wrong2": "Only Green food", "wrong2_img": null,
		"expl": "Different colors have different vitamins." 
	},
	{ 
		"id": "B13", 
		"q": "Tomatoes are technically...", 
		"q_img": null,
		"ans": "Fruits", "ans_img": null,
		"wrong1": "Roots", "wrong1_img": null,
		"wrong2": "Leaves", "wrong2_img": null,
		"expl": "They have seeds inside!" 
	},
	{ 
		"id": "B14", 
		"q": "A vegetable that grows underground?", 
		"q_img": null,
		"ans": "Carrot", "ans_img": null,
		"wrong1": "Corn", "wrong1_img": null,
		"wrong2": "Lettuce", "wrong2_img": null,
		"expl": "Root vegetables grow in the soil." 
	}
]

static var group_c: Array = [
	# --- DAYS 1-5 ---
	{ 
		"id": "C1", 
		"q": "How much of your plate is fruit & veg?", 
		"q_img": null,
		"ans": "Half (1/2)", "ans_img": null,
		"wrong1": "None", "wrong1_img": null,
		"wrong2": "All of it", "wrong2_img": null,
		"expl": "A balanced meal is half Glow foods!" 
	},
	{ 
		"id": "C2", 
		"q": "Why is fiber important?", 
		"q_img": null,
		"ans": "Digestion", "ans_img": null,
		"wrong1": "Vision", "wrong1_img": null,
		"wrong2": "Hearing", "wrong2_img": null,
		"expl": "Fiber helps food move through your tummy." 
	},
	{ 
		"id": "C3", 
		"q": "What happens if you skip breakfast?", 
		"q_img": null,
		"ans": "Low Energy", "ans_img": null,
		"wrong1": "Super Strength", "wrong1_img": null,
		"wrong2": "Better Vision", "wrong2_img": null,
		"expl": "Breakfast is the fuel to start your day." 
	},
	{ 
		"id": "C4", 
		"q": "What should you drink when thirsty?", 
		"q_img": null,
		"ans": "Water", "ans_img": null,
		"wrong1": "Soda", "wrong1_img": null,
		"wrong2": "Juice only", "wrong2_img": null,
		"expl": "Water is the best for hydration." 
	},
	{ 
		"id": "C5", 
		"q": "How long should you wash hands?", 
		"q_img": null,
		"ans": "20 Seconds", "ans_img": null,
		"wrong1": "2 Seconds", "wrong1_img": null,
		"wrong2": "1 Minute", "wrong2_img": null,
		"expl": "Sing Happy Birthday twice!" 
	},
	# --- DAYS 6-10 ---
	{ 
		"id": "C6", 
		"q": "Brush teeth how many times a day?", 
		"q_img": null,
		"ans": "Two Times", "ans_img": null,
		"wrong1": "Never", "wrong1_img": null,
		"wrong2": "Ten times", "wrong2_img": null,
		"expl": "Morning and before bed." 
	},
	{ 
		"id": "C7", 
		"q": "Sleep helps you...", 
		"q_img": null,
		"ans": "Grow & Rest", "ans_img": null,
		"wrong1": "Get tired", "wrong1_img": null,
		"wrong2": "Stay small", "wrong2_img": null,
		"expl": "Your body repairs itself while sleeping." 
	},
	{ 
		"id": "C8", 
		"q": "Junk food is considered...", 
		"q_img": null,
		"ans": "Sometimes Food", "ans_img": null,
		"wrong1": "Everyday Food", "wrong1_img": null,
		"wrong2": "Never Food", "wrong2_img": null,
		"expl": "It's okay as a treat, but not always." 
	},
	{ 
		"id": "C9", 
		"q": "Exercise makes your heart...", 
		"q_img": null,
		"ans": "Stronger", "ans_img": null,
		"wrong1": "Slower", "wrong1_img": null,
		"wrong2": "Weaker", "wrong2_img": null,
		"expl": "The heart is a muscle that needs exercise." 
	},
	{ 
		"id": "C10", 
		"q": "Instead of TV, you should...", 
		"q_img": null,
		"ans": "Play Outside", "ans_img": null,
		"wrong1": "Sleep all day", "wrong1_img": null,
		"wrong2": "Eat candy", "wrong2_img": null,
		"expl": "Active play keeps bodies strong." 
	},
	# --- DAYS 11-14 ---
	{ 
		"id": "C11", 
		"q": "Wash fruits before...", 
		"q_img": null,
		"ans": "Eating", "ans_img": null,
		"wrong1": "Sleeping", "wrong1_img": null,
		"wrong2": "Cooking only", "wrong2_img": null,
		"expl": "Washing removes dirt and germs." 
	},
	{ 
		"id": "C12", 
		"q": "Milk teeth fall out for...", 
		"q_img": null,
		"ans": "Adult Teeth", "ans_img": null,
		"wrong1": "No Teeth", "wrong1_img": null,
		"wrong2": "Gold Teeth", "wrong2_img": null,
		"expl": "Permanent teeth last forever if brushed." 
	},
	{ 
		"id": "C13", 
		"q": "Germs make you...", 
		"q_img": null,
		"ans": "Sick", "ans_img": null,
		"wrong1": "Strong", "wrong1_img": null,
		"wrong2": "Happy", "wrong2_img": null,
		"expl": "Washing hands stops germs." 
	},
	{ 
		"id": "C14", 
		"q": "A healthy snack is...", 
		"q_img": null,
		"ans": "Yogurt", "ans_img": null,
		"wrong1": "Chips", "wrong1_img": null,
		"wrong2": "Cake", "wrong2_img": null,
		"expl": "Yogurt has calcium and protein." 
	}
]

# Master Dictionary to access by Group Name
static var data: Dictionary = {
	"A": group_a,
	"B": group_b,
	"C": group_c
}

# --- DAILY SCHEDULE (14 DAYS) ---
# Each day gets 1 question from A, 1 from B, 1 from C
static var daily_schedule: Dictionary = {
	1: ["A1", "B1", "C1"],
	2: ["A2", "B2", "C2"],
	3: ["A3", "B3", "C3"],
	4: ["A4", "B4", "C4"],
	5: ["A5", "B5", "C5"],
	6: ["A6", "B6", "C6"],
	7: ["A7", "B7", "C7"],
	8: ["A8", "B8", "C8"],
	9: ["A9", "B9", "C9"],
	10: ["A10", "B10", "C10"],
	11: ["A11", "B11", "C11"],
	12: ["A12", "B12", "C12"],
	13: ["A13", "B13", "C13"],
	14: ["A14", "B14", "C14"]
}

# --- HELPERS ---

static func get_all_questions() -> Array:
	var all = []
	all.append_array(group_a)
	all.append_array(group_b)
	all.append_array(group_c)
	return all

static func get_question_by_id(target_id: String) -> Dictionary:
	for q in get_all_questions():
		if q["id"] == target_id:
			return q
	return {}

static func get_questions_for_day(day: int) -> Array:
	var ids = daily_schedule.get(day, [])
	var questions = []
	for id in ids:
		var q = get_question_by_id(id)
		if not q.is_empty():
			questions.append(q)
	return questions
