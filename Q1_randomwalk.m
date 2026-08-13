%% BPhO Computational Challenge 2026 - Task 1: 2D Random Walk
% An N-step random walk with fixed step size s.
% Each direction is chosen uniformly from 0 to 2*pi radians.
%
% The script shows:
%   1. One representative random walk.
%   2. The distribution of final displacements from many walks.
%   3. A comparison with the theoretical mean and RMS displacement.

clear;
close all;
clc;

%% USER PARAMETERS
N = 300;              % Number of steps in each walk
s = 5.0;              % Step size
numWalks = 5000;      % Number of walks used for the statistical test
useFixedSeed = false; % Set true to reproduce exactly the same result
randomSeed = 1;

%% INPUT CHECKS
validateattributes(N, {'numeric'}, ...
    {'scalar', 'integer', 'positive', 'finite'}, mfilename, 'N');
validateattributes(s, {'numeric'}, ...
    {'scalar', 'real', 'positive', 'finite'}, mfilename, 's');
validateattributes(numWalks, {'numeric'}, ...
    {'scalar', 'integer', 'positive', 'finite'}, mfilename, 'numWalks');

if useFixedSeed
    rng(randomSeed);
else
    rng('shuffle');
end

%% PART 1: ONE RANDOM WALK
angles = 2*pi*rand(1, N);
dx = s*cos(angles);
dy = s*sin(angles);

x = [0, cumsum(dx)];
y = [0, cumsum(dy)];

finalDisplacement = hypot(x(end), y(end));
totalDistance = N*s;

%% PART 2: MANY RANDOM WALKS
% Each row contains one complete walk.
allAngles = 2*pi*rand(numWalks, N);
finalX = s*sum(cos(allAngles), 2);
finalY = s*sum(sin(allAngles), 2);
finalR = hypot(finalX, finalY);

% Simulated statistics
simulatedMean = mean(finalR);
simulatedRMS = sqrt(mean(finalR.^2));
simulatedMeanR2 = mean(finalR.^2);

% Theoretical results for a 2D random walk
% <R> is the large-N Rayleigh approximation.
theoreticalMean = (sqrt(pi)/2)*s*sqrt(N);
theoreticalRMS = s*sqrt(N);
theoreticalMeanR2 = N*s^2;

percentageErrorR2 = 100*abs(simulatedMeanR2 - theoreticalMeanR2) ...
                    / theoreticalMeanR2;

%% DISPLAY NUMERICAL RESULTS
fprintf('====================================================\n');
fprintf('BPhO TASK 1: TWO-DIMENSIONAL RANDOM WALK\n');
fprintf('====================================================\n');
fprintf('Steps per walk, N:                 %d\n', N);
fprintf('Step size, s:                      %.3f\n', s);
fprintf('Total distance travelled, Ns:      %.3f\n', totalDistance);
fprintf('Single-walk final position:         (%.3f, %.3f)\n', ...
        x(end), y(end));
fprintf('Single-walk displacement:           %.3f\n\n', ...
        finalDisplacement);

fprintf('Number of simulated walks:          %d\n', numWalks);
fprintf('Simulated mean displacement:        %.3f\n', simulatedMean);
fprintf('Theoretical mean displacement:      %.3f\n', theoreticalMean);
fprintf('Simulated RMS displacement:         %.3f\n', simulatedRMS);
fprintf('Theoretical RMS displacement:       %.3f\n', theoreticalRMS);
fprintf('Simulated <R^2>:                    %.3f\n', simulatedMeanR2);
fprintf('Theoretical <R^2> = Ns^2:           %.3f\n', theoreticalMeanR2);
fprintf('Percentage error in <R^2>:          %.3f%%\n', percentageErrorR2);
fprintf('====================================================\n');

%% PLOT RESULTS
figure('Color', 'w', 'Position', [100, 100, 1250, 520]);
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

% ---- Representative walk ----
nexttile;
hPath = plot(x, y, '-', 'LineWidth', 1.4, ...
    'DisplayName', 'Walk path');
hold on;
hStart = plot(x(1), y(1), 'o', ...
    'MarkerSize', 9, ...
    'MarkerFaceColor', [0.20, 0.65, 0.25], ...
    'MarkerEdgeColor', 'k', ...
    'DisplayName', 'Start');
hEnd = plot(x(end), y(end), 'o', ...
    'MarkerSize', 9, ...
    'MarkerFaceColor', [0.90, 0.25, 0.15], ...
    'MarkerEdgeColor', 'k', ...
    'DisplayName', 'End');

axis equal;
grid on;
box on;
xlabel('x position');
ylabel('y position');
title({'Single 2D random walk', ...
       sprintf('N = %d, s = %.2f, final displacement = %.2f', ...
               N, s, finalDisplacement)});
legend([hPath, hStart, hEnd], 'Location', 'best');
hold off;

% ---- Distribution of final displacements ----
nexttile;
hHist = histogram(finalR, 30, ...
    'Normalization', 'pdf', ...
    'FaceAlpha', 0.65, ...
    'DisplayName', 'Simulation');
hold on;

rMax = max(finalR)*1.05;
rTheory = linspace(0, rMax, 400);
rayleighPDF = (2*rTheory/(N*s^2)) .* ...
              exp(-(rTheory.^2)/(N*s^2));

hTheory = plot(rTheory, rayleighPDF, '-', ...
    'LineWidth', 2.0, ...
    'DisplayName', 'Theoretical distribution');

xline(theoreticalMean, '--', 'Theoretical mean', ...
    'LabelVerticalAlignment', 'middle', ...
    'LabelHorizontalAlignment', 'left');

xline(theoreticalRMS, ':', 'Theoretical RMS', ...
    'LabelVerticalAlignment', 'middle', ...
    'LabelHorizontalAlignment', 'left');

grid on;
box on;
xlabel('Final displacement, R');
ylabel('Probability density');
title({'Final-displacement distribution', ...
       sprintf('%d walks; error in <R^2> = %.2f%%', ...
               numWalks, percentageErrorR2)});
legend([hHist, hTheory], 'Location', 'best');
hold off;
