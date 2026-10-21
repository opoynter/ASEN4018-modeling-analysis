function AcData = readParams(fullPath,file)


    if endsWith(file, '.mat')
        data = load(fullPath);
        if isfield(data, 'acData')
            AcData = data.acData;
        else
            error('The .mat file must contain a struct named "acData".');
        end
    else
        opts = detectImportOptions(fullPath);
        opts.VariableNamingRule = 'preserve';
        T = readtable(fullPath, opts);

        for i = 1:height(T)
            % Convert to string and clean up any accidental spaces
            paramName = strtrim(string(T{i,1}));

            if ismissing(paramName) || paramName == ""
                continue;
            end

            paramVal = T{i,2};

            % Assign to struct (char conversion required for field names)
            AcData.(char(paramName)) = paramVal;
        end
    end
end

