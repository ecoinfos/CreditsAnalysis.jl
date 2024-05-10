using CSV
using DataFrames
using ShiftedArrays
using Test
using Statistics

import CreditsAnalysis.ExamScoresTransformer as EST


@testset "CSV data file recognition test" begin
  file_path_correct_csv = joinpath(@__DIR__, "test/test_csv1.csv")
  expected_df = DataFrame(SN = [1, 2, 3], col1 = [1, 2, 3], col2 = [1, 2, 3])
  @test EST.load_exam_scores_data(file_path_correct_csv) == expected_df

  file_path_xlsx = joinpath(@__DIR__, "test/test_csv1.xlsx")
  @test_throws ErrorException EST.load_exam_scores_data(file_path_xlsx)

  file_path_wrong_csv = joinpath(@__DIR__, "test/test_csv1_xlsx.csv") 
  @test_throws ErrorException EST.load_exam_scores_data(file_path_wrong_csv)
end

@testset "Questions column titles generation test" begin
  no_questions1 = 10
  test_colnames_vector1 = EST.make_questions_colnames_vector(no_questions1)
  @test typeof(test_colnames_vector1) == Vector{Symbol}
  @test length(test_colnames_vector1) == no_questions1
  symbol_lengths1 = length.(string.(test_colnames_vector1))
  @test std(symbol_lengths1) == 0.0

  no_questions2 = 100
  test_colnames_vector2 = EST.make_questions_colnames_vector(no_questions2)
  @test typeof(test_colnames_vector2) == Vector{Symbol}
  @test length(test_colnames_vector2) == no_questions2
  symbol_lengths2 = length.(string.(test_colnames_vector2))
  @test std(symbol_lengths2) == 0.0
end





df_res = df_1[occursin.("결과", df_1[:, :DataGroups]), :]

for col in names(df_res, r"^Q\d+$")
    unique_values = unique(df_res[!, col])
    if !issubset(unique_values, ["O", "X"])
        println("Column $col contains values other than 'O' and 'X': $unique_values")
    end
end


df_res_copy = copy(df_res)

for col in names(df_res_copy, r"^Q\d+$")
    df_res_copy[!, col] = map(x -> x == "O" ? 5 : x == "X" ? 0 : missing, df_res_copy[!, col])
end

df_res_copy

# 데이터프레임 df_res_copy가 있다고 가정

# 열 이름을 지정하여 데이터 타입 확인
col_name = :Q01  # 확인하고자 하는 열 이름
unique_types = unique(typeof.(df_res_copy[!, col_name]))
println("Data types in column $col_name: $unique_types")

# 모든 열에 대해 데이터 타입 확인
for col_name in names(df_res_copy)
    unique_types = unique(typeof.(df_res_copy[!, col_name]))
    println("Data types in column $col_name: $unique_types")
end
