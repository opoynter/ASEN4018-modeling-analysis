function  displaySizingData(FLAG,W0,FinalSegmentData,FinalWeightData,IterationData,outputTable,MSN_Profile)
    disp("================================================================================")
    disp("W0: "+ num2str(W0) + " lbs")
    disp("================================================================================")


    if FLAG
        disp(IterationData)
        disp("================================================================================")
        disp(FinalWeightData)
        disp("================================================================================")

        for i=1:length(FinalSegmentData)
            disp(table2array(FinalWeightData(i,1)))
            disp(FinalSegmentData{i})

        end
        disp("================================================================================")
        disp(outputTable)
        disp("================================================================================")
        if (size(FinalWeightData,2)>2) %only plots fuelburn for non-electric

            figure
            fuelburn=FinalWeightData{:,4};
            fuelburn=str2double(fuelburn);
            bar(fuelburn,'Labels',MSN_Profile.legtype(:))
            xlabel("Mission Segment")
            ylabel("Fuel Burn [lbf]")
            title("Fuel Burn over Mission Segments")
            grid on
        end
    end

end

