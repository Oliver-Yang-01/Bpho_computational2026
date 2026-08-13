function task05_hydrogen_emission
% TASK05_HYDROGEN_EMISSION
% Interactive Bohr-model explorer for the hydrogen emission spectrum.
%
% Features
%   * Photon energy vs wavelength for Lyman-Pfund series
%   * Normal (left-to-right) logarithmic wavelength axis
%   * Selectable spectral series and maximum initial quantum number
%   * Visible-region shading
%   * Clickable transition points with a linked energy-level diagram
%   * Numerical comparison with the Rydberg equation
%
% Run with:
%   task05_hydrogen_emission

%% Physical constants
h_eVs   = 4.135667696e-15;      % Planck constant [eV s]
c       = 299792458;            % Speed of light [m s^-1]
hc_eVnm = h_eVs*c*1e9;          % hc [eV nm]
E0      = 13.605693122994;       % Rydberg energy [eV]
Rinf    = 10973731.568160;       % Rydberg constant [m^-1]

seriesNames = {'Lyman','Balmer','Paschen','Brackett','Pfund'};
seriesNf    = 1:5;
seriesColor = [ ...
    0.84 0.16 0.16; ...          % Lyman
    0.12 0.45 0.80; ...          % Balmer
    0.10 0.62 0.36; ...          % Paschen
    0.58 0.32 0.78; ...          % Brackett
    0.90 0.55 0.08];             % Pfund

%% Figure
fig = figure('Name','Task 5 - Hydrogen Emission Explorer', ...
    'NumberTitle','off', ...
    'Color','w', ...
    'Position',[80 60 1420 820]);

% Main title
uicontrol(fig,'Style','text','Units','normalized', ...
    'Position',[0.02 0.945 0.96 0.04], ...
    'String','Hydrogen Emission Spectrum - Bohr Model', ...
    'FontSize',17,'FontWeight','bold', ...
    'BackgroundColor','w');

%% Controls
uicontrol(fig,'Style','text','Units','normalized', ...
    'Position',[0.025 0.895 0.13 0.027], ...
    'String','Maximum initial n:', ...
    'HorizontalAlignment','left','FontWeight','bold', ...
    'BackgroundColor','w');

nValueText = uicontrol(fig,'Style','text','Units','normalized', ...
    'Position',[0.155 0.895 0.035 0.027], ...
    'String','10','FontWeight','bold', ...
    'BackgroundColor','w');   

nSlider = uicontrol(fig,'Style','slider','Units','normalized', ...
    'Position',[0.025 0.865 0.165 0.025], ...
    'Min',2,'Max',30,'Value',10, ...
    'SliderStep',[1/28 4/28], ...
    'Callback',@updatePlot);

uicontrol(fig,'Style','text','Units','normalized', ...
    'Position',[0.22 0.895 0.075 0.027], ...
    'String','Show series:', ...
    'HorizontalAlignment','left','FontWeight','bold', ...
    'BackgroundColor','w');

checkBox = gobjects(1,5);
xCB = [0.30 0.39 0.49 0.59 0.69];
for k = 1:5
    checkBox(k) = uicontrol(fig,'Style','checkbox','Units','normalized', ...
        'Position',[xCB(k) 0.865 0.10 0.055], ...
        'String',sprintf('%s (n_f=%d)',seriesNames{k},seriesNf(k)), ...
        'Value',k<=3, ...
        'BackgroundColor','w', ...
        'Callback',@updatePlot);
end

resetButton = uicontrol(fig,'Style','pushbutton','Units','normalized', ...
    'Position',[0.82 0.87 0.13 0.045], ...
    'String','Reset view', ...
    'FontWeight','bold', ...
    'Callback',@resetView); %#ok<NASGU>

%% Axes
axLevels = axes('Parent',fig,'Units','normalized', ...
    'Position',[0.055 0.20 0.29 0.62]);
axSpec = axes('Parent',fig,'Units','normalized', ...
    'Position',[0.405 0.20 0.55 0.62]);

%% Information panel
infoPanel = uipanel(fig,'Units','normalized', ...
    'Position',[0.055 0.035 0.90 0.115], ...
    'Title','Selected transition', ...
    'FontWeight','bold', ...
    'BackgroundColor','w');

infoText = uicontrol(infoPanel,'Style','text','Units','normalized', ...
    'Position',[0.015 0.08 0.97 0.82], ...
    'String','Select a point on the spectrum to inspect a transition.', ...
    'HorizontalAlignment','left', ...
    'FontSize',10.5, ...
    'BackgroundColor','w');

%% State
selectedTransition = [3 2];  % Default: H-alpha, 3 -> 2
currentData = [];

updatePlot();

%% ---------------------------------------------------------------------
    function updatePlot(~,~)
        nMax = round(get(nSlider,'Value'));
        set(nSlider,'Value',nMax);
        set(nValueText,'String',num2str(nMax));

        % Build transition table: [ni nf Ei Ef Ephoton lambda lambdaRydberg]
        rows = [];
        for ni = 2:nMax
            for nf = 1:min(5,ni-1)
                Ei = -E0/ni^2;
                Ef = -E0/nf^2;
                Eph = Ei - Ef;  % positive emitted-photon energy
                lambdaEnergy = hc_eVnm/Eph;
                invLambda = Rinf*(1/nf^2 - 1/ni^2);  % m^-1
                lambdaRydberg = 1e9/invLambda;
                rows(end+1,:) = [ni nf Ei Ef Eph lambdaEnergy lambdaRydberg]; %#ok<AGROW>
            end
        end

        selectedSeries = false(1,5);
        for k = 1:5
            selectedSeries(k) = logical(get(checkBox(k),'Value'));
        end

        if ~any(selectedSeries)
            % Keep the interface usable if everything is unticked.
            selectedSeries(2) = true;
            set(checkBox(2),'Value',1);
        end

        mask = false(size(rows,1),1);
        for k = 1:5
            if selectedSeries(k)
                mask = mask | rows(:,2)==k;
            end
        end
        currentData = rows(mask,:);

        drawSpectrum(selectedSeries,nMax);

        % Preserve current selection if it is still visible; otherwise choose
        % the first available transition.
        idx = find(currentData(:,1)==selectedTransition(1) & ...
                   currentData(:,2)==selectedTransition(2),1);
        if isempty(idx)
            selectedTransition = currentData(1,1:2);
            idx = 1;
        end
        showTransition(currentData(idx,:));

        % Enable data cursor so the user can click any plotted transition.
        dcm = datacursormode(fig);
        set(dcm,'Enable','on','UpdateFcn',@dataTipText,'SnapToDataVertex','on');
    end

%% ---------------------------------------------------------------------
    function drawSpectrum(selectedSeries,nMax)
        cla(axSpec);
        hold(axSpec,'on');

        set(axSpec,'XScale','log','XDir','normal','Box','on', ...
            'FontSize',10.5,'Layer','top');
        grid(axSpec,'on');

        % Visible-light region (approx. 380-750 nm)
        yMax = 14.4;
        patch(axSpec,[380 750 750 380],[0 0 yMax yMax], ...
            [0.93 0.93 0.93], ...
            'FaceAlpha',0.32,'EdgeColor','none', ...
            'HandleVisibility','off','HitTest','off');
        text(axSpec,sqrt(380*750),0.55,'visible', ...
            'HorizontalAlignment','center','Rotation',90, ...
            'Color',[0.35 0.35 0.35],'FontSize',9, ...
            'HitTest','off');

        legendHandles = gobjects(0);
        legendLabels = {};
        for k = 1:5
            if ~selectedSeries(k), continue; end
            subset = currentData(currentData(:,2)==k,:);
            if isempty(subset), continue; end

            hSc = scatter(axSpec,subset(:,6),subset(:,5),62, ...
                'MarkerFaceColor',seriesColor(k,:), ...
                'MarkerEdgeColor',[0.12 0.12 0.12], ...
                'LineWidth',0.8, ...
                'DisplayName',seriesNames{k});
            legendHandles(end+1) = hSc; %#ok<AGROW>
            legendLabels{end+1} = sprintf('%s (n_f=%d)',seriesNames{k},k); %#ok<AGROW>
        end

        % Highlight selection on the spectrum.
        selectedRow = currentData(currentData(:,1)==selectedTransition(1) & ...
                                  currentData(:,2)==selectedTransition(2),:);
        if ~isempty(selectedRow)
            plot(axSpec,selectedRow(1,6),selectedRow(1,5),'o', ...
                'MarkerSize',13,'MarkerFaceColor','none', ...
                'MarkerEdgeColor','k','LineWidth',2.0, ...
                'HandleVisibility','off','HitTest','off', ...
                'Tag','SelectedTransitionRing');
        end

        xlabel(axSpec,'Wavelength, \lambda (nm)','FontWeight','bold');
        ylabel(axSpec,'Photon energy, E_\gamma (eV)','FontWeight','bold');
        title(axSpec,sprintf('Hydrogen photon emissions (n_i \\leq %d)',nMax), ...
            'FontWeight','bold');

        xlim(axSpec,[80 1e4]);
        ylim(axSpec,[0 yMax]);
        set(axSpec,'XTick',[100 200 400 700 1000 2000 5000 10000], ...
            'XTickLabel',{'100','200','400','700','1000','2000','5000','10000'});

        if ~isempty(legendHandles)
            legend(axSpec,legendHandles,legendLabels,'Location','northeast');
        end

        hold(axSpec,'off');
    end

%% ---------------------------------------------------------------------
    function showTransition(row)
        ni = row(1); nf = row(2);
        Ei = row(3); Ef = row(4); Eph = row(5);
        lambdaEnergy = row(6); lambdaRydberg = row(7);

        selectedTransition = [ni nf];
        k = nf;  % spectral-series index

        % Determine approximate electromagnetic region.
        if lambdaEnergy < 380
            region = 'ultraviolet';
        elseif lambdaEnergy <= 750
            region = visibleColourName(lambdaEnergy);
        elseif lambdaEnergy < 1e6
            region = 'infrared';
        else
            region = 'long-wavelength infrared';
        end

        pctDiff = 100*abs(lambdaEnergy-lambdaRydberg)/lambdaRydberg;

        set(infoText,'String',sprintf([ ...
            'Transition: n_i = %d  ->  n_f = %d    |    Series: %s\n' ...
            'E_i = %.4f eV,   E_f = %.4f eV,   photon energy = %.4f eV    |    ' ...
            '\\lambda = %.2f nm (%s)\n' ...
            'Rydberg check: %.2f nm    |    percentage difference = %.3g %%'], ...
            ni,nf,seriesNames{k},Ei,Ef,Eph,lambdaEnergy,region, ...
            lambdaRydberg,pctDiff));

        drawEnergyLevels(ni,nf,Ei,Ef,k);
        updateSelectionRing(lambdaEnergy,Eph);
    end

%% ---------------------------------------------------------------------
    function drawEnergyLevels(ni,nf,Ei,Ef,k)
        cla(axLevels);
        hold(axLevels,'on');
        set(axLevels,'Box','on','FontSize',10.5);
        grid(axLevels,'on');

        nMaxDisplay = max(6,min(10,round(get(nSlider,'Value'))));
        if ni > nMaxDisplay
            levels = unique([1:nMaxDisplay ni]);
        else
            levels = 1:nMaxDisplay;
        end

        for n = levels
            En = -E0/n^2;
            lw = 1.2;
            clr = [0.38 0.38 0.38];
            if n==ni || n==nf
                lw = 3.0;
                clr = seriesColor(k,:);
            end
            plot(axLevels,[0.18 0.88],[En En],'-','Color',clr,'LineWidth',lw);
            text(axLevels,0.91,En,sprintf('n=%d',n), ...
                'VerticalAlignment','middle','FontSize',9.5);
        end

        % Ionisation limit
        plot(axLevels,[0.18 0.88],[0 0],'--','Color',[0.25 0.25 0.25], ...
            'LineWidth',1.2);
        text(axLevels,0.91,0,'n=\infty','VerticalAlignment','middle','FontSize',9.5);

        % Emission arrow, from initial to final level
        quiver(axLevels,0.53,Ei,0,Ef-Ei,0, ...
            'Color',seriesColor(k,:), ...
            'LineWidth',2.5,'MaxHeadSize',0.45);
        text(axLevels,0.57,(Ei+Ef)/2, ...
            sprintf('  photon\n  %.3f eV',Ei-Ef), ...
            'Color',seriesColor(k,:),'FontWeight','bold', ...
            'VerticalAlignment','middle');

        xlim(axLevels,[0 1.16]);
        ylim(axLevels,[-14.2 0.8]);
        set(axLevels,'XTick',[]);
        ylabel(axLevels,'Electron energy (eV)','FontWeight','bold');
        title(axLevels,sprintf('Energy levels: n=%d \\rightarrow n=%d',ni,nf), ...
            'FontWeight','bold');
        hold(axLevels,'off');
    end


%% ---------------------------------------------------------------------
    function updateSelectionRing(lambdaNm,Eph)
        % Move the black selection ring without rebuilding the spectrum.
        oldRing = findobj(axSpec,'Tag','SelectedTransitionRing');
        if ~isempty(oldRing)
            delete(oldRing);
        end
        hold(axSpec,'on');
        plot(axSpec,lambdaNm,Eph,'o', ...
            'MarkerSize',13,'MarkerFaceColor','none', ...
            'MarkerEdgeColor','k','LineWidth',2.0, ...
            'HandleVisibility','off','HitTest','off', ...
            'Tag','SelectedTransitionRing');
        hold(axSpec,'off');
    end

%% ---------------------------------------------------------------------
    function txt = dataTipText(~,eventObj)
        pos = eventObj.Position;

        % Nearest point in relative log-wavelength / energy coordinates.
        dx = abs(log10(currentData(:,6))-log10(pos(1)));
        dy = abs(currentData(:,5)-pos(2))/14;
        [~,idx] = min(dx+dy);
        row = currentData(idx,:);

        showTransition(row);

        txt = {sprintf('n_i=%d -> n_f=%d',row(1),row(2)), ...
               sprintf('%s series',seriesNames{row(2)}), ...
               sprintf('E_\\gamma = %.4f eV',row(5)), ...
               sprintf('\\lambda = %.2f nm',row(6))};
    end

%% ---------------------------------------------------------------------
    function resetView(~,~)
        set(nSlider,'Value',10);
        for q = 1:5
            set(checkBox(q),'Value',q<=3);
        end
        selectedTransition = [3 2];
        updatePlot();
    end

%% ---------------------------------------------------------------------
    function name = visibleColourName(lambdaNm)
        % Descriptive label only; wavelength boundaries are approximate.
        if lambdaNm < 450
            name = 'visible violet/blue';
        elseif lambdaNm < 495
            name = 'visible blue';
        elseif lambdaNm < 570
            name = 'visible green';
        elseif lambdaNm < 590
            name = 'visible yellow';
        elseif lambdaNm < 620
            name = 'visible orange';
        else
            name = 'visible red';
        end
    end
end
