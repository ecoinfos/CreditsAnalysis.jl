module CreatePlots

using DataFrames
using CairoMakie
 
export plot_achievement_radar, plot_origin_accuracy

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
    labelsize=10,
    backgroundcolor=(:white, 0.8)
  ) 
  fig

end

function plot_origin_accuracy(accuracy_dict::Dict{String, Float64}, student_id::Int64)
    categories = ["Original", "Quiz"]
    bar_labels = ["Total", "$student_id"]

    # Create table-like data structure
    tbl = (
        cat = [1, 1, 2, 2],
        height = [
            accuracy_dict["total_orig_accuracy"],
            accuracy_dict["student_orig_accuracy"],
            accuracy_dict["total_quiz_accuracy"],
            accuracy_dict["student_quiz_accuracy"]
        ],
        grp = [1, 2, 1, 2]
    )

    fig = Figure(size = (600, 400))
    ax = Axis(
        fig[1, 1],
        ylabel = "Accuracy (%)",
        xticks = (1:2, categories),
        limits = ((0.5, 2.5), (0, 100)),
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






end
