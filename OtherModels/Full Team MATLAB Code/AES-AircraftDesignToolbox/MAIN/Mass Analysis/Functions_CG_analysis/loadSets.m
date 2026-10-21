function sets = loadSets(setsFile,compNames)
    % load in data from previous run, load same sets if components are the same

    if isfile(setsFile)
        load(setsFile)
        if isequal(prev.compNames,compNames)
            sets = prev.sets;
        else
            disp('setsFile and MassProps file have different components, redefine sets')
            sets = {};
        end
    else
        sets = {};
    end

end