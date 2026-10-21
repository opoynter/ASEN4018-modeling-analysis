function [allSets,sets] = buildComponentSetGUI(compNames, compMass, compCG, sets)
% BUILDCOMPONENTSETGUI  Multi-set GUI. Returns a struct array where each
%                       element has fields:  setName, components
%                       components is itself a struct array with fields:
%                       name, originalMass, weightFraction, scaledMass,
%                       cgX, cgY, cgZ

    n         = length(compNames);
    activeSet = 0;
    allSets   = [];

    % Per-component widget handles
    chkBoxes      = gobjects(n, 1);
    nameLabels    = gobjects(n, 1);
    pctFields     = gobjects(n, 1);
    pctLabels     = gobjects(n, 1);
    rowPanels     = gobjects(n, 1);
    setRowHandles = {};   % uibutton handles for sidebar rows

    % ---- Figure ---------------------------------------------------------
    figW = 1100;  figH = 680;
    fig = uifigure('Name', 'VSP Component Weight Set Builder', ...
                   'Position', [80 80 figW figH], ...
                   'Color', [0.10 0.11 0.14], ...
                   'Resize', 'off');

    % Header bar
    uipanel(fig, 'Position', [0 figH-52 figW 52], ...
        'BackgroundColor', [0.13 0.15 0.19], 'BorderType', 'none');
    uilabel(fig, 'Text', 'VSP Mass Properties  //  Component Weight Set Builder', ...
        'Position', [20 figH-38 700 26], ...
        'FontName', 'Consolas', 'FontSize', 14, 'FontWeight', 'bold', ...
        'FontColor', [0.85 0.90 0.95]);

    % ---- LEFT sidebar ---------------------------------------------------
    sideW = 230;
    uipanel(fig, 'Position', [0 0 sideW figH-52], ...
        'BackgroundColor', [0.11 0.13 0.16], 'BorderType', 'none');

    uilabel(fig, 'Text', 'WEIGHT SETS', ...
        'Position', [12 figH-78 140 18], ...
        'FontName', 'Consolas', 'FontSize', 9, 'FontWeight', 'bold', ...
        'FontColor', [0.40 0.45 0.52]);

    % "+ New Set" button
    uibutton(fig, 'push', 'Text', '+ New Set', ...
        'Position', [8 figH-100 sideW-16 26], ...
        'FontName', 'Consolas', 'FontSize', 10, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.14 0.28 0.48], ...
        'FontColor', [0.35 0.65 1.0], ...
        'ButtonPushedFcn', @(~,~) onNewSet());

    % Scrollable set list
    setListPanel = uipanel(fig, ...
        'Position', [8 118 sideW-16 figH-230], ...
        'BackgroundColor', [0.11 0.13 0.16], ...
        'BorderType', 'line', 'HighlightColor', [0.20 0.22 0.28], ...
        'Scrollable', 'on');

    setInner = uipanel(setListPanel, ...
        'Position', [0 0 sideW-22 200], ...
        'BackgroundColor', [0.11 0.13 0.16], 'BorderType', 'none');

    uibutton(fig, 'push', 'Text', 'Delete Set', ...
        'Position', [8 86 sideW-16 26], ...
        'FontName', 'Consolas', 'FontSize', 10, ...
        'BackgroundColor', [0.20 0.12 0.12], ...
        'FontColor', [0.75 0.35 0.35], ...
        'ButtonPushedFcn', @(~,~) onDeleteSet());

    uibutton(fig, 'push', 'Text', 'Done  —  Export All Sets', ...
        'Position', [8 50 sideW-16 30], ...
        'FontName', 'Consolas', 'FontSize', 10, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.12 0.30 0.20], ...
        'FontColor', [0.25 0.85 0.50], ...
        'ButtonPushedFcn', @(~,~) onFinish());

    uibutton(fig, 'push', 'Text', 'Cancel', ...
        'Position', [8 14 sideW-16 26], ...
        'FontName', 'Consolas', 'FontSize', 10, ...
        'BackgroundColor', [0.13 0.13 0.16], ...
        'FontColor', [0.45 0.48 0.55], ...
        'ButtonPushedFcn', @(~,~) onCancel());

    % Vertical divider
    uipanel(fig, 'Position', [sideW 0 2 figH-52], ...
        'BackgroundColor', [0.20 0.22 0.28], 'BorderType', 'none');

    % ---- RIGHT: component editor ----------------------------------------
    rightX = sideW + 10;
    rightW = figW - sideW - 18;

    uilabel(fig, 'Text', 'Set Name:', ...
        'Position', [rightX figH-78 72 22], ...
        'FontName', 'Consolas', 'FontSize', 10, ...
        'FontColor', [0.55 0.60 0.68]);

    fldSetName = uieditfield(fig, 'text', ...
        'Value', '', ...
        'Position', [rightX+78 figH-80 260 26], ...
        'FontName', 'Consolas', 'FontSize', 11, 'FontWeight', 'bold', ...
        'FontColor', [0.85 0.90 0.95], ...
        'BackgroundColor', [0.16 0.18 0.23], ...
        'Visible', 'off', ...
        'ValueChangedFcn', @(src,~) onSetNameChanged(src.Value));

    lblNoSet = uilabel(fig, ...
        'Text', 'Press  "+ New Set"  to get started.', ...
        'Position', [rightX+78 figH-80 400 26], ...
        'FontName', 'Consolas', 'FontSize', 11, ...
        'FontColor', [0.35 0.38 0.44]);

    btnSelAll = uibutton(fig, 'push', 'Text', 'Select All', ...
        'Position', [figW-220 figH-80 100 26], ...
        'FontName', 'Consolas', 'FontSize', 9, ...
        'BackgroundColor', [0.14 0.22 0.32], ...
        'FontColor', [0.35 0.65 1.0], ...
        'Visible', 'off', ...
        'ButtonPushedFcn', @(~,~) selectAll());

    btnClrAll = uibutton(fig, 'push', 'Text', 'Clear All', ...
        'Position', [figW-112 figH-80 100 26], ...
        'FontName', 'Consolas', 'FontSize', 9, ...
        'BackgroundColor', [0.14 0.14 0.17], ...
        'FontColor', [0.45 0.48 0.55], ...
        'Visible', 'off', ...
        'ButtonPushedFcn', @(~,~) clearAll());

    uipanel(fig, 'Position', [sideW+2 figH-88 figW-sideW-2 2], ...
        'BackgroundColor', [0.20 0.22 0.28], 'BorderType', 'none');

    % Scrollable component list
    compScroll = uipanel(fig, ...
        'Position', [rightX 96 rightW figH-192], ...
        'BackgroundColor', [0.10 0.11 0.14], ...
        'BorderType', 'line', 'HighlightColor', [0.20 0.22 0.28], ...
        'Scrollable', 'on');

    rowHeight = 62;  rowPad = 4;
    totalH    = n*(rowHeight+rowPad) + 10;
    innerPanel = uipanel(compScroll, ...
        'Position', [0 0 rightW-10 max(totalH, figH-200)], ...
        'BackgroundColor', [0.10 0.11 0.14], 'BorderType', 'none');

    for i = 1:n
        yPos = totalH - i*(rowHeight+rowPad) + rowPad;

        rowPanels(i) = uipanel(innerPanel, ...
            'Position', [4 yPos rightW-22 rowHeight], ...
            'BackgroundColor', [0.13 0.14 0.18], ...
            'BorderType', 'line', 'HighlightColor', [0.20 0.22 0.28]);

        chkBoxes(i) = uicheckbox(rowPanels(i), 'Text', '', ...
            'Position', [8 22 20 20], 'Value', false, ...
            'Enable', false, ...
            'ValueChangedFcn', @(src,~) onCheckChanged(i, src.Value));

        nameLabels(i) = uilabel(rowPanels(i), ...
            'Text', compNames(i), ...
            'Position', [34 36 380 20], ...
            'FontName', 'Consolas', 'FontSize', 12, 'FontWeight', 'bold', ...
            'FontColor', [0.50 0.54 0.62]);

        uilabel(rowPanels(i), ...
            'Text', sprintf('mass: %.4e', compMass(i)), ...
            'Position', [34 14 200 18], ...
            'FontName', 'Consolas', 'FontSize', 9, ...
            'FontColor', [0.38 0.42 0.48]);

        uilabel(rowPanels(i), ...
            'Text', sprintf('cg: [%.2f, %.2f, %.2f]', compCG(i,1), compCG(i,2), compCG(i,3)), ...
            'Position', [240 14 300 18], ...
            'FontName', 'Consolas', 'FontSize', 9, ...
            'FontColor', [0.32 0.36 0.42]);


        pctFields(i) = uieditfield(rowPanels(i), 'numeric', ...
            'Value', 100, ...
            'Position', [rightW-120 26 72 26], ...
            'FontName', 'Consolas', 'FontSize', 11, ...
            'FontColor', [0.35 0.65 1.0], ...
            'BackgroundColor', [0.08 0.09 0.12], ...
            'HorizontalAlignment', 'right', ...
            'Visible', 'off', ...
            'ValueChangedFcn', @(src,~) onPctChanged(i, src.Value));

        pctLabels(i) = uilabel(rowPanels(i), 'Text', '%', ...
            'Position', [rightW-45 28 18 20], ...
            'FontName', 'Consolas', 'FontSize', 11, ...
            'FontColor', [0.50 0.54 0.62], ...
            'Visible', 'off');
    end

    % Summary bar
    uipanel(fig, 'Position', [sideW+2 88 figW-sideW-2 2], ...
        'BackgroundColor', [0.20 0.22 0.28], 'BorderType', 'none');

    lblSelected = uilabel(fig, ...
        'Text', '', ...
        'Position', [rightX 64 280 22], ...
        'FontName', 'Consolas', 'FontSize', 10, ...
        'FontColor', [0.35 0.65 1.0]);

    lblTotalMass = uilabel(fig, ...
        'Text', '', ...
        'Position', [rightX+290 64 440 22], ...
        'FontName', 'Consolas', 'FontSize', 10, ...
        'FontColor', [0.25 0.75 0.45]);

    % Load pre-existing sets into the GUI if any were passed in
    if ~isempty(sets)
        rebuildSetList();
        switchToSet(1);
    end

    uiwait(fig);

    % =================================================================
    % Nested callbacks
    % =================================================================

    function onNewSet()
        newIdx      = length(sets) + 1;
        s.setName   = sprintf('Set %d', newIdx);
        s.included  = false(n, 1);
        s.weightPct = 100 * ones(n, 1);
        sets{end+1} = s;
        rebuildSetList();
        switchToSet(length(sets));
    end

    function onDeleteSet()
        if activeSet == 0 || isempty(sets), return; end
        sets(activeSet) = [];
        if isempty(sets)
            activeSet = 0;
            fldSetName.Visible = 'off';
            lblNoSet.Visible   = 'on';
            btnSelAll.Visible  = 'off';
            btnClrAll.Visible  = 'off';
            lblSelected.Text   = '';
            lblTotalMass.Text  = '';
            for k = 1:n
                chkBoxes(k).Enable = false;
                chkBoxes(k).Value  = false;
                applyRowStyle(k, false);
            end
        else
            switchToSet(min(activeSet, length(sets)));
        end
        rebuildSetList();
    end

    function onSetNameChanged(val)
        if activeSet == 0, return; end
        sets{activeSet}.setName = val;
        rebuildSetList();
    end

    function switchToSet(idx)
        if activeSet > 0 && activeSet <= length(sets)
            saveWidgets();
        end
        activeSet = idx;
        loadWidgets(idx);
        fldSetName.Visible = 'on';
        lblNoSet.Visible   = 'off';
        btnSelAll.Visible  = 'on';
        btnClrAll.Visible  = 'on';
        for k = 1:n
            chkBoxes(k).Enable = true;
        end
        rebuildSetList();
    end

    function saveWidgets()
        for k = 1:n
            sets{activeSet}.included(k)  = chkBoxes(k).Value;
            sets{activeSet}.weightPct(k) = pctFields(k).Value;
        end
    end

    function loadWidgets(idx)
        s = sets{idx};
        fldSetName.Value = s.setName;
        for k = 1:n
            chkBoxes(k).Value  = s.included(k);
            pctFields(k).Value = s.weightPct(k);
            applyRowStyle(k, s.included(k));
        end
        updateSummary();
    end

    function applyRowStyle(idx, isOn)
        if isOn
            nameLabels(idx).FontColor      = [0.85 0.90 0.95];
            rowPanels(idx).BackgroundColor = [0.08 0.14 0.22];
            rowPanels(idx).HighlightColor  = [0.22 0.40 0.65];
            pctFields(idx).Visible  = 'on';
            pctLabels(idx).Visible  = 'on';
        else
            nameLabels(idx).FontColor      = [0.50 0.54 0.62];
            rowPanels(idx).BackgroundColor = [0.13 0.14 0.18];
            rowPanels(idx).HighlightColor  = [0.20 0.22 0.28];
            pctFields(idx).Visible  = 'off';
            pctLabels(idx).Visible  = 'off';
        end
    end

    function onCheckChanged(idx, val)
        if activeSet == 0, return; end
        sets{activeSet}.included(idx) = val;
        applyRowStyle(idx, val);
        updateSummary();
    end

    function onPctChanged(idx, val)
        if activeSet == 0, return; end
        sets{activeSet}.weightPct(idx) = val;
        updateSummary();
    end

    function updateSummary()
        if activeSet == 0, return; end
        s    = sets{activeSet};
        nSel = sum(s.included);
        lblSelected.Text = sprintf('Selected: %d component(s)', nSel);
        if nSel == 0
            lblTotalMass.Text = 'Total Scaled Mass: —';
        else
            scaled = compMass(s.included) .* (s.weightPct(s.included) / 100);
            lblTotalMass.Text = sprintf('Total Scaled Mass: %.6e', sum(scaled));
        end
    end

    function selectAll()
        if activeSet == 0, return; end
        for k = 1:n
            sets{activeSet}.included(k) = true;
            chkBoxes(k).Value = true;
            applyRowStyle(k, true);
        end
        updateSummary();
    end

    function clearAll()
        if activeSet == 0, return; end
        for k = 1:n
            sets{activeSet}.included(k) = false;
            chkBoxes(k).Value = false;
            applyRowStyle(k, false);
        end
        updateSummary();
    end

    % ---- Set list sidebar (uibuttons instead of uilabels) ---------------
    function rebuildSetList()
        % Delete old rows
        for k = 1:length(setRowHandles)
            if isvalid(setRowHandles{k}), delete(setRowHandles{k}); end
        end
        setRowHandles = {};

        nSets   = length(sets);
        rH      = 48;  rPad = 4;
        totalSH = nSets*(rH+rPad) + 6;
        setInner.Position(4) = max(totalSH, 200);

        for k = 1:nSets
            yp    = totalSH - k*(rH+rPad) + rPad;
            isAct = (k == activeSet);

            if isAct
                bgc = [0.10 0.18 0.28];
                tc  = [0.75 0.88 1.00];
            else
                bgc = [0.13 0.14 0.18];
                tc  = [0.55 0.60 0.68];
            end

            kk  = k;
            nComp = sum(sets{k}.included);
            btnText = sprintf('%s\n%d component(s)', sets{k}.setName, nComp);

            rb = uibutton(setInner, 'push', ...
                'Text', btnText, ...
                'Position', [3 yp sideW-36 rH], ...
                'FontName', 'Consolas', 'FontSize', 10, ...
                'FontWeight', 'bold', ...
                'HorizontalAlignment', 'left', ...
                'BackgroundColor', bgc, ...
                'FontColor', tc, ...
                'ButtonPushedFcn', @(~,~) switchToSet(kk));
            setRowHandles{end+1} = rb;

            if isAct
                uipanel(setInner, ...
                    'Position', [3 yp 3 rH], ...
                    'BackgroundColor', [0.35 0.65 1.0], ...
                    'BorderType', 'none');
            end
        end
    end

    % ---- Export ---------------------------------------------------------
    function onFinish()
        if activeSet > 0, saveWidgets(); end

        if isempty(sets)
            allSets = [];
        else
            allSets = struct('setName', {}, 'components', {});
            for s = 1:length(sets)
                st     = sets{s};
                idxSel = find(st.included);
                comps  = struct('name',{}, 'originalMass',{}, ...
                                'weightFraction',{}, 'scaledMass',{}, ...
                                'cgX',{}, 'cgY',{}, 'cgZ',{});
                for k = 1:length(idxSel)
                    ii = idxSel(k);
                    comps(k).name           = char(compNames(ii));
                    comps(k).originalMass   = compMass(ii);
                    comps(k).weightFraction = st.weightPct(ii) / 100;
                    comps(k).scaledMass     = compMass(ii) * (st.weightPct(ii) / 100);
                    comps(k).cgX            = compCG(ii, 1);
                    comps(k).cgY            = compCG(ii, 2);
                    comps(k).cgZ            = compCG(ii, 3);
                end
                allSets(s).setName    = st.setName;
                allSets(s).components = comps;
            end
        end
        uiresume(fig);
        delete(fig);
    end

    function onCancel()
        allSets = [];
        uiresume(fig);
        delete(fig);
    end

end  % buildComponentSetGUI