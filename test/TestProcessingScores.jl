using DataFrames
using Test

import CreditsAnalysis.LoadOMR as LO


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

