using CSV
using DataFrames
using ShiftedArrays
using Test
using Statistics

import CreditsAnalysis.OMRDataTransformer as ODT


@testset "CSV data file recognition test" begin
  file_path_correct_csv = joinpath(@__DIR__, "test_csv1.csv")
  expected_df = DataFrame(SN = [1, 2, 3], col1 = [1, 2, 3], col2 = [1, 2, 3])
  @test ODT.load_exam_data(file_path_correct_csv) == expected_df

  file_path_xlsx = joinpath(@__DIR__, "test_csv1.xlsx")
  @test_throws ErrorException ODT.load_exam_data(file_path_xlsx)

  file_path_wrong_csv = joinpath(@__DIR__, "test_csv1_xlsx.csv") 
  @test_throws ErrorException ODT.load_exam_data(file_path_wrong_csv)
end

@testset "Questions column titles generation test" begin
  no_questions1 = 10
  test_colnames_vector1 = ODT.make_questions_colnames_vector(no_questions1)
  @test typeof(test_colnames_vector1) == Vector{Symbol}
  @test length(test_colnames_vector1) == no_questions1
  symbol_lengths1 = length.(string.(test_colnames_vector1))
  @test std(symbol_lengths1) == 0.0

  no_questions2 = 100
  test_colnames_vector2 = ODT.make_questions_colnames_vector(no_questions2)
  @test typeof(test_colnames_vector2) == Vector{Symbol}
  @test length(test_colnames_vector2) == no_questions2
  symbol_lengths2 = length.(string.(test_colnames_vector2))
  @test std(symbol_lengths2) == 0.0
end
