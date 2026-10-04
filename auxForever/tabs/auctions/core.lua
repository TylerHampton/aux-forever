select(2, ...) 'aux.tabs.auctions'

local aux = require 'aux'
local scan = require 'aux.core.scan'

local tab = aux.tab 'Auctions'

-- Forever: the list comes from C_AuctionHouse.QueryOwnedAuctions and auctions are cancelled by ID.

function aux.event.AUX_LOADED()
    aux.event_listener('OWNED_AUCTIONS_UPDATED', function()
        refresh = true
    end)
    for _, event in ipairs{'AUCTION_CANCELED', 'AUCTION_HOUSE_AUCTION_CREATED', 'AUCTION_HOUSE_AUCTIONS_EXPIRED'} do
        aux.event_listener(event, function()
            if aux.frame:IsShown() then
                aux.query_owned_auctions()
            end
        end)
    end
    aux.coro_thread(function()
        while true do
            local timestamp = GetTime()
            while GetTime() - timestamp < 1 do
                aux.coro_wait()
            end
            refresh = true
        end
    end)
end

function tab.OPEN()
    frame:Show()
    aux.query_owned_auctions()
end

function tab.CLOSE()
    listing:SetSelectedRecord()
    frame:Hide()
end

function M.scan_auctions()
    local auctions = {}
    for _, auction in scan.owner_auctions() do
        tinsert(auctions, auction)
    end
    listing:SetDatabase(auctions)
end

do
    local locked = {}

    function cancel_auction()
        local record = listing:GetSelection().record
        if record.auction_id and GetTime() - (locked[record.auction_id] or 0) > .5 and C_AuctionHouse.CanCancelAuction(record.auction_id) then
            local cost = C_AuctionHouse.GetCancelCost(record.auction_id) or 0
            if cost > GetMoney() then
                UIErrorsFrame:AddExternalErrorMessage(ERR_NOT_ENOUGH_MONEY)
                return
            end
            C_AuctionHouse.CancelAuction(record.auction_id)
            locked[record.auction_id] = GetTime()
        end
    end
end

function on_update()
    if refresh then
        refresh = false
        scan_auctions()
    end

    local selection = listing:GetSelection()
    if selection and selection.record.sale_status == 0 and selection.record.auction_id and C_AuctionHouse.CanCancelAuction(selection.record.auction_id) then
        cancel_button:Enable()
    else
        cancel_button:Disable()
    end
end
