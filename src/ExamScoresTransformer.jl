module ExamScoresTransformer

using CSV
using DataFrames
using ShiftedArrays

export load_exam_scores_data, make_questions_colnames_vector,
       transform_omr_data, replace_missings_from_df, convert_column_types,
       remove_unnecessary_columns, remove_unnecessary_marks,
       find_missing_rows_dict

function load_exam_scores_data(file_path::String)::DataFrame
  """
  Load examination score data file saved in CSV format. The data is from
  an Optical Mark Recognition (OMR) sheet. Make sure that the data in xls
  format should be converted to CSV format before loading it.
  """

  try
    df = CSV.read(file_path, DataFrame, missingstring="")
    return df 

  catch e
    if isa(e, ArgumentError) && occursin("Symbol name may not contain", e.msg)
        error("Invalid file format. Expected CSV file.")
    elseif isa(e, CSV.Error)
      error("Invalid CSV format: $(e.msg)")
    else
      rethrow(e)
    end
  end
end

function make_questions_colnames_vector(no_questions::Int64)::Vector{Symbol}
  """
  Create a vector of symbols for the questions columns in the transformed
  data frame. The number of questions is used to determine the number of
  columns for questions in the transformed data frame.
  """

  new_questions_colnames = Vector{Symbol}(undef, no_questions)

  for i in 1:no_questions
    if i <= 9
      new_questions_colnames[i] = Symbol("Q00$i")
    elseif i<= 99
      new_questions_colnames[i] = Symbol("Q0$i")
    else
      new_questions_colnames[i] = Symbol("Q$i")
    end
  end

  return new_questions_colnames
end


function transform_omr_data(
  df:: DataFrame, no_questions::Int64, new_questions_colnames::Vector{Symbol}
)::DataFrame
  """
  Transform the OMR data to a more readable format. The transformed data
  frame will have the following columns: No, Grades, IDs, Names, Scores,
  TotalScores, Scores100, Ranks, DataGroups, and the questions columns
  that look line Q001, Q002, etc.
  """ 

  # Select columns for questions
  select!(df, Not(9 + no_questions + 1:size(df, 2)))

  # Prepare column names
  new_parameters_col_names = [:No, :Grades, :IDs, :Names, :Scores, :TotalScores, :Scores100, :Ranks, :DataGroups]
  combined_col_names = vcat(new_parameters_col_names, new_questions_colnames)
  rename!(df, combined_col_names)

  # Remove the first row that contains missing values
  df = df[2:end, :]
  
  return df
end

function replace_missings_from_df(df_transformed::DataFrame)::DataFrame
  """
  Replace missing values in the transformed data frame with the values
  in the previous row. This is done to fill the missing values in the
  transformed data frame.
  """
  for i in 1:3:size(df_transformed, 1)
    if i + 2 <= size(df_transformed, 1)
      for j in i+1:i+2
        for col in 1:8 
          df_transformed[j, col] = df_transformed[i, col]
        end
      end
    end
  end

  return df_transformed
end

function convert_column_types(df_transformed::DataFrame)::DataFrame

  df_transformed.Grades = parse.(Int64, df_transformed.Grades)
  df_transformed.IDs = parse.(Int64, df_transformed.IDs)
  df_transformed.Names = convert.(String, df_transformed.Names)
  df_transformed.DataGroups = convert.(String, df_transformed.DataGroups)

  return df_transformed
end

function remove_unnecessary_columns(df_transformed::DataFrame)::DataFrame
  df_transformed = select!(
    df_transformed, Not(:No, :Scores, :TotalScores, :Scores100, :Ranks)
  )
  return df_transformed
end

function remove_unnecessary_marks(df_transformed::DataFrame)::DataFrame
  for col in names(df_transformed) 
    if  eltype(df_transformed[!, col]) == String
      df_transformed[!, col] = replace.(df_transformed[!, col], "*"=> "")
    end
  end

  return df_transformed
end

function find_missing_rows(col)
    return findall(ismissing, col)
end

function find_missing_rows_dict(df::DataFrame)
    missing_rows = Dict{String, Vector{Int64}}()
    for (col_name, col_data) in zip(names(df), eachcol(df))
        missing_indices = find_missing_rows(col_data)
        if !isempty(missing_indices)
            missing_rows[col_name] = missing_indices
        end
    end

    return missing_rows
end

end
