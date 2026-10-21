function allSets = PlaneCGcalc(allSets)
% PLANECG  Computes the mass-weighted CG for each set and appends the
%          result as new fields on the allSets struct array.
%
%  Adds to each allSets(s):
%    .totalMass   — sum of scaled component masses
%    .cgX         — mass-weighted X centroid
%    .cgY         — mass-weighted Y centroid
%    .cgZ         — mass-weighted Z centroid

    for s = 1:length(allSets)
        comps = allSets(s).components;

        if isempty(comps)
            allSets(s).totalMass = 0;
            allSets(s).cgX = 0;
            allSets(s).cgY = 0;
            allSets(s).cgZ = 0;
            continue
        end

        % Collect scaled masses and CG coordinates into vectors
        masses = [comps.scaledMass]';
        cgXs   = [comps.cgX]';
        cgYs   = [comps.cgY]';
        cgZs   = [comps.cgZ]';

        totalM = sum(masses);

        % Mass-weighted average position
        if totalM == 0
            cgX = 0;  cgY = 0;  cgZ = 0;
        else
            cgX = sum(masses .* cgXs) / totalM;
            cgY = sum(masses .* cgYs) / totalM;
            cgZ = sum(masses .* cgZs) / totalM;
        end

        allSets(s).totalMass = totalM;
        allSets(s).cgX       = cgX;
        allSets(s).cgY       = cgY;
        allSets(s).cgZ       = cgZ;
    end
end