local EvalOp, EvalFun, DiffOp, DiffFun

local function diff( var, expr )
	if type( expr ) == 'table' then
		if DiffOp[expr[1]] then
			return DiffOp[expr[1]]( var, expr[2], expr[3] )
		elseif DiffFun[expr[1]] then
			return {'*', diff( var, expr[2] ), DiffFun[expr[1]]( expr[2] )}
		else
			error( tostring( expr[1] ) .. ' not registred as operator or function' )
		end
	elseif expr == var then
		return 1
	else
		return 0
	end
end

local function compile( expr )
	if type( expr ) == 'table' then
		if DiffOp[expr[1]] then
			return '(' .. compile( expr[2] ) .. expr[1] .. compile( expr[3] ) .. ')'
		elseif DiffFun[expr[1]] then
			return expr[1] .. '(' .. compile( expr[2] ) .. ')'
		else
			error( tostring( expr[1] ) .. ' not registred as operator or function' )
		end
	elseif tonumber( expr ) then
		return tostring( expr )
	else
		return expr
	end
end

local function equal( a, b )
	if a == b then
		return true
	else
		local t1, t2 = type( a ), type( b )
		if t1 == t2 and t1 == 'table' then
			local n = #a
			if n == #b then
				for i = 1, n do
					if a[i] ~= b[i] then
						return false
					end
				end
				return true
			else
				return false
			end
		else
			return false
		end
	end
end

local function simplify( expr )
	if type( expr ) == 'table' then
		local op = expr[1]
		if EvalOp[op] then
			local arg1, arg2 = simplify( expr[2] ), simplify( expr[3] )
			if tonumber( arg1 ) and tonumber( arg2 ) then
				return EvalOp[op]( arg1, arg2 )
			elseif op == '*' then
				if tonumber(arg1) == 0 or tonumber(arg2) == 0 then
					return 0
				elseif tonumber(arg1) == 1 then
					return arg2
				elseif tonumber(arg2) == 1 then
					return arg1
				elseif type( arg2 ) == 'table' and arg2[1] == '/' and tonumber(arg2[2]) == 1 then
					return simplify{'/', arg1, arg2[3]}
				elseif type( arg1 ) == 'table' and arg1[1] == '/' and tonumber(arg1[2]) == 1 then
					return simplify{'/', arg2, arg1[3]}
				end
			elseif op == '+' then
				if tonumber(arg1) == 0 then
					return arg2
				elseif tonumber(arg2) == 0 then
					return arg1
				end
			elseif op == '/' then
				if tonumber(arg1) == 0 then
					return 0
				elseif equal( arg1, arg2 ) then
					return 1
				elseif tonumber(arg2) == 1 then
					return arg1
				end
			elseif op == '-' then
				if tonumber(arg2) == 0 then
					return arg1
				elseif equal(arg1,arg2) then
					return 0
				end
			elseif op == '^' then
				if tonumber(arg1) == 0 then
					return 0
				elseif tonumber(arg1) == 1 or tonumber(arg2) == 0 then
					return 1
				elseif tonumber(arg2) == 1 then
					return arg1
				end
			end
			return {op, arg1, arg2} 
		end
	end
	return expr
end

local Predefined = [[
local sin,cos,tan,arcsin,arccos,arctan,ln = math.sin,math.cos,math.tan,math.asin,math.acos,math.atan,math.log
local function cot( x ) return 1 / tan( x ) end
local function arccot( x ) return atan( 1/ x ) end
]]

local function collect( expr, vars )
	return assert( load( Predefined .. 'return function(' .. table.concat( vars or {},',' ) .. ') return ' .. compile( simplify( expr )) .. ' end' ))()
end

DiffFun = {
	sin = function( x ) return {'cos', x} end,
	cos = function( x ) return {'sin', x} end,
	tan = function( x ) return {'+', {'^', {'cos', x}, 2}, 1} end,
	cot = function( x ) return {'+', {'^', {'sin', x}, 2}, 1} end,
	arcsin = function( x ) return {'/', 1, {'^', {'-', 1, {'^', x, 2}}, {'/', 1, 2}}} end,
	arccos = function( x ) return {'/',-1, {'^', {'-', 1, {'^', x, 2}}, {'/', 1, 2}}} end,
	arctan = function( x ) return {'/', 1, {'+', 1, {'^', x, 2}}} end,
	arccot = function( x ) return {'/',-1, {'+', 1, {'^', x, 2}}} end,
	ln = function( x ) return {'/', 1, x } end,
}

local tan, atan = math.tan, math.atan

EvalFun = {
	sin = math.sin,
	cos = math.cos,
	tan = math.tan,
	cot = function( x ) return 1 / tan( x ) end,
	arcsin = math.asin,
	arccos = math.acos,
	arctan = math.atan,
	arccot = function( x ) return atan( 1 / x ) end,
	ln = math.log,
}

EvalOp = {
	['+'] = function( u, v ) return u + v end,
	['-'] = function( u, v ) return u - v end,
	['*'] = function( u, v ) return u * v end,
	['/'] = function( u, v ) return u / v end,
	['^'] = function( u, v ) return u ^ v end,
}

DiffOp = {
	['+'] = function( var, u, v )
		return {'+', diff( var, u ), diff( var, v )}
	end,

	['-'] = function( var, u, v )
		return {'-', diff( var, u ), diff( var, v )}
	end,

	['*'] = function( var, u, v )
		return {'+', {'*', diff( var, u ), v}, {'*', u, diff( var, v )}}
	end,

	['/'] = function( var, u, v )
		return {'/', {'-',{'*', diff( var, u ), b}, {'*', u, diff( var, v )}}, {'*', v, v}}
	end,

	['^'] = function( var, u, v )
		return {'*',{'^', u, v}, diff(var, {'*',{'ln',u}, v} )}
	end,
}

return {
	diff = diff,
	simplify = simplify,
	compile = compile,
	collect = collect,
}
