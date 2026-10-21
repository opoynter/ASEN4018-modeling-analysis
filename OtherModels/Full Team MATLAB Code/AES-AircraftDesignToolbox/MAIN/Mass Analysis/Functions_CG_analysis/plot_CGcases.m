function plot_CGcases(allSets,X_np,c_MAC,SM_min_req,SM_max_req)

    cg_lim_aft = (X_np/c_MAC-SM_min_req)*c_MAC;
    cg_lim_forward = (X_np/c_MAC-SM_max_req)*c_MAC;

    for i = 1:length(allSets) % Calculate static margin
        allSets(i).SM =  X_np/c_MAC - allSets(i).cgX/c_MAC;
    end

    figure()
    hold on
    ax = gca;
    yyaxis left
    for i = 1:length(allSets) % Plot CG
        scatter(allSets(i).cgX,allSets(i).totalMass,'blue','filled')
        text(allSets(i).cgX, allSets(i).totalMass, allSets(i).setName,...
            'VerticalAlignment','bottom','HorizontalAlignment','right');
    end
    xline(cg_lim_aft,'b--')
    xline(cg_lim_forward,'b--')
    xlabel('Aircraft Center of Gravity (From Nose, Feet)')
    ylabel('Aircraft Weight (lb)')
    ax.YColor = 'blue';

    yyaxis right
    for i = 1:length(allSets) % Plot static margin
        scatter(allSets(i).cgX,allSets(i).SM,'red','filled')
        text(allSets(i).cgX, allSets(i).SM, allSets(i).setName,...
            'VerticalAlignment','bottom','HorizontalAlignment','right');
    end
    yline(SM_min_req,'r--')
    yline(SM_max_req,'r--')
    ylabel('Static Margin (%)')
    ax.YColor = 'red';
end