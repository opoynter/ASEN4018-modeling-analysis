function [totalMass, compNames, compMass, compCG] = readVSPMassProps(filename)
    % This function reads an OpenVSP Mass_Prop text file to extract the
    % total mass, component names, component mass, and component cgs
    lines = readlines(filename);

    % Find component table header
    headerIdx = find(contains(lines,"Name") & contains(lines,"Mass"), 1, 'first');

    % Find totals row
    totalsIdx = find(contains(lines,"Totals"), 1, 'first');

    % Extract component rows
    compLines = lines(headerIdx+1:totalsIdx-2);

    n = length(compLines);
    compNames = strings(n, 1);
    compMass  = zeros(n, 1);
    compCG    = zeros(n, 3);

    for i = 1:n
        parts = split(strtrim(compLines(i)));

        % Detect first numeric entry
        numIdx = find(~isnan(str2double(parts)), 1, 'first');

        % Name = everything before numeric data
        compNames(i) = strjoin(parts(1:numIdx-1), " ");

        % First numeric value is mass
        compMass(i) = str2double(parts(numIdx));

        % Next three values are cgX, cgY, cgZ
        compCG(i, 1) = str2double(parts(numIdx+1));
        compCG(i, 2) = str2double(parts(numIdx+2));
        compCG(i, 3) = str2double(parts(numIdx+3));
    end

    % Extract total mass
    totalsParts = split(strtrim(lines(totalsIdx)));
    totalMass = str2double(totalsParts(2));

end