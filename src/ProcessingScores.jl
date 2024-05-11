module ProcessingScores

using CreditsAnalysis
using DataFrames
using CairoMakie

export collect_results, count_correct_responses!


function collect_results(df::DataFrame)::DataFrame
  df_res = df[occursin.("RES", df[:, :DataGroups]), :]

  return df_res
end


function count_correct_responses!(
  df::DataFrame, col_prefix::String, old_new_pair::Dict{String, Int64}
)::DataFrame

  student_ids = df.IDs
  for i in eachindex(student_ids) 
    if student_ids[i] in student_ids[i+1:end]
      error("Duplicate ID found")
    end
  end

  cols = filter(col -> startswith(col, col_prefix), names(df))
  for col in cols 
    df[!, col] = map(x -> get(old_new_pair, x, x), df[!, col])
    df[!, col] = convert.(Int64, df[!, col])
  end

  return df
end

end
