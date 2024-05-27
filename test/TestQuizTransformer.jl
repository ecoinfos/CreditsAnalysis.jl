using CreditsAnalysis
using CSV
using DataFrames
using Test

import CreditsAnalysis.QuizTransformer as QT 


@testset "CSV file loading test" begin
  test_csv1 = "test/test_csv1.csv"
  #test_csv1 = joinpath(@__DIR__, "test_csv1.csv")
  expected_df_from_csv = DataFrame(SN=[1, 2, 3], col1 = [1, 2, 3], col2 = [1, 2, 3])
  @test QT.read_csv_to_dataframe(test_csv1) == expected_df_from_csv

  test_csv2 = joinpath(@__DIR__, "test_csv1.xlsx")
  @test_throws ErrorException QT.read_csv_to_dataframe(test_csv2)



  for col in names(df) 
    any(ismissing, df[!, col]) && println(col)
  end
end

@testset "multiple CSVs loading test" begin
  test_data_paths1=[
    "test/test_csv1.csv"
    "test/test_csv2.csv"
    #joinpath(@__DIR__, "test_csv1.csv"),
    #joinpath(@__DIR__, "test_csv2.csv")
  ]
  df_dict1 = QT.read_multiple_csvs_to_dataframes(test_data_paths1)
  expected_test_dfA = DataFrame(SN = 1:3, col1 = [1, 2, 3], col2 = [1, 2, 3])
  expected_test_dfB = DataFrame(SN = 1:3, col1 = [4, 5, 6], col2 = [4, 5, 6])
  @test df_dict1[:dfA] == expected_test_dfA
  @test df_dict1[:dfB] == expected_test_dfB

  test_data_paths2=[
    joinpath(@__DIR__, "test_csv1.csv"), 
    joinpath(@__DIR__, "test_csv2.csv"),
    joinpath(@__DIR__, "test_csv1_duplicated.csv")
  ]
  @test_throws ArgumentError QT.read_multiple_csvs_to_dataframes(test_data_paths2)
end

@testset "DataFrames column titles comparison test" begin
  test_dfA1 = DataFrame(SN = 1:2, col1 = [1, 1], col2 = [2, 2])
  test_dfB1 = DataFrame(SN = 1:2, col1 = [3, 3], col2 = [4, 4])
  test_dfC1 = DataFrame(SN = 1:2, col1 = [5, 6], col2 = [5, 6])

  df_dict1 = Dict("dfA" => test_dfA1, "dfB" => test_dfB1, "dfC" => test_dfC1)
  @test_logs (:info, "Column titles of dfB are same to dfA's column titles.") (:info, "Column titles of dfC are same to dfA's column titles.") QT.column_titles_comparison(df_dict1)

  test_dfA2 = DataFrame(SN = 1:2, col1 = [1, 1], col2 = [2, 2])
  test_dfB2 = DataFrame(SN = 1:2, col1 = [3, 3], col2 = [4, 4])
  test_dfC2 = DataFrame(SN = 1:2, col2 = [5, 6], col3 = [5, 6])

  df_dict2 = Dict("dfA" => test_dfA2, "dfB" => test_dfB2, "dfC" => test_dfC2)
  @test_throws ErrorException QT.column_titles_comparison(df_dict2)
end

@testset "Merge dataframes test" begin
  df_lengths = []
    for df_name in df_names 
      df_length = size(df_dict_quiz[df_name], 1)
      push!(df_lengths, df_length)
    end
  size(df_quiz_merge,1) == sum(df_lengths)
end
