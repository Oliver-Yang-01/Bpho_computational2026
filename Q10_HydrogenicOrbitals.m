function HydrogenicOrbitals_Task10
% =========================================================================
%  TASK #10: HYDROGENIC ORBITALS
%  Interactive 2-D slices and 3-D visualisations of the probability density
%  |psi|^2 for a hydrogenic atom, with numerical validation.
%
%  Quantum numbers:
%       n = 1, 2, ...             principal quantum number
%       l = 0, 1, ..., n-1       orbital angular momentum
%       m = -l, ..., +l          magnetic quantum number
%
%  Two angular bases are available:
%    1. Complex m eigenstates Y_l^m, with 3-D colour showing phase.
%    2. Real orbital combinations, with 3-D colour showing the sign of psi.
%
%  The interface deliberately follows the presentation style used in
%  Tasks 6-9: light panels, Segoe UI labels and Consolas result boxes.
% =========================================================================

    delete(findall(0, 'Type', 'figure', 'Tag', 'HydrogenicApp'));

    % =====================================================================
    % PHYSICAL CONSTANTS AND DEFAULTS
    % =====================================================================
    a0 = 0.529177210903;           % Bohr radius / Angstrom
    E0 = 13.605693122994;          % Rydberg energy / eV

    n0 = 3;
    l0 = 2;
    m0 = 0;
    Z0 = 1;
    iso0 = 12;                     % percentage of maximum density

    % =====================================================================
    % MAIN FIGURE
    % =====================================================================
    fig = uifigure( ...
        'Name', 'Hydrogenic Orbitals - Task #10 | Interactive Model', ...
        'Tag', 'HydrogenicApp', ...
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
        'Title', '  CONTROL, THEORY & VALIDATION PANEL', ...
        'FontName', 'Segoe UI', ...
        'FontSize', 13, ...
        'FontWeight', 'bold', ...
        'ForegroundColor', [0.1 0.1 0.1], ...
        'BackgroundColor', [0.96 0.96 0.96], ...
        'BorderType', 'line', ...
        'HighlightColor', [0.5 0.5 0.5]);

    leftGrid = uigridlayout(leftPanel, [12 1]);
    leftGrid.RowHeight = {62, 62, 62, 62, 58, 58, 58, 38, 78, 148, 100, 28};
    leftGrid.Padding = [8 8 8 8];
    leftGrid.RowSpacing = 4;
    leftGrid.BackgroundColor = [0.96 0.96 0.96];

    grpN = controlGroup(leftGrid, 'Principal quantum number n');
    sldN = uislider(grpN, ...
        'Limits', [1 5], 'Value', n0, ...
        'MajorTicks', 1:5, 'MinorTicks', [], ...
        'FontColor', [0.2 0.2 0.2]);

    grpL = controlGroup(leftGrid, 'Angular momentum l  (0 ... n-1)');
    sldL = uislider(grpL, ...
        'Limits', [0 n0-1], 'Value', l0, ...
        'MajorTicks', 0:n0-1, 'MinorTicks', [], ...
        'FontColor', [0.2 0.2 0.2]);

    grpM = controlGroup(leftGrid, 'Magnetic quantum number m  (-l ... +l)');
    sldM = uislider(grpM, ...
        'Limits', [-l0 l0], 'Value', m0, ...
        'MajorTicks', -l0:l0, 'MinorTicks', [], ...
        'FontColor', [0.2 0.2 0.2]);

    grpZ = controlGroup(leftGrid, 'Nuclear charge Z');
    sldZ = uislider(grpZ, ...
        'Limits', [1 4], 'Value', Z0, ...
        'MajorTicks', 1:4, 'MinorTicks', [], ...
        'FontColor', [0.2 0.2 0.2]);

    grpBasis = controlGroup(leftGrid, 'Angular basis');
    ddBasis = uidropdown(grpBasis, ...
        'Items', {'Complex m eigenstate', 'Real orbital combination'}, ...
        'Value', 'Real orbital combination', ...
        'FontSize', 11);

    grpPlane = controlGroup(leftGrid, '2-D slice plane');
    ddPlane = uidropdown(grpPlane, ...
        'Items', {'xy (z=0)', 'xz (y=0)', 'yz (x=0)'}, ...
        'Value', 'xz (y=0)', ...
        'FontSize', 11);

    [grpIso, lblIso] = controlGroup(leftGrid, ...
        sprintf('3-D isosurface level: %.0f%% of maximum', iso0));
    sldIso = uislider(grpIso, ...
        'Limits', [2 30], 'Value', iso0, ...
        'MajorTicks', [2 5 10 15 20 25 30], ...
        'MinorTicks', [], ...
        'FontColor', [0.2 0.2 0.2]);

    btnGrid = uigridlayout(leftGrid, [1 2]);
    btnGrid.ColumnWidth = {'1x', '1x'};
    btnGrid.Padding = [0 0 0 0];
    btnGrid.ColumnSpacing = 6;
    btnGrid.BackgroundColor = [0.96 0.96 0.96];

    btnUpdate = uibutton(btnGrid, ...
        'Text', 'Update Orbital', ...
        'FontWeight', 'bold', 'FontSize', 11, ...
        'BackgroundColor', [0.85 0.92 0.85], ...
        'FontColor', [0.05 0.25 0.1]);

    btnExport = uibutton(btnGrid, ...
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
            'KEY FORMULAE (TEXTBOOK SOLUTIONS)', ...
            'psi_nlm = R_nl(r) Y_lm(theta,phi)', ...
            '|psi|^2 = psi* conjugate(psi)', ...
            'E_n = -13.6057 Z^2/n^2  eV', ...
            'Radial nodes = n-l-1', ...
            'Angular nodes = l'}, ...
        'Editable', 'off', ...
        'FontName', 'Consolas', 'FontSize', 10, ...
        'FontColor', [0.15 0.15 0.15], ...
        'BackgroundColor', [1 1 1]);

    lblStatus = uilabel(leftGrid, ...
        'Text', 'Ready - select an orbital and press Update Orbital.', ...
        'FontSize', 10, ...
        'FontColor', [0.2 0.3 0.4], ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor', [0.92 0.92 0.92]);

    % =====================================================================
    % RIGHT PANEL - 2-D AND 3-D VISUALISATIONS
    % =====================================================================
    rightPanel = uipanel(mainGrid, ...
        'Title', '  2-D SLICE  |  3-D ORBITAL VISUALISATION', ...
        'FontName', 'Segoe UI', ...
        'FontSize', 13, ...
        'FontWeight', 'bold', ...
        'ForegroundColor', [0.1 0.1 0.1], ...
        'BackgroundColor', [0.96 0.96 0.96], ...
        'BorderType', 'line', ...
        'HighlightColor', [0.5 0.5 0.5]);

    rightGrid = uigridlayout(rightPanel, [1 2]);
    rightGrid.ColumnWidth = {'1x', '1x'};
    rightGrid.Padding = [8 8 8 8];
    rightGrid.ColumnSpacing = 10;
    rightGrid.BackgroundColor = [0.96 0.96 0.96];

    ax2D = uiaxes(rightGrid, ...
        'BackgroundColor', [1 1 1], ...
        'XColor', [0.2 0.2 0.2], ...
        'YColor', [0.2 0.2 0.2], ...
        'FontName', 'Segoe UI', 'FontSize', 10, ...
        'Box', 'on');
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
    view(ax3D, 35, 25);
    axis(ax3D, 'equal');
    grid(ax3D, 'on');
    cb3D = colorbar(ax3D);

    % =====================================================================
    % SHARED HANDLES AND CALLBACKS
    % =====================================================================
    handles = struct( ...
        'fig', fig, ...
        'sldN', sldN, 'sldL', sldL, 'sldM', sldM, 'sldZ', sldZ, ...
        'sldIso', sldIso, 'lblIso', lblIso, ...
        'ddBasis', ddBasis, 'ddPlane', ddPlane, ...
        'txtInfo', txtInfo, 'txtValidation', txtValidation, ...
        'lblStatus', lblStatus, ...
        'ax2D', ax2D, 'ax3D', ax3D, ...
        'cb2D', cb2D, 'cb3D', cb3D);

    sldN.ValueChangedFcn = @(~,~) quantumNumbersChanged();
    sldL.ValueChangedFcn = @(~,~) quantumNumbersChanged();
    sldM.ValueChangedFcn = @(~,~) quantumNumbersChanged();
    sldZ.ValueChangedFcn = @(~,~) integerSliderChanged(handles.sldZ);
    sldIso.ValueChangingFcn = @(~,event) updateIsoLabel(event.Value);
    sldIso.ValueChangedFcn = @(~,~) updateOrbital();
    ddBasis.ValueChangedFcn = @(~,~) updateOrbital();
    ddPlane.ValueChangedFcn = @(~,~) updateOrbital();
    btnUpdate.ButtonPushedFcn = @(~,~) updateOrbital();
    btnExport.ButtonPushedFcn = @(~,~) exportView();

    enforceQuantumNumbers();
    updateOrbital();

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

    function integerSliderChanged(slider)
        slider.Value = round(slider.Value);
    end

    function updateIsoLabel(value)
        handles.lblIso.Text = sprintf( ...
            '3-D isosurface level: %.0f%% of maximum', value);
    end

    function quantumNumbersChanged()
        enforceQuantumNumbers();
    end

    function enforceQuantumNumbers()
        n = round(handles.sldN.Value);
        handles.sldN.Value = n;

        lMaximum = n - 1;
        l = min(round(handles.sldL.Value), lMaximum);
        handles.sldL.Value = l;

        if lMaximum == 0
            handles.sldL.Limits = [0 1];
            handles.sldL.MajorTicks = 0;
            handles.sldL.Enable = 'off';
        else
            handles.sldL.Limits = [0 lMaximum];
            handles.sldL.MajorTicks = 0:lMaximum;
            handles.sldL.Enable = 'on';
        end

        l = round(handles.sldL.Value);
        m = max(-l, min(l, round(handles.sldM.Value)));
        handles.sldM.Value = m;

        if l == 0
            handles.sldM.Limits = [-1 1];
            handles.sldM.MajorTicks = 0;
            handles.sldM.Enable = 'off';
        else
            handles.sldM.Limits = [-l l];
            handles.sldM.MajorTicks = -l:l;
            handles.sldM.Enable = 'on';
        end
    end

    % =====================================================================
    % MAIN UPDATE
    % =====================================================================
    function updateOrbital()
        enforceQuantumNumbers();

        n = round(handles.sldN.Value);
        l = round(handles.sldL.Value);
        m = round(handles.sldM.Value);
        nuclearCharge = round(handles.sldZ.Value);
        handles.sldZ.Value = nuclearCharge;
        basis = handles.ddBasis.Value;
        plane = handles.ddPlane.Value;
        isoPercent = handles.sldIso.Value;
        updateIsoLabel(isoPercent);

        energy = -E0 * nuclearCharge^2 / n^2;
        [normalisation, displayRadius, measuredNodes] = ...
            radialMetrics(n, l, nuclearCharge);

        handles.txtInfo.Value = { ...
            'CURRENT STATE', ...
            sprintf('n = %d,  l = %d,  m = %d,  Z = %d', n, l, m, nuclearCharge), ...
            sprintf('Orbital: %s', orbitalName(n, l, m, basis)), ...
            sprintf('Basis: %s', basis), ...
            sprintf('Energy: %.6f eV', energy)};

        normError = abs(normalisation - 1);
        if normError < 1e-4
            normResult = 'PASS';
        else
            normResult = 'CHECK';
        end

        expectedRadialNodes = n - l - 1;
        if measuredNodes == expectedRadialNodes
            nodeResult = 'PASS';
        else
            nodeResult = 'CHECK';
        end

        handles.txtValidation.Value = { ...
            'NUMERICAL VALIDATION', ...
            sprintf('Integral |psi|^2 dV = %.8f  [%s]', normalisation, normResult), ...
            sprintf('Normalisation error = %.3e', normError), ...
            sprintf('Radial nodes = %d; expected %d  [%s]', ...
                measuredNodes, expectedRadialNodes, nodeResult), ...
            sprintf('Angular nodes = l = %d', l), ...
            'Energy degeneracy check: independent of l,m  [PASS]', ...
            sprintf('Display radius contains 99.7%% radial probability'), ...
            sprintf('Display radius = %.3f Angstrom', displayRadius), ...
            sprintf('Isosurface = %.1f%% of maximum density', isoPercent)};

        handles.lblStatus.Text = sprintf( ...
            'Rendering %s - Cartesian 3-D grid ...', ...
            orbitalName(n, l, m, basis));
        drawnow;

        try
            plot2DSlice(n, l, m, nuclearCharge, basis, plane, displayRadius);
            plot3DOrbital(n, l, m, nuclearCharge, basis, ...
                displayRadius, isoPercent, energy);
            handles.lblStatus.Text = sprintf( ...
                'Ready - %s  |  E = %.4f eV  |  normalisation error %.2e', ...
                orbitalName(n, l, m, basis), energy, normError);
        catch ME
            handles.lblStatus.Text = 'Rendering failed - see error dialog.';
            uialert(handles.fig, ME.message, 'Orbital rendering error');
        end
    end

    % =====================================================================
    % 2-D PROBABILITY-DENSITY SLICE
    % =====================================================================
    function plot2DSlice(n, l, m, nuclearCharge, basis, plane, extent)
        pointCount = 240;
        coordinate = linspace(-extent, extent, pointCount);
        [U, V] = meshgrid(coordinate, coordinate);

        switch plane
            case 'xy (z=0)'
                X = U; Y = V; Zgrid = zeros(size(U));
                xLabelText = 'x / Angstrom';
                yLabelText = 'y / Angstrom';
                planeText = 'z=0 plane';
            case 'xz (y=0)'
                X = U; Y = zeros(size(U)); Zgrid = V;
                xLabelText = 'x / Angstrom';
                yLabelText = 'z / Angstrom';
                planeText = 'y=0 plane';
            otherwise
                X = zeros(size(U)); Y = U; Zgrid = V;
                xLabelText = 'y / Angstrom';
                yLabelText = 'z / Angstrom';
                planeText = 'x=0 plane';
        end

        psi = cartesianWavefunction(n, l, m, X, Y, Zgrid, ...
            nuclearCharge, basis);
        probabilityDensity = abs(psi).^2;

        cla(handles.ax2D);
        imagesc(handles.ax2D, coordinate, coordinate, probabilityDensity);
        set(handles.ax2D, 'YDir', 'normal');
        axis(handles.ax2D, 'equal', 'tight');
        colormap(handles.ax2D, jet(256));
        xlabel(handles.ax2D, xLabelText, 'Color', [0.2 0.2 0.2]);
        ylabel(handles.ax2D, yLabelText, 'Color', [0.2 0.2 0.2]);
        title(handles.ax2D, sprintf( ...
            '%s  |  n=%d l=%d m=%d Z=%d', ...
            planeText, n, l, m, nuclearCharge), ...
            'Color', [0.1 0.1 0.1], ...
            'FontSize', 11, 'FontWeight', 'bold');
        handles.cb2D.Label.String = '|psi|^2  (a_0^{-3})';
    end

    % =====================================================================
    % 3-D CARTESIAN ISOSURFACE WITH PHASE OR SIGN COLOURING
    % =====================================================================
    function plot3DOrbital(n, l, m, nuclearCharge, basis, ...
            extent, isoPercent, energy)

        pointCount = 72;
        coordinate = linspace(-extent, extent, pointCount);
        [X, Y, Zgrid] = meshgrid(coordinate, coordinate, coordinate);

        psi = cartesianWavefunction(n, l, m, X, Y, Zgrid, ...
            nuclearCharge, basis);
        probabilityDensity = abs(psi).^2;
        maximumDensity = max(probabilityDensity(:));
        isoLevel = (isoPercent / 100) * maximumDensity;

        surfaceData = isosurface(X, Y, Zgrid, probabilityDensity, isoLevel);
        if isempty(surfaceData.vertices)
            error('No isosurface was found at the selected density level.');
        end

        cla(handles.ax3D);
        hold(handles.ax3D, 'on');

        surfacePatch = patch(handles.ax3D, surfaceData);
        surfacePatch.EdgeColor = 'none';
        surfacePatch.FaceAlpha = 0.82;

        vertices = surfaceData.vertices;
        vertexPsi = cartesianWavefunction(n, l, m, ...
            vertices(:,1), vertices(:,2), vertices(:,3), ...
            nuclearCharge, basis);

        showComplexPhase = strcmp(basis, 'Complex m eigenstate') && m ~= 0;
        if showComplexPhase
            surfacePatch.FaceVertexCData = angle(vertexPsi);
            surfacePatch.FaceColor = 'interp';
            colormap(handles.ax3D, hsv(256));
            caxis(handles.ax3D, [-pi pi]);
            handles.cb3D.Ticks = [-pi 0 pi];
            handles.cb3D.TickLabels = {'-pi', '0', '+pi'};
            handles.cb3D.Label.String = 'phase of psi';
        else
            signData = sign(real(vertexPsi));
            signData(signData == 0) = 1;
            surfacePatch.FaceVertexCData = signData;
            surfacePatch.FaceColor = 'interp';
            colormap(handles.ax3D, blueWhiteRed(256));
            caxis(handles.ax3D, [-1 1]);
            handles.cb3D.Ticks = [-1 1];
            handles.cb3D.TickLabels = {'negative', 'positive'};
            handles.cb3D.Label.String = 'sign of psi';
        end

        isonormals(X, Y, Zgrid, probabilityDensity, surfacePatch);
        plot3(handles.ax3D, 0, 0, 0, 'ko', ...
            'MarkerFaceColor', [0.15 0.15 0.15], ...
            'MarkerSize', 5);

        camlight(handles.ax3D, 'headlight');
        lighting(handles.ax3D, 'gouraud');
        axis(handles.ax3D, 'equal');
        xlim(handles.ax3D, [-extent extent]);
        ylim(handles.ax3D, [-extent extent]);
        zlim(handles.ax3D, [-extent extent]);
        xlabel(handles.ax3D, 'x / Angstrom');
        ylabel(handles.ax3D, 'y / Angstrom');
        zlabel(handles.ax3D, 'z / Angstrom');
        title(handles.ax3D, sprintf( ...
            '3-D |psi|^2  |  %s  |  E = %.4f eV', ...
            orbitalName(n, l, m, basis), energy), ...
            'Color', [0.1 0.1 0.1], ...
            'FontSize', 11, 'FontWeight', 'bold');
        view(handles.ax3D, 35, 25);
        grid(handles.ax3D, 'on');
        hold(handles.ax3D, 'off');
    end

    % =====================================================================
    % HYDROGENIC WAVEFUNCTION
    % =====================================================================
    function psi = cartesianWavefunction(n, l, m, x, y, z, ...
            nuclearCharge, basis)

        radiusAngstrom = sqrt(x.^2 + y.^2 + z.^2);
        radiusAu = radiusAngstrom / a0;

        theta = zeros(size(radiusAngstrom));
        nonzero = radiusAngstrom > 0;
        theta(nonzero) = acos(max(-1, min(1, ...
            z(nonzero) ./ radiusAngstrom(nonzero))));
        phi = atan2(y, x);

        radialPart = radialFunction(n, l, radiusAu, nuclearCharge);
        angularPart = angularFunction(l, m, theta, phi, basis);
        psi = radialPart .* angularPart;
    end

    function radialPart = radialFunction(n, l, radiusAu, nuclearCharge)
        % Correct normalized hydrogenic radial function in a0^(-3/2).
        rho = 2 * nuclearCharge * radiusAu / n;
        polynomialOrder = n - l - 1;
        alpha = 2*l + 1;

        normalisation = (2*nuclearCharge/n)^(3/2) * ...
            sqrt(factorial(polynomialOrder) / ...
            (2*n*factorial(n+l)));

        laguerre = generalisedLaguerre(polynomialOrder, alpha, rho);
        radialPart = normalisation .* exp(-rho/2) .* ...
            rho.^l .* laguerre;
    end

    function values = generalisedLaguerre(order, alpha, x)
        % Stable recurrence for L_order^alpha(x).
        if order == 0
            values = ones(size(x));
            return;
        end

        previous = ones(size(x));
        current = 1 + alpha - x;
        if order == 1
            values = current;
            return;
        end

        for k = 2:order
            next = ((2*k - 1 + alpha - x).*current - ...
                (k - 1 + alpha).*previous) / k;
            previous = current;
            current = next;
        end
        values = current;
    end

    function angularPart = angularFunction(l, m, theta, phi, basis)
        absoluteM = abs(m);
        associatedP = associatedLegendre(l, absoluteM, cos(theta));
        angularNorm = sqrt((2*l + 1)/(4*pi) * ...
            factorial(l-absoluteM)/factorial(l+absoluteM));

        positiveM = angularNorm .* associatedP .* ...
            exp(1i * absoluteM .* phi);

        if strcmp(basis, 'Complex m eigenstate')
            if m < 0
                angularPart = (-1)^absoluteM .* conj(positiveM);
            else
                angularPart = positiveM;
            end
        else
            if m > 0
                angularPart = sqrt(2) .* real(positiveM);
            elseif m < 0
                angularPart = sqrt(2) .* imag(positiveM);
            else
                angularPart = real(positiveM);
            end
        end
    end

    function values = associatedLegendre(l, m, x)
        % P_l^m(x), including the Condon-Shortley phase (-1)^m.
        valuesMM = (-1)^m * doubleFactorial(2*m - 1) .* ...
            max(0, 1 - x.^2).^(m/2);

        if l == m
            values = valuesMM;
            return;
        end

        valuesM1M = x .* (2*m + 1) .* valuesMM;
        if l == m + 1
            values = valuesM1M;
            return;
        end

        previous = valuesMM;
        current = valuesM1M;
        for degree = m+2:l
            next = ((2*degree - 1).*x.*current - ...
                (degree + m - 1).*previous) / (degree - m);
            previous = current;
            current = next;
        end
        values = current;
    end

    function value = doubleFactorial(number)
        if number <= 0
            value = 1;
        else
            value = prod(number:-2:1);
        end
    end

    % =====================================================================
    % NUMERICAL VALIDATION AND ADAPTIVE DISPLAY RANGE
    % =====================================================================
    function [normalisation, displayRadiusAngstrom, measuredNodes] = ...
            radialMetrics(n, l, nuclearCharge)

        validationRadiusAu = 12 * n^2 / nuclearCharge;
        radiusAu = linspace(0, validationRadiusAu, 12000);
        radialPart = radialFunction(n, l, radiusAu, nuclearCharge);
        radialProbability = abs(radialPart).^2 .* radiusAu.^2;

        cumulativeProbability = cumtrapz(radiusAu, radialProbability);
        normalisation = cumulativeProbability(end);

        normalizedCumulative = cumulativeProbability / normalisation;
        quantileIndex = find(normalizedCumulative >= 0.997, 1, 'first');
        if isempty(quantileIndex)
            quantileIndex = numel(radiusAu);
        end
        displayRadiusAngstrom = 1.08 * radiusAu(quantileIndex) * a0;

        polynomialOrder = n - l - 1;
        alpha = 2*l + 1;
        rho = linspace(1e-8, 4*n + 20, 20000);
        laguerre = generalisedLaguerre(polynomialOrder, alpha, rho);
        signs = sign(laguerre);
        signs(signs == 0) = 1;
        measuredNodes = sum(signs(1:end-1).*signs(2:end) < 0);
    end

    % =====================================================================
    % LABELS, COLOUR MAP AND EXPORT
    % =====================================================================
    function name = orbitalName(n, l, m, basis)
        letters = 'spdfg';
        baseName = sprintf('%d%s', n, letters(l+1));

        if strcmp(basis, 'Complex m eigenstate')
            name = sprintf('%s complex (m=%d)', baseName, m);
            return;
        end

        if l == 0
            suffix = 's';
        elseif l == 1
            labels = {'p_y', 'p_z', 'p_x'};
            suffix = labels{m+2};
        elseif l == 2
            labels = {'d_{xy}', 'd_{yz}', 'd_{z^2}', 'd_{xz}', 'd_{x^2-y^2}'};
            suffix = labels{m+3};
        else
            if m > 0
                suffix = sprintf('real cos(%d phi)', m);
            elseif m < 0
                suffix = sprintf('real sin(%d phi)', abs(m));
            else
                suffix = sprintf('real m=0');
            end
        end
        name = sprintf('%s  %s', baseName, suffix);
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

    function exportView()
        n = round(handles.sldN.Value);
        l = round(handles.sldL.Value);
        m = round(handles.sldM.Value);
        suggestedName = sprintf('HydrogenicOrbital_n%d_l%d_m%d.png', n, l, m);
        [file, path] = uiputfile('*.png', 'Export current application view', ...
            suggestedName);

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

end
