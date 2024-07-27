using DataFrames
using Test

import CreditsAnalysis.TopicStats as TS

@testset "concatenate two exam dataframes test" begin
  df_midterm = DataFrame(
    IDs = [1, 2], QuestionIDs = ["Q001", "Q001"], res = [0, 5]
  )
  df_final = DataFrame(
    IDs = [1, 2], QuestionIDs = ["Q001", "Q001"], res = [5, 5]
  )
  mod_col_midterm = :QuestionIDs
  mod_col_final = :QuestionIDs
  prefix_midterm = "M_"
  prefix_final = "F_"
  
  df_total1 = TS.create_total_exam_df_by_subject(
    df_midterm, df_final, mod_col_midterm, mod_col_final,
    prefix_midterm, prefix_final
  )
  
  df_total_expected1 = DataFrame(
    IDs = [1, 2, 1, 2],
    QuestionIDs = ["M_Q001", "M_Q001", "F_Q001", "F_Q001"],
    res = [0, 5, 5, 5]
  )
  @test df_total1 == df_total_expected1
  
  df_midterm[2, 2] = "001"
  df_total2 = TS.create_total_exam_df_by_subject(
    df_midterm, df_final, mod_col_midterm, mod_col_final,
    prefix_midterm, prefix_final
  )
  df_total_expected2 = DataFrame(
    IDs = [1, 2, 1, 2],
    QuestionIDs = ["M_Q001", "M_001", "F_Q001", "F_Q001"],
    res = [0, 5, 5, 5]
  )
  @test df_total2 == df_total_expected2

  df_midterm.QuestionIDs = Vector{Union{String, Int64}}(df_midterm.QuestionIDs)
  df_midterm[2, 2] = 001 
  @test_throws MethodError df_total3 = TS.create_total_exam_df_by_subject(
    df_midterm, df_final, mod_col_midterm, mod_col_final,
    prefix_midterm, prefix_final
  )
end
