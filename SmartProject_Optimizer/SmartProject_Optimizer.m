%% SMARTPROJECT OPTIMIZER
% Interactive MATLAB mini project:
% Optimal Resource Allocation and Project Scheduling
% Recommended: MATLAB R2018b or later.
% Required: Optimization Toolbox (linprog and intlinprog).
%
% HOW TO RUN:
% 1. Open this file in MATLAB.
% 2. Set it as the Current Folder file or simply click Run.
% 3. Choose "Run sample project" in the startup menu.
% 4. Explore charts, tables and what-if analysis from the dashboard.
%
% OUTPUTS:
% A SmartProject_Output folder is created beside this .m file. It contains
% PNG figures, CSV tables, a MAT data file and a text summary.
%
% MODELLING NOTE:
% LP is a capacity-constrained transportation-style effort allocation
% model. ILP is a separate one-developer-per-task assignment model.
% CPM Gantt scheduling is precedence-based and does not perform resource
% leveling. All sample project data and INR rates are illustrative.

clear; clc; close all;

fprintf('\n============================================================\n');
fprintf('                 SMARTPROJECT OPTIMIZER\n');
fprintf('  LP Transportation | ILP Assignment | CPM | PERT | WHAT-IF\n');
fprintf('============================================================\n');

startChoice = menu('SmartProject Optimizer', ...
    'Run sample software project', 'Exit');
if startChoice ~= 1
    fprintf('Project run cancelled by user.\n');
    return;
end

% Use the folder containing this script, not an assumed working folder.
projectDir = fileparts(mfilename('fullpath'));
if isempty(projectDir), projectDir = pwd; end
outDir = fullfile(projectDir,'SmartProject_Output');
if ~exist(outDir,'dir'), mkdir(outDir); end

% ---------------------- PROJECT DATA -------------------------
% Durations are working days. PERT estimates are in days.
taskNames = {'Requirements','UI/UX Design','Database Design', ...
    'Backend Development','Frontend Development','Integration', ...
    'Testing','Deployment'};
n = numel(taskNames);

% Predecessor task IDs. Tasks are listed in topological order.
pred = {[],1,1,[2 3],2,[4 5],6,7};
optimistic = [2 2 2 5 4 2 3 1];
mostLikely = [3 3 3 7 6 3 4 2];
pessimistic = [5 5 4 10 9 5 7 3];
pertDur = (optimistic + 4*mostLikely + pessimistic)/6;
pertVar = ((pessimistic-optimistic)/6).^2;

% Skill categories: Analysis, Design, Database, Coding,
% Integration, Testing and Deployment.
skillNames = {'Analysis','Design','Database','Coding', ...
              'Integration','Testing','Deployment'};
nSkill = numel(skillNames);

% Required effort (person-days) per task and skill category.
% Row order matches taskNames; column order matches skillNames.
demandByTask = [3 0 0 0 0 0 0; ...
                0 3 0 0 0 0 0; ...
                0 0 3 0 0 0 0; ...
                0 0 0 12 0 0 0; ...
                0 6 0 0 0 0 0; ...
                0 0 0 0 5 0 0; ...
                0 0 0 0 0 7 0; ...
                0 0 0 0 0 0 2];
skillDemand = sum(demandByTask,1)';

% Developers: rows are developers; columns are skill categories.
developerNames = {'Aarav','Diya','Kabir','Meera','Rohan'};
skills = [1 0 0 1 1 0 0; ...
          0 1 0 0 0 1 0; ...
          0 0 1 1 0 0 0; ...
          0 1 0 1 1 1 0; ...
          0 0 0 0 1 1 1];
dailyCost = [1800;1600;1700;2000;1500]; % illustrative INR/person-day
capacity = [10;10;10;12;10];           % available person-days/developer
nDev = numel(developerNames);

fprintf('\nPROJECT: Web-based Student Management System\n');
fprintf('Tasks: %d | Developers: %d | Currency: INR\n',n,nDev);
fprintf('Working-time unit: person-days / working days\n');

% Check that the Optimization Toolbox functions are available.
if exist('linprog','file') ~= 2 || exist('intlinprog','file') ~= 2
    error(['Optimization Toolbox functions linprog and intlinprog were not found. ', ...
        'Install/enable MATLAB Optimization Toolbox, then rerun this script.']);
end

% ---------------- LINEAR PROGRAMMING -------------------------
% x(d,s): effort supplied by developer d to skill s.
% Minimize sum(dailyCost(d)*x(d,s)) subject to skill demand and capacity.
% The structure is a capacity-constrained transportation-style model.
f = repmat(dailyCost,nSkill,1);
Aeq = zeros(nSkill,nDev*nSkill);
for s = 1:nSkill
    for d = 1:nDev
        Aeq(s,(s-1)*nDev+d) = skills(d,s);
    end
end
beq = skillDemand;
A = zeros(nDev,nDev*nSkill);
for d = 1:nDev
    for s = 1:nSkill
        A(d,(s-1)*nDev+d) = 1;
    end
end
b = capacity;
lb = zeros(nDev*nSkill,1);
ub = inf(nDev*nSkill,1);
for s = 1:nSkill
    for d = 1:nDev
        if skills(d,s) == 0
            ub((s-1)*nDev+d) = 0; % prohibit incompatible developer-skill routes
        end
    end
end
opts = optimoptions('linprog','Display','none');
[xLP,minCost,exitLP] = linprog(f,A,b,Aeq,beq,lb,ub,opts);
if exitLP <= 0
    error('Linear program did not find a feasible solution. Review skills, demand and capacity.');
end
alloc = reshape(xLP,nDev,nSkill);

fprintf('\n--------------- LINEAR PROGRAMMING ----------------\n');
fprintf('Minimum resource-allocation cost: INR %.2f\n',minCost);
disp(array2table(alloc,'RowNames',developerNames,'VariableNames',skillNames));
usedCapacity = sum(alloc,2);
disp(table(developerNames',usedCapacity,capacity,capacity-usedCapacity, ...
    'VariableNames',{'Developer','AllocatedDays','AvailableDays','UnusedDays'}));

% ---------------- INTEGER PROGRAMMING ------------------------
% y(t,d) is binary: 1 if developer d is assigned to task t.
% Exactly one eligible developer is assigned to each task.
taskSkill = [1 2 3 4 2 5 6 7];
eligible = skills(:,taskSkill)'; % n tasks x nDev developers
fInt = zeros(n*nDev,1);
for t = 1:n
    for d = 1:nDev
        fInt((t-1)*nDev+d) = dailyCost(d)*mostLikely(t);
    end
end
AeqI = zeros(n,n*nDev);
for t = 1:n
    AeqI(t,(t-1)*nDev+(1:nDev)) = 1;
end
AI = zeros(nDev,n*nDev);
for d = 1:nDev
    for t = 1:n
        AI(d,(t-1)*nDev+d) = mostLikely(t);
    end
end
bI = capacity;
lbI = zeros(n*nDev,1);
ubI = reshape(eligible',[],1); % task-major vector, matching fInt
intcon = 1:(n*nDev);
optsI = optimoptions('intlinprog','Display','off');
[y,assignCost,exitInt] = intlinprog(fInt,intcon,AI,bI,AeqI,ones(n,1), ...
    lbI,ubI,optsI);
if exitInt <= 0 || isempty(y)
    error('Integer assignment is infeasible. Increase capacities or review skill eligibility.');
end
Y = reshape(round(y),nDev,n)';
[~,assignment] = max(Y,[],2);
assignedDeveloper = developerNames(assignment)';
assignmentTable = table(taskNames',assignedDeveloper,mostLikely', ...
    'VariableNames',{'Task','AssignedDeveloper','EstimatedDays'});

fprintf('\n--------------- INTEGER TASK ASSIGNMENT ----------------\n');
disp(assignmentTable);
fprintf('Task-assignment cost estimate: INR %.2f\n',assignCost);

% ---------------- CPM: CRITICAL PATH METHOD ------------------
ES = zeros(1,n); EF = zeros(1,n);
for t = 1:n
    if ~isempty(pred{t})
        ES(t) = max(EF(pred{t}));
    end
    EF(t) = ES(t) + mostLikely(t);
end
projectDuration = max(EF);
LF = projectDuration*ones(1,n); LS = zeros(1,n);
for t = n:-1:1
    successors = find(cellfun(@(p) any(p==t),pred));
    if ~isempty(successors)
        LF(t) = min(LS(successors));
    end
    LS(t) = LF(t) - mostLikely(t);
end
slack = LS - ES;
critical = abs(slack) < 1e-8;
cpmTable = table(taskNames',mostLikely',ES',EF',LS',LF',slack',critical', ...
    'VariableNames',{'Task','Duration','ES','EF','LS','LF','Slack','Critical'});

fprintf('\n--------------- CPM RESULTS ----------------\n');
disp(cpmTable);
fprintf('Critical project duration: %.1f working days\n',projectDuration);
fprintf('Critical tasks: %s\n',strjoin(taskNames(critical),', '));

% ---------------- PERT UNCERTAINTY ANALYSIS -----------------
% PERT aggregation uses the critical path determined by most-likely times.
expectedDuration = sum(pertDur(critical));
projectVariance = sum(pertVar(critical));
projectSD = sqrt(projectVariance);
target = projectDuration + 5;
z = (target-expectedDuration)/max(projectSD,eps);
completionProbability = 0.5*(1+erf(z/sqrt(2)));

fprintf('\n--------------- PERT RESULTS ----------------\n');
fprintf('Expected duration along CPM critical path: %.2f days\n',expectedDuration);
fprintf('Critical-path variance: %.3f days^2\n',projectVariance);
fprintf('Critical-path standard deviation: %.2f days\n',projectSD);
fprintf('Approx. probability of completion within %.1f days: %.1f%%\n', ...
    target,100*completionProbability);

% ---------------- WHAT-IF ANALYSIS ---------------------------
extraCapacity = 2;
bWhatIf = capacity + extraCapacity;
[~,costWhatIf,exitWhatIf] = linprog(f,A,bWhatIf,Aeq,beq,lb,ub,opts);
if exitWhatIf > 0
    fprintf('\nWHAT-IF: +%.1f person-days capacity/developer changes LP cost by INR %.2f\n', ...
        extraCapacity,costWhatIf-minCost);
else
    costWhatIf = NaN;
    fprintf('\nWHAT-IF: Modified capacity scenario was infeasible.\n');
end

% ---------------------- VISUALIZATIONS -----------------------
% 1. Dependency-based Gantt chart (not resource leveled).
fig1 = figure('Name','Project Gantt Chart','Color','w');
hold on;
for t = 1:n
    if critical(t), face = [0.82 0.25 0.24]; else, face = [0.20 0.48 0.72]; end
    rectangle('Position',[ES(t),t-0.35,mostLikely(t),0.7], ...
        'FaceColor',face,'EdgeColor','k');
    text(ES(t)+mostLikely(t)/2,t,sprintf('%.0f d',mostLikely(t)), ...
        'HorizontalAlignment','center','Color','w','FontWeight','bold');
end
yticks(1:n); yticklabels(taskNames); set(gca,'YDir','reverse');
xlabel('Working days'); title('Software Project Gantt Chart (Red = Critical)');
grid on; xlim([0 projectDuration+2]); hold off;
saveas(fig1,fullfile(outDir,'01_Gantt_Chart.png'));

% 2. LP effort allocation by developer and skill.
fig2 = figure('Name','Resource Allocation','Color','w');
bar(alloc,'stacked'); xticks(1:nDev); xticklabels(developerNames);
ylabel('Allocated person-days'); title('Minimum-Cost Resource Allocation');
legend(skillNames,'Location','eastoutside'); grid on;
saveas(fig2,fullfile(outDir,'02_Resource_Allocation.png'));

% 3. PERT time estimates.
fig3 = figure('Name','PERT Duration','Color','w');
bar([optimistic' mostLikely' pessimistic' pertDur']);
xticks(1:n); xticklabels(taskNames); xtickangle(25);
ylabel('Days'); title('PERT Duration Estimates');
legend({'Optimistic','Most Likely','Pessimistic','Expected'},'Location','northwest');
grid on; saveas(fig3,fullfile(outDir,'03_PERT_Analysis.png'));

% 4. CPM slack analysis.
fig4 = figure('Name','CPM Slack','Color','w');
bar(slack); xticks(1:n); xticklabels(taskNames); xtickangle(25);
ylabel('Slack (days)'); title('Task Slack: Zero Slack Indicates Critical Task');
grid on; saveas(fig4,fullfile(outDir,'04_CPM_Slack.png'));

% 5. Binary task-to-developer assignment map.
fig5 = figure('Name','Task Assignment Map','Color','w');
imagesc(Y); colormap(gca,[0.94 0.96 0.98; 0.12 0.48 0.70]);
set(gca,'XTick',1:nDev,'XTickLabel',developerNames, ...
    'YTick',1:n,'YTickLabel',taskNames);
xlabel('Developer'); ylabel('Project task');
title('Integer Programming: Task-to-Developer Assignment');
for t = 1:n
    for d = 1:nDev
        if Y(t,d) == 1, text(d,t,'Assigned','Color','w', ...
                'HorizontalAlignment','center','FontWeight','bold'); end
    end
end
saveas(fig5,fullfile(outDir,'05_Task_Assignment.png'));

% ---------------- EXPORT TABLES AND REPORT -------------------
writetable(assignmentTable,fullfile(outDir,'Task_Assignments.csv'));
writetable(cpmTable,fullfile(outDir,'CPM_Results.csv'));
resourceTable = array2table(alloc,'RowNames',developerNames, ...
    'VariableNames',skillNames);
writetable(resourceTable,fullfile(outDir,'Resource_Allocation.csv'), ...
    'WriteRowNames',true);

reportFile = fullfile(outDir,'Project_Summary.txt');
fid = fopen(reportFile,'w');
if fid < 0, error('Could not create Project_Summary.txt in output folder.'); end
fprintf(fid,'SMARTPROJECT OPTIMIZER - EXECUTION SUMMARY\n');
fprintf(fid,'Project: Web-based Student Management System\n');
fprintf(fid,'Minimum LP resource allocation cost: INR %.2f\n',minCost);
fprintf(fid,'ILP task assignment cost: INR %.2f\n',assignCost);
fprintf(fid,'CPM completion time: %.2f working days\n',projectDuration);
fprintf(fid,'PERT expected critical-path duration: %.2f days\n',expectedDuration);
fprintf(fid,'PERT standard deviation: %.2f days\n',projectSD);
fprintf(fid,'Completion probability within %.1f days: %.2f%%\n', ...
    target,100*completionProbability);
fprintf(fid,'Critical tasks: %s\n',strjoin(taskNames(critical),', '));
fprintf(fid,'What-if LP cost after capacity increase: INR %.2f\n',costWhatIf);
fprintf(fid,'\nNote: Values are based on the illustrative sample dataset.\n');
fclose(fid);

save(fullfile(outDir,'SmartProject_Results.mat'), ...
    'taskNames','developerNames','skillNames','alloc','minCost', ...
    'assignmentTable','cpmTable','projectDuration','pertDur','pertVar', ...
    'expectedDuration','projectVariance','projectSD','critical', ...
    'completionProbability','costWhatIf','Y');

fprintf('\n============================================================\n');
fprintf('PROJECT EXECUTION COMPLETED SUCCESSFULLY\n');
fprintf('All tables, charts and results saved in:\n%s\n',outDir);
fprintf('============================================================\n');

% ---------------- INTERACTIVE RESULTS DASHBOARD --------------
% Keep selecting views or run custom additional-capacity scenarios.
keepOpen = true;
while keepOpen
    dashboardChoice = menu('SmartProject Results Dashboard', ...
        'View Gantt Chart','View Resource Allocation', ...
        'View PERT Analysis','View CPM Slack','View Task Assignment Map', ...
        'Display Result Tables','Run Custom Capacity What-if','Exit Dashboard');
    switch dashboardChoice
        case 1
            figure(fig1);
        case 2
            figure(fig2);
        case 3
            figure(fig3);
        case 4
            figure(fig4);
        case 5
            figure(fig5);
        case 6
            disp('--- TASK ASSIGNMENTS ---'); disp(assignmentTable);
            disp('--- CPM RESULTS ---'); disp(cpmTable);
            disp('--- RESOURCE ALLOCATION ---'); disp(resourceTable);
        case 7
            extra = input('Enter additional person-days available to EACH developer (0 or more): ');
            while isempty(extra) || ~isscalar(extra) || ~isnumeric(extra) || ...
                    ~isfinite(extra) || extra < 0
                extra = input('Enter a valid non-negative numeric value: ');
            end
            [~,customCost,customExit] = linprog(f,A,capacity+extra,Aeq,beq,lb,ub,opts);
            if customExit > 0
                fprintf('Custom scenario minimum LP cost: INR %.2f\n',customCost);
                fprintf('Cost change against baseline: INR %.2f\n',customCost-minCost);
            else
                fprintf('The custom capacity scenario is infeasible.\n');
            end
        otherwise
            keepOpen = false;
    end
end
fprintf('Dashboard closed. Review SmartProject_Output for saved deliverables.\n');
