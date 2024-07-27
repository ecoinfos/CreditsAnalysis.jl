module TopicStats

using DataFrames
using CSV
using Statistics

export join_scores_with_target_col, calculate_total_subject_avgs,
       calculate_student_subject_avgs, calculate_accuracy_from_origin,
       create_total_exam_df_by_subject

function join_scores_with_target_col(
  df_questions::DataFrame, df_anp_res::DataFrame, target_col::Symbol
)::DataFrame
  df_questions_selected = select(df_questions, :QuestionIDs, target_col)
  question_cols = names(df_anp_res, r"Q\d+")
  df_anp_res_long = stack(
    df_anp_res, question_cols, variable_name="QuestionIDs", value_name="Score"
  )
  df_joined = innerjoin(
    df_anp_res_long, df_questions_selected, on=:QuestionIDs
  )

  return df_joined
end

function calculate_total_subject_avgs(df_joined::DataFrame)::DataFrame
  df_avg_scores_per_question = combine(
    groupby(df_joined, [:Subjects, :QuestionIDs]), :Score => mean => :AvgScore
  )
  df_avg_scores_per_subject = combine(
    groupby(
      df_avg_scores_per_question, :Subjects
    ), :AvgScore => mean => :AvgScore
  )

  return df_avg_scores_per_subject
end

function calculate_student_subject_avgs(df_joined::DataFrame)::DataFrame
  df_avg_scores_per_student = combine(
    groupby(df_joined, [:IDs, :Names, :Subjects]), :Score => mean => :AvgScore
  )
  df_avg_scores_per_student = sort(df_avg_scores_per_student, :IDs)

  return df_avg_scores_per_student
end

function calculate_accuracy_from_origin(
  df_joined::DataFrame,
  student_id::Union{Int64, Nothing} = nothing
)::Dict{String, Float64}

  total_orig_rows = df_joined.Origin .== "오리지널"
  total_quiz_rows = df_joined.Origin .== "퀴즈"
  
  total_orig_correct = count(df_joined[total_orig_rows, :Score] .!= 0)
  total_quiz_correct = count(df_joined[total_quiz_rows, :Score] .!= 0)
  
  total_orig_total = count(total_orig_rows)
  total_quiz_total = count(total_quiz_rows)
  
  total_orig_accuracy = total_orig_correct / total_orig_total * 100
  total_quiz_accuracy = total_quiz_correct / total_quiz_total * 100
  
  result_dict = Dict{String, Float64}(
    "total_orig_accuracy" => total_orig_accuracy,
    "total_quiz_accuracy" => total_quiz_accuracy
  )
  
  if student_id === nothing
    result_dict["student_orig_accuracy"] = NaN
    result_dict["student_quiz_accuracy"] = NaN
  else
    student_rows = df_joined.IDs .== student_id
    student_orig_rows = student_rows .& (df_joined.Origin .== "오리지널")
    student_quiz_rows = student_rows .& (df_joined.Origin .== "퀴즈")
    
    student_orig_correct = count(df_joined[student_orig_rows, :Score] .!= 0)
    student_quiz_correct = count(df_joined[student_quiz_rows, :Score] .!= 0)
    
    student_orig_total = count(student_orig_rows)
    student_quiz_total = count(student_quiz_rows)
    
    student_orig_accuracy = student_orig_correct / student_orig_total * 100
    student_quiz_accuracy = student_quiz_correct / student_quiz_total * 100
    
    result_dict["student_orig_accuracy"] = student_orig_accuracy
    result_dict["student_quiz_accuracy"] = student_quiz_accuracy
  end
  
  return result_dict
end

function create_total_exam_df_by_subject(
  df_midterm::DataFrame,
  df_final::DataFrame,
  mod_col_midterm::Symbol,
  mod_col_final::Symbol,
  prefix_midterm::String = "M_",
  prefix_final::String = "F_"
)

  """

  """

  df_midterm_mod = transform(
    df_midterm, mod_col_midterm => ByRow(x -> prefix_midterm * x) => mod_col_midterm
  )
  df_final_mod = transform(
    df_final, mod_col_final => ByRow(x -> prefix_final * x) => mod_col_final
  )
  df_total = vcat(df_midterm_mod, df_final_mod)

  return df_total
end

end
