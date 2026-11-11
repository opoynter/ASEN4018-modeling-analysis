function [delta_CLmax] = flap_effects(flap_design)
% FLAP_EFFECTS_PARAM Computes 3D wing CLmax increment and CD0 parasitic drag increment 
% from trailing-edge flaps given explicit geometric and deflection parameters.
%
% Inputs:
%   flap_type     - 'plain', 'split', 'slotted', or 'fowler'
%   cf_c          - Flap chord to wing chord ratio (c_f / c), e.g., 0.25
%   bf_b          - Flapped span to wing span ratio (b_f / b), e.g., 0.60
%   delta_f_deg   - Flap deflection angle [deg]
%   Lambda_hl_deg - Flap hinge sweep angle [deg] (0 for unswept hinge lines)
%
% Outputs:
%   delta_CLmax    - 3D maximum lift coefficient increment
%   delta_CD0_flap - Parasitic drag increment due to flap deployment

flap_type = flap_design.type;
cf_c = flap_design.cr;
bf_b = flap_design.br;
% delta_f_deg = flap_design.Dangle;
Lambda_hl_deg = flap_design.HLangle;

% Convert input angles to radians
% delta_f_rad   = deg2rad(delta_f_deg);
Lambda_hl_rad = deg2rad(Lambda_hl_deg);


% Select empirical lift and drag scaling factors based on flap architecture
switch lower(flap_type)
    case 'plain'
        delta_Cl_max = 0.9;
    case 'split'
        delta_Cl_max = 0.9;
    case 'slotted'
        delta_Cl_max = 1.3;
    case 'fowler'
        delta_Cl_max = 1.3 * cf_c; % Accounts for chord extension
    otherwise
        error('Unknown flap type. Options are: plain, split, slotted, fowler');
end


% 3D wing maximum lift increment (delta_CLmax)
% Corrected for flapped span fraction and hinge-line sweep
delta_CLmax = delta_Cl_max * bf_b * cos(Lambda_hl_rad);

end