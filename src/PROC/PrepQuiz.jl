module PrepQuiz

using CSV
using DataFrames
using Statistics
using Dates

export create_quiz_analysis_df, create_quiz_question_time_dict,
       quiz_start_t_diff, quiz_duration

# Quiz performace preparation

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

# Quiz access preparation

function quiz_start_t_diff(df_quiz_access::DataFrame, df_Wstart_t::DataFrame)

  df_Wstart_t.Wstart_t = DateTime.(df_Wstart_t.Wstart_t)
  df_merged = leftjoin(df_quiz_access, df_Wstart_t, on=:Weeks)
  df_clean = dropmissing(df_merged, [:Weeks, :Qstart_t, :Wstart_t])
  df_clean.time_diff = map(df_clean.Qstart_t, df_clean.Wstart_t) do qstart, wstart
    return (Dates.value(qstart) - Dates.value(wstart)) / 1000 / 3600 / 24
  end

  gdf = groupby(df_clean, :Weeks)

  df_start_t_diff = combine(
    gdf,
    :time_diff => mean => :mean_days,
    :time_diff => median => :median_days,
    :time_diff => std => :std_days,
    nrow => :count
  )

  sort!(df_start_t_diff, :Weeks)

  return df_start_t_diff 
end

function quiz_duration(df_quiz_access::DataFrame)

  df_clean = dropmissing(df_quiz_access, [:Weeks, :Qstart_t])
  gdf = groupby(df_clean, :Weeks)

  df_duration = combine(
    gdf,
    :Duration => mean => :mean_durations,
    :Duration => median => :median_durations,
    :Duration => std => :std_durations,
    nrow => :count
  )

  sort!(df_duration, :Weeks)

  return df_duration 
end

end
