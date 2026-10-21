function updateVSPWeightsGUI(txtFileName, vspFileName, calculatedWeights)
    %Jonathan Morris 3/19/2026
    %This function updates a vsp3 file based on user input
    %% Read mass props file.
    %Note this uses a custom code to read in a specific format. Normaly
    %readmatrix/readcell etc don't work here
    fid = fopen(txtFileName, 'r');

    if fid == -1
        error('Could not open file: %s. Make sure you are passing the Mass Props TXT file.', txtFileName);
    end
    namesList = {};
    volList = [];
    while ~feof(fid)
        line = strtrim(fgetl(fid));
        if startsWith(line, 'Name') && contains(line, 'Mass') && contains(line, 'Volume')
            break;
        end
    end

    % Read the data rows
    while ~feof(fid)
        line = strtrim(fgetl(fid));
        if isempty(line) || startsWith(line, 'Totals') || startsWith(line, '...Filling')
            break;
        end

        parts = strsplit(line);

        % The Mass Props file has exactly 11 number columns after the name.
        % ASSUMES THE  last column is always Volume.
        if length(parts) > 11
            volVal = str2double(parts{end});

            % Reconstruct the name (AI added this for spaces. earlier had
            % text that was cut off (i.e. 'Main Wing' isn't just Main)
            nameParts = parts(1:end-11);
            compName = strjoin(nameParts, ' ');
            if ~strcmp(compName,"Name")
                %prevents from creating a comp called name!
                namesList{end+1} = compName; %#ok<AGROW>
                volList(end+1) = volVal; %#ok<AGROW>
            end

        end
    end
    fclose(fid);

    % Get unique VSP names
    vspNames = unique(namesList,'stable');
    allComps = fieldnames(calculatedWeights);
    raymerComps = {};
    for i = 1:length(allComps)
        comp = allComps{i};
        if calculatedWeights.(comp) > 0
            raymerComps{end+1} = comp; %#ok<AGROW>
        end
    end

    %%Build the Graphical Interface
    % Create the main window
    fig = uifigure('Name', 'VSP Weight Allocation Matrix', 'Position', [100 100 900 400]);

    % Initialize table data with zeros
    numVSP = length(vspNames);
    numRaymer = length(raymerComps);
    initialData = num2cell(zeros(numVSP, numRaymer));

    % Create the interactive table
    t = uitable(fig, 'Data', initialData, ...
        'ColumnName', raymerComps, ...
        'RowName', vspNames, ...
        'ColumnEditable', true, ...
        'Position', [20 70 860 310]);

    % Add instructional text
    uilabel(fig, 'Text', 'Enter fractions (e.g., 0.5 to assign half a weight, 1.0 for full weight) to map Raymer outputs to VSP geometry.', ...
        'Position', [20 40 860 22], 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

    % Add the execution button (Now passing the correct volList)
    uibutton(fig, 'Text', 'Calculate & Update VSP File', ...
        'Position', [350 10 200 30], ...
        'ButtonPushedFcn', @(btn,event) processMatrix(t.Data, vspNames, volList, namesList, raymerComps, calculatedWeights, vspFileName, fig));
end

%%Callback func. This saves the data to
%%the VSP3 file!
function processMatrix(tableData, vspNames, volList, namesList, raymerComps, calculatedWeights, vspFileName, fig)
    disp('--- Processing Allocation Matrix ---');

    allocMatrix = cell2mat(tableData);

    vspDensities = containers.Map();

    for i = 1:length(vspNames)
        vspName = vspNames{i};

        % Calculate the total target weight for THIS specific VSP component
        targetWeight = 0;
        for j = 1:length(raymerComps)
            fraction = allocMatrix(i, j);
            if fraction > 0
                targetWeight = targetWeight + (fraction * calculatedWeights.(raymerComps{j}));
            end
        end

        % If weight was assigned to this component, compute its density
        if targetWeight > 0
            % Find ALL indices of rows that match the VSP name
            volIdx = find(strcmp(namesList, vspName));

            if ~isempty(volIdx)
                % SUM the volumes! (Handles symmetric parts like Engine Pairs)
                activeVol = sum(volList(volIdx), 'omitnan');

                if activeVol > 0.001
                    reqDensity = targetWeight / activeVol;
                    vspDensities(vspName) = reqDensity;
                    fprintf('VSP Component: %-18s | Target Wt: %8.1f | Vol (MassProps): %8.1f | Req Density: %.4f\n', ...
                        vspName, targetWeight, activeVol, reqDensity);
                else
                    warning('Volume for %s is near zero in Mass Props. Cannot assign a density.', vspName);
                end
            end

        else
            % set other densities to zero
            vspDensities(vspName) = 0;
            fprintf('VSP Component: %-18s | Target Wt:      0.0 | Req Density: 0.0000 (Zeroed out)\n', vspName);

        end
    end

    %%Check for Unallocated / Missing Weight
    disp('--- Unallocated Weights Report ---');
    totalMissingWeight = 0;
    for j = 1:length(raymerComps)
        comp = raymerComps{j};

        % Sum up the fractions the user entered in the column
        totalAssignedFraction = sum(allocMatrix(:, j));

        % If not 100% of this category's weight...
        if totalAssignedFraction < 1.0
            missingWt = calculatedWeights.(comp) * (1.0 - totalAssignedFraction);
            totalMissingWeight = totalMissingWeight + missingWt;
            fprintf('WARNING: %-18s -> %8.1f lbs was not assigned to any geometry!\n', comp, missingWt);
        elseif totalAssignedFraction > 1.0
            warning('You assigned MORE than 100%% of the weight for %s!', comp);
        end
    end
    fprintf('TOTAL MISSING WEIGHT: %.1f lbs\n\n', totalMissingWeight);

    %%Updated VSP3 File
    disp('--- Updating VSP3 File ---');
    vspData = readstruct(vspFileName, 'FileType', 'xml', 'AttributeSuffix', '_vsp_attr');
    numParts = length(vspData.Vehicle.Geom);

    for i = 1:numParts
        partName = vspData.Vehicle.Geom(i).ParmContainer.Name;

        % If we calculated a new density for this part, update it in the XML tree
        if isKey(vspDensities, partName)
            vspData.Vehicle.Geom(i).ParmContainer.Mass_Props.Density.Value_vsp_attr = vspDensities(partName);
            disp(['Updated density for VSP Part: ', partName]);
        end
    end


    [filepath, name, ext] = fileparts(char(vspFileName));
    newVspName = fullfile(filepath, [name, '_updated', ext]);

    writestruct(vspData, newVspName, 'FileType', 'xml', 'AttributeSuffix', '_vsp_attr', 'StructNodeName', 'Vsp_Geometry');
    disp(['Saved updated aircraft to: ', newVspName]);

    close(fig);
end
