STRATEGY_ID_2_NAME = {
    1: "Explanation_of_concept",
    2: "Ask_a_question",
    # 3: "Provide_a_hint", # Not doing because it doesn't show up enough
    4: "Provide_a_solution_strategy",
    5: "Prompt_an_explanation",
    6: "Encourage_student",
    7: "Affirm_correct_answer", 
    8: "Give_away_answer_explanation",
    9: "Retry",
    # 10: "NA"
}

CLASSIFIER_STRATEGY_NL = {
    "strategies-2": "Ask Question to Guide Thinking",
    "strategies-4": "Give Solution Strategy",
    "strategies-5": "Prompt Student to Explain",
    "strategies-6": "Encourage Student in Generic Way",
    "strategies-7": "Affirm Student's Correct Attempt",
    "strategies-8": "Give Away Answer/Explanation",
    "strategies-9": "Ask Student to Retry",
}

strategies_fname = "data/filtered_copilot_data.csv"