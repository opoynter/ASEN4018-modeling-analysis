function [X_Y_req,X_Req_Data,msgs] = Point_Performance_Handler(Req_Input,Constants,W_S_range,Propulsion_Input,Config_Row,DragPolar_Model,WaveDrag_Data,msgs)
    %Author: Jonathan Morris
    %ASEN 4138
    %Point_Performance_Handler takes in a Req_Input structure (defined in
    %an Excel spreadsheet, created through Read_Requirements_Input.m) to
    %dynamically create point performance plots based on the number of
    %requirements. 
    %Outputs: X_Y_req- array containting T_W as a function of W_S, P_W as a
    %function of W_S, or a constant W_S depending on the requirement type.
    %Inputs: Req_Input (structure defining requirements)
    %Constants: array containing many constants necessary for constraint_EQ
    %W_S_range: Wingloading range for eval/plotting specified by user
    %Propulsion_Input table describing vehicle propulsion system
    %DragPolar_Model table containing information on drag polar
    %WaveDrag_Data table containing information on wave drag

    Config_Row=Constants{2};
    reqtype=Req_Input.reqtype;
    input_table=Req_Input.input_table;
    X_Y_req=zeros(length(reqtype),length(W_S_range));
    PropType=Propulsion_Input.PropType;
    PropType=PropType(Config_Row);
    

    %if statement will return P_W information for Props, T_W for jet.
    
    if strcmp(PropType,'PROP_Fuel')||strcmp(PropType,'PROP_Electric')||strcmp(PropType,'PROP_Turbocharged')||strcmp(PropType,'PROP_Turboprop')
        %iterates through number of requirements
        for i=1:length(reqtype)
            Req_Inputs=table2cell(input_table{i});
            %determines which function to call based on requirement type
            %saves P_W or W_S data into X_Y_req struct based on inputs and
            %type of constraint
            switch reqtype(i)

                case "Takeoff Distance"
                    
                    [~,P_Wreq,X_Req_Data{i}]=Takeoff_Constraint_EQ(Req_Inputs,Constants,W_S_range,Propulsion_Input,DragPolar_Model,WaveDrag_Data);
                    X_Y_req(i,:)=P_Wreq;
                case "Stall Velocity"
                    [W_S_req,X_Req_Data{i}]=Stall_Constraint_EQ(Req_Inputs,Constants);
                    X_Y_req(i,:)=W_S_req*ones(1,length(W_S_range));
                case "Absolute Ceiling"
                    [~,P_Wreq,X_Req_Data{i}] = Master_Constraint_EQ(Req_Inputs,Constants,W_S_range,Propulsion_Input,DragPolar_Model,WaveDrag_Data);
                    X_Y_req(i,:)=P_Wreq;

                case "Service Ceiling"
                    [~,P_Wreq,X_Req_Data{i}] = Master_Constraint_EQ(Req_Inputs,Constants,W_S_range,Propulsion_Input,DragPolar_Model,WaveDrag_Data);
                    X_Y_req(i,:)=P_Wreq;

                case "Max Mach"
                    [~,P_Wreq,X_Req_Data{i}] = Master_Constraint_EQ(Req_Inputs,Constants,W_S_range,Propulsion_Input,DragPolar_Model,WaveDrag_Data);
                    X_Y_req(i,:)=P_Wreq;

                case "Sustained Turn"
                    [~,P_Wreq,X_Req_Data{i}] = Master_Constraint_EQ(Req_Inputs,Constants,W_S_range,Propulsion_Input,DragPolar_Model,WaveDrag_Data);
                    X_Y_req(i,:)=P_Wreq;

                case "Landing Distance"
                    [W_S_req,X_Req_Data{i}]=Landing_Constraint_EQ(Req_Inputs,Constants,DragPolar_Model,WaveDrag_Data);
                    X_Y_req(i,:)=W_S_req*ones(1,length(W_S_range));
                case "VTOL"
                    [P_Wreq,X_Req_Data{i}]=Vtol_Constraint_EQ(Req_Inputs,Constants,Propulsion_Input,10);
                    X_Y_req(i,:)=P_Wreq;
                otherwise
                    error("Unkown requirement type: " + reqtype(i))

            end
        end



    else
        for i=1:length(reqtype)
            
        %iterates through number of requirements
            Req_Inputs=table2cell(input_table{i});
            %determines which function to call based on requirement type
            %saves T_W or W_S data into X_Y_req struct based on inputs and
            %type of constraint
            switch reqtype(i)

                case "Takeoff Distance"
                    [T_Wreq,~,X_Req_Data{i}]=Takeoff_Constraint_EQ(Req_Inputs,Constants,W_S_range,Propulsion_Input,DragPolar_Model,WaveDrag_Data);
                    X_Y_req(i,:)=T_Wreq;

                case "Stall Velocity"
                    [W_S_req,X_Req_Data{i}]=Stall_Constraint_EQ(Req_Inputs,Constants);
                    X_Y_req(i,:)=W_S_req*ones(1,length(W_S_range));

                case "Absolute Ceiling"
                    [T_Wreq,~,X_Req_Data{i}] = Master_Constraint_EQ(Req_Inputs,Constants,W_S_range,Propulsion_Input,DragPolar_Model,WaveDrag_Data);
                    X_Y_req(i,:)=T_Wreq;

                case "Service Ceiling"
                    [T_Wreq,~,X_Req_Data{i}] = Master_Constraint_EQ(Req_Inputs,Constants,W_S_range,Propulsion_Input,DragPolar_Model,WaveDrag_Data);
                    X_Y_req(i,:)=T_Wreq;
                case "Max Mach"
                    [T_Wreq,~,X_Req_Data{i}] = Master_Constraint_EQ(Req_Inputs,Constants,W_S_range,Propulsion_Input,DragPolar_Model,WaveDrag_Data);
                    X_Y_req(i,:)=T_Wreq;

                case "Sustained Turn"
                    [T_Wreq,~,X_Req_Data{i}] = Master_Constraint_EQ(Req_Inputs,Constants,W_S_range,Propulsion_Input,DragPolar_Model,WaveDrag_Data);
                    X_Y_req(i,:)=T_Wreq;

                case "Landing Distance"
                    [W_S_req,X_Req_Data{i}]=Landing_Constraint_EQ(Req_Inputs,Constants,DragPolar_Model,WaveDrag_Data);
                    X_Y_req(i,:)=W_S_req*ones(1,length(W_S_range));

                otherwise
                    error("Unkown requirement type: " + reqtype(i))
            end
        end
    end
end

