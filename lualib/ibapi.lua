--[[
RAW IB API
TODO:
    verify api params
    notify when disconnect/socket error etc.    

]]--
local socket = require "socket"
local skynet = require "skynet"
local driver = require "socketdriver"
local assert = assert
local math = math

local ibapi = {}

local API_VERSION = "9.71" -- support IB API version
local CLIENT_VERSION = 63
local MIN_SERVER_VERSION = 70

-- constants
-- outgoing msg id's
local REQ_MKT_DATA = 1
local CANCEL_MKT_DATA = 2
local PLACE_ORDER = 3
local CANCEL_ORDER = 4
local REQ_OPEN_ORDERS = 5
local REQ_ACCOUNT_DATA = 6
local REQ_EXECUTIONS = 7
local REQ_IDS = 8
local REQ_CONTRACT_DATA = 9
local REQ_MKT_DEPTH = 10
local CANCEL_MKT_DEPTH = 11
local REQ_NEWS_BULLETINS = 12
local CANCEL_NEWS_BULLETINS = 13
local SET_SERVER_LOGLEVEL = 14
local REQ_AUTO_OPEN_ORDERS = 15
local REQ_ALL_OPEN_ORDERS = 16
local REQ_MANAGED_ACCTS = 17
local REQ_FA = 18
local REPLACE_FA = 19
local REQ_HISTORICAL_DATA = 20
local EXERCISE_OPTIONS = 21
local REQ_SCANNER_SUBSCRIPTION = 22
local CANCEL_SCANNER_SUBSCRIPTION = 23
local REQ_SCANNER_PARAMETERS = 24
local CANCEL_HISTORICAL_DATA = 25
local REQ_CURRENT_TIME = 49
local REQ_REAL_TIME_BARS = 50
local CANCEL_REAL_TIME_BARS = 51
local REQ_FUNDAMENTAL_DATA = 52
local CANCEL_FUNDAMENTAL_DATA = 53
local REQ_CALC_IMPLIED_VOLAT = 54
local REQ_CALC_OPTION_PRICE = 55
local CANCEL_CALC_IMPLIED_VOLAT = 56
local CANCEL_CALC_OPTION_PRICE = 57
local REQ_GLOBAL_CANCEL = 58
local REQ_MARKET_DATA_TYPE = 59
local REQ_POSITIONS = 61
local REQ_ACCOUNT_SUMMARY = 62
local CANCEL_ACCOUNT_SUMMARY = 63
local CANCEL_POSITIONS = 64
local VERIFY_REQUEST = 65
local VERIFY_MESSAGE = 66
local QUERY_DISPLAY_GROUPS = 67
local SUBSCRIBE_TO_GROUP_EVENTS = 68
local UPDATE_DISPLAY_GROUP = 69
local UNSUBSCRIBE_FROM_GROUP_EVENTS = 70
local START_API = 71

-- incoming msg id's
local TICK_PRICE         = 1
local TICK_SIZE          = 2
local ORDER_STATUS       = 3
local ERR_MSG            = 4
local OPEN_ORDER         = 5
local ACCT_VALUE         = 6
local PORTFOLIO_VALUE    = 7
local ACCT_UPDATE_TIME   = 8
local NEXT_VALID_ID      = 9
local CONTRACT_DATA      = 10
local EXECUTION_DATA     = 11
local MARKET_DEPTH       = 12
local MARKET_DEPTH_L2    = 13
local NEWS_BULLETINS     = 14
local MANAGED_ACCTS      = 15
local RECEIVE_FA         = 16
local HISTORICAL_DATA    = 17
local BOND_CONTRACT_DATA = 18
local SCANNER_PARAMETERS = 19
local SCANNER_DATA       = 20
local TICK_OPTION_COMPUTATION = 21
local TICK_GENERIC = 45
local TICK_STRING = 46
local TICK_EFP = 47
local CURRENT_TIME = 49
local REAL_TIME_BARS = 50
local FUNDAMENTAL_DATA = 51
local CONTRACT_DATA_END = 52
local OPEN_ORDER_END = 53
local ACCT_DOWNLOAD_END = 54
local EXECUTION_DATA_END = 55
local DELTA_NEUTRAL_VALIDATION = 56
local TICK_SNAPSHOT_END = 57
local MARKET_DATA_TYPE = 58
local COMMISSION_REPORT = 59
local POSITION = 61
local POSITION_END = 62
local ACCOUNT_SUMMARY = 63
local ACCOUNT_SUMMARY_END = 64
local VERIFY_MESSAGE_API = 65
local VERIFY_COMPLETED = 66
local DISPLAY_GROUP_LIST = 67
local DISPLAY_GROUP_UPDATED = 68
-- custom msg id's
local TWS_CONNECTED = 10000
local TWS_DISCONNECTED = 100001

-- error table
local EClientErrors = {
  NO_VALID_ID = -1,
  NOT_CONNECTED = { code = 504, msg = "Not connected" },
  UPDATE_TWS = { code = 503, msg = "The TWS is out of date and must be upgraded." },
  ALREADY_CONNECTED = { code = 501, msg = "Already connected." },
  CONNECT_FAIL = { code = 502, msg = "Couldn't connect to TWS.  Confirm that \"Enable ActiveX and Socket Clients\" is enabled on the TWS \"Configure->API\" menu." },
  FAIL_SEND = { code = 509, msg = "Failed to send message - " }, -- generic message, msg = all future messages should use this
  UNKNOWN_ID = { code = 505, msg = "Fatal Error: Unknown message id." },
  FAIL_SEND_REQMKT = { code = 510, msg = "Request Market Data Sending Error - " },
  FAIL_SEND_CANMKT = { code = 511, msg = "Cancel Market Data Sending Error - " },
  FAIL_SEND_ORDER = { code = 512, msg = "Order Sending Error - " },
  FAIL_SEND_ACCT = { code = 513, msg = "Account Update Request Sending Error -" },
  FAIL_SEND_EXEC = { code = 514, msg = "Request For Executions Sending Error -" },
  FAIL_SEND_CORDER = { code = 515, msg = "Cancel Order Sending Error -" },
  FAIL_SEND_OORDER = { code = 516, msg = "Request Open Order Sending Error -" },
  UNKNOWN_CONTRACT = { code = 517, msg = "Unknown contract. Verify the contract details supplied." },
  FAIL_SEND_REQCONTRACT = { code = 518, msg = "Request Contract Data Sending Error - " },
  FAIL_SEND_REQMKTDEPTH = { code = 519, msg = "Request Market Depth Sending Error - " },
  FAIL_SEND_CANMKTDEPTH = { code = 520, msg = "Cancel Market Depth Sending Error - " },
  FAIL_SEND_SERVER_LOG_LEVEL = { code = 521, msg = "Set Server Log Level Sending Error - " },
  FAIL_SEND_FA_REQUEST = { code = 522, msg = "FA Information Request Sending Error - " },
  FAIL_SEND_FA_REPLACE = { code = 523, msg = "FA Information Replace Sending Error - " },
  FAIL_SEND_REQSCANNER = { code = 524, msg = "Request Scanner Subscription Sending Error - " },
  FAIL_SEND_CANSCANNER = { code = 525, msg = "Cancel Scanner Subscription Sending Error - " },
  FAIL_SEND_REQSCANNERPARAMETERS = { code = 526, msg = "Request Scanner Parameter Sending Error - " },
  FAIL_SEND_REQHISTDATA = { code = 527, msg = "Request Historical Data Sending Error - " },
  FAIL_SEND_CANHISTDATA = { code = 528, msg = "Request Historical Data Sending Error - " },
  FAIL_SEND_REQRTBARS = { code = 529, msg = "Request Real-time Bar Data Sending Error - " },
  FAIL_SEND_CANRTBARS = { code = 530, msg = "Cancel Real-time Bar Data Sending Error - " },
  FAIL_SEND_REQCURRTIME = { code = 531, msg = "Request Current Time Sending Error - " },
  FAIL_SEND_REQFUNDDATA = { code = 532, msg = "Request Fundamental Data Sending Error - " },
  FAIL_SEND_CANFUNDDATA = { code = 533, msg = "Cancel Fundamental Data Sending Error - " },
  FAIL_SEND_REQCALCIMPLIEDVOLAT = { code = 534, msg = "Request Calculate Implied Volatility Sending Error - " },
  FAIL_SEND_REQCALCOPTIONPRICE = { code = 535, msg = "Request Calculate Option Price Sending Error - " },
  FAIL_SEND_CANCALCIMPLIEDVOLAT = { code = 536, msg = "Cancel Calculate Implied Volatility Sending Error - " },
  FAIL_SEND_CANCALCOPTIONPRICE = { code = 537, msg = "Cancel Calculate Option Price Sending Error - " },
  FAIL_SEND_REQGLOBALCANCEL = { code = 538, msg = "Request Global Cancel Sending Error - " },
  FAIL_SEND_REQMARKETDATATYPE = { code = 539, msg = "Request Market Data Type Sending Error - " },
  FAIL_SEND_REQPOSITIONS = { code = 540, msg = "Request Positions Sending Error - " },
  FAIL_SEND_CANPOSITIONS = { code = 541, msg = "Cancel Positions Sending Error - " },
  FAIL_SEND_REQACCOUNTDATA = { code = 542, msg = "Request Account Data Sending Error - " },
  FAIL_SEND_CANACCOUNTDATA = { code = 543, msg = "Cancel Account Data Sending Error - " },
  FAIL_SEND_VERIFYREQUEST = { code = 544, msg = "Verify Request Sending Error - " },
  FAIL_SEND_VERIFYMESSAGE = { code = 545, msg = "Verify Message Sending Error - " },
  FAIL_SEND_QUERYDISPLAYGROUPS = { code = 546, msg = "Query Display Groups Sending Error - " },
  FAIL_SEND_SUBSCRIBETOGROUPEVENTS = { code = 547, msg = "Subscribe To Group Events Sending Error - " },
  FAIL_SEND_UPDATEDISPLAYGROUP = { code = 548, msg = "Update Display Group Sending Error - " },
  FAIL_SEND_UNSUBSCRIBEFROMGROUPEVENTS = { code = 549, msg = "Unsubscribe From Group Events Sending Error - " },
  FAIL_SEND_STARTAPI = { code = 550, msg = "Start API Sending Error - " },
}
-- tick name
-- global table for external use
TickName = {
  [0]  = "BID_SIZE",
  [1]  = "BID",
  [2]  = "ASK",
  [3]  = "ASK_SIZE",
  [4]  = "LAST",
  [5]  = "LAST_SIZE",
  [6]  = "HIGH",
  [7]  = "LOW",
  [8]  = "VOLUME",
  [9]  = "CLOSE",
  [10]  = "BID_OPTION",
  [11] = "ASK_OPTION",
  [12]  = "LAST_OPTION",
  [13]  = "MODEL_OPTION",
  [14]  = "OPEN",
  [15]  = "LOW_13_WEEK",
  [16]  = "HIGH_13_WEEK",
  [17]  = "LOW_26_WEEK",
  [18]  = "HIGH_26_WEEK",
  [19]  = "LOW_52_WEEK",
  [20]  = "HIGH_52_WEEK",
  [21]  = "AVG_VOLUME",
  [22]  = "OPEN_INTEREST",
  [23]  = "OPTION_HISTORICAL_VOL",
  [24]  = "OPTION_IMPLIED_VOL",
  [25]  = "OPTION_BID_EXCH",
  [26]  = "OPTION_ASK_EXCH",
  [27]  = "OPTION_CALL_OPEN_INTEREST",
  [28]  = "OPTION_PUT_OPEN_INTEREST",
  [29]  = "OPTION_CALL_VOLUME",
  [30]  = "OPTION_PUT_VOLUME",
  [31]  = "INDEX_FUTURE_PREMIUM",
  [32]  = "BID_EXCH",
  [33]  = "ASK_EXCH",
  [34]  = "AUCTION_VOLUME",
  [35]  = "AUCTION_PRICE",
  [36]  = "AUCTION_IMBALANCE",
  [37]  = "MARK_PRICE",
  [38]  = "BID_EFP_COMPUTATION",
  [39]  = "ASK_EFP_COMPUTATION",
  [40]  = "LAST_EFP_COMPUTATION",
  [41]  = "OPEN_EFP_COMPUTATION",
  [42]  = "HIGH_EFP_COMPUTATION",
  [43]  = "LOW_EFP_COMPUTATION",
  [44]  = "CLOSE_EFP_COMPUTATION",
  [45]  = "LAST_TIMESTAMP",
  [46]  = "SHORTABLE",
  [47]  = "FUNDAMENTAL_RATIOS",
  [48]  = "RT_VOLUME",
  [49]  = "HALTED",
  [50]  = "BID_YIELD",
  [51]  = "ASK_YIELD",
  [52]  = "LAST_YIELD",
  [53]  = "CUST_OPTION_COMPUTATION",
  [54]  = "TRADE_COUNT",
  [55]  = "TRADE_RATE",
  [56]  = "VOLUME_RATE",
  [57]  = "LAST_RTH_TRADE",
  [61]  = "REGULATORY_IMBALANCE",
}

-- decoder helper

local function sendMsg(s, t, ...)
  local message_handler = s.handler.message
  if message_handler then
    message_handler(s, t, ...)
  end
end

local function readStr(fd)
  local token = socket.readline(fd, "\0")
  return token
end

local function readInt(fd)
  local token = readStr(fd)
  return math.tointeger(token)
end

local function readDouble(fd)
  local token = readStr(fd)
  return tonumber(token)
end

local function readBool(fd)
  local i = readInt(fd)
  if i == nil then
    return false
  elseif i ~= 0 then
    return true
  else
    return false
  end
end

local function readIntMax(fd)
  local token = readStr(fd)
  if not token then return nil end
  if string.len(token) == 0 then return nil end
  return math.tointeger(token)
end

local function readDoubleMax(fd)
  local token = readStr(fd)
  if not token then return nil end
  if string.len(token) == 0 then return nil end
  return tonumber(token)
end

local readLong = readInt

local decoder = {}

-- internal api --
local function processMsg(s)
  while true do
    local msgId = readInt(s.fd)
    local f = decoder[msgId]
    if f then
      f(s)
    else
      local msg = string.format("%d %s\n", errorCode, errorMsg)
      skynet.error(msg)
      s:eDisconnect()
      local handler = self.handler.disconnect
      if handler then
        handler(self)
      end
    end
  end   -- while
end

-- decoder function --
decoder[TICK_PRICE] = function(s)
  local version = readInt(s.fd)
  local tickerId = readInt(s.fd)
  local tickType = readInt(s.fd)
  local price = readDouble(s.fd)
  local size = 0
  if version >= 2 then
    size = readInt(s.fd)
  end
  local canAutoExecute = 0
  if version >= 3 then
    canAutoExecute = readInt(s.fd)
  end

  sendMsg(s, TICK_PRICE, tickerId, tickType, price, size, canAutoExecute)
end

decoder[TICK_SIZE] = function(s)
  local version = readInt(s.fd)
  local tickerId = readInt(s.fd)
  local tickType = readInt(s.fd)
  local size = readInt(s.fd)

  sendMsg(s, TICK_SIZE, tickerId, tickType, size)
end

decoder[POSITION] = function(s)
  local version = readInt(s.fd)
  local account = readStr(s.fd)

  contract = {}
  contract.conId = readInt(s.fd)
  contract.symbol = readStr(s.fd)
  contract.secType = readStr(s.fd)
  contract.expiry = readStr(s.fd)
  contract.strike = readDouble(s.fd)
  contract.right = readStr(s.fd)
  contract.multiplier = readStr(s.fd)
  contract.exchange = readStr(s.fd)
  contract.currency = readStr(s.fd)
  contract.localSymbol = readStr(s.fd)
  if version >= 2 then
    contract.tradingClass = readStr(s.fd)
  end

  local pos = readInt(s.fd)
  local avgCost = 0

  if version >= 3 then
    avgCost = readDouble(s.fd)
  end
  sendMsg(s, POSITION, account, contract, pos, avgCost)
end

decoder[POSITION_END] = function(s)
  local version = readInt(s.fd)
  sendMsg(s, POSITION_END)
end

decoder[ACCOUNT_SUMMARY] = function(s)
  local version = readInt(s.fd)
  local reqId = readInt(s.fd)
  local account = readStr(s.fd)
  local tag = readStr(s.fd)
  local value = readStr(s.fd)
  local currency = readStr(s.fd)
  sendMsg(s, ACCOUNT_SUMMARY, reqId, account, tag, value, currency)  
end

decoder[ACCOUNT_SUMMARY_END] = function(s)
  local version = readInt(s.fd)
  local reqId = readInt(s.fd)
  sendMsg(s, ACCOUNT_SUMMARY_END, reqId)  
end

decoder[TICK_OPTION_COMPUTATION] = function(s)
  local version = readInt(s.fd)
  local tickerId = readInt(s.fd)
  local tickType = readInt(s.fd)
  local impliedVol = readDouble(s.fd)
  if impliedVol < 0 then -- -1 is the "not yet computed" indicator
    impliedVol = nil
  end
  local delta = readDouble(s.fd)
  if math.abs(delta) > 1 then -- -2 is the "not yet computed" indicator
    delta = nil
  end
  local optPrice = nil
  local pvDividend = nil
  local gamma = nil
  local vega = nil
  local theta = nil
  local undPrice = nil
  -- TODO
  if version >= 6   or tickType == TickType.MODEL_OPTION then -- introduced in version == 5
    optPrice = readDouble(s.fd)
    if optPrice < 0 then -- -1 is the "not yet computed" indicator
      optPrice = nil
    end
    pvDividend = readDouble(s.fd)
    if pvDividend < 0 then -- -1 is the "not yet computed" indicator
      pvDividend = nil
    end
  end
  if version >= 6 then
    gamma = readDouble(s.fd)
    if math.abs(gamma) > 1 then -- -2 is the "not yet computed" indicator
      gamma = nil
    end
    vega = readDouble(s.fd)
    if math.abs(vega) > 1 then -- -2 is the "not yet computed" indicator
      vega = nil
    end
    theta = readDouble(s.fd)
    if math.abs(theta) > 1 then -- -2 is the "not yet computed" indicator
      theta = nil
    end
    undPrice = readDouble(s.fd)
    if undPrice < 0 then -- -1 is the "not yet computed" indicator
      undPrice = nil
    end
  end

  sendMsg(s, TICK_OPTION_COMPUTATION, tickerId, tickType, impliedVol, delta, optPrice, pvDividend, gamma, vega, theta, undPrice)  
end

decoder[TICK_GENERIC] = function(s)
  local version = readInt(s.fd)
  local tickerId = readInt(s.fd)
  local tickType = readInt(s.fd)
  local value = readDouble(s.fd)
  sendMsg(s, TICK_GENERIC, tickerId, tickType, value)  
end

decoder[TICK_STRING] = function(s)
  local version = readInt(s.fd)
  local tickerId = readInt(s.fd)
  local tickType = readInt(s.fd)
  local value = readStr(s.fd)
  sendMsg(s, TICK_STRING, tickerId, tickType, value)  
end

decoder[TICK_EFP] = function(s)
  local version = readInt(s.fd)
  local tickerId = readInt(s.fd)
  local tickType = readInt(s.fd)
  local basisPoints = readDouble(s.fd)
  local formattedBasisPoints = readStr(s.fd)
  local impliedFuturesPrice = readDouble(s.fd)
  local holdDays = readInt(s.fd)
  local futureExpiry = readStr(s.fd)
  local dividendImpact = readDouble(s.fd)
  local dividendsToExpiry = readDouble(s.fd)

  sendMsg(s, TICK_EFP, tickerId, tickType, basisPoints, formattedBasisPoints,
    impliedFuturesPrice, holdDays, futureExpiry, dividendImpact, dividendsToExpiry)  
end

decoder[ORDER_STATUS] = function(s)
  local version = readInt(s.fd)
  local id = readInt(s.fd)
  local status = readStr(s.fd)
  local filled = readInt(s.fd)
  local remaining = readInt(s.fd)
  local avgFillPrice = readDouble(s.fd)

  local permId = 0
  if  version >= 2 then
    permId = readInt(s.fd)
  end

  local parentId = 0
  if  version >= 3 then
    parentId = readInt(s.fd)
  end

  local lastFillPrice = 0
  if  version >= 4 then
    lastFillPrice = readDouble(s.fd)
  end

  local clientId = 0
  if  version >= 5 then
    clientId = readInt(s.fd)
  end

  local whyHeld = null
  if  version >= 6 then
    whyHeld = readStr(s.fd)
  end
  sendMsg(s, ORDER_STATUS, id, status, filled, remaining, avgFillPrice,
    permId, parentId, lastFillPrice, clientId, whyHeld)
end

decoder[ACCT_VALUE] = function(s)
  local version = readInt(s.fd)
  local key = readStr(s.fd)
  local val  = readStr(s.fd)
  local cur = readStr(s.fd)
  local accountName = null
  if  version >= 2 then
    accountName = readStr(s.fd)
  end
  sendMsg(s, ACCT_VALUE, key, val, cur, accountName)
end

decoder[PORTFOLIO_VALUE] = function(s)
  local version = readInt(s.fd)
  local contract = {}
  if version >= 6 then
    contract.conId = readInt(s.fd)
  end
  contract.symbol  = readStr(s.fd)
  contract.secType = readStr(s.fd)
  contract.expiry  = readStr(s.fd)
  contract.strike  = readDouble(s.fd)
  contract.right   = readStr(s.fd)
  if version >= 7 then
    contract.multiplier = readStr(s.fd)
    contract.primaryExch = readStr(s.fd)
  end
  contract.currency = readStr(s.fd)
  if  version >= 2  then
    contract.localSymbol = readStr(s.fd)
  end
  if version >= 8 then
    contract.tradingClass = readStr(s.fd)
  end

  local position  = readInt(s.fd)
  local marketPrice = readDouble(s.fd)
  local marketValue = readDouble(s.fd)
  local  averageCost = 0.0
  local  unrealizedPNL = 0.0
  local  realizedPNL = 0.0
  if version >=3  then
    averageCost = readDouble(s.fd)
    unrealizedPNL = readDouble(s.fd)
    realizedPNL = readDouble(s.fd)
  end

  local accountName = null
  if  version >= 4 then
    accountName = readStr(s.fd)
  end

  sendMsg(s, PORTFOLIO_VALUE, contract, position, marketPrice, marketValue,
    averageCost, unrealizedPNL, realizedPNL, accountName)  
end


decoder[ACCT_UPDATE_TIME] = function(s)
  local version = readInt(s.fd)
  local timeStamp = readStr(s.fd)
  sendMsg(s, ACCT_UPDATE_TIME, timeStamp)
end

decoder[ERR_MSG] = function(s)
  local version = readInt(s.fd)
  local errorId = EClientErrors.NO_VALID_ID
  local errorCode = EClientErrors.UNKNOWN_ID.code
  local errorMsg
  if version < 2 then
    errorMsg = readStr(s.fd)
  else
    errorId = readInt(s.fd)
    errorCode    = readInt(s.fd)
    errorMsg = readStr(s.fd)
  end
  -- TODO
  sendMsg(s, ERR_MSG, errorId, errorCode, errorMsg)  
end

decoder[OPEN_ORDER] = function(s)
  -- read version
  local version = readInt(s.fd)

  -- read order id
  local order = {}
  order.orderId = readInt(s.fd)

  -- read contract fields
  local contract = {}
  if version >= 17 then
    contract.conId = readInt(s.fd)
  end
  contract.symbol = readStr(s.fd)
  contract.secType = readStr(s.fd)
  contract.expiry = readStr(s.fd)
  contract.strike = readDouble(s.fd)
  contract.right = readStr(s.fd)
  if  version >= 32 then
    contract.multiplier = readStr(s.fd)
  end
  contract.exchange = readStr(s.fd)
  contract.currency = readStr(s.fd)
  if  version >= 2  then
    contract.localSymbol = readStr(s.fd)
  end
  if version >= 32 then
    contract.tradingClass = readStr(s.fd)
  end

  -- read order fields
  order.action = readStr(s.fd)
  order.totalQuantity = readInt(s.fd)
  order.orderType = readStr(s.fd)

  if version < 29 then
    order.lmtPrice = readDouble(s.fd)
  else
    order.lmtPrice = readDoubleMax(s.fd)
  end

  if version < 30 then
    order.auxPrice = readDouble(s.fd)
  else
    order.auxPrice = readDoubleMax(s.fd)
  end

  order.tif = readStr(s.fd)
  order.ocaGroup = readStr(s.fd)
  order.account = readStr(s.fd)
  order.openClose = readStr(s.fd)
  order.origin = readInt(s.fd)
  order.orderRef = readStr(s.fd)

  if version >= 3 then
    order.clientId = readInt(s.fd)
  end

  if  version >= 4  then
    order.permId = readInt(s.fd)
    --if  version < 18 then
    -- will never happen
    --    order.ignoreRth = readBool(s.fd)
    --else
    order.outsideRth = readBool(s.fd)
    --end
    order.hidden = readBool(s.fd)
    order.discretionaryAmt = readDouble(s.fd)
  end

  if  version >= 5  then
    order.goodAfterTime = readStr(s.fd)
  end

  if  version >= 6  then
    -- skip deprecated sharesAllocation field
    readStr(s.fd)
  end

  if  version >= 7  then
    order.faGroup = readStr(s.fd)
    order.faMethod = readStr(s.fd)
    order.faPercentage = readStr(s.fd)
    order.faProfile = readStr(s.fd)
  end

  if  version >= 8  then
    order.goodTillDate = readStr(s.fd)
  end

  if  version >= 9 then
    order.rule80A = readStr(s.fd)
    order.percentOffset = readDoubleMax(s.fd)
    order.settlingFirm = readStr(s.fd)
    order.shortSaleSlot = readInt(s.fd)
    order.designatedLocation = readStr(s.fd)
    --if  s.serverVersion == 51 then
    --    readInt(s.fd) -- exemptCode
    --else 
    if  version >= 23 then
      order.exemptCode = readInt(s.fd)
    end
    order.auctionStrategy = readInt(s.fd)
    order.startingPrice = readDoubleMax(s.fd)
    order.stockRefPrice = readDoubleMax(s.fd)
    order.delta = readDoubleMax(s.fd)
    order.stockRangeLower = readDoubleMax(s.fd)
    order.stockRangeUpper = readDoubleMax(s.fd)
    order.displaySize = readInt(s.fd)
    --if  version < 18 then
    -- will never happen
    --    order.rthOnly = readBool(s.fd)
    --end
    order.blockOrder = readBool(s.fd)
    order.sweepToFill = readBool(s.fd)
    order.allOrNone = readBool(s.fd)
    order.minQty = readIntMax(s.fd)
    order.ocaType = readInt(s.fd)
    order.eTradeOnly = readBool(s.fd)
    order.firmQuoteOnly = readBool(s.fd)
    order.nbboPriceCap = readDoubleMax(s.fd)
  end

  if  version >= 10 then
    order.parentId = readInt(s.fd)
    order.triggerMethod = readInt(s.fd)
  end

  if version >= 11 then
    order.volatility = readDoubleMax(s.fd)
    order.volatilityType = readInt(s.fd)
    --[[if version == 11 then
                        local receivedlocal = readInt(s.fd)
                        if receivedlocal == 0 then
                          order.deltaNeutralOrderType = "NONE"
                        else
                          order.deltaNeutralOrderType = "MKT"
                        end
                    else -- version 12 and up ]]--
    order.deltaNeutralOrderType = readStr(s.fd)
    order.deltaNeutralAuxPrice = readDoubleMax(s.fd)

    if version >= 27 then
      if StringIsEmpty(order.deltaNeutralOrderType) == false then
        order.deltaNeutralConId = readInt(s.fd)
        order.deltaNeutralSettlingFirm = readStr(s.fd)
        order.deltaNeutralClearingAccount = readStr(s.fd)
        order.deltaNeutralClearingIntent = readStr(s.fd)
      end
    end

    if version >= 31 then
      if StringIsEmpty(order.deltaNeutralOrderType) == false then
        order.deltaNeutralOpenClose = readStr(s.fd)
        order.deltaNeutralShortSale = readBool(s.fd)
        order.deltaNeutralShortSaleSlot = readInt(s.fd)
        order.deltaNeutralDesignatedLocation = readStr(s.fd)
      end
    end
    --end
    order.continuousUpdate = readInt(s.fd)
    --[[if s.serverVersion == 26 then
                        order.stockRangeLower = readDouble(s.fd)
                        order.stockRangeUpper = readDouble(s.fd)
                    end]]--
  order.referencePriceType = readInt(s.fd)
end

if version >= 13 then
  order.trailStopPrice = readDoubleMax(s.fd)
end

if version >= 30 then
  order.trailingPercent = readDoubleMax(s.fd)
end

if version >= 14 then
  order.basisPoints = readDoubleMax(s.fd)
  order.basisPointsType = readIntMax(s.fd)
  contract.comboLegsDescrip = readStr(s.fd)
end

if version >= 29 then
  local comboLegsCount = readInt(s.fd) or 0
  if comboLegsCount > 0 then
    contract.comboLegs = {}
    for i = 1, comboLegsCount do
      contract.comboLegs[i] = {}
      local leg = contract.comboLegs[i]
      leg.conId = readInt(s.fd)
      leg.ratio = readInt(s.fd)
      leg.action = readStr(s.fd)
      leg.exchange = readStr(s.fd)
      leg.openClose = readInt(s.fd)
      leg.shortSaleSlot = readInt(s.fd)
      leg.designatedLocation = readStr(s.fd)
      leg.exemptCode = readInt(s.fd)
    end
  end

  local orderComboLegsCount = readInt(s.fd) or 0
  if orderComboLegsCount > 0 then
    order.orderComboLegs = {}
    for i = 1,orderComboLegsCount do
      local price = readDoubleMax(s.fd)
      order.orderComboLegs[i] = price
    end
  end
end

if version >= 26 then
  local smartComboRoutingParamsCount = readInt(s.fd) or 0
  if smartComboRoutingParamsCount > 0 then
    order.smartComboRoutingParams = {}
    for i = 1, smartComboRoutingParamsCount do
      local tagValue = {}
      tagValue.tag = readStr(s.fd)
      tagValue.value = readStr(s.fd)
      order.smartComboRoutingParams[i] = tagValue
    end
  end
end

if version >= 15 then
  if version >= 20 then
    order.scaleInitLevelSize = readIntMax(s.fd)
    order.scaleSubsLevelSize = readIntMax(s.fd)
  else
    -- local notSuppScaleNumComponents =
    readIntMax(s.fd)
    order.scaleInitLevelSize = readIntMax(s.fd)
  end
  order.scalePriceIncrement = readDoubleMax(s.fd)
end

if version >= 28 then
  if order.scalePriceIncrement ~= nil then
    if order.scalePriceIncrement > 0.0 then
      order.scalePriceAdjustValue = readDoubleMax(s.fd)
      order.scalePriceAdjustInterval = readIntMax(s.fd)
      order.scaleProfitOffset = readDoubleMax(s.fd)
      order.scaleAutoReset = readBool(s.fd)
      order.scaleInitPosition = readIntMax(s.fd)
      order.scaleInitFillQty = readIntMax(s.fd)
      order.scaleRandomPercent = readBool(s.fd)
    end
  end
end

if version >= 24 then
  order.hedgeType = readStr(s.fd)
  if StringIsEmpty(order.hedgeType) == false then
    order.hedgeParam = readStr(s.fd)
  end
end

if version >= 25 then
  order.optOutSmartRouting = readBool(s.fd)
end

if version >= 19 then
  order.clearingAccount = readStr(s.fd)
  order.clearingIntent = readStr(s.fd)
end

if version >= 22 then
  order.notHeld = readBool(s.fd)
end

if version >= 20 then
  local hasUnderComp = readBool(s.fd)
  if hasUnderComp then
    local underComp = {}
    underComp.conId = readInt(s.fd)
    underComp.delta = readDouble(s.fd)
    underComp.price = readDouble(s.fd)
    contract.underComp = underComp
  end
end

if version >= 21 then
  order.algoStrategy = readStr(s.fd)
  if StringIsEmpty(order.algoStrategy) == false then
    local algoParamsCount = readInt(s.fd) or 0
    if algoParamsCount > 0 then
      order.algoParams = {}
      for i = 1, algoParamsCount do
        local tagValue = {}
        tagValue.tag = readStr(s.fd)
        tagValue.value = readStr(s.fd)
        order.algoParams[i] = tagValue
      end
    end
  end
end

local orderState = {}

if version >= 16 then

  order.whatIf = readBool(s.fd)

  orderState.status = readStr(s.fd)
  orderState.initMargin = readStr(s.fd)
  orderState.maintMargin = readStr(s.fd)
  orderState.equityWithLoan = readStr(s.fd)
  orderState.commission = readDoubleMax(s.fd)
  orderState.minCommission = readDoubleMax(s.fd)
  orderState.maxCommission = readDoubleMax(s.fd)
  orderState.commissionCurrency = readStr(s.fd)
  orderState.warningText = readStr(s.fd)
end

sendMsg(s, OPEN_ORDER, order.orderId, contract, order, orderState)
end


decoder[NEXT_VALID_ID] = function(s)
  local version = readInt(s.fd)
  local orderId = readInt(s.fd)
  sendMsg(s, NEXT_VALID_ID, orderId)
end

decoder[SCANNER_DATA] = function(s)
  local contract = {}
  contract.summary = {}
  local version = readInt(s.fd)
  local tickerId = readInt(s.fd)
  local numberOfElements = readInt(s.fd)
  --local elements = {}
  for ctr=1, numberOfElements do
    local rank = readInt(s.fd)
    if version >= 3 then
      contract.summary.conId = readInt(s.fd)
    end
    contract.summary.symbol = readStr(s.fd)
    contract.summary.secType = readStr(s.fd)
    contract.summary.expiry = readStr(s.fd)
    contract.summary.strike = readDouble(s.fd)
    contract.summary.right = readStr(s.fd)
    contract.summary.exchange = readStr(s.fd)
    contract.summary.currency = readStr(s.fd)
    contract.summary.localSymbol = readStr(s.fd)
    contract.marketName = readStr(s.fd)
    contract.summary.tradingClass = readStr(s.fd)
    local distance = readStr(s.fd)
    local benchmark = readStr(s.fd)
    local projection = readStr(s.fd)
    local legsStr = null
    if version >= 2 then
      legsStr = readStr(s.fd)
    end

    sendMsg(s, SCANNER_DATA, rank, contract, distance,
      benchmark, projection, legsStr)
  end

  sendMsg(s, SCANNER_DATA_END, tickerId)
end

decoder[CONTRACT_DATA] = function(s)
  local version = readInt(s.fd)

  local reqId = -1
  if version >= 3 then
    reqId = readInt(s.fd)
  end

  local contract = {}
  contract.summary = {}
  contract.summary.symbol = readStr(s.fd)
  contract.summary.secType = readStr(s.fd)
  contract.summary.expiry = readStr(s.fd)
  contract.summary.strike = readDouble(s.fd)
  contract.summary.right = readStr(s.fd)
  contract.summary.exchange = readStr(s.fd)
  contract.summary.currency = readStr(s.fd)
  contract.summary.localSymbol = readStr(s.fd)
  contract.marketName = readStr(s.fd)
  contract.summary.tradingClass = readStr(s.fd)
  contract.summary.conId = readInt(s.fd)
  contract.minTick = readDouble(s.fd)
  contract.summary.multiplier = readStr(s.fd)
  contract.orderTypes = readStr(s.fd)
  contract.validExchanges = readStr(s.fd)
  if version >= 2 then
    contract.priceMagnifier = readInt(s.fd)
  end
  if version >= 4 then
    contract.underConId = readInt(s.fd)
  end
  if  version >= 5 then
    contract.longName = readStr(s.fd)
    contract.summary.primaryExch = readStr(s.fd)
  end
  if  version >= 6 then
    contract.contractMonth = readStr(s.fd)
    contract.industry = readStr(s.fd)
    contract.category = readStr(s.fd)
    contract.subcategory = readStr(s.fd)
    contract.timeZoneId = readStr(s.fd)
    contract.tradingHours = readStr(s.fd)
    contract.liquidHours = readStr(s.fd)
  end
  if version >= 8 then
    contract.evRule = readStr(s.fd)
    contract.evMultiplier = readDouble(s.fd)
  end
  if version >= 7 then
    local secIdListCount = readInt(s.fd)
    if secIdListCount  > 0 then
      contract.secIdList = {}
      for i = 1, secIdListCount do
        local tagValue = {}
        tagValue.tag = readStr(s.fd)
        tagValue.value = readStr(s.fd)
        contract.secIdList[i] = tagValue
      end
    end
  end
  --s.contractDetails( reqId, contract)
  sendMsg(s, CONTRACT_DATA, contract)  
end

decoder[BOND_CONTRACT_DATA] = function(s)
  local version = readInt(s.fd)

  local reqId = -1
  if version >= 3 then
    reqId = readInt(s.fd)
  end

  local contract = {}
  contract.summary = {}
  contract.summary.symbol = readStr(s.fd)
  contract.summary.secType = readStr(s.fd)
  contract.cusip = readStr(s.fd)
  contract.coupon = readDouble(s.fd)
  contract.maturity = readStr(s.fd)
  contract.issueDate  = readStr(s.fd)
  contract.ratings = readStr(s.fd)
  contract.bondType = readStr(s.fd)
  contract.couponType = readStr(s.fd)
  contract.convertible = readBool(s.fd)
  contract.callable = readBool(s.fd)
  contract.putable = readBool(s.fd)
  contract.descAppend = readStr(s.fd)
  contract.summary.exchange = readStr(s.fd)
  contract.summary.currency = readStr(s.fd)
  contract.marketName = readStr(s.fd)
  contract.summary.tradingClass = readStr(s.fd)
  contract.summary.conId = readInt(s.fd)
  contract.minTick = readDouble(s.fd)
  contract.orderTypes = readStr(s.fd)
  contract.validExchanges = readStr(s.fd)
  if version >= 2 then
    contract.nextOptionDate = readStr(s.fd)
    contract.nextOptionType = readStr(s.fd)
    contract.nextOptionPartial = readBool(s.fd)
    contract.notes = readStr(s.fd)
  end
  if  version >= 4 then
    contract.longName = readStr(s.fd)
  end
  if  version >= 6 then
    contract.evRule = readStr(s.fd)
    contract.evMultiplier = readDouble(s.fd)
  end
  if version >= 5 then
    local secIdListCount = readInt(s.fd)
    if secIdListCount  > 0 then
      contract.secIdList = {}
      for i = 1, secIdListCount do
        local tagValue = {}
        tagValue.tag = readStr(s.fd)
        tagValue.value = readStr(s.fd)
        contract.secIdList[i] = tagValue
      end
    end
  end
  sendMsg(s, BOND_CONTRACT_DATA, reqId, contract)
end

decoder[EXECUTION_DATA] = function(s)
  local version = readInt(s.fd)

  local reqId = -1
  if version >= 7 then
    reqId = readInt(s.fd)
  end

  local orderId = readInt(s.fd)

  -- read contract fields
  local contract = {}
  if version >= 5 then
    contract.conId = readInt(s.fd)
  end
  contract.symbol = readStr(s.fd)
  contract.secType = readStr(s.fd)
  contract.expiry = readStr(s.fd)
  contract.strike = readDouble(s.fd)
  contract.right = readStr(s.fd)
  if version >= 9 then
    contract.multiplier = readStr(s.fd)
  end
  contract.exchange = readStr(s.fd)
  contract.currency = readStr(s.fd)
  contract.localSymbol = readStr(s.fd)
  if version >= 10 then
    contract.tradingClass = readStr(s.fd)
  end

  local exec = {}
  exec.orderId = orderId
  exec.execId = readStr(s.fd)
  exec.time = readStr(s.fd)
  exec.acctNumber = readStr(s.fd)
  exec.exchange = readStr(s.fd)
  exec.side = readStr(s.fd)
  exec.shares = readInt(s.fd)
  exec.price = readDouble(s.fd)
  if  version >= 2  then
    exec.permId = readInt(s.fd)
  end
  if  version >= 3 then
    exec.clientId = readInt(s.fd)
  end
  if  version >= 4 then
    exec.liquidation = readInt(s.fd)
  end
  if version >= 6 then
    exec.cumQty = readInt(s.fd)
    exec.avgPrice = readDouble(s.fd)
  end
  if version >= 8 then
    exec.orderRef = readStr(s.fd)
  end
  if version >= 9 then
    exec.evRule = readStr(s.fd)
    exec.evMultiplier = readDouble(s.fd)
  end

  sendMsg(s, EXECUTION_DATA, reqId, contract, exec)  
end


decoder[MARKET_DEPTH] = function(s)
  local version = readInt(s.fd)
  local id = readInt(s.fd)

  local position = readInt(s.fd)
  local operation = readInt(s.fd)
  local side = readInt(s.fd)
  local price = readDouble(s.fd)
  local size = readInt(s.fd)

  sendMsg(s, MARKET_DEPTH, id, position, operation, side, price, size)  
end

decoder[MARKET_DEPTH_L2] = function(s)
  local version = readInt(s.fd)
  local id = readInt(s.fd)

  local position = readInt(s.fd)
  local marketMaker = readStr(s.fd)
  local operation = readInt(s.fd)
  local side = readInt(s.fd)
  local price = readDouble(s.fd)
  local size = readInt(s.fd)

  sendMsg(s, MARKET_DEPTH_L2, id, position, marketMaker, operation, side, price, size)  
end

decoder[NEWS_BULLETINS] = function(s)
  local version = readInt(s.fd)
  local newsMsgId = readInt(s.fd)
  local newsMsgType = readInt(s.fd)
  local newsMessage = readStr(s.fd)
  local originatingExch = readStr(s.fd)

  sendMsg(s, NEWS_BULLETINS, newsMsgId, newsMsgType, newsMessage, originatingExch)  
end

decoder[MANAGED_ACCTS] = function(s)
  local version = readInt(s.fd)
  local accountsList = readStr(s.fd)
  sendMsg(s, MANAGED_ACCTS, accountsList)  
end

decoder[RECEIVE_FA] = function(s)
  local version = readInt(s.fd)
  local faDataType = readInt(s.fd)
  local xml = readStr(s.fd)

  sendMsg(s, RECEIVE_FA, faDataType, xml)  
end

decoder[HISTORICAL_DATA] = function(s)
  local version = readInt(s.fd)
  local reqId = readInt(s.fd)
  local startDateStr
  local endDateStr
  local completedIndicator = "finished"
  if version >= 2 then
    startDateStr = readStr(s.fd)
    endDateStr = readStr(s.fd)
    completedIndicator = completedIndicator .."-" .. startDateStr .. "-" .. endDateStr
  end
  local itemCount = readInt(s.fd)
  for ctr = 1, itemCount do
    local date = readStr(s.fd)
    local open = readDouble(s.fd)
    local high = readDouble(s.fd)
    local low = readDouble(s.fd)
    local close = readDouble(s.fd)
    local volume = readInt(s.fd)
    local WAP = readDouble(s.fd)
    local hasGaps = readBool(s.fd)
    local barCount = -1
    if version >= 3 then
      barCount = readInt(s.fd)
    end

    sendMsg(s, HISTORICAL_DATA, reqId, date, open, high, low, close, volume, barCount, WAP, hasGaps)
  end
  -- send end of dataset marker

  sendMsg(s, HISTORICAL_DATA, reqId, completedIndicator, -1, -1, -1, -1, -1, -1, -1, false)  
end

decoder[SCANNER_PARAMETERS] = function(s)
  local version = readInt(s.fd)
  local xml = readStr(s.fd)

  sendMsg(s, SCANNER_PARAMETERS, xml)  
end

decoder[CURRENT_TIME] = function(s)
  local version = readInt(s.fd)
  local time = readLong(s.fd)

  sendMsg(s, CURRENT_TIME, time)  
end

decoder[REAL_TIME_BARS] = function(s)
  local version = readInt(s.fd)
  local reqId = readInt(s.fd)
  local time = readLong()
  local open = readDouble(s.fd)
  local high = readDouble(s.fd)
  local low = readDouble(s.fd)
  local close = readDouble(s.fd)
  local volume = readLong()
  local wap = readDouble(s.fd)
  local count = readInt(s.fd)

  sendMsg(s, REAL_TIME_BARS, reqId, time, open, high, low, close, volume, wap, count)  
end

decoder[FUNDAMENTAL_DATA] = function(s)
  local version = readInt(s.fd)
  local reqId = readInt(s.fd)
  local data = readStr(s.fd)

  sendMsg(s, FUNDAMENTAL_DATA, reqId, data)  
end

decoder[CONTRACT_DATA_END] = function(s)
  local version = readInt(s.fd)
  local reqId = readInt(s.fd)

  sendMsg(s, CONTRACT_DATA_END, reqId)  
end
decoder[OPEN_ORDER_END] = function(s)
  local version = readInt(s.fd)
  sendMsg(s, OPEN_ORDER_END)  
end

decoder[ACCT_DOWNLOAD_END] = function(s)
  local version = readInt(s.fd)
  local accountName = readStr(s.fd)

  sendMsg(s, ACCT_DOWNLOAD_END, accountName)  
end

decoder[EXECUTION_DATA_END] = function(s)
  local version = readInt(s.fd)
  local reqId = readInt(s.fd)

  sendMsg(s, EXECUTION_DATA_END, reqId)  
end

decoder[DELTA_NEUTRAL_VALIDATION] = function(s)
  local version = readInt(s.fd)
  local reqId = readInt(s.fd)

  local underComp = {}
  underComp.conId = readInt(s.fd)
  underComp.delta = readDouble(s.fd)
  underComp.price = readDouble(s.fd)

  sendMsg(s, DELTA_NEUTRAL_VALIDATION, reqId, underComp)  
end

decoder[TICK_SNAPSHOT_END] = function(s)
  local version = readInt(s.fd)
  local reqId = readInt(s.fd)

  sendMsg(s, TICK_SNAPSHOT_END, reqId)  
end

decoder[MARKET_DATA_TYPE] = function(s)
  local version = readInt(s.fd)
  local reqId = readInt(s.fd)
  local marketDataType = readInt(s.fd)

  sendMsg(s, MARKET_DATA_TYPE, reqId, marketDataType) 
end

decoder[COMMISSION_REPORT] = function(s)
  local version = readInt(s.fd)

  local commissionReport = {}
  commissionReport.execId = readStr(s.fd)
  commissionReport.commission = readDouble(s.fd)
  commissionReport.currency = readStr(s.fd)
  commissionReport.realizedPNL = readDouble(s.fd)
  commissionReport.yield = readDouble(s.fd)
  commissionReport.yieldRedemptionDate = readInt(s.fd)

  sendMsg(s, COMMISSION_REPORT, commissionReport)
end

decoder[VERIFY_MESSAGE_API] = function(s)
  local version = readInt(s.fd)
  local apiData = readStr(s.fd)

  sendMsg(s, VERIFY_MESSAGE_API, apiData)  
end

decoder[VERIFY_COMPLETED] = function(s)
  local version = readInt(s.fd)
  local isSuccessfulStr = readStr(s.fd)
  local isSuccessful = "true" == isSuccessfulStr
  local errorText = readStr(s.fd)


  if isSuccessful then
    startAPI(s)
  end

  sendMsg(s, VERIFY_COMPLETED, isSuccessful, errorText)
end

decoder[DISPLAY_GROUP_LIST] = function(s)
  local version = readInt(s.fd)
  local reqId = readInt(s.fd)
  local groups = readStr(s.fd)

  sendMsg(s, DISPLAY_GROUP_LIST, reqId, groups)
end

decoder[DISPLAY_GROUP_UPDATED] = function(s)
  local version = readInt(s.fd)
  local reqId = readInt(s.fd)
  local contractInfo = readStr(s.fd)

  sendMsg(s, DISPLAY_GROUP_UPDATED, reqId, contractInfo)
end

--encoder helper --
local function sendEOL(conn)
  socket.write(conn.fd, "\000")
  --s.buf[#s.buf + 1] = '\0'
end

local function sendStr(conn, v)
  if v then
    assert(type(v) == "string")
    if string.len(v) > 0 then
      socket.write(conn.fd, v)
      --s.buf[#s.buf+1] = v
    end
  end
  sendEOL(conn)
end

local function sendInt(conn, v)
  if not v then v= 0 end
  assert(type(v) == "number")
  assert(math.type(v) == "integer")
  socket.write(conn.fd, string.format("%d\000", v))
  --s.buf[#s.buf+1] = string.format("%d\000", v)
end

local function sendBool(conn, v)
  if v then
    assert(type(v) == "boolean")
    socket.write(conn.fd, "1\000")
    --s.buf[#s.buf+1] = "1\000"
  else
    socket.write(conn.fd, "0\000")
    --s.buf[#s.buf+1] = "0\000"
  end
end

local function sendDouble(conn, v)
  if not v then v= 0.0 end
  assert(type(v) == "number")
  socket.write(conn.fd, string.format("%g\000", v))
  --s.buf[#s.buf+1] = string.format("%g\000", v)
end

local function sendMaxInt(conn, v)
  if v == nil then
    sendEOL(conn)
  else
    sendInt(conn, v)
  end
end

local function sendMaxDouble(conn, v)
  if v == nil then
    sendEOL(conn)
  else
    sendDouble(conn, v)
  end
end

local function StringIsEmpty(str)
  if str == nil then return true end
  if str == "" then return true end
  return false
end

-- API --
local function formatOptions(s,Options)
  local OptionsStr = nil
  local OptionsCount = 0

  if scannerSubscriptionOptions ~= nil then 
    OptionsCount = #Options
  end

  if OptionsCount > 0 then
    for i = 1, OptionsCount do
      local tagValue = Options[i]
      OptionsStr = OptionsStr .. tagValue.tag .. "=" .. tagValue.value .. ""
    end
    return OptionsStr
  else
    return nil
  end  
end

local function sendContract(conn, contract, mode)
  sendInt(conn,contract.conId)
  sendStr(conn,contract.symbol)
  sendStr(conn,contract.secType)
  sendStr(conn,contract.expiry)
  sendDouble(conn,contract.strike)
  sendStr(conn,contract.right)
  sendStr(conn,contract.multiplier)
  sendStr(conn,contract.exchange)
  if mode then
    sendStr(conn,contract.primaryExch)
  end
  sendStr(conn,contract.currency)
  sendStr(conn, contract.localSymbol)
  sendStr(conn, contract.tradingClass)
end

local function startAPI(conn)
  local VERSION = 1
  sendInt(conn,START_API)
  sendInt(conn,VERSION)
  sendInt(conn,conn.clientId)
end

function ibapi:reqMktData(tickerId, contract, genericTickList, snapshot, mktDataOptions)
  local VERSION = 11
  --  send req mkt data msg
  sendInt(self,REQ_MKT_DATA)
  sendInt(self,VERSION)
  sendInt(self,tickerId)

  --  send contract fields
  sendContract(self, contract, true) -- true mean send primaryExch

  if "BAG" == contract.secType then
    if contract.comboLegs == nil then
      sendInt(self, 0)
    else
      sendInt(self, #contract.comboLegs)
      for i=1, #contract.comboLegs do
        local comboLeg = contract.comboLegs[i]
        sendInt(self, comboLeg.conId)
        sendInt(self, comboLeg.ratio)
        sendStr(self, comboLeg.action)
        sendStr(self, comboLeg.exchange)
      end
    end
  end

  if contract.underComp == nil then
    sendBool(self, false)
  else
    local underComp = contract.underComp
    sendBool(self, true)
    sendInt(self, underComp.conId)
    sendDouble(self, underComp.delta)
    sendDouble(self, underComp.price)
  end

  sendStr(self, genericTickList)
  sendBool(self, snapshot)
  --  send mktDataOptions parameter
  sendStr(self,formatOptions(mktDataOptions))
end

function ibapi:cancelScannerSubscription(tickerId)
  local VERSION = 1
  sendInt(self, CANCEL_SCANNER_SUBSCRIPTION)
  sendInt(self, VERSION)
  sendInt(self, tickerId)
end

function ibapi:reqScannerParameters()
  local VERSION = 1
  sendInt(self, REQ_SCANNER_PARAMETERS)
  sendInt(self, VERSION)
end


function ibapi:cancelHistoricalData(tickerId )
  local VERSION = 1
  --  send cancel mkt data msg
  sendInt(self, CANCEL_HISTORICAL_DATA)
  sendInt(self, VERSION)
  sendInt(self, tickerId)    
end

function ibapi:reqScannerSubscription(tickerId, subscription, scannerSubscriptionOptions)
  local VERSION = 4

  sendInt(self, REQ_SCANNER_SUBSCRIPTION)
  sendInt(self, VERSION)
  sendInt(self, tickerId)
  sendMaxInt(self, subscription.numberOfRows)
  sendStr(self, subscription.instrument)
  sendStr(self, subscription.locationCode)
  sendStr(self, subscription.scanCode)
  sendMaxDouble(self, subscription.abovePrice)
  sendMaxDouble(self, subscription.belowPrice)
  sendMaxDouble(self, subscription.aboveVolume)
  sendMaxDouble(self, subscription.marketCapAbove)
  sendMaxDouble(self, subscription.marketCapBelow)
  sendStr(self, subscription.moodyRatingAbove)
  sendStr(self, subscription.moodyRatingBelow)
  sendStr(self, subscription.spRatingAbove)
  sendStr(self, subscription.spRatingBelow)
  sendStr(self, subscription.maturityDateAbove)
  sendStr(self, subscription.maturityDateBelow)
  sendMaxDouble(self, subscription.couponRateAbove)
  sendMaxDouble(self, subscription.couponRateBelow)
  sendStr(self, subscription.excludeConvertible)

  sendMaxDouble(self, subscription.averageOptionVolumeAbove)
  sendStr(self, subscription.scannerSettingPairs)
  sendStr(self, subscription.stockTypeFilter)

  --  send scannerSubscriptionOptions parameter
  sendStr(self, formatOptions(scannerSubscriptionOptions))
end

function ibapi:cancelRealTimeBars(tickerId)
  local VERSION = 1
  --  send cancel mkt data msg
  sendInt(self, CANCEL_REAL_TIME_BARS)
  sendInt(self, VERSION)
  sendInt(self, tickerId)
end

-- Note that formatData parameter affects intra-day bars only 1-day bars always return with date in YYYYMMDD format.
function ibapi:reqHistoricalData(tickerId, contract, endDateTime, durationStr, barSizeSetting, whatToShow,
    useRTH, formatDate, chartOptions)
  local VERSION = 6

  sendInt(self, REQ_HISTORICAL_DATA)
  sendInt(self, VERSION)
  sendInt(self, tickerId)

  --  send contract fields
  sendContract(self, contract, true)

  sendBool(self,contract.includeExpired)
  sendStr(self,endDateTime)
  sendStr(self,barSizeSetting)
  sendStr(self,durationStr)
  sendBool(self,useRTH)
  sendStr(self,whatToShow)
  sendInt(self,formatDate)

  if "BAG" == contract.secType then
    if contract.comboLegs == nil then
      sendInt(self,0)
    else
      sendInt(self,#contract.comboLegs)
      local comboLeg              
      for i = 1, #contract.comboLegs do
        comboLeg = contract.comboLegs[i]
        sendInt(self,comboLeg.conId)
        sendInt(self,comboLeg.ratio)
        sendStr(self,comboLeg.action)
        sendStr(self,comboLeg.exchange)
      end
    end
  end 
  --  send chartOptions parameter
  sendStr(self, formatOptions(chartOptions))
end

function ibapi:reqRealTimeBars(tickerId, contract, barSize, whatToShow, useRTH, realTimeBarsOptions)
  local VERSION = 3

  --  send req mkt data msg
  sendInt(self,REQ_REAL_TIME_BARS)
  sendInt(self,VERSION)
  sendInt(self,tickerId)

  --  send contract fields
  sendContract(self, contract, true)

  sendInt(self,barSize)  --  this parameter is not currently used
  sendStr(self,whatToShow)
  sendBool(self,useRTH)
  --  send realTimeBarsOptions parameter
  sendStr(self, formatOptions(realTimeBarsOptions))
end

function ibapi:reqContractDetails(reqId, contract)
  local VERSION = 7

  --  send req mkt data msg
  sendInt(self, REQ_CONTRACT_DATA)
  sendInt(self, VERSION)

  sendInt(self, reqId)

  --  send contract fields
  sendContract(self, contract, false)

  sendInt(self, contract.includeExpired)
  sendStr(self, contract.secIdType)
  sendStr(self, contract.secId)
end

function ibapi:reqMktDepth(tickerId, contract, numRows, mktDepthOptions)
  local VERSION = 5

  --  send req mkt data msg
  sendInt(self, REQ_MKT_DEPTH)
  sendInt(self, VERSION)
  sendInt(self, tickerId)

  --  send contract fields
  sendContract(self, contract, false)

  sendInt(self, numRows)
  --  send mktDepthOptions parameter
  sendStr(self, formatOptions(mktDepthOptions))
end

function ibapi:cancelMktData(tickerId) 
  local VERSION = 1
  --  send cancel mkt data msg
  sendInt(self, CANCEL_MKT_DATA)
  sendInt(self, VERSION)
  sendInt(self, tickerId)
end

function ibapi:cancelMktDepth(tickerId)
  local VERSION = 1
  --  send cancel mkt data msg
  sendInt(self, CANCEL_MKT_DEPTH)
  sendInt(self, VERSION)
  sendInt(self, tickerId)
end

function ibapi:exerciseOptions(tickerId, contract, exerciseAction, exerciseQuantity, account, override)
  local VERSION = 2

  sendInt(self,EXERCISE_OPTIONS)
  sendInt(self,VERSION)
  sendInt(self,tickerId)

  --  send contract fields
  sendContract(self,contract, false)

  sendInt(self,exerciseAction)
  sendInt(self,exerciseQuantity)
  sendStr(self,account)
  sendInt(self,override)
end

function ibapi:placeOrder(orderId, contract, order)

  local VERSION =  42

  --  send place order msg
  sendInt(self, PLACE_ORDER)
  sendInt(self, VERSION)
  sendInt(self, orderId)

  --  send contract fields
  sendContract(self, contract, true)

  sendStr(self, contract.secIdType)
  sendStr(self, contract.secId)

  --  send main order fields
  sendStr(self, order.action)
  sendInt(self, order.totalQuantity)
  sendStr(self, order.orderType)
  sendMaxDouble(self, order.lmtPrice)
  sendMaxDouble(self, order.auxPrice)
  --  send extended order fields
  sendStr(self, order.tif)
  sendStr(self, order.ocaGroup)
  sendStr(self, order.account)
  sendStr(self, order.openClose)
  sendInt(self, order.origin)
  sendStr(self, order.orderRef)
  sendBool(self, order.transmit)
  sendInt(self, order.parentId)

  sendBool(self, order.blockOrder)
  sendBool(self, order.sweepToFill)
  sendInt(self, order.displaySize)
  sendInt(self, order.triggerMethod)
  sendBool(self, order.outsideRth)
  sendBool(self,order.hidden)

  --  Send combo legs for BAG requests
  if "BAG" == contract.secType then
    if contract.comboLegs == nil  then
      sendInt(self, 0)
    else 
      sendInt(self,#contract.comboLegs)
      local comboLeg
      for i=1, #contract.comboLegs do
        comboLeg = contract.comboLegs[i]
        sendInt(self, comboLeg.conId)
        sendInt(self, comboLeg.ratio)
        sendStr(self, comboLeg.action)
        sendStr(self, comboLeg.exchange)

        sendInt(self, comboLeg.openClose)
        sendInt(self, comboLeg.shortSaleSlot)
        sendStr(self, comboLeg.designatedLocation)
        sendInt(self, comboLeg.exemptCode)
      end
    end
  end

  --  Send order combo legs for BAG requests
  if "BAG" == contract.secType then
    if  order.orderComboLegs == nil  then
      sendInt(self, 0)
    else
      sendInt(self, #order.orderComboLegs)

      for i = 1, #order.orderComboLegs do
        sendMaxDouble(self, orderComboLegs[i].price)
      end
    end
  end

  if "BAG" == contract.secType then
    local smartComboRoutingParams = order.smartComboRoutingParams
    local smartComboRoutingParamsCount = 0
    if smartComboRoutingParams ~= nil then  smartComboRoutingParamsCount = #smartComboRoutingParams end
    send(s, smartComboRoutingParamsCount)
    if smartComboRoutingParamsCount > 0 then
      for i = 1, smartComboRoutingParamsCount do
        local tagValue = smartComboRoutingParams[i]
        sendStr(self, tagValue.tag)
        sendStr(self, tagValue.value)
      end
    end
  end

  --  send deprecated sharesAllocation field
  sendStr(self, "")

  sendDouble(self, order.discretionaryAmt)

  sendStr(self, order.goodAfterTime)

  sendStr(self, order.goodTillDate)

  sendStr(self, order.faGroup)
  sendStr(self, order.faMethod)
  sendStr(self, order.faPercentage)
  sendStr(self, order.faProfile)

  sendInt(self, order.shortSaleSlot)      --  0 only for retail, 1 or 2 only for institution.
  sendStr(self, order.designatedLocation) --  only populate when order.shortSaleSlot = 2.

  sendInt(self, order.exemptCode)

  sendInt(self, order.ocaType)

  sendStr(self, order.rule80A)
  sendStr(self, order.settlingFirm)
  sendBool(self, order.allOrNone)
  sendMaxInt(self, order.minQty)
  sendMaxDouble(self, order.percentOffset)
  sendBool(self, order.eTradeOnly)
  sendBool(self, order.firmQuoteOnly)
  sendMaxDouble(self, order.nbboPriceCap)
  sendMaxInt(self, order.auctionStrategy)
  sendMaxDouble(self, order.startingPrice)
  sendMaxDouble(self, order.stockRefPrice)
  sendMaxDouble(self, order.delta)
  --  Volatility orders had specific watermark price attribs in server version 26
  sendMaxDouble(self, order.stockRangeLower)
  sendMaxDouble(self, order.stockRangeUpper)


  sendBool(self, order.overridePercentageConstraints)

  sendMaxDouble(self, order.volatility)
  sendMaxInt(self, order.volatilityType)

  sendStr(self, order.deltaNeutralOrderType)
  sendMaxDouble(self, order.deltaNeutralAuxPrice)

  if order.deltaNeutralOrderType ~= nil  then
    sendInt(self, order.deltaNeutralConId)
    sendStr(self, order.deltaNeutralSettlingFirm)
    sendStr(self, order.deltaNeutralClearingAccount)
    sendStr(self, order.deltaNeutralClearingIntent)
  end

  if order.deltaNeutralOrderType ~= nil then
    sendStr(self, order.deltaNeutralOpenClose)
    sendInt(self, order.deltaNeutralShortSale)
    sendInt(self, order.deltaNeutralShortSaleSlot)
    sendStr(self, order.deltaNeutralDesignatedLocation)
  end
  sendBool(self, order.continuousUpdate)
  sendMaxInt(self, order.referencePriceType)

  sendMaxDouble(self, order.trailStopPrice)

  sendMaxDouble(self, order.trailingPercent)

  sendMaxInt(self, order.scaleInitLevelSize)
  sendMaxInt(self, order.scaleSubsLevelSize)
  sendMaxDouble(self, order.scalePriceIncrement)

  if  order.scalePriceIncrement > 0.0 then
    if order.scalePriceIncrement ~= nil then
      sendMaxDouble(self,order.scalePriceAdjustValue)
      sendMaxInt(self,order.scalePriceAdjustInterval)
      sendMaxDouble(self,order.scaleProfitOffset)
      sendBool(self, order.scaleAutoReset)
      sendMaxInt(self,order.scaleInitPosition)
      sendMaxInt(self,order.scaleInitFillQty)
      sendBool(self, order.scaleRandomPercent)
    end
  end

  sendStr(self, order.scaleTable)
  sendStr(self, order.activeStartTime)
  sendStr(self, order.activeStopTime)

  sendStr(self, order.hedgeType)
  if order.hedgeType ~= nil or order.hedgeType ~= "" then
    sendStr(self, order.hedgeParam)
  end

  sendBool(self, order.optOutSmartRouting)

  sendStr(self, order.clearingAccount)
  sendStr(self, order.clearingIntent)

  sendBool(self, order.notHeld)

  if contract.underComp ~= nil then
    local underComp = contract.underComp
    sendBool(self, true)
    sendInt(self, underComp.conId)
    sendDouble(self, underComp.delta)
    sendDouble(self, underComp.price)
  else
    sendBool(self, false)
  end

  send(s, order.algoStrategy)
  if order.algoStrategy ~=nil then
    local algoParams = order.algoParams
    local algoParamsCount = 0
    if algoParams ~= nil then algoParamsCount = #algoParams end
    send(s, algoParamsCount)
    if  algoParamsCount > 0 then
      for i = 1, algoParamsCount do
        local tagValue = algoParams[i]
        sendStr(self, tagValue.tag)
        sendStr(self, tagValue.value)
      end
    end
  end

  sendBool(self, order.whatIf)

  --  send orderMiscOptions parameter
  sendStr(self,formatOptions(orderMiscOptions))
end

function ibapi:reqAccountUpdates(subscribe, acctCode)
  local VERSION = 2
  --  send cancel order msg
  sendInt(self, REQ_ACCOUNT_DATA )
  sendInt(self, VERSION)
  sendBool(self, subscribe)
  --  Send the account code. This will only be used for FA clients
  sendStr(self, acctCode)
end

function ibapi:reqExecutions(reqId, filter)
  local VERSION = 3
  sendInt(self, REQ_EXECUTIONS)
  sendInt(self, VERSION)

  sendInt(self, reqId)

  sendInt(self, filter.clientId)
  sendStr(self, filter.acctCode)

  --  Note that the valid format for m_time is "yyyymmdd-hh:mm:ss"
  sendStr(self, filter.time)
  sendStr(self, filter.symbol)
  sendStr(self, filter.secType)
  sendStr(self, filter.exchange)
  sendStr(self, filter.side)
end

function ibapi:cancelOrder(id)
  local VERSION = 1
  sendInt(self, CANCEL_ORDER)
  sendInt(self, VERSION)
  sendInt(self, id)
end

function ibapi:reqOpenOrders()
  local VERSION = 1
  sendInt(self, REQ_OPEN_ORDERS)
  sendInt(self, VERSION)
end

function ibapi:reqIds(numIds)
  local VERSION = 1
  sendInt(self, REQ_IDS)
  sendInt(self, VERSION)
  sendInt(self, numIds)
end

function ibapi:reqNewsBulletins(allMsgs)
  local VERSION = 1
  sendInt(self, REQ_NEWS_BULLETINS)
  sendInt(self, VERSION)
  sendBool(self, allMsgs)
end

function ibapi:cancelNewsBulletins()
  local VERSION = 1
  sendInt(self, CANCEL_NEWS_BULLETINS)
  sendInt(self, VERSION)
end

function ibapi:setServerLogLevel(logLevel)
  local VERSION = 1
  sendInt(self, SET_SERVER_LOGLEVEL)
  sendInt(self, VERSION)
  sendInt(self, logLevel)
end

function ibapi:reqAutoOpenOrders(bAutoBind)
  local VERSION = 1
  sendInt(self, REQ_AUTO_OPEN_ORDERS)
  sendInt(self, VERSION)
  sendBool(self, bAutoBind)
end

function ibapi:reqAllOpenOrders()
  local VERSION = 1
  sendInt(self, REQ_ALL_OPEN_ORDERS)
  sendInt(self, VERSION)
end

function ibapi:reqManagedAccts()
  local VERSION = 1
  sendInt(self, REQ_MANAGED_ACCTS)
  sendInt(self, VERSION)
end

function ibapi:requestFA(faDataType )
  local VERSION = 1
  sendInt(self, REQ_FA )
  sendInt(self, VERSION)
  sendInt(self, faDataType)
end

function ibapi:replaceFA(faDataType, xml)
  local VERSION = 1
  sendInt(self, REPLACE_FA )
  sendInt(self, VERSION)
  sendInt(self, faDataType)
  sendStr(self, xml)
end

function ibapi:reqCurrentTime()
  local VERSION = 1
  sendInt(self, REQ_CURRENT_TIME )
  sendInt(self, VERSION)
end

function ibapi:reqFundamentalData(reqId, contract, reportType)
  local VERSION = 2
  sendInt(self, REQ_FUNDAMENTAL_DATA)
  sendInt(self, VERSION)
  sendInt(self, reqId)

  sendInt(self,contract.conId)
  sendStr(self, contract.symbol)
  sendStr(self, contract.secType)
  sendStr(self, contract.exchange)
  sendStr(self, contract.primaryExch)
  sendStr(self, contract.currency)
  sendStr(self, contract.localSymbol)
  sendStr(self, reportType)
end

function ibapi:cancelFundamentalData(reqId)
  local VERSION = 1
  sendInt(self, CANCEL_FUNDAMENTAL_DATA)
  sendInt(self, VERSION)
  sendInt(self, reqId)
end

function ibapi:calculateImpliedVolatility(reqId, contract, optionPrice, underPrice)
  local VERSION = 2
  sendInt(self, REQ_CALC_IMPLIED_VOLAT)
  sendInt(self, VERSION)
  sendInt(self, reqId)
  sendContract(s, contract, true)

  sendDouble(self, optionPrice)
  sendDouble(self, underPrice)
end

function ibapi:cancelCalculateImpliedVolatility(reqId)
  local VERSION = 1
  sendInt(self, CANCEL_CALC_IMPLIED_VOLAT)
  sendInt(self, VERSION)
  sendInt(self, reqId)
end

function ibapi:calculateOptionPrice(reqId, contract, volatility, underPrice)
  local VERSION = 2
  sendInt(self, REQ_CALC_OPTION_PRICE)
  sendInt(self, VERSION)
  sendInt(self, reqId)
  sendContract(s, contract, true)

  sendDouble(self, volatility)
  sendDouble(self, underPrice)
end

function ibapi:cancelCalculateOptionPrice(reqId)
  local VERSION = 1
  sendInt(self, CANCEL_CALC_OPTION_PRICE)
  sendInt(self, VERSION)
  sendInt(self, reqId)
end

function ibapi:reqGlobalCancel()
  local VERSION = 1
  sendInt(self, REQ_GLOBAL_CANCEL)
  sendInt(self, VERSION)
end

function ibapi:reqMarketDataType(marketDataType)
  local VERSION = 1
  sendInt(self, REQ_MARKET_DATA_TYPE)
  sendInt(self, VERSION)
  sendInt(self, marketDataType)    
end

function ibapi:reqPositions()
  local VERSION = 1
  sendInt(self, REQ_POSITIONS)
  sendInt(self, VERSION)
end

function ibapi:cancelPositions()
  local VERSION = 1
  sendInt(self, CANCEL_POSITIONS)
  sendInt(self, VERSION)
end

function ibapi:reqAccountSummary(reqId,  group,  tags)
  local VERSION = 1
  sendInt(self, REQ_ACCOUNT_SUMMARY)
  sendInt(self, VERSION)
  sendInt(self, reqId)
  sendStr(self, group)
  sendStr(self, tags)
end

function ibapi:cancelAccountSummary(reqId)
  local VERSION = 1
  sendInt(self, CANCEL_ACCOUNT_SUMMARY)
  sendInt(self, VERSION)
  sendInt(self, reqId)
end

function ibapi:verifyRequest(apiName, apiVersion)
  local VERSION = 1
  sendInt(self, VERIFY_REQUEST)
  sendInt(self, VERSION)
  sendStr(self, apiName)
  sendStr(self, apiVersion)
end

function ibapi:verifyMessage(apiData)
  local VERSION = 1
  sendInt(self, VERIFY_MESSAGE)
  sendInt(self, VERSION)
  sendInt(self, apiData)
end

function ibapi:queryDisplayGroups(reqId)
  local VERSION = 1
  sendInt(self, QUERY_DISPLAY_GROUPS)
  sendInt(self, VERSION)
  sendInt(self, reqId)
end

function ibapi:subscribeToGroupEvents(reqId,  groupId)
  local VERSION = 1
  sendInt(self, SUBSCRIBE_TO_GROUP_EVENTS)
  sendInt(self, VERSION)
  sendInt(self, reqId)
  sendInt(self, groupId)
end   

function ibapi:updateDisplayGroup(reqId, contractInfo)
  local VERSION = 1
  sendInt(self, UPDATE_DISPLAY_GROUP)
  sendInt(self, VERSION)
  sendInt(self, reqId)
  sendStr(self, contractInfo)
end   

function ibapi:unsubscribeFromGroupEvents(reqId)
  local VERSION = 1
  sendInt(self, UNSUBSCRIBE_FROM_GROUP_EVENTS)
  sendInt(self, VERSION)
  sendInt(self, reqId)
end 


function ibapi:eConnect()
  self.fd = socket.open(self.host, self.port)
  if self.fd then
    driver.nodelay(self.fd, true)

    -- handshark
    sendInt(self, CLIENT_VERSION)
    self.serverVersion = readInt(self.fd)

    if (self.serverVersion >= 20) then
      self.TwsTime = readStr(self.fd)
    end

    if self.serverVersion < MIN_SERVER_VERSION then
      return false, EClientErrors.UPDATE_TWS
    end

    startAPI(self)

    self.connected = true

    -- fork tws message reader
    skynet.fork(processMsg, self)

    return true
  else
    return false
  end
end

function ibapi:eDisconnect()
  driver.close(self.fd)
  self.connected = false
end

function ibapi:new(conf, handler)
  local host = conf.host or "127.0.0.1"
  local port = conf.port or 7496
  local clientId = conf.clientId or 1

  local conn = { fd = 0, clientId = clientId, host = host, port = port, connected = false, handler = handler }
  setmetatable(conn, {__index = self})
  return conn
end

return ibapi
