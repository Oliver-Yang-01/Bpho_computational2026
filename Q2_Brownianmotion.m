%% BPhO Computational Challenge 2026 - Task 2: Brownian Motion
% Many light particles perform persistent random walks inside a reflecting
% box. Elastic collisions transfer momentum to one much heavier particle.
%
% The left panel animates the particles and the full red trajectory of the
% large particle. The right panel shows the squared displacement of that single
% large-particle trajectory in real time.
%
% No specialist MATLAB toolboxes are required.

clear;
clc;
close all;

%% ------------------------- USER SETTINGS -----------------------------
% Random-number control
useFixedSeed = false;       % false: a genuinely different run each time
fixedSeed = 2026;           % used only when useFixedSeed is true

% Geometry
Lx = 2.0;                   % box width / m
Ly = 2.0;                   % box height / m

% Small particles
N = 100;                    % number of small particles
m = 1.0e-3;                 % mass of each small particle / kg
r = 0.012;                  % radius of each small particle / m
smallSpeed = 0.55;          % typical small-particle speed / m s^-1
turnRate = 4.0;             % mean random direction changes per second

% Large particle
M = 0.20;                   % large-particle mass / kg
R = 0.12;                   % large-particle radius / m
randomiseLargeStart = true; % place it randomly within the central region

% Time integration
simulationTime = 25;        % simulated time / s
dt = 0.01;                  % timestep / s
includeSmallSmallCollisions = true;
collisionPasses = 1;        % increase only if visible overlaps persist

% Animation
plotEvery = 5;              % update the figure every this many timesteps
pausePerFrame = 0.01;       % increase to slow the visible animation

%% ---------------------- RANDOM-NUMBER SETUP --------------------------
if useFixedSeed
    rng(fixedSeed, 'twister');
else
    rng('shuffle');
end
seedInformation = rng;

%% ----------------------- BASIC VALIDATION ----------------------------
validateattributes(N, {'numeric'}, {'scalar','integer','positive'});
validateattributes(m, {'numeric'}, {'scalar','positive','finite'});
validateattributes(M, {'numeric'}, {'scalar','positive','finite'});
validateattributes(r, {'numeric'}, {'scalar','positive','finite'});
validateattributes(R, {'numeric'}, {'scalar','positive','finite'});
validateattributes(dt, {'numeric'}, {'scalar','positive','finite'});
validateattributes(simulationTime, {'numeric'}, {'scalar','positive','finite'});

if 2*R >= min(Lx, Ly)
    error('The large particle is too large for the box.');
end
if 2*r >= min(Lx, Ly)
    error('The small particles are too large for the box.');
end

nSteps = round(simulationTime/dt);
time = (0:nSteps)' * dt;
turnProbability = 1 - exp(-turnRate*dt);

%% ----------------------- INITIAL CONDITIONS -------------------------
% Start the heavy particle at rest. A random central starting point makes
% each unseeded run visibly different while keeping it away from the walls.
if randomiseLargeStart
    centralFraction = 0.30;
    posBig = [Lx/2 + (rand - 0.5)*centralFraction*Lx, ...
              Ly/2 + (rand - 0.5)*centralFraction*Ly];
else
    posBig = [Lx/2, Ly/2];
end
velBig = [0, 0];
posBigInitial = posBig;

% Rejection sampling prevents initial particle overlap.
posSmall = initialiseSmallParticles(N, Lx, Ly, r, posBig, R);

% All small particles initially have the same speed but random directions.
angles = 2*pi*rand(N,1);
velSmall = smallSpeed * [cos(angles), sin(angles)];

% Storage for the large particle.
bigTrajectory = zeros(nSteps + 1, 2);
bigTrajectory(1,:) = posBig;
squaredDisplacement = zeros(nSteps + 1, 1);

% Diagnostics.
totalBigCollisions = 0;
totalSmallCollisions = 0;
maxRelativeMomentumError = 0;
completedSteps = nSteps;

%% -------------------------- FIGURE SETUP -----------------------------
fig = figure( ...
    'Color', 'w', ...
    'Name', 'BPhO Task 2 - Brownian Motion', ...
    'NumberTitle', 'off', ...
    'Position', [80 100 1320 570]);

layout = tiledlayout(fig, 1, 2, ...
    'TileSpacing', 'compact', 'Padding', 'compact');

% ----- Left panel: animated particles -----
axAnimation = nexttile(layout, 1);
hold(axAnimation, 'on');
axis(axAnimation, 'equal');
box(axAnimation, 'on');
xlim(axAnimation, [0 Lx]);
ylim(axAnimation, [0 Ly]);
xlabel(axAnimation, 'x / m');
ylabel(axAnimation, 'y / m');
title(axAnimation, 'Brownian-motion particle simulation');

% Boundary.
plot(axAnimation, [0 Lx Lx 0 0], [0 0 Ly Ly 0], ...
    'k-', 'LineWidth', 1.4, 'HandleVisibility', 'off');

% Draw small particles as visible points. Their physical collision radius is
% still r, even though marker size is specified in screen points.
hSmall = scatter(axAnimation, posSmall(:,1), posSmall(:,2), 20, ...
    [0.10 0.40 0.90], 'filled', ...
    'DisplayName', 'Small particles');

circleAngle = linspace(0, 2*pi, 100);
hBig = patch(axAnimation, ...
    posBig(1) + R*cos(circleAngle), ...
    posBig(2) + R*sin(circleAngle), ...
    [0.90 0.28 0.20], ...
    'EdgeColor', [0.35 0.05 0.05], ...
    'LineWidth', 1.5, ...
    'DisplayName', 'Large particle');

hInitial = plot(axAnimation, posBigInitial(1), posBigInitial(2), 'kx', ...
    'MarkerSize', 9, 'LineWidth', 1.6, ...
    'DisplayName', 'Initial position');

hTrail = plot(axAnimation, posBig(1), posBig(2), '-', ...
    'Color', [0.85 0.15 0.15], 'LineWidth', 1.5, ...
    'DisplayName', 'Large-particle trajectory');

hInformation = text(axAnimation, 0.02, 0.98, '', ...
    'Units', 'normalized', ...
    'VerticalAlignment', 'top', ...
    'BackgroundColor', 'w', ...
    'Margin', 5, ...
    'FontSize', 10);

legend(axAnimation, [hSmall hBig hInitial hTrail], ...
    'Location', 'southoutside', 'Orientation', 'horizontal');

% ----- Right panel: live squared displacement -----
axDisplacement = nexttile(layout, 2);
hold(axDisplacement, 'on');
box(axDisplacement, 'on');
grid(axDisplacement, 'on');
xlim(axDisplacement, [0 simulationTime]);
ylim(axDisplacement, [0 0.02]);
xlabel(axDisplacement, 'Time / s');
ylabel(axDisplacement, '|R(t) - R(0)|^2 / m^2');
title(axDisplacement, 'Squared displacement: one large-particle trajectory');

hSquaredDisplacement = plot(axDisplacement, time(1), squaredDisplacement(1), ...
    'LineWidth', 1.7, ...
    'Color', [0.12 0.35 0.75], ...
    'DisplayName', 'Squared displacement');

hCurrentPoint = plot(axDisplacement, time(1), squaredDisplacement(1), 'o', ...
    'MarkerSize', 6, ...
    'MarkerFaceColor', [0.90 0.28 0.20], ...
    'MarkerEdgeColor', [0.45 0.05 0.05], ...
    'DisplayName', 'Current value');

legend(axDisplacement, 'Location', 'northwest');
drawnow;

%% ----------------------- MAIN SIMULATION LOOP ------------------------
for step = 1:nSteps
    if ~isgraphics(fig)
        completedSteps = step - 1;
        break;
    end

    % Each small particle changes direction at random times. This produces
    % a persistent random walk rather than a new direction every timestep.
    turning = rand(N,1) < turnProbability;
    nTurning = nnz(turning);
    if nTurning > 0
        newAngles = 2*pi*rand(nTurning,1);
        velSmall(turning,:) = smallSpeed * ...
            [cos(newAngles), sin(newAngles)];
    end

    % Advance all particles by one explicit timestep.
    posSmall = posSmall + velSmall*dt;
    posBig = posBig + velBig*dt;

    % Perfectly reflecting walls.
    [posSmall, velSmall] = reflectWalls(posSmall, velSmall, r, Lx, Ly);
    [posBig, velBig] = reflectWalls(posBig, velBig, R, Lx, Ly);

    % Finite timesteps can create small overlaps. Collision resolution also
    % separates particles so that they do not remain stuck together.
    for pass = 1:collisionPasses
        if includeSmallSmallCollisions
            [posSmall, velSmall, smallCollisionCount] = ...
                resolveSmallSmallCollisions(posSmall, velSmall, m, r);
            totalSmallCollisions = totalSmallCollisions + smallCollisionCount;
        end

        [posSmall, velSmall, posBig, velBig, bigCollisionCount, ...
            stepMomentumError] = resolveSmallBigCollisions( ...
            posSmall, velSmall, posBig, velBig, m, M, r, R);

        totalBigCollisions = totalBigCollisions + bigCollisionCount;
        maxRelativeMomentumError = max(maxRelativeMomentumError, ...
            stepMomentumError);

        % Collision corrections can move a particle slightly across a wall.
        [posSmall, velSmall] = reflectWalls(posSmall, velSmall, r, Lx, Ly);
        [posBig, velBig] = reflectWalls(posBig, velBig, R, Lx, Ly);
    end

    % Record the large-particle trajectory and its displacement from its own
    % initial position. This is squared displacement, not an ensemble MSD.
    bigTrajectory(step + 1,:) = posBig;
    displacementVector = posBig - posBigInitial;
    squaredDisplacement(step + 1) = dot(displacementVector, displacementVector);

    %% ---------------------- LIVE VISUALISATION ----------------------
    if mod(step, plotEvery) == 0 || step == 1 || step == nSteps
        set(hSmall, ...
            'XData', posSmall(:,1), ...
            'YData', posSmall(:,2));

        set(hBig, ...
            'XData', posBig(1) + R*cos(circleAngle), ...
            'YData', posBig(2) + R*sin(circleAngle));

        % Show the complete path travelled by the large particle from its
        % initial position up to the current time.
        visibleTrail = bigTrajectory(1:step + 1,:);
        set(hTrail, ...
            'XData', visibleTrail(:,1), ...
            'YData', visibleTrail(:,2));

        set(hSquaredDisplacement, ...
            'XData', time(1:step + 1), ...
            'YData', squaredDisplacement(1:step + 1));
        set(hCurrentPoint, ...
            'XData', time(step + 1), ...
            'YData', squaredDisplacement(step + 1));

        % Expand the vertical scale only when required, avoiding a jumpy plot.
        maximumShown = max(squaredDisplacement(1:step + 1));
        currentLimit = ylim(axDisplacement);
        if maximumShown > 0.88*currentLimit(2)
            newUpperLimit = max(0.02, 1.25*maximumShown);
            ylim(axDisplacement, [0 newUpperLimit]);
        end

        set(hInformation, 'String', sprintf([ ...
            't = %5.2f s\n' ...
            'large-particle speed = %.3f m s^{-1}\n' ...
            'small-large collisions = %d'], ...
            step*dt, norm(velBig), totalBigCollisions));

        title(axAnimation, sprintf( ...
            'Brownian motion, t = %.2f s', step*dt));

        drawnow limitrate;
        if pausePerFrame > 0
            pause(pausePerFrame);
        end
    end
end

%% ------------------------- FINAL SUMMARY -----------------------------
usedTime = time(1:completedSteps + 1);
usedSquaredDisplacement = squaredDisplacement(1:completedSteps + 1);

fprintf('\nBPhO Task 2: Brownian-motion simulation complete\n');
fprintf('--------------------------------------------------\n');
fprintf('Random seed used: %u\n', seedInformation.Seed);
fprintf('Small particles: %d\n', N);
fprintf('Simulated time: %.2f s\n', usedTime(end));
fprintf('Small-large collisions: %d\n', totalBigCollisions);
if includeSmallSmallCollisions
    fprintf('Small-small collisions: %d\n', totalSmallCollisions);
end
fprintf('Initial large-particle position: (%.4f, %.4f) m\n', ...
    posBigInitial(1), posBigInitial(2));
fprintf('Final large-particle position:   (%.4f, %.4f) m\n', ...
    posBig(1), posBig(2));
fprintf('Final large-particle speed: %.5f m/s\n', norm(velBig));
fprintf('Final squared displacement: %.6f m^2\n', ...
    usedSquaredDisplacement(end));
fprintf('Maximum relative momentum error in a small-large collision: %.3e\n', ...
    maxRelativeMomentumError);
fprintf(['Note: the live graph is the squared displacement of one trajectory, ' ...
    'not an ensemble mean-squared displacement.\n\n']);

if isgraphics(fig)
    set(hInformation, 'String', sprintf([ ...
        'Simulation complete\n' ...
        'small-large collisions = %d\n' ...
        'max momentum error = %.2e'], ...
        totalBigCollisions, maxRelativeMomentumError));
end

%% -------------------------- LOCAL FUNCTIONS --------------------------
function positions = initialiseSmallParticles(N, Lx, Ly, r, posBig, R)
%INITIALISESMALLPARTICLES Place particles without initial overlap.

    positions = zeros(N,2);
    numberPlaced = 0;
    attempts = 0;
    maximumAttempts = 250000;

    while numberPlaced < N && attempts < maximumAttempts
        attempts = attempts + 1;

        candidate = [r + (Lx - 2*r)*rand, ...
                     r + (Ly - 2*r)*rand];

        if norm(candidate - posBig) <= r + R
            continue;
        end

        if numberPlaced > 0
            separations = positions(1:numberPlaced,:) - candidate;
            distancesSquared = sum(separations.^2, 2);
            if any(distancesSquared <= (2*r)^2)
                continue;
            end
        end

        numberPlaced = numberPlaced + 1;
        positions(numberPlaced,:) = candidate;
    end

    if numberPlaced < N
        error(['Could not place all particles without overlap. ' ...
            'Reduce N or the radii, or enlarge the box.']);
    end
end

function [positions, velocities] = reflectWalls( ...
    positions, velocities, radius, Lx, Ly)
%REFLECTWALLS Reflect circular particles elastically at all four walls.

    hit = positions(:,1) < radius;
    positions(hit,1) = 2*radius - positions(hit,1);
    velocities(hit,1) = abs(velocities(hit,1));

    hit = positions(:,1) > Lx - radius;
    positions(hit,1) = 2*(Lx - radius) - positions(hit,1);
    velocities(hit,1) = -abs(velocities(hit,1));

    hit = positions(:,2) < radius;
    positions(hit,2) = 2*radius - positions(hit,2);
    velocities(hit,2) = abs(velocities(hit,2));

    hit = positions(:,2) > Ly - radius;
    positions(hit,2) = 2*(Ly - radius) - positions(hit,2);
    velocities(hit,2) = -abs(velocities(hit,2));
end

function [positions, velocities, collisionCount] = ...
    resolveSmallSmallCollisions(positions, velocities, mass, radius)
%RESOLVESMALLSMALLCOLLISIONS Resolve equal-mass elastic collisions.

    numberParticles = size(positions,1);
    minimumDistance = 2*radius;
    collisionCount = 0;

    for i = 1:numberParticles - 1
        for j = i + 1:numberParticles
            separation = positions(i,:) - positions(j,:);
            distance = norm(separation);

            if distance >= minimumDistance
                continue;
            end

            if distance <= eps
                randomAngle = 2*pi*rand;
                normal = [cos(randomAngle), sin(randomAngle)];
                distance = eps;
            else
                normal = separation/distance;
            end

            % Equal particles share the overlap correction equally.
            overlap = minimumDistance - distance;
            positions(i,:) = positions(i,:) + 0.5*overlap*normal;
            positions(j,:) = positions(j,:) - 0.5*overlap*normal;

            relativeNormalVelocity = dot( ...
                velocities(i,:) - velocities(j,:), normal);

            if relativeNormalVelocity < 0
                [newVelocityI, newVelocityJ] = elasticCollision( ...
                    velocities(i,:), velocities(j,:), mass, mass, normal);
                velocities(i,:) = newVelocityI;
                velocities(j,:) = newVelocityJ;
                collisionCount = collisionCount + 1;
            end
        end
    end
end

function [posSmall, velSmall, posBig, velBig, collisionCount, ...
    maximumMomentumError] = resolveSmallBigCollisions( ...
    posSmall, velSmall, posBig, velBig, m, M, r, R)
%RESOLVESMALLBIGCOLLISIONS Resolve elastic collisions with heavy particle.
% The returned error verifies pairwise conservation of vector momentum.

    numberParticles = size(posSmall,1);
    minimumDistance = r + R;
    collisionCount = 0;
    maximumMomentumError = 0;

    for i = 1:numberParticles
        separation = posSmall(i,:) - posBig;
        distance = norm(separation);

        if distance >= minimumDistance
            continue;
        end

        if distance <= eps
            randomAngle = 2*pi*rand;
            normal = [cos(randomAngle), sin(randomAngle)];
            distance = eps;
        else
            normal = separation/distance;
        end

        % Mass-weighted positional correction: the light particle moves most.
        overlap = minimumDistance - distance;
        posSmall(i,:) = posSmall(i,:) + ...
            overlap*(M/(m + M))*normal;
        posBig = posBig - overlap*(m/(m + M))*normal;

        relativeNormalVelocity = dot(velSmall(i,:) - velBig, normal);
        if relativeNormalVelocity >= 0
            continue;
        end

        momentumBefore = m*velSmall(i,:) + M*velBig;
        momentumScale = max( ...
            m*norm(velSmall(i,:)) + M*norm(velBig), eps);

        [newSmallVelocity, newBigVelocity] = elasticCollision( ...
            velSmall(i,:), velBig, m, M, normal);

        momentumAfter = m*newSmallVelocity + M*newBigVelocity;
        relativeMomentumError = norm(momentumAfter - momentumBefore) / ...
            momentumScale;

        maximumMomentumError = max(maximumMomentumError, ...
            relativeMomentumError);

        velSmall(i,:) = newSmallVelocity;
        velBig = newBigVelocity;
        collisionCount = collisionCount + 1;
    end
end

function [newVelocity1, newVelocity2] = elasticCollision( ...
    velocity1, velocity2, mass1, mass2, normal)
%ELASTICCOLLISION Perfectly elastic 2D collision along line of centres.
% Tangential velocity components remain unchanged.

    relativeNormalVelocity = dot(velocity1 - velocity2, normal);

    newVelocity1 = velocity1 - ...
        (2*mass2/(mass1 + mass2))*relativeNormalVelocity*normal;
    newVelocity2 = velocity2 + ...
        (2*mass1/(mass1 + mass2))*relativeNormalVelocity*normal;
end
