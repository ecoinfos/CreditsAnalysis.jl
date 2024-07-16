using CSV
using DataFrames
using ShiftedArrays
using Test
using Statistics

import CreditsAnalysis.LoadOMR as LO


@testset "CSV data file recognition test" begin
  file_path_correct_csv = "./test/test_csv1.csv"
  expected_df = DataFrame(SN = [1, 2, 3], col1 = [1, 2, 3], col2 = [1, 2, 3])
  @test LO.load_exam_data(file_path_correct_csv) == expected_df

  file_path_xlsx = "./test/test_csv1.xlsx"
  @test_throws ErrorException LO.load_exam_data(file_path_xlsx)

  file_path_wrong_csv = "./test/test_csv1_xlsx.csv"
  @test_throws ErrorException LO.load_exam_data(file_path_wrong_csv)
end

@testset "Questions column titles generation test" begin
  no_questions1 = 10
  test_colnames_vector1 = LO.make_questions_colnames_vector(no_questions1)
  @test typeof(test_colnames_vector1) == Vector{Symbol}
  @test length(test_colnames_vector1) == no_questions1
  symbol_lengths1 = length.(string.(test_colnames_vector1))
  @test std(symbol_lengths1) == 0.0

  no_questions2 = 100
  test_colnames_vector2 = LO.make_questions_colnames_vector(no_questions2)
  @test typeof(test_colnames_vector2) == Vector{Symbol}
  @test length(test_colnames_vector2) == no_questions2
  symbol_lengths2 = length.(string.(test_colnames_vector2))
  @test std(symbol_lengths2) == 0.0
end

# OX into scores
# histogram development
# "results" extraction from the data df
@testset "Extraction from OMR data test" begin
  df = DataFrame(
    SN = 1:6,
    IDs = [2024194998, 2024194998, 2024194998, 2024194999, 2024194999, 2024194999],
    Names = ["John", "John", "John", "Jane", "Jane", "Jane"],
    DataGroups = ["ANS", "SANS", "RES", "ANS", "SANS", "RES"],
    Q1 = ["1", "1", "O", "2", "1", "X"],
    Q2 = ["1", "1", "O", "2", "2", "O"]
  )

  df_res = LO.collect_results(df, "RES")
  df_length = length(df[!, 1])
  @test length(df_res[!, 1]) == Int(df_length / 3)
  @test unique(df_res.DataGroups) == ["RES"]
  @test unique(df_res.Q1) == ["O", "X"]
end

@testset "OX to scores conversion test" begin
  df1 = DataFrame(
    SN = 1:2,
    IDs = [2024194998, 2024194999],
    Names = ["John", "Jane"],
    DataGroups = ["RES", "RES"],
    Q1 = ["O", "X"],
    Q2 = ["O", "O"]
  )
  df1_res = LO.convert_ox_to_scores!(df1, "Q", Dict("O"=>5, "X"=>0))
  @test eltype(df1_res.Q1) == Int64
  @test eltype(df1_res.Q2) == Int64
  @test unique(df1_res.Q1) == [5, 0]

  df2 = DataFrame(
    SN = 1:2,
    IDs = [2024194998, 2024194998],
    Names = ["John", "Jane"],
    DataGroups = ["RES", "RES"],
    Q1 = ["O", "X"],
    Q2 = ["O", "O"]
  )
  @test_throws ErrorException LO.convert_ox_to_scores!(
    df2, "Q", Dict("O"=>5, "X"=>0)
  )
end
