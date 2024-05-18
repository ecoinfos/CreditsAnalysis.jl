module ProcessingScores

using CreditsAnalysis
using DataFrames
using CairoMakie

export collect_results, convert_ox_to_scores!, calculate_score_sums,
       plot_histogram


function collect_results(df::DataFrame, cat::String)::DataFrame
  """
  Collect row indices from a DataFrame where the DataGroups column contains
  the specified category (`cat`). The resulting DataFrame contains only the
  rows that match the specified category.
  """
  row_indices = findall(row -> occursin(cat, row.DataGroups), eachrow(df))
  df_res = df[row_indices, :]

  return df_res
end

function convert_ox_to_scores!(
  df::DataFrame, col_prefix::String, old_new_pair::Dict{String, Int64}
)::DataFrame
  """
  Find all columns in the DataFrame that start with the specified prefix after
  duplication test. Then convert the values in each column to the new values
  specified in the `old_new_pair` dictionary. The converted values are then
  converted to Int64 types and summed up to calculate the total score for
  each student.
  """
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

function calculate_score_sums(df::DataFrame, col_prefix::String)::DataFrame
  cols = filter(col -> startswith(col, col_prefix), names(df)) 
  df[!, :ScoreSums] = sum(eachcol(df[!, cols]))

  return df
end

function plot_histogram(df::DataFrame, bins::Int64, title::String, period::String)
  fig = Figure(size=(800, 600)) 

  ax = Axis(
    fig[1, 1],
    title = title,
    xlabel="Anatomy & Physiology $period Scores (pts.)",
    ylabel="Number of students (persons)"
  )
  hist!(ax, df.ScoreSums, bins=bins, color=:steelblue, strokewidth=0)

  return fig
end

end
