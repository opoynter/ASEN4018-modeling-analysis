function [W_Mat,BMF_Mat,DATA,msgs] = MSN_SEG_Handler(MSN_Profile,W_start,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs)
    %Author: Jonathan Morris
    %ASEN 4138
    %MSN_SEG_Handler interprets a MSN_Profile structure (defined by user in
    %an excel spreadsheet, created by Read_MSN_Profile.m) and returns
    %weight information/battery mass fraction for each mission segment.
    %Also returns a DATA structure that contains relevant information for
    %each mission segment (i.e cruise Drag and thrust available) useful for
    %debugging.


    %unpacking from structure
    legnum=MSN_Profile.legnum;
    input_table=MSN_Profile.input_table;
    segment=MSN_Profile.legtype;

    %initializing variables
    W=W_start;
    W_Mat=zeros(legnum,5);
    config=Constants{1};
    PropType=Propulsion_Input.PropType(config);
    BMF_Mat=0;

    if strcmp(PropType,"PROP_Electric") %ELECTRIC
        for i=1:legnum %iterates through the given mission profile and calls the relevant MSN_SEG function for each legtype.
            seg_inpt=input_table{i};%gets the row for the ith mission segment from the cell array of inputs.
            %dropflag=false;% flag for when the drop payload segment is used. currently drop isn't implemented for electric aircraft.
            switch segment(i)
                case "Takeoff"
                    [BMF,DATA{i},msgs]=MSN_SEG_TO_Elec(seg_inpt(1),seg_inpt(2),seg_inpt(3),seg_inpt(4),W,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs);
                case "Climb"
                    [BMF,DATA{i},msgs]=MSN_SEG_Climb_Elec(seg_inpt(1),seg_inpt(2),seg_inpt(3),seg_inpt(4),seg_inpt(5),W,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs);
                case "Cruise"
                    [BMF,DATA{i},msgs]=MSN_SEG_Cruise_Elec(seg_inpt(1),seg_inpt(2),seg_inpt(3),seg_inpt(4),W,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs);
                case "Loiter"
                    [BMF,DATA{i},msgs]=MSN_SEG_Loiter_Elec(seg_inpt(1),seg_inpt(2),seg_inpt(3),W,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs);
                case "Startup/Taxi"
                    BMF=seg_inpt(1);
                    %Weight_Fraction=Wa_Wb;
                    DATA{i}=table(BMF);
                case "Descent"
                    BMF=seg_inpt(1);
                    %Weight_Fraction=Wa_Wb;
                    DATA{i}=table(BMF);
                case "Landing"
                    BMF=seg_inpt(1);
                    %Weight_Fraction=Wa_Wb;
                    DATA{i}=table(BMF);
                    %currently Dropping payload isn't implemented for
                    %electric aircraft. Somewhat difficult to implement as we
                    %return a BMF but the BMF is zero although the weight
                    %decreases. Would have to return more variables from this
                    %function to implement a drop
                    %%%%%%%%%%%%
                    %                 case "Drop"
                    %                     BMF=(W-seg_inpt(1))/W;
                    %                     dropflag=true;
                    %                     Payload_Dropped=seg_inpt(1);
                    %                     Weight_Fraction=Wa_Wb;
                    %                     DATA{i}=table(Payload_Dropped,Weight_Fraction);
                case "VTOL"
                    error("VTOL currently not supported for electric aircraft!")

                otherwise
                    error("Uknown Mission Segment Type: "+segment(i));
            end


            BMF_Mat(i)=BMF;



        end


    else% NON-ELECTRIC
        for i=1:legnum%iterates through the given mission profile and calls the relevant MSN_SEG function for each legtype.
            W_Mat(i,1)=W; %starting weight
            seg_inpt=input_table{i};%gets the row for the ith mission segment from the cell array of inputs.
            dropflag=false;%initial flag for when the aircraft is dropping payload in segment
            refuelflag=false;% initial flag for if air refueling segment present in mission profile
            switch segment(i)
                case "Takeoff"
                    [Wa_Wb,DATA{i},msgs]=MSN_SEG_TO(seg_inpt(1),seg_inpt(2),seg_inpt(3),seg_inpt(4),W,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs);
                case "Climb"
                    [Wa_Wb,DATA{i},msgs]=MSN_SEG_Climb(seg_inpt(1),seg_inpt(2),seg_inpt(3),seg_inpt(4),seg_inpt(5),W,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs);
                case "Cruise"
                    [Wa_Wb,DATA{i},msgs]=MSN_SEG_Cruise(seg_inpt(1),seg_inpt(2),seg_inpt(3),seg_inpt(4),W,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs);
                case "Supercruise"
                    [Wa_Wb,DATA{i},msgs]=MSN_SEG_Supercruise(seg_inpt(1),seg_inpt(2),seg_inpt(3),seg_inpt(4),W,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs);
                case "Loiter"
                    [Wa_Wb,DATA{i},msgs]=MSN_SEG_Loiter(seg_inpt(1),seg_inpt(2),seg_inpt(3),W,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs);
                case "Startup/Taxi"
                    Wa_Wb=seg_inpt(1);
                    Weight_Fraction=Wa_Wb;
                    DATA{i}=table(Weight_Fraction);
                case "Descent"
                    Wa_Wb=seg_inpt(1);
                    Weight_Fraction=Wa_Wb;
                    DATA{i}=table(Weight_Fraction);
                case "Landing"
                    Wa_Wb=seg_inpt(1);
                    Weight_Fraction=Wa_Wb;
                    DATA{i}=table(Weight_Fraction);
                case "Drop"
                    Wa_Wb=(W-seg_inpt(1))/W;
                    dropflag=true;
                    Payload_Dropped=seg_inpt(1);
                    Weight_Fraction=Wa_Wb;
                    DATA{i}=table(Payload_Dropped,Weight_Fraction);
                case "VTOL"
                    [Wa_Wb,DATA{i},msgs]=MSN_SEG_VTOL(seg_inpt(1),seg_inpt(2),seg_inpt(3),W,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs);

                case "Air Refuel"
                    Wa_Wb=(W+seg_inpt(1))/W;
                    refuelflag=true;
                    Fuel_Added=seg_inpt(1);
                    Weight_Fraction=Wa_Wb;
                    DATA{i}=table(Fuel_Added,Weight_Fraction);
                otherwise
                    error("Uknown Mission Segment Type:");
            end

            if dropflag

                %setsfuel weight to zero if the aircraft had a segment that
                %was dropping payload or air refueling
                %(these segments are instantaneous paylaod drops so no fuel is used)
                W_Fuel=0;
                Fuel_Added=0;
            elseif refuelflag
                W_Fuel=0;
            else
                W_Fuel=W-Wa_Wb*W;
                Fuel_Added = 0;
            end
            W=W*Wa_Wb;
            W_Mat(i,2)=W;%ending weight
            W_Mat(i,3)=W_Fuel; %Fuel used during segment
            W_Mat(i,4)=Wa_Wb; %Segment weight fraction
            W_Mat(i,5)=Fuel_Added; %Fuell added during segment

        end

    end


end

