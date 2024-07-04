module ProcessingQuiz

using CSV
using DataFrames
using Statistics

export create_quiz_analysis_df, create_quiz_question_time_dict

function create_quiz_analysis_df(objective_data::String, df_quiz_weekly::DataFrame) 
  df_quiz_objectives = CSV.read(objective_data, DataFrame)
  df_quiz_joined = leftjoin(df_quiz_weekly, df_quiz_objectives, makeunique = true, on=:Questions)

  return df_quiz_joined
end

function create_quiz_question_time_dict(df_quiz_joined::DataFrame, student_id::Int64)
  # Filter quiz data by `Purposes` data 
  df_understanding = filter(row -> row.Purposes == "이해", df_quiz_joined)
  df_exploration = filter(row -> row.Purposes == "탐색", df_quiz_joined)
  
  # Calculate means of time for every question for all students
  df_understanding_time_avg = combine(
    groupby(df_understanding, [:Weeks, :IDs]), :Time => mean => :AvgTime
  )
  df_exploration_time_avg = combine(
    groupby(df_exploration, [:Weeks, :IDs]), :Time => mean => :AvgTime
  )

  # Filter student_id daata
  df_understanding_time_avg_student = filter(row -> row.IDs == student_id, df_understanding_time_avg)
  df_exploration_time_avg_student = filter(row -> row.IDs == student_id, df_exploration_time_avg)

  # Prepare dictionary containing the dataframes
  dict_quiz_purposes = Dict(
    "ua" => df_understanding_time_avg,
    "ea" => df_exploration_time_avg,
    "us" => df_understanding_time_avg_student,
    "es" => df_exploration_time_avg_student
  )

  return dict_quiz_purposes
end

end
