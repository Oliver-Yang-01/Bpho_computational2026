function ElectronDiffraction_Task6
% =========================================================================
%  TASK #6: ELECTRON DIFFRACTION SIMULATOR
%  =========================================================================
%  High-standard interactive MATLAB model of electron-wave diffraction rings
%  on a spherical phosphor screen (Teltron / PHYWE style tube).
%
%  PHYSICS SUMMARY (detailed annotations throughout code)
%  -------------------------------------------------------
%  1. de Broglie wavelength of accelerated electrons:
%        λ = h / p ,   p = sqrt(2 * m_e * e * V)
%        Convenient form:  λ (nm) = 1.22639 / sqrt(V)   (V in volts)
%
%  2. Bragg condition for constructive interference (n-th order):
%        2 * d * sin(θ) = n * λ
%        ⇒  sin(θ) = n * λ / (2 * d)
%     where θ = Bragg angle (angle between beam and lattice planes)
%
%  3. Geometry of the spherical glass diffraction tube (R = 65 mm):
%        The electrons are scattered through an angle φ = 2θ
%        (the diffraction cone half-angle is 2θ).
%        On the spherical phosphor screen the measured ring radius
%        (perpendicular distance from the undeflected beam axis) is:
%            x = R * sin(φ) = R * sin(2θ)
%
%  4. Verification required by the task:
%        Plot 1/√V  versus  sin(φ/2)   [= sin(θ)]
%        This must produce a straight line through the origin because
%        sin(θ) ∝ λ ∝ 1/√V .
%
%  Graphite interplanar spacings used (standard literature values):
%        d_inner  = 0.213 nm   → produces the INNER ring (smaller angle)
%        d_outer  = 0.123 nm   → produces the OUTER ring (larger angle)
%
%  INTERACTIVE FEATURES
%  --------------------
%  • Live voltage slider (1.0 – 5.0 kV) with continuous ring update
%  • Toggle visibility of each ring independently
%  • Adjustable ring blur / intensity
%  • Real-time display of λ, θ, φ, x for both rings
%  • One-click generation of the verification 1/√V vs sin(φ/2) graph
%    with linear fit, R², slope analysis and theoretical expectation
%  • Voltage sweep animation
%  • Export current ring data / screenshot of pattern
%  • Theory panel and equation display always visible
%  • Tooltips and status messages for educational clarity
%
%  
%  =========================================================================

    % ----- Close any previous instance -----
    delete(findall(0, 'Type', 'figure', 'Tag', 'ElectronDiffractionApp'));

    % =====================================================================
    % PHYSICAL CONSTANTS (SI units) – annotated for transparency
    % =====================================================================
    h   = 6.62607015e-34;      % Planck constant (J·s)
    m_e = 9.1093837015e-31;    % electron rest mass (kg)
    e   = 1.602176634e-19;     % elementary charge (C)
    % Pre-computed conversion factor so that λ(nm) = LAMBDA_FACTOR / sqrt(V)
    % Derived from: λ = h / sqrt(2*m_e*e*V) * 1e9
    LAMBDA_FACTOR = (h / sqrt(2*m_e*e)) * 1e9;   % ≈ 1.22639 nm·√V

    % Tube geometry (task specification)
    R_mm = 65;                 % spherical glass radius (mm)

    % Graphite lattice spacings (nm) – accepted literature values
    d_inner = 0.213;           % nm – produces inner (smaller-radius) ring
    d_outer = 0.123;           % nm – produces outer (larger-radius) ring

    % Default simulation parameters
    V_default_kV = 3.0;        % kV
    n_order      = 1;          % Bragg order (mainly first order observed)

    % =====================================================================
    % CREATE MAIN FIGURE – plain light background
    % =====================================================================
    fig = uifigure( ...
        'Name',           'Electron Diffraction – Task #6 | Interactive Model', ...
        'Tag',            'ElectronDiffractionApp', ...
        'Position',       [80 60 1280 780], ...
        'Color',          [0.94 0.94 0.94], ...
        'Resize',         'on', ...
        'WindowState',    'normal');

    % Main grid: left control panel | right display area
    mainGrid = uigridlayout(fig, [1 2]);
    mainGrid.ColumnWidth   = {340, '1x'};
    mainGrid.Padding       = [12 12 12 12];
    mainGrid.ColumnSpacing = 14;
    mainGrid.BackgroundColor = [0.94 0.94 0.94];

    % =====================================================================
    % LEFT PANEL – CONTROLS & THEORY
    % =====================================================================
    leftPanel = uipanel(mainGrid, ...
        'Title',          '  CONTROL & THEORY PANEL', ...
        'FontName',       'Segoe UI', ...
        'FontSize',       13, ...
        'FontWeight',     'bold', ...
        'ForegroundColor',[0.1 0.1 0.1], ...
        'BackgroundColor',[0.96 0.96 0.96], ...
        'BorderType',     'line', ...
        'HighlightColor', [0.5 0.5 0.5]);

    leftGrid = uigridlayout(leftPanel, [12 1]);
    leftGrid.RowHeight = {28, 55, 40, 40, 30, 55, 40, 90, 50, 40, 40, '1x'};
    leftGrid.Padding   = [10 10 10 10];
    leftGrid.RowSpacing = 8;
    leftGrid.BackgroundColor = [0.96 0.96 0.96];

    % --- Title / subtitle ---
    uilabel(leftGrid, ...
        'Text',           'Accelerating Voltage V', ...
        'FontSize',       12, ...
        'FontWeight',     'bold', ...
        'FontColor',      [0.1 0.1 0.1], ...
        'HorizontalAlignment', 'center');

    % Voltage slider + live readout
    voltPanel = uigridlayout(leftGrid, [1 2]);
    voltPanel.ColumnWidth = {'1x', 70};
    voltPanel.Padding = [0 0 0 0];
    voltPanel.BackgroundColor = [0.96 0.96 0.96];

    sldV = uislider(voltPanel, ...
        'Limits',         [1.0 5.0], ...
        'Value',          V_default_kV, ...
        'MajorTicks',     [1 2 3 4 5], ...
        'MinorTicks',     1.5:0.5:4.5, ...
        'FontColor',      [0.2 0.2 0.2], ...
        'Tooltip',        'Drag to change accelerating voltage (1–5 kV). Rings update live.');

    lblV = uilabel(voltPanel, ...
        'Text',           sprintf('%.2f kV', V_default_kV), ...
        'FontSize',       14, ...
        'FontWeight',     'bold', ...
        'FontColor',      [0.0 0.4 0.1], ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor',[0.90 0.95 0.90]);

    % --- Lattice spacing toggles ---
    uilabel(leftGrid, ...
        'Text',           'Graphite Lattice Spacings (toggle rings)', ...
        'FontSize',       11, ...
        'FontWeight',     'bold', ...
        'FontColor',      [0.1 0.1 0.1], ...
        'HorizontalAlignment', 'center');

    chkPanel = uigridlayout(leftGrid, [1 2]);
    chkPanel.Padding = [0 0 0 0];
    chkPanel.BackgroundColor = [0.96 0.96 0.96];

    chkInner = uicheckbox(chkPanel, ...
        'Text',           sprintf('Inner  d = %.3f nm', d_inner), ...
        'Value',          true, ...
        'FontColor',      [0.0 0.45 0.15], ...
        'FontSize',       11, ...
        'Tooltip',        'd = 0.213 nm → smaller Bragg angle → INNER ring');

    chkOuter = uicheckbox(chkPanel, ...
        'Text',           sprintf('Outer  d = %.3f nm', d_outer), ...
        'Value',          true, ...
        'FontColor',      [0.0 0.3 0.6], ...
        'FontSize',       11, ...
        'Tooltip',        'd = 0.123 nm → larger Bragg angle → OUTER ring');

    % --- Ring appearance controls ---
    uilabel(leftGrid, ...
        'Text',           'Ring Appearance (blur / brightness)', ...
        'FontSize',       11, ...
        'FontWeight',     'bold', ...
        'FontColor',      [0.1 0.1 0.1], ...
        'HorizontalAlignment', 'center');

    sldBlur = uislider(leftGrid, ...
        'Limits',         [0.3 4.0], ...
        'Value',          1.2, ...
        'MajorTicks',     [0.5 1 2 3 4], ...
        'FontColor',      [0.2 0.2 0.2], ...
        'Tooltip',        'Gaussian width of the diffraction rings (mm)');

    % --- Live calculated values panel ---
    uilabel(leftGrid, ...
        'Text',           'Live Calculated Quantities', ...
        'FontSize',       11, ...
        'FontWeight',     'bold', ...
        'FontColor',      [0.1 0.1 0.1], ...
        'HorizontalAlignment', 'center');

    txtValues = uitextarea(leftGrid, ...
        'Value',          {''}, ...
        'Editable',       'off', ...
        'FontName',       'Consolas', ...
        'FontSize',       11, ...
        'FontColor',      [0.1 0.1 0.1], ...
        'BackgroundColor',[1 1 1], ...
        'Tooltip',        'Real-time de Broglie wavelength, Bragg angles and ring radii');

    % --- Action buttons ---
    btnGrid = uigridlayout(leftGrid, [1 2]);
    btnGrid.Padding = [0 0 0 0];
    btnGrid.BackgroundColor = [0.96 0.96 0.96];

    btnVerify = uibutton(btnGrid, ...
        'Text',           'Generate 1/√V vs sin(φ/2) Graph', ...
        'FontWeight',     'bold', ...
        'FontSize',       11, ...
        'BackgroundColor',[0.85 0.92 0.85], ...
        'FontColor',      [0.05 0.25 0.1], ...
        'Tooltip',        'Creates the verification straight-line plot required by the task');

    btnSweep = uibutton(btnGrid, ...
        'Text',           '▶ Voltage Sweep Animation', ...
        'FontWeight',     'bold', ...
        'FontSize',       11, ...
        'BackgroundColor',[0.85 0.90 0.95], ...
        'FontColor',      [0.1 0.2 0.4], ...
        'Tooltip',        'Animate voltage from 1 kV → 5 kV while watching rings shrink');

    btnExport = uibutton(leftGrid, ...
        'Text',           'Export Pattern Data & Screenshot', ...
        'FontWeight',     'bold', ...
        'BackgroundColor',[0.95 0.92 0.85], ...
        'FontColor',      [0.3 0.2 0.05], ...
        'Tooltip',        'Save current numerical results and a PNG of the phosphor screen');

    % --- Theory / equations box ---
    uilabel(leftGrid, ...
        'Text',           'Key Equations (always visible)', ...
        'FontSize',       11, ...
        'FontWeight',     'bold', ...
        'FontColor',      [0.1 0.1 0.1], ...
        'HorizontalAlignment', 'center');

    txtTheory = uitextarea(leftGrid, ...
        'Value', { ...
            'λ (nm) = 1.22639 / √V          (de Broglie)', ...
            '2 d sinθ = n λ                 (Bragg)', ...
            'φ = 2θ                         (scattering angle)', ...
            'x = R · sin(φ) = R · sin(2θ)   (ring radius, R=65 mm)', ...
            'Graph:  1/√V   vs   sin(φ/2)   → straight line', ...
            '', ...
            'Inner ring ← d = 0.213 nm', ...
            'Outer ring ← d = 0.123 nm'}, ...
        'Editable',       'off', ...
        'FontName',       'Consolas', ...
        'FontSize',       10, ...
        'FontColor',      [0.15 0.15 0.15], ...
        'BackgroundColor',[1 1 1]);

    % Status bar
    lblStatus = uilabel(leftGrid, ...
        'Text',           'Ready – move the voltage slider to begin.', ...
        'FontSize',       10, ...
        'FontColor',      [0.2 0.3 0.4], ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor',[0.92 0.92 0.92]);

    % =====================================================================
    % RIGHT PANEL – VISUALISATION
    % =====================================================================
    rightPanel = uipanel(mainGrid, ...
        'Title',          '  PHOSPHOR SCREEN  |  VERIFICATION GRAPH', ...
        'FontName',       'Segoe UI', ...
        'FontSize',       13, ...
        'FontWeight',     'bold', ...
        'ForegroundColor',[0.1 0.1 0.1], ...
        'BackgroundColor',[0.96 0.96 0.96], ...
        'BorderType',     'line', ...
        'HighlightColor', [0.5 0.5 0.5]);

    rightGrid = uigridlayout(rightPanel, [2 1]);
    rightGrid.RowHeight = {'1.15x', '1x'};
    rightGrid.Padding   = [8 8 8 8];
    rightGrid.RowSpacing = 10;
    rightGrid.BackgroundColor = [0.96 0.96 0.96];

    % ----- Phosphor screen axes -----
    axPattern = uiaxes(rightGrid, ...
        'BackgroundColor', [0.05 0.08 0.05], ...   % still dark so the green rings show clearly
        'XColor',          [0.3 0.3 0.3], ...
        'YColor',          [0.3 0.3 0.3], ...
        'ZColor',          [0.3 0.3 0.3], ...
        'FontName',        'Segoe UI', ...
        'FontSize',        10, ...
        'Box',             'on');
    title(axPattern, 'Simulated Phosphor Screen (spherical tube R = 65 mm)', ...
        'Color', [0.1 0.1 0.1], 'FontSize', 13, 'FontWeight', 'bold');
    xlabel(axPattern, 'x (mm) – radial distance from beam axis', 'Color', [0.2 0.2 0.2]);
    ylabel(axPattern, 'y (mm)', 'Color', [0.2 0.2 0.2]);
    axis(axPattern, 'equal');
    hold(axPattern, 'on');
    colormap(axPattern, customGreenColormap());

    % ----- Verification graph axes -----
    axGraph = uiaxes(rightGrid, ...
        'BackgroundColor', [1 1 1], ...
        'XColor',          [0.2 0.2 0.2], ...
        'YColor',          [0.2 0.2 0.2], ...
        'FontName',        'Segoe UI', ...
        'FontSize',        10, ...
        'Box',             'on', ...
        'GridColor',       [0.7 0.7 0.7], ...
        'GridAlpha',       0.6);
    title(axGraph, 'Verification: 1/\surdV  vs  sin(\phi/2)  – must be a straight line', ...
        'Color', [0.1 0.1 0.1], 'FontSize', 12, 'FontWeight', 'bold');
    xlabel(axGraph, 'sin(\phi/2)  =  sin(\theta)   (Bragg angle)', 'Color', [0.2 0.2 0.2]);
    ylabel(axGraph, '1 / \surdV   (V in volts)', 'Color', [0.2 0.2 0.2]);
    grid(axGraph, 'on');
    hold(axGraph, 'on');

    % =====================================================================
    % CALLBACKS – interactive behaviour
    % =====================================================================
    sldV.ValueChangedFcn      = @(src,~) updateAll();
    sldBlur.ValueChangedFcn   = @(src,~) updatePatternOnly();
    chkInner.ValueChangedFcn  = @(src,~) updatePatternOnly();
    chkOuter.ValueChangedFcn  = @(src,~) updatePatternOnly();
    btnVerify.ButtonPushedFcn = @(src,~) generateVerificationGraph();
    btnSweep.ButtonPushedFcn  = @(src,~) runVoltageSweep();
    btnExport.ButtonPushedFcn = @(src,~) exportResults();

    % Store handles in a simple struct for nested functions
    handles = struct();
    handles.sldV      = sldV;
    handles.lblV      = lblV;
    handles.chkInner  = chkInner;
    handles.chkOuter  = chkOuter;
    handles.sldBlur   = sldBlur;
    handles.txtValues = txtValues;
    handles.axPattern = axPattern;
    handles.axGraph   = axGraph;
    handles.lblStatus = lblStatus;
    handles.fig       = fig;

    % Initial draw
    updateAll();

    % =====================================================================
    % NESTED FUNCTIONS
    % =====================================================================

    function updateAll()
        % Master update: pattern + numerical values
        V_kV = handles.sldV.Value;
        handles.lblV.Text = sprintf('%.2f kV', V_kV);
        updatePatternOnly();
        updateValueDisplay(V_kV);
        handles.lblStatus.Text = sprintf('Voltage = %.2f kV  |  Rings updated live', V_kV);
    end

    function updatePatternOnly()
        % Redraw only the phosphor screen (fast for slider)
        V_kV   = handles.sldV.Value;
        V      = V_kV * 1000;          % volts
        blur   = handles.sldBlur.Value;
        showIn = handles.chkInner.Value;
        showOut= handles.chkOuter.Value;

        % --- Compute wavelengths and angles ---
        lambda_nm = LAMBDA_FACTOR / sqrt(V);   % nm

        % Bragg angles (θ) and scattering angles (φ = 2θ)
        [x_in, theta_in, phi_in]   = computeRing(lambda_nm, d_inner, n_order, R_mm);
        [x_out, theta_out, phi_out] = computeRing(lambda_nm, d_outer, n_order, R_mm);

        % --- Build 2-D intensity map that looks like real phosphor ---
        N = 512;                           % resolution
        lim = 70;                          % mm – slightly larger than R
        [X, Y] = meshgrid(linspace(-lim, lim, N));
        rho = sqrt(X.^2 + Y.^2);

        % Central undeflected spot (very bright)
        I = 1.8 * exp( -(rho / 1.8).^2 );

        % Diffraction rings – Gaussian profiles for realistic soft edges
        if showIn && ~isnan(x_in)
            I = I + 0.95 * exp( -((rho - x_in) / blur).^2 );
            % faint second-order hint
            I = I + 0.25 * exp( -((rho - 2*x_in) / (blur*1.3)).^2 );
        end
        if showOut && ~isnan(x_out)
            I = I + 0.85 * exp( -((rho - x_out) / blur).^2 );
            I = I + 0.20 * exp( -((rho - 2*x_out) / (blur*1.3)).^2 );
        end

        % Soft circular mask of the spherical screen
        mask = rho <= (R_mm + 2);
        I = I .* mask;
        I = I + 0.02 * (1 - mask);         % very dark outside

        % Display
        cla(handles.axPattern);
        imagesc(handles.axPattern, [-lim lim], [-lim lim], I);
        axis(handles.axPattern, 'equal', 'tight');
        set(handles.axPattern, 'YDir', 'normal');
        colormap(handles.axPattern, customGreenColormap());
        clim(handles.axPattern, [0 2.0]);

        % Overlay geometric circle of the tube radius
        th = linspace(0, 2*pi, 200);
        plot(handles.axPattern, R_mm*cos(th), R_mm*sin(th), ...
            '--', 'Color', [0.5 0.7 0.5], 'LineWidth', 1.2);

        % Mark the calculated ring radii with thin circles + labels
        if showIn && ~isnan(x_in)
            plot(handles.axPattern, x_in*cos(th), x_in*sin(th), ...
                ':', 'Color', [0.6 1 0.6], 'LineWidth', 1.0);
            text(handles.axPattern, x_in*0.72, 8, sprintf('inner\n%.1f mm', x_in), ...
                'Color', [0.7 1 0.7], 'FontSize', 9, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center');
        end
        if showOut && ~isnan(x_out)
            plot(handles.axPattern, x_out*cos(th), x_out*sin(th), ...
                ':', 'Color', [0.5 0.85 1], 'LineWidth', 1.0);
            text(handles.axPattern, x_out*0.72, -10, sprintf('outer\n%.1f mm', x_out), ...
                'Color', [0.6 0.9 1], 'FontSize', 9, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center');
        end

        % Central cross-hair
        plot(handles.axPattern, [-4 4], [0 0], 'w-', 'LineWidth', 0.8);
        plot(handles.axPattern, [0 0], [-4 4], 'w-', 'LineWidth', 0.8);

        title(handles.axPattern, sprintf( ...
            'Phosphor Screen  |  V = %.2f kV  |  \\lambda = %.4f nm  |  R = 65 mm', ...
            V_kV, lambda_nm), ...
            'Color', [0.1 0.1 0.1], 'FontSize', 12, 'FontWeight', 'bold');
        xlim(handles.axPattern, [-lim lim]);
        ylim(handles.axPattern, [-lim lim]);
    end

    function updateValueDisplay(V_kV)
        V = V_kV * 1000;
        lambda_nm = LAMBDA_FACTOR / sqrt(V);

        [x_in, theta_in, phi_in]   = computeRing(lambda_nm, d_inner, n_order, R_mm);
        [x_out, theta_out, phi_out] = computeRing(lambda_nm, d_outer, n_order, R_mm);

        lines = {
            sprintf('Accelerating voltage V = %.2f kV  (%.0f V)', V_kV, V)
            sprintf('de Broglie wavelength  λ = %.5f nm', lambda_nm)
            ''
            '── Inner ring (d = 0.213 nm) ──'
            sprintf('  Bragg angle θ   = %.3f °', theta_in*180/pi)
            sprintf('  Scattering φ=2θ = %.3f °', phi_in*180/pi)
            sprintf('  Ring radius x   = %.2f mm', x_in)
            ''
            '── Outer ring (d = 0.123 nm) ──'
            sprintf('  Bragg angle θ   = %.3f °', theta_out*180/pi)
            sprintf('  Scattering φ=2θ = %.3f °', phi_out*180/pi)
            sprintf('  Ring radius x   = %.2f mm', x_out)
            };
        handles.txtValues.Value = lines;
    end

    function [x_mm, theta, phi] = computeRing(lambda_nm, d_nm, n, R)
        % Compute Bragg angle, scattering angle and ring radius
        % from wavelength and lattice spacing (exact, no small-angle approx)
        arg = n * lambda_nm / (2 * d_nm);
        if arg > 1
            % physically impossible – wavelength too long for this d
            x_mm  = NaN;
            theta = NaN;
            phi   = NaN;
            return;
        end
        theta = asin(arg);                 % Bragg angle (rad)
        phi   = 2 * theta;                 % full scattering angle
        x_mm  = R * sin(phi);              % ring radius on sphere (mm)
    end

    function generateVerificationGraph()
        % TASK REQUIREMENT: produce 1/√V vs sin(φ/2) straight-line graph
        handles.lblStatus.Text = 'Generating verification graph …';
        drawnow;

        V_kV_range = 1.0 : 0.15 : 5.0;
        V_range    = V_kV_range * 1000;

        invSqrtV = 1 ./ sqrt(V_range);

        % Theoretical sin(θ) = sin(φ/2) for both spacings
        sinTheta_in  = zeros(size(V_range));
        sinTheta_out = zeros(size(V_range));
        for k = 1:numel(V_range)
            lam = LAMBDA_FACTOR / sqrt(V_range(k));
            [~, th_in,  ~] = computeRing(lam, d_inner, n_order, R_mm);
            [~, th_out, ~] = computeRing(lam, d_outer, n_order, R_mm);
            sinTheta_in(k)  = sin(th_in);
            sinTheta_out(k) = sin(th_out);
        end

        % Clear and plot
        cla(handles.axGraph);
        hold(handles.axGraph, 'on');

        % Inner ring data + fit
        p_in = polyfit(sinTheta_in, invSqrtV, 1);
        fit_in = polyval(p_in, sinTheta_in);
        h1 = plot(handles.axGraph, sinTheta_in, invSqrtV, 'o', ...
            'MarkerSize', 7, 'MarkerFaceColor', [0.2 0.7 0.3], ...
            'MarkerEdgeColor', [0.1 0.4 0.15], 'LineWidth', 1.2);
        plot(handles.axGraph, sinTheta_in, fit_in, '-', ...
            'Color', [0.1 0.55 0.25], 'LineWidth', 2.0);

        % Outer ring data + fit
        p_out = polyfit(sinTheta_out, invSqrtV, 1);
        fit_out = polyval(p_out, sinTheta_out);
        h2 = plot(handles.axGraph, sinTheta_out, invSqrtV, 's', ...
            'MarkerSize', 7, 'MarkerFaceColor', [0.25 0.5 0.85], ...
            'MarkerEdgeColor', [0.1 0.25 0.55], 'LineWidth', 1.2);
        plot(handles.axGraph, sinTheta_out, fit_out, '-', ...
            'Color', [0.15 0.35 0.7], 'LineWidth', 2.0);

        % Ideal theoretical lines (through origin)
        % From Bragg + de Broglie: sinθ = (n * LAMBDA_FACTOR) / (2 d) * 1/√V
        % ⇒  1/√V = (2 d / (n * LAMBDA_FACTOR)) * sinθ
        slope_theory_in  = 2 * d_inner  / (n_order * LAMBDA_FACTOR);
        slope_theory_out = 2 * d_outer  / (n_order * LAMBDA_FACTOR);

        % R² calculation
        R2_in  = 1 - sum((invSqrtV - fit_in).^2)  / sum((invSqrtV - mean(invSqrtV)).^2);
        R2_out = 1 - sum((invSqrtV - fit_out).^2) / sum((invSqrtV - mean(invSqrtV)).^2);

        legend(handles.axGraph, [h1 h2], { ...
            sprintf('Inner d=0.213 nm  (R²=%.5f, slope=%.3f)', R2_in,  p_in(1)), ...
            sprintf('Outer d=0.123 nm  (R²=%.5f, slope=%.3f)', R2_out, p_out(1))}, ...
            'Location', 'northwest', 'TextColor', [0.1 0.1 0.1], ...
            'Color', [1 1 1], 'FontSize', 9);

        title(handles.axGraph, { ...
            'Verification Graph: 1/\surdV  versus  sin(\phi/2)  [= sin(\theta)]'; ...
            'Both data sets are perfectly linear (model is consistent with theory)'}, ...
            'Color', [0.1 0.1 0.1], 'FontSize', 11);

        % Annotate the theoretical slopes
        text(handles.axGraph, 0.02, max(invSqrtV)*0.92, ...
            sprintf('Theory slope (inner) = 2d/λ₀ = %.4f', slope_theory_in), ...
            'Color', [0.1 0.45 0.2], 'FontSize', 9, 'FontName', 'Consolas');
        text(handles.axGraph, 0.02, max(invSqrtV)*0.82, ...
            sprintf('Theory slope (outer) = 2d/λ₀ = %.4f', slope_theory_out), ...
            'Color', [0.1 0.3 0.55], 'FontSize', 9, 'FontName', 'Consolas');

        handles.lblStatus.Text = sprintf( ...
            'Verification complete – both rings give R² > 0.9999 (perfect linearity)');
    end

    function runVoltageSweep()
        % Educational animation: watch rings shrink as V increases
        handles.lblStatus.Text = 'Sweeping voltage 1 → 5 kV … observe rings contract';
        btnSweep.Enable = 'off';
        btnVerify.Enable = 'off';
        drawnow;

        for v = 1.0 : 0.08 : 5.0
            handles.sldV.Value = v;
            updateAll();
            pause(0.04);               % smooth animation speed
            if ~isvalid(handles.fig), return; end
        end

        btnSweep.Enable = 'on';
        btnVerify.Enable = 'on';
        handles.lblStatus.Text = 'Sweep finished – rings are smaller at higher voltage (shorter λ)';
    end

    function exportResults()
        % Save numerical summary + pattern image
        V_kV = handles.sldV.Value;
        V    = V_kV * 1000;
        lam  = LAMBDA_FACTOR / sqrt(V);
        [xin, thin, phin]   = computeRing(lam, d_inner, n_order, R_mm);
        [xout, thout, phout] = computeRing(lam, d_outer, n_order, R_mm);

        % Text report
        report = sprintf([ ...
            'ELECTRON DIFFRACTION SIMULATION – TASK #6\n' ...
            '========================================\n' ...
            'Accelerating voltage : %.3f kV\n' ...
            'de Broglie wavelength: %.6f nm\n\n' ...
            'INNER RING (d = 0.213 nm)\n' ...
            '  Bragg angle θ      : %.4f rad (%.3f °)\n' ...
            '  Scattering angle φ : %.4f rad (%.3f °)\n' ...
            '  Ring radius x      : %.3f mm\n\n' ...
            'OUTER RING (d = 0.123 nm)\n' ...
            '  Bragg angle θ      : %.4f rad (%.3f °)\n' ...
            '  Scattering angle φ : %.4f rad (%.3f °)\n' ...
            '  Ring radius x      : %.3f mm\n\n' ...
            'Geometry: spherical tube radius R = 65 mm\n' ...
            'Relation used: x = R * sin(φ)  with  φ = 2θ\n' ...
            'Verification graph: 1/√V vs sin(φ/2) is linear by construction.\n'], ...
            V_kV, lam, ...
            thin, thin*180/pi, phin, phin*180/pi, xin, ...
            thout, thout*180/pi, phout, phout*180/pi, xout);

        % Write to file next to the script
        [file, path] = uiputfile('ElectronDiffraction_Results.txt', ...
            'Save numerical results');
        if isequal(file, 0)
            handles.lblStatus.Text = 'Export cancelled.';
            return;
        end
        fid = fopen(fullfile(path, file), 'w');
        fprintf(fid, '%s', report);
        fclose(fid);

        % Also capture the pattern axes as image
        try
            exportgraphics(handles.axPattern, ...
                fullfile(path, strrep(file, '.txt', '_Pattern.png')), ...
                'Resolution', 200);
        catch
            % older MATLAB fallback
        end

        handles.lblStatus.Text = sprintf('Exported → %s', file);
    end

    function cmap = customGreenColormap()
        % Phosphor-green colormap (black → deep green → bright green-white)
        % Kept for realistic appearance of the diffraction rings
        n = 256;
        r = [zeros(1, n/2), linspace(0, 0.7, n/2)];
        g = [linspace(0, 0.4, n/4), linspace(0.4, 1.0, 3*n/4)];
        b = [zeros(1, 3*n/4), linspace(0, 0.4, n/4)];
        cmap = [r' g' b'];
        % mild gamma for more realistic glow
        cmap = cmap .^ 0.85;
    end

end