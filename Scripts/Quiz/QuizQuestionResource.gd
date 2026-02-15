# QuizQuestionResource.gd
extends Resource
class_name QuizQuestionResource

@export var question_id: String = "Q_UNIQUE_ID" # CRITICAL: Unique ID for tracking SRS progress
@export var question_text: String = "What helps you run faster?"
@export var image_path: String = "" # Path to the main visual prompt
@export var correct_answer_key: String = "Go"

# Uses the globally defined QuizAnswerResource type.
@export var answers: Array[QuizAnswerResource]
