module CreditsAnalysis

# Write your package code here.
include("PROC/QuizTransformer.jl")
include("PROC/LoadOMR.jl")
include("PROC/ProcessingScores.jl")
include("PROC/SubjectAchievement.jl")
include("PROC/ProcessingQuiz.jl")
include("UI/CreatePlots.jl")

end
