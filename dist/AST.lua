local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./AST", { "./Localization", "./Pool", "./Profiler", "./Debug", "./Ovale", "./Lexer", "./Condition", "./Lexer", "./Scripts", "./SpellBook", "./Stance" }, function(__exports, __Localization, __Pool, __Profiler, __Debug, __Ovale, __Lexer, __Condition, __Lexer, __Scripts, __SpellBook, __Stance)
local OvaleASTBase = __Ovale.Ovale:NewModule("OvaleAST")
local format = string.format
local gsub = string.gsub
local _ipairs = ipairs
local _next = next
local _pairs = pairs
local _rawset = rawset
local _setmetatable = setmetatable
local strlower = string.lower
local strsub = string.sub
local tconcat = table.concat
local tinsert = table.insert
local _tonumber = tonumber
local _tostring = tostring
local tsort = table.sort
local _type = type
local _wipe = wipe
local API_GetItemInfo = GetItemInfo
local KEYWORD = {
    ["and"] = true,
    ["if"] = true,
    ["not"] = true,
    ["or"] = true,
    ["unless"] = true
}
local DECLARATION_KEYWORD = {
    ["AddActionIcon"] = true,
    ["AddCheckBox"] = true,
    ["AddFunction"] = true,
    ["AddIcon"] = true,
    ["AddListItem"] = true,
    ["Define"] = true,
    ["Include"] = true,
    ["ItemInfo"] = true,
    ["ItemRequire"] = true,
    ["ItemList"] = true,
    ["ScoreSpells"] = true,
    ["SpellInfo"] = true,
    ["SpellList"] = true,
    ["SpellRequire"] = true
}
local PARAMETER_KEYWORD = {
    ["checkbox"] = true,
    ["help"] = true,
    ["if_buff"] = true,
    ["if_equipped"] = true,
    ["if_spell"] = true,
    ["if_stance"] = true,
    ["if_target_debuff"] = true,
    ["itemcount"] = true,
    ["itemset"] = true,
    ["level"] = true,
    ["listitem"] = true,
    ["pertrait"] = true,
    ["specialization"] = true,
    ["talent"] = true,
    ["trait"] = true,
    ["text"] = true,
    ["wait"] = true
}
local SPELL_AURA_KEYWORD = {
    ["SpellAddBuff"] = true,
    ["SpellAddDebuff"] = true,
    ["SpellAddPetBuff"] = true,
    ["SpellAddPetDebuff"] = true,
    ["SpellAddTargetBuff"] = true,
    ["SpellAddTargetDebuff"] = true,
    ["SpellDamageBuff"] = true,
    ["SpellDamageDebuff"] = true
}
local STANCE_KEYWORD = {
    ["if_stance"] = true,
    ["stance"] = true,
    ["to_stance"] = true
}
do
    for keyword, value in _pairs(SPELL_AURA_KEYWORD) do
        DECLARATION_KEYWORD[keyword] = value
    end
    for keyword, value in _pairs(DECLARATION_KEYWORD) do
        KEYWORD[keyword] = value
    end
    for keyword, value in _pairs(PARAMETER_KEYWORD) do
        KEYWORD[keyword] = value
    end
end
local ACTION_PARAMETER_COUNT = {
    ["item"] = 1,
    ["macro"] = 1,
    ["spell"] = 1,
    ["texture"] = 1,
    ["setstate"] = 2
}
local STATE_ACTION = {
    ["setstate"] = true
}
local STRING_LOOKUP_FUNCTION = {
    ["ItemName"] = true,
    ["L"] = true,
    ["SpellName"] = true
}
local UNARY_OPERATOR = {
    ["not"] = {
        [1] = "logical",
        [2] = 15
    },
    ["-"] = {
        [1] = "arithmetic",
        [2] = 50
    }
}
local BINARY_OPERATOR = {
    ["or"] = {
        [1] = "logical",
        [2] = 5,
        [3] = "associative"
    },
    ["xor"] = {
        [1] = "logical",
        [2] = 8,
        [3] = "associative"
    },
    ["and"] = {
        [1] = "logical",
        [2] = 10,
        [3] = "associative"
    },
    ["!="] = {
        [1] = "compare",
        [2] = 20
    },
    ["<"] = {
        [1] = "compare",
        [2] = 20
    },
    ["<="] = {
        [1] = "compare",
        [2] = 20
    },
    ["=="] = {
        [1] = "compare",
        [2] = 20
    },
    [">"] = {
        [1] = "compare",
        [2] = 20
    },
    [">="] = {
        [1] = "compare",
        [2] = 20
    },
    ["+"] = {
        [1] = "arithmetic",
        [2] = 30,
        [3] = "associative"
    },
    ["-"] = {
        [1] = "arithmetic",
        [2] = 30
    },
    ["%"] = {
        [1] = "arithmetic",
        [2] = 40
    },
    ["*"] = {
        [1] = "arithmetic",
        [2] = 40,
        [3] = "associative"
    },
    ["/"] = {
        [1] = "arithmetic",
        [2] = 40
    },
    ["^"] = {
        [1] = "arithmetic",
        [2] = 100
    }
}
local indent = {}
indent[0] = ""
local INDENT = function(key)
    local ret = indent[key]
    if ret == nil then
        ret = INDENT(key - 1)
        indent[key] = ret
    end
    return ret
end
local TokenizeComment = function(token)
    return "comment", token
end

local TokenizeLua = function(token)
    token = strsub(token, 3, -3)
    return "lua", token
end

local TokenizeName = function(token)
    if KEYWORD[token] then
        return "keyword", token
    else
        return "name", token
    end
end

local TokenizeNumber = function(token)
    return "number", token
end

local TokenizeString = function(token)
    token = strsub(token, 2, -2)
    return "string", token
end

local TokenizeWhitespace = function(token)
    return "space", token
end

local Tokenize = function(token)
    return token, token
end

local NoToken = function()
    return nil
end

local MATCHES = {
    [1] = {
        [1] = "^%s+",
        [2] = TokenizeWhitespace
    },
    [2] = {
        [1] = "^%d+%.?%d*",
        [2] = TokenizeNumber
    },
    [3] = {
        [1] = "^[%a_][%w_]*",
        [2] = TokenizeName
    },
    [4] = {
        [1] = "^((['\"])%2)",
        [2] = TokenizeString
    },
    [5] = {
        [1] = [[^(['"]).-\%1]],
        [2] = TokenizeString
    },
    [6] = {
        [1] = [[^(['"]).-[^]%1]],
        [2] = TokenizeString
    },
    [7] = {
        [1] = "^#.-\n",
        [2] = TokenizeComment
    },
    [8] = {
        [1] = "^!=",
        [2] = Tokenize
    },
    [9] = {
        [1] = "^==",
        [2] = Tokenize
    },
    [10] = {
        [1] = "^<=",
        [2] = Tokenize
    },
    [11] = {
        [1] = "^>=",
        [2] = Tokenize
    },
    [12] = {
        [1] = "^.",
        [2] = Tokenize
    },
    [13] = {
        [1] = "^$",
        [2] = NoToken
    }
}
local FILTERS = {
    comments = TokenizeComment,
    space = TokenizeWhitespace
}
local SelfPool = __class(__Pool.OvalePool, {
    constructor = function(self, ovaleAst)
        __Pool.OvalePool.constructor(self, "OvaleAST_pool")
    end,
    Clean = function(self, node)
        if node.child then
            self.ovaleAst.self_childrenPool:Release(node.child)
            node.child = nil
        end
        if node.postOrder then
            self.ovaleAst.self_postOrderPool:Release(node.postOrder)
            node.postOrder = nil
        end
    end,
})
local OvaleASTClass = __class(__Debug.OvaleDebug:RegisterDebugging(__Profiler.OvaleProfiler:RegisterProfiling(OvaleASTBase)), {
    constructor = function(self)
        self.self_indent = 0
        self.self_outputPool = __Pool.OvalePool("OvaleAST_outputPool")
        self.self_controlPool = __Pool.OvalePool("OvaleAST_controlPool")
        self.self_parametersPool = __Pool.OvalePool("OvaleAST_parametersPool")
        self.self_childrenPool = __Pool.OvalePool("OvaleAST_childrenPool")
        self.self_postOrderPool = __Pool.OvalePool("OvaleAST_postOrderPool")
        self.postOrderVisitedPool = __Pool.OvalePool("OvaleAST_postOrderVisitedPool")
        self.self_pool = SelfPool(self)
        self.PARAMETER_KEYWORD = PARAMETER_KEYWORD
        self.UnparseAddCheckBox = function(node)
                local s
                if node.rawPositionalParams and _next(node.rawPositionalParams) or node.rawNamedParams and _next(node.rawNamedParams) then
                    s = format("AddCheckBox(%s %s %s)", node.name, self:Unparse(node.description), self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
                else
                    s = format("AddCheckBox(%s %s)", node.name, self:Unparse(node.description))
                end
                return s
            end

        self.UnparseAddFunction = function(node)
                local s
                if self:HasParameters(node) then
                    s = format("AddFunction %s %s%s", node.name, self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams), self:UnparseGroup(node.child[1]))
                else
                    s = format("AddFunction %s%s", node.name, self:UnparseGroup(node.child[1]))
                end
                return s
            end

        self.UnparseAddIcon = function(node)
                local s
                if self:HasParameters(node) then
                    s = format("AddIcon %s%s", self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams), self:UnparseGroup(node.child[1]))
                else
                    s = format("AddIcon%s", self:UnparseGroup(node.child[1]))
                end
                return s
            end

        self.UnparseAddListItem = function(node)
                local s
                if self:HasParameters(node) then
                    s = format("AddListItem(%s %s %s %s)", node.name, node.item, self:Unparse(node.description), self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
                else
                    s = format("AddListItem(%s %s %s)", node.name, node.item, self:Unparse(node.description))
                end
                return s
            end

        self.UnparseBangValue = function(node)
                return self:Unparse(node.child[1])
            end

        self.UnparseComment = function(node)
                if  not node.comment or node.comment == "" then
                    return ""
                else
                    return node.comment
                end
            end

        self.UnparseCommaSeparatedValues = function(node)
                local output = self.self_outputPool:Get()
                for k, v in _ipairs(node.csv) do
                    output[k] = self:Unparse(v)
                end
                local outputString = tconcat(output, ",")
                self.self_outputPool:Release(output)
                return outputString
            end

        self.UnparseDefine = function(node)
                return format("Define(%s %s)", node.name, node.value)
            end

        self.UnparseExpression = function(node)
                local expression
                local precedence = self:GetPrecedence(node)
                if node.expressionType == "unary" then
                    local rhsExpression
                    local rhsNode = node.child[1]
                    local rhsPrecedence = self:GetPrecedence(rhsNode)
                    if rhsPrecedence and precedence >= rhsPrecedence then
                        rhsExpression = self:Unparse(rhsNode)
                    else
                        rhsExpression = self:Unparse(rhsNode)
                    end
                    if node.operator == "-" then
                        expression = rhsExpression
                    else
                        expression = node.operator .. rhsExpression
                    end
                elseif node.expressionType == "binary" then
                    local lhsExpression, rhsExpression
                    local lhsNode = node.child[1]
                    local lhsPrecedence = self:GetPrecedence(lhsNode)
                    if lhsPrecedence and lhsPrecedence < precedence then
                        lhsExpression = self:Unparse(lhsNode)
                    else
                        lhsExpression = self:Unparse(lhsNode)
                    end
                    local rhsNode = node.child[2]
                    local rhsPrecedence = self:GetPrecedence(rhsNode)
                    if rhsPrecedence and precedence > rhsPrecedence then
                        rhsExpression = self:Unparse(rhsNode)
                    elseif rhsPrecedence and precedence == rhsPrecedence then
                        if BINARY_OPERATOR[node.operator][3] == "associative" and node.operator == rhsNode.operator then
                            rhsExpression = self:Unparse(rhsNode)
                        else
                            rhsExpression = self:Unparse(rhsNode)
                        end
                    else
                        rhsExpression = self:Unparse(rhsNode)
                    end
                    expression = lhsExpression .. node.operator .. rhsExpression
                end
                return expression
            end

        self.UnparseIf = function(node)
                if node.child[2].type == "group" then
                    return format("if %s%s", self:Unparse(node.child[1]), self:UnparseGroup(node.child[2]))
                else
                    return format("if %s %s", self:Unparse(node.child[1]), self:Unparse(node.child[2]))
                end
            end

        self.UnparseItemInfo = function(node)
                local identifier = node.name and node.name or node.itemId
                return format("ItemInfo(%s %s)", identifier, self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
            end

        self.UnparseItemRequire = function(node)
                local identifier = node.name and node.name or node.itemId
                return format("ItemRequire(%s %s %s)", identifier, node.property, self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
            end

        self.UnparseList = function(node)
                return format("%s(%s %s)", node.keyword, node.name, self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
            end

        self.UnparseNumber = function(node)
                return _tostring(node.value)
            end

        self.UnparseParameters = function(positionalParams, namedParams)
                local output = self.self_outputPool:Get()
                for k, v in _pairs(namedParams) do
                    if k == "checkbox" then
                        for _, name in _ipairs(v) do
                            output[#output + 1] = format("checkbox=%s", self:Unparse(name))
                        end
                    elseif k == "listitem" then
                        for list, item in _pairs(v) do
                            output[#output + 1] = format("listitem=%s:%s", list, self:Unparse(item))
                        end
                    elseif _type(v) == "table" then
                        output[#output + 1] = format("%s=%s", k, self:Unparse(v))
                    elseif k == "filter" or k == "target" then
                    else
                        output[#output + 1] = format("%s=%s", k, v)
                    end
                end
                tsort(output)
                for k = #positionalParams, 1, -1 do
                    tinsert(output, 1, self:Unparse(positionalParams[k]))
                end
                local outputString = tconcat(output, " ")
                self.self_outputPool:Release(output)
                return outputString
            end

        self.UnparseScoreSpells = function(node)
                return format("ScoreSpells(%s)", self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
            end

        self.UnparseScript = function(node)
                local output = self.self_outputPool:Get()
                local previousDeclarationType
                for _, declarationNode in _ipairs(node.child) do
                    if declarationNode.type == "item_info" or declarationNode.type == "spell_aura_list" or declarationNode.type == "spell_info" or declarationNode.type == "spell_require" then
                        local s = self:Unparse(declarationNode)
                        if s == "" then
                            output[#output + 1] = s
                        else
                            output[#output + 1] = INDENT(self.self_indent + 1) .. s
                        end
                    else
                        local insertBlank = false
                        if previousDeclarationType and previousDeclarationType ~= declarationNode.type then
                            insertBlank = true
                        end
                        if declarationNode.type == "add_function" or declarationNode.type == "icon" then
                            insertBlank = true
                        end
                        if insertBlank then
                            output[#output + 1] = ""
                        end
                        output[#output + 1] = self:Unparse(declarationNode)
                        previousDeclarationType = declarationNode.type
                    end
                end
                local outputString = tconcat(output, "\n")
                self.self_outputPool:Release(output)
                return outputString
            end

        self.UnparseSpellAuraList = function(node)
                local identifier = node.name and node.name or node.spellId
                return format("%s(%s %s)", node.keyword, identifier, self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
            end

        self.UnparseSpellInfo = function(node)
                local identifier = node.name and node.name or node.spellId
                return format("SpellInfo(%s %s)", identifier, self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
            end

        self.UnparseSpellRequire = function(node)
                local identifier = node.name and node.name or node.spellId
                return format("SpellRequire(%s %s %s)", identifier, node.property, self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
            end

        self.UNPARSE_VISITOR = {
                ["action"] = self.UnparseFunction,
                ["add_function"] = self.UnparseAddFunction,
                ["arithmetic"] = self.UnparseExpression,
                ["bang_value"] = self.UnparseBangValue,
                ["checkbox"] = self.UnparseAddCheckBox,
                ["compare"] = self.UnparseExpression,
                ["comma_separated_values"] = self.UnparseCommaSeparatedValues,
                ["comment"] = self.UnparseComment,
                ["custom_function"] = self.UnparseFunction,
                ["define"] = self.UnparseDefine,
                ["function"] = self.UnparseFunction,
                ["group"] = self.UnparseGroup,
                ["icon"] = self.UnparseAddIcon,
                ["if"] = self.UnparseIf,
                ["item_info"] = self.UnparseItemInfo,
                ["item_require"] = self.UnparseItemRequire,
                ["list"] = self.UnparseList,
                ["list_item"] = self.UnparseAddListItem,
                ["logical"] = self.UnparseExpression,
                ["score_spells"] = self.UnparseScoreSpells,
                ["script"] = self.UnparseScript,
                ["spell_aura_list"] = self.UnparseSpellAuraList,
                ["spell_info"] = self.UnparseSpellInfo,
                ["spell_require"] = self.UnparseSpellRequire,
                ["state"] = self.UnparseFunction,
                ["string"] = self.UnparseString,
                ["unless"] = self.UnparseUnless,
                ["value"] = self.UnparseNumber,
                ["variable"] = self.UnparseVariable
            }
        self.ParseIf = function(tokenStream, nodeList, annotation)
                local ok = true
                do
                    local tokenType, token = tokenStream:Consume()
                    if  not (tokenType == "keyword" and token == "if") then
                        self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing IF; 'if' expected.", token)
                        ok = false
                    end
                end
                local conditionNode, bodyNode
                if ok then
                    ok, conditionNode = self:ParseExpression(tokenStream, nodeList, annotation)
                end
                if ok then
                    ok, bodyNode = self:ParseStatement(tokenStream, nodeList, annotation)
                end
                local node
                if ok then
                    node = self:NewNode(nodeList, true)
                    node.type = "if"
                    node.child[1] = conditionNode
                    node.child[2] = bodyNode
                end
                return ok, node
            end

        self.ParseItemInfo = function(tokenStream, nodeList, annotation)
                local ok = true
                local name, lowername
                do
                    local tokenType, token = tokenStream:Consume()
                    if  not (tokenType == "keyword" and token == "ItemInfo") then
                        self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMINFO; 'ItemInfo' expected.", token)
                        ok = false
                    end
                end
                if ok then
                    local tokenType, token = tokenStream:Consume()
                    if tokenType ~= "(" then
                        self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMINFO; '(' expected.", token)
                        ok = false
                    end
                end
                local itemId
                if ok then
                    local tokenType, token = tokenStream:Consume()
                    if tokenType == "number" then
                        itemId = token
                    elseif tokenType == "name" then
                        name = token
                    else
                        self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMINFO; number or name expected.", token)
                        ok = false
                    end
                end
                local positionalParams, namedParams
                if ok then
                    ok, positionalParams, namedParams = self:ParseParameters(tokenStream, nodeList, annotation)
                end
                if ok then
                    local tokenType, token = tokenStream:Consume()
                    if tokenType ~= ")" then
                        self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMINFO; ')' expected.", token)
                        ok = false
                    end
                end
                local node
                if ok then
                    node = self:NewNode(nodeList)
                    node.type = "item_info"
                    node.itemId = itemId
                    node.name = name
                    node.rawPositionalParams = positionalParams
                    node.rawNamedParams = namedParams
                    annotation.parametersReference = annotation.parametersReference or {}
                    annotation.parametersReference[#annotation.parametersReference + 1] = node
                    if name then
                        annotation.nameReference = annotation.nameReference or {}
                        annotation.nameReference[#annotation.nameReference + 1] = node
                    end
                end
                return ok, node
            end

        self.ParseParameters = function(tokenStream, nodeList, annotation, isList)
                local ok = true
                local positionalParams = self.self_parametersPool:Get()
                local namedParams = self.self_parametersPool:Get()
                while ok do
                    local tokenType, token = tokenStream:Peek()
                    if tokenType then
                        local name, node
                        if tokenType == "name" then
                            ok, node = self:ParseVariable(tokenStream, nodeList, annotation)
                            if ok then
                                name = node.name
                            end
                        elseif tokenType == "number" then
                            ok, node = self:ParseNumber(tokenStream, nodeList, annotation)
                            if ok then
                                name = node.value
                            end
                        elseif tokenType == "-" then
                            tokenStream:Consume()
                            ok, node = self:ParseNumber(tokenStream, nodeList, annotation)
                            if ok then
                                local value = -1 * node.value
                                node = self:GetNumberNode(value, nodeList, annotation)
                                name = value
                            end
                        elseif tokenType == "string" then
                            ok, node = self:ParseString(tokenStream, nodeList, annotation)
                            if ok then
                                name = node.value
                            end
                        elseif PARAMETER_KEYWORD[token] then
                            if isList then
                                self:SyntaxError(tokenStream, "Syntax error: unexpected keyword '%s' when parsing PARAMETERS; simple expression expected.", token)
                                ok = false
                            else
                                tokenStream:Consume()
                                name = token
                            end
                        else
                            break
                        end
                        if ok and name then
                            tokenType, token = tokenStream:Peek()
                            if tokenType == "=" then
                                tokenStream:Consume()
                                if name == "checkbox" or name == "listitem" then
                                    local control = namedParams[name] or self.self_controlPool:Get()
                                    if name == "checkbox" then
                                        ok, node = self:ParseSimpleParameterValue(tokenStream, nodeList, annotation)
                                        if ok and node then
                                            if  not (node.type == "variable" or (node.type == "bang_value" and node.child[1].type == "variable")) then
                                                self:SyntaxError(tokenStream, "Syntax error: 'checkbox' parameter with unexpected value '%s'.", self:Unparse(node))
                                                ok = false
                                            end
                                        end
                                        if ok then
                                            control[#control + 1] = node
                                        end
                                    else
                                        tokenType, token = tokenStream:Consume()
                                        local list
                                        if tokenType == "name" then
                                            list = token
                                        else
                                            self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARAMETERS; name expected.", token)
                                            ok = false
                                        end
                                        if ok then
                                            tokenType, token = tokenStream:Consume()
                                            if tokenType ~= ":" then
                                                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARAMETERS; ':' expected.", token)
                                                ok = false
                                            end
                                        end
                                        if ok then
                                            ok, node = self:ParseSimpleParameterValue(tokenStream, nodeList, annotation)
                                        end
                                        if ok and node then
                                            if  not (node.type == "variable" or (node.type == "bang_value" and node.child[1].type == "variable")) then
                                                self:SyntaxError(tokenStream, "Syntax error: 'listitem=%s' parameter with unexpected value '%s'.", self:Unparse(node))
                                                ok = false
                                            end
                                        end
                                        if ok then
                                            control[list] = node
                                        end
                                    end
                                    if  not namedParams[name] then
                                        namedParams[name] = control
                                        annotation.controlList = annotation.controlList or {}
                                        annotation.controlList[#annotation.controlList + 1] = control
                                    end
                                else
                                    ok, node = self:ParseParameterValue(tokenStream, nodeList, annotation)
                                    namedParams[name] = node
                                end
                            else
                                positionalParams[#positionalParams + 1] = node
                            end
                        end
                    else
                        break
                    end
                end
                if ok then
                    annotation.parametersList = annotation.parametersList or {}
                    annotation.parametersList[#annotation.parametersList + 1] = positionalParams
                    annotation.parametersList[#annotation.parametersList + 1] = namedParams
                else
                    positionalParams = nil
                    namedParams = nil
                end
                return ok, positionalParams, namedParams
            end

        self.ParseParentheses = function(tokenStream, nodeList, annotation)
                local ok = true
                local leftToken, rightToken
                do
                    local tokenType, token = tokenStream:Consume()
                    if tokenType == "(" then
                        leftToken, rightToken = "(", ")"
                    elseif tokenType == "{" then
                        leftToken, rightToken = "{", "}"
                    else
                        self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARENTHESES; '(' or '{' expected.", token)
                        ok = false
                    end
                end
                local node
                if ok then
                    ok, node = self:ParseExpression(tokenStream, nodeList, annotation)
                end
                if ok then
                    local tokenType, token = tokenStream:Consume()
                    if tokenType ~= rightToken then
                        self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARENTHESES; '%s' expected.", token, rightToken)
                        ok = false
                    end
                end
                if ok then
                    node.left = leftToken
                    node.right = rightToken
                end
                return ok, node
            end

        self.ParseScoreSpells = function(tokenStream, nodeList, annotation)
                local ok = true
                do
                    local tokenType, token = tokenStream:Consume()
                    if  not (tokenType == "keyword" and token == "ScoreSpells") then
                        self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SCORESPELLS; 'ScoreSpells' expected.", token)
                        ok = false
                    end
                end
                if ok then
                    local tokenType, token = tokenStream:Consume()
                    if tokenType ~= "(" then
                        self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SCORESPELLS; '(' expected.", token)
                        ok = false
                    end
                end
                local positionalParams, namedParams
                if ok then
                    ok, positionalParams, namedParams = self:ParseParameters(tokenStream, nodeList, annotation)
                end
                if ok then
                    local tokenType, token = tokenStream:Consume()
                    if tokenType ~= ")" then
                        self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SCORESPELLS; ')' expected.", token)
                        ok = false
                    end
                end
                local node
                if ok then
                    node = self:NewNode(nodeList)
                    node.type = "score_spells"
                    node.rawPositionalParams = positionalParams
                    node.rawNamedParams = namedParams
                    annotation.parametersReference = annotation.parametersReference or {}
                    annotation.parametersReference[#annotation.parametersReference + 1] = node
                end
                return ok, node
            end

        self.PARSE_VISITOR = {
                ["action"] = self.ParseFunction,
                ["add_function"] = self.ParseAddFunction,
                ["arithmetic"] = self.ParseExpression,
                ["bang_value"] = self.ParseSimpleParameterValue,
                ["checkbox"] = self.ParseAddCheckBox,
                ["compare"] = self.ParseExpression,
                ["comment"] = self.ParseComment,
                ["custom_function"] = self.ParseFunction,
                ["define"] = self.ParseDefine,
                ["expression"] = self.ParseExpression,
                ["function"] = self.ParseFunction,
                ["group"] = self.ParseGroup,
                ["icon"] = self.ParseAddIcon,
                ["if"] = self.ParseIf,
                ["item_info"] = self.ParseItemInfo,
                ["item_require"] = self.ParseItemRequire,
                ["list"] = self.ParseList,
                ["list_item"] = self.ParseAddListItem,
                ["logical"] = self.ParseExpression,
                ["score_spells"] = self.ParseScoreSpells,
                ["script"] = self.ParseScript,
                ["spell_aura_list"] = self.ParseSpellAuraList,
                ["spell_info"] = self.ParseSpellInfo,
                ["spell_require"] = self.ParseSpellRequire,
                ["string"] = self.ParseString,
                ["unless"] = self.ParseUnless,
                ["value"] = self.ParseNumber,
                ["variable"] = self.ParseVariable
            }
        __Debug.OvaleDebug:RegisterDebugging(__Profiler.OvaleProfiler:RegisterProfiling(OvaleASTBase)).constructor(self)
    end,
    print_r = function(self, node, indent, done, output)
        done = done or {}
        output = output or {}
        indent = indent or ""
        for key, value in _pairs(node) do
            if _type(value) == "table" then
                if done[value] then
                    tinsert(output, indent .. _tostring(key))
                else
                    done[value] = true
                    if value.type then
                        tinsert(output, indent .. _tostring(key))
                    else
                        tinsert(output, indent .. _tostring(key))
                    end
                    self:print_r(value, indent, done, output)
                    if  not value.type then
                        tinsert(output, indent)
                    end
                end
            else
                tinsert(output, indent .. _tostring(key) .. _tostring(value))
            end
        end
        return output
    end,
    GetNumberNode = function(self, value, nodeList, annotation)
        annotation.numberFlyweight = annotation.numberFlyweight or {}
        local node = annotation.numberFlyweight[value]
        if  not node then
            node = self:NewNode(nodeList)
            node.type = "value"
            node.value = value
            node.origin = 0
            node.rate = 0
            annotation.numberFlyweight[value] = node
        end
        return node
    end,
    PostOrderTraversal = function(self, node, array, visited)
        if node.child then
            for _, childNode in _ipairs(node.child) do
                if  not visited[childNode.nodeId] then
                    self:PostOrderTraversal(childNode, array, visited)
                    array[#array + 1] = node
                end
            end
        end
        array[#array + 1] = node
        visited[node.nodeId] = true
    end,
    FlattenParameterValue = function(self, parameterValue, annotation)
        local value = parameterValue
        if _type(parameterValue) == "table" then
            local node = parameterValue
            if node.type == "comma_separated_values" then
                value = self.self_parametersPool:Get()
                for k, v in _ipairs(node.csv) do
                    value[k] = self:FlattenParameterValue(v, annotation)
                end
                annotation.parametersList = annotation.parametersList or {}
                annotation.parametersList[#annotation.parametersList + 1] = value
            else
                local isBang = false
                if node.type == "bang_value" then
                    isBang = true
                    node = node.child[1]
                end
                if node.type == "value" then
                    value = node.value
                elseif node.type == "variable" then
                    value = node.name
                elseif node.type == "string" then
                    value = node.value
                end
                if isBang then
                    value = _tostring(value)
                end
            end
        end
        return value
    end,
    GetPrecedence = function(self, node)
        local precedence = node.precedence
        if  not precedence then
            local operator = node.operator
            if operator then
                if node.expressionType == "unary" and UNARY_OPERATOR[operator] then
                    precedence = UNARY_OPERATOR[operator][2]
                elseif node.expressionType == "binary" and BINARY_OPERATOR[operator] then
                    precedence = BINARY_OPERATOR[operator][2]
                end
            end
        end
        return precedence
    end,
    HasParameters = function(self, node)
        return node.rawPositionalParams and _next(node.rawPositionalParams) or node.rawNamedParams and _next(node.rawNamedParams)
    end,
    Unparse = function(self, node)
        if node.asString then
            return node.asString
        else
            local visitor
            if node.previousType then
                visitor = self.UNPARSE_VISITOR[node.previousType]
            else
                visitor = self.UNPARSE_VISITOR[node.type]
            end
            if  not visitor then
                self:Error("Unable to unparse node of type '%s'.", node.type)
            else
                return visitor(node)
            end
        end
    end,
    UnparseFunction = function(self, node)
        local s
        if self:HasParameters(node) then
            local name
            local filter = node.rawNamedParams.filter
            if filter == "debuff" then
                name = gsub(node.name, "^Buff", "Debuff")
            else
                name = node.name
            end
            local target = node.rawNamedParams.target
            if target then
                s = format("%s.%s(%s)", target, name, self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
            else
                s = format("%s(%s)", name, self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
            end
        else
            s = format("%s()", node.name)
        end
        return s
    end,
    UnparseGroup = function(self, node)
        local output = self.self_outputPool:Get()
        output[#output + 1] = ""
        output[#output + 1] = INDENT(self.self_indent)
        self.self_indent = self.self_indent + 1
        for _, statementNode in _ipairs(node.child) do
            local s = self:Unparse(statementNode)
            if s == "" then
                output[#output + 1] = s
            else
                output[#output + 1] = INDENT(self.self_indent) .. s
            end
        end
        self.self_indent = self.self_indent - 1
        output[#output + 1] = INDENT(self.self_indent)
        local outputString = tconcat(output, "\n")
        self.self_outputPool:Release(output)
        return outputString
    end,
    UnparseString = function(self, node)
        return node.value
    end,
    UnparseUnless = function(self, node)
        if node.child[2].type == "group" then
            return format("unless %s%s", self:Unparse(node.child[1]), self:UnparseGroup(node.child[2]))
        else
            return format("unless %s %s", self:Unparse(node.child[1]), self:Unparse(node.child[2]))
        end
    end,
    UnparseVariable = function(self, node)
        return node.name
    end,
    SyntaxError = function(self, tokenStream, ...)
        self:Print(...)
        local context = {
            [1] = "Next tokens:"
        }
        for i = 1, 20, 1 do
            local tokenType, token = tokenStream:Peek(i)
            if tokenType then
                context[#context + 1] = token
            else
                context[#context + 1] = "<EOS>"
                break
            end
        end
        self:Print(tconcat(context, " "))
    end,
    Parse = function(self, nodeType, tokenStream, nodeList, annotation)
        local visitor = self.PARSE_VISITOR[nodeType]
        if  not visitor then
            self:Error("Unable to parse node of type '%s'.", nodeType)
        else
            return visitor(tokenStream, nodeList, annotation)
        end
    end,
    ParseAddCheckBox = function(self, tokenStream, nodeList, annotation)
        local ok = true
        do
            local tokenType, token = tokenStream:Consume()
            if  not (tokenType == "keyword" and token == "AddCheckBox") then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; 'AddCheckBox' expected.", token)
                ok = false
            end
        end
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= "(" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; '(' expected.", token)
                ok = false
            end
        end
        local name
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType == "name" then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; name expected.", token)
                ok = false
            end
        end
        local descriptionNode
        if ok then
            ok, descriptionNode = self:ParseString(tokenStream, nodeList, annotation)
        end
        local parameters
        local positionalParams, namedParams
        if ok then
            ok, positionalParams, namedParams = self:ParseParameters(tokenStream, nodeList, annotation)
        end
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; ')' expected.", token)
                ok = false
            end
        end
        local node
        if ok then
            node = self:NewNode(nodeList)
            node.type = "checkbox"
            node.name = name
            node.description = descriptionNode
            node.rawPositionalParams = positionalParams
            node.rawNamedParams = namedParams
            annotation.parametersReference = annotation.parametersReference or {}
            annotation.parametersReference[#annotation.parametersReference + 1] = node
        end
        return ok, node
    end,
    ParseAddFunction = function(self, tokenStream, nodeList, annotation)
        local ok = true
        local tokenType, token = tokenStream:Consume()
        if  not (tokenType == "keyword" and token == "AddFunction") then
            self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDFUNCTION; 'AddFunction' expected.", token)
            ok = false
        end
        local name
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType == "name" then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDFUNCTION; name expected.", token)
                ok = false
            end
        end
        local positionalParams, namedParams
        if ok then
            ok, positionalParams, namedParams = self:ParseParameters(tokenStream, nodeList, annotation)
        end
        local bodyNode
        if ok then
            ok, bodyNode = self:ParseGroup(tokenStream, nodeList, annotation)
        end
        local node
        if ok then
            node = self:NewNode(nodeList, true)
            node.type = "add_function"
            node.name = name
            node.child[1] = bodyNode
            node.rawPositionalParams = positionalParams
            node.rawNamedParams = namedParams
            annotation.parametersReference = annotation.parametersReference or {}
            annotation.parametersReference[#annotation.parametersReference + 1] = node
            annotation.postOrderReference = annotation.postOrderReference or {}
            annotation.postOrderReference[#annotation.postOrderReference + 1] = bodyNode
            annotation.customFunction = annotation.customFunction or {}
            annotation.customFunction[name] = node
        end
        return ok, node
    end,
    ParseAddIcon = function(self, tokenStream, nodeList, annotation)
        local ok = true
        local tokenType, token = tokenStream:Consume()
        if  not (tokenType == "keyword" and token == "AddIcon") then
            self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDICON; 'AddIcon' expected.", token)
            ok = false
        end
        local positionalParams, namedParams
        if ok then
            ok, positionalParams, namedParams = self:ParseParameters(tokenStream, nodeList, annotation)
        end
        local bodyNode
        if ok then
            ok, bodyNode = self:ParseGroup(tokenStream, nodeList, annotation)
        end
        local node
        if ok then
            node = self:NewNode(nodeList, true)
            node.type = "icon"
            node.child[1] = bodyNode
            node.rawPositionalParams = positionalParams
            node.rawNamedParams = namedParams
            annotation.parametersReference = annotation.parametersReference or {}
            annotation.parametersReference[#annotation.parametersReference + 1] = node
            annotation.postOrderReference = annotation.postOrderReference or {}
            annotation.postOrderReference[#annotation.postOrderReference + 1] = bodyNode
        end
        return ok, node
    end,
    ParseAddListItem = function(self, tokenStream, nodeList, annotation)
        local ok = true
        do
            local tokenType, token = tokenStream:Consume()
            if  not (tokenType == "keyword" and token == "AddListItem") then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; 'AddListItem' expected.", token)
                ok = false
            end
        end
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= "(" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; '(' expected.", token)
                ok = false
            end
        end
        local name
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType == "name" then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; name expected.", token)
                ok = false
            end
        end
        local item
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType == "name" then
                item = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; name expected.", token)
                ok = false
            end
        end
        local descriptionNode
        if ok then
            ok, descriptionNode = self:ParseString(tokenStream, nodeList, annotation)
        end
        local positionalParams, namedParams
        if ok then
            ok, positionalParams, namedParams = self:ParseParameters(tokenStream, nodeList, annotation)
        end
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; ')' expected.", token)
                ok = false
            end
        end
        local node
        if ok then
            node = self:NewNode(nodeList)
            node.type = "list_item"
            node.name = name
            node.item = item
            node.description = descriptionNode
            node.rawPositionalParams = positionalParams
            node.rawNamedParams = namedParams
            annotation.parametersReference = annotation.parametersReference or {}
            annotation.parametersReference[#annotation.parametersReference + 1] = node
        end
        return ok, node
    end,
    ParseComment = function(self, tokenStream, nodeList, annotation)
        return nil
    end,
    ParseDeclaration = function(self, tokenStream, nodeList, annotation)
        local ok = true
        local node
        local tokenType, token = tokenStream:Peek()
        if tokenType == "keyword" and DECLARATION_KEYWORD[token] then
            if token == "AddCheckBox" then
                ok, node = self:ParseAddCheckBox(tokenStream, nodeList, annotation)
            elseif token == "AddFunction" then
                ok, node = self:ParseAddFunction(tokenStream, nodeList, annotation)
            elseif token == "AddIcon" then
                ok, node = self:ParseAddIcon(tokenStream, nodeList, annotation)
            elseif token == "AddListItem" then
                ok, node = self:ParseAddListItem(tokenStream, nodeList, annotation)
            elseif token == "Define" then
                ok, node = self:ParseDefine(tokenStream, nodeList, annotation)
            elseif token == "Include" then
                ok, node = self:ParseInclude(tokenStream, nodeList, annotation)
            elseif token == "ItemInfo" then
                ok, node = self:ParseItemInfo(tokenStream, nodeList, annotation)
            elseif token == "ItemRequire" then
                ok, node = self:ParseItemRequire(tokenStream, nodeList, annotation)
            elseif token == "ItemList" then
                ok, node = self:ParseList(tokenStream, nodeList, annotation)
            elseif token == "ScoreSpells" then
                ok, node = self:ParseScoreSpells(tokenStream, nodeList, annotation)
            elseif SPELL_AURA_KEYWORD[token] then
                ok, node = self:ParseSpellAuraList(tokenStream, nodeList, annotation)
            elseif token == "SpellInfo" then
                ok, node = self:ParseSpellInfo(tokenStream, nodeList, annotation)
            elseif token == "SpellList" then
                ok, node = self:ParseList(tokenStream, nodeList, annotation)
            elseif token == "SpellRequire" then
                ok, node = self:ParseSpellRequire(tokenStream, nodeList, annotation)
            end
        else
            self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DECLARATION; declaration keyword expected.", token)
            tokenStream:Consume()
            ok = false
        end
        return ok, node
    end,
    ParseDefine = function(self, tokenStream, nodeList, annotation)
        local ok = true
        do
            local tokenType, token = tokenStream:Consume()
            if  not (tokenType == "keyword" and token == "Define") then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; 'Define' expected.", token)
                ok = false
            end
        end
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= "(" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; '(' expected.", token)
                ok = false
            end
        end
        local name
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType == "name" then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; name expected.", token)
                ok = false
            end
        end
        local value
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType == "-" then
                tokenType, token = tokenStream:Consume()
                if tokenType == "number" then
                    value = -1 * _tonumber(token)
                else
                    self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; number expected after '-'.", token)
                    ok = false
                end
            elseif tokenType == "number" then
                value = _tonumber(token)
            elseif tokenType == "string" then
                value = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; number or string expected.", token)
                ok = false
            end
        end
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; ')' expected.", token)
                ok = false
            end
        end
        local node
        if ok then
            node = self:NewNode(nodeList)
            node.type = "define"
            node.name = name
            node.value = value
            annotation.definition = annotation.definition or {}
            annotation.definition[name] = value
        end
        return ok, node
    end,
    ParseExpression = function(self, tokenStream, nodeList, annotation, minPrecedence)
        minPrecedence = minPrecedence or 0
        local ok = true
        local node
        do
            local tokenType, token = tokenStream:Peek()
            if tokenType then
                local opInfo = UNARY_OPERATOR[token]
                if opInfo then
                    local opType, precedence = opInfo[1], opInfo[2]
                    tokenStream:Consume()
                    local operator = token
                    local rhsNode
                    ok, rhsNode = self:ParseExpression(tokenStream, nodeList, annotation, precedence)
                    if ok then
                        if operator == "-" and rhsNode.type == "value" then
                            local value = -1 * rhsNode.value
                            node = self:GetNumberNode(value, nodeList, annotation)
                        else
                            node = self:NewNode(nodeList, true)
                            node.type = opType
                            node.expressionType = "unary"
                            node.operator = operator
                            node.precedence = precedence
                            node.child[1] = rhsNode
                        end
                    end
                else
                    ok, node = self:ParseSimpleExpression(tokenStream, nodeList, annotation)
                end
            end
        end
        while ok do
            local keepScanning = false
            local tokenType, token = tokenStream:Peek()
            if tokenType then
                local opInfo = BINARY_OPERATOR[token]
                if opInfo then
                    local opType, precedence = opInfo[1], opInfo[2]
                    if precedence and precedence > minPrecedence then
                        keepScanning = true
                        tokenStream:Consume()
                        local operator = token
                        local lhsNode = node
                        local rhsNode
                        ok, rhsNode = self:ParseExpression(tokenStream, nodeList, annotation, precedence)
                        if ok then
                            node = self:NewNode(nodeList, true)
                            node.type = opType
                            node.expressionType = "binary"
                            node.operator = operator
                            node.precedence = precedence
                            node.child[1] = lhsNode
                            node.child[2] = rhsNode
                            local rotated = false
                            while node.type == rhsNode.type and node.operator == rhsNode.operator and BINARY_OPERATOR[node.operator][3] == "associative" and rhsNode.expressionType == "binary" do
                                node.child[2] = rhsNode.child[1]
                                rhsNode.child[1] = node
                                node.asString = self:UnparseExpression(node)
                                node = rhsNode
                                rhsNode = node.child[2]
                                rotated = true
                            end
                            if rotated then
                                node.asString = self:UnparseExpression(node)
                            end
                        end
                    end
                end
            end
            if  not keepScanning then
                break
            end
        end
        if ok and node then
            node.asString = node.asString or self:Unparse(node)
        end
        return ok, node
    end,
    ParseFunction = function(self, tokenStream, nodeList, annotation)
        local ok = true
        local name, lowername
        do
            local tokenType, token = tokenStream:Consume()
            if tokenType == "name" then
                name = token
                lowername = strlower(name)
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; name expected.", token)
                ok = false
            end
        end
        local target
        if ok then
            local tokenType, token = tokenStream:Peek()
            if tokenType == "." then
                target = name
                tokenType, token = tokenStream:Consume(2)
                if tokenType == "name" then
                    name = token
                    lowername = strlower(name)
                else
                    self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; name expected.", token)
                    ok = false
                end
            end
        end
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= "(" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; '(' expected.", token)
                ok = false
            end
        end
        local positionalParams, namedParams
        if ok then
            ok, positionalParams, namedParams = self:ParseParameters(tokenStream, nodeList, annotation)
        end
        if ok and ACTION_PARAMETER_COUNT[lowername] then
            local count = ACTION_PARAMETER_COUNT[lowername]
            if count > #positionalParams then
                self:SyntaxError(tokenStream, "Syntax error: action '%s' requires at least %d fixed parameter(s).", name, count)
                ok = false
            end
        end
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; ')' expected.", token)
                ok = false
            end
        end
        if ok then
            if  not namedParams.target then
                if strsub(lowername, 1, 6) == "target" then
                    namedParams.target = "target"
                    lowername = strsub(lowername, 7)
                    name = strsub(name, 7)
                end
            end
            if  not namedParams.filter then
                if strsub(lowername, 1, 6) == "debuff" then
                    namedParams.filter = "debuff"
                elseif strsub(lowername, 1, 4) == "buff" then
                    namedParams.filter = "buff"
                elseif strsub(lowername, 1, 11) == "otherdebuff" then
                    namedParams.filter = "debuff"
                elseif strsub(lowername, 1, 9) == "otherbuff" then
                    namedParams.filter = "buff"
                end
            end
            if target then
                namedParams.target = target
            end
        end
        local node
        if ok then
            node = self:NewNode(nodeList)
            node.name = name
            node.lowername = lowername
            if STATE_ACTION[lowername] then
                node.type = "state"
                node.func = lowername
            elseif ACTION_PARAMETER_COUNT[lowername] then
                node.type = "action"
                node.func = lowername
            elseif STRING_LOOKUP_FUNCTION[name] then
                node.type = "function"
                node.func = name
                annotation.stringReference = annotation.stringReference or {}
                annotation.stringReference[#annotation.stringReference + 1] = node
            elseif __Condition.OvaleCondition:IsCondition(lowername) then
                node.type = "function"
                node.func = lowername
            else
                node.type = "custom_function"
                node.func = name
            end
            node.rawPositionalParams = positionalParams
            node.rawNamedParams = namedParams
            node.asString = self:UnparseFunction(node)
            annotation.parametersReference = annotation.parametersReference or {}
            annotation.parametersReference[#annotation.parametersReference + 1] = node
            annotation.functionCall = annotation.functionCall or {}
            annotation.functionCall[node.func] = true
            annotation.functionReference = annotation.functionReference or {}
            annotation.functionReference[#annotation.functionReference + 1] = node
        end
        return ok, node
    end,
    ParseGroup = function(self, tokenStream, nodeList, annotation)
        local ok = true
        do
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= "{" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing GROUP; '{' expected.", token)
                ok = false
            end
        end
        local child = self.self_childrenPool:Get()
        local tokenType, token = tokenStream:Peek()
        while ok and tokenType and tokenType ~= "}" do
            local statementNode
            ok, statementNode = self:ParseStatement(tokenStream, nodeList, annotation)
            if ok then
                child[#child + 1] = statementNode
                tokenType, token = tokenStream:Peek()
            else
                break
            end
        end
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= "}" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing GROUP; '}' expected.", token)
                ok = false
            end
        end
        local node
        if ok then
            node = self:NewNode(nodeList)
            node.type = "group"
            node.child = child
        else
            self.self_childrenPool:Release(child)
        end
        return ok, node
    end,
    ParseInclude = function(self, tokenStream, nodeList, annotation)
        local ok = true
        do
            local tokenType, token = tokenStream:Consume()
            if  not (tokenType == "keyword" and token == "Include") then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing INCLUDE; 'Include' expected.", token)
                ok = false
            end
        end
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= "(" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing INCLUDE; '(' expected.", token)
                ok = false
            end
        end
        local name
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType == "name" then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing INCLUDE; script name expected.", token)
                ok = false
            end
        end
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing INCLUDE; ')' expected.", token)
                ok = false
            end
        end
        local code = __Scripts.OvaleScripts:GetScript(name)
        if  not code then
            self:Error("Script '%s' not found when parsing INCLUDE.", name)
            ok = false
        end
        local node
        if ok then
            local includeTokenStream = __Lexer.OvaleLexer(name, code, MATCHES, FILTERS)
            ok, node = self:ParseScriptStream(includeTokenStream, nodeList, annotation)
            includeTokenStream:Release()
        end
        return ok, node
    end,
    ParseItemRequire = function(self, tokenStream, nodeList, annotation)
        local ok = true
        do
            local tokenType, token = tokenStream:Consume()
            if  not (tokenType == "keyword" and token == "ItemRequire") then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; keyword expected.", token)
                ok = false
            end
        end
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= "(" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; '(' expected.", token)
                ok = false
            end
        end
        local itemId, name
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType == "number" then
                itemId = token
            elseif tokenType == "name" then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; number or name expected.", token)
                ok = false
            end
        end
        local property
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType == "name" then
                property = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; property name expected.", token)
                ok = false
            end
        end
        local positionalParams, namedParams
        if ok then
            ok, positionalParams, namedParams = self:ParseParameters(tokenStream, nodeList, annotation)
        end
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; ')' expected.", token)
                ok = false
            end
        end
        local node
        if ok then
            node = self:NewNode(nodeList)
            node.type = "item_require"
            node.itemId = itemId
            node.name = name
            node.property = property
            node.rawPositionalParams = positionalParams
            node.rawNamedParams = namedParams
            annotation.parametersReference = annotation.parametersReference or {}
            annotation.parametersReference[#annotation.parametersReference + 1] = node
            if name then
                annotation.nameReference = annotation.nameReference or {}
                annotation.nameReference[#annotation.nameReference + 1] = node
            end
        end
        return ok, node
    end,
    ParseList = function(self, tokenStream, nodeList, annotation)
        local ok = true
        local keyword
        do
            local tokenType, token = tokenStream:Consume()
            if tokenType == "keyword" and (token == "ItemList" or token == "SpellList") then
                keyword = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing LIST; keyword expected.", token)
                ok = false
            end
        end
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= "(" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing LIST; '(' expected.", token)
                ok = false
            end
        end
        local name
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType == "name" then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing LIST; name expected.", token)
                ok = false
            end
        end
        local positionalParams, namedParams
        if ok then
            ok, positionalParams, namedParams = self:ParseParameters(tokenStream, nodeList, annotation)
        end
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing LIST; ')' expected.", token)
                ok = false
            end
        end
        local node
        if ok then
            node = self:NewNode(nodeList)
            node.type = "list"
            node.keyword = keyword
            node.name = name
            node.rawPositionalParams = positionalParams
            node.rawNamedParams = namedParams
            annotation.parametersReference = annotation.parametersReference or {}
            annotation.parametersReference[#annotation.parametersReference + 1] = node
        end
        return ok, node
    end,
    ParseNumber = function(self, tokenStream, nodeList, annotation)
        local ok = true
        local value
        do
            local tokenType, token = tokenStream:Consume()
            if tokenType == "number" then
                value = _tonumber(token)
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing NUMBER; number expected.", token)
                ok = false
            end
        end
        local node
        if ok then
            node = self:GetNumberNode(value, nodeList, annotation)
        end
        return ok, node
    end,
    ParseParameterValue = function(self, tokenStream, nodeList, annotation)
        local ok = true
        local node
        local tokenType, token
        local parameters
        repeat
            ok, node = self:ParseSimpleParameterValue(tokenStream, nodeList, annotation)
            if ok and node then
                tokenType, token = tokenStream:Peek()
                if tokenType == "," then
                    tokenStream:Consume()
                    parameters = parameters or self.self_parametersPool:Get()
                end
                if parameters then
                    parameters[#parameters + 1] = node
                end
            end
        until not ( not ( not ok or tokenType ~= ","))
        if ok and parameters then
            node = self:NewNode(nodeList)
            node.type = "comma_separated_values"
            node.csv = parameters
            annotation.parametersList = annotation.parametersList or {}
            annotation.parametersList[#annotation.parametersList + 1] = parameters
        end
        return ok, node
    end,
    ParseScriptStream = function(self, tokenStream, nodeList, annotation)
        self:StartProfiling("OvaleAST_ParseScript")
        local ok = true
        local child = self.self_childrenPool:Get()
        while ok do
            local tokenType, token = tokenStream:Peek()
            if tokenType then
                local declarationNode
                ok, declarationNode = self:ParseDeclaration(tokenStream, nodeList, annotation)
                if ok then
                    if declarationNode.type == "script" then
                        for _, node in _ipairs(declarationNode.child) do
                            child[#child + 1] = node
                        end
                        self.self_pool:Release(declarationNode)
                    else
                        child[#child + 1] = declarationNode
                    end
                end
            else
                break
            end
        end
        local ast
        if ok then
            ast = self:NewNode()
            ast.type = "script"
            ast.child = child
        else
            self.self_childrenPool:Release(child)
        end
        self:StopProfiling("OvaleAST_ParseScript")
        return ok, ast
    end,
    ParseSimpleExpression = function(self, tokenStream, nodeList, annotation)
        local ok = true
        local node
        local tokenType, token = tokenStream:Peek()
        if tokenType == "number" then
            ok, node = self:ParseNumber(tokenStream, nodeList, annotation)
        elseif tokenType == "string" then
            ok, node = self:ParseString(tokenStream, nodeList, annotation)
        elseif tokenType == "name" then
            tokenType, token = tokenStream:Peek(2)
            if tokenType == "." or tokenType == "(" then
                ok, node = self:ParseFunction(tokenStream, nodeList, annotation)
            else
                ok, node = self:ParseVariable(tokenStream, nodeList, annotation)
            end
        elseif tokenType == "(" or tokenType == "{" then
            ok, node = self:ParseParentheses(tokenStream, nodeList, annotation)
        else
            tokenStream:Consume()
            self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SIMPLE EXPRESSION", token)
            ok = false
        end
        return ok, node
    end,
    ParseSimpleParameterValue = function(self, tokenStream, nodeList, annotation)
        local ok = true
        local isBang = false
        local tokenType, token = tokenStream:Peek()
        if tokenType == "!" then
            isBang = true
            tokenStream:Consume()
        end
        local expressionNode
        tokenType, token = tokenStream:Peek()
        if tokenType == "(" or tokenType == "-" then
            ok, expressionNode = self:ParseExpression(tokenStream, nodeList, annotation)
        else
            ok, expressionNode = self:ParseSimpleExpression(tokenStream, nodeList, annotation)
        end
        local node
        if isBang then
            node = self:NewNode(nodeList, true)
            node.type = "bang_value"
            node.child[1] = expressionNode
        else
            node = expressionNode
        end
        return ok, node
    end,
    ParseSpellAuraList = function(self, tokenStream, nodeList, annotation)
        local ok = true
        local keyword
        do
            local tokenType, token = tokenStream:Consume()
            if tokenType == "keyword" and SPELL_AURA_KEYWORD[token] then
                keyword = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLAURALIST; keyword expected.", token)
                ok = false
            end
        end
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= "(" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLAURALIST; '(' expected.", token)
                ok = false
            end
        end
        local spellId, name
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType == "number" then
                spellId = token
            elseif tokenType == "name" then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLAURALIST; number or name expected.", token)
                ok = false
            end
        end
        local positionalParams, namedParams
        if ok then
            ok, positionalParams, namedParams = self:ParseParameters(tokenStream, nodeList, annotation)
        end
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLAURALIST; ')' expected.", token)
                ok = false
            end
        end
        local node
        if ok then
            node = self:NewNode(nodeList)
            node.type = "spell_aura_list"
            node.keyword = keyword
            node.spellId = spellId
            node.name = name
            node.rawPositionalParams = positionalParams
            node.rawNamedParams = namedParams
            annotation.parametersReference = annotation.parametersReference or {}
            annotation.parametersReference[#annotation.parametersReference + 1] = node
            if name then
                annotation.nameReference = annotation.nameReference or {}
                annotation.nameReference[#annotation.nameReference + 1] = node
            end
        end
        return ok, node
    end,
    ParseSpellInfo = function(self, tokenStream, nodeList, annotation)
        local ok = true
        local name, lowername
        do
            local tokenType, token = tokenStream:Consume()
            if  not (tokenType == "keyword" and token == "SpellInfo") then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLINFO; 'SpellInfo' expected.", token)
                ok = false
            end
        end
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= "(" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLINFO; '(' expected.", token)
                ok = false
            end
        end
        local spellId
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType == "number" then
                spellId = token
            elseif tokenType == "name" then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLINFO; number or name expected.", token)
                ok = false
            end
        end
        local positionalParams, namedParams
        if ok then
            ok, positionalParams, namedParams = self:ParseParameters(tokenStream, nodeList, annotation)
        end
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLINFO; ')' expected.", token)
                ok = false
            end
        end
        local node
        if ok then
            node = self:NewNode(nodeList)
            node.type = "spell_info"
            node.spellId = spellId
            node.name = name
            node.rawPositionalParams = positionalParams
            node.rawNamedParams = namedParams
            annotation.parametersReference = annotation.parametersReference or {}
            annotation.parametersReference[#annotation.parametersReference + 1] = node
            if name then
                annotation.nameReference = annotation.nameReference or {}
                annotation.nameReference[#annotation.nameReference + 1] = node
            end
        end
        return ok, node
    end,
    ParseSpellRequire = function(self, tokenStream, nodeList, annotation)
        local ok = true
        do
            local tokenType, token = tokenStream:Consume()
            if  not (tokenType == "keyword" and token == "SpellRequire") then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; keyword expected.", token)
                ok = false
            end
        end
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= "(" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; '(' expected.", token)
                ok = false
            end
        end
        local spellId, name
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType == "number" then
                spellId = token
            elseif tokenType == "name" then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; number or name expected.", token)
                ok = false
            end
        end
        local property
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType == "name" then
                property = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; property name expected.", token)
                ok = false
            end
        end
        local positionalParams, namedParams
        if ok then
            ok, positionalParams, namedParams = self:ParseParameters(tokenStream, nodeList, annotation)
        end
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; ')' expected.", token)
                ok = false
            end
        end
        local node
        if ok then
            node = self:NewNode(nodeList)
            node.type = "spell_require"
            node.spellId = spellId
            node.name = name
            node.property = property
            node.rawPositionalParams = positionalParams
            node.rawNamedParams = namedParams
            annotation.parametersReference = annotation.parametersReference or {}
            annotation.parametersReference[#annotation.parametersReference + 1] = node
            if name then
                annotation.nameReference = annotation.nameReference or {}
                annotation.nameReference[#annotation.nameReference + 1] = node
            end
        end
        return ok, node
    end,
    ParseStatement = function(self, tokenStream, nodeList, annotation)
        local ok = true
        local node
        local tokenType, token = tokenStream:Peek()
        if tokenType then
            local parser
            if token == "{" then
                local i = 1
                local count = 0
                while tokenType do
                    if token == "{" then
                        count = count + 1
                    elseif token == "}" then
                        count = count - 1
                    end
                    i = i + 1
                    tokenType, token = tokenStream:Peek(i)
                    if count == 0 then
                        break
                    end
                end
                if tokenType then
                    if BINARY_OPERATOR[token] then
                        ok, node = self:ParseExpression(tokenStream, nodeList, annotation)
                    else
                        ok, node = self:ParseGroup(tokenStream, nodeList, annotation)
                    end
                else
                    self:SyntaxError(tokenStream, "Syntax error: unexpected end of script.")
                end
            elseif token == "if" then
                ok, node = self:ParseIf(tokenStream, nodeList, annotation)
            elseif token == "unless" then
                ok, node = self:ParseUnless(tokenStream, nodeList, annotation)
            else
                ok, node = self:ParseExpression(tokenStream, nodeList, annotation)
            end
        end
        return ok, node
    end,
    ParseString = function(self, tokenStream, nodeList, annotation)
        local ok = true
        local node
        local value
        if ok then
            local tokenType, token = tokenStream:Peek()
            if tokenType == "string" then
                value = token
                tokenStream:Consume()
            elseif tokenType == "name" then
                if STRING_LOOKUP_FUNCTION[token] then
                    ok, node = self:ParseFunction(tokenStream, nodeList, annotation)
                else
                    value = token
                    tokenStream:Consume()
                end
            else
                tokenStream:Consume()
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing STRING; string, variable, or function expected.", token)
                ok = false
            end
        end
        if ok and  not node then
            node = self:NewNode(nodeList)
            node.type = "string"
            node.value = value
            annotation.stringReference = annotation.stringReference or {}
            annotation.stringReference[#annotation.stringReference + 1] = node
        end
        return ok, node
    end,
    ParseUnless = function(self, tokenStream, nodeList, annotation)
        local ok = true
        do
            local tokenType, token = tokenStream:Consume()
            if  not (tokenType == "keyword" and token == "unless") then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing UNLESS; 'unless' expected.", token)
                ok = false
            end
        end
        local conditionNode, bodyNode
        if ok then
            ok, conditionNode = self:ParseExpression(tokenStream, nodeList, annotation)
        end
        if ok then
            ok, bodyNode = self:ParseStatement(tokenStream, nodeList, annotation)
        end
        local node
        if ok then
            node = self:NewNode(nodeList, true)
            node.type = "unless"
            node.child[1] = conditionNode
            node.child[2] = bodyNode
        end
        return ok, node
    end,
    ParseVariable = function(self, tokenStream, nodeList, annotation)
        local ok = true
        local name
        do
            local tokenType, token = tokenStream:Consume()
            if tokenType == "name" then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing VARIABLE; name expected.", token)
                ok = false
            end
        end
        local node
        if ok then
            node = self:NewNode(nodeList)
            node.type = "variable"
            node.name = name
            annotation.nameReference = annotation.nameReference or {}
            annotation.nameReference[#annotation.nameReference + 1] = node
        end
        return ok, node
    end,
    OnInitialize = function(self)
    end,
    DebugAST = function(self)
        self.self_pool:DebuggingInfo()
        self.self_parametersPool:DebuggingInfo()
        self.self_controlPool:DebuggingInfo()
        self.self_childrenPool:DebuggingInfo()
        self.self_outputPool:DebuggingInfo()
    end,
    NewNode = function(self, nodeList, hasChild)
        local node = self.self_pool:Get()
        if nodeList then
            local nodeId = #nodeList + 1
            node.nodeId = nodeId
            nodeList[nodeId] = node
        end
        if hasChild then
            node.child = self.self_childrenPool:Get()
        end
        return node
    end,
    NodeToString = function(self, node)
        local output = self:print_r(node)
        return tconcat(output, "\n")
    end,
    ReleaseAnnotation = function(self, annotation)
        if annotation.controlList then
            for _, control in _ipairs(annotation.controlList) do
                self.self_controlPool:Release(control)
            end
        end
        if annotation.parametersList then
            for _, parameters in _ipairs(annotation.parametersList) do
                self.self_parametersPool:Release(parameters)
            end
        end
        if annotation.nodeList then
            for _, node in _ipairs(annotation.nodeList) do
                self.self_pool:Release(node)
            end
        end
        for key, value in _pairs(annotation) do
            if _type(value) == "table" then
                _wipe(value)
            end
            annotation[key] = nil
        end
    end,
    Release = function(self, ast)
        if ast.annotation then
            self:ReleaseAnnotation(ast.annotation)
            ast.annotation = nil
        end
        self.self_pool:Release(ast)
    end,
    ParseCode = function(self, nodeType, code, nodeList, annotation)
        nodeList = nodeList or {}
        annotation = annotation or {}
        local tokenStream = __Lexer.OvaleLexer("Ovale", code, MATCHES)
        local ok, node = self:Parse(nodeType, tokenStream, nodeList, annotation)
        tokenStream:Release()
        return node, nodeList, annotation
    end,
    ParseScript = function(self, name, options)
        local code = __Scripts.OvaleScripts:GetScript(name)
        local ast
        if code then
            options = options or {
                optimize = true,
                verify = true
            }
            local annotation = {
                nodeList = {},
                verify = options.verify
            }
            ast = self:ParseCode("script", code, annotation.nodeList, annotation)
            if ast then
                ast.annotation = annotation
                self:PropagateConstants(ast)
                self:PropagateStrings(ast)
                self:FlattenParameters(ast)
                self:VerifyParameterStances(ast)
                self:VerifyFunctionCalls(ast)
                if options.optimize then
                    self:Optimize(ast)
                end
                self:InsertPostOrderTraversal(ast)
            else
                ast = self:NewNode()
                ast.annotation = annotation
                self:Release(ast)
                ast = nil
            end
        end
        return ast
    end,
    PropagateConstants = function(self, ast)
        self:StartProfiling("OvaleAST_PropagateConstants")
        if ast.annotation then
            local dictionary = ast.annotation.definition
            if dictionary and ast.annotation.nameReference then
                for _, node in _ipairs(ast.annotation.nameReference) do
                    if (node.type == "item_info" or node.type == "item_require") and node.name then
                        local itemId = dictionary[node.name]
                        if itemId then
                            node.itemId = itemId
                        end
                    elseif (node.type == "spell_aura_list" or node.type == "spell_info" or node.type == "spell_require") and node.name then
                        local spellId = dictionary[node.name]
                        if spellId then
                            node.spellId = spellId
                        end
                    elseif node.type == "variable" then
                        local name = node.name
                        local value = dictionary[name]
                        if value then
                            node.previousType = "variable"
                            node.type = "value"
                            node.value = value
                            node.origin = 0
                            node.rate = 0
                        end
                    end
                end
            end
        end
        self:StopProfiling("OvaleAST_PropagateConstants")
    end,
    PropagateStrings = function(self, ast)
        self:StartProfiling("OvaleAST_PropagateStrings")
        if ast.annotation and ast.annotation.stringReference then
            for _, node in _ipairs(ast.annotation.stringReference) do
                if node.type == "string" then
                    local key = node.value
                    local value = __Localization.L[key]
                    if key ~= value then
                        node.value = value
                        node.key = key
                    end
                elseif node.type == "variable" then
                    local value = node.name
                    node.previousType = node.type
                    node.type = "string"
                    node.value = value
                elseif node.type == "number" then
                    local value = _tostring(node.value)
                    node.previousType = "number"
                    node.type = "string"
                    node.value = value
                elseif node.type == "function" then
                    local key = node.rawPositionalParams[1]
                    if _type(key) == "table" then
                        if key.type == "value" then
                            key = key.value
                        elseif key.type == "variable" then
                            key = key.name
                        elseif key.type == "string" then
                            key = key.value
                        end
                    end
                    local value
                    if key then
                        local name = node.name
                        if name == "ItemName" then
                            value = API_GetItemInfo(key) or "item:" + key
                        elseif name == "L" then
                            value = __Localization.L[key]
                        elseif name == "SpellName" then
                            value = __SpellBook.OvaleSpellBook:GetSpellName(key) or "spell:" + key
                        end
                    end
                    if value then
                        node.previousType = "function"
                        node.type = "string"
                        node.value = value
                        node.key = key
                    end
                end
            end
        end
        self:StopProfiling("OvaleAST_PropagateStrings")
    end,
    FlattenParameters = function(self, ast)
        self:StartProfiling("OvaleAST_FlattenParameters")
        local annotation = ast.annotation
        if annotation and annotation.parametersReference then
            local dictionary = annotation.definition
            for _, node in _ipairs(annotation.parametersReference) do
                if node.rawPositionalParams then
                    local parameters = self.self_parametersPool:Get()
                    for key, value in _ipairs(node.rawPositionalParams) do
                        parameters[key] = self:FlattenParameterValue(value, annotation)
                    end
                    node.positionalParams = parameters
                    annotation.parametersList = annotation.parametersList or {}
                    annotation.parametersList[#annotation.parametersList + 1] = parameters
                end
                if node.rawNamedParams then
                    local parameters = self.self_parametersPool:Get()
                    for key, value in _pairs(node.rawNamedParams) do
                        if key == "checkbox" or key == "listitem" then
                            local control = parameters[key] or self.self_controlPool:Get()
                            if key == "checkbox" then
                                for i, name in _ipairs(value) do
                                    control[i] = self:FlattenParameterValue(name, annotation)
                                end
                            else
                                for list, item in _pairs(value) do
                                    control[list] = self:FlattenParameterValue(item, annotation)
                                end
                            end
                            if  not parameters[key] then
                                parameters[key] = control
                                annotation.controlList = annotation.controlList or {}
                                annotation.controlList[#annotation.controlList + 1] = control
                            end
                        else
                            if _type(key) ~= "number" and dictionary and dictionary[key] then
                                key = dictionary[key]
                            end
                            parameters[key] = self:FlattenParameterValue(value, annotation)
                        end
                    end
                    node.namedParams = parameters
                    annotation.parametersList = annotation.parametersList or {}
                    annotation.parametersList[#annotation.parametersList + 1] = parameters
                end
                local output = self.self_outputPool:Get()
                for k, v in _pairs(node.namedParams) do
                    if k == "checkbox" then
                        for _, name in _ipairs(v) do
                            output[#output + 1] = format("checkbox=%s", name)
                        end
                    elseif k == "listitem" then
                        for list, item in _ipairs(v) do
                            output[#output + 1] = format("listitem=%s:%s", list, item)
                        end
                    elseif _type(v) == "table" then
                        output[#output + 1] = format("%s=%s", k, tconcat(v, ","))
                    else
                        output[#output + 1] = format("%s=%s", k, v)
                    end
                end
                tsort(output)
                for k = #node.positionalParams, 1, -1 do
                    tinsert(output, 1, node.positionalParams[k])
                end
                if #output > 0 then
                    node.paramsAsString = tconcat(output, " ")
                else
                    node.paramsAsString = ""
                end
                self.self_outputPool:Release(output)
            end
        end
        self:StopProfiling("OvaleAST_FlattenParameters")
    end,
    VerifyFunctionCalls = function(self, ast)
        self:StartProfiling("OvaleAST_VerifyFunctionCalls")
        if ast.annotation and ast.annotation.verify then
            local customFunction = ast.annotation.customFunction
            local functionCall = ast.annotation.functionCall
            if functionCall then
                for name in _pairs(functionCall) do
                    if ACTION_PARAMETER_COUNT[name] then
                    elseif STRING_LOOKUP_FUNCTION[name] then
                    elseif __Condition.OvaleCondition:IsCondition(name) then
                    elseif customFunction and customFunction[name] then
                    else
                        self:Error("unknown function '%s'.", name)
                    end
                end
            end
        end
        self:StopProfiling("OvaleAST_VerifyFunctionCalls")
    end,
    VerifyParameterStances = function(self, ast)
        self:StartProfiling("OvaleAST_VerifyParameterStances")
        local annotation = ast.annotation
        if annotation and annotation.verify and annotation.parametersReference then
            for _, node in _ipairs(annotation.parametersReference) do
                if node.rawNamedParams then
                    for stanceKeyword in _pairs(STANCE_KEYWORD) do
                        local valueNode = node.rawNamedParams[stanceKeyword]
                        if valueNode then
                            if valueNode.type == "comma_separated_values" then
                                valueNode = valueNode.csv[1]
                            end
                            if valueNode.type == "bang_value" then
                                valueNode = valueNode.child[1]
                            end
                            local value = self:FlattenParameterValue(valueNode, annotation)
                            if __Stance.OvaleStance.STANCE_NAME[value] then
                            elseif _type(value) == "number" then
                            else
                                self:Error("unknown stance '%s'.", value)
                            end
                        end
                    end
                end
            end
        end
        self:StopProfiling("OvaleAST_VerifyParameterStances")
    end,
    InsertPostOrderTraversal = function(self, ast)
        self:StartProfiling("OvaleAST_InsertPostOrderTraversal")
        local annotation = ast.annotation
        if annotation and annotation.postOrderReference then
            for _, node in _ipairs(annotation.postOrderReference) do
                local array = self.self_postOrderPool:Get()
                local visited = self.postOrderVisitedPool:Get()
                self:PostOrderTraversal(node, array, visited)
                self.postOrderVisitedPool:Release(visited)
                node.postOrder = array
            end
        end
        self:StopProfiling("OvaleAST_InsertPostOrderTraversal")
    end,
    Optimize = function(self, ast)
        self:CommonFunctionElimination(ast)
        self:CommonSubExpressionElimination(ast)
    end,
    CommonFunctionElimination = function(self, ast)
        self:StartProfiling("OvaleAST_CommonFunctionElimination")
        if ast.annotation then
            if ast.annotation.functionReference then
                local functionHash = ast.annotation.functionHash or {}
                for _, node in _ipairs(ast.annotation.functionReference) do
                    if node.positionalParams or node.namedParams then
                        local hash = node.name .. node.paramsAsString
                        node.functionHash = hash
                        functionHash[hash] = functionHash[hash] or node
                    end
                end
                ast.annotation.functionHash = functionHash
            end
            if ast.annotation.functionHash and ast.annotation.nodeList then
                local functionHash = ast.annotation.functionHash
                for _, node in _ipairs(ast.annotation.nodeList) do
                    if node.child then
                        for k, childNode in _ipairs(node.child) do
                            if childNode.functionHash then
                                node.child[k] = functionHash[childNode.functionHash]
                            end
                        end
                    end
                end
            end
        end
        self:StopProfiling("OvaleAST_CommonFunctionElimination")
    end,
    CommonSubExpressionElimination = function(self, ast)
        self:StartProfiling("OvaleAST_CommonSubExpressionElimination")
        if ast and ast.annotation and ast.annotation.nodeList then
            local expressionHash = {}
            for _, node in _ipairs(ast.annotation.nodeList) do
                local hash = node.asString
                if hash then
                    expressionHash[hash] = expressionHash[hash] or node
                end
                if node.child then
                    for i, childNode in _ipairs(node.child) do
                        hash = childNode.asString
                        if hash then
                            local hashNode = expressionHash[hash]
                            if hashNode then
                                node.child[i] = hashNode
                            else
                                expressionHash[hash] = childNode
                            end
                        end
                    end
                end
            end
            ast.annotation.expressionHash = expressionHash
        end
        self:StopProfiling("OvaleAST_CommonSubExpressionElimination")
    end,
})
__exports.OvaleAST = OvaleASTClass()
end)
