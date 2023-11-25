local M = {}
string = require('stringutils')
local inspect = require('external.inspect')

-- utility functions
local function updateParserState(state, index, result)
    return {
        targetString = state['targetString'],
        index = index,
        result = result,
        isError = state['isError'],
        error = state['error'],
    }
end

local function updateParserError(state, errorMsg)
    return {
        targetString = state['targetString'],
        index = state['index'],
        result = state['result'],
        isError = true,
        error = errorMsg,
    }
end

local function updateParserResult(state, result)
    return {
        targetString = state['targetString'],
        index = state['index'],
        result = result,
        isError = state['isError'],
        error = state['error'],
    }
end

-- parser class
M.Parser = {
    parserStateTransformerFn = nil,
}

function M.Parser:new(parserStateTransformerFn)
    self.parserStateTransformerFn = parserStateTransformerFn
    return self
end

function M.Parser:run(targetString)
    local initialState = {
        targetString = targetString,
        index = 0,
        result = nil,
        isError = false,
        error = nil,
    }

    return self.parserStateTransformerFn(initialState)
end

function M.string(s)
    return M.Parser:new(function(parserState)
        local targetString = parserState['targetString']
        local index = parserState['index']
        local isError = parserState['isError']

        if isError then
            return parserState
        end

        local targetSliced = targetString:sub(index)
        if targetSliced:startswith(s) then
            return updateParserState(
                parserState,
                index + #s + 1,
                s
            )
        end

        return updateParserError(
            parserState,
            string.format(
                'STRING: tried to match [%s] but got [%s]',
                s,
                targetString:sub(index, index+10)
            )
        )
    end)
end

function M.sequenceOf(parsers)
    return M.Parser:new(function(parserState)
        local isError = parserState['isError']

        if isError then
            return parserState
        end

        local results = {}
        local nextState = parserState

        for i,v in ipairs(parsers)
        do
            nextState = v.parserStateTransformerFn(nextState)
            table.insert(results, i, nextState['result'])
        end

        return updateParserResult(nextState, results)
    end)
end

local parser = M.sequenceOf({
    M.string('hello'),
    M.string('world')
})

local targetString = 'helloworld'

print(
    inspect(parser:run(targetString))
)