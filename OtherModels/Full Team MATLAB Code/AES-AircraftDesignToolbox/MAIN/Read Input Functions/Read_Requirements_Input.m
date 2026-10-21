function Req_Input=Read_Requirements_Input(Filename,SheetNum,RequirementsName)
%Author: Jonathan Morris
%ASEN 4138 11/23/24
%This function exists to read in user created point performance requirements 
%defined in an excel sheet. It is only expected to function with the format 
%shown in the demo excel sheet (Requirements_Input_Template.xlsx). Any deviations 
%from this format could cause errors. Currently the code does not catch these
%errors in a user friendly way, so it will be difficult to diagnose these
%errors. 
%
%Inputs:
%Filename: excel sheet filename
%SheetNum: number of sheet for the mission profile you are analyzing
%Requirement Name: Name of the requirements you're creating. (e.g. "F16 req A")
%
%Outputs:
%Req_Input: A matlab structure that describes the mission profile defined
%in the excel sheet. Consists chiefy of input_table, a cell array that 
% saves the input to each Constraint_EQ function, and reqtype, an array of 
% strings describing which Constraint_EQ function to use.
% Used directly in the Point_Performance_Handler function
    X=readtable(Filename,'Sheet',SheetNum,'HeaderLines',0,'ReadVariableNames',false);
    Inputs=X(2:end,3:end);
    Inputs = Inputs(1:2:end, :);

    %these for loops iterates through the inputs and finds the index of the
    %first 'bad' value (empty or NaN) and then saves the row to input_table
    %cell array.
    for i=1:size(Inputs,1)
        if isnan(table2array(Inputs(i,1)))
            break;
        end

        for j=1:size(Inputs,2)
            element=table2array(Inputs(i,j));
            if iscell(element)
                element=char(element);
                if ~isempty(element)
                    idx_col=j;
                end
            else
                if ~isnan(element)
                    idx_col=j;
                end
            end


        end
        input_table(i)={Inputs(i,1:idx_col-1)};
        label(i)=string(cell2mat(Inputs{i,idx_col}));
    end
    %The Matlab readtable function will sometimes treat numeric values as
    %strings if they are in the same collumn as other strings. This loop
    %exists to convert any numbers saved as strings into doubles. 
    for k=1:length(input_table)
        row=input_table{k};

        for l=1:size(input_table{k},2)
            element=row{1,l};
            if iscell(element)
                s=element{1};
                num=extractNumFromStr(s);
                if ~isempty(num)
                    row{1,l}=num2cell(num);
                end

            end

        end
        input_table{k}=row;
    end



    Req_Input.name=RequirementsName;
    reqtype=rmmissing(X(:,2));
    reqtype=string(table2array(reqtype)');
    Req_Input.reqtype=reqtype;
    Req_Input.input_table=input_table;
    Req_Input.labels=label;
end



function numArray = extractNumFromStr(str)
    %%TODO
    %I got this regular expression function from the Matlab forums.
    %Currently on a plane without internet but will link the author/post once I
    %have internet again! -Jonathan 
    str1 = regexprep(str,'[,;=]', ' ');
    str2 = regexprep(regexprep(str1,'[^- 0-9.eE(,)/]',''), ' \D* ',' ');
    str3 = regexprep(str2, {'\.\s','\E\s','\e\s','\s\E','\s\e'},' ');
    numArray = str2num(str3);
end

