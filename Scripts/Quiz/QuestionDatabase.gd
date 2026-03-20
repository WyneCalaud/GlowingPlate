class_name QuestionDatabase
extends Node

# --- CENTRALIZED QUESTION DATA ---
# This is the single source of truth for both GlowDesk and QuizScene.

# HOW TO ADD IMAGES:
# Use preload: "q_img": preload("res://Items/Fruits/Apple.png")
# If no image, keep it null.

static var group_a: Array = [
	{ 
		"id": "A1", 
		"q": "Pinggang Pinoy is made up of?", 
		"q_img": preload("res://Assets/UI/QuestionImages/PP1.png"),
		"ans": "Go, Grow, Glow Foods and Water", "ans_img": null,
		"wrong1": "Go Foods and Water", "wrong1_img": null,
		"wrong2": "Go, Grow, Glow Foods", "wrong2_img": null,
		"expl": "A balanced plate includes all food groups plus water." 
	},
	{ 
		"id": "A2", 
		"q": "Which food group belongs in this red section of the plate?", 
		"q_img": preload("res://Assets/UI/QuestionImages/PP2.png"),
		"ans": "Go Foods", "ans_img": null,
		"wrong1": "Glow Foods", "wrong1_img": null,
		"wrong2": "Grow Foods", "wrong2_img": null,
		"expl": "Go foods provide energy." 
	},
	{ 
		"id": "A3", 
		"q": "Which food group belongs in this green section of the plate?", 
		"q_img": preload("res://Assets/UI/QuestionImages/PP3.png"),
		"ans": "Glow Foods", "ans_img": null,
		"wrong1": "Go Foods", "wrong1_img": null,
		"wrong2": "Grow Foods", "wrong2_img": null,
		"expl": "Glow foods keep you healthy." 
	},
	{ 
		"id": "A4", 
		"q": "Which food group belongs in this yellow section of the plate?", 
		"q_img": preload("res://Assets/UI/QuestionImages/PP4.png"),
		"ans": "Grow Foods", "ans_img": null,
		"wrong1": "Glow Foods", "wrong1_img": null,
		"wrong2": "Go Foods", "wrong2_img": null,
		"expl": "Grow foods build muscles." 
	},
	{ 
		"id": "A5", 
		"q": "What is the main role of carbohydrates in our body?", 
		"q_img": preload("res://Assets/UI/QuestionImages/Go1.png"),
		"ans": "Give lots of energy", "ans_img": null,
		"wrong1": "Helps with digestion", "wrong1_img": null,
		"wrong2": "Helps build strong bones and muscles", "wrong2_img": null,
		"expl": "Carbohydrates are the body's main energy source." 
	},
	{ 
		"id": "A6", 
		"q": "Go foods are rich in?", 
		"q_img": preload("res://Assets/UI/QuestionImages/Go2.png"),
		"ans": "Carbohydrates/ Carbs", "ans_img": null,
		"wrong1": "Protein", "wrong1_img": null,
		"wrong2": "Starch", "wrong2_img": null,
		"expl": "Go foods provide carbohydrates for energy." 
	},
	{ 
		"id": "A7", 
		"q": "What does carbohydrates do for our body?", 
		"q_img": preload("res://Assets/UI/QuestionImages/Go3.png"),
		"ans": "Give lots of energy", "ans_img": null,
		"wrong1": "Helps with digestion", "wrong1_img": null,
		"wrong2": "Helps build strong bones and muscles", "wrong2_img": null,
		"expl": "Carbs fuel the brain and muscles." 
	},
	{ 
		"id": "A8", 
		"q": "What is the main role of protein in our body?", 
		"q_img": preload("res://Assets/UI/QuestionImages/Grow1.png"),
		"ans": "Helps build strong bones and muscles", "ans_img": null,
		"wrong1": "Give lots of energy", "wrong1_img": null,
		"wrong2": "Helps fight diseases", "wrong2_img": null,
		"expl": "Protein builds and repairs body tissues." 
	},
	{ 
		"id": "A9", 
		"q": "Grow foods are rich in?", 
		"q_img": preload("res://Assets/UI/QuestionImages/Grow2.png"),
		"ans": "Protein", "ans_img": null,
		"wrong1": "Carbohydrates/ Carbs", "wrong1_img": null,
		"wrong2": "Vitamins, Minerals and Fiber", "wrong2_img": null,
		"expl": "Grow foods are protein-rich foods." 
	},
	{ 
		"id": "A10", 
		"q": "What does protein do for our body?", 
		"q_img": preload("res://Assets/UI/QuestionImages/Grow3.png"),
		"ans": "Helps build strong bones and muscles", "ans_img": null,
		"wrong1": "Give lots of energy", "wrong1_img": null,
		"wrong2": "Helps with digestion", "wrong2_img": null,
		"expl": "Protein builds and repairs body tissues." 
	},
	{ 
		"id": "A11", 
		"q": "What is the main role of vitamins, and minerals in our body?", 
		"q_img": preload("res://Assets/UI/QuestionImages/Glow1.png"),
		"ans": "Helps fight diseases", "ans_img": null,
		"wrong1": "Give lots of energy", "wrong1_img": null,
		"wrong2": "Helps build strong bones and muscles", "wrong2_img": null,
		"expl": "Vitamins and minerals protect the body." 
	},
	{ 
		"id": "A12", 
		"q": "Glow foods are rich in?", 
		"q_img": preload("res://Assets/UI/QuestionImages/Glow2.png"),
		"ans": "Vitamins, Minerals and Fiber", "ans_img": null,
		"wrong1": "Carbohydrates/Carbs", "wrong1_img": null,
		"wrong2": "Protein", "wrong2_img": null,
		"expl": "Glow foods keep you healthy." 
	},
	{ 
		"id": "A13", 
		"q": "What does Vitamins and Minerals do for our body?", 
		"q_img": preload("res://Assets/UI/QuestionImages/Glow3.png"),
		"ans": "Helps fight off diseases", "ans_img": null,
		"wrong1": "Give lots of energy", "wrong1_img": null,
		"wrong2": "Helps with digestion and keeps you full", "wrong2_img": null,
		"expl": "They boost your immune system." 
	},
	{ 
		"id": "A14", 
		"q": "What does Fiber do for our body?", 
		"q_img": preload("res://Assets/UI/QuestionImages/Glow4.png"),
		"ans": "Helps with digestion and keeps you full", "ans_img": null,
		"wrong1": "Give lots of energy", "wrong1_img": null,
		"wrong2": "Helps fight off diseases", "wrong2_img": null,
		"expl": "Fiber keeps your stomach happy." 
	}
]

static var group_b: Array = [
	{ 
		"id": "B1", 
		"q": "Which foods help your body build strong bones and muscles?", 
		"q_img": preload("res://Assets/UI/QuestionImages/FGC1.png"),
		"ans": null, "ans_img": preload("res://Assets/UI/AnswerImages/FishAndEgg.png"),
		"wrong1": null, "wrong1_img": preload("res://Assets/UI/AnswerImages/RiceAndCorn.png"),
		"wrong2": null, "wrong2_img": preload("res://Assets/UI/AnswerImages/MangoAndCarrot.png"),
		"expl": "Fish and egg are Grow foods." 
	},
	{ 
		"id": "B2", 
		"q": "Which foods gives you lots of carbohydrates?", 
		"q_img": preload("res://Assets/UI/QuestionImages/FGC1.png"),
		"ans": null, "ans_img": preload("res://Assets/UI/AnswerImages/RiceAndCorn.png"),
		"wrong1": null, "wrong1_img": preload("res://Assets/UI/AnswerImages/FishAndEgg.png"),
		"wrong2": null, "wrong2_img": preload("res://Assets/UI/AnswerImages/MangoAndCarrot.png"),
		"expl": "Rice and corn are Go foods." 
	},
	{ 
		"id": "B3", 
		"q": "Which foods are both Grow foods?", 
		"q_img": preload("res://Assets/UI/QuestionImages/FGC1.png"),
		"ans": null, "ans_img": preload("res://Assets/UI/AnswerImages/TokwaAndFish.png"),
		"wrong1": null, "wrong1_img": preload("res://Assets/UI/AnswerImages/CornAndPandesal.png"),
		"wrong2": null, "wrong2_img": preload("res://Assets/UI/AnswerImages/FishAndRice.png"),
		"expl": "Tokwa and Fish are rich in protein." 
	},
	{ 
		"id": "B4", 
		"q": "Which foods are both Go foods?", 
		"q_img": preload("res://Assets/UI/QuestionImages/FGC1.png"),
		"ans": null, "ans_img": preload("res://Assets/UI/AnswerImages/CornAndPandesal.png"),
		"wrong1": null, "wrong1_img": preload("res://Assets/UI/AnswerImages/FishAndRice.png"),
		"wrong2": null, "wrong2_img": preload("res://Assets/UI/AnswerImages/TokwaAndMango.png"),
		"expl": "Corn and bread give you energy." 
	},
	{ 
		"id": "B5", 
		"q": "Which foods are both Glow foods?", 
		"q_img": preload("res://Assets/UI/QuestionImages/FGC1.png"),
		"ans": null, "ans_img": preload("res://Assets/UI/AnswerImages/SitawAndBanana.png"),
		"wrong1": null, "wrong1_img": preload("res://Assets/UI/AnswerImages/MangoAndEgg.png"),
		"wrong2": null, "wrong2_img": preload("res://Assets/UI/AnswerImages/TokwaAndMango.png"),
		"expl": "Fruits and vegetables make you glow." 
	},
	{ 
		"id": "B6", 
		"q": "Which group does “rice” belong to?", 
		"q_img": preload("res://Assets/UI/QuestionImages/FGC2.png"),
		"ans": "GO", "ans_img": null,
		"wrong1": "GROW", "wrong1_img": null,
		"wrong2": "GLOW", "wrong2_img": null,
		"expl": "Rice is a carbohydrate." 
	},
	{ 
		"id": "B7", 
		"q": "Which group does “pan de sal” belongs to?", 
		"q_img": preload("res://Assets/UI/QuestionImages/FGC3.png"),
		"ans": "GO", "ans_img": null,
		"wrong1": "GROW", "wrong1_img": null,
		"wrong2": "GLOW", "wrong2_img": null,
		"expl": "Bread is a carbohydrate." 
	},
	{ 
		"id": "B8", 
		"q": "Which group does “chicken” belongs to?", 
		"q_img": preload("res://Assets/UI/QuestionImages/FGC4.png"),
		"ans": "GROW", "ans_img": null,
		"wrong1": "GO", "wrong1_img": null,
		"wrong2": "GLOW", "wrong2_img": null,
		"expl": "Chicken provides protein." 
	},
	{ 
		"id": "B9", 
		"q": "Which group does “fish” belong to?", 
		"q_img": preload("res://Assets/UI/QuestionImages/FGC5.png"),
		"ans": "GROW", "ans_img": null,
		"wrong1": "GO", "wrong1_img": null,
		"wrong2": "GLOW", "wrong2_img": null,
		"expl": "Fish provides protein." 
	},
	{ 
		"id": "B10", 
		"q": "Which group does “egg” belong to?", 
		"q_img": preload("res://Assets/UI/QuestionImages/FGC6.png"),
		"ans": "GROW", "ans_img": null,
		"wrong1": "GO", "wrong1_img": null,
		"wrong2": "GLOW", "wrong2_img": null,
		"expl": "Eggs provide protein." 
	},
	{ 
		"id": "B11", 
		"q": "Which group does “tokwa” belong to?", 
		"q_img": preload("res://Assets/UI/QuestionImages/FGC7.png"),
		"ans": "GROW", "ans_img": null,
		"wrong1": "GO", "wrong1_img": null,
		"wrong2": "GLOW", "wrong2_img": null,
		"expl": "Tokwa provides plant-based protein." 
	},
	{ 
		"id": "B12", 
		"q": "Which group does “mango” belong to?", 
		"q_img": preload("res://Assets/UI/QuestionImages/FGC8.png"),
		"ans": "GLOW", "ans_img": null,
		"wrong1": "GO", "wrong1_img": null,
		"wrong2": "GROW", "wrong2_img": null,
		"expl": "Fruits give you vitamins." 
	},
	{ 
		"id": "B13", 
		"q": "Which group does “banana” belong to?", 
		"q_img": preload("res://Assets/UI/QuestionImages/FGC9.png"),
		"ans": "GLOW", "ans_img": null,
		"wrong1": "GO", "wrong1_img": null,
		"wrong2": "GROW", "wrong2_img": null,
		"expl": "Fruits give you vitamins." 
	},
	{ 
		"id": "B14", 
		"q": "Which group does “sitaw” belong to?", 
		"q_img": preload("res://Assets/UI/QuestionImages/FGC10.png"),
		"ans": "GLOW", "ans_img": null,
		"wrong1": "GO", "wrong1_img": null,
		"wrong2": "GROW", "wrong2_img": null,
		"expl": "Vegetables give you vitamins and fiber." 
	},
	{ 
		"id": "B15", 
		"q": "Which group does “carrots” belong to?", 
		"q_img": preload("res://Assets/UI/QuestionImages/FGC11.png"),
		"ans": "GLOW", "ans_img": null,
		"wrong1": "GO", "wrong1_img": null,
		"wrong2": "GROW", "wrong2_img": null,
		"expl": "Vegetables give you vitamins and fiber." 
	},
	{ 
		"id": "B16", 
		"q": "Which group does “corn” belong to?", 
		"q_img": preload("res://Assets/UI/QuestionImages/FGC12.png"),
		"ans": "GO", "ans_img": null,
		"wrong1": "GROW", "wrong1_img": null,
		"wrong2": "GLOW", "wrong2_img": null,
		"expl": "Corn is a carbohydrate source." 
	},
	{ 
		"id": "B17", 
		"q": "Which group does “watermelon” belong to?", 
		"q_img": preload("res://Assets/UI/QuestionImages/FGC13.png"),
		"ans": "GLOW", "ans_img": null,
		"wrong1": "GO", "wrong1_img": null,
		"wrong2": "GROW", "wrong2_img": null,
		"expl": "Fruits give you vitamins." 
	},
	{ 
		"id": "B18", 
		"q": "Which food group is missing from the plate?", 
		"q_img": preload("res://Assets/UI/QuestionImages/BM1.png"),
		"ans": "Go Foods", "ans_img": null,
		"wrong1": "Grow Foods", "wrong1_img": null,
		"wrong2": "Glow Foods", "wrong2_img": null,
		"expl": "A complete plate needs Go, Grow, and Glow." 
	},
	{ 
		"id": "B19", 
		"q": "Which of the following meal is complete?", 
		"q_img": preload("res://Assets/UI/QuestionImages/BM2.png"),
		"ans": null, "ans_img": preload("res://Assets/UI/AnswerImages/Meal2.png"),
		"wrong1": null, "wrong1_img": preload("res://Assets/UI/AnswerImages/Meal1.png"),
		"wrong2": null, "wrong2_img": preload("res://Assets/UI/AnswerImages/Meal3.png"),
		"expl": "A complete meal has Go, Grow, and Glow foods." 
	},
	{ 
		"id": "B20", 
		"q": "What can you add to make this meal balanced?", 
		"q_img": preload("res://Assets/UI/QuestionImages/BM3.png"),
		"ans": null, "ans_img": preload("res://Assets/UI/AnswerImages/RiceAndCorn.png"),
		"wrong1": null, "wrong1_img": preload("res://Assets/UI/AnswerImages/FishAndPapaya.png"),
		"wrong2": null, "wrong2_img": preload("res://Assets/UI/AnswerImages/KalabasaAndWatermelon.png"),
		"expl": "Adding carbs provides Go foods for energy." 
	},
	{ 
		"id": "B21", 
		"q": "What can you add to make this meal balanced?", 
		"q_img": preload("res://Assets/UI/QuestionImages/BM4.png"),
		"ans": null, "ans_img": preload("res://Assets/UI/AnswerImages/FishAndPapaya.png"),
		"wrong1": null, "wrong1_img": preload("res://Assets/UI/AnswerImages/RiceAndCorn.png"),
		"wrong2": null, "wrong2_img": preload("res://Assets/UI/AnswerImages/KalabasaAndWatermelon.png"),
		"expl": "Adding protein provides Grow foods for muscles." 
	},
	{ 
		"id": "B22", 
		"q": "What can you add to make this meal balanced?", 
		"q_img": preload("res://Assets/UI/QuestionImages/BM5.png"),
		"ans": null, "ans_img": preload("res://Assets/UI/AnswerImages/FishAndWatermelon.png"),
		"wrong1": null, "wrong1_img": preload("res://Assets/UI/AnswerImages/RiceAndCorn.png"),
		"wrong2": null, "wrong2_img": preload("res://Assets/UI/AnswerImages/KalabasaAndWatermelon.png"),
		"expl": "Adding vegetables and fruit provides Glow foods." 
	},
	{ 
		"id": "B23", 
		"q": "Why is a balanced meal important?", 
		"q_img": preload("res://Assets/UI/QuestionImages/BM6.png"),
		"ans": "It keeps our body healthy", "ans_img": null,
		"wrong1": "To make plate colorful", "wrong1_img": null,
		"wrong2": "It is faster to cook", "wrong2_img": null,
		"expl": "Balanced meals support overall health." 
	}
]

static var group_c: Array = [
	{ 
		"id": "C1", 
		"q": "How much sitaw should a 6–9 year old eat in one meal?", 
		"q_img": preload("res://Assets/UI/QuestionImages/P1.png"),
		"ans": null, "ans_img": preload("res://Assets/UI/AnswerImages/ThreeFourthCupSitaw.png"),
		"wrong1": null, "wrong1_img": preload("res://Assets/UI/AnswerImages/OneCupSitaw.png"),
		"wrong2": null, "wrong2_img": preload("res://Assets/UI/AnswerImages/HalfCupSitaw.png"),
		"expl": "Portion sizes depend on age." 
	},
	{ 
		"id": "C2", 
		"q": "How much carrot should a 10-12 year old in one meal?", 
		"q_img": preload("res://Assets/UI/QuestionImages/P2.png"),
		"ans": null, "ans_img": preload("res://Assets/UI/AnswerImages/OneCupCarrot.png"),
		"wrong1": null, "wrong1_img": preload("res://Assets/UI/AnswerImages/ThreeFourthCarrot.png"),
		"wrong2": null, "wrong2_img": preload("res://Assets/UI/AnswerImages/OneFourthCarrot.png"),
		"expl": "Portion sizes depend on age." 
	},
	{ 
		"id": "C3", 
		"q": "How much mango should a kid eat in one meal?", 
		"q_img": preload("res://Assets/UI/QuestionImages/P3.png"),
		"ans": null, "ans_img": preload("res://Assets/UI/AnswerImages/OneSliceMango.png"),
		"wrong1": null, "wrong1_img": preload("res://Assets/UI/AnswerImages/HalfSliceMango.png"),
		"wrong2": null, "wrong2_img": preload("res://Assets/UI/AnswerImages/TwoWholeSliceMango.png"),
		"expl": "Portion sizes depend on age." 
	},
	{ 
		"id": "C4", 
		"q": "How much watermelon should a kid eat in one meal?", 
		"q_img": preload("res://Assets/UI/QuestionImages/P4.png"),
		"ans": null, "ans_img": preload("res://Assets/UI/AnswerImages/OneWatermelon.png"),
		"wrong1": null, "wrong1_img": preload("res://Assets/UI/AnswerImages/TwoWatermelons.png"),
		"wrong2": null, "wrong2_img": preload("res://Assets/UI/AnswerImages/ThreeWatermelons.png"),
		"expl": "Portion sizes depend on age." 
	},
	{ 
		"id": "C5", 
		"q": "How much chicken should a 6-9 year old eat in one meal?", 
		"q_img": preload("res://Assets/UI/QuestionImages/P5.png"),
		"ans": null, "ans_img": preload("res://Assets/UI/AnswerImages/WholeChicken.png"),
		"wrong1": null, "wrong1_img": preload("res://Assets/UI/AnswerImages/HalfChicken.png"),
		"wrong2": null, "wrong2_img": preload("res://Assets/UI/AnswerImages/2WholeChicken.png"),
		"expl": "Portion sizes depend on age." 
	},
	{ 
		"id": "C6", 
		"q": "How much fish should a 10-12 year old eat in one meal?", 
		"q_img": preload("res://Assets/UI/QuestionImages/P6.png"),
		"ans": null, "ans_img": preload("res://Assets/UI/AnswerImages/WholeFish.png"),
		"wrong1": null, "wrong1_img": preload("res://Assets/UI/AnswerImages/HalfFish.png"),
		"wrong2": null, "wrong2_img": preload("res://Assets/UI/AnswerImages/TwoWholeFish.png"),
		"expl": "Portion sizes depend on age." 
	},
	{ 
		"id": "C7", 
		"q": "How much rice should a 10-12 year old eat in one meal?", 
		"q_img": preload("res://Assets/UI/QuestionImages/P7.png"),
		"ans": null, "ans_img": preload("res://Assets/UI/AnswerImages/OneCupRice.png"),
		"wrong1": null, "wrong1_img": preload("res://Assets/UI/AnswerImages/ThreeFourthCup.png"),
		"wrong2": null, "wrong2_img": preload("res://Assets/UI/AnswerImages/TwoCupsRice.png"),
		"expl": "Portion sizes depend on age." 
	},
	{ 
		"id": "C8", 
		"q": "How much pan de sal should a 10-12 year old eat in one meal?", 
		"q_img": preload("res://Assets/UI/QuestionImages/P8.png"),
		"ans": null, "ans_img": preload("res://Assets/UI/AnswerImages/FourPandesal.png"),
		"wrong1": null, "wrong1_img": preload("res://Assets/UI/AnswerImages/ThreePandesal.png"),
		"wrong2": null, "wrong2_img": preload("res://Assets/UI/AnswerImages/TwoPandesal.png"),
		"expl": "Portion sizes depend on age." 
	},
	{ 
		"id": "C9", 
		"q": "Which drink is the healthiest choice when you are thirsty?", 
		"q_img": preload("res://Assets/UI/QuestionImages/HD1.png"),
		"ans": null, "ans_img": preload("res://Assets/UI/AnswerImages/Water.png"),
		"wrong1": null, "wrong1_img": preload("res://Assets/UI/AnswerImages/SweetenedJuice.png"),
		"wrong2": null, "wrong2_img": preload("res://Assets/UI/AnswerImages/Soda.png"),
		"expl": "Water is always the healthiest choice." 
	},
	{ 
		"id": "C10", 
		"q": "Why drinking water is important?", 
		"q_img": preload("res://Assets/UI/QuestionImages/HD2.png"),
		"ans": "It helps our body work properly", "ans_img": null,
		"wrong1": "It gives you strong muscles", "wrong1_img": null,
		"wrong2": "It replaces eating vegetables", "wrong2_img": null,
		"expl": "Water is essential for hydration." 
	},
	{ 
		"id": "C11", 
		"q": "Which drink helps keep your bones and teeth strong?", 
		"q_img": preload("res://Assets/UI/QuestionImages/HD3.png"),
		"ans": null, "ans_img": preload("res://Assets/UI/AnswerImages/Milk.png"),
		"wrong1": null, "wrong1_img": preload("res://Assets/UI/AnswerImages/SweetenedJuice.png"),
		"wrong2": null, "wrong2_img": preload("res://Assets/UI/AnswerImages/Soda2.png"),
		"expl": "Milk is full of calcium." 
	},
	{ 
		"id": "C12", 
		"q": "Milk is rich in which nutrient?", 
		"q_img": preload("res://Assets/UI/QuestionImages/HD4.png"),
		"ans": "Calcium", "ans_img": null,
		"wrong1": "Fiber", "wrong1_img": null,
		"wrong2": "Carbohydrates", "wrong2_img": null,
		"expl": "Milk contains calcium for strong bones." 
	},
	{ 
		"id": "C13", 
		"q": "What does Calcium do to our body?", 
		"q_img": preload("res://Assets/UI/QuestionImages/HD5.png"),
		"ans": "Keep our bones and muscles strong", "ans_img": null,
		"wrong1": "Helps with digestion", "wrong1_img": null,
		"wrong2": "Helps fight off diseases", "wrong2_img": null,
		"expl": "Calcium is essential for bone strength." 
	}
]

# Master Dictionary to access by Group Name
static var data: Dictionary = {
	"A": group_a,
	"B": group_b,
	"C": group_c
}

static var daily_schedule: Dictionary = {
	1: ["A1", "B1", "C1"],
	2: ["A2", "B2", "C2"],
	3: ["A3", "B3", "C3"],
	4: ["A4", "B4", "C4"],
	5: ["A5", "B5", "C5"],
	6: ["A6", "B6", "C6"],
	7: ["A7", "B7", "C7"],
	8: ["A8", "B8", "B9", "C8"],
	9: ["A9", "B10", "B11", "C9"],
	10: ["A10", "B12", "B13", "C10"],
	11: ["A11", "B14", "B15", "C11"],
	12: ["A12", "B16", "B17", "C12"],
	13: ["A13", "B18", "B19", "B20", "C13"],
	14: ["A14", "B21", "B22", "B23"]
}

# ==========================================================
# 🔥 NEW: AUTO ADD CONCEPT BASED ON ID
# ==========================================================

static func _add_concept_field(q: Dictionary) -> Dictionary:
	var new_q = q.duplicate(true)

	if not new_q.has("concept"):
		var id: String = new_q.get("id", "")
		
		# Extract concept (A5 → A5, B12 → B12)
		new_q["concept"] = id

	return new_q


# ==========================================================
# HELPERS (UPDATED)
# ==========================================================

static func get_all_questions() -> Array:
	var all = []
	
	for q in group_a:
		all.append(_add_concept_field(q))
	for q in group_b:
		all.append(_add_concept_field(q))
	for q in group_c:
		all.append(_add_concept_field(q))
	
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


static func get_all_concepts() -> Array:
	var concepts = []

	for q in get_all_questions():
		var c = q.get("concept")
		if c != null and not concepts.has(c):
			concepts.append(c)

	return concepts


static func get_questions_by_concept(concept: String) -> Array:
	var results = []

	for q in get_all_questions():
		if q.get("concept") == concept:
			results.append(q)

	return results
