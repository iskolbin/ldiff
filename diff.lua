local DiffOp, DiffFun

local function isop( op )
	return DiffOp[op] ~= nil
end

local function isfun( fun )
	return DiffFun[fun] ~= nil
end

local function diff( expr, var )
	if type( expr ) == 'table' then
		if isop( expr[1] ) then
			return DiffOp[expr[1]]( expr[2], expr[3], var )
		elseif isfun( expr[1] ) then
			return {'*', diff( expr[2], var ), {DiffFun[expr[1]],expr[2]}}
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
		if isop( expr[1] ) then
			return '(' .. compile( expr[2] ) .. expr[1] .. compile( expr[3] ) .. ')'
		elseif isfun( expr[1] ) then
			return expr[1] .. '(' .. compile( expr[2] ) .. ')'
		else
			error( tostring( expr[1] ) .. ' not registred as operator or function' )
		end
	elseif type( expr ) == 'number' then
		return tostring( expr )
	else
		return expr
	end
end

local function simplify( expr )
	if type( expr ) == 'table' then
		local arg1, arg2 = simplify( expr[2], expr[3] )
	end
end

local function collect( expr, vars )
	return load( 'function(' .. table.concat( vars,',' ) .. ') return ' .. compile( expr ) .. ' end' )
end

DiffFun = {
	[''] = function( x, var )

	end,
}

DiffOp = {
	['+'] = function( u, v, var )
		return {'+', diff( u, var ), diff( v, var )}
	end,

	['-'] = function( u, v, var )
		return {'-', diff( u, var ), diff( v, var )}
	end,

	['*'] = function( u, v, var )
		return {'+', {'*', diff( u, var ), v}, {'*', u, diff( v, var )}}
	end,

	['/'] = function( u, v, var )
		return {'/', {'-',{'*', diff( u, var ), b}, {'*', u, diff( v, var)}}, {'*', v, v}}
	end,

	['pow'] = function( u, v, var )
		if type( u ) == 'number' and type( v ) == 'number' then
			return 0
		elseif u == 0 or u == 1 or v == 0 then
			return 0
		elseif u == 'e' then
			return {'*',diff( v ),{'pow', 'e', v}}
		elseif type( u ) == 'number' then
			return {'*', {'*',{'ln', u},diff( v )}, v}
		elseif v == 1 then
			return diff( u )
		elseif type( v ) == 'number' then
			return {'*',v,:q

	end,
}

return {
	diff = diff,
	compile = compile,
	collect = collect,
}


