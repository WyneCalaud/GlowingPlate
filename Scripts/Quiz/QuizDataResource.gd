extends Resource
class_name QuizDataResource

# --- Global Quiz Configuration ---
@export var quiz_name: String = "Go Grow Glow Quiz"

# --- Array of Questions ---
# Uses the globally defined QuizQuestionResource type.
@export var questions: Array[QuizQuestionResource]
