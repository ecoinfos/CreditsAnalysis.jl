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
  function check_symbol_format(sym::Symbol)
    str = string(sym)
    return occursin(r"^Q\d{3}$", str)
  end

  #test the function of symbol structure check
  test_vec1 = [:Q0001]
  @test all(check_symbol_format, test_vec1) == false
  test_vec2 = [:Q001, :Q0002]
  @test all(check_symbol_format, test_vec2) == false
  test_vec3 = [:Q001, :Q002, :Q003]
  @test all(check_symbol_format, test_vec3) == true

  test_no_q1 = 3 
  test_vec_res1 = LO.make_questions_colnames_vector(test_no_q1)
  @test typeof(test_vec_res1) == Vector{Symbol}
  @test length(test_vec_res1) == 3
  @test all(check_symbol_format, test_vec_res1) == true
  
  test_no_q2 = 10
  test_vec_res2 = LO.make_questions_colnames_vector(test_no_q2)
  @test all(check_symbol_format, test_vec_res2) == true

  test_no_q3 = 1000
  test_vec_res3 = LO.make_questions_colnames_vector(test_no_q3)
  @test all(check_symbol_format, test_vec_res3) == false

  test_no_q4 = 3.1
  @test_throws MethodError LO.make_questions_colnames_vector(test_no_q4)
end

#df = DataFrame(
#  :Grades => Union{Int64, Missing}[1, 1, 1],
#  :IDs => Union{String, Missing}["2020194999", "2020194999", "2020194999"],
#  :Names => Union{String, Missing}["Jone", "Frank", "James"],
#  :DataGroups => Union{String, Missing}["Answer", "Response", "Result"]
#)
#df_converted = LO.convert_column_types(df)

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

