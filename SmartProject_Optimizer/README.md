# SmartProject Optimizer — MATLAB Mini Project

## Overview
Interactive MATLAB prototype for optimal effort allocation and software project scheduling. It demonstrates:
- Linear Programming using `linprog` (capacity-constrained, transportation-style effort allocation)
- Integer Linear Programming using `intlinprog` (one eligible developer per task)
- Critical Path Method (CPM), including ES, EF, LS, LF, slack and critical activities
- Program Evaluation and Review Technique (PERT), including expected times, variance and an approximate completion probability
- What-if capacity analysis, interactive chart/table dashboard, and automatic output export

## Requirements
- MATLAB R2018b or later recommended
- Optimization Toolbox (required for `linprog` and `intlinprog`)
- A writable project folder

## Run
1. Extract this folder.
2. Open MATLAB and navigate to the `SmartProject_Optimizer` folder.
3. Open `SmartProject_Optimizer.m` and click **Run**.
4. Select **Run sample software project**.
5. Explore chart/table views and the custom capacity what-if from the dashboard.
6. Review the generated `SmartProject_Output` folder beside the `.m` file.

## Output files
- `01_Gantt_Chart.png`
- `02_Resource_Allocation.png`
- `03_PERT_Analysis.png`
- `04_CPM_Slack.png`
- `05_Task_Assignment.png`
- `Task_Assignments.csv`, `CPM_Results.csv`, `Resource_Allocation.csv`
- `Project_Summary.txt`, `SmartProject_Results.mat`

## Sample model assumptions
Eight tasks and five fictional developers are included. Task durations are working days; resource effort and capacities are person-days; rates are illustrative INR per person-day. Developer skills determine permitted assignments. The LP and ILP are complementary but separate mathematical models. The Gantt chart respects task dependencies and does not perform resource leveling. PERT aggregation uses the CPM critical path based on most-likely durations.

## Independently checked sample results
- LP resource allocation cost: INR 68,000.00
- ILP task assignment cost: INR 50,300.00
- CPM duration: 22 working days
- PERT expected critical-path duration: 26.00 days
- PERT standard deviation: 1.45 days
- Approximate probability of finishing within 27 days: 75.4%
- LP cost with +2 person-days capacity per developer: INR 66,800.00

These are outputs calculated from the built-in sample data. Replace the input values to model your own project.
