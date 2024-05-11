module ProcessingScores

using CreditsAnalysis
using DataFrames
using CairoMakie

export collect_results, count_correct_responses


function collect_results(df::DataFrame)::DataFrame
  df_res = df[occursin.("RES", df[:, :DataGroups]), :]

  return df_res
end

function count_correct_responses(df::DataFrame)::DataFrame
  student_ids = df.IDs
  for i in eachindex(student_ids) 
    if student_ids[i] in student_ids[i+1:end]
      error("Duplicate ID found")
    end
  end

  unique_ids = unique(df.IDs)
  df_res = DataFrame(ID = Int64[], Names = String[], Correct_count = Int64[])
  for student_id in unique_ids 
    student_df = filter(row -> row.IDs == student_id, df)
    student_name = first(student_df.Names)
    question_cols = filter(col -> startswith(string(col), "Q"), names(student_df))
    correct_count = sum(eachcol(student_df[!, question_cols] .== "O"))
    push!(df_res, (student_id, student_name, correct_count), promote=true)
  end

  return df_res
end

end
