function fullfilename = writeSizingData(FLAG,W0,FinalSegmentData,FinalWeightData,IterationData,outputTable,DragPolar_Model,ProfileName,codeversion,outputfolder)
    if FLAG
        % Format filename
        currentTime = datetime('now');
        formatSpec = 'yyyy-MM-dd_HH-mm-ss';
        timeStampStr = string(currentTime, formatSpec);
        fileExtension = '.xlsx';
        filename = ProfileName + '_' + codeversion + "_" + timeStampStr + fileExtension; % Use string concatenation
        fullfilename = fullfile(outputfolder,filename);

        %write data to file
        writetable(outputTable,fullfilename,Sheet='Main Output')
        writetable(DragPolar_Model,fullfilename,Sheet='Drag Polar')
        writetable(FinalWeightData,fullfilename,Sheet='Mission Legs')
        writetable(IterationData,fullfilename,Sheet='Iteration Data')


        for i = 1:length(FinalSegmentData)
            writetable(FinalWeightData(i,1),fullfilename,Sheet="Segment Info",WriteMode="append")
            if ~isempty(FinalSegmentData{i})
                writetable(FinalSegmentData{i},fullfilename,Sheet="Segment Info",WriteMode="append",WriteVariableNames=true)
            else
                writematrix('No Data',fullfilename,Sheet="Segment Info",WriteMode="append")
            end
        end
        
    end
end