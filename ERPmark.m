function ERPmark(ioObj,address,mark)
%     disp(mark);
    try
        io32(ioObj,address,0);
        io32(ioObj,address,mark);
        WaitSecs(.010);
        io32(ioObj,address,0);
    catch
        try
        io64(ioObj,address,0);
        io64(ioObj,address,mark);
        WaitSecs(.010);
        io64(ioObj,address,0);
        catch
        end
     end
end
