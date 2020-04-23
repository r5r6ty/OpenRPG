MainObject = nil

function start()

end

function update()
    if MainObject.controller ~= nil and MainObject.AI then
        MainObject.controller:judgeAI(MainObject)
    end

    MainObject:update()
end


function fixedupdate()

    MainObject:fixedupdate()

    if MainObject.controller ~= nil and MainObject.AI then
        MainObject.controller:resetCommands()
    end
end