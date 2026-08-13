function QuantumCryptography_Task8
% =========================================================================
%  TASK #8: QUANTUM CRYPTOGRAPHY
%  Visual calculator of classical and quantum mismatch probabilities
%  for the detection of polarized entangled photons.
% =========================================================================
%
%  PHYSICS SUMMARY (detailed annotations)
%  ---------------------------------------
%  Two photons are prepared in the polarization-entangled singlet state
%
%        |ψ⟩ = ( |H V⟩ − |V H⟩ ) / √2
%
%  Alice measures with polarizer at angle θ, Bob at angle φ.
%  Relative angle α = θ − φ.
%
%  Quantum-mechanical correlation function:
%        E(α) = − cos(2α)
%
%  Probability that Alice and Bob obtain *different* outcomes (mismatch):
%        P_Q(α) = [1 − E(α)] / 2 = cos²(α)
%
%  Classical local-realistic (hidden-variable) model yields a linear
%  dependence on the relative angle (standard textbook comparison):
%        P_C(α) = (2/π) · |α|     for α ∈ [−π/2 , π/2]
%  (normalized so that P_C(±90°) = 1).
%
%  The quantum prediction is more strongly anti-correlated than any
%  classical model allows, which is the origin of Bell-inequality
%  violation and of the security of entanglement-based quantum
%  key distribution (E91 protocol).
%
%  INTERACTIVE FEATURES
%  --------------------
%  • Sliders for Alice's angle θ and Bob's angle φ (0–180°)
%  • Live relative angle α and both mismatch probabilities
%  • Plot of classical vs quantum mismatch probability vs α
%  • Schematic of the two detector orientations
%  • Numerical readout and export
%  • Plain light UI, detailed annotations
%
%  
% =========================================================================

    % Close previous instance
    delete(findall(0, 'Type', 'figure', 'Tag', 'QuantumCryptoApp'));

    % =====================================================================
    % DEFAULTS
    % =====================================================================
    theta0 = 0;      % degrees
    phi0   = 22.5;   % degrees (classic Bell angle)

    % =====================================================================
    % MAIN FIGURE – plain light background
    % =====================================================================
    fig = uifigure( ...
        'Name',     'Quantum Cryptography – Task #8 | Mismatch Calculator', ...
        'Tag',      'QuantumCryptoApp', ...
        'Position', [50 40 1280 780], ...
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

    leftGrid = uigridlayout(leftPanel, [12 1]);
    leftGrid.RowHeight = {26, 50, 26, 50, 30, 100, 40, 40, 26, '1x', 30};
    leftGrid.Padding = [10 10 10 10];
    leftGrid.RowSpacing = 8;
    leftGrid.BackgroundColor = [0.96 0.96 0.96];

    % --- Alice angle θ ---
    uilabel(leftGrid, 'Text', 'Alice detector angle θ (°)', ...
        'FontSize', 12, 'FontWeight', 'bold', 'FontColor', [0.1 0.1 0.1], ...
        'HorizontalAlignment', 'center');

    thPanel = uigridlayout(leftGrid, [1 2]);
    thPanel.ColumnWidth = {'1x', 60};
    thPanel.Padding = [0 0 0 0];
    thPanel.BackgroundColor = [0.96 0.96 0.96];

    sldTheta = uislider(thPanel, ...
        'Limits', [0 180], 'Value', theta0, ...
        'MajorTicks', 0:45:180, ...
        'FontColor', [0.2 0.2 0.2], ...
        'Tooltip', 'Orientation of Alice polarizer (Detector A)');

    lblTheta = uilabel(thPanel, ...
        'Text', sprintf('%.1f°', theta0), ...
        'FontSize', 13, 'FontWeight', 'bold', ...
        'FontColor', [0.0 0.45 0.15], ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor', [0.90 0.95 0.90]);

    % --- Bob angle φ ---
    uilabel(leftGrid, 'Text', 'Bob detector angle φ (°)', ...
        'FontSize', 12, 'FontWeight', 'bold', 'FontColor', [0.1 0.1 0.1], ...
        'HorizontalAlignment', 'center');

    phPanel = uigridlayout(leftGrid, [1 2]);
    phPanel.ColumnWidth = {'1x', 60};
    phPanel.Padding = [0 0 0 0];
    phPanel.BackgroundColor = [0.96 0.96 0.96];

    sldPhi = uislider(phPanel, ...
        'Limits', [0 180], 'Value', phi0, ...
        'MajorTicks', 0:45:180, ...
        'FontColor', [0.2 0.2 0.2], ...
        'Tooltip', 'Orientation of Bob polarizer (Detector B)');

    lblPhi = uilabel(phPanel, ...
        'Text', sprintf('%.1f°', phi0), ...
        'FontSize', 13, 'FontWeight', 'bold', ...
        'FontColor', [0.0 0.3 0.55], ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor', [0.90 0.93 0.97]);

    % --- Live results ---
    uilabel(leftGrid, 'Text', 'Live Mismatch Probabilities', ...
        'FontSize', 11, 'FontWeight', 'bold', 'FontColor', [0.1 0.1 0.1], ...
        'HorizontalAlignment', 'center');

    txtValues = uitextarea(leftGrid, ...
        'Value', {''}, 'Editable', 'off', ...
        'FontName', 'Consolas', 'FontSize', 12, ...
        'FontColor', [0.1 0.1 0.1], ...
        'BackgroundColor', [1 1 1]);

    % Buttons
    btnReset = uibutton(leftGrid, ...
        'Text', 'Reset to classic Bell angles (0°, 22.5°)', ...
        'FontWeight', 'bold', 'FontSize', 11, ...
        'BackgroundColor', [0.85 0.92 0.85], ...
        'FontColor', [0.05 0.25 0.1]);

    btnExport = uibutton(leftGrid, ...
        'Text', 'Export Current Results', ...
        'FontWeight', 'bold', ...
        'BackgroundColor', [0.95 0.92 0.85], ...
        'FontColor', [0.3 0.2 0.05]);

    % Theory box
    uilabel(leftGrid, 'Text', 'Key Equations', ...
        'FontSize', 11, 'FontWeight', 'bold', 'FontColor', [0.1 0.1 0.1], ...
        'HorizontalAlignment', 'center');

    txtTheory = uitextarea(leftGrid, ...
        'Value', { ...
            'Relative angle α = θ − φ', ...
            '', ...
            'Quantum (singlet state):', ...
            '  E(α) = −cos(2α)', ...
            '  P_mismatch^Q = cos²(α)', ...
            '', ...
            'Classical (local realistic):', ...
            '  P_mismatch^C = (2/π)·|α|', ...
            '', ...
            'At α = 22.5° quantum is more', ...
            'anti-correlated than classical.'}, ...
        'Editable', 'off', ...
        'FontName', 'Consolas', 'FontSize', 10, ...
        'FontColor', [0.15 0.15 0.15], ...
        'BackgroundColor', [1 1 1]);

    % Status
    lblStatus = uilabel(leftGrid, ...
        'Text', 'Ready – move the angle sliders.', ...
        'FontSize', 10, 'FontColor', [0.2 0.3 0.4], ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor', [0.92 0.92 0.92]);

    % =====================================================================
    % RIGHT PANEL – VISUALISATION
    % =====================================================================
    rightPanel = uipanel(mainGrid, ...
        'Title', '  DETECTOR SCHEMATIC  |  MISMATCH PROBABILITY CURVES', ...
        'FontName', 'Segoe UI', 'FontSize', 13, 'FontWeight', 'bold', ...
        'ForegroundColor', [0.1 0.1 0.1], ...
        'BackgroundColor', [0.96 0.96 0.96], ...
        'BorderType', 'line', 'HighlightColor', [0.5 0.5 0.5]);

    rightGrid = uigridlayout(rightPanel, [2 1]);
    rightGrid.RowHeight = {'0.85x', '1.15x'};
    rightGrid.Padding = [8 8 8 8];
    rightGrid.RowSpacing = 10;
    rightGrid.BackgroundColor = [0.96 0.96 0.96];

    % Detector schematic axes
    axSchem = uiaxes(rightGrid, ...
        'BackgroundColor', [1 1 1], ...
        'XColor', [0.3 0.3 0.3], 'YColor', [0.3 0.3 0.3], ...
        'FontName', 'Segoe UI', 'FontSize', 10, ...
        'Box', 'on');
    title(axSchem, 'Detector orientations (Alice green, Bob blue)', ...
        'Color', [0.1 0.1 0.1], 'FontSize', 12, 'FontWeight', 'bold');
    axis(axSchem, 'equal');
    hold(axSchem, 'on');
    xlim(axSchem, [-1.6 1.6]);
    ylim(axSchem, [-1.2 1.2]);
    axSchem.XTick = []; axSchem.YTick = [];

    % Probability curves axes
    axProb = uiaxes(rightGrid, ...
        'BackgroundColor', [1 1 1], ...
        'XColor', [0.2 0.2 0.2], 'YColor', [0.2 0.2 0.2], ...
        'FontName', 'Segoe UI', 'FontSize', 10, ...
        'Box', 'on', 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.5);
    title(axProb, 'Mismatch probability vs relative angle α', ...
        'Color', [0.1 0.1 0.1], 'FontSize', 12, 'FontWeight', 'bold');
    xlabel(axProb, 'Relative angle α = θ − φ  (degrees)', 'Color', [0.2 0.2 0.2]);
    ylabel(axProb, 'Mismatch probability', 'Color', [0.2 0.2 0.2]);
    grid(axProb, 'on');
    hold(axProb, 'on');
    ylim(axProb, [0 1.05]);

    % =====================================================================
    % CALLBACKS
    % =====================================================================
    sldTheta.ValueChangedFcn = @(~,~) updateAll();
    sldPhi.ValueChangedFcn   = @(~,~) updateAll();
    btnReset.ButtonPushedFcn = @(~,~) resetAngles();
    btnExport.ButtonPushedFcn = @(~,~) exportResults();

    handles = struct();
    handles.sldTheta  = sldTheta;
    handles.lblTheta  = lblTheta;
    handles.sldPhi    = sldPhi;
    handles.lblPhi    = lblPhi;
    handles.txtValues = txtValues;
    handles.axSchem   = axSchem;
    handles.axProb    = axProb;
    handles.lblStatus = lblStatus;
    handles.fig       = fig;

    % Initial draw
    updateAll();

    % =====================================================================
    % NESTED FUNCTIONS
    % =====================================================================

    function updateAll()
        theta = handles.sldTheta.Value;
        phi   = handles.sldPhi.Value;
        handles.lblTheta.Text = sprintf('%.1f°', theta);
        handles.lblPhi.Text   = sprintf('%.1f°', phi);

        alpha_deg = theta - phi;
        alpha_rad = deg2rad(alpha_deg);

        % --- Probabilities ---
        % Quantum: P_mismatch = cos²(α)
        P_Q = cos(alpha_rad).^2;

        % Classical linear model (standard comparison)
        % Fold into [−90, 90] for the linear piece
        a_fold = mod(alpha_deg + 90, 180) - 90;   % → [−90, 90]
        P_C = (2/pi) * abs(deg2rad(a_fold));

        % Live text
        lines = {
            sprintf('Alice angle θ  = %6.1f °', theta)
            sprintf('Bob   angle φ  = %6.1f °', phi)
            sprintf('Relative α     = %6.1f °', alpha_deg)
            ''
            sprintf('Quantum mismatch  P_Q = %.4f', P_Q)
            sprintf('Classical mismatch P_C = %.4f', P_C)
            ''
            sprintf('Difference |P_Q − P_C| = %.4f', abs(P_Q - P_C))
            };
        handles.txtValues.Value = lines;

        % Status
        if abs(alpha_deg) < 1
            msg = 'α ≈ 0° → perfect anti-correlation (quantum)';
        elseif abs(abs(alpha_deg) - 22.5) < 2
            msg = 'α ≈ 22.5° → classic Bell angle (strong quantum advantage)';
        elseif abs(abs(alpha_deg) - 45) < 2
            msg = 'α ≈ 45° → maximum classical–quantum difference region';
        else
            msg = sprintf('α = %.1f°  |  P_Q = %.3f  |  P_C = %.3f', alpha_deg, P_Q, P_C);
        end
        handles.lblStatus.Text = msg;

        % ----- Schematic of detectors -----
        drawSchematic(theta, phi);

        % ----- Probability curves -----
        drawCurves(alpha_deg, P_Q, P_C);
    end

    function drawSchematic(theta, phi)
        cla(handles.axSchem);
        hold(handles.axSchem, 'on');

        % Alice (left) – green
        drawDetector(handles.axSchem, -0.9, 0, theta, [0.1 0.55 0.2], 'Alice (θ)');
        % Bob (right) – blue
        drawDetector(handles.axSchem,  0.9, 0, phi,   [0.1 0.3 0.6], 'Bob (φ)');

        % Entangled photons symbol in the middle
        plot(handles.axSchem, [0 0], [-0.25 0.25], 'r-', 'LineWidth', 2.5);
        plot(handles.axSchem, [-0.18 0.18], [0 0], 'r-', 'LineWidth', 2.5);
        text(handles.axSchem, 0, 0.45, 'Entangled', ...
            'HorizontalAlignment', 'center', 'FontSize', 10, ...
            'FontWeight', 'bold', 'Color', [0.7 0.1 0.1]);
        text(handles.axSchem, 0, -0.45, 'photons', ...
            'HorizontalAlignment', 'center', 'FontSize', 10, ...
            'FontWeight', 'bold', 'Color', [0.7 0.1 0.1]);

        xlim(handles.axSchem, [-1.7 1.7]);
        ylim(handles.axSchem, [-1.1 1.1]);
        axis(handles.axSchem, 'off');
    end

    function drawDetector(ax, cx, cy, ang_deg, col, label)
        % Draw a simple polarizer / detector schematic
        ang = deg2rad(ang_deg);
        len = 0.55;

        % Transmission axis (thick arrow)
        ux = len * cos(ang);
        uy = len * sin(ang);
        quiver(ax, cx, cy, ux, uy, 0, ...
            'Color', col, 'LineWidth', 2.8, 'MaxHeadSize', 0.8);
        quiver(ax, cx, cy, -ux, -uy, 0, ...
            'Color', col, 'LineWidth', 1.2, 'MaxHeadSize', 0.4);

        % Orthogonal axis (dashed)
        vx = len * 0.7 * cos(ang + pi/2);
        vy = len * 0.7 * sin(ang + pi/2);
        plot(ax, [cx-vx cx+vx], [cy-vy cy+vy], '--', ...
            'Color', col*0.7 + 0.3, 'LineWidth', 1.2);

        % Label
        text(ax, cx, cy - 0.85, label, ...
            'HorizontalAlignment', 'center', 'FontSize', 11, ...
            'FontWeight', 'bold', 'Color', col);
    end

    function drawCurves(alpha_now, P_Q_now, P_C_now)
        cla(handles.axProb);
        hold(handles.axProb, 'on');

        % Full curves
        a_deg = linspace(-90, 90, 400);
        a_rad = deg2rad(a_deg);

        P_Q_curve = cos(a_rad).^2;
        P_C_curve = (2/pi) * abs(a_rad);

        plot(handles.axProb, a_deg, P_Q_curve, '-', ...
            'Color', [0.15 0.55 0.25], 'LineWidth', 2.2, ...
            'DisplayName', 'Quantum  P_Q = cos²(α)');
        plot(handles.axProb, a_deg, P_C_curve, '--', ...
            'Color', [0.7 0.25 0.1], 'LineWidth', 2.0, ...
            'DisplayName', 'Classical  P_C = (2/π)|α|');

        % Current point
        plot(handles.axProb, alpha_now, P_Q_now, 'o', ...
            'MarkerSize', 10, 'MarkerFaceColor', [0.15 0.55 0.25], ...
            'MarkerEdgeColor', [0.05 0.3 0.1], 'LineWidth', 1.5, ...
            'HandleVisibility', 'off');
        plot(handles.axProb, alpha_now, P_C_now, 's', ...
            'MarkerSize', 10, 'MarkerFaceColor', [0.7 0.25 0.1], ...
            'MarkerEdgeColor', [0.4 0.1 0.05], 'LineWidth', 1.5, ...
            'HandleVisibility', 'off');

        % Vertical line at current α
        xline(handles.axProb, alpha_now, ':', ...
            'Color', [0.4 0.4 0.4], 'LineWidth', 1.2, ...
            'HandleVisibility', 'off');

        legend(handles.axProb, 'Location', 'north', 'FontSize', 10);
        xlim(handles.axProb, [-90 90]);
        ylim(handles.axProb, [0 1.05]);
        title(handles.axProb, sprintf( ...
            'Mismatch probability  (current α = %.1f°)', alpha_now), ...
            'Color', [0.1 0.1 0.1], 'FontSize', 12, 'FontWeight', 'bold');
    end

    function resetAngles()
        handles.sldTheta.Value = 0;
        handles.sldPhi.Value   = 22.5;
        updateAll();
        handles.lblStatus.Text = 'Reset to classic Bell angles (θ = 0°, φ = 22.5°)';
    end

    function exportResults()
        theta = handles.sldTheta.Value;
        phi   = handles.sldPhi.Value;
        alpha = theta - phi;
        a_rad = deg2rad(alpha);
        P_Q = cos(a_rad).^2;
        a_fold = mod(alpha + 90, 180) - 90;
        P_C = (2/pi) * abs(deg2rad(a_fold));

        report = sprintf([ ...
            'QUANTUM CRYPTOGRAPHY – TASK #8\n' ...
            'Mismatch probability calculator\n' ...
            '================================\n' ...
            'Alice angle θ = %.2f °\n' ...
            'Bob   angle φ = %.2f °\n' ...
            'Relative α   = %.2f °\n\n' ...
            'Quantum mismatch  P_Q = cos²(α)     = %.6f\n' ...
            'Classical mismatch P_C = (2/π)|α|   = %.6f\n' ...
            'Difference |P_Q − P_C|              = %.6f\n\n' ...
            'Note: At α = ±22.5° the quantum prediction is\n' ...
            'noticeably more anti-correlated than the classical\n' ...
            'local-realistic bound – the basis of Bell tests\n' ...
            'and of the security of entanglement-based QKD.\n'], ...
            theta, phi, alpha, P_Q, P_C, abs(P_Q - P_C));

        [file, path] = uiputfile('QuantumCrypto_Results.txt', 'Save results');
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