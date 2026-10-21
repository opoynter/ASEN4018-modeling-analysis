function [a,c1,c2,c3,c4,c5,msgs] = WeightModel(PropType,AcType,msgs)
    %WEIGHTMODEL Outputs constants for weight fraction model
    %   ASEN 4138
    %   Author: Jonathan Morris
    %   Inputs:
    %   PropType [1x1] cell array generated from Excel file detailing the type of Propulsion
    %   AcType [1x1] cell array generated from Excel file detailing the
    %   type of Aircraft for use in empty weight fraction model
    %
    %   Outputs: returns 1,b,c1,c2,c3,c4,c5 - constants used in estimating
    %   weight fraction from Raymer Models (6th edition textbook) (Tables 6.1 and 6.2)
    PropType=char(PropType);
    AcType=char(AcType);

    if PropType=="JET_LBP_Turbofan" || PropType=="JET_HBP_Turbofan"
        switch (AcType)
            case "Jet_Fighter"
                a = 3.498; %From Raymer Table 6.1 based on aicraft type (Jet Fighter)
                c1 = -0.082; %From Raymer Table 6.1 based on aicraft type (Jet Fighter)
                c2 = 0.211; %From Raymer Table 6.1 based on aicraft type (Jet Fighter)
                c3 = 0.124; %From Raymer Table 6.1 based on aicraft type (Jet Fighter)
                c4 = -0.251; %From Raymer Table 6.1 based on aicraft type (Jet Fighter)
                c5 = 0.043; %From Raymer Table 6.1 based on aicraft type (Jet Fighter)
            case "Jet_Trainer"
                a = 3.955; %From Raymer Table 6.1 based on aicraft type (Jet Trainer)
                c1 = -.08; %From Raymer Table 6.1 based on aicraft type (Jet Trainer)
                c2 = .099; %From Raymer Table 6.1 based on aicraft type (Jet Trainer)
                c3 = .126; %From Raymer Table 6.1 based on aicraft type (Jet Trainer)
                c4 = -.284; %From Raymer Table 6.1 based on aicraft type (Jet Trainer)
                c5 = .10; %From Raymer Table 6.1 based on aicraft type (Jet Trainer)
            case "Jet_Transport"
                a = 0.869; %From Raymer Table 6.1 based on aicraft type (Jet Transport)
                c1 = -.037; %From Raymer Table 6.1 based on aicraft type (Jet Transport)
                c2 = .398; %From Raymer Table 6.1 based on aicraft type (Jet Transport)
                c3 = .1; %From Raymer Table 6.1 based on aicraft type (Jet Transport)
                c4 = -.161; %From Raymer Table 6.1 based on aicraft type (Jet Transport)
                c5 = .05; %From Raymer Table 6.1 based on aicraft type (Jet Transport)
            case "Military_Cargo/Bomber"
                a = 1.057; %From Raymer Table 6.1 based on aicraft type (Military Cargo/Bomber)
                c1 = -.012; %From Raymer Table 6.1 based on aicraft type (Military Cargo/Bomber)
                c2 = .141; %From Raymer Table 6.1 based on aicraft type (Military Cargo/Bomber)
                c3 = .017; %From Raymer Table 6.1 based on aicraft type (Military Cargo/Bomber)
                c4 = -.21; %From Raymer Table 6.1 based on aicraft type (Military Cargo/Bomber)
                c5 = .05; %From Raymer Table 6.1 based on aicraft type (Military Cargo/Bomber)
            case "Business_Jet"
                a = 0.704; %From Raymer Table 6.1 based on aicraft type (Business Jet)
                c1 = -.06; %From Raymer Table 6.1 based on aicraft type (Business Jet)
                c2 = .473; %From Raymer Table 6.1 based on aicraft type (Business Jet)
                c3 = .1; %From Raymer Table 6.1 based on aicraft type (Business Jet)
                c4 = -.099; %From Raymer Table 6.1 based on aicraft type (Business Jet)
                c5 = .07; %From Raymer Table 6.1 based on aicraft type (Business Jet)
            case "UAV_Jet"
                a = 1.128; %From Raymer Table 6.1 based on aicraft type (Business Jet)
                c1 = -.05; %From Raymer Table 6.1 based on aicraft type (Business Jet)
                c2 = .09; %From Raymer Table 6.1 based on aicraft type (Business Jet)
                c3 = .05; %From Raymer Table 6.1 based on aicraft type (Business Jet)
                c4 = -.256; %From Raymer Table 6.1 based on aicraft type (Business Jet)
                c5 = .04; %From Raymer Table 6.1 based on aicraft type (Business Jet)
            otherwise
                error("Incorrect Weight Model Type")
        end
    elseif PropType=="PROP_Fuel" || PropType=="PROP_Electric"||PropType=="PROP_Turbocharged"||PropType=="PROP_Turboprop"
        switch (AcType)
            case "GA_Metal_Single"
                a = 0.947; %From Raymer Table 6.2 based on aicraft type (General Aviation Single Engine)
                c1 = -0.2; %From Raymer Table 6.2 based on aicraft type (General Aviation Single Engine)
                c2 = 0.110; %From Raymer Table 6.2 based on aicraft type (General Aviation Single Engine)
                c3 = 0.05; %From Raymer Table 6.2 based on aicraft type (General Aviation Single Engine)
                c4 = -0.05; %From Raymer Table 6.2 based on aicraft type (General Aviation Single Engine)
                c5 = 0.24; %From Raymer Table 6.2 based on aicraft type (General Aviation Single Engine)
            case "GA_Metal_Twin"
                a = 0.854; %From Raymer Table 6.2 based on aicraft type (General Aviation Twin Engine)
                c1 = -0.196; %From Raymer Table 6.2 based on aicraft type (General Aviation Twin Engine)
                c2 = 0.05; %From Raymer Table 6.2 based on aicraft type (General Aviation Twin Engine)
                c3 = 0.05; %From Raymer Table 6.2 based on aicraft type (General Aviation Twin Engine)
                c4 = -0.05; %From Raymer Table 6.2 based on aicraft type (General Aviation Twin Engine)
                c5 = 0.293; %From Raymer Table 6.2 based on aicraft type (General Aviation Twin Engine)
            case "Ag_Aircraft_Prop"
                a = 1.76; %From Raymer Table 6.2 based on aicraft type (Ag Aircraft)
                c1 = -.1; %From Raymer Table 6.2 based on aicraft type (Ag Aircraft)
                c2 = 0.0; %From Raymer Table 6.2 based on aicraft type (Ag Aircraft)
                c3 = 0.284; %From Raymer Table 6.2 based on aicraft type (Ag Aircraft)
                c4 = -0.334; %From Raymer Table 6.2 based on aicraft type (Ag Aircraft)
                c5 = 0.289; %From Raymer Table 6.2 based on aicraft type (Ag Aircraft)
            case "Turboprop_Transport"
                a = 0.139; %From Raymer Table 6.2 based on aicraft type (Turboprop)
                c1 = -.03; %From Raymer Table 6.2 based on aicraft type (Turboprop)
                c2 = 0.42; %From Raymer Table 6.2 based on aicraft type (Turboprop)
                c3 = 0.06; %From Raymer Table 6.2 based on aicraft type (Turboprop)
                c4 = -0.2; %From Raymer Table 6.2 based on aicraft type (Turboprop)
                c5 = 0.30; %From Raymer Table 6.2 based on aicraft type (Turboprop)
            case "Flying_Boat_Prop"
                a = 0.178; %From Raymer Table 6.2 based on aicraft type (Flying Boat)
                c1 = -.05; %From Raymer Table 6.2 based on aicraft type (Flying Boat)
                c2 = 0.35; %From Raymer Table 6.2 based on aicraft type (Flying Boat)
                c3 = 0.08; %From Raymer Table 6.2 based on aicraft type (Flying Boat)
                c4 = -0.08; %From Raymer Table 6.2 based on aicraft type (Flying Boat)
                c5 = 0.3; %From Raymer Table 6.2 based on aicraft type (Flying Boat)
            case "Homebuilt_Metal/wood_Prop"
                a = 1.082; %From Raymer Table 6.2 based on aicraft type (Homebuilt-Metal/wood)
                c1 = -.10; %From Raymer Table 6.2 based on aicraft type (Homebuilt-Metal/wood)
                c2 = .038; %From Raymer Table 6.2 based on aicraft type (Homebuilt-Metal/wood)
                c3 = 0.12; %From Raymer Table 6.2 based on aicraft type (Homebuilt-Metal/wood)
                c4 = -0.05; %From Raymer Table 6.2 based on aicraft type (Homebuilt-Metal/wood)
                c5 = 0.1; %From Raymer Table 6.2 based on aicraft type (Homebuilt-Metal/wood)
            case "Homebuilt_Composite_Prop"
                a = 0.969; %From Raymer Table 6.2 based on aicraft type (Homebuilt-Composite)
                c1 = -.10; %From Raymer Table 6.2 based on aicraft type (Homebuilt-Composite)
                c2 = .03; %From Raymer Table 6.2 based on aicraft type (Homebuilt-Composite)
                c3 = 0.12; %From Raymer Table 6.2 based on aicraft type (Homebuilt-Composite)
                c4 = -0.05; %From Raymer Table 6.2 based on aicraft type (Homebuilt-Composite)
                c5 = 0.1; %From Raymer Table 6.2 based on aicraft type (Homebuilt-Composite)
            case "Sailplane_Unpowered"
                a = 0.677; %From Raymer Table 6.2 based on aicraft type (Sailplane_Unpowered)
                c1 = -.05; %From Raymer Table 6.2 based on aicraft type (Sailplane_Unpowered)
                c2 = .233; %From Raymer Table 6.2 based on aicraft type (Sailplane_Unpowered)
                c3 = 0.0; %From Raymer Table 6.2 based on aicraft type (Sailplane_Unpowered)
                c4 = -0.471; %From Raymer Table 6.2 based on aicraft type (Sailplane_Unpowered)
                c5 = 0.09; %From Raymer Table 6.2 based on aicraft type (Sailplane_Unpowered)
            case "Sailplane_Powered"
                a = 1.368; %From Raymer Table 6.2 based on aicraft type (Sailplane_powered)
                c1 = -.05; %From Raymer Table 6.2 based on aicraft type (Sailplane_powered)
                c2 = .233; %From Raymer Table 6.2 based on aicraft type (Sailplane_powered)
                c3 = 0.190; %From Raymer Table 6.2 based on aicraft type (Sailplane_powered)
                c4 = -0.471; %From Raymer Table 6.2 based on aicraft type (Sailplane_powered)
                c5 = 0.09; %From Raymer Table 6.2 based on aicraft type (Sailplane_powered)
            case "Aerobatic_Prop"
                a = 0.946; %From Raymer Table 6.2 based on aicraft type (Aerobatic_Prop)
                c1 = -.05; %From Raymer Table 6.2 based on aicraft type (Aerobatic_Prop)
                c2 = 0.0; %From Raymer Table 6.2 based on aicraft type (Aerobatic_Prop)
                c3 = 0.1; %From Raymer Table 6.2 based on aicraft type (Aerobatic_Prop)
                c4 = 0.0; %From Raymer Table 6.2 based on aicraft type (Aerobatic_Prop)
                c5 = 0.036; %From Raymer Table 6.2 based on aicraft type (Aerobatic_Prop)
            case "UAV_Prop"
                a = 0.606; %From Raymer Table 6.2 based on aicraft type (UAV_Prop)
                c1 = -.05; %From Raymer Table 6.2 based on aicraft type (UAV_Prop)
                c2 = 0.09; %From Raymer Table 6.2 based on aicraft type (UAV_Prop)
                c3 = 0.05; %From Raymer Table 6.2 based on aicraft type (UAV_Prop)
                c4 = -0.05; %From Raymer Table 6.2 based on aicraft type (UAV_Prop)
                c5 = 0.05; %From Raymer Table 6.2 based on aicraft type (UAV_Prop)
            otherwise
                error("Incorrect Weight Model Type")
        end

    else
        error("Either PropType or ACType are invalid entries")
    end



end

