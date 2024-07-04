module LoadQuiz

using CreditsAnalysis
using DataFrames
using CSV
using Dates

export read_csv_to_dataframe, read_multiple_csvs_to_dataframes, 
       column_titles_comparison, vcat_quiz_data, modify_quiz_df_col_titles,
       convert_to_datetime, read_multiple_access_csvs_to_dict

# 1. Load and transform quiz score data

function read_csv_to_dataframe(file_path::String)::DataFrame
  """
  Reads a CSV file and returns a DataFrame. If the file extension is not .csv,
  an error is thrown.

  ```julia
  test_csv1 = "test/test_csv1.csv"
  read_csv_to_dataframe(test_csv1)
  ```
  3×3 DataFrame
    Row │ SN     col1   col2
        │ Int64  Int64  Int64
  ──────┼─────────────────────
      1 │     1      1      1
      2 │     2      2      2
      3 │     3      3      3 
  """

  file_extension = splitext(file_path)[2]
  if lowercase(file_extension) != ".csv"
    error("Invalid file format. Expected CSV file, got $file_extension")
  end

  df = CSV.File(file_path, missingstring="", pool=false) |> DataFrame

  for col in names(df) 
    df[!, col] = coalesce.(df[!, col], missing, "")
  end

  return df
end

function read_multiple_csvs_to_dataframes(
  score_data_paths::Vector{String}
)::Dict{Symbol, DataFrame}

  """
  Reads multiple CSV files and returns a dictionary of DataFrames. The keys
  are generated as dfA, dfB, dfC, etc. The function throws an error if any of
  the CSV files are identical.

  ```julia
  test_data_paths=["test/test_csv1.csv", "test/test_csv2.csv"]
  df_dict = LS.read_multiple_csvs_to_dataframes(test_data_paths)
  ```
  Dict{Symbol, DataFrame} with 2 entries:
    :dfA => 3×3 DataFrame…
    :dfB => 3×3 DataFrame…
  """

  num_dfs = length(score_data_paths)
  df_dict = Dict{Symbol, DataFrame}()

  for i in 1:num_dfs
    df_name = Symbol("df" * Char(64 + i))
    new_df = read_csv_to_dataframe(score_data_paths[i])

    for (key, existing_df) in df_dict
      if isequal(new_df,existing_df)
        error(
          "Duplicate dataframe found: CSV file number $i is the same as $key."
        )
    end
  end

    df_dict[df_name] = new_df
  end

  return df_dict
end

# dataframe structure test

function column_titles_comparison(df_dict::Dict{Symbol, DataFrame})
  dfA_colnames = names(df_dict[:dfA])
  for key in sort(collect(keys(df_dict)))[2:end]
    df_colnames = names(df_dict[key])
    if names(df_dict[key]) != dfA_colnames
      diff_indices = findall(df_colnames .!= dfA_colnames)
      for i in diff_indices 
        @info "- $key column $i: $(df_colnames[i]) (dfA column $i: $(dfA_colnames[i]))"
      end
      error("Column titles of $key are different from dfA's column titles.")
    else
      @info "Column titles of $key are same to dfA's column titles."
    end
  end
end

function vcat_quiz_data(df_dict::Dict{Symbol, DataFrame})::DataFrame
  """
  Merges multiple DataFrames into a single DataFrame.
  ```julia
  df_dict = Dict(:dfA => dfA, :dfB => dfB)
  df_quiz_vcat = vcat_quiz_data(df_dict)
  ```
  """
  df_quiz_vcat = DataFrame()
  df_names = sort(collect(keys(df_dict)))
  for df_name in df_names 
    df = df_dict[df_name] 
    if isempty(df_quiz_vcat)
      df_quiz_vcat = df
    else
      df_quiz_vcat = vcat(df_quiz_vcat, df)
    end
  end

  return df_quiz_vcat
end

function modify_quiz_df_col_titles(df_quiz_vcat::DataFrame)::DataFrame
  new_col_titles = [
    :No,
    :Weeks,
    :Sessions,
    :Depts,
    :Classes,
    :Names,
    :IDs,
    :Qtypes,
    :Questions,
    :Answers,
    :Responses,
    :Correctness,
    :Scores,
    :Qstart_t, 
    :Qend_t,
    :Time
  ]
  df_quiz_vcat = rename(df_quiz_vcat, new_col_titles)
  df_quiz_vcat = select(df_quiz_vcat, Not(:Depts, :Qtypes))
  df_quiz_vcat.Classes = convert.(String, df_quiz_vcat.Classes)
  df_quiz_vcat.Names = convert.(String, df_quiz_vcat.Names)
  #df_quiz_merge.Answers = convert.(String, df_merge.Answers)
  #df_quiz_merge.Responses = convert.(String, df_merge.Responses)
  df_quiz_vcat.Correctness = convert.(String, df_quiz_vcat.Correctness)
  df_quiz_vcat.Qstart_t = convert.(String, df_quiz_vcat.Qstart_t)
  df_quiz_vcat.Qend_t = convert.(String, df_quiz_vcat.Qend_t)
  
  return df_quiz_vcat
end

function convert_to_datetime(str::String)
  if isempty(str)
    return missing
  end
  
  replaced_str = replace(str, "오전" => "AM", "오후" => "PM")
  replaced_str = replace(replaced_str, r"(AM|PM) (\d{1,2}:\d{2}:\d{2})" => s"\2 \1")
  return DateTime(replaced_str, dateformat"yyyy-mm-dd HH:MM:SS p")
end

# 2. Load and transform quiz access data
function read_multiple_access_csvs_to_dict(
  access_data_paths::Vector{String},
  class::String,
  start_week::Int64,
)::Dict{Symbol, DataFrame}

  num_dfs = length(access_data_paths)
  df_dict = Dict{Symbol, DataFrame}()

  for i in 1:num_dfs
    df_name = Symbol("df_" * class * "W" * string(start_week + i - 1))
    new_df = read_csv_to_dataframe(access_data_paths[i])

    for (key, existing_df) in df_dict 
      if isequal(existing_df, new_df)
        error("Duplicate dataframe found")
      end
    end
    
    df_dict[df_name] = new_df 
  end

  return df_dict
end

function modify_quiz_access_df_col_titles(df_quiz_vcat::DataFrame)::DataFrame
  new_col_titles = [
    :No,
    :Classes,
    :Weeks,
    :Depts,
    :Names,
    :IDs,
    :Access_t,
    :Compeleted_t,
    :Duration,
    :Status,
    :Scores
  ]
  df_quiz_vcat = rename(df_quiz_vcat, new_col_titles)
  df_quiz_vcat = select(df_quiz_vcat, Not(:Depts, :Qtypes))
  df_quiz_vcat.Classes = convert.(String, df_quiz_vcat.Classes)
  df_quiz_vcat.Names = convert.(String, df_quiz_vcat.Names)
  #df_quiz_merge.Answers = convert.(String, df_merge.Answers)
  #df_quiz_merge.Responses = convert.(String, df_merge.Responses)
  df_quiz_vcat.Correctness = convert.(String, df_quiz_vcat.Correctness)
  df_quiz_vcat.Qstart_t = convert.(String, df_quiz_vcat.Qstart_t)
  df_quiz_vcat.Qend_t = convert.(String, df_quiz_vcat.Qend_t)
  
  return df_quiz_vcat
end

end
