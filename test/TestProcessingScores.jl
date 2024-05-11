using DataFrames
using Test

import CreditsAnalysis.ProcessingScores as PS


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

  df_res = PS.collect_results(df)
  df_length = length(df[!, 1])
  @test length(df_res[!, 1]) == Int(df_length / 3)
  @test unique(df_res.DataGroups) == ["RES"]
  @test unique(df_res.Q1) == ["O", "X"]
end

@testset "Count correct answers test" begin
  df1 = DataFrame(
    SN = 1:2,
    IDs = [2024194998, 2024194999],
    Names = ["John", "Jane"],
    DataGroups = ["RES", "RES"],
    Q1 = ["O", "X"],
    Q2 = ["O", "O"]
  )
  PS.count_correct_responses(df1)
  
end

