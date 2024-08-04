module LoadOMR

using CSV
using DataFrames
using ShiftedArrays

export load_exam_data, make_questions_colnames_vector,
       transform_omr_data, replace_missings_from_df, convert_column_types,
       remove_unnecessary_columns, remove_unnecessary_marks,
       find_missing_rows_dict, collect_results, convert_ox_to_scores!,
       calculate_score_sums, rename_exam_df_col_titles

# 1. Load OMR data from csvs and prepare data dictionary

function load_exam_data(file_path::String)::DataFrame
  """
  Load examination score data file saved in CSV format. The data is from
  an Optical Mark Recognition (OMR) sheet. Make sure that the data in xls
  format should be converted to CSV format before loading it.

  ```julia
  file_path_correct_csv = "./test/test_csv1.csv"
  load_exam_data(file_path_correct_csv)
  ```
  3×3 DataFrame
  Row │ SN     col1   col2
      │ Int64  Int64  Int64
  ────┼─────────────────────
    1 │     1      1      1
    2 │     2      2      2
    3 │     3      3      3
  """

  df = DataFrame()
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

  ```julia
  no_questions = 3 
  make_questions_colnames_vector(no_questions)
  ```
  3-element Vector{Symbol}:
  :Q001
  :Q002
  :Q003
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
  
  For example, the resulting DataFrame looks like:
  Row | No      Grades    IDs        ...  DataGroups  Q001    Q002    Q003
      | Int64?  String7?  String15?       String7?    String1 String1 String1
  ────┼──────────────────────────────────────────────────────────────────────
    1 |       1 1         20200001   ...  정답        2       5       3 
    2 | missing missing   20200001   ...  표기        2       5       1
    3 | missing missing   20200001   ...  결과        O       O       X 
    4 | ...
  """ 

  df_sel = select!(df, Not(9 + no_questions + 1:size(df, 2)))

  # Prepare column names
  new_parameters_col_names = [
    :No,
    :Grades,
    :IDs,
    :Names,
    :Scores,
    :TotalScores,
    :Scores100,
    :Ranks,
    :DataGroups
  ]
  combined_col_names = vcat(new_parameters_col_names, new_questions_colnames)
  rename!(df_sel, combined_col_names)

  # Remove the first row that contains missing values
  df_sel = df_sel[2:end, :]
  
  return df_sel
end

function replace_missings_from_df(df_transformed::DataFrame)::DataFrame
  """
  Replace missing values in the transformed data frame with the values
  in the previous row. This is done to fill the missing values in the
  transformed data frame.

  For example, the resulting DataFrame looks like:
  Row | No      Grades    IDs        ...  DataGroups  Q001    Q002    Q003
      | Int64?  String7?  String15?       String7?    String1 String1 String1
  ────┼──────────────────────────────────────────────────────────────────────
    1 |       1 1         20200001   ...  정답        2       5       3 
    2 |       1 1         20200001   ...  표기        2       5       1
    3 |       1 1         20200001   ...  결과        O       O       X 
    4 | ...

  Please compare this resulting DataFrame with the docstring example
  DataFrame in the function `transform_omr_data`.
  """

  df_copy = deepcopy(df_transformed)
  cols_with_missing = findall(col -> any(ismissing, col), eachcol(df_copy))
  for i in 1:3:size(df_copy, 1)
    if i + 2 <= size(df_copy, 1)
      for j in i+1:i+2
        for col in cols_with_missing 
          if  ismissing(df_copy[j, col])
            df_copy[j, col] = df_copy[i, col]
          end
        end
      end
    end
  end

  return df_copy
end

function convert_column_types(df_transformed::DataFrame)::DataFrame
  """
  Convert the data types of the columns in the transformed data frame to
  the appropriate types. The Grades and IDs columns are converted to Int64
  while the Names and DataGroups columns are converted to String.
  """

  df_transformed.Grades = parse.(Int64, df_transformed.Grades)
  df_transformed.IDs = parse.(Int64, df_transformed.IDs)
  for id in df_transformed[!, :IDs] 
    if ndigits(id) != 8
      error("ID $id is too short") 
    end
  end
  df_transformed.Names = convert.(String, df_transformed.Names)
  df_transformed.DataGroups = convert.(String, df_transformed.DataGroups)

  return df_transformed
end

function remove_unnecessary_columns(df_transformed::DataFrame)::DataFrame
  """
  Remove unnecessary columns from the transformed data frame. The columns
  removed are: No, Scores, TotalScores, Scores100, and Ranks.
  """

  df_transformed = select!(
    df_transformed, Not(:No, :Scores, :TotalScores, :Scores100, :Ranks)
  )
  return df_transformed
end

function remove_unnecessary_marks(df_transformed::DataFrame)::DataFrame
  """
  Remove unnecessary marks from the transformed data frame. The marks
  removed are: * from the Names column.
  """

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
  """
  Find missing values in the data frame and return a dictionary of column
  names and the row indices of the missing values in the respective columns.
  """

  missing_rows = Dict{String, Vector{Int64}}()
  for (col_name, col_data) in zip(names(df), eachcol(df))
    missing_indices = find_missing_rows(col_data)
    if !isempty(missing_indices)
      missing_rows[col_name] = missing_indices
    end
  end

  return missing_rows
end


# 2. Calculate scores from OMR data

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
  converted to Int64 types. 
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
  """
  Calculate the sum of all columns in the DataFrame that start with the
  specified prefix. The resulting sum is stored in a new column called
  `ScoreSums`.
  """
  cols = filter(col -> startswith(col, col_prefix), names(df)) 
  df[!, :ScoreSums] = sum(eachcol(df[!, cols]))

  return df
end


end
