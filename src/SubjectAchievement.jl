module SubjectAchievement

using DataFrames
using CSV
using CairoMakie
using Statistics

export join_scores_with_subjects, calculate_total_subject_avgs,
       calculate_student_subject_avgs, plot_achievement_radar,
       calculate_total_origin_avg, calculate_total_origin_std,
       calculate_student_origin_avg, calculate_student_origin_std,
       plot_origination_bar_graph



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

# SAA 2. Analysis of achievement on question origins

function calculate_total_origin_avg(
  df_joined::DataFrame
)::Tuple{Float64, Float64} 
  orig_rows = df_joined.Origin .== "오리지널"
  quiz_rows = df_joined.Origin .== "퀴즈"

  orig_avg = mean((df_joined[orig_rows, :Score]))
  quiz_avg = mean((df_joined[quiz_rows, :Score]))
  
  return orig_avg, quiz_avg
end

function calculate_total_origin_std(
    df_joined::DataFrame
)::Tuple{Float64, Float64}
  orig_rows = df_joined.Origin .== "오리지널"
  quiz_rows = df_joined.Origin .== "퀴즈"
  
  orig_std = std(df_joined[orig_rows, :Score])
  quiz_std = std(df_joined[quiz_rows, :Score])
  
  return orig_std, quiz_std
end

function calculate_student_origin_avg(
    df_joined::DataFrame,
    student_id::Int64
)::Tuple{Float64, Float64}
  student_rows = df_joined.IDs .== student_id
  
  orig_rows = student_rows .& (df_joined.Origin .== "오리지널")
  quiz_rows = student_rows .& (df_joined.Origin .== "퀴즈")
  
  student_orig_avg = mean(df_joined[orig_rows, :Score])
  student_quiz_avg = mean(df_joined[quiz_rows, :Score])
  
  return student_orig_avg, student_quiz_avg
end

function calculate_student_origin_std(
    df_joined::DataFrame,
    student_id::Int64
)::Tuple{Float64, Float64}
  student_rows = df_joined.IDs .== student_id
  
  orig_rows = student_rows .& (df_joined.Origin .== "오리지널")
  quiz_rows = student_rows .& (df_joined.Origin .== "퀴즈")
  
  student_orig_std = std(df_joined[orig_rows, :Score])
  student_quiz_std = std(df_joined[quiz_rows, :Score])
  
  return student_orig_std, student_quiz_std
end

function plot_origination_bar_graph(data_dict::Dict{String, Real})
    categories = ["오리지널", "퀴즈"]
    bar_labels = ["전체 평균", "학생 평균"]

    fig = Figure(size = (600, 400))
    ax = Axis(fig[1, 1], ylabel = "점수", xticks = (1:2, categories))

    # Create total average bars
    bars1 = barplot!(
        ax,
        1 .+ [-0.2, 0.2],
        [data_dict["orig_avg"], data_dict["quiz_avg"]],
        width = 0.35
    )
    errorbars!(
        ax,
        1 .+ [-0.2, 0.2],
        [data_dict["orig_avg"], data_dict["quiz_avg"]],
        [data_dict["orig_std"], data_dict["quiz_std"]],
        whiskerwidth = 10
    )

    # Create student average bars
    bars2 = barplot!(
        ax,
        2 .+ [-0.2, 0.2],
        [data_dict["student_orig_avg"], data_dict["student_quiz_avg"]],
        width = 0.35
    )
    errorbars!(
        ax,
        2 .+ [-0.2, 0.2],
        [data_dict["student_orig_avg"], data_dict["student_quiz_avg"]],
        [data_dict["student_orig_std"], data_dict["student_quiz_std"]],
        whiskerwidth = 10
    )

    # Convert bars to iterable objects
    bars1_iterable = [bars1[i] for i in 1:length(bars1)]
    bars2_iterable = [bars2[i] for i in 1:length(bars2)]

    # Add labels
    for (bar, label) in zip(bars1_iterable, bar_labels)
        text!(
            ax,
            "$(label)",
            position = (bar.x[], bar.y[] + bar.height[] + 0.1),
            align = (:center, :bottom),
            textsize = 10
        )
    end
    for (bar, label) in zip(bars2_iterable, bar_labels)
        text!(
            ax,
            "$(label)",
            position = (bar.x[], bar.y[] + bar.height[] + 0.1),
            align = (:center, :bottom),
            textsize = 10
        )
    end

    ax.xticks = (1:2, categories)
    ax.xticksize = 10
    ax.yticksize = 10

    fig[1, 2] = Legend(fig, ax, "평균", framevisible = false)

    return fig
end






end
