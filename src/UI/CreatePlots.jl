module CreatePlots

using DataFrames
using CairoMakie
 
export plot_achievement_radar, plot_origin_accuracy, plot_weekly_quiz_score,
       plot_weekly_quiz_question_time, plot_quiz_access_time,
       plot_quiz_duration

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

  num_subjects = length(unique(subjects_all))

  fig = Figure(size=(800, 400))
  ax = PolarAxis(
    fig[1, 1],
    title="핵심주제별 평균 비교: 전체 평균 vs. 학생 $student_id",
    titlegap=30,
    
    # Theta ticks setting / thetatick length=ticks+1 
    theta_0 = -pi/2,
    direction = -1,
    thetaticks = (range(0, 2pi, length=num_subjects+1)[1:end-1],subjects_all),
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
    labelsize=10,
    backgroundcolor=(:white, 0.8)
  ) 
  fig

end

function plot_origin_accuracy(accuracy_dict::Dict{String, Float64}, student_id::Int64)
    categories = ["original", "quiz", "formative", "lecture_clip"]
    bar_labels = ["Total", "$student_id"]
    
    # Create table-like data structure
    tbl = (
        cat = [1, 1, 2, 2, 3, 3, 4, 4],  # 1-4까지 각 카테고리마다 2개씩 (Total, student)
        height = [
            get(accuracy_dict, "total_orig_accuracy", NaN),
            get(accuracy_dict, "student_orig_accuracy", NaN),
            get(accuracy_dict, "total_quiz_accuracy", NaN),
            get(accuracy_dict, "student_quiz_accuracy", NaN),
            get(accuracy_dict, "total_formative_accuracy", NaN),  # 수정: assessment -> formative
            get(accuracy_dict, "student_formative_accuracy", NaN), # 수정: assessment -> formative
            get(accuracy_dict, "total_lecture_clip_accuracy", NaN),     # 수정: lecture -> lecture_clip
            get(accuracy_dict, "student_lecture_clip_accuracy", NaN)    # 수정: lecture -> lecture_clip
        ],
        grp = [1, 2, 1, 2, 1, 2, 1, 2]  # 각 카테고리별로 1(Total)과 2(student) 그룹 지정
    )
    
    # NaN 값 대신 0 표시 (선택적)
    tbl = (
        cat = tbl.cat,
        height = [isnan(h) ? 0.0 : h for h in tbl.height],
        grp = tbl.grp
    )
    
    fig = Figure(size = (800, 400))  # 더 많은 카테고리를 표시하기 위해 너비 증가
    ax = Axis(
        fig[1, 1],
        ylabel = "Accuracy (%)",
        xticks = (1:4, categories),  # 4개 카테고리로 수정
        limits = ((0.5, 4.5), (0, 100)),  # x축 범위를 4개 카테고리에 맞게 조정
        yticksvisible = true,
        yticks = 0:20:100,
    )
    
    # Define colors for each group
    colors = [:dodgerblue, :crimson]
    
    # Plot bars with dodge
    barplot!(ax, tbl.cat, tbl.height, dodge = tbl.grp, color = colors[tbl.grp])
    
    # Create legend
    elements = [PolyElement(polycolor = colors[i]) for i in 1:length(bar_labels)]
    legend = Legend(fig[1, 2], elements, bar_labels, labelsize=10)
    
    return fig
end

function plot_weekly_quiz_score(df_quiz_weekly::DataFrame, student_id::Int64)
  df_weekly_score_sums = combine(
    groupby(df_quiz_weekly, [:Weeks, :IDs]), :Scores => sum => :WeeklyScores
  )
  student_df = filter(row -> row.IDs == student_id, df_weekly_score_sums)

  student_df = sort(student_df, :Weeks)

  fig = Figure(size = (800, 400))
  ax = Axis(
    fig[1, 1],
    limits = (0.5, maximum(student_df.Weeks)+0.5, 0, 105),
    xlabel = "Weeks",
    yticks = 0:20:105,
    yminorticksvisible = true,
    yminorticks = IntervalsBetween(9),
    yminorgridvisible = true,
    yminorgridstyle = :dot,
    yminorgridcolor = :gray90
  )

  box = boxplot!(
    ax,
    df_weekly_score_sums.Weeks,
    df_weekly_score_sums.WeeklyScores,
    whiskerwidth = 0.3,
    width = 0.7,
    color = :lightgray,
    show_median = true,
    range = 3,
    label = "All students"
  )
  line = lines!(ax, student_df.Weeks, student_df.WeeklyScores, color = :red)
  scatter!(
    ax, student_df.Weeks, student_df.WeeklyScores, markersize=8, color = :red
  )

  Legend(
    fig[1, 2],
    [box, line],
    ["Total students", "Student ID: $student_id"],
    labelsize = 10,
    backgroundcolor=(:white, 0.8)
  )

  return fig
end

function plot_weekly_quiz_question_time(
  dict_quiz_purposes::Dict, student_id::Int64
)
  dict_quiz_purposes["ua"] = sort(dict_quiz_purposes["ua"], :Weeks)
  dict_quiz_purposes["aa"] = sort(dict_quiz_purposes["aa"], :Weeks)
  dict_quiz_purposes["us"] = sort(dict_quiz_purposes["us"], :Weeks)
  dict_quiz_purposes["as"] = sort(dict_quiz_purposes["as"], :Weeks)

  fig = Figure(size = (800, 600))
  ax1 = Axis(
    fig[1, 1],
    xlabel = "Weeks",
    xticks = 0:1:maximum(dict_quiz_purposes["ua"].Weeks),
    ylabel = "Average time (sec)",
    yticks = 0:60:ceil(maximum(dict_quiz_purposes["ua"].AvgTime)/60)*60,
    yminorticksvisible = true,
    yminorticks = IntervalsBetween(6),
    yminorgridvisible = true,
    yminorgridstyle = :dot,
    yminorgridcolor = :gray90,
    title = "Purpose: understanding"
  )

  ax2 = Axis(
    fig[2, 1],
    xlabel = "Weeks",
    xticks = 0:1:maximum(dict_quiz_purposes["aa"].Weeks),
    ylabel = "Average time (sec)",
    yticks = 0:60:ceil(maximum(dict_quiz_purposes["ua"].AvgTime)/60)*60,
    yminorticksvisible = true,
    yminorticks = IntervalsBetween(6),
    yminorgridvisible = true,
    yminorgridstyle = :dot,
    yminorgridcolor = :gray90,
    title = "Purpose: application"
  )

  box1 = boxplot!(
    ax1,
    dict_quiz_purposes["ua"].Weeks,
    dict_quiz_purposes["ua"].AvgTime,
    show_outliers = false,
    color = :lightgray,
    gap = 0.5
  )

  box2 = boxplot!(
    ax2,
    dict_quiz_purposes["aa"].Weeks,
    dict_quiz_purposes["aa"].AvgTime,
    show_outliers = false,
    color = :lightgray,
    gap = 0.5
  )

  line1 = lines!(
    ax1,
    dict_quiz_purposes["us"].Weeks,
    dict_quiz_purposes["us"].AvgTime,
    color = :red,
    label = "Student ID: $student_id"
  )

  scatter!(
    ax1,
    dict_quiz_purposes["us"].Weeks,
    dict_quiz_purposes["us"].AvgTime,
    color = :red,
    markersize =10 
  )

  line2 = lines!(
    ax2,
    dict_quiz_purposes["as"].Weeks,
    dict_quiz_purposes["as"].AvgTime,
    color = :red,
    label = "Student ID: $student_id"
  )

  scatter!(
    ax2,
    dict_quiz_purposes["as"].Weeks,
    dict_quiz_purposes["as"].AvgTime,
    color = :red,
    markersize = 10 
  )

  Legend(
    fig[1, 2],
    [box1, line1],
    ["Total students", "Student ID: $student_id"],
    labelsize = 10,
    backgroundcolor=(:white, 0.8)
  )

  Legend(
    fig[2, 2],
    [box2, line2],
    ["Total students", "Student ID: $student_id"],
    labelsize = 10,
    backgroundcolor=(:white, 0.8)
  )

  return fig
end

function plot_quiz_access_time(
  df_Qstart_t_diff::DataFrame,
  student_df::DataFrame,
  id::Int64
)

  fig = Figure(size = (1000, 600))
  ax1 = Axis(
    fig[1, 1], 
    title = "Quiz Access Time and Scores (Student ID: $id)",
    xlabel = "Weeks",
    ylabel = "Days to quiz access",
    xticks = 1:14,
    limits = (0.6, 14.4, 0, 5),
  )
  
  ax2 = Axis(
    fig[1, 1],
    ylabel = "Quiz Scores",
    yaxisposition = :right,
    ygridvisible = false
  )
  hidespines!(ax2)
  hidexdecorations!(ax2)
  
  linkxaxes!(ax1, ax2)
  
  # Plot average data
  x_avg = df_Qstart_t_diff[!, :Weeks]
  y_avg = df_Qstart_t_diff[!, :mean_days]
  error = df_Qstart_t_diff[!, :std_days]
  band!(ax1, x_avg, y_avg .- error, y_avg .+ error, color = (:lightgray, 0.5))
  avg_line = lines!(ax1, x_avg, y_avg, color = :red, linewidth = 2)
  scatter!(ax1, x_avg, y_avg, color = :red, markersize = 10)
  
  # Plot student data
  student_data = filter(row -> row.IDs == id, student_df)
  x_student = student_data[!, :Weeks]
  y_student_diff = student_data[!, :access_time_diff]
  y_student_score = student_data[!, :Scores]
  
  student_line = lines!(
    ax1,
    x_student,
    y_student_diff,
    color = :blue,
    linewidth = 2
  )
  scatter!(ax1, x_student, y_student_diff, color = :blue, markersize = 10)
  
  score_line = lines!(
    ax2,
    x_student,
    y_student_score,
    color = :green,
    linewidth = 2
  )
  scatter!(ax2, x_student, y_student_score, color = :green, markersize = 10)
  
  Legend(
    fig[1, 2],
    [avg_line, student_line, score_line],
    ["Average Access Time", "Student Access Time", "Scores"],
    labelsize = 10,
    backgroundcolor = (:white, 0.8)
  )
  
  return fig
end

function plot_quiz_duration(
  df_quiz_duration::DataFrame,
  student_df::DataFrame,
  id::Int64
)

  fig = Figure(size = (1000, 600))
  ax1 = Axis(
    fig[1, 1], 
    title = "Weekly time spent on quiz (Student ID: $id)",
    xlabel = "Weeks",
    ylabel = "Duration (mins)",
    xticks = 1:14,
    limits = (0.6, 14.4, 0, 120),
  )
  
  ax2 = Axis(
    fig[1, 1],
    ylabel = "Quiz Scores",
    yaxisposition = :right,
    ygridvisible = false,
    limits = (0.6, 14.4, 0, 105)
  )
  hidespines!(ax2)
  hidexdecorations!(ax2)
  
  linkxaxes!(ax1, ax2)
  
  # Plot average data
  x_avg = df_quiz_duration[!, :Weeks]
  y_avg = df_quiz_duration[!, :mean_durations]
  error = df_quiz_duration[!, :std_durations]
  band!(ax1, x_avg, y_avg .- error, y_avg .+ error, color = (:lightgray, 0.5))
  avg_line = lines!(ax1, x_avg, y_avg, color = :red, linewidth = 2)
  scatter!(ax1, x_avg, y_avg, color = :red, markersize = 10)
  
  # Plot student data
  student_data = filter(row -> row.IDs == id, student_df)
  x_student = student_data[!, :Weeks]
  y_student_duration = student_data[!, :Duration]
  y_student_score = student_data[!, :Scores]
  
  student_line = lines!(
    ax1,
    x_student,
    y_student_duration,
    color = :blue,
    linewidth = 2
  )
  scatter!(ax1, x_student, y_student_duration, color = :blue, markersize = 10)
  
  score_line = lines!(
    ax2,
    x_student,
    y_student_score,
    color = :green,
    linewidth = 2
  )
  scatter!(ax2, x_student, y_student_score, color = :green, markersize = 10)
  
  Legend(
    fig[1, 2],
    [avg_line, student_line, score_line],
    ["Average Duration", "Student Duration", "Scores"],
    labelsize = 10,
    backgroundcolor = (:white, 0.8)
  )
  
  return fig
end

end
