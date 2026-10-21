function writemsgs(msgs,outputfilename)
    writetable(struct2table(msgs),outputfilename,Sheet='Messages')
end