module SubjectAchievement

using DataFrames
using CSV
using CairoMakie
using Statistics

export join_scores_with_subjects, calculate_subject_avgs,
       calculate_student_avgs, plot_achievement_radar


function join_scores_with_subjects(
  df_questions::DataFrame, df_anp_res::DataFrame, target_col::Symbol
)::DataFrame
  df_questions_selected = select(df_questions, :QuestionIDs, target_col)
  question_cols = names(df_anp_res, r"Q\d+")
  df_anp_res_long = stack(
    df_anp_res, question_cols, variable_name="QuestionIDs", value_name="Score"
  )
  df_joined = innerjoin(
    df_anp_res_long, df_questions_selected, on=:QuestionIDs
  )

  return df_joined
end

# Studuent Achievement Analysis (SAA)
# SAA 1. Analysis of achievement on subjects

function calculate_total_subject_avgs(df_joined::DataFrame)::DataFrame
  df_avg_scores_per_question = combine(
    groupby(df_joined, [:Subjects, :QuestionIDs]), :Score => mean => :AvgScore
  )
  df_avg_scores_per_subject = combine(
    groupby(
      df_avg_scores_per_question, :Subjects
    ), :AvgScore => mean => :AvgScore
  )

  return df_avg_scores_per_subject
end

function calculate_student_subject_avgs(df_joined::DataFrame)::DataFrame
  df_avg_scores_per_student = combine(
    groupby(df_joined, [:IDs, :Names, :Subjects]), :Score => mean => :AvgScore
  )
  df_avg_scores_per_student = sort(df_avg_scores_per_student, :IDs)

  return df_avg_scores_per_student
end

function plot_achievement_radar(
  df_avg_scores_per_subject::DataFrame,
  df_avg_scores_per_student::DataFrame,
  student_id::Int64
)
  # Calculate total average per subject 
  subjects_all = df_avg_scores_per_subject.Subjects
  avg_scores_all = df_avg_scores_per_subject.AvgScore

  student_data = filter(
    row -> row.IDs == student_id, df_avg_scores_per_student
  )
  subjects_student = student_data.Subjects
  avg_scores_student = student_data.AvgScore

  fig = Figure(size=(800, 400))
  ax = PolarAxis(
    fig[1, 1],
    title="핵심주제별 평균 비교: 전체 평균 vs. 학생 $student_id",
    titlegap=30,
    
    # Theta ticks setting / thetatick length=ticks+1 
    theta_0 = -pi/2,
    direction = -1,
    thetaticks = (range(0, 2pi, length=8)[1:end-1],subjects_all),
    thetaticklabelsize=13,
    
    # Radius ticks setting
    rticks=0:1:5,
    rticklabelsize=10,
    rticklabelcolor=:gray,

    # Grid lines setting
    rgridcolor=:gray,
    thetagridcolor=:gray
  )
  rlims!(ax, 0.0, 5.3)

  line1 = lines!(
    ax,
    range(0, 2π, length=length(subjects_all)+1),
    vcat(avg_scores_all, avg_scores_all[1]),
    color=:blue,
    linewidth=2,
    label="전체 평균"
  )
  line2 = lines!(
    ax,
    range(0, 2π, length=length(subjects_student)+1),
    vcat(avg_scores_student, avg_scores_student[1]),
    color=:red,
    linewidth=2,
    label="$student_id 학생 평균"
  )

  Legend(
    fig[1,2],
    [line1, line2],
    ["전체 평균", "$student_id 학생 평균"],
    labelsize=7,
    backgroundcolor=(:white, 0.8)
  ) 
  fig

end


end
