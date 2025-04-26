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
  student_id::Union{Int64, Nothing} = nothing,
  origin_types::Vector{String} = ["오리지널", "퀴즈", "형성평가", "강의영상"]
)::Dict{String, Float64}
  
  result_dict = Dict{String, Float64}()
  
  # 기존 호환성을 위한 매핑 정의
  key_mapping = Dict(
    "오리지널" => "orig",
    "퀴즈" => "quiz",
    "형성평가" => "formative",
    "강의영상" => "lecture_clip"
  )
  
  # 전체 학생 정확도 계산
  for origin in origin_types
    origin_rows = df_joined.Origin .== origin
    origin_correct = count(df_joined[origin_rows, :Score] .!= 0)
    origin_total = count(origin_rows)
    
    # 분모가 0인 경우 처리
    origin_accuracy = origin_total > 0 ? (origin_correct / origin_total * 100) : NaN
    
    # 기존 키 규칙 유지 (오리지널 -> orig, 퀴즈 -> quiz 등)
    key_suffix = get(key_mapping, origin, lowercase(origin))
    result_dict["total_$(key_suffix)_accuracy"] = origin_accuracy
  end
  
  # 특정 학생 정확도 계산
  if student_id !== nothing
    student_rows = df_joined.IDs .== student_id
    
    for origin in origin_types
      student_origin_rows = student_rows .& (df_joined.Origin .== origin)
      student_origin_correct = count(df_joined[student_origin_rows, :Score] .!= 0)
      student_origin_total = count(student_origin_rows)
      
      # 분모가 0인 경우 처리
      student_origin_accuracy = student_origin_total > 0 ? 
                               (student_origin_correct / student_origin_total * 100) : NaN
      
      # 기존 키 규칙 유지
      key_suffix = get(key_mapping, origin, lowercase(origin))
      result_dict["student_$(key_suffix)_accuracy"] = student_origin_accuracy
    end
  else
    # student_id가 없는 경우, 모든 출처 유형에 대해 NaN 값 설정
    for origin in origin_types
      key_suffix = get(key_mapping, origin, lowercase(origin))
      result_dict["student_$(key_suffix)_accuracy"] = NaN
    end
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
  Add corresponding prefix to question IDs in the midterm and final exam
  DataFrames. Then, concatenate the two DataFrames to create a total exam
  DataFrame.

  ```julia
  df_midterm = DataFrame(
    IDs = [1, 2], QuestionIDs = ["Q001", "Q001"], res = [0, 5]
  )
  df_final = DataFrame(
    IDs = [1, 2], QuestionIDs = ["Q001", "Q001"], res = [5, 5]
  )
  mod_col_midterm = :QuestionIDs
  mod_col_final = :QuestionIDs
  prefix_midterm = "M_"
  prefix_final = "F_"
  
  df_total = TS.create_total_exam_df_by_subject(
    df_midterm,
    df_final,
    mod_col_midterm,
    mod_col_final,
    prefix_midterm,
    prefix_final
  )
  ```
  8×3 DataFrame
  Row │ IDs    QuestionIDs  res
      │ Int64  String       Int64
  ────┼───────────────────────────
    1 │     1  M_Q001           0
    2 │     2  M_Q001           5
    3 │     1  F_Q001           5
    4 │     2  F_Q001           5
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
