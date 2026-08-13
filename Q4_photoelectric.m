function task04_photoelectric_effect
% TASK04_PHOTOELECTRIC_EFFECT
% Interactive analytical model of the photoelectric effect.
%
% The program plots stopping voltage against:
%   1) incident photon frequency
%   2) in-vacuum wavelength
%
% It also displays work functions, threshold frequencies and threshold
% wavelengths for selected metals.
%
% Core equation:
%       e V_s = h f - phi
%
% where photoemission occurs only when h f >= phi.
%
% Run using:
%       task04_photoelectric_effect

%% Physical constants (exact SI definitions)
h = 6.62607015e-34;       % Planck constant / J s
e = 1.602176634e-19;      % Elementary charge / C
c = 299792458;            % Speed of light / m s^-1

%% Metal data
% Representative work-function values retained from the original draft.
metalNames = {
    'Cesium (Cs)'
    'Sodium (Na)'
    'Calcium (Ca)'
    'Aluminum (Al)'
    'Platinum (Pt)'
    };

phi_eV = [2.14, 2.36, 2.87, 4.08, 5.64];
numMetals = numel(metalNames);
plotColors = lines(numMetals);

%% Plot ranges
frequency = linspace(0.30e15, 1.90e15, 1800);  % Hz
wavelength = linspace(150e-9, 850e-9, 1800);   % m
maxStoppingVoltage = 6.5;                       % V

%% User interface
fig = uifigure( ...
    'Name', 'BPhO Task 4 - Photoelectric Effect', ...
    'Color', 'white', ...
    'Position', [70 70 1500 830]);

mainGrid = uigridlayout(fig, [3 3]);
mainGrid.RowHeight = {54, '1x', 220};
mainGrid.ColumnWidth = {270, '1x', '1x'};
mainGrid.Padding = [14 12 14 14];
mainGrid.RowSpacing = 10;
mainGrid.ColumnSpacing = 12;

heading = uilabel(mainGrid, ...
    'Text', 'Photoelectric Effect: Stopping Voltage and Threshold Behaviour', ...
    'HorizontalAlignment', 'center', ...
    'FontSize', 23, ...
    'FontWeight', 'bold');
heading.Layout.Row = 1;
heading.Layout.Column = [1 3];

%% Control panel
controlPanel = uipanel(mainGrid, ...
    'Title', 'Display controls', ...
    'FontWeight', 'bold');
controlPanel.Layout.Row = [2 3];
controlPanel.Layout.Column = 1;

controlGrid = uigridlayout(controlPanel, [12 1]);
controlGrid.RowHeight = {30, 30, 30, 30, 30, 30, 36, 36, 16, 96, 28, '1x'};
controlGrid.Padding = [12 10 12 10];
controlGrid.RowSpacing = 7;

instruction = uilabel(controlGrid, ...
    'Text', 'Select the metals to compare:', ...
    'FontWeight', 'bold');

metalChecks = gobjects(numMetals, 1);
for k = 1:numMetals
    metalChecks(k) = uicheckbox(controlGrid, ...
        'Text', metalNames{k}, ...
        'Value', true, ...
        'ValueChangedFcn', @updatePlots);
end

buttonGrid = uigridlayout(controlGrid, [1 2]);
buttonGrid.ColumnWidth = {'1x', '1x'};
buttonGrid.Padding = [0 0 0 0];
buttonGrid.ColumnSpacing = 7;

uibutton(buttonGrid, ...
    'Text', 'Select all', ...
    'ButtonPushedFcn', @(~,~) setAllSelections(true));

uibutton(buttonGrid, ...
    'Text', 'Clear', ...
    'ButtonPushedFcn', @(~,~) setAllSelections(false));

resetButton = uibutton(controlGrid, ...
    'Text', 'Reset view', ...
    'ButtonPushedFcn', @resetView);

separator = uilabel(controlGrid, 'Text', '');

physicsBox = uitextarea(controlGrid, ...
    'Editable', 'off', ...
    'Value', {
        'Einstein photoelectric equation:'
        'eV_s = hf - \phi'
        ''
        'Below threshold: no electrons emitted.'
        'Above threshold: V_s rises linearly with f.'
        });

slopeLabel = uilabel(controlGrid, ...
    'Text', sprintf('Universal gradient h/e = %.6e V s', h/e), ...
    'FontSize', 11, ...
    'FontWeight', 'bold', ...
    'WordWrap', 'on');

statusLabel = uilabel(controlGrid, ...
    'Text', '', ...
    'FontSize', 11, ...
    'WordWrap', 'on', ...
    'VerticalAlignment', 'top');

%% Plot axes
frequencyAxes = uiaxes(mainGrid);
frequencyAxes.Layout.Row = 2;
frequencyAxes.Layout.Column = 2;
frequencyAxes.FontSize = 12;
frequencyAxes.Box = 'on';
frequencyAxes.XGrid = 'on';
frequencyAxes.YGrid = 'on';
frequencyAxes.Title.String = 'Stopping Voltage vs Frequency';
frequencyAxes.Title.FontSize = 17;
frequencyAxes.Title.FontWeight = 'bold';
frequencyAxes.XLabel.String = 'Frequency, f (10^{15} Hz)';
frequencyAxes.YLabel.String = 'Stopping voltage, V_s (V)';
frequencyAxes.XLim = [frequency(1), frequency(end)] / 1e15;
frequencyAxes.YLim = [0, maxStoppingVoltage];

wavelengthAxes = uiaxes(mainGrid);
wavelengthAxes.Layout.Row = 2;
wavelengthAxes.Layout.Column = 3;
wavelengthAxes.FontSize = 12;
wavelengthAxes.Box = 'on';
wavelengthAxes.XGrid = 'on';
wavelengthAxes.YGrid = 'on';
wavelengthAxes.Title.String = 'Stopping Voltage vs Wavelength';
wavelengthAxes.Title.FontSize = 17;
wavelengthAxes.Title.FontWeight = 'bold';
wavelengthAxes.XLabel.String = 'In-vacuum wavelength, \lambda (nm)';
wavelengthAxes.YLabel.String = 'Stopping voltage, V_s (V)';
wavelengthAxes.XLim = [150, 850];
wavelengthAxes.YLim = [0, maxStoppingVoltage];

%% Results table
resultsTable = uitable(mainGrid);
resultsTable.Layout.Row = 3;
resultsTable.Layout.Column = [2 3];
resultsTable.ColumnName = {
    'Metal', ...
    'Work function / eV', ...
    'Threshold frequency / 10^{14} Hz', ...
    'Threshold wavelength / nm', ...
    'Numerical slope / 10^{-15} V s', ...
    'Slope error / %'};
resultsTable.ColumnEditable = false(1, 6);
resultsTable.ColumnWidth = {180, 130, 205, 185, 190, 120};
resultsTable.RowName = [];

%% Initial plot
updatePlots();

%% Nested callback functions
    function setAllSelections(value)
        for n = 1:numMetals
            metalChecks(n).Value = value;
        end
        updatePlots();
    end

    function resetView(~,~)
        frequencyAxes.XLim = [frequency(1), frequency(end)] / 1e15;
        frequencyAxes.YLim = [0, maxStoppingVoltage];
        wavelengthAxes.XLim = [150, 850];
        wavelengthAxes.YLim = [0, maxStoppingVoltage];
    end

    function updatePlots(~,~)
        selected = arrayfun(@(box) box.Value, metalChecks);

        cla(frequencyAxes);
        cla(wavelengthAxes);
        hold(frequencyAxes, 'on');
        hold(wavelengthAxes, 'on');

        frequencyAxes.XGrid = 'on';
        frequencyAxes.YGrid = 'on';
        wavelengthAxes.XGrid = 'on';
        wavelengthAxes.YGrid = 'on';

        drawVisibleSpectrum(wavelengthAxes, maxStoppingVoltage);

        tableRows = cell(sum(selected), 6);
        row = 0;
        maximumSlopeError = 0;
        frequencyLineHandles = gobjects(0);
        wavelengthLineHandles = gobjects(0);
        legendNames = {};

        for index = 1:numMetals
            if ~selected(index)
                continue
            end

            row = row + 1;
            workFunctionJ = phi_eV(index) * e;
            thresholdFrequency = workFunctionJ / h;
            thresholdWavelength = h*c / workFunctionJ;

            % Frequency representation
            activeFrequency = frequency >= thresholdFrequency;
            fPlot = frequency(activeFrequency);
            voltageFromFrequency = (h/e).*fPlot - phi_eV(index);

            if ~isempty(fPlot)
                frequencyLineHandles(end+1) = plot(frequencyAxes, ...
                    fPlot/1e15, voltageFromFrequency, ...
                    'LineWidth', 2.5, ...
                    'Color', plotColors(index,:)); %#ok<AGROW>

                plot(frequencyAxes, thresholdFrequency/1e15, 0, 'o', ...
                    'MarkerSize', 7, ...
                    'MarkerFaceColor', plotColors(index,:), ...
                    'MarkerEdgeColor', plotColors(index,:), ...
                    'HandleVisibility', 'off');

                % Numerical line fit used as a code validation check.
                fitCoefficients = polyfit(fPlot, voltageFromFrequency, 1);
                numericalSlope = fitCoefficients(1);
                slopeError = 100*abs(numericalSlope - h/e)/(h/e);
            else
                numericalSlope = NaN;
                slopeError = NaN;
            end

            % Wavelength representation
            activeWavelength = wavelength <= thresholdWavelength;
            lambdaPlot = wavelength(activeWavelength);
            voltageFromWavelength = h*c./(e.*lambdaPlot) - phi_eV(index);

            if ~isempty(lambdaPlot)
                wavelengthLineHandles(end+1) = plot(wavelengthAxes, ...
                    lambdaPlot/1e-9, voltageFromWavelength, ...
                    'LineWidth', 2.5, ...
                    'Color', plotColors(index,:)); %#ok<AGROW>

                plot(wavelengthAxes, thresholdWavelength/1e-9, 0, 'o', ...
                    'MarkerSize', 7, ...
                    'MarkerFaceColor', plotColors(index,:), ...
                    'MarkerEdgeColor', plotColors(index,:), ...
                    'HandleVisibility', 'off');
            end

            legendNames{end+1} = metalNames{index}; %#ok<AGROW>

            tableRows(row,:) = {
                metalNames{index}, ...
                sprintf('%.2f', phi_eV(index)), ...
                sprintf('%.3f', thresholdFrequency/1e14), ...
                sprintf('%.1f', thresholdWavelength/1e-9), ...
                sprintf('%.6f', numericalSlope/1e-15), ...
                sprintf('%.3g', slopeError)};

            if isfinite(slopeError)
                maximumSlopeError = max(maximumSlopeError, slopeError);
            end
        end

        % Restore labels because cla can reset some axes properties.
        formatAxes();

        if any(selected)
            legend(frequencyAxes, frequencyLineHandles, legendNames, ...
                'Location', 'northwest');
            legend(wavelengthAxes, wavelengthLineHandles, legendNames, ...
                'Location', 'northeast');
            resultsTable.Data = tableRows;

            statusLabel.Text = sprintf([ ...
                '%d metal(s) selected.\n\n' ...
                'Threshold markers show V_s = 0.\n\n' ...
                'Largest numerical gradient error: %.3g %%'], ...
                sum(selected), maximumSlopeError);
        else
            resultsTable.Data = cell(0,6);
            statusLabel.Text = 'No metals selected. Choose at least one metal to display its threshold behaviour.';
        end

        hold(frequencyAxes, 'off');
        hold(wavelengthAxes, 'off');
    end

    function formatAxes()
        frequencyAxes.Title.String = 'Stopping Voltage vs Frequency';
        frequencyAxes.Title.FontSize = 17;
        frequencyAxes.Title.FontWeight = 'bold';
        frequencyAxes.XLabel.String = 'Frequency, f (10^{15} Hz)';
        frequencyAxes.YLabel.String = 'Stopping voltage, V_s (V)';
        frequencyAxes.XLim = [frequency(1), frequency(end)]/1e15;
        frequencyAxes.YLim = [0, maxStoppingVoltage];
        frequencyAxes.Box = 'on';
        frequencyAxes.XGrid = 'on';
        frequencyAxes.YGrid = 'on';

        wavelengthAxes.Title.String = 'Stopping Voltage vs Wavelength';
        wavelengthAxes.Title.FontSize = 17;
        wavelengthAxes.Title.FontWeight = 'bold';
        wavelengthAxes.XLabel.String = 'In-vacuum wavelength, \lambda (nm)';
        wavelengthAxes.YLabel.String = 'Stopping voltage, V_s (V)';
        wavelengthAxes.XLim = [150, 850];
        wavelengthAxes.YLim = [0, maxStoppingVoltage];
        wavelengthAxes.Box = 'on';
        wavelengthAxes.XGrid = 'on';
        wavelengthAxes.YGrid = 'on';
    end
end

function drawVisibleSpectrum(ax, maximumVoltage)
% Add low-opacity wavelength bands to identify the visible region.
% Approximate divisions are used only as a visual guide.

bands = [
    380 450
    450 495
    495 570
    570 590
    590 620
    620 750];

bandColors = [
    0.48 0.18 0.75
    0.15 0.38 0.95
    0.10 0.65 0.30
    0.95 0.85 0.10
    0.98 0.50 0.08
    0.85 0.10 0.10];

for k = 1:size(bands,1)
    patch(ax, ...
        [bands(k,1), bands(k,2), bands(k,2), bands(k,1)], ...
        [0, 0, maximumVoltage, maximumVoltage], ...
        bandColors(k,:), ...
        'FaceAlpha', 0.055, ...
        'EdgeColor', 'none', ...
        'HandleVisibility', 'off');
end

xline(ax, 380, ':', 'Visible', ...
    'Color', [0.35 0.35 0.35], ...
    'LabelVerticalAlignment', 'bottom', ...
    'HandleVisibility', 'off');
xline(ax, 750, ':', ...
    'Color', [0.35 0.35 0.35], ...
    'HandleVisibility', 'off');
end
