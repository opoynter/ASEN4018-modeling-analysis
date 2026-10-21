function displayMSN_Profile(MSN_Profile,Seg_Input_Struct)
    legnum=MSN_Profile.legnum;
    legtype=MSN_Profile.legtype;
    input_table=MSN_Profile.input_table;


    for i=1:MSN_Profile.legnum
        log_idx_mat=strcmp(legtype(i),Seg_Input_Struct.LegNames);
        idx=find(log_idx_mat);
        Fieldnames=Seg_Input_Struct.FieldNames{idx};

        VarNames=["Segment Number","Leg Type"];
        VarNames=[VarNames,Fieldnames];


        %seg_inpt=zeros(1,length(input_table{i}));
        seg_inpt=input_table{i};
        vars=[i,legtype(i),seg_inpt];

        T=table;
        for j=1:length(VarNames)
            T=addvars(T,vars(j));

        end
        T.Properties.VariableNames=VarNames;
        disp(T)
    end
    input("Press any key to continue");
end



