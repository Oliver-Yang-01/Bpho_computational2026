function H2plus_LCAO_Extension
% =========================================================================
%  TASK #10 EXTENSION: H2+ MOLECULAR ORBITALS
%  Linear Combination of Atomic Orbitals (LCAO) model for the one-electron
%  molecular ion H2+.
%
%  The program compares the normalized bonding and antibonding combinations
%       psi+ = N+ (phi_A + phi_B)
%       psi- = N- (phi_A - phi_B)
%  of two hydrogen 1s orbitals separated by an internuclear distance R.
%
%  The normalization is calculated from the overlap matrix
%       S_matrix = [1 S; S 1]
%       N = 1/sqrt(c' S_matrix c)
%  where
%       S(R) = exp(-R) (1 + R + R^2/3),       R in units of a0.
%
%  This model investigates molecular-orbital shape and interference only.
%  It deliberately does not calculate an energy-separation curve.
% =========================================================================

    delete(findall(0, 'Type', 'figure', 'Tag', 'H2plusLCAOApp'));

    % =====================================================================
    % CONSTANTS AND DEFAULTS
    % =====================================================================
    a0 = 0.529177210903;           % Bohr radius / Angstrom
    defaultR = 4.0;                % internuclear separation / a0
    defaultIso = 12;               % isosurface / percent of maximum density

    animationStop = false;
    animationRunning = false;

    % =====================================================================
    % MAIN FIGURE
    % =====================================================================
    fig = uifigure( ...
        'Name', 'H2+ Molecular Orbitals - LCAO Extension', ...
        'Tag', 'H2plusLCAOApp', ...
        'Position', [25 20 1480 900], ...
        'Color', [0.94 0.94 0.94]);

    mainGrid = uigridlayout(fig, [1 2]);
    mainGrid.ColumnWidth = {335, '1x'};
    mainGrid.Padding = [10 10 10 10];
    mainGrid.ColumnSpacing = 12;
    mainGrid.BackgroundColor = [0.94 0.94 0.94];

    % =====================================================================
    % LEFT PANEL - CONTROLS, THEORY AND VALIDATION
    % =====================================================================
    leftPanel = uipanel(mainGrid, ...
        'Title', '  H2+ LCAO CONTROL & THEORY PANEL', ...
        'FontName', 'Segoe UI', ...
        'FontSize', 13, ...
        'FontWeight', 'bold', ...
        'ForegroundColor', [0.1 0.1 0.1], ...
        'BackgroundColor', [0.96 0.96 0.96], ...
        'BorderType', 'line', ...
        'HighlightColor', [0.5 0.5 0.5]);

    leftGrid = uigridlayout(leftPanel, [10 1]);
    leftGrid.RowHeight = {64, 58, 58, 58, 34, 72, 92, 176, 146, 28};
    leftGrid.Padding = [8 8 8 8];
    leftGrid.RowSpacing = 4;
    leftGrid.BackgroundColor = [0.96 0.96 0.96];

    [grpR, lblR] = controlGroup(leftGrid, ...
        sprintf('Internuclear separation R = %.2f a0  (%.3f Angstrom)', ...
        defaultR, defaultR*a0));
    sldR = uislider(grpR, ...
        'Limits', [0.8 8.0], ...
        'Value', defaultR, ...
        'MajorTicks', [1 2 3 4 6 8], ...
        'MinorTicks', [], ...
        'FontColor', [0.2 0.2 0.2]);

    grpState = controlGroup(leftGrid, 'Molecular-orbital state');
    ddState = uidropdown(grpState, ...
        'Items', {'Bonding 1sigma_g', 'Antibonding 1sigma_u'}, ...
        'Value', 'Bonding 1sigma_g', ...
        'FontSize', 11);

    grpPlane = controlGroup(leftGrid, '2-D slice plane');
    ddPlane = uidropdown(grpPlane, ...
        'Items', {'xy (z=0)', 'xz (y=0)', 'yz (x=0)'}, ...
        'Value', 'xy (z=0)', ...
        'FontSize', 11);

    [grpIso, lblIso] = controlGroup(leftGrid, ...
        sprintf('3-D isosurface level: %.0f%% of maximum', defaultIso));
    sldIso = uislider(grpIso, ...
        'Limits', [2 30], ...
        'Value', defaultIso, ...
        'MajorTicks', [2 5 10 15 20 25 30], ...
        'MinorTicks', [], ...
        'FontColor', [0.2 0.2 0.2]);

    chkAtomic = uicheckbox(leftGrid, ...
        'Text', 'Show individual atomic-orbital contributions', ...
        'Value', true, ...
        'FontSize', 11, ...
        'FontWeight', 'bold', ...
        'FontColor', [0.1 0.1 0.1]);

    buttonGrid = uigridlayout(leftGrid, [2 2]);
    buttonGrid.RowHeight = {'1x', '1x'};
    buttonGrid.ColumnWidth = {'1x', '1x'};
    buttonGrid.Padding = [0 0 0 0];
    buttonGrid.RowSpacing = 5;
    buttonGrid.ColumnSpacing = 6;
    buttonGrid.BackgroundColor = [0.96 0.96 0.96];

    btnAnimate = uibutton(buttonGrid, ...
        'Text', 'Animate Approach', ...
        'FontWeight', 'bold', 'FontSize', 11, ...
        'BackgroundColor', [0.85 0.90 0.95], ...
        'FontColor', [0.1 0.2 0.4]);

    btnStop = uibutton(buttonGrid, ...
        'Text', 'Stop Animation', ...
        'FontWeight', 'bold', 'FontSize', 11, ...
        'BackgroundColor', [0.95 0.87 0.84], ...
        'FontColor', [0.4 0.1 0.05]);

    btnReset = uibutton(buttonGrid, ...
        'Text', 'Reset', ...
        'FontWeight', 'bold', 'FontSize', 11, ...
        'BackgroundColor', [0.85 0.92 0.85], ...
        'FontColor', [0.05 0.25 0.1]);

    btnExport = uibutton(buttonGrid, ...
        'Text', 'Export Current View', ...
        'FontWeight', 'bold', 'FontSize', 11, ...
        'BackgroundColor', [0.95 0.92 0.85], ...
        'FontColor', [0.3 0.2 0.05]);

    txtInfo = uitextarea(leftGrid, ...
        'Value', {'CURRENT STATE'}, ...
        'Editable', 'off', ...
        'FontName', 'Consolas', 'FontSize', 10, ...
        'FontColor', [0.1 0.1 0.1], ...
        'BackgroundColor', [1 1 1]);

    txtValidation = uitextarea(leftGrid, ...
        'Value', {'NUMERICAL VALIDATION'}, ...
        'Editable', 'off', ...
        'FontName', 'Consolas', 'FontSize', 10, ...
        'FontColor', [0.1 0.1 0.1], ...
        'BackgroundColor', [1 1 1]);

    txtTheory = uitextarea(leftGrid, ...
        'Value', { ...
            'KEY FORMULAE - H2+ LCAO', ...
            'phi_A,B = exp(-r_A,B/a0)/sqrt(pi a0^3)', ...
            'psi = N(c_A phi_A + c_B phi_B)', ...
            'S(R) = exp(-R)(1 + R + R^2/3)', ...
            'N = 1/sqrt(c^T S_matrix c)', ...
            '', ...
            'Bonding coefficients:      c = [1; 1]', ...
            'Antibonding coefficients:  c = [1;-1]', ...
            '', ...
            'No energy-separation curve is assumed.'}, ...
        'Editable', 'off', ...
        'FontName', 'Consolas', 'FontSize', 10, ...
        'FontColor', [0.15 0.15 0.15], ...
        'BackgroundColor', [1 1 1]);

    lblStatus = uilabel(leftGrid, ...
        'Text', 'Ready - adjust R or select a molecular-orbital state.', ...
        'FontSize', 10, ...
        'FontColor', [0.2 0.3 0.4], ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor', [0.92 0.92 0.92]);

    % =====================================================================
    % RIGHT PANEL - MOLECULAR VISUALISATIONS
    % =====================================================================
    rightPanel = uipanel(mainGrid, ...
        'Title', '  H2+ MOLECULAR ORBITAL  |  NORMALIZED LCAO MODEL', ...
        'FontName', 'Segoe UI', ...
        'FontSize', 13, ...
        'FontWeight', 'bold', ...
        'ForegroundColor', [0.1 0.1 0.1], ...
        'BackgroundColor', [0.96 0.96 0.96], ...
        'BorderType', 'line', ...
        'HighlightColor', [0.5 0.5 0.5]);

    rightGrid = uigridlayout(rightPanel, [2 2]);
    rightGrid.RowHeight = {'1x', 225};
    rightGrid.ColumnWidth = {'1x', '1x'};
    rightGrid.Padding = [8 8 8 8];
    rightGrid.RowSpacing = 10;
    rightGrid.ColumnSpacing = 10;
    rightGrid.BackgroundColor = [0.96 0.96 0.96];

    ax2D = uiaxes(rightGrid, ...
        'BackgroundColor', [1 1 1], ...
        'XColor', [0.2 0.2 0.2], ...
        'YColor', [0.2 0.2 0.2], ...
        'FontName', 'Segoe UI', 'FontSize', 10, ...
        'Box', 'on');
    ax2D.Layout.Row = 1;
    ax2D.Layout.Column = 1;
    axis(ax2D, 'equal');
    colormap(ax2D, jet(256));
    cb2D = colorbar(ax2D);
    cb2D.Label.String = '|psi|^2  (a_0^{-3})';

    ax3D = uiaxes(rightGrid, ...
        'BackgroundColor', [1 1 1], ...
        'XColor', [0.2 0.2 0.2], ...
        'YColor', [0.2 0.2 0.2], ...
        'ZColor', [0.2 0.2 0.2], ...
        'FontName', 'Segoe UI', 'FontSize', 10, ...
        'Box', 'on');
    ax3D.Layout.Row = 1;
    ax3D.Layout.Column = 2;
    view(ax3D, 35, 24);
    axis(ax3D, 'equal');
    grid(ax3D, 'on');
    cb3D = colorbar(ax3D);

    axBond = uiaxes(rightGrid, ...
        'BackgroundColor', [1 1 1], ...
        'XColor', [0.2 0.2 0.2], ...
        'YColor', [0.2 0.2 0.2], ...
        'FontName', 'Segoe UI', 'FontSize', 10, ...
        'Box', 'on', ...
        'GridColor', [0.75 0.75 0.75], ...
        'GridAlpha', 0.5);
    axBond.Layout.Row = 2;
    axBond.Layout.Column = [1 2];
    grid(axBond, 'on');

    % =====================================================================
    % SHARED HANDLES AND CALLBACKS
    % =====================================================================
    handles = struct( ...
        'fig', fig, ...
        'sldR', sldR, 'lblR', lblR, ...
        'sldIso', sldIso, 'lblIso', lblIso, ...
        'ddState', ddState, 'ddPlane', ddPlane, ...
        'chkAtomic', chkAtomic, ...
        'btnAnimate', btnAnimate, ...
        'txtInfo', txtInfo, 'txtValidation', txtValidation, ...
        'lblStatus', lblStatus, ...
        'ax2D', ax2D, 'ax3D', ax3D, 'axBond', axBond, ...
        'cb2D', cb2D, 'cb3D', cb3D);

    sldR.ValueChangingFcn = @(~,event) updateRLabel(event.Value);
    sldR.ValueChangedFcn = @(~,~) updateModel(true);
    sldIso.ValueChangingFcn = @(~,event) updateIsoLabel(event.Value);
    sldIso.ValueChangedFcn = @(~,~) updateModel(true);
    ddState.ValueChangedFcn = @(~,~) updateModel(true);
    ddPlane.ValueChangedFcn = @(~,~) updateModel(true);
    chkAtomic.ValueChangedFcn = @(~,~) updateModel(true);
    btnAnimate.ButtonPushedFcn = @(~,~) animateApproach();
    btnStop.ButtonPushedFcn = @(~,~) stopAnimation();
    btnReset.ButtonPushedFcn = @(~,~) resetApplication();
    btnExport.ButtonPushedFcn = @(~,~) exportView();

    updateModel(true);

    % =====================================================================
    % INTERFACE HELPERS
    % =====================================================================
    function [group, label] = controlGroup(parent, labelText)
        group = uigridlayout(parent, [2 1]);
        group.RowHeight = {22, '1x'};
        group.Padding = [0 0 0 0];
        group.RowSpacing = 1;
        group.BackgroundColor = [0.96 0.96 0.96];
        label = uilabel(group, ...
            'Text', labelText, ...
            'FontSize', 11, ...
            'FontWeight', 'bold', ...
            'FontColor', [0.1 0.1 0.1], ...
            'HorizontalAlignment', 'center');
    end

    function updateRLabel(value)
        handles.lblR.Text = sprintf( ...
            'Internuclear separation R = %.2f a0  (%.3f Angstrom)', ...
            value, value*a0);
    end

    function updateIsoLabel(value)
        handles.lblIso.Text = sprintf( ...
            '3-D isosurface level: %.0f%% of maximum', value);
    end

    % =====================================================================
    % MAIN MODEL UPDATE
    % =====================================================================
    function updateModel(highQuality)
        if ~isvalid(handles.fig)
            return;
        end

        separation = handles.sldR.Value;
        isoPercent = handles.sldIso.Value;
        state = handles.ddState.Value;
        updateRLabel(separation);
        updateIsoLabel(isoPercent);

        [coefficients, parity, stateName, stateSymbol] = stateDefinition(state);
        overlap = overlap1s(separation);
        overlapMatrix = [1 overlap; overlap 1];
        normalization = 1 / sqrt(coefficients' * overlapMatrix * coefficients);

        extentAu = separation/2 + 6.5;
        if highQuality
            gridPoints3D = 80;
            gridPoints2D = 250;
        else
            gridPoints3D = 48;
            gridPoints2D = 150;
        end

        handles.txtInfo.Value = { ...
            'CURRENT STATE', ...
            'System: H2+ (two protons, one electron)', ...
            sprintf('State: %s', stateName), ...
            sprintf('R = %.3f a0 = %.3f Angstrom', separation, separation*a0), ...
            sprintf('Coefficient vector c = [%+d; %+d]', ...
                coefficients(1), coefficients(2)), ...
            sprintf('Overlap S(R) = %.7f', overlap), ...
            sprintf('Normalization N = %.7f', normalization)};

        handles.lblStatus.Text = sprintf( ...
            'Rendering %s at R = %.2f a0 ...', stateName, separation);
        drawnow;

        try
            plot2DSlice(separation, coefficients, normalization, ...
                stateName, gridPoints2D, extentAu);

            validation = plot3DOrbital(separation, coefficients, ...
                normalization, stateName, stateSymbol, parity, ...
                gridPoints3D, extentAu, isoPercent);

            plotBondAxis(separation, coefficients, normalization, ...
                stateName, extentAu);

            analyticNorm = normalization^2 * ...
                (coefficients' * overlapMatrix * coefficients);
            gridError = abs(validation.numericNorm - 1);
            if gridError < 0.02
                gridResult = 'PASS';
            else
                gridResult = 'CHECK';
            end
            if validation.symmetryError < 1e-12
                symmetryResult = 'PASS';
            else
                symmetryResult = 'CHECK';
            end

            if parity < 0
                nodeValue = abs(validation.midpointPsi);
                if nodeValue < 1e-12
                    nodeResult = 'PASS';
                else
                    nodeResult = 'CHECK';
                end
                interferenceText = sprintf( ...
                    'Midpoint node |psi(0)| = %.3e  [%s]', ...
                    nodeValue, nodeResult);
            else
                interferenceText = sprintf( ...
                    'Midpoint density |psi(0)|^2 = %.6f a0^-3', ...
                    abs(validation.midpointPsi)^2);
            end

            handles.txtValidation.Value = { ...
                'NUMERICAL VALIDATION', ...
                sprintf('Analytic normalization = %.10f  [PASS]', analyticNorm), ...
                sprintf('Cartesian-grid integral = %.7f  [%s]', ...
                    validation.numericNorm, gridResult), ...
                sprintf('Finite-grid error = %.3e', gridError), ...
                sprintf('Exchange symmetry error = %.3e  [%s]', ...
                    validation.symmetryError, symmetryResult), ...
                interferenceText, ...
                sprintf('Large-R limit: S -> 0; current S = %.3e', overlap), ...
                sprintf('Isosurface = %.1f%% of maximum density', isoPercent)};

            handles.lblStatus.Text = sprintf( ...
                'Ready - %s  |  R = %.2f a0  |  grid norm %.5f', ...
                stateName, separation, validation.numericNorm);
        catch ME
            handles.lblStatus.Text = 'Rendering failed - see error dialog.';
            uialert(handles.fig, ME.message, 'H2+ rendering error');
        end
    end

    % =====================================================================
    % 2-D PROBABILITY-DENSITY SLICE
    % =====================================================================
    function plot2DSlice(separation, coefficients, normalization, ...
            stateName, pointCount, extentAu)

        extentAngstrom = extentAu * a0;
        coordinate = linspace(-extentAngstrom, extentAngstrom, pointCount);
        [U, V] = meshgrid(coordinate, coordinate);

        switch handles.ddPlane.Value
            case 'xy (z=0)'
                X = U; Y = V; Zgrid = zeros(size(U));
                xText = 'x / Angstrom'; yText = 'y / Angstrom';
                planeText = 'z=0 plane (molecular axis in plane)';
                nucleusA = [-separation*a0/2, 0];
                nucleusB = [ separation*a0/2, 0];
                showNuclei = true;
            case 'xz (y=0)'
                X = U; Y = zeros(size(U)); Zgrid = V;
                xText = 'x / Angstrom'; yText = 'z / Angstrom';
                planeText = 'y=0 plane (molecular axis in plane)';
                nucleusA = [-separation*a0/2, 0];
                nucleusB = [ separation*a0/2, 0];
                showNuclei = true;
            otherwise
                X = zeros(size(U)); Y = U; Zgrid = V;
                xText = 'y / Angstrom'; yText = 'z / Angstrom';
                planeText = 'x=0 plane (perpendicular bisector)';
                nucleusA = [0, 0]; nucleusB = [0, 0];
                showNuclei = false;
        end

        [psi, phiA, phiB] = molecularWavefunction( ...
            X, Y, Zgrid, separation, coefficients, normalization);
        density = abs(psi).^2;

        cla(handles.ax2D);
        imagesc(handles.ax2D, coordinate, coordinate, density);
        set(handles.ax2D, 'YDir', 'normal');
        axis(handles.ax2D, 'equal', 'tight');
        colormap(handles.ax2D, jet(256));
        hold(handles.ax2D, 'on');

        if handles.chkAtomic.Value
            atomicMaximum = max([abs(phiA(:)).^2; abs(phiB(:)).^2]);
            if atomicMaximum > 0
                contourLevels = atomicMaximum * [0.08 0.25 0.55];
                contour(handles.ax2D, U, V, abs(phiA).^2, contourLevels, ...
                    '--', 'Color', [0.1 0.1 0.1], 'LineWidth', 0.9);
                contour(handles.ax2D, U, V, abs(phiB).^2, contourLevels, ...
                    ':', 'Color', [1 1 1], 'LineWidth', 1.1);
            end
        end

        if showNuclei
            plot(handles.ax2D, nucleusA(1), nucleusA(2), 'wo', ...
                'MarkerFaceColor', [0.18 0.18 0.18], ...
                'MarkerSize', 7, 'LineWidth', 1.2);
            plot(handles.ax2D, nucleusB(1), nucleusB(2), 'wo', ...
                'MarkerFaceColor', [0.18 0.18 0.18], ...
                'MarkerSize', 7, 'LineWidth', 1.2);
        end

        xlabel(handles.ax2D, xText, 'Color', [0.2 0.2 0.2]);
        ylabel(handles.ax2D, yText, 'Color', [0.2 0.2 0.2]);
        title(handles.ax2D, sprintf('%s  |  %s', planeText, stateName), ...
            'Color', [0.1 0.1 0.1], ...
            'FontSize', 11, 'FontWeight', 'bold');
        handles.cb2D.Label.String = '|psi|^2  (a_0^{-3})';
        hold(handles.ax2D, 'off');
    end

    % =====================================================================
    % 3-D MOLECULAR ISOSURFACE AND GRID VALIDATION
    % =====================================================================
    function validation = plot3DOrbital(separation, coefficients, ...
            normalization, stateName, stateSymbol, parity, ...
            pointCount, extentAu, isoPercent)

        extentAngstrom = extentAu * a0;
        coordinate = linspace(-extentAngstrom, extentAngstrom, pointCount);
        [X, Y, Zgrid] = meshgrid(coordinate, coordinate, coordinate);

        [psi, phiA, phiB] = molecularWavefunction( ...
            X, Y, Zgrid, separation, coefficients, normalization);
        density = abs(psi).^2;
        maximumDensity = max(density(:));
        isoLevel = (isoPercent/100) * maximumDensity;

        surfaceData = isosurface(X, Y, Zgrid, density, isoLevel);
        if isempty(surfaceData.vertices)
            error('No molecular isosurface was found at this density level.');
        end

        cla(handles.ax3D);
        hold(handles.ax3D, 'on');

        if handles.chkAtomic.Value
            drawAtomicSurface(X, Y, Zgrid, abs(phiA).^2, ...
                [0.25 0.55 0.85], 0.10);
            drawAtomicSurface(X, Y, Zgrid, abs(phiB).^2, ...
                [0.35 0.70 0.45], 0.10);
        end

        molecularPatch = patch(handles.ax3D, surfaceData);
        molecularPatch.EdgeColor = 'none';
        molecularPatch.FaceAlpha = 0.84;

        vertices = surfaceData.vertices;
        vertexPsi = molecularWavefunction( ...
            vertices(:,1), vertices(:,2), vertices(:,3), ...
            separation, coefficients, normalization);
        signData = sign(real(vertexPsi));
        signData(signData == 0) = 1;
        molecularPatch.FaceVertexCData = signData;
        molecularPatch.FaceColor = 'interp';
        colormap(handles.ax3D, blueWhiteRed(256));
        caxis(handles.ax3D, [-1 1]);
        handles.cb3D.Ticks = [-1 1];
        handles.cb3D.TickLabels = {'negative', 'positive'};
        handles.cb3D.Label.String = 'sign of psi';

        isonormals(X, Y, Zgrid, density, molecularPatch);

        nucleusX = [-separation separation] * a0/2;
        scatter3(handles.ax3D, nucleusX, [0 0], [0 0], 65, ...
            [0.20 0.20 0.20; 0.20 0.20 0.20], ...
            'filled', 'MarkerEdgeColor', [0.05 0.05 0.05]);
        text(handles.ax3D, nucleusX(1), 0, 0, '  A', ...
            'Color', [0.1 0.1 0.1], 'FontWeight', 'bold');
        text(handles.ax3D, nucleusX(2), 0, 0, '  B', ...
            'Color', [0.1 0.1 0.1], 'FontWeight', 'bold');

        camlight(handles.ax3D, 'headlight');
        lighting(handles.ax3D, 'gouraud');
        axis(handles.ax3D, 'equal');
        xlim(handles.ax3D, [-extentAngstrom extentAngstrom]);
        ylim(handles.ax3D, [-extentAngstrom extentAngstrom]);
        zlim(handles.ax3D, [-extentAngstrom extentAngstrom]);
        xlabel(handles.ax3D, 'x / Angstrom');
        ylabel(handles.ax3D, 'y / Angstrom');
        zlabel(handles.ax3D, 'z / Angstrom');
        title(handles.ax3D, sprintf( ...
            '3-D %s  |  %s  |  R = %.2f a_0', ...
            stateSymbol, stateName, separation), ...
            'Color', [0.1 0.1 0.1], ...
            'FontSize', 11, 'FontWeight', 'bold');
        view(handles.ax3D, 35, 24);
        grid(handles.ax3D, 'on');
        hold(handles.ax3D, 'off');

        stepAu = (2*extentAu)/(pointCount - 1);
        validation.numericNorm = sum(density(:)) * stepAu^3;

        swappedPsi = normalization * ...
            (coefficients(1)*phiB + coefficients(2)*phiA);
        scale = max(abs(psi(:)));
        validation.symmetryError = max(abs(swappedPsi(:) - parity*psi(:))) / scale;

        validation.midpointPsi = molecularWavefunction( ...
            0, 0, 0, separation, coefficients, normalization);
    end

    function drawAtomicSurface(X, Y, Zgrid, atomicDensity, colour, alpha)
        atomicLevel = 0.16 * max(atomicDensity(:));
        atomicSurface = isosurface(X, Y, Zgrid, atomicDensity, atomicLevel);
        if isempty(atomicSurface.vertices)
            return;
        end
        atomicPatch = patch(handles.ax3D, atomicSurface);
        atomicPatch.FaceColor = colour;
        atomicPatch.EdgeColor = 'none';
        atomicPatch.FaceAlpha = alpha;
    end

    % =====================================================================
    % DENSITY ALONG THE INTERNUCLEAR AXIS
    % =====================================================================
    function plotBondAxis(separation, coefficients, normalization, ...
            stateName, extentAu)

        xAu = linspace(-extentAu, extentAu, 900);
        xAngstrom = xAu * a0;
        [psi, phiA, phiB] = molecularWavefunction( ...
            xAngstrom, zeros(size(xAu)), zeros(size(xAu)), ...
            separation, coefficients, normalization);
        density = abs(psi).^2;

        cla(handles.axBond);
        hold(handles.axBond, 'on');
        plot(handles.axBond, xAu, density, ...
            'Color', [0.15 0.45 0.75], ...
            'LineWidth', 2.2, ...
            'DisplayName', 'Molecular density |psi|^2');

        if handles.chkAtomic.Value
            plot(handles.axBond, xAu, abs(phiA).^2, '--', ...
                'Color', [0.2 0.55 0.25], ...
                'LineWidth', 1.2, ...
                'DisplayName', '|phi_A|^2');
            plot(handles.axBond, xAu, abs(phiB).^2, ':', ...
                'Color', [0.75 0.35 0.15], ...
                'LineWidth', 1.5, ...
                'DisplayName', '|phi_B|^2');
        end

        xline(handles.axBond, -separation/2, '-', 'Nucleus A', ...
            'Color', [0.35 0.35 0.35], ...
            'LineWidth', 1.1, ...
            'LabelVerticalAlignment', 'bottom', ...
            'HandleVisibility', 'off');
        xline(handles.axBond, separation/2, '-', 'Nucleus B', ...
            'Color', [0.35 0.35 0.35], ...
            'LineWidth', 1.1, ...
            'LabelVerticalAlignment', 'bottom', ...
            'HandleVisibility', 'off');
        xline(handles.axBond, 0, ':', 'Midpoint', ...
            'Color', [0.55 0.15 0.15], ...
            'LineWidth', 1.0, ...
            'HandleVisibility', 'off');

        xlabel(handles.axBond, 'Position along molecular axis  x/a_0');
        ylabel(handles.axBond, 'Probability density  (a_0^{-3})');
        title(handles.axBond, sprintf( ...
            'Density along the internuclear axis  |  %s', stateName), ...
            'Color', [0.1 0.1 0.1], ...
            'FontSize', 11, 'FontWeight', 'bold');
        legend(handles.axBond, 'Location', 'northeast', 'FontSize', 9);
        grid(handles.axBond, 'on');
        hold(handles.axBond, 'off');
    end

    % =====================================================================
    % LCAO WAVEFUNCTION AND OVERLAP MATRIX
    % =====================================================================
    function [psi, phiA, phiB] = molecularWavefunction( ...
            xAngstrom, yAngstrom, zAngstrom, ...
            separation, coefficients, normalization)

        xAu = xAngstrom / a0;
        yAu = yAngstrom / a0;
        zAu = zAngstrom / a0;

        radiusA = sqrt((xAu + separation/2).^2 + yAu.^2 + zAu.^2);
        radiusB = sqrt((xAu - separation/2).^2 + yAu.^2 + zAu.^2);

        phiA = exp(-radiusA) / sqrt(pi);
        phiB = exp(-radiusB) / sqrt(pi);
        psi = normalization * ...
            (coefficients(1)*phiA + coefficients(2)*phiB);
    end

    function overlap = overlap1s(separation)
        overlap = exp(-separation) * ...
            (1 + separation + separation^2/3);
    end

    function [coefficients, parity, stateName, stateSymbol] = ...
            stateDefinition(state)
        if strcmp(state, 'Bonding 1sigma_g')
            coefficients = [1; 1];
            parity = 1;
            stateName = 'Bonding 1sigma_g';
            stateSymbol = '1\sigma_g';
        else
            coefficients = [1; -1];
            parity = -1;
            stateName = 'Antibonding 1sigma_u';
            stateSymbol = '1\sigma_u';
        end
    end

    % =====================================================================
    % ANIMATION, RESET AND EXPORT
    % =====================================================================
    function animateApproach()
        if animationRunning
            return;
        end

        animationRunning = true;
        animationStop = false;
        handles.btnAnimate.Enable = 'off';
        handles.lblStatus.Text = ...
            'Animation: nuclei approaching from R = 7.5 a0 to R = 1.2 a0.';

        approachValues = linspace(7.5, 1.2, 28);
        for index = 1:numel(approachValues)
            if animationStop || ~isvalid(handles.fig)
                break;
            end
            handles.sldR.Value = approachValues(index);
            updateModel(false);
            drawnow;
        end

        if isvalid(handles.fig)
            animationRunning = false;
            handles.btnAnimate.Enable = 'on';
            updateModel(true);
            if animationStop
                handles.lblStatus.Text = 'Approach animation stopped.';
            else
                handles.lblStatus.Text = ...
                    'Approach animation complete - final high-resolution view rendered.';
            end
        end
    end

    function stopAnimation()
        animationStop = true;
    end

    function resetApplication()
        animationStop = true;
        handles.sldR.Value = defaultR;
        handles.sldIso.Value = defaultIso;
        handles.ddState.Value = 'Bonding 1sigma_g';
        handles.ddPlane.Value = 'xy (z=0)';
        handles.chkAtomic.Value = true;
        updateModel(true);
    end

    function exportView()
        suggestedName = sprintf('H2plus_%s_R%.2fa0.png', ...
            strrep(handles.ddState.Value, ' ', '_'), handles.sldR.Value);
        [file, path] = uiputfile('*.png', ...
            'Export current H2+ application view', suggestedName);

        if isequal(file, 0)
            handles.lblStatus.Text = 'Export cancelled.';
            return;
        end

        try
            exportapp(handles.fig, fullfile(path, file));
            handles.lblStatus.Text = sprintf('Exported current view -> %s', file);
        catch ME
            uialert(handles.fig, ME.message, 'Export error');
            handles.lblStatus.Text = 'Export failed.';
        end
    end

    function map = blueWhiteRed(numberOfColours)
        half = floor(numberOfColours/2);
        lower = [linspace(0.15,1,half)', ...
                 linspace(0.35,1,half)', ...
                 ones(half,1)];
        upperCount = numberOfColours - half;
        upper = [ones(upperCount,1), ...
                 linspace(1,0.25,upperCount)', ...
                 linspace(1,0.2,upperCount)'];
        map = [lower; upper];
    end

end
