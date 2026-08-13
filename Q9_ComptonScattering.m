function ComptonScattering_Task9_Correct
% =========================================================================
%  TASK #9: COMPTON SCATTERING  (CORRECTED VERSION)
%  Interactive model: fractional wavelength shift Δλ/λ, electron recoil
%  speed v and recoil angle φ versus photon scattering angle θ.
% =========================================================================
%
%  PHYSICS SUMMARY (detailed annotations)
%  ---------------------------------------
%  An X-ray (or γ-ray) photon of wavelength λ collides with a free
%  electron at rest (mass m_e). After the collision the photon is
%  scattered through an angle θ with a longer wavelength λ' and the
%  electron recoils with speed v at an angle φ to the incident direction.
%
%  Compton formula (wavelength shift):
%        λ' − λ = λ_C (1 − cos θ)
%  where λ_C = h / (m_e c) ≈ 2.426 pm is the Compton wavelength.
%
%  Fractional shift:
%        Δλ / λ = (λ_C / λ) (1 − cos θ)
%
%  Scattered photon energy:
%        E' = h c / λ'
%
%  Electron kinetic energy (from energy conservation):
%        K = E − E'     (E = h c / λ)
%
%  Relativistic speed of the recoiling electron:
%        γ = 1 + K/(m_e c²)
%        v = c √(1 − 1/γ²)
%
%  Electron recoil angle (momentum conservation):
%        cot φ = (1 + α) tan(θ/2)
%  where α = E / (m_e c²) = λ_C / λ
%
%  INTERACTIVE FEATURES
%  --------------------
%  • Slider for photon scattering angle θ (0–180°)
%  • Slider for incident wavelength λ (typical X-ray range)
%  • Three live plots: Δλ/λ, v/c and φ versus θ
%  • Red marker always sits exactly on the curves
%  • Numerical read-out of all quantities for the current θ
%  • Export of results
%  • Plain light UI, detailed source annotations
%
%  Author: Grok (xAI)
% =========================================================================

    % Close previous instance
    delete(findall(0, 'Type', 'figure', 'Tag', 'ComptonAppCorrect'));

    % =====================================================================
    % PHYSICAL CONSTANTS
    % =====================================================================
    h     = 6.62607015e-34;      % Planck constant (J s)
    c     = 2.99792458e8;        % speed of light (m/s)
    m_e   = 9.1093837015e-31;    % electron mass (kg)
    eV    = 1.602176634e-19;     % 1 eV in joules
    lambda_C = h/(m_e*c);        % Compton wavelength (m) ≈ 2.426e-12 m

    % Defaults
    theta0   = 90;               % degrees
    lambda0  = 0.071;            % nm  (typical Mo Kα X-ray ≈ 0.071 nm)

    % =====================================================================
    % MAIN FIGURE – plain light background
    % =====================================================================
    fig = uifigure( ...
        'Name',     'Compton Scattering – Task #9 (Correct) | Interactive Model', ...
        'Tag',      'ComptonAppCorrect', ...
        'Position', [40 30 1340 820], ...
        'Color',    [0.94 0.94 0.94]);

    mainGrid = uigridlayout(fig, [1 2]);
    mainGrid.ColumnWidth   = {340, '1x'};
    mainGrid.Padding       = [12 12 12 12];
    mainGrid.ColumnSpacing = 14;
    mainGrid.BackgroundColor = [0.94 0.94 0.94];

    % =====================================================================
    % LEFT PANEL – CONTROLS
    % =====================================================================
    leftPanel = uipanel(mainGrid, ...
        'Title', '  CONTROL & THEORY PANEL', ...
        'FontName', 'Segoe UI', 'FontSize', 13, 'FontWeight', 'bold', ...
        'ForegroundColor', [0.1 0.1 0.1], ...
        'BackgroundColor', [0.96 0.96 0.96], ...
        'BorderType', 'line', 'HighlightColor', [0.5 0.5 0.5]);

    leftGrid = uigridlayout(leftPanel, [13 1]);
    leftGrid.RowHeight = {26, 50, 26, 50, 30, 120, 40, 40, 26, '1x', 30};
    leftGrid.Padding = [10 10 10 10];
    leftGrid.RowSpacing = 7;
    leftGrid.BackgroundColor = [0.96 0.96 0.96];

    % --- Scattering angle θ ---
    uilabel(leftGrid, 'Text', 'Photon scattering angle θ (°)', ...
        'FontSize', 12, 'FontWeight', 'bold', 'FontColor', [0.1 0.1 0.1], ...
        'HorizontalAlignment', 'center');

    thPanel = uigridlayout(leftGrid, [1 2]);
    thPanel.ColumnWidth = {'1x', 55};
    thPanel.Padding = [0 0 0 0];
    thPanel.BackgroundColor = [0.96 0.96 0.96];

    sldTheta = uislider(thPanel, ...
        'Limits', [0 180], 'Value', theta0, ...
        'MajorTicks', 0:30:180, ...
        'FontColor', [0.2 0.2 0.2], ...
        'Tooltip', 'Angle through which the photon is scattered');

    lblTheta = uilabel(thPanel, ...
        'Text', sprintf('%.0f°', theta0), ...
        'FontSize', 13, 'FontWeight', 'bold', ...
        'FontColor', [0.0 0.4 0.15], ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor', [0.90 0.95 0.90]);

    % --- Incident wavelength ---
    uilabel(leftGrid, 'Text', 'Incident wavelength λ (nm)', ...
        'FontSize', 12, 'FontWeight', 'bold', 'FontColor', [0.1 0.1 0.1], ...
        'HorizontalAlignment', 'center');

    lamPanel = uigridlayout(leftGrid, [1 2]);
    lamPanel.ColumnWidth = {'1x', 70};
    lamPanel.Padding = [0 0 0 0];
    lamPanel.BackgroundColor = [0.96 0.96 0.96];

    sldLam = uislider(lamPanel, ...
        'Limits', [0.01 0.20], 'Value', lambda0, ...
        'MajorTicks', [0.01 0.05 0.10 0.15 0.20], ...
        'FontColor', [0.2 0.2 0.2], ...
        'Tooltip', 'Wavelength of the incoming X-ray / γ-ray photon');

    lblLam = uilabel(lamPanel, ...
        'Text', sprintf('%.3f nm', lambda0), ...
        'FontSize', 12, 'FontWeight', 'bold', ...
        'FontColor', [0.0 0.3 0.55], ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor', [0.90 0.93 0.97]);

    % --- Live values ---
    uilabel(leftGrid, 'Text', 'Live Calculated Quantities', ...
        'FontSize', 11, 'FontWeight', 'bold', 'FontColor', [0.1 0.1 0.1], ...
        'HorizontalAlignment', 'center');

    txtValues = uitextarea(leftGrid, ...
        'Value', {''}, 'Editable', 'off', ...
        'FontName', 'Consolas', 'FontSize', 11, ...
        'FontColor', [0.1 0.1 0.1], ...
        'BackgroundColor', [1 1 1]);

    % Buttons
    btnExport = uibutton(leftGrid, ...
        'Text', 'Export Numerical Results', ...
        'FontWeight', 'bold', ...
        'BackgroundColor', [0.95 0.92 0.85], ...
        'FontColor', [0.3 0.2 0.05]);

    btnReset = uibutton(leftGrid, ...
        'Text', 'Reset to θ = 90°, λ = 0.071 nm', ...
        'FontWeight', 'bold', 'FontSize', 11, ...
        'BackgroundColor', [0.85 0.92 0.85], ...
        'FontColor', [0.05 0.25 0.1]);

    % Theory
    uilabel(leftGrid, 'Text', 'Key Equations', ...
        'FontSize', 11, 'FontWeight', 'bold', 'FontColor', [0.1 0.1 0.1], ...
        'HorizontalAlignment', 'center');

    txtTheory = uitextarea(leftGrid, ...
        'Value', { ...
            'λ′ − λ = λ_C (1 − cos θ)', ...
            'Δλ/λ = (λ_C/λ)(1 − cos θ)', ...
            '', ...
            'α = E/(m c²) = λ_C/λ', ...
            'cot φ = (1+α) tan(θ/2)', ...
            '', ...
            'K = E − E′', ...
            'γ = 1 + K/(m c²)', ...
            'v = c √(1 − 1/γ²)'}, ...
        'Editable', 'off', ...
        'FontName', 'Consolas', 'FontSize', 10, ...
        'FontColor', [0.15 0.15 0.15], ...
        'BackgroundColor', [1 1 1]);

    % Status
    lblStatus = uilabel(leftGrid, ...
        'Text', 'Ready – move the sliders to explore Compton scattering.', ...
        'FontSize', 10, 'FontColor', [0.2 0.3 0.4], ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor', [0.92 0.92 0.92]);

    % =====================================================================
    % RIGHT PANEL – THREE PLOTS
    % =====================================================================
    rightPanel = uipanel(mainGrid, ...
        'Title', '  Δλ/λ   |   Electron recoil speed v/c   |   Recoil angle φ', ...
        'FontName', 'Segoe UI', 'FontSize', 13, 'FontWeight', 'bold', ...
        'ForegroundColor', [0.1 0.1 0.1], ...
        'BackgroundColor', [0.96 0.96 0.96], ...
        'BorderType', 'line', 'HighlightColor', [0.5 0.5 0.5]);

    rightGrid = uigridlayout(rightPanel, [3 1]);
    rightGrid.RowHeight = {'1x', '1x', '1x'};
    rightGrid.Padding = [8 8 8 8];
    rightGrid.RowSpacing = 8;
    rightGrid.BackgroundColor = [0.96 0.96 0.96];

    ax1 = uiaxes(rightGrid, 'BackgroundColor', [1 1 1], ...
        'XColor', [0.2 0.2 0.2], 'YColor', [0.2 0.2 0.2], ...
        'FontName', 'Segoe UI', 'FontSize', 10, ...
        'Box', 'on', 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.5);
    title(ax1, 'Fractional wavelength shift  Δλ / λ', ...
        'Color', [0.1 0.1 0.1], 'FontSize', 12, 'FontWeight', 'bold');
    xlabel(ax1, 'Photon scattering angle θ (°)', 'Color', [0.2 0.2 0.2]);
    ylabel(ax1, 'Δλ / λ', 'Color', [0.2 0.2 0.2]);
    grid(ax1, 'on'); hold(ax1, 'on');

    ax2 = uiaxes(rightGrid, 'BackgroundColor', [1 1 1], ...
        'XColor', [0.2 0.2 0.2], 'YColor', [0.2 0.2 0.2], ...
        'FontName', 'Segoe UI', 'FontSize', 10, ...
        'Box', 'on', 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.5);
    title(ax2, 'Electron recoil speed  v / c', ...
        'Color', [0.1 0.1 0.1], 'FontSize', 12, 'FontWeight', 'bold');
    xlabel(ax2, 'Photon scattering angle θ (°)', 'Color', [0.2 0.2 0.2]);
    ylabel(ax2, 'v / c', 'Color', [0.2 0.2 0.2]);
    grid(ax2, 'on'); hold(ax2, 'on');

    ax3 = uiaxes(rightGrid, 'BackgroundColor', [1 1 1], ...
        'XColor', [0.2 0.2 0.2], 'YColor', [0.2 0.2 0.2], ...
        'FontName', 'Segoe UI', 'FontSize', 10, ...
        'Box', 'on', 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.5);
    title(ax3, 'Electron recoil angle  φ', ...
        'Color', [0.1 0.1 0.1], 'FontSize', 12, 'FontWeight', 'bold');
    xlabel(ax3, 'Photon scattering angle θ (°)', 'Color', [0.2 0.2 0.2]);
    ylabel(ax3, 'φ (°)', 'Color', [0.2 0.2 0.2]);
    grid(ax3, 'on'); hold(ax3, 'on');

    % =====================================================================
    % CALLBACKS
    % =====================================================================
    sldTheta.ValueChangedFcn = @(~,~) updateAll();
    sldLam.ValueChangedFcn   = @(~,~) updateAll();
    btnExport.ButtonPushedFcn = @(~,~) exportResults();
    btnReset.ButtonPushedFcn  = @(~,~) resetDefaults();

    handles = struct();
    handles.sldTheta  = sldTheta;
    handles.lblTheta  = lblTheta;
    handles.sldLam    = sldLam;
    handles.lblLam    = lblLam;
    handles.txtValues = txtValues;
    handles.ax1       = ax1;
    handles.ax2       = ax2;
    handles.ax3       = ax3;
    handles.lblStatus = lblStatus;
    handles.fig       = fig;

    updateAll();

    % =====================================================================
    % NESTED FUNCTIONS
    % =====================================================================

    function updateAll()
        theta_deg = handles.sldTheta.Value;
        handles.lblTheta.Text = sprintf('%.0f°', theta_deg);
        lambda_nm = handles.sldLam.Value;
        handles.lblLam.Text = sprintf('%.3f nm', lambda_nm);

        lambda = lambda_nm * 1e-9;          % metres
        theta  = deg2rad(theta_deg);

        % --- Current point (scalar) – used for both markers and text ---
        [dlam_r, v_r, phi_r] = compton_quantities(theta, lambda);

        % --- Full curves vs θ ---
        th_deg = linspace(0, 180, 361);
        th     = deg2rad(th_deg);
        [dlam_over_lam, v_over_c, phi_deg] = compton_quantities(th, lambda);

        % Plot 1: fractional shift
        cla(handles.ax1); hold(handles.ax1, 'on');
        plot(handles.ax1, th_deg, dlam_over_lam, '-', ...
            'Color', [0.15 0.45 0.7], 'LineWidth', 2.0);
        plot(handles.ax1, theta_deg, dlam_r, 'o', ...
            'MarkerSize', 9, 'MarkerFaceColor', [0.85 0.25 0.15], ...
            'MarkerEdgeColor', [0.5 0.1 0.05], 'LineWidth', 1.4);
        xlim(handles.ax1, [0 180]);
        title(handles.ax1, sprintf('Fractional wavelength shift  Δλ/λ   (λ = %.3f nm)', lambda_nm), ...
            'Color', [0.1 0.1 0.1], 'FontSize', 12, 'FontWeight', 'bold');

        % Plot 2: recoil speed
        cla(handles.ax2); hold(handles.ax2, 'on');
        plot(handles.ax2, th_deg, v_over_c, '-', ...
            'Color', [0.15 0.55 0.25], 'LineWidth', 2.0);
        plot(handles.ax2, theta_deg, v_r, 'o', ...
            'MarkerSize', 9, 'MarkerFaceColor', [0.85 0.25 0.15], ...
            'MarkerEdgeColor', [0.5 0.1 0.05], 'LineWidth', 1.4);
        xlim(handles.ax2, [0 180]);
        title(handles.ax2, 'Electron recoil speed  v / c', ...
            'Color', [0.1 0.1 0.1], 'FontSize', 12, 'FontWeight', 'bold');

        % Plot 3: recoil angle
        cla(handles.ax3); hold(handles.ax3, 'on');
        plot(handles.ax3, th_deg, phi_deg, '-', ...
            'Color', [0.6 0.25 0.1], 'LineWidth', 2.0);
        plot(handles.ax3, theta_deg, phi_r, 'o', ...
            'MarkerSize', 9, 'MarkerFaceColor', [0.85 0.25 0.15], ...
            'MarkerEdgeColor', [0.5 0.1 0.05], 'LineWidth', 1.4);
        xlim(handles.ax3, [0 180]);
        ylim(handles.ax3, [0 90]);
        title(handles.ax3, 'Electron recoil angle  φ', ...
            'Color', [0.1 0.1 0.1], 'FontSize', 12, 'FontWeight', 'bold');

        % --- Live numbers for current θ ---
        E     = h*c / lambda;                 % J
        E_eV  = E / eV;
        lambda_p = lambda + lambda_C*(1 - cos(theta));
        E_p   = h*c / lambda_p;
        K_eV  = (E - E_p) / eV;

        lines = {
            sprintf('θ = %.1f °', theta_deg)
            sprintf('λ = %.4f nm', lambda_nm)
            sprintf('λ′ = %.4f nm', lambda_p*1e9)
            sprintf('Δλ/λ = %.5f', dlam_r)
            ''
            sprintf('Incident energy E = %.1f eV', E_eV)
            sprintf('Electron KE K = %.1f eV', K_eV)
            sprintf('Recoil speed v/c = %.4f', v_r)
            sprintf('Recoil angle φ = %.2f °', phi_r)
            };
        handles.txtValues.Value = lines;

        handles.lblStatus.Text = sprintf( ...
            'θ = %.0f°  |  Δλ/λ = %.4f  |  v/c = %.3f  |  φ = %.1f°', ...
            theta_deg, dlam_r, v_r, phi_r);
    end

    function [dlam_over_lam, v_over_c, phi_deg] = compton_quantities(theta, lambda)
        % theta in radians, lambda in metres – works for scalar or vector
        dlam = lambda_C * (1 - cos(theta));
        dlam_over_lam = dlam ./ lambda;

        % Energies
        E  = h*c ./ lambda;
        Ep = h*c ./ (lambda + dlam);
        K  = E - Ep;                        % kinetic energy of electron

        % Relativistic factor
        gamma = 1 + K/(m_e*c^2);
        v_over_c = sqrt(max(0, 1 - 1./gamma.^2));   % max guards tiny negatives
        v_over_c(theta < 1e-8) = 0;

        % Recoil angle: cot φ = (1+α) tan(θ/2)
        alpha = lambda_C / lambda;          % = E/(m c²)
        tan_half = tan(theta/2);
        cot_phi  = (1 + alpha) .* tan_half;
        phi      = acot(cot_phi);
        phi(theta < 1e-8) = 0;
        phi_deg  = rad2deg(phi);
    end

    function resetDefaults()
        handles.sldTheta.Value = 90;
        handles.sldLam.Value   = 0.071;
        updateAll();
        handles.lblStatus.Text = 'Reset to θ = 90°, λ = 0.071 nm (Mo Kα)';
    end

    function exportResults()
        theta_deg = handles.sldTheta.Value;
        lambda_nm = handles.sldLam.Value;
        lambda = lambda_nm * 1e-9;
        theta  = deg2rad(theta_deg);

        [dlam_r, v_r, phi_r] = compton_quantities(theta, lambda);
        E_eV = (h*c/lambda)/eV;
        lambda_p = lambda + lambda_C*(1-cos(theta));
        K_eV = (h*c/lambda - h*c/lambda_p)/eV;

        report = sprintf([ ...
            'COMPTON SCATTERING – TASK #9\n' ...
            '==============================\n' ...
            'Incident wavelength λ = %.4f nm\n' ...
            'Photon scattering angle θ = %.2f °\n\n' ...
            'Scattered wavelength λ′ = %.4f nm\n' ...
            'Fractional shift Δλ/λ = %.6f\n' ...
            'Incident photon energy E = %.2f eV\n' ...
            'Electron kinetic energy K = %.2f eV\n' ...
            'Electron recoil speed v/c = %.5f\n' ...
            'Electron recoil angle φ = %.3f °\n\n' ...
            'Compton wavelength λ_C = %.4f pm\n'], ...
            lambda_nm, theta_deg, lambda_p*1e9, dlam_r, ...
            E_eV, K_eV, v_r, phi_r, lambda_C*1e12);

        [file, path] = uiputfile('Compton_Results.txt', 'Save results');
        if isequal(file, 0)
            handles.lblStatus.Text = 'Export cancelled.';
            return;
        end
        fid = fopen(fullfile(path, file), 'w');
        fprintf(fid, '%s', report);
        fclose(fid);
        handles.lblStatus.Text = sprintf('Exported → %s', file);
    end

end