
---------------------------------------------------------
---------------- Auto Bundled Code Block ----------------
---------------------------------------------------------

do
    local searchers = package.searchers or package.loaders
    local origin_seacher = searchers[2]
    searchers[2] = function(path)
        local files =
        {
------------------------
-- Modules part begin --
------------------------

["struct"] = function()
--------------------
-- Module: 'struct'
--------------------
--[[
 * Copyright (c) 2015-2020 Iryont <https://github.com/iryont/lua-struct>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
]]

local unpack = table.unpack or _G.unpack

local struct = {}

function struct.pack(format, ...)
  local stream = {}
  local vars = {...}
  local endianness = true

  for i = 1, format:len() do
    local opt = format:sub(i, i)

    if opt == '<' then
      endianness = true
    elseif opt == '>' then
      endianness = false
    elseif opt:find('[bBhHiIlL]') then
      local n = opt:find('[hH]') and 2 or opt:find('[iI]') and 4 or opt:find('[lL]') and 8 or 1
      local val = tonumber(table.remove(vars, 1))

      local bytes = {}
      for j = 1, n do
        table.insert(bytes, string.char(val % (2 ^ 8)))
        val = math.floor(val / (2 ^ 8))
      end

      if not endianness then
        table.insert(stream, string.reverse(table.concat(bytes)))
      else
        table.insert(stream, table.concat(bytes))
      end
    elseif opt:find('[fd]') then
      local val = tonumber(table.remove(vars, 1))
      local sign = 0

      if val < 0 then
        sign = 1
        val = -val
      end

      local mantissa, exponent = math.frexp(val)
      if val == 0 then
        mantissa = 0
        exponent = 0
      else
        mantissa = (mantissa * 2 - 1) * math.ldexp(0.5, (opt == 'd') and 53 or 24)
        exponent = exponent + ((opt == 'd') and 1022 or 126)
      end

      local bytes = {}
      if opt == 'd' then
        val = mantissa
        for i = 1, 6 do
          table.insert(bytes, string.char(math.floor(val) % (2 ^ 8)))
          val = math.floor(val / (2 ^ 8))
        end
      else
        table.insert(bytes, string.char(math.floor(mantissa) % (2 ^ 8)))
        val = math.floor(mantissa / (2 ^ 8))
        table.insert(bytes, string.char(math.floor(val) % (2 ^ 8)))
        val = math.floor(val / (2 ^ 8))
      end

      table.insert(bytes, string.char(math.floor(exponent * ((opt == 'd') and 16 or 128) + val) % (2 ^ 8)))
      val = math.floor((exponent * ((opt == 'd') and 16 or 128) + val) / (2 ^ 8))
      table.insert(bytes, string.char(math.floor(sign * 128 + val) % (2 ^ 8)))
      val = math.floor((sign * 128 + val) / (2 ^ 8))

      if not endianness then
        table.insert(stream, string.reverse(table.concat(bytes)))
      else
        table.insert(stream, table.concat(bytes))
      end
    elseif opt == 's' then
      table.insert(stream, tostring(table.remove(vars, 1)))
      table.insert(stream, string.char(0))
    elseif opt == 'c' then
      local n = format:sub(i + 1):match('%d+')
      local length = tonumber(n)

      if length > 0 then
        local str = tostring(table.remove(vars, 1))
        if length - str:len() > 0 then
          str = str .. string.rep(' ', length - str:len())
        end
        table.insert(stream, str:sub(1, length))
      end
      i = i + n:len()
    end
  end

  return table.concat(stream)
end

function struct.unpack(format, stream, pos)
  local vars = {}
  local iterator = pos or 1
  local endianness = true

  for i = 1, format:len() do
    local opt = format:sub(i, i)

    if opt == '<' then
      endianness = true
    elseif opt == '>' then
      endianness = false
    elseif opt:find('[bBhHiIlL]') then
      local n = opt:find('[hH]') and 2 or opt:find('[iI]') and 4 or opt:find('[lL]') and 8 or 1
      local signed = opt:lower() == opt

      local val = 0
      for j = 1, n do
        local byte = string.byte(stream:sub(iterator, iterator))
        if endianness then
          val = val + byte * (2 ^ ((j - 1) * 8))
        else
          val = val + byte * (2 ^ ((n - j) * 8))
        end
        iterator = iterator + 1
      end

      if signed and val >= 2 ^ (n * 8 - 1) then
        val = val - 2 ^ (n * 8)
      end

      table.insert(vars, math.floor(val))
    elseif opt:find('[fd]') then
      local n = (opt == 'd') and 8 or 4
      local x = stream:sub(iterator, iterator + n - 1)
      iterator = iterator + n

      if not endianness then
        x = string.reverse(x)
      end

      local sign = 1
      local mantissa = string.byte(x, (opt == 'd') and 7 or 3) % ((opt == 'd') and 16 or 128)
      for i = n - 2, 1, -1 do
        mantissa = mantissa * (2 ^ 8) + string.byte(x, i)
      end

      if string.byte(x, n) > 127 then
        sign = -1
      end

      local exponent = (string.byte(x, n) % 128) * ((opt == 'd') and 16 or 2) + math.floor(string.byte(x, n - 1) / ((opt == 'd') and 16 or 128))
      if exponent == 0 then
        table.insert(vars, 0.0)
      else
        mantissa = (math.ldexp(mantissa, (opt == 'd') and -52 or -23) + 1) * sign
        table.insert(vars, math.ldexp(mantissa, exponent - ((opt == 'd') and 1023 or 127)))
      end
    elseif opt == 's' then
      local bytes = {}
      for j = iterator, stream:len() do
        if stream:sub(j, j) == string.char(0) then
          break
        end

        table.insert(bytes, stream:sub(j, j))
      end

      local str = table.concat(bytes)
      iterator = iterator + str:len() + 1
      table.insert(vars, str)
    elseif opt == 'c' then
      local n = format:sub(i + 1):match('%d+')
      table.insert(vars, stream:sub(iterator, iterator + tonumber(n)-1))
      iterator = iterator + tonumber(n)
      i = i + n:len()
    end
  end

  return unpack(vars)
end

return struct

end,

["glue"] = function()
--------------------
-- Module: 'glue'
--------------------

-- Lua extended vocabulary of basic tools.
-- Written by Cosmin Apreutesei. Public domain.
-- Modifications by Sled

local glue = {}

local min, max, floor, ceil, log =
	math.min, math.max, math.floor, math.ceil, math.log
local select, unpack, pairs, rawget = select, unpack, pairs, rawget

--math -----------------------------------------------------------------------

function glue.round(x, p)
	p = p or 1
	return floor(x / p + .5) * p
end

function glue.floor(x, p)
	p = p or 1
	return floor(x / p) * p
end

function glue.ceil(x, p)
	p = p or 1
	return ceil(x / p) * p
end

glue.snap = glue.round

function glue.clamp(x, x0, x1)
	return min(max(x, x0), x1)
end

function glue.lerp(x, x0, x1, y0, y1)
	return y0 + (x-x0) * ((y1-y0) / (x1 - x0))
end

function glue.nextpow2(x)
	return max(0, 2^(ceil(log(x) / log(2))))
end

--varargs --------------------------------------------------------------------

if table.pack then
	glue.pack = table.pack
else
	function glue.pack(...)
		return {n = select('#', ...), ...}
	end
end

--always use this because table.unpack's default j is #t not t.n.
function glue.unpack(t, i, j)
	return unpack(t, i or 1, j or t.n or #t)
end

--tables ---------------------------------------------------------------------

--count the keys in a table with an optional upper limit.
function glue.count(t, maxn)
	local maxn = maxn or 1/0
	local n = 0
	for _ in pairs(t) do
		n = n + 1
		if n >= maxn then break end
	end
	return n
end

--reverse keys with values.
function glue.index(t)
	local dt={}
	for k,v in pairs(t) do dt[v]=k end
	return dt
end

--put keys in a list, optionally sorted.
local function desc_cmp(a, b) return a > b end
function glue.keys(t, cmp)
	local dt={}
	for k in pairs(t) do
		dt[#dt+1]=k
	end
	if cmp == true or cmp == 'asc' then
		table.sort(dt)
	elseif cmp == 'desc' then
		table.sort(dt, desc_cmp)
	elseif cmp then
		table.sort(dt, cmp)
	end
	return dt
end

--stateless pairs() that iterate elements in key order.
function glue.sortedpairs(t, cmp)
	local kt = glue.keys(t, cmp or true)
	local i = 0
	return function()
		i = i + 1
		return kt[i], t[kt[i]]
	end
end

--update a table with the contents of other table(s).
function glue.update(dt,...)
	for i=1,select('#',...) do
		local t=select(i,...)
		if t then
			for k,v in pairs(t) do dt[k]=v end
		end
	end
	return dt
end

--add the contents of other table(s) without overwrite.
function glue.merge(dt,...)
	for i=1,select('#',...) do
		local t=select(i,...)
		if t then
			for k,v in pairs(t) do
				if rawget(dt, k) == nil then dt[k]=v end
			end
		end
	end
	return dt
end

function glue.deepcopy(orig)
	local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[glue.deepcopy(orig_key)] = glue.deepcopy(orig_value)
        end
        setmetatable(copy, glue.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

--get the value of a table field, and if the field is not present in the
--table, create it as an empty table, and return it.
function glue.attr(t, k, v0)
	local v = t[k]
	if v == nil then
		if v0 == nil then
			v0 = {}
		end
		v = v0
		t[k] = v
	end
	return v
end

--lists ----------------------------------------------------------------------

--extend a list with the elements of other lists.
function glue.extend(dt,...)
	for j=1,select('#',...) do
		local t=select(j,...)
		if t then
			local j = #dt
			for i=1,#t do dt[j+i]=t[i] end
		end
	end
	return dt
end

--append non-nil arguments to a list.
function glue.append(dt,...)
	local j = #dt
	for i=1,select('#',...) do
		dt[j+i] = select(i,...)
	end
	return dt
end

--insert n elements at i, shifting elemens on the right of i (i inclusive)
--to the right.
local function insert(t, i, n)
	if n == 1 then --shift 1
		table.insert(t, i, false)
		return
	end
	for p = #t,i,-1 do --shift n
		t[p+n] = t[p]
	end
end

--remove n elements at i, shifting elements on the right of i (i inclusive)
--to the left.
local function remove(t, i, n)
	n = min(n, #t-i+1)
	if n == 1 then --shift 1
		table.remove(t, i)
		return
	end
	for p=i+n,#t do --shift n
		t[p-n] = t[p]
	end
	for p=#t,#t-n+1,-1 do --clean tail
		t[p] = nil
	end
end

--shift all the elements on the right of i (i inclusive) to the left
--or further to the right.
function glue.shift(t, i, n)
	if n > 0 then
		insert(t, i, n)
	elseif n < 0 then
		remove(t, i, -n)
	end
	return t
end

--map f over t or extract a column from a list of records.
function glue.map(t, f, ...)
	local dt = {}
	if #t == 0 then --treat as hashmap
		if type(f) == 'function' then
			for k,v in pairs(t) do
				dt[k] = f(k, v, ...)
			end
		else
			for k,v in pairs(t) do
				local sel = v[f]
				if type(sel) == 'function' then --method to apply
					dt[k] = sel(v, ...)
				else --field to pluck
					dt[k] = sel
				end
			end
		end
	else --treat as array
		if type(f) == 'function' then
			for i,v in ipairs(t) do
				dt[i] = f(v, ...)
			end
		else
			for i,v in ipairs(t) do
				local sel = v[f]
				if type(sel) == 'function' then --method to apply
					dt[i] = sel(v, ...)
				else --field to pluck
					dt[i] = sel
				end
			end
		end
	end
	return dt
end

--arrays ---------------------------------------------------------------------

--scan list for value. works with ffi arrays too given i and j.
function glue.indexof(v, t, eq, i, j)
	i = i or 1
	j = j or #t
	if eq then
		for i = i, j do
			if eq(t[i], v) then
				return i
			end
		end
	else
		for i = i, j do
			if t[i] == v then
				return i
			end
		end
	end
end

--- Return the index of a table/array if value exists
---@param array table
---@param value any
function glue.arrayhas(array, value)
	for k,v in pairs(array) do
		if (v == value) then return k end
	end
	return nil
end

--- Get the new values of an array
---@param oldarray table
---@param newarray table
function glue.arraynv(oldarray, newarray)
	local newvalues = {}
	for k,v in pairs(newarray) do
		if (not glue.arrayhas(oldarray, v)) then
			glue.append(newvalues, v)
		end
	end
	return newvalues
end

--reverse elements of a list in place. works with ffi arrays too given i and j.
function glue.reverse(t, i, j)
	i = i or 1
	j = (j or #t) + 1
	for k = 1, (j-i)/2 do
		t[i+k-1], t[j-k] = t[j-k], t[i+k-1]
	end
	return t
end

--- Get all the values of a key recursively
---@param t table
---@param dp any
function glue.childsbyparent(t, dp)
    for p,ch in pairs(t) do
		if (p == dp) then
			return ch
		end
		if (ch) then
			local found = glue.childsbyparent(ch, dp)
			if (found) then
				return found
			end
		end
    end
    return nil
end

-- Get the key of a value recursively
---@param t table
---@param dp any
function glue.parentbychild(t, dp)
    for p,ch in pairs(t) do
		if (ch[dp]) then
			return p
		end
		if (ch) then
			local found = glue.parentbychild(ch, dp)
			if (found) then
				return found
			end
		end
    end
    return nil
end

--- Split a list/array into small parts of given size
---@param list table
---@param chunks number
function glue.chunks(list, chunks)
	local chunkcounter = 0
	local chunk = {}
	local chunklist = {}
	-- Append chunks to the list in the specified amount of elements
	for k,v in pairs(list) do
		if (chunkcounter == chunks) then
			glue.append(chunklist, chunk)
			chunk = {}
			chunkcounter = 0
		end
		glue.append(chunk, v)
		chunkcounter = chunkcounter + 1
	end
	-- If there was a chunk that was not completed append it
	if (chunkcounter ~= 0) then
		glue.append(chunklist, chunk)
	end
	return chunklist
end

--binary search for an insert position that keeps the table sorted.
--works with ffi arrays too if lo and hi are provided.
local cmps = {}
cmps['<' ] = function(t, i, v) return t[i] <  v end
cmps['>' ] = function(t, i, v) return t[i] >  v end
cmps['<='] = function(t, i, v) return t[i] <= v end
cmps['>='] = function(t, i, v) return t[i] >= v end
local less = cmps['<']
function glue.binsearch(v, t, cmp, lo, hi)
	lo, hi = lo or 1, hi or #t
	cmp = cmp and cmps[cmp] or cmp or less
	local len = hi - lo + 1
	if len == 0 then return nil end
	if len == 1 then return not cmp(t, lo, v) and lo or nil end
	while lo < hi do
		local mid = floor(lo + (hi - lo) / 2)
		if cmp(t, mid, v) then
			lo = mid + 1
			if lo == hi and cmp(t, lo, v) then
				return nil
			end
		else
			hi = mid
		end
	end
	return lo
end

--strings --------------------------------------------------------------------

--string submodule. has its own namespace which can be merged with _G.string.
glue.string = {}

--- Split a string list/array given a separator string
function glue.string.split(s, sep)
    if (sep == nil or sep == '') then return 1 end
    local position, array = 0, {}
    for st, sp in function() return string.find(s, sep, position, true) end do
        table.insert(array, string.sub(s, position, st-1))
        position = sp + 1
    end
    table.insert(array, string.sub(s, position))
    return array
end

--split a string by a separator that can be a pattern or a plain string.
--return a stateless iterator for the pieces.
local function iterate_once(s, s1)
	return s1 == nil and s or nil
end
function glue.string.gsplit(s, sep, start, plain)
	start = start or 1
	plain = plain or false
	if not s:find(sep, start, plain) then
		return iterate_once, s:sub(start)
	end
	local done = false
	local function pass(i, j, ...)
		if i then
			local seg = s:sub(start, i - 1)
			start = j + 1
			return seg, ...
		else
			done = true
			return s:sub(start)
		end
	end
	return function()
		if done then return end
		if sep == '' then done = true; return s:sub(start) end
		return pass(s:find(sep, start, plain))
	end
end

--split a string into lines, optionally including the line terminator.
function glue.lines(s, opt)
	local term = opt == '*L'
	local patt = term and '([^\r\n]*()\r?\n?())' or '([^\r\n]*)()\r?\n?()'
	local next_match = s:gmatch(patt)
	local empty = s == ''
	local ended --string ended with no line ending
	return function()
		local s, i1, i2 = next_match()
		if s == nil then return end
		if s == '' and not empty and ended then s = nil end
		ended = i1 == i2
		return s
	end
end

--string trim12 from lua wiki.
function glue.string.trim(s)
	local from = s:match('^%s*()')
	return from > #s and '' or s:match('.*%S', from)
end

--escape a string so that it can be matched literally inside a pattern.
local function format_ci_pat(c)
	return ('[%s%s]'):format(c:lower(), c:upper())
end
function glue.string.esc(s, mode) --escape is a reserved word in Terra
	s = s:gsub('%%','%%%%'):gsub('%z','%%z')
		:gsub('([%^%$%(%)%.%[%]%*%+%-%?])', '%%%1')
	if mode == '*i' then s = s:gsub('[%a]', format_ci_pat) end
	return s
end

--string or number to hex.
function glue.string.tohex(s, upper)
	if type(s) == 'number' then
		return (upper and '%08.8X' or '%08.8x'):format(s)
	end
	if upper then
		return (s:gsub('.', function(c)
		  return ('%02X'):format(c:byte())
		end))
	else
		return (s:gsub('.', function(c)
		  return ('%02x'):format(c:byte())
		end))
	end
end

--hex to binary string.
function glue.string.fromhex(s)
	if #s % 2 == 1 then
		return glue.string.fromhex('0'..s)
	end
	return (s:gsub('..', function(cc)
	  return string.char(tonumber(cc, 16))
	end))
end

function glue.string.starts(s, p) --5x faster than s:find'^...' in LuaJIT 2.1
	return s:sub(1, #p) == p
end

function glue.string.ends(s, p)
	return p == '' or s:sub(-#p) == p
end

function glue.string.subst(s, t) --subst('{foo} {bar}', {foo=1, bar=2}) -> '1 2'
	return s:gsub('{([_%w]+)}', t)
end

--publish the string submodule in the glue namespace.
glue.update(glue, glue.string)

--iterators ------------------------------------------------------------------

--run an iterator and collect the n-th return value into a list.
local function select_at(i,...)
	return ...,select(i,...)
end
local function collect_at(i,f,s,v)
	local t = {}
	repeat
		v,t[#t+1] = select_at(i,f(s,v))
	until v == nil
	return t
end
local function collect_first(f,s,v)
	local t = {}
	repeat
		v = f(s,v); t[#t+1] = v
	until v == nil
	return t
end
function glue.collect(n,...)
	if type(n) == 'number' then
		return collect_at(n,...)
	else
		return collect_first(n,...)
	end
end

--closures -------------------------------------------------------------------

--no-op filters.
function glue.pass(...) return ... end
function glue.noop() return end

--memoize for 0, 1, 2-arg and vararg and 1 retval functions.
local function memoize0(fn) --for strict no-arg functions
	local v, stored
	return function()
		if not stored then
			v = fn(); stored = true
		end
		return v
	end
end
local nilkey = {}
local nankey = {}
local function memoize1(fn) --for strict single-arg functions
	local cache = {}
	return function(arg)
		local k = arg == nil and nilkey or arg ~= arg and nankey or arg
		local v = cache[k]
		if v == nil then
			v = fn(arg); cache[k] = v == nil and nilkey or v
		else
			if v == nilkey then v = nil end
		end
		return v
	end
end
local function memoize2(fn) --for strict two-arg functions
	local cache = {}
	return function(a1, a2)
		local k1 = a1 ~= a1 and nankey or a1 == nil and nilkey or a1
		local cache2 = cache[k1]
		if cache2 == nil then
			cache2 = {}
			cache[k1] = cache2
		end
		local k2 = a2 ~= a2 and nankey or a2 == nil and nilkey or a2
		local v = cache2[k2]
		if v == nil then
			v = fn(a1, a2)
			cache2[k2] = v == nil and nilkey or v
		else
			if v == nilkey then v = nil end
		end
		return v
	end
end
local function memoize_vararg(fn, minarg, maxarg)
	local cache = {}
	local values = {}
	return function(...)
		local key = cache
		local narg = min(max(select('#',...), minarg), maxarg)
		for i = 1, narg do
			local a = select(i,...)
			local k = a ~= a and nankey or a == nil and nilkey or a
			local t = key[k]
			if not t then
				t = {}; key[k] = t
			end
			key = t
		end
		local v = values[key]
		if v == nil then
			v = fn(...); values[key] = v == nil and nilkey or v
		end
		if v == nilkey then v = nil end
		return v
	end
end
local memoize_narg = {[0] = memoize0, memoize1, memoize2}
local function choose_memoize_func(func, narg)
	if narg then
		local memoize_narg = memoize_narg[narg]
		if memoize_narg then
			return memoize_narg
		else
			return memoize_vararg, narg, narg
		end
	else
		local info = debug.getinfo(func, 'u')
		if info.isvararg then
			return memoize_vararg, info.nparams, 1/0
		else
			return choose_memoize_func(func, info.nparams)
		end
	end
end
function glue.memoize(func, narg)
	local memoize, minarg, maxarg = choose_memoize_func(func, narg)
	return memoize(func, minarg, maxarg)
end

--memoize a function with multiple return values.
function glue.memoize_multiret(func, narg)
	local memoize, minarg, maxarg = choose_memoize_func(func, narg)
	local function wrapper(...)
		return glue.pack(func(...))
	end
	local func = memoize(wrapper, minarg, maxarg)
	return function(...)
		return glue.unpack(func(...))
	end
end

local tuple_mt = {__call = glue.unpack}
function tuple_mt:__tostring()
	local t = {}
	for i=1,self.n do
		t[i] = tostring(self[i])
	end
	return string.format('(%s)', table.concat(t, ', '))
end
function glue.tuples(narg)
	return glue.memoize(function(...)
		return setmetatable(glue.pack(...), tuple_mt)
	end)
end

--objects --------------------------------------------------------------------

--set up dynamic inheritance by creating or updating a table's metatable.
function glue.inherit(t, parent)
	local meta = getmetatable(t)
	if meta then
		meta.__index = parent
	elseif parent ~= nil then
		setmetatable(t, {__index = parent})
	end
	return t
end

--prototype-based dynamic inheritance with __call constructor.
function glue.object(super, o, ...)
	o = o or {}
	o.__index = super
	o.__call = super and super.__call
	glue.update(o, ...) --add mixins, defaults, etc.
	return setmetatable(o, o)
end

local function install(self, combine, method_name, hook)
	rawset(self, method_name, combine(self[method_name], hook))
end
local function before(method, hook)
	if method then
		return function(self, ...)
			hook(self, ...)
			return method(self, ...)
		end
	else
		return hook
	end
end
function glue.before(self, method_name, hook)
	install(self, before, method_name, hook)
end
local function after(method, hook)
	if method then
		return function(self, ...)
			method(self, ...)
			return hook(self, ...)
		end
	else
		return hook
	end
end
function glue.after(self, method_name, hook)
	install(self, after, method_name, hook)
end
local function override(method, hook)
	local method = method or glue.noop
	return function(...)
		return hook(method, ...)
	end
end
function glue.override(self, method_name, hook)
	install(self, override, method_name, hook)
end

--return a metatable that supports virtual properties.
--can be used with setmetatable() and ffi.metatype().
function glue.gettersandsetters(getters, setters, super)
	local get = getters and function(t, k)
		local get = getters[k]
		if get then return get(t) end
		return super and super[k]
	end
	local set = setters and function(t, k, v)
		local set = setters[k]
		if set then set(t, v); return end
		rawset(t, k, v)
	end
	return {__index = get, __newindex = set}
end

--i/o ------------------------------------------------------------------------

--check if a file exists and can be opened for reading or writing.
function glue.canopen(name, mode)
	local f = io.open(name, mode or 'rb')
	if f then f:close() end
	return f ~= nil and name or nil
end

--read a file into a string (in binary mode by default).
function glue.readfile(name, mode, open)
	open = open or io.open
	local f, err = open(name, mode=='t' and 'r' or 'rb')
	if not f then return nil, err end
	local s, err = f:read'*a'
	if s == nil then return nil, err end
	f:close()
	return s
end

--read the output of a command into a string.
function glue.readpipe(cmd, mode, open)
	return glue.readfile(cmd, mode, open or io.popen)
end

--like os.rename() but behaves like POSIX on Windows too.
if jit then

	local ffi = require'ffi'

	if ffi.os == 'Windows' then

		ffi.cdef[[
			int MoveFileExA(
				const char *lpExistingFileName,
				const char *lpNewFileName,
				unsigned long dwFlags
			);
			int GetLastError(void);
		]]

		local MOVEFILE_REPLACE_EXISTING = 1
		local MOVEFILE_WRITE_THROUGH    = 8
		local ERROR_FILE_EXISTS         = 80
		local ERROR_ALREADY_EXISTS      = 183

		function glue.replacefile(oldfile, newfile)
			if ffi.C.MoveFileExA(oldfile, newfile, 0) ~= 0 then
				return true
			end
			local err = ffi.C.GetLastError()
			if err == ERROR_FILE_EXISTS or err == ERROR_ALREADY_EXISTS then
				if ffi.C.MoveFileExA(oldfile, newfile,
					bit.bor(MOVEFILE_WRITE_THROUGH, MOVEFILE_REPLACE_EXISTING)) ~= 0
				then
					return true
				end
				err = ffi.C.GetLastError()
			end
			return nil, 'WinAPI error '..err
		end

	else

		function glue.replacefile(oldfile, newfile)
			return os.rename(oldfile, newfile)
		end

	end

end

--write a string, number, table or the results of a read function to a file.
--uses binary mode by default.
function glue.writefile(filename, s, mode, tmpfile)
	if tmpfile then
		local ok, err = glue.writefile(tmpfile, s, mode)
		if not ok then
			return nil, err
		end
		local ok, err = glue.replacefile(tmpfile, filename)
		if not ok then
			os.remove(tmpfile)
			return nil, err
		else
			return true
		end
	end
	local f, err = io.open(filename, mode=='t' and 'w' or 'wb')
	if not f then
		return nil, err
	end
	local ok, err
	if type(s) == 'table' then
		for i = 1, #s do
			ok, err = f:write(s[i])
			if not ok then break end
		end
	elseif type(s) == 'function' then
		local read = s
		while true do
			ok, err = xpcall(read, debug.traceback)
			if not ok or err == nil then break end
			ok, err = f:write(err)
			if not ok then break end
		end
	else --string or number
		ok, err = f:write(s)
	end
	f:close()
	if not ok then
		os.remove(filename)
		return nil, err
	else
		return true
	end
end

--virtualize the print function.
function glue.printer(out, format)
	format = format or tostring
	return function(...)
		local n = select('#', ...)
		for i=1,n do
			out(format((select(i, ...))))
			if i < n then
				out'\t'
			end
		end
		out'\n'
	end
end

--dates & timestamps ---------------------------------------------------------

--compute timestamp diff. to UTC because os.time() has no option for UTC.
function glue.utc_diff(t)
   local d1 = os.date( '*t', 3600 * 24 * 10)
   local d2 = os.date('!*t', 3600 * 24 * 10)
	d1.isdst = false
	return os.difftime(os.time(d1), os.time(d2))
end

--overloading os.time to support UTC and get the date components as separate args.
function glue.time(utc, y, m, d, h, M, s, isdst)
	if type(utc) ~= 'boolean' then --shift arg#1
		utc, y, m, d, h, M, s, isdst = nil, utc, y, m, d, h, M, s
	end
	if type(y) == 'table' then
		local t = y
		if utc == nil then utc = t.utc end
		y, m, d, h, M, s, isdst = t.year, t.month, t.day, t.hour, t.min, t.sec, t.isdst
	end
	local utc_diff = utc and glue.utc_diff() or 0
	if not y then
		return os.time() + utc_diff
	else
		s = s or 0
		local t = os.time{year = y, month = m or 1, day = d or 1, hour = h or 0,
			min = M or 0, sec = s, isdst = isdst}
		return t and t + s - floor(s) + utc_diff
	end
end

--get the time at the start of the week of a given time, plus/minus a number of weeks.
function glue.sunday(utc, t, offset)
	if type(utc) ~= 'boolean' then --shift arg#1
		utc, t, offset = false, utc, t
	end
	local d = os.date(utc and '!*t' or '*t', t)
	return glue.time(false, d.year, d.month, d.day - (d.wday - 1) + (offset or 0) * 7)
end

--get the time at the start of the day of a given time, plus/minus a number of days.
function glue.day(utc, t, offset)
	if type(utc) ~= 'boolean' then --shift arg#1
		utc, t, offset = false, utc, t
	end
	local d = os.date(utc and '!*t' or '*t', t)
	return glue.time(false, d.year, d.month, d.day + (offset or 0))
end

--get the time at the start of the month of a given time, plus/minus a number of months.
function glue.month(utc, t, offset)
	if type(utc) ~= 'boolean' then --shift arg#1
		utc, t, offset = false, utc, t
	end
	local d = os.date(utc and '!*t' or '*t', t)
	return glue.time(false, d.year, d.month + (offset or 0))
end

--get the time at the start of the year of a given time, plus/minus a number of years.
function glue.year(utc, t, offset)
	if type(utc) ~= 'boolean' then --shift arg#1
		utc, t, offset = false, utc, t
	end
	local d = os.date(utc and '!*t' or '*t', t)
	return glue.time(false, d.year + (offset or 0))
end

--error handling -------------------------------------------------------------

--allocation-free assert() with string formatting.
--NOTE: unlike standard assert(), this only returns the first argument
--to avoid returning the error message and it's args along with it so don't
--use it with functions returning multiple values when you want those values.
function glue.assert(v, err, ...)
	if v then return v end
	err = err or 'assertion failed!'
	if select('#',...) > 0 then
		err = string.format(err, ...)
	end
	error(err, 2)
end

--pcall with traceback. LuaJIT and Lua 5.2 only.
local function pcall_error(e)
	return debug.traceback('\n'..tostring(e))
end
function glue.pcall(f, ...)
	return xpcall(f, pcall_error, ...)
end

local function unprotect(ok, result, ...)
	if not ok then return nil, result, ... end
	if result == nil then result = true end --to distinguish from error.
	return result, ...
end

--wrap a function that raises errors on failure into a function that follows
--the Lua convention of returning nil,err on failure.
function glue.protect(func)
	return function(...)
		return unprotect(pcall(func, ...))
	end
end

--pcall with finally and except "clauses":
--		local ret,err = fpcall(function(finally, except)
--			local foo = getfoo()
--			finally(function() foo:free() end)
--			except(function(err) io.stderr:write(err, '\n') end)
--		emd)
--NOTE: a bit bloated at 2 tables and 4 closures. Can we reduce the overhead?
local function fpcall(f,...)
	local fint, errt = {}, {}
	local function finally(f) fint[#fint+1] = f end
	local function onerror(f) errt[#errt+1] = f end
	local function err(e)
		for i=#errt,1,-1 do errt[i](e) end
		for i=#fint,1,-1 do fint[i]() end
		return tostring(e) .. '\n' .. debug.traceback()
	end
	local function pass(ok,...)
		if ok then
			for i=#fint,1,-1 do fint[i]() end
		end
		return ok,...
	end
	return pass(xpcall(f, err, finally, onerror, ...))
end

function glue.fpcall(...)
	return unprotect(fpcall(...))
end

--fcall is like fpcall() but without the protection (i.e. raises errors).
local function assert_fpcall(ok, ...)
	if not ok then error(..., 2) end
	return ...
end
function glue.fcall(...)
	return assert_fpcall(fpcall(...))
end

--modules --------------------------------------------------------------------

--create a module table that dynamically inherits another module.
--naming the module returns the same module table for the same name.
function glue.module(name, parent)
	if type(name) ~= 'string' then
		name, parent = parent, name
	end
	if type(parent) == 'string' then
		parent = require(parent)
	end
	parent = parent or _M
	local parent_P = parent and assert(parent._P, 'parent module has no _P') or _G
	local M = package.loaded[name]
	if M then
		return M, M._P
	end
	local P = {__index = parent_P}
	M = {__index = parent, _P = P}
	P._M = M
	M._M = M
	P._P = P
	setmetatable(P, P)
	setmetatable(M, M)
	if name then
		package.loaded[name] = M
		P[name] = M
	end
	setfenv(2, P)
	return M, P
end

--setup a module to load sub-modules when accessing specific keys.
function glue.autoload(t, k, v)
	local mt = getmetatable(t) or {}
	if not mt.__autoload then
		local old_index = mt.__index
	 	local submodules = {}
		mt.__autoload = submodules
		mt.__index = function(t, k)
			--overriding __index...
			if type(old_index) == 'function' then
				local v = old_index(t, k)
				if v ~= nil then return v end
			elseif type(old_index) == 'table' then
				local v = old_index[k]
				if v ~= nil then return v end
			end
			if submodules[k] then
				local mod
				if type(submodules[k]) == 'string' then
					mod = require(submodules[k]) --module
				else
					mod = submodules[k](k) --custom loader
				end
				submodules[k] = nil --prevent loading twice
				if type(mod) == 'table' then --submodule returned its module table
					assert(mod[k] ~= nil) --submodule has our symbol
					t[k] = mod[k]
				end
				return rawget(t, k)
			end
		end
		setmetatable(t, mt)
	end
	if type(k) == 'table' then
		glue.update(mt.__autoload, k) --multiple key -> module associations.
	else
		mt.__autoload[k] = v --single key -> module association.
	end
	return t
end

--portable way to get script's directory, based on arg[0].
--NOTE: the path is not absolute, but relative to the current directory!
--NOTE: for bundled executables, this returns the executable's directory.
local dir = rawget(_G, 'arg') and arg[0]
	and arg[0]:gsub('[/\\]?[^/\\]+$', '') or '' --remove file name
glue.bin = dir == '' and '.' or dir

--portable way to add more paths to package.path, at any place in the list.
--negative indices count from the end of the list like string.sub().
--index 'after' means 0.
function glue.luapath(path, index, ext)
	ext = ext or 'lua'
	index = index or 1
	local psep = package.config:sub(1,1) --'/'
	local tsep = package.config:sub(3,3) --';'
	local wild = package.config:sub(5,5) --'?'
	local paths = glue.collect(glue.gsplit(package.path, tsep, nil, true))
	path = path:gsub('[/\\]', psep) --normalize slashes
	if index == 'after' then index = 0 end
	if index < 1 then index = #paths + 1 + index end
	table.insert(paths, index,  path .. psep .. wild .. psep .. 'init.' .. ext)
	table.insert(paths, index,  path .. psep .. wild .. '.' .. ext)
	package.path = table.concat(paths, tsep)
end

--portable way to add more paths to package.cpath, at any place in the list.
--negative indices count from the end of the list like string.sub().
--index 'after' means 0.
function glue.cpath(path, index)
	index = index or 1
	local psep = package.config:sub(1,1) --'/'
	local tsep = package.config:sub(3,3) --';'
	local wild = package.config:sub(5,5) --'?'
	local ext = package.cpath:match('%.([%a]+)%'..tsep..'?') --dll | so | dylib
	local paths = glue.collect(glue.gsplit(package.cpath, tsep, nil, true))
	path = path:gsub('[/\\]', psep) --normalize slashes
	if index == 'after' then index = 0 end
	if index < 1 then index = #paths + 1 + index end
	table.insert(paths, index,  path .. psep .. wild .. '.' .. ext)
	package.cpath = table.concat(paths, tsep)
end

--allocation -----------------------------------------------------------------

--freelist for Lua tables.
local function create_table()
	return {}
end
function glue.freelist(create, destroy)
	create = create or create_table
	destroy = destroy or glue.noop
	local t = {}
	local n = 0
	local function alloc()
		local e = t[n]
		if e then
			t[n] = false
			n = n - 1
		end
		return e or create()
	end
	local function free(e)
		destroy(e)
		n = n + 1
		t[n] = e
	end
	return alloc, free
end

--ffi ------------------------------------------------------------------------

if jit then

local ffi = require'ffi'

--static, auto-growing buffer allocation pattern (ctype must be vla).
function glue.buffer(ctype)
	local vla = ffi.typeof(ctype)
	local buf, len = nil, -1
	return function(minlen)
		if minlen == false then
			buf, len = nil, -1
		elseif minlen > len then
			len = glue.nextpow2(minlen)
			buf = vla(len)
		end
		return buf, len
	end
end

--like glue.buffer() but preserves data on reallocations
--also returns minlen instead of capacity.
function glue.dynarray(ctype)
	local buffer = glue.buffer(ctype)
	local elem_size = ffi.sizeof(ctype, 1)
	local buf0, minlen0
	return function(minlen)
		local buf, len = buffer(minlen)
		if buf ~= buf0 and buf ~= nil and buf0 ~= nil then
			ffi.copy(buf, buf0, minlen0 * elem_size)
		end
		buf0, minlen0 = buf, minlen
		return buf, minlen
	end
end

local intptr_ct = ffi.typeof'intptr_t'
local intptrptr_ct = ffi.typeof'const intptr_t*'
local intptr1_ct = ffi.typeof'intptr_t[1]'
local voidptr_ct = ffi.typeof'void*'

--x86: convert a pointer's address to a Lua number.
local function addr32(p)
	return tonumber(ffi.cast(intptr_ct, ffi.cast(voidptr_ct, p)))
end

--x86: convert a number to a pointer, optionally specifying a ctype.
local function ptr32(ctype, addr)
	if not addr then
		ctype, addr = voidptr_ct, ctype
	end
	return ffi.cast(ctype, addr)
end

--x64: convert a pointer's address to a Lua number or possibly string.
local function addr64(p)
	local np = ffi.cast(intptr_ct, ffi.cast(voidptr_ct, p))
   local n = tonumber(np)
	if ffi.cast(intptr_ct, n) ~= np then
		--address too big (ASLR? tagged pointers?): convert to string.
		return ffi.string(intptr1_ct(np), 8)
	end
	return n
end

--x64: convert a number or string to a pointer, optionally specifying a ctype.
local function ptr64(ctype, addr)
	if not addr then
		ctype, addr = voidptr_ct, ctype
	end
	if type(addr) == 'string' then
		return ffi.cast(ctype, ffi.cast(voidptr_ct,
			ffi.cast(intptrptr_ct, addr)[0]))
	else
		return ffi.cast(ctype, addr)
	end
end

glue.addr = ffi.abi'64bit' and addr64 or addr32
glue.ptr = ffi.abi'64bit' and ptr64 or ptr32

end --if jit

if bit then

	local band, bor, bnot = bit.band, bit.bor, bit.bnot

	--extract the bool value of a bitmask from a value.
	function glue.getbit(from, mask)
		return band(from, mask) == mask
	end

	--set a single bit of a value without affecting other bits.
	function glue.setbit(over, mask, yes)
		return bor(yes and mask or 0, band(over, bnot(mask)))
	end

	local function bor_bit(bits, k, mask, strict)
		local b = bits[k]
		if b then
			return bit.bor(mask, b)
		elseif strict then
			error(string.format('invalid bit %s', k))
		else
			return mask
		end
	end
	function glue.bor(flags, bits, strict)
		local mask = 0
		if type(flags) == 'number' then
			return flags --passthrough
		elseif type(flags) == 'string' then
			for k in flags:gmatch'[^%s]+' do
				mask = bor_bit(bits, k, mask, strict)
			end
		elseif type(flags) == 'table' then
			for k,v in pairs(flags) do
				k = type(k) == 'number' and v or k
				mask = bor_bit(bits, k, mask, strict)
			end
		else
			error'flags expected'
		end
		return mask
	end

end

return glue

end,

["inspect"] = function()
--------------------
-- Module: 'inspect'
--------------------
local inspect ={
  _VERSION = 'inspect.lua 3.1.0',
  _URL     = 'http://github.com/kikito/inspect.lua',
  _DESCRIPTION = 'human-readable representations of tables',
  _LICENSE = [[
    MIT LICENSE

    Copyright (c) 2013 Enrique García Cota

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
}

local tostring = tostring

inspect.KEY       = setmetatable({}, {__tostring = function() return 'inspect.KEY' end})
inspect.METATABLE = setmetatable({}, {__tostring = function() return 'inspect.METATABLE' end})

local function rawpairs(t)
  return next, t, nil
end

-- Apostrophizes the string if it has quotes, but not aphostrophes
-- Otherwise, it returns a regular quoted string
local function smartQuote(str)
  if str:match('"') and not str:match("'") then
    return "'" .. str .. "'"
  end
  return '"' .. str:gsub('"', '\\"') .. '"'
end

-- \a => '\\a', \0 => '\\0', 31 => '\31'
local shortControlCharEscapes = {
  ["\a"] = "\\a",  ["\b"] = "\\b", ["\f"] = "\\f", ["\n"] = "\\n",
  ["\r"] = "\\r",  ["\t"] = "\\t", ["\v"] = "\\v"
}
local longControlCharEscapes = {} -- \a => nil, \0 => \000, 31 => \031
for i=0, 31 do
  local ch = string.char(i)
  if not shortControlCharEscapes[ch] then
    shortControlCharEscapes[ch] = "\\"..i
    longControlCharEscapes[ch]  = string.format("\\%03d", i)
  end
end

local function escape(str)
  return (str:gsub("\\", "\\\\")
             :gsub("(%c)%f[0-9]", longControlCharEscapes)
             :gsub("%c", shortControlCharEscapes))
end

local function isIdentifier(str)
  return type(str) == 'string' and str:match( "^[_%a][_%a%d]*$" )
end

local function isSequenceKey(k, sequenceLength)
  return type(k) == 'number'
     and 1 <= k
     and k <= sequenceLength
     and math.floor(k) == k
end

local defaultTypeOrders = {
  ['number']   = 1, ['boolean']  = 2, ['string'] = 3, ['table'] = 4,
  ['function'] = 5, ['userdata'] = 6, ['thread'] = 7
}

local function sortKeys(a, b)
  local ta, tb = type(a), type(b)

  -- strings and numbers are sorted numerically/alphabetically
  if ta == tb and (ta == 'string' or ta == 'number') then return a < b end

  local dta, dtb = defaultTypeOrders[ta], defaultTypeOrders[tb]
  -- Two default types are compared according to the defaultTypeOrders table
  if dta and dtb then return defaultTypeOrders[ta] < defaultTypeOrders[tb]
  elseif dta     then return true  -- default types before custom ones
  elseif dtb     then return false -- custom types after default ones
  end

  -- custom types are sorted out alphabetically
  return ta < tb
end

-- For implementation reasons, the behavior of rawlen & # is "undefined" when
-- tables aren't pure sequences. So we implement our own # operator.
local function getSequenceLength(t)
  local len = 1
  local v = rawget(t,len)
  while v ~= nil do
    len = len + 1
    v = rawget(t,len)
  end
  return len - 1
end

local function getNonSequentialKeys(t)
  local keys, keysLength = {}, 0
  local sequenceLength = getSequenceLength(t)
  for k,_ in rawpairs(t) do
    if not isSequenceKey(k, sequenceLength) then
      keysLength = keysLength + 1
      keys[keysLength] = k
    end
  end
  table.sort(keys, sortKeys)
  return keys, keysLength, sequenceLength
end

local function countTableAppearances(t, tableAppearances)
  tableAppearances = tableAppearances or {}

  if type(t) == 'table' then
    if not tableAppearances[t] then
      tableAppearances[t] = 1
      for k,v in rawpairs(t) do
        countTableAppearances(k, tableAppearances)
        countTableAppearances(v, tableAppearances)
      end
      countTableAppearances(getmetatable(t), tableAppearances)
    else
      tableAppearances[t] = tableAppearances[t] + 1
    end
  end

  return tableAppearances
end

local copySequence = function(s)
  local copy, len = {}, #s
  for i=1, len do copy[i] = s[i] end
  return copy, len
end

local function makePath(path, ...)
  local keys = {...}
  local newPath, len = copySequence(path)
  for i=1, #keys do
    newPath[len + i] = keys[i]
  end
  return newPath
end

local function processRecursive(process, item, path, visited)
  if item == nil then return nil end
  if visited[item] then return visited[item] end

  local processed = process(item, path)
  if type(processed) == 'table' then
    local processedCopy = {}
    visited[item] = processedCopy
    local processedKey

    for k,v in rawpairs(processed) do
      processedKey = processRecursive(process, k, makePath(path, k, inspect.KEY), visited)
      if processedKey ~= nil then
        processedCopy[processedKey] = processRecursive(process, v, makePath(path, processedKey), visited)
      end
    end

    local mt  = processRecursive(process, getmetatable(processed), makePath(path, inspect.METATABLE), visited)
    if type(mt) ~= 'table' then mt = nil end -- ignore not nil/table __metatable field
    setmetatable(processedCopy, mt)
    processed = processedCopy
  end
  return processed
end



-------------------------------------------------------------------

local Inspector = {}
local Inspector_mt = {__index = Inspector}

function Inspector:puts(...)
  local args   = {...}
  local buffer = self.buffer
  local len    = #buffer
  for i=1, #args do
    len = len + 1
    buffer[len] = args[i]
  end
end

function Inspector:down(f)
  self.level = self.level + 1
  f()
  self.level = self.level - 1
end

function Inspector:tabify()
  self:puts(self.newline, string.rep(self.indent, self.level))
end

function Inspector:alreadyVisited(v)
  return self.ids[v] ~= nil
end

function Inspector:getId(v)
  local id = self.ids[v]
  if not id then
    local tv = type(v)
    id              = (self.maxIds[tv] or 0) + 1
    self.maxIds[tv] = id
    self.ids[v]     = id
  end
  return tostring(id)
end

function Inspector:putKey(k)
  if isIdentifier(k) then return self:puts(k) end
  self:puts("[")
  self:putValue(k)
  self:puts("]")
end

function Inspector:putTable(t)
  if t == inspect.KEY or t == inspect.METATABLE then
    self:puts(tostring(t))
  elseif self:alreadyVisited(t) then
    self:puts('<table ', self:getId(t), '>')
  elseif self.level >= self.depth then
    self:puts('{...}')
  else
    if self.tableAppearances[t] > 1 then self:puts('<', self:getId(t), '>') end

    local nonSequentialKeys, nonSequentialKeysLength, sequenceLength = getNonSequentialKeys(t)
    local mt                = getmetatable(t)

    self:puts('{')
    self:down(function()
      local count = 0
      for i=1, sequenceLength do
        if count > 0 then self:puts(',') end
        self:puts(' ')
        self:putValue(t[i])
        count = count + 1
      end

      for i=1, nonSequentialKeysLength do
        local k = nonSequentialKeys[i]
        if count > 0 then self:puts(',') end
        self:tabify()
        self:putKey(k)
        self:puts(' = ')
        self:putValue(t[k])
        count = count + 1
      end

      if type(mt) == 'table' then
        if count > 0 then self:puts(',') end
        self:tabify()
        self:puts('<metatable> = ')
        self:putValue(mt)
      end
    end)

    if nonSequentialKeysLength > 0 or type(mt) == 'table' then -- result is multi-lined. Justify closing }
      self:tabify()
    elseif sequenceLength > 0 then -- array tables have one extra space before closing }
      self:puts(' ')
    end

    self:puts('}')
  end
end

function Inspector:putValue(v)
  local tv = type(v)

  if tv == 'string' then
    self:puts(smartQuote(escape(v)))
  elseif tv == 'number' or tv == 'boolean' or tv == 'nil' or
         tv == 'cdata' or tv == 'ctype' then
    self:puts(tostring(v))
  elseif tv == 'table' then
    self:putTable(v)
  else
    self:puts('<', tv, ' ', self:getId(v), '>')
  end
end

-------------------------------------------------------------------

function inspect.inspect(root, options)
  options       = options or {}

  local depth   = options.depth   or math.huge
  local newline = options.newline or '\n'
  local indent  = options.indent  or '  '
  local process = options.process

  if process then
    root = processRecursive(process, root, {}, {})
  end

  local inspector = setmetatable({
    depth            = depth,
    level            = 0,
    buffer           = {},
    ids              = {},
    maxIds           = {},
    newline          = newline,
    indent           = indent,
    tableAppearances = countTableAppearances(root)
  }, Inspector_mt)

  inspector:putValue(root)

  return table.concat(inspector.buffer)
end

setmetatable(inspect, { __call = function(_, ...) return inspect.inspect(...) end })

return inspect


end,

["json"] = function()
--------------------
-- Module: 'json'
--------------------
--
-- json.lua
--
-- Copyright (c) 2019 rxi
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

local json = { _version = "0.1.2" }

-------------------------------------------------------------------------------
-- Encode
-------------------------------------------------------------------------------

local encode

local escape_char_map = {
  [ "\\" ] = "\\\\",
  [ "\"" ] = "\\\"",
  [ "\b" ] = "\\b",
  [ "\f" ] = "\\f",
  [ "\n" ] = "\\n",
  [ "\r" ] = "\\r",
  [ "\t" ] = "\\t",
}

local escape_char_map_inv = { [ "\\/" ] = "/" }
for k, v in pairs(escape_char_map) do
  escape_char_map_inv[v] = k
end


local function escape_char(c)
  return escape_char_map[c] or string.format("\\u%04x", c:byte())
end


local function encode_nil(val)
  return "null"
end


local function encode_table(val, stack)
  local res = {}
  stack = stack or {}

  -- Circular reference?
  if stack[val] then error("circular reference") end

  stack[val] = true

  if rawget(val, 1) ~= nil or next(val) == nil then
    -- Treat as array -- check keys are valid and it is not sparse
    local n = 0
    for k in pairs(val) do
      if type(k) ~= "number" then
        error("invalid table: mixed or invalid key types")
      end
      n = n + 1
    end
    if n ~= #val then
      error("invalid table: sparse array")
    end
    -- Encode
    for i, v in ipairs(val) do
      table.insert(res, encode(v, stack))
    end
    stack[val] = nil
    return "[" .. table.concat(res, ",") .. "]"

  else
    -- Treat as an object
    for k, v in pairs(val) do
      if type(k) ~= "string" then
        error("invalid table: mixed or invalid key types")
      end
      table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
    end
    stack[val] = nil
    return "{" .. table.concat(res, ",") .. "}"
  end
end


local function encode_string(val)
  return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end


local function encode_number(val)
  -- Check for NaN, -inf and inf
  if val ~= val or val <= -math.huge or val >= math.huge then
    error("unexpected number value '" .. tostring(val) .. "'")
  end
  return string.format("%.14g", val)
end


local type_func_map = {
  [ "nil"     ] = encode_nil,
  [ "table"   ] = encode_table,
  [ "string"  ] = encode_string,
  [ "number"  ] = encode_number,
  [ "boolean" ] = tostring,
}


encode = function(val, stack)
  local t = type(val)
  local f = type_func_map[t]
  if f then
    return f(val, stack)
  end
  error("unexpected type '" .. t .. "'")
end


function json.encode(val)
  return ( encode(val) )
end


-------------------------------------------------------------------------------
-- Decode
-------------------------------------------------------------------------------

local parse

local function create_set(...)
  local res = {}
  for i = 1, select("#", ...) do
    res[ select(i, ...) ] = true
  end
  return res
end

local space_chars   = create_set(" ", "\t", "\r", "\n")
local delim_chars   = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
local escape_chars  = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
local literals      = create_set("true", "false", "null")

local literal_map = {
  [ "true"  ] = true,
  [ "false" ] = false,
  [ "null"  ] = nil,
}


local function next_char(str, idx, set, negate)
  for i = idx, #str do
    if set[str:sub(i, i)] ~= negate then
      return i
    end
  end
  return #str + 1
end


local function decode_error(str, idx, msg)
  local line_count = 1
  local col_count = 1
  for i = 1, idx - 1 do
    col_count = col_count + 1
    if str:sub(i, i) == "\n" then
      line_count = line_count + 1
      col_count = 1
    end
  end
  error( string.format("%s at line %d col %d", msg, line_count, col_count) )
end


local function codepoint_to_utf8(n)
  -- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
  local f = math.floor
  if n <= 0x7f then
    return string.char(n)
  elseif n <= 0x7ff then
    return string.char(f(n / 64) + 192, n % 64 + 128)
  elseif n <= 0xffff then
    return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
  elseif n <= 0x10ffff then
    return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128,
                       f(n % 4096 / 64) + 128, n % 64 + 128)
  end
  error( string.format("invalid unicode codepoint '%x'", n) )
end


local function parse_unicode_escape(s)
  local n1 = tonumber( s:sub(3, 6),  16 )
  local n2 = tonumber( s:sub(9, 12), 16 )
  -- Surrogate pair?
  if n2 then
    return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
  else
    return codepoint_to_utf8(n1)
  end
end


local function parse_string(str, i)
  local has_unicode_escape = false
  local has_surrogate_escape = false
  local has_escape = false
  local last
  for j = i + 1, #str do
    local x = str:byte(j)

    if x < 32 then
      decode_error(str, j, "control character in string")
    end

    if last == 92 then -- "\\" (escape char)
      if x == 117 then -- "u" (unicode escape sequence)
        local hex = str:sub(j + 1, j + 5)
        if not hex:find("%x%x%x%x") then
          decode_error(str, j, "invalid unicode escape in string")
        end
        if hex:find("^[dD][89aAbB]") then
          has_surrogate_escape = true
        else
          has_unicode_escape = true
        end
      else
        local c = string.char(x)
        if not escape_chars[c] then
          decode_error(str, j, "invalid escape char '" .. c .. "' in string")
        end
        has_escape = true
      end
      last = nil

    elseif x == 34 then -- '"' (end of string)
      local s = str:sub(i + 1, j - 1)
      if has_surrogate_escape then
        s = s:gsub("\\u[dD][89aAbB]..\\u....", parse_unicode_escape)
      end
      if has_unicode_escape then
        s = s:gsub("\\u....", parse_unicode_escape)
      end
      if has_escape then
        s = s:gsub("\\.", escape_char_map_inv)
      end
      return s, j + 1

    else
      last = x
    end
  end
  decode_error(str, i, "expected closing quote for string")
end


local function parse_number(str, i)
  local x = next_char(str, i, delim_chars)
  local s = str:sub(i, x - 1)
  local n = tonumber(s)
  if not n then
    decode_error(str, i, "invalid number '" .. s .. "'")
  end
  return n, x
end


local function parse_literal(str, i)
  local x = next_char(str, i, delim_chars)
  local word = str:sub(i, x - 1)
  if not literals[word] then
    decode_error(str, i, "invalid literal '" .. word .. "'")
  end
  return literal_map[word], x
end


local function parse_array(str, i)
  local res = {}
  local n = 1
  i = i + 1
  while 1 do
    local x
    i = next_char(str, i, space_chars, true)
    -- Empty / end of array?
    if str:sub(i, i) == "]" then
      i = i + 1
      break
    end
    -- Read token
    x, i = parse(str, i)
    res[n] = x
    n = n + 1
    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = str:sub(i, i)
    i = i + 1
    if chr == "]" then break end
    if chr ~= "," then decode_error(str, i, "expected ']' or ','") end
  end
  return res, i
end


local function parse_object(str, i)
  local res = {}
  i = i + 1
  while 1 do
    local key, val
    i = next_char(str, i, space_chars, true)
    -- Empty / end of object?
    if str:sub(i, i) == "}" then
      i = i + 1
      break
    end
    -- Read key
    if str:sub(i, i) ~= '"' then
      decode_error(str, i, "expected string for key")
    end
    key, i = parse(str, i)
    -- Read ':' delimiter
    i = next_char(str, i, space_chars, true)
    if str:sub(i, i) ~= ":" then
      decode_error(str, i, "expected ':' after key")
    end
    i = next_char(str, i + 1, space_chars, true)
    -- Read value
    val, i = parse(str, i)
    -- Set
    res[key] = val
    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = str:sub(i, i)
    i = i + 1
    if chr == "}" then break end
    if chr ~= "," then decode_error(str, i, "expected '}' or ','") end
  end
  return res, i
end


local char_func_map = {
  [ '"' ] = parse_string,
  [ "0" ] = parse_number,
  [ "1" ] = parse_number,
  [ "2" ] = parse_number,
  [ "3" ] = parse_number,
  [ "4" ] = parse_number,
  [ "5" ] = parse_number,
  [ "6" ] = parse_number,
  [ "7" ] = parse_number,
  [ "8" ] = parse_number,
  [ "9" ] = parse_number,
  [ "-" ] = parse_number,
  [ "t" ] = parse_literal,
  [ "f" ] = parse_literal,
  [ "n" ] = parse_literal,
  [ "[" ] = parse_array,
  [ "{" ] = parse_object,
}


parse = function(str, idx)
  local chr = str:sub(idx, idx)
  local f = char_func_map[chr]
  if f then
    return f(str, idx)
  end
  decode_error(str, idx, "unexpected character '" .. chr .. "'")
end


function json.decode(str)
  if type(str) ~= "string" then
    error("expected argument of type string, got " .. type(str))
  end
  local res, idx = parse(str, next_char(str, 1, space_chars, true))
  idx = next_char(str, idx, space_chars, true)
  if idx <= #str then
    decode_error(str, idx, "trailing garbage")
  end
  return res
end


return json

end,

["lua-redux"] = function()
--------------------
-- Module: 'lua-redux'
--------------------
local ActionTypes = {INIT = "@@lua-redux/INIT"}

local function inverse(table)
    local newTable = {}
    for k, v in pairs(table) do
        newTable[v] = k
    end
    return newTable
end

local function createStore(reducer, preloadedState)
    local store = {
        reducer = reducer,
        state = preloadedState,
        subscribers = {}
    }

    function store:subscribe(callback)
        local i = table.insert(self.subscribers, callback)
        return function()
            table.remove(self.subscribers, inverse(self.subscribers)[callback])
        end
    end
    function store:dispatch(action)
        self.state = self.reducer(self.state, action)
        for k, v in pairs(self.subscribers) do
            v()
        end
    end
    function store:getState()
        return self.state
    end
    function store:replaceReducer(reducer)
        self.reducer = reducer
        self:dispatch({type = ActionTypes.INIT})
    end

    store:dispatch({type = ActionTypes.INIT})

    return store
end

return {
    ActionTypes = ActionTypes,
    createStore = createStore
}

end,

["maethrillian"] = function()
--------------------
-- Module: 'maethrillian'
--------------------
------------------------------------------------------------------------------
-- Maethrillian library
-- Sledmine
-- Version 4.0
-- Encode, decode tools for data manipulation
------------------------------------------------------------------------------
local glue = require "glue"
local maethrillian = {}

--- Compress table data in the given format
---@param inputTable table
---@param requestFormat table
---@param noHex boolean
---@return table
function maethrillian.encodeTable(inputTable, requestFormat, noHex)
    local compressedTable = {}
    for property, value in pairs(inputTable) do
        if (type(value) ~= "table") then
            local expectedProperty
            local encodeFormat
            for formatIndex, format in pairs(requestFormat) do
                if (glue.arrayhas(format, property)) then
                    expectedProperty = format[1]
                    encodeFormat = format[2]
                end
            end
            if (encodeFormat) then
                if (not noHex) then
                    compressedTable[property] = glue.tohex(string.pack(encodeFormat, value))
                else
                    compressedTable[property] = string.pack(encodeFormat, value)
                end
            else
                if (expectedProperty == property) then
                    compressedTable[property] = value
                end
            end
        end
    end
    return compressedTable
end

--- Format table into request string
---@param inputTable table
---@param requestFormat table
---@return string
function maethrillian.tableToRequest(inputTable, requestFormat, separator)
    local requestData = {}
    for property, value in pairs(inputTable) do
        if (requestFormat) then
            for formatIndex, format in pairs(requestFormat) do
                if (glue.arrayhas(format, property)) then
                    requestData[formatIndex] = value
                end
            end
        else
            requestData[#requestData + 1] = value
        end
    end
    return table.concat(requestData, separator)
end

--- Decompress table data given expected encoding format
---@param inputTable table
---@param requestFormat any
function maethrillian.decodeTable(inputTable, requestFormat)
    local dataDecompressed = {}
    for property, encodedValue in pairs(inputTable) do
        -- Get encode format for current value
        local encodeFormat
        for formatIndex, format in pairs(requestFormat) do
            if (glue.arrayhas(format, property)) then
                encodeFormat = format[2]
            end
        end
        if (encodeFormat) then
            -- There is a compression format available
            value = string.unpack(encodeFormat, glue.fromhex(tostring(encodedValue)))
        elseif (tonumber(encodedValue)) then
            -- Convert value into number
            value = tonumber(encodedValue)
        else
            -- Value is just a string
            value = encodedValue
        end
        dataDecompressed[property] = value
    end
    return dataDecompressed
end

--- Transform request into table given
---@param request string
---@param requestFormat table
function maethrillian.requestToTable(request, requestFormat, separator)
    local outputTable = {}
    local splitRequest = glue.string.split(request, separator)
    for index, value in pairs(splitRequest) do
        local currentFormat = requestFormat[index]
        local propertyName = currentFormat[1]
        local encodeFormat = currentFormat[2]
        -- Convert value into number
        local toNumberValue = tonumber(value)
        if (not encodeFormat and toNumberValue) then
            value = toNumberValue
        end
        if (propertyName) then
            outputTable[propertyName] = value
        end
    end
    return outputTable
end

return maethrillian

end,

["blam"] = function()
--------------------
-- Module: 'blam'
--------------------
------------------------------------------------------------------------------
-- Blam! library for Chimera/SAPP Lua scripting
-- Sledmine, JerryBrick
-- Improves memory handle and provides standard functions for scripting
------------------------------------------------------------------------------
local blam = {_VERSION = "1.4.0"}

------------------------------------------------------------------------------
-- Useful functions for internal usage
------------------------------------------------------------------------------

-- From legacy glue library!
--- String or number to hex
local function tohex(s, upper)
    if type(s) == "number" then
        return (upper and "%08.8X" or "%08.8x"):format(s)
    end
    if upper then
        return (s:sub(".", function(c)
            return ("%02X"):format(c:byte())
        end))
    else
        return (s:gsub(".", function(c)
            return ("%02x"):format(c:byte())
        end))
    end
end

--- Hex to binary string
local function fromhex(s)
    if #s % 2 == 1 then
        return fromhex("0" .. s)
    end
    return (s:gsub("..", function(cc)
        return string.char(tonumber(cc, 16))
    end))
end

------------------------------------------------------------------------------
-- Blam! engine data
------------------------------------------------------------------------------

-- Engine address list
local addressList = {
    tagDataHeader = 0x40440000,
    cameraType = 0x00647498, -- from Giraffe
    gamePaused = 0x004ACA79,
    gameOnMenus = 0x00622058,
    joystickInput = 0x64D998, -- from aLTis
    firstPerson = 0x40000EB8, -- from aLTis
    objectTable = 0x400506B4,
    deviceGroupsTable = 0x00816110
}

-- Server side addresses adjustment
if (api_version or server_type == "sapp") then
    addressList.deviceGroupsTable = 0x006E1C50
end

-- Tag classes values
local tagClasses = {
    actorVariant = "actv",
    actor = "actr",
    antenna = "ant!",
    biped = "bipd",
    bitmap = "bitm",
    cameraTrack = "trak",
    colorTable = "colo",
    continuousDamageEffect = "cdmg",
    contrail = "cont",
    damageEffect = "jpt!",
    decal = "deca",
    detailObjectCollection = "dobc",
    deviceControl = "ctrl",
    deviceLightFixture = "lifi",
    deviceMachine = "mach",
    device = "devi",
    dialogue = "udlg",
    effect = "effe",
    equipment = "eqip",
    flag = "flag",
    fog = "fog ",
    font = "font",
    garbage = "garb",
    gbxmodel = "mod2",
    globals = "matg",
    glow = "glw!",
    grenadeHudInterface = "grhi",
    hudGlobals = "hudg",
    hudMessageText = "hmt ",
    hudNumber = "hud#",
    itemCollection = "itmc",
    item = "item",
    lensFlare = "lens",
    lightVolume = "mgs2",
    light = "ligh",
    lightning = "elec",
    materialEffects = "foot",
    meter = "metr",
    modelAnimations = "antr",
    modelCollisiionGeometry = "coll",
    model = "mode",
    multiplayerScenarioDescription = "mply",
    object = "obje",
    particleSystem = "pctl",
    particle = "part",
    physics = "phys",
    placeHolder = "plac",
    pointPhysics = "pphy",
    preferencesNetworkGame = "ngpr",
    projectile = "proj",
    scenarioStructureBsp = "sbsp",
    scenario = "scnr",
    scenery = "scen",
    shaderEnvironment = "senv",
    shaderModel = "soso",
    shaderTransparentChicagoExtended = "scex",
    shaderTransparentChicago = "schi",
    shaderTransparentGeneric = "sotr",
    shaderTransparentGlass = "sgla",
    shaderTransparentMeter = "smet",
    shaderTransparentPlasma = "spla",
    shaderTransparentWater = "swat",
    shader = "shdr",
    sky = "sky ",
    soundEnvironment = "snde",
    soundLooping = "lsnd",
    soundScenery = "ssce",
    sound = "snd!",
    spheroid = "boom",
    stringList = "str#",
    tagCollection = "tagc",
    uiWidgetCollection = "Soul",
    uiWidgetDefinition = "DeLa",
    unicodeStringList = "ustr",
    unitHudInterface = "unhi",
    unit = "unit",
    vehicle = "vehi",
    virtualKeyboard = "vcky",
    weaponHudInterface = "wphi",
    weapon = "weap",
    weatherParticleSystem = "rain",
    wind = "wind"
}

-- Blam object classes values
local objectClasses = {
    biped = 0,
    vehicle = 1,
    weapon = 2,
    equipment = 3,
    garbage = 4,
    projectile = 5,
    scenery = 6,
    machine = 7,
    control = 8,
    lightFixture = 9,
    placeHolder = 10,
    soundScenery = 11
}

-- Camera types
local cameraTypes = {
    scripted = 1, -- 22192
    firstPerson = 2, -- 30400
    devcam = 3, -- 30704
    thirdPerson = 4, -- 31952
    deadCamera = 5 -- 23776
}

-- Netgame flags type 
local netgameFlagTypes = {
    ctfFlag = 0,
    ctfVehicle = 1,
    ballSpawn = 2,
    raceTrack = 3,
    raceVehicle = 4,
    vegasBank = 5,
    teleportFrom = 6,
    teleportTo = 7,
    hillFlag = 8
}

-- Netgame equipment types
local netgameEquipmentTypes = {
    none = 0,
    ctf = 1,
    slayer = 2,
    oddball = 3,
    koth = 4,
    race = 5,
    terminator = 6,
    stub = 7,
    ignored1 = 8,
    ignored2 = 9,
    ignored3 = 10,
    ignored4 = 11,
    allGames = 12,
    allExceptCtf = 13,
    allExceptRaceCtf = 14
}

-- Standard console colors
local consoleColors = {
    success = {1, 0.235, 0.82, 0},
    warning = {1, 0.94, 0.75, 0.098},
    error = {1, 1, 0.2, 0.2},
    unknown = {1, 0.66, 0.66, 0.66}
}

-- Offset input from the joystick game data
local joystickInputs = {
    -- No zero values also pressed time until maxmimum byte size
    button1 = 0, -- Triangle
    button2 = 1, -- Circle
    button3 = 2, -- Cross
    button4 = 3, -- Square
    leftBumper = 4,
    rightBumper = 5,
    leftTrigger = 6,
    rightTrigger = 7,
    backButton = 8,
    startButton = 9,
    leftStick = 10,
    rightStick = 11,
    -- Multiple values on the same offset, check dPadValues table
    dPad = 96,
    -- Non zero values
    dPadUp = 100,
    dPadDown = 104,
    dPadLeft = 106,
    dPadRight = 102,
    dPadUpRight = 101,
    dPadDownRight = 103,
    dPadUpLeft = 107,
    dPadDownLeft = 105
    -- TODO Add joys axis
    -- rightJoystick = 30,
}

-- Values for the possible dPad values from the joystick inputs
local dPadValues = {
    noButton = 1020,
    upRight = 766,
    downRight = 768,
    upLeft = 772,
    downLeft = 770,
    left = 771,
    right = 767,
    down = 769,
    up = 765
}

------------------------------------------------------------------------------
-- SAPP API bindings
------------------------------------------------------------------------------
-- All the functions at the top of the module are for EmmyLua autocompletion purposes!
-- They do not have a real implementation and are not supossed to be imported
if (variableThatObviouslyDoesNotExist) then

    --- Attempt to spawn an object given tag id and coordinates or tag type and class plus coordinates
    ---@param tagId number Optional tag id of the object to spawn
    ---@param tagType string Type of the tag to spawn
    ---@param tagPath string Path of object to spawn
    ---@param x number
    ---@param y number
    ---@param z number
    function spawn_object(tagType, tagPath, x, y, z)
    end

    --- Get object address from a specific player given playerIndex
    ---@param playerIndex number
    ---@return number Player object memory address
    function get_dynamic_player(playerIndex)
    end
end
if (api_version) then
    -- Provide global server type variable on SAPP
    server_type = "sapp"

    local split = function(s, sep)
        if (sep == nil or sep == "") then
            return 1
        end
        local position, array = 0, {}
        for st, sp in function()
            return string.find(s, sep, position, true)
        end do
            table.insert(array, string.sub(s, position, st - 1))
            position = sp + 1
        end
        table.insert(array, string.sub(s, position))
        return array
    end

    --- Function wrapper for file writing from Chimera to SAPP
    ---@param path string Path to the file to write
    ---@param content string Content to write into the file
    ---@return boolean | nil, string True if successful otherwise nil, error
    function write_file(path, content)
        local file, error = io.open(path, "w")
        if (not file) then
            return nil, error
        end
        local success, err = file:write(content)
        file:close()
        if (not success) then
            os.remove(path)
            return nil, err
        else
            return true
        end
    end

    --- Function wrapper for file reading from Chimera to SAPP
    ---@param path string Path to the file to read
    ---@return string | nil, string Content of the file otherwise nil, error
    function read_file(path)
        local file, error = io.open(path, "r")
        if (not file) then
            return nil, error
        end
        local content, error = file:read("*a")
        if (content == nil) then
            return nil, error
        end
        file:close()
        return content
    end

    -- TODO PENDING FUNCTION!!
    function directory_exists(dir)
        return true
    end

    --- Function wrapper for directory listing from Chimera to SAPP
    ---@param dir string
    function list_directory(dir)
        -- TODO This needs a way to separate folders from files
        if (dir) then
            local command = "dir " .. dir .. " /B"
            local pipe = io.popen(command, "r")
            local output = pipe:read("*a")
            if (output) then
                local items = split(output, "\n")
                for index, item in pairs(items) do
                    if (item and item == "") then
                        items[index] = nil
                    end
                end
                return items
            end
        end
        return nil
    end

    --- Return the memory address of a tag given tagId or tagClass and tagPath
    ---@param tagIdOrTagType string | number
    ---@param tagPath string
    ---@return number
    function get_tag(tagIdOrTagType, tagPath)
        if (not tagPath) then
            return lookup_tag(tagIdOrTagType)
        else
            return lookup_tag(tagIdOrTagType, tagPath)
        end
    end

    --- Execute a game command or script block
    ---@param command string
    function execute_script(command)
        return execute_command(command)
    end

    --- Return the address of the object memory given object id
    ---@param objectId number
    ---@return number
    function get_object(objectId)
        if (objectId) then
            local object_memory = get_object_memory(objectId)
            if (object_memory ~= 0) then
                return object_memory
            end
        end
        return nil
    end

    --- Delete an object given object id
    ---@param objectId number
    function delete_object(objectId)
        destroy_object(objectId)
    end

    --- Print text into console
    ---@param message string
    ---@param red number
    ---@param green number
    ---@param blue number
    function console_out(message, red, green, blue)
        -- TODO Add color printing to this function
        cprint(message)
    end

    --- Get if the game console is opened \
    --- Always returns true on SAPP.
    ---@return boolean
    function console_is_open()
        return true
    end

    --- Get the value of a Halo scripting global\
    ---An error will occur if the global is not found.
    ---@param name string Name of the global variable to get from hsc
    ---@return boolean | number
    function get_global(name)
        error("SAPP can't retrieve global variables as Chimera does.. yet!")
    end

    --- Print messages to the player HUD\
    ---Server messages will be printed if executed from SAPP.
    ---@param message string
    function hud_message(message)
        for playerIndex = 1, 16 do
            if (player_present(playerIndex)) then
                rprint(playerIndex, message)
            end
        end
    end

    print("Compatibility with Chimera Lua API has been loaded!")
end

------------------------------------------------------------------------------
-- Generic functions
------------------------------------------------------------------------------

--- Verify if the given variable is a number
---@param var any
---@return boolean
local function isNumber(var)
    return (type(var) == "number")
end

--- Verify if the given variable is a string
---@param var any
---@return boolean
local function isString(var)
    return (type(var) == "string")
end

--- Verify if the given variable is a boolean
---@param var any
---@return boolean
local function isBoolean(var)
    return (type(var) == "boolean")
end

--- Verify if the given variable is a table
---@param var any
---@return boolean
local function isTable(var)
    return (type(var) == "table")
end

--- Remove spaces and tabs from the beginning and the end of a string
---@param str string
---@return string
local function trim(str)
    return str:match("^%s*(.*)"):match("(.-)%s*$")
end

--- Verify if the value is valid
---@param var any
---@return boolean
local function isValid(var)
    return (var and var ~= "" and var ~= 0)
end

------------------------------------------------------------------------------
-- Utilities
------------------------------------------------------------------------------

--- Convert tag class int to string
---@param tagClassInt number
---@return string
local function tagClassFromInt(tagClassInt)
    if (tagClassInt) then
        local tagClassHex = tohex(tagClassInt)
        local tagClass = ""
        if (tagClassHex) then
            local byte = ""
            for char in string.gmatch(tagClassHex, ".") do
                byte = byte .. char
                if (#byte % 2 == 0) then
                    tagClass = tagClass .. string.char(tonumber(byte, 16))
                    byte = ""
                end
            end
        end
        return tagClass
    end
    return nil
end

--- Return the current existing objects in the current map, ONLY WORKS FOR CHIMERA!!!
---@return table
function blam.getObjects()
    local currentObjectsList = {}
    for i = 0, 2047 do
        if (get_object(i)) then
            currentObjectsList[#currentObjectsList + 1] = i
        end
    end
    return currentObjectsList
end

-- Local reference to the original console_out function
local original_console_out = console_out

--- Print a console message. It also supports multi-line messages!
---@param message string
local function consoleOutput(message, ...)
    -- Put the extra arguments into a table
    local args = {...}

    if (message == nil or #args > 5) then
        consoleOutput(debug.traceback("Wrong number of arguments on console output function", 2),
                      consoleColors.error)
    end

    -- Output color
    local colorARGB = {1, 1, 1, 1}

    -- Get the output color from arguments table
    if (isTable(args[1])) then
        colorARGB = args[1]
    elseif (#args == 3 or #args == 4) then
        colorARGB = args
    end

    -- Set alpha channel if not set
    if (#colorARGB == 3) then
        table.insert(colorARGB, 1, 1)
    end

    if (isString(message)) then
        -- Explode the string!!
        for line in message:gmatch("([^\n]+)") do
            -- Trim the line
            local trimmedLine = trim(line)

            -- Print the line
            original_console_out(trimmedLine, table.unpack(colorARGB))
        end
    else
        original_console_out(message, table.unpack(colorARGB))
    end
end

--- Convert booleans to bits and bits to booleans
---@param bitOrBool number
---@return boolean | number
local function b2b(bitOrBool)
    if (bitOrBool == 1) then
        return true
    elseif (bitOrBool == 0) then
        return false
    elseif (bitOrBool == true) then
        return 1
    elseif (bitOrBool == false) then
        return 0
    end
    error("B2B error, expected boolean or bit value, got " .. tostring(bitOrBool) .. " " ..
              type(bitOrBool))
end

------------------------------------------------------------------------------
-- Data manipulation and binding
------------------------------------------------------------------------------

local typesOperations

local function readBit(address, propertyData)
    return b2b(read_bit(address, propertyData.bitLevel))
end

local function writeBit(address, propertyData, propertyValue)
    return write_bit(address, propertyData.bitLevel, b2b(propertyValue))
end

local function readByte(address)
    return read_byte(address)
end

local function writeByte(address, propertyData, propertyValue)
    return write_byte(address, propertyValue)
end

local function readShort(address)
    return read_short(address)
end

local function writeShort(address, propertyData, propertyValue)
    return write_short(address, propertyValue)
end

local function readWord(address)
    return read_word(address)
end

local function writeWord(address, propertyData, propertyValue)
    return write_word(address, propertyValue)
end

local function readInt(address)
    return read_int(address)
end

local function writeInt(address, propertyData, propertyValue)
    return write_int(address, propertyValue)
end

local function readDword(address)
    return read_dword(address)
end

local function writeDword(address, propertyData, propertyValue)
    return write_dword(address, propertyValue)
end

local function readFloat(address)
    return read_float(address)
end

local function writeFloat(address, propertyData, propertyValue)
    return write_float(address, propertyValue)
end

local function readChar(address)
    return read_char(address)
end

local function writeChar(address, propertyData, propertyValue)
    return write_char(address, propertyValue)
end

local function readString(address)
    return read_string(address)
end

local function writeString(address, propertyData, propertyValue)
    return write_string(address, propertyValue)
end

-- //TODO Refactor this to support full unicode char size
--- Return the string of a unicode string given address
---@param address number
---@param rawRead boolean
---@return string
function blam.readUnicodeString(address, rawRead)
    local stringAddress
    if (rawRead) then
        stringAddress = address
    else
        stringAddress = read_dword(address)
    end
    local length = stringAddress / 2
    local output = ""
    for i = 1, length do
        local char = read_string(stringAddress + (i - 1) * 0x2)
        if (char == "") then
            break
        end
        output = output .. char
    end
    return output
end

-- //TODO Refactor this to support writing ASCII and Unicode strings
--- Writes a unicode string in a given address
---@param address number
---@param newString string
---@param forced boolean
function blam.writeUnicodeString(address, newString, forced)
    local stringAddress
    if (forced) then
        stringAddress = address
    else
        stringAddress = read_dword(address)
    end
    for i = 1, #newString do
        write_string(stringAddress + (i - 1) * 0x2, newString:sub(i, i))
        if (i == #newString) then
            write_byte(stringAddress + #newString * 0x2, 0x0)
        end
    end
end

local function readPointerUnicodeString(address, propertyData)
    return blam.readUnicodeString(address)
end

local function readUnicodeString(address, propertyData)
    return blam.readUnicodeString(address, true)
end

local function writePointerUnicodeString(address, propertyData, propertyValue)
    return blam.writeUnicodeString(address, propertyValue)
end

local function writeUnicodeString(address, propertyData, propertyValue)
    return blam.writeUnicodeString(address, propertyValue, true)
end

local function readList(address, propertyData)
    local operation = typesOperations[propertyData.elementsType]
    local elementCount = read_byte(address - 0x4)
    local addressList = read_dword(address) + 0xC
    if (propertyData.noOffset) then
        addressList = read_dword(address)
    end
    local list = {}
    for currentElement = 1, elementCount do
        list[currentElement] = operation.read(addressList +
                                                  (propertyData.jump * (currentElement - 1)))
    end
    return list
end

local function writeList(address, propertyData, propertyValue)
    local operation = typesOperations[propertyData.elementsType]
    local elementCount = read_word(address - 0x4)
    local addressList
    if (propertyData.noOffset) then
        addressList = read_dword(address)
    else
        addressList = read_dword(address) + 0xC
    end
    for currentElement = 1, elementCount do
        local elementValue = propertyValue[currentElement]
        if (elementValue) then
            -- Check if there are problems at sending property data here due to missing property data
            operation.write(addressList + (propertyData.jump * (currentElement - 1)), propertyData,
                            elementValue)
        else
            if (currentElement > #propertyValue) then
                break
            end
        end
    end
end

local function readTable(address, propertyData)
    local table = {}
    local elementsCount = read_byte(address - 0x4)
    local firstElement = read_dword(address)
    for elementPosition = 1, elementsCount do
        local elementAddress = firstElement + ((elementPosition - 1) * propertyData.jump)
        table[elementPosition] = {}
        for subProperty, subPropertyData in pairs(propertyData.rows) do
            local operation = typesOperations[subPropertyData.type]
            table[elementPosition][subProperty] = operation.read(elementAddress +
                                                                     subPropertyData.offset,
                                                                 subPropertyData)
        end
    end
    return table
end

local function writeTable(address, propertyData, propertyValue)
    local elementCount = read_byte(address - 0x4)
    local firstElement = read_dword(address)
    for currentElement = 1, elementCount do
        local elementAddress = firstElement + (currentElement - 1) * propertyData.jump
        if (propertyValue[currentElement]) then
            for subProperty, subPropertyValue in pairs(propertyValue[currentElement]) do
                local subPropertyData = propertyData.rows[subProperty]
                if (subPropertyData) then
                    local operation = typesOperations[subPropertyData.type]
                    operation.write(elementAddress + subPropertyData.offset, subPropertyData,
                                    subPropertyValue)
                end
            end
        else
            if (currentElement > #propertyValue) then
                break
            end
        end
    end
end

-- Data types operations references
typesOperations = {
    bit = {read = readBit, write = writeBit},
    byte = {read = readByte, write = writeByte},
    short = {read = readShort, write = writeShort},
    word = {read = readWord, write = writeWord},
    int = {read = readInt, write = writeInt},
    dword = {read = readDword, write = writeDword},
    float = {read = readFloat, write = writeFloat},
    char = {read = readChar, write = writeChar},
    string = {read = readString, write = writeString},
    -- TODO This is not ok, a pointer type with subtyping should be implemented
    pustring = {read = readPointerUnicodeString, write = writePointerUnicodeString},
    ustring = {read = readUnicodeString, write = writeUnicodeString},
    list = {read = readList, write = writeList},
    table = {read = readTable, write = writeTable}
}

-- Magic luablam metatable
local dataBindingMetaTable = {
    __newindex = function(object, property, propertyValue)
        -- Get all the data related to property field
        local propertyData = object.structure[property]
        if (propertyData) then
            local operation = typesOperations[propertyData.type]
            local propertyAddress = object.address + propertyData.offset
            operation.write(propertyAddress, propertyData, propertyValue)
        else
            local errorMessage = "Unable to write an invalid property ('" .. property .. "')"
            error(debug.traceback(errorMessage, 2))
        end
    end,
    __index = function(object, property)
        local objectStructure = object.structure
        local propertyData = objectStructure[property]
        if (propertyData) then
            local operation = typesOperations[propertyData.type]
            local propertyAddress = object.address + propertyData.offset
            return operation.read(propertyAddress, propertyData)
        else
            local errorMessage = "Unable to read an invalid property ('" .. property .. "')"
            error(debug.traceback(errorMessage, 2))
        end
    end
}

------------------------------------------------------------------------------
-- Object functions
------------------------------------------------------------------------------

--- Create a blam object
---@param address number
---@param struct table
---@return table
local function createObject(address, struct)
    -- Create object
    local object = {}

    -- Set up legacy values
    object.address = address
    object.structure = struct

    -- Set mechanisim to bind properties to memory
    setmetatable(object, dataBindingMetaTable)

    return object
end

--- Return a dump of a given LuaBlam object
---@param object table
---@return table
local function dumpObject(object)
    local dump = {}
    for k, v in pairs(object.structure) do
        dump[k] = object[k]
    end
    return dump
end

--- Return a extended parent structure with another given structure
---@param parent table
---@param structure table
---@return table
local function extendStructure(parent, structure)
    local extendedStructure = {}
    for k, v in pairs(parent) do
        extendedStructure[k] = v
    end
    for k, v in pairs(structure) do
        extendedStructure[k] = v
    end
    return extendedStructure
end

------------------------------------------------------------------------------
-- Object structures
------------------------------------------------------------------------------

---@class dataTable
---@field name string
---@field maxElements number
---@field elementSize number
---@field capacity number
---@field size number
---@field nextElementId number
---@field firstElementAddress number
local dataTableStructure = {
    name = {type = "string", offset = 0},
    maxElements = {type = "word", offset = 0x20},
    elementSize = {type = "word", offset = 0x22},
    -- padding1 = {size = 0x0A, offset = 0x24},
    capacity = {type = "word", offset = 0x2E},
    size = {type = "word", offset = 0x30},
    nextElementId = {type = "word", offset = 0x32},
    firstElementAddress = {type = "dword", offset = 0x34}
}

local deviceGroupsTableStructure = {
    name = {type = "string", offset = 0},
    maxElements = {type = "word", offset = 0x20},
    elementSize = {type = "word", offset = 0x22},
    firstElementAddress = {type = "dword", offset = 0x34}
}

---@class blamObject
---@field address number
---@field tagId number Object tag ID
---@field isGhost boolean Set object in some type of ghost mode
---@field isOnGround boolean Is the object touching ground
---@field ignoreGravity boolean Make object to ignore gravity
---@field isInWater boolean Is the object touching on water
---@field dynamicShading boolean Enable disable dynamic shading for lightmaps
---@field isNotCastingShadow boolean Enable/disable object shadow casting
---@field isFrozen boolean Freeze/unfreeze object existence
---@field isOutSideMap boolean Is object outside/inside bsp
---@field isCollideable boolean Enable/disable object collision, does not work with bipeds or vehicles
---@field hasNoCollision boolean Enable/disable object collision, causes animation problems
---@field model number Gbxmodel tag ID
---@field health number Current health of the object
---@field shield number Current shield of the object
---@field redA number Red color channel for A modifier
---@field greenA number Green color channel for A modifier
---@field blueA number Blue color channel for A modifier
---@field x number Current position of the object on X axis
---@field y number Current position of the object on Y axis
---@field z number Current position of the object on Z axis
---@field xVel number Current velocity of the object on X axis
---@field yVel number Current velocity of the object on Y axis
---@field zVel number Current velocity of the object on Z axis
---@field vX number Current x value in first rotation vector
---@field vY number Current y value in first rotation vector
---@field vZ number Current z value in first rotation vector
---@field v2X number Current x value in second rotation vector
---@field v2Y number Current y value in second rotation vector
---@field v2Z number Current z value in second rotation vector
---@field yawVel number Current velocity of the object in yaw
---@field pitchVel number Current velocity of the object in pitch
---@field rollVel number Current velocity of the object in roll
---@field locationId number Current id of the location in the map
---@field boundingRadius number Radius amount of the object in radians
---@field type number Object type
---@field team number Object multiplayer team
---@field nameIndex number Index of object name in the scenario tag
---@field playerId number Current player id if the object
---@field parentId number Current parent id of the object
---@field isHealthEmpty boolean Is the object health deploeted, also marked as "dead"
---@field animationTagId number Current animation tag ID
---@field animation number Current animation index
---@field animationFrame number Current animation frame
---@field isNotDamageable boolean Make the object undamageable
---@field regionPermutation1 number
---@field regionPermutation2 number
---@field regionPermutation3 number
---@field regionPermutation4 number
---@field regionPermutation5 number
---@field regionPermutation6 number
---@field regionPermutation7 number
---@field regionPermutation8 number

-- blamObject structure
local objectStructure = {
    tagId = {type = "dword", offset = 0x0},
    isGhost = {type = "bit", offset = 0x10, bitLevel = 0},
    isOnGround = {type = "bit", offset = 0x10, bitLevel = 1},
    ignoreGravity = {type = "bit", offset = 0x10, bitLevel = 2},
    isInWater = {type = "bit", offset = 0x10, bitLevel = 3},
    isStationary = {type = "bit", offset = 0x10, bitLevel = 5},
    hasNoCollision = {type = "bit", offset = 0x10, bitLevel = 7},
    dynamicShading = {type = "bit", offset = 0x10, bitLevel = 14},
    isNotCastingShadow = {type = "bit", offset = 0x10, bitLevel = 18},
    isFrozen = {type = "bit", offset = 0x10, bitLevel = 20},
    -- FIXME Deprecated property, should be erased at a major release later
    frozen = {type = "bit", offset = 0x10, bitLevel = 20},
    isOutSideMap = {type = "bit", offset = 0x12, bitLevel = 5},
    isCollideable = {type = "bit", offset = 0x10, bitLevel = 24},
    model = {type = "dword", offset = 0x34},
    health = {type = "float", offset = 0xE0},
    shield = {type = "float", offset = 0xE4},
    redA = {type = "float", offset = 0x1B8},
    greenA = {type = "float", offset = 0x1BC},
    blueA = {type = "float", offset = 0x1C0},
    x = {type = "float", offset = 0x5C},
    y = {type = "float", offset = 0x60},
    z = {type = "float", offset = 0x64},
    xVel = {type = "float", offset = 0x68},
    yVel = {type = "float", offset = 0x6C},
    zVel = {type = "float", offset = 0x70},
    vX = {type = "float", offset = 0x74},
    vY = {type = "float", offset = 0x78},
    vZ = {type = "float", offset = 0x7C},
    v2X = {type = "float", offset = 0x80},
    v2Y = {type = "float", offset = 0x84},
    v2Z = {type = "float", offset = 0x88},
    -- FIXME Some order from this values is probaby wrong, expected order is pitch, yaw, roll
    yawVel = {type = "float", offset = 0x8C},
    pitchVel = {type = "float", offset = 0x90},
    rollVel = {type = "float", offset = 0x94},
    locationId = {type = "dword", offset = 0x98},
    boundingRadius = {type = "float", offset = 0xAC},
    type = {type = "word", offset = 0xB4},
    team = {type = "word", offset = 0xB8},
    nameIndex = {type = "word", offset = 0xBA},
    playerId = {type = "dword", offset = 0xC0},
    parentId = {type = "dword", offset = 0xC4},
    isHealthEmpty = {type = "bit", offset = 0x106, bitLevel = 2},
    animationTagId = {type = "dword", offset = 0xCC},
    animation = {type = "word", offset = 0xD0},
    animationFrame = {type = "word", offset = 0xD2},
    isNotDamageable = {type = "bit", offset = 0x106, bitLevel = 11},
    regionPermutation1 = {type = "byte", offset = 0x180},
    regionPermutation2 = {type = "byte", offset = 0x181},
    regionPermutation3 = {type = "byte", offset = 0x182},
    regionPermutation4 = {type = "byte", offset = 0x183},
    regionPermutation5 = {type = "byte", offset = 0x184},
    regionPermutation6 = {type = "byte", offset = 0x185},
    regionPermutation7 = {type = "byte", offset = 0x186},
    regionPermutation8 = {type = "byte", offset = 0x187}
}

---@class biped : blamObject
---@field invisible boolean Biped invisible state
---@field noDropItems boolean Biped ability to drop items at dead
---@field ignoreCollision boolean Biped ignores collisiion
---@field flashlight boolean Biped has flaslight enabled
---@field cameraX number Current position of the biped  X axis
---@field cameraY number Current position of the biped  Y axis
---@field cameraZ number Current position of the biped  Z axis
---@field crouchHold boolean Biped is holding crouch action
---@field jumpHold boolean Biped is holding jump action
---@field actionKeyHold boolean Biped is holding action key
---@field actionKey boolean Biped pressed action key
---@field meleeKey boolean Biped pressed melee key
---@field reloadKey boolean Biped pressed reload key
---@field weaponPTH boolean Biped is holding primary weapon trigger
---@field weaponSTH boolean Biped is holding secondary weapon trigger
---@field flashlightKey boolean Biped pressed flashlight key
---@field grenadeHold boolean Biped is holding grenade action
---@field crouch number Is biped crouch
---@field shooting number Is biped shooting, 0 when not, 1 when shooting
---@field weaponSlot number Current biped weapon slot
---@field zoomLevel number Current biped weapon zoom level, 0xFF when no zoom, up to 255 when zoomed
---@field invisibleScale number Opacity amount of biped invisiblity
---@field primaryNades number Primary grenades count
---@field secondaryNades number Secondary grenades count
---@field landing number Biped landing state, 0 when landing, stays on 0 when landing hard, null otherwise
---@field bumpedObjectId number Object ID that the biped is bumping, vehicles, bipeds, etc, keeps the previous value if not bumping a new object
---@field vehicleSeatIndex number Current vehicle seat index of this biped
---@field vehicleObjectId number Current vehicle objectId of this object
---@field walkingState number Biped walking state, 0 = not walking, 1 = walking, 2 = stoping walking, 3 = stationary
---@field motionState number Biped motion state, 0 = standing , 1 = walking , 2 = jumping/falling
---@field mostRecentDamagerPlayer number Id of the player that caused the most recent damage to this biped

-- Biped structure (extends object structure)
local bipedStructure = extendStructure(objectStructure, {
    invisible = {type = "bit", offset = 0x204, bitLevel = 4},
    noDropItems = {type = "bit", offset = 0x204, bitLevel = 20},
    ignoreCollision = {type = "bit", offset = 0x4CC, bitLevel = 3},
    flashlight = {type = "bit", offset = 0x204, bitLevel = 19},
    cameraX = {type = "float", offset = 0x230},
    cameraY = {type = "float", offset = 0x234},
    cameraZ = {type = "float", offset = 0x238},
    crouchHold = {type = "bit", offset = 0x208, bitLevel = 0},
    jumpHold = {type = "bit", offset = 0x208, bitLevel = 1},
    actionKeyHold = {type = "bit", offset = 0x208, bitLevel = 14},
    actionKey = {type = "bit", offset = 0x208, bitLevel = 6},
    meleeKey = {type = "bit", offset = 0x208, bitLevel = 7},
    reloadKey = {type = "bit", offset = 0x208, bitLevel = 10},
    weaponPTH = {type = "bit", offset = 0x208, bitLevel = 11},
    weaponSTH = {type = "bit", offset = 0x208, bitLevel = 12},
    flashlightKey = {type = "bit", offset = 0x208, bitLevel = 4},
    grenadeHold = {type = "bit", offset = 0x208, bitLevel = 13},
    crouch = {type = "byte", offset = 0x2A0},
    shooting = {type = "float", offset = 0x284},
    weaponSlot = {type = "byte", offset = 0x2A1},
    zoomLevel = {type = "byte", offset = 0x320},
    invisibleScale = {type = "byte", offset = 0x37C},
    primaryNades = {type = "byte", offset = 0x31E},
    secondaryNades = {type = "byte", offset = 0x31F},
    landing = {type = "byte", offset = 0x508},
    bumpedObjectId = {type = "dword", offset = 0x4FC},
    vehicleObjectId = {type = "dword", offset = 0x11C},
    vehicleSeatIndex = {type = "word", offset = 0x2F0},
    walkingState = {type = "char", offset = 0x503},
    motionState = {type = "byte", offset = 0x4D2},
    mostRecentDamagerPlayer = {type = "dword", offset = 0x43C}
})

-- Tag data header structure
local tagDataHeaderStructure = {
    array = {type = "dword", offset = 0x0},
    scenario = {type = "dword", offset = 0x4},
    count = {type = "word", offset = 0xC}
}

---@class tag
---@field class number Type of the tag
---@field index number Tag Index
---@field id number Tag ID
---@field path string Path of the tag
---@field data number Address of the tag data
---@field indexed boolean Is tag indexed on an external map file

-- Tag structure
local tagHeaderStructure = {
    class = {type = "dword", offset = 0x0},
    index = {type = "word", offset = 0xC},
    -- //TODO This needs some review
    -- id = {type = "word", offset = 0xE},
    -- fullId = {type = "dword", offset = 0xC},
    id = {type = "dword", offset = 0xC},
    path = {type = "dword", offset = 0x10},
    data = {type = "dword", offset = 0x14},
    indexed = {type = "dword", offset = 0x18}
}

---@class tagCollection
---@field count number Number of tags in the collection
---@field tagList table List of tags

-- tagCollection structure
local tagCollectionStructure = {
    count = {type = "byte", offset = 0x0},
    tagList = {type = "list", offset = 0x4, elementsType = "dword", jump = 0x10}
}

---@class unicodeStringList
---@field count number Number of unicode strings
---@field stringList table List of unicode strings

-- UnicodeStringList structure
local unicodeStringListStructure = {
    count = {type = "byte", offset = 0x0},
    stringList = {type = "list", offset = 0x4, elementsType = "pustring", jump = 0x14}
}

---@class bitmapSequence
---@field name string
---@field firtBitmapIndex number
---@field bitmapCount number

---@class bitmap
---@field type number
---@field format number
---@field usage number
---@field usageFlags number
---@field detailFadeFactor number
---@field sharpenAmount number
---@field bumpHeight number
---@field spriteBudgetSize number
---@field spriteBudgetCount number
---@field colorPlateWidth number
---@field colorPlateHeight number 
---@field compressedColorPlate string
---@field processedPixelData string
---@field blurFilterSize number
---@field alphaBias number
---@field mipmapCount number
---@field spriteUsage number
---@field spriteSpacing number
---@field sequencesCount number
---@field sequences bitmapSequence[]
---@field bitmapsCount number
---@field bitmaps table

-- Bitmap structure
local bitmapStructure = {
    type = {type = "word", offset = 0x0},
    format = {type = "word", offset = 0x2},
    usage = {type = "word", offset = 0x4},
    usageFlags = {type = "word", offset = 0x6},
    detailFadeFactor = {type = "dword", offset = 0x8},
    sharpenAmount = {type = "dword", offset = 0xC},
    bumpHeight = {type = "dword", offset = 0x10},
    spriteBudgetSize = {type = "word", offset = 0x14},
    spriteBudgetCount = {type = "word", offset = 0x16},
    colorPlateWidth = {type = "word", offset = 0x18},
    colorPlateHeight = {type = "word", offset = 0x1A},
    -- compressedColorPlate = {offset = 0x1C},
    -- processedPixelData = {offset = 0x30},
    blurFilterSize = {type = "float", offset = 0x44},
    alphaBias = {type = "float", offset = 0x48},
    mipmapCount = {type = "word", offset = 0x4C},
    spriteUsage = {type = "word", offset = 0x4E},
    spriteSpacing = {type = "word", offset = 0x50},
    -- padding1 = {size = 0x2, offset = 0x52},
    sequencesCount = {type = "byte", offset = 0x54},
    sequences = {
        type = "table",
        offset = 0x58,
        jump = 0x40,
        rows = {
            name = {type = "string", offset = 0x0},
            firstBitmapIndex = {type = "word", offset = 0x20},
            bitmapCount = {type = "word", offset = 0x22}
            -- padding = {size = 0x10, offset = 0x24},
            --[[
            sprites = {
                type = "table",
                offset = 0x34,
                jump = 0x20,
                rows = {
                    bitmapIndex = {type = "word", offset = 0x0},
                    --padding1 = {size = 0x2, offset = 0x2},
                    --padding2 = {size = 0x4, offset = 0x4},
                    left = {type = "float", offset = 0x8},
                    right = {type = "float", offset = 0xC},
                    top = {type = "float", offset = 0x10},
                    bottom = {type = "float", offset = 0x14},
                    registrationX = {type = "float", offset = 0x18},
                    registrationY = {type = "float", offset = 0x1C}
                }
            }
            ]]
        }
    },
    bitmapsCount = {type = "byte", offset = 0x60},
    bitmaps = {
        type = "table",
        offset = 0x64,
        jump = 0x30,
        rows = {
            class = {type = "dword", offset = 0x0},
            width = {type = "word", offset = 0x4},
            height = {type = "word", offset = 0x6},
            depth = {type = "word", offset = 0x8},
            type = {type = "word", offset = 0xA},
            format = {type = "word", offset = 0xC},
            flags = {type = "word", offset = 0xE},
            x = {type = "word", offset = 0x10},
            y = {type = "word", offset = 0x12},
            mipmapCount = {type = "word", offset = 0x14},
            -- padding1 = {size = 0x2, offset = 0x16},
            pixelOffset = {type = "dword", offset = 0x18}
            -- padding2 = {size = 0x4, offset = 0x1C},
            -- padding3 = {size = 0x4, offset = 0x20},
            -- padding4 = {size = 0x4, offset= 0x24},
            -- padding5 = {size = 0x8, offset= 0x28}
        }
    }
}

---@class uiWidgetDefinition
---@field type number Type of widget
---@field controllerIndex number Index of the player controller
---@field name string Name of the widget
---@field boundsY number Top bound of the widget
---@field boundsX number Left bound of the widget
---@field height number Bottom bound of the widget
---@field width number Right bound of the widget
---@field backgroundBitmap number Tag ID of the background bitmap
---@field eventType number
---@field tagReference number
---@field childWidgetsCount number Number of child widgets
---@field childWidgetsList table tag ID list of the child widgets

-- UI Widget Definition structure
local uiWidgetDefinitionStructure = {
    type = {type = "word", offset = 0x0},
    controllerIndex = {type = "word", offset = 0x2},
    name = {type = "string", offset = 0x4},
    boundsY = {type = "short", offset = 0x24},
    boundsX = {type = "short", offset = 0x26},
    height = {type = "short", offset = 0x28},
    width = {type = "short", offset = 0x2A},
    backgroundBitmap = {type = "word", offset = 0x44},
    eventType = {type = "byte", offset = 0x03F0},
    tagReference = {type = "word", offset = 0x400},
    childWidgetsCount = {type = "dword", offset = 0x03E0},
    childWidgetsList = {type = "list", offset = 0x03E4, elementsType = "dword", jump = 0x50}
}

---@class uiWidgetCollection
---@field count number Number of widgets in the collection
---@field tagList table Tag ID list of the widgets

-- uiWidgetCollection structure
local uiWidgetCollectionStructure = {
    count = {type = "byte", offset = 0x0},
    tagList = {type = "list", offset = 0x4, elementsType = "dword", jump = 0x10}
}

---@class crosshairOverlay
---@field x number
---@field y number
---@field widthScale number
---@field heightScale number
---@field defaultColorA number
---@field defaultColorR number
---@field defaultColorG number
---@field defaultColorB number
---@field sequenceIndex number

---@class crosshair
---@field type number
---@field mapType number
---@field bitmap number
---@field overlays crosshairOverlay[]

---@class weaponHudInterface
---@field childHud number
---@field totalAmmoCutOff number
---@field loadedAmmoCutOff number
---@field heatCutOff number
---@field ageCutOff number
---@field crosshairs crosshair[]

-- Weapon HUD Interface structure
local weaponHudInterfaceStructure = {
    childHud = {type = "dword", offset = 0xC},
    -- //TODO Check if this property should be moved to a nested property type
    usingParentHudFlashingParameters = {type = "bit", offset = "word", bitLevel = 1},
    -- padding1 = {type = "word", offset = 0x12},
    totalAmmoCutOff = {type = "word", offset = 0x14},
    loadedAmmoCutOff = {type = "word", offset = 0x16},
    heatCutOff = {type = "word", offset = 0x18},
    ageCutOff = {type = "word", offset = 0x1A},
    -- padding2 = {size = 0x20, offset = 0x1C},
    -- screenAlignment = {type = "word", },
    -- padding3 = {size = 0x2, offset = 0x3E},
    -- padding4 = {size = 0x20, offset = 0x40},
    crosshairs = {
        type = "table",
        offset = 0x88,
        jump = 0x68,
        rows = {
            type = {type = "word", offset = 0x0},
            mapType = {type = "word", offset = 0x2},
            -- padding1 = {size = 0x2, offset = 0x4},
            -- padding2 = {size = 0x1C, offset = 0x6},
            bitmap = {type = "dword", offset = 0x30},
            overlays = {
                type = "table",
                offset = 0x38,
                jump = 0x6C,
                rows = {
                    x = {type = "word", offset = 0x0},
                    y = {type = "word", offset = 0x2},
                    widthScale = {type = "float", offset = 0x4},
                    heightScale = {type = "float", offset = 0x8},
                    defaultColorB = {type = "byte", offset = 0x24},
                    defaultColorG = {type = "byte", offset = 0x25},
                    defaultColorR = {type = "byte", offset = 0x26},
                    defaultColorA = {type = "byte", offset = 0x27},
                    sequenceIndex = {type = "byte", offset = 0x46}
                }
            }
        }
    }
}

---@class spawnLocation
---@field x number
---@field y number
---@field z number
---@field rotation number
---@field type number
---@field teamIndex number

---@class scenario
---@field sceneryPaletteCount number Number of sceneries in the scenery palette
---@field sceneryPaletteList table Tag ID list of scenerys in the scenery palette
---@field spawnLocationCount number Number of spawns in the scenario
---@field spawnLocationList spawnLocation[] List of spawns in the scenario
---@field vehicleLocationCount number Number of vehicles locations in the scenario
---@field vehicleLocationList table List of vehicles locations in the scenario
---@field netgameEquipmentCount number Number of netgame equipments
---@field netgameEquipmentList table List of netgame equipments
---@field netgameFlagsCount number Number of netgame equipments
---@field netgameFlagsList table List of netgame equipments
---@field objectNamesCount number Count of the object names in the scenario
---@field objectNames string[] List of all the object names in the scenario

-- Scenario structure
local scenarioStructure = {
    sceneryPaletteCount = {type = "byte", offset = 0x021C},
    sceneryPaletteList = {type = "list", offset = 0x0220, elementsType = "dword", jump = 0x30},
    spawnLocationCount = {type = "byte", offset = 0x354},
    spawnLocationList = {
        type = "table",
        offset = 0x358,
        jump = 0x34,
        rows = {
            x = {type = "float", offset = 0x0},
            y = {type = "float", offset = 0x4},
            z = {type = "float", offset = 0x8},
            rotation = {type = "float", offset = 0xC},
            teamIndex = {type = "byte", offset = 0x10},
            bspIndex = {type = "short", offset = 0x12},
            type = {type = "byte", offset = 0x14}
        }
    },
    vehicleLocationCount = {type = "byte", offset = 0x240},
    vehicleLocationList = {
        type = "table",
        offset = 0x244,
        jump = 0x78,
        rows = {
            type = {type = "word", offset = 0x0},
            nameIndex = {type = "word", offset = 0x2},
            x = {type = "float", offset = 0x8},
            y = {type = "float", offset = 0xC},
            z = {type = "float", offset = 0x10},
            yaw = {type = "float", offset = 0x14},
            pitch = {type = "float", offset = 0x18},
            roll = {type = "float", offset = 0x1C}
        }
    },
    netgameFlagsCount = {type = "byte", offset = 0x378},
    netgameFlagsList = {
        type = "table",
        offset = 0x37C,
        jump = 0x94,
        rows = {
            x = {type = "float", offset = 0x0},
            y = {type = "float", offset = 0x4},
            z = {type = "float", offset = 0x8},
            rotation = {type = "float", offset = 0xC},
            type = {type = "byte", offset = 0x10},
            teamIndex = {type = "word", offset = 0x12}
        }
    },
    netgameEquipmentCount = {type = "byte", offset = 0x384},
    netgameEquipmentList = {
        type = "table",
        offset = 0x388,
        jump = 0x90,
        rows = {
            levitate = {type = "bit", offset = 0x0, bitLevel = 0},
            type1 = {type = "word", offset = 0x4},
            type2 = {type = "word", offset = 0x6},
            type3 = {type = "word", offset = 0x8},
            type4 = {type = "word", offset = 0xA},
            teamIndex = {type = "byte", offset = 0xC},
            spawnTime = {type = "word", offset = 0xE},
            x = {type = "float", offset = 0x40},
            y = {type = "float", offset = 0x44},
            z = {type = "float", offset = 0x48},
            facing = {type = "float", offset = 0x4C},
            itemCollection = {type = "dword", offset = 0x5C}
        }
    },
    objectNamesCount = {type = "dword", offset = 0x204},
    objectNames = {
        type = "list",
        offset = 0x208,
        elementsType = "string",
        jump = 36,
        noOffset = true
    }
}

---@class scenery
---@field model number
---@field modifierShader number

-- Scenery structure
local sceneryStructure = {
    model = {type = "word", offset = 0x28 + 0xC},
    modifierShader = {type = "word", offset = 0x90 + 0xC}
}

---@class collisionGeometry
---@field vertexCount number Number of vertex in the collision geometry
---@field vertexList table List of vertex in the collision geometry

-- Collision Model structure
local collisionGeometryStructure = {
    vertexCount = {type = "byte", offset = 0x408},
    vertexList = {
        type = "table",
        offset = 0x40C,
        jump = 0x10,
        rows = {
            x = {type = "float", offset = 0x0},
            y = {type = "float", offset = 0x4},
            z = {type = "float", offset = 0x8}
        }
    }
}

---@class animationClass
---@field name string Name of the animation
---@field type number Type of the animation
---@field frameCount number Frame count of the animation
---@field nextAnimation number Next animation id of the animation
---@field sound number Sound id of the animation

---@class modelAnimations
---@field fpAnimationCount number Number of first-person animations
---@field fpAnimationList number[] List of first-person animations
---@field animationCount number Number of animations of the model
---@field animationList animationClass[] List of animations of the model

-- Model Animation structure
local modelAnimationsStructure = {
    fpAnimationCount = {type = "byte", offset = 0x90},
    fpAnimationList = {
        type = "list",
        offset = 0x94,
        noOffset = true,
        elementsType = "byte",
        jump = 0x2
    },
    animationCount = {type = "byte", offset = 0x74},
    animationList = {
        type = "table",
        offset = 0x78,
        jump = 0xB4,
        rows = {
            name = {type = "string", offset = 0x0},
            type = {type = "word", offset = 0x20},
            frameCount = {type = "byte", offset = 0x22},
            nextAnimation = {type = "byte", offset = 0x38},
            sound = {type = "byte", offset = 0x3C}
        }
    }
}

---@class weapon : blamObject
---@field pressedReloadKey boolean Is weapon trying to reload
---@field isWeaponPunching boolean Is weapon playing melee or grenade animation

local weaponStructure = extendStructure(objectStructure, {
    pressedReloadKey = {type = "bit", offset = 0x230, bitLevel = 3},
    isWeaponPunching = {type = "bit", offset = 0x230, bitLevel = 4}
})

---@class weaponTag
---@field model number Tag ID of the weapon model

-- Weapon structure
local weaponTagStructure = {model = {type = "dword", offset = 0x34}}

-- @class modelMarkers
-- @field name string
-- @field nodeIndex number
-- TODO Add rotation fields, check Guerilla tag
-- @field x number
-- @field y number
-- @field z number

---@class modelRegion
---@field permutationCount number
-- @field markersList modelMarkers[]

---@class modelNode
---@field x number
---@field y number
---@field z number

---@class gbxModel
---@field nodeCount number Number of nodes
---@field nodeList modelNode[] List of the model nodes
---@field regionCount number Number of regions
---@field regionList modelRegion[] List of regions

-- Model structure
local modelStructure = {
    nodeCount = {type = "dword", offset = 0xB8},
    nodeList = {
        type = "table",
        offset = 0xBC,
        jump = 0x9C,
        rows = {
            x = {type = "float", offset = 0x28},
            y = {type = "float", offset = 0x2C},
            z = {type = "float", offset = 0x30}
        }
    },
    regionCount = {type = "dword", offset = 0xC4},
    regionList = {
        type = "table",
        offset = 0xC8,
        jump = 76,
        rows = {
            permutationCount = {type = "dword", offset = 0x40}
            --[[permutationsList = {
                type = "table",
                offset = 0x16C,
                jump = 0x0,
                rows = {
                    name = {type = "string", offset = 0x0},
                    markersList = {
                        type = "table",
                        offset = 0x4C,
                        jump = 0x0,
                        rows = {
                            name = {type = "string", offset = 0x0},
                            nodeIndex = {type = "word", offset = 0x20}
                        }
                    }
                }
            }]]
        }
    }
}

---@class projectile : blamObject
---@field action number Enumeration of denotation action
---@field attachedToObjectId number Id of the attached object
---@field armingTimer number PENDING
---@field xVel number Velocity in x direction
---@field yVel number Velocity in y direction
---@field zVel number Velocity in z direction
---@field yaw number Rotation in yaw direction
---@field pitch number Rotation in pitch direction
---@field roll number Rotation in roll direction

-- Projectile structure
local projectileStructure = extendStructure(objectStructure, {
    action = {type = "word", offset = 0x230},
    attachedToObjectId = {type = "dword", offset = 0x11C},
    armingTimer = {type = "float", offset = 0x248},
    --[[xVel = {type = "float", offset = 0x254},
    yVel = {type = "float", offset = 0x258},
    zVel = {type = "float", offset = 0x25C},]]
    pitch = {type = "float", offset = 0x264},
    yaw = {type = "float", offset = 0x268},
    roll = {type = "float", offset = 0x26C}
})

---@class player
---@field id number Get playerId of this player
---@field host number Check if player is host, 0 when host, null when not
---@field name string Name of this player
---@field team number Team color of this player, 0 when red, 1 when on blue team
---@field objectId number Return the objectId associated to this player
---@field color number Color of the player, only works on "Free for All" gametypes
---@field index number Local index of this player (0-15
---@field speed number Current speed of this player
---@field ping number Ping amount from server of this player in milliseconds
---@field kills number Kills quantity done by this player

local playerStructure = {
    id = {type = "word", offset = 0x0},
    host = {type = "word", offset = 0x2},
    name = {type = "ustring", forced = true, offset = 0x4},
    team = {type = "byte", offset = 0x20},
    objectId = {type = "dword", offset = 0x34},
    color = {type = "word", offset = 0x60},
    index = {type = "byte", offset = 0x67},
    speed = {type = "float", offset = 0x6C},
    ping = {type = "dword", offset = 0xDC},
    kills = {type = "word", offset = 0x9C}
}

---@class firstPersonInterface
---@field firstPersonHands number

---@class multiplayerInformation
---@field flag number Tag ID of the flag object used for multiplayer games
---@field unit number Tag ID of the unit object used for multiplayer games

---@class globalsTag
---@field multiplayerInformation multiplayerInformation[]
---@field firstPersonInterface firstPersonInterface[]

local globalsTagStructure = {
    multiplayerInformation = {
        type = "table",
        jump = 0x0,
        offset = 0x168,
        rows = {flag = {type = "dword", offset = 0xC}, unit = {type = "dword", offset = 0x1C}}
    },
    firstPersonInterface = {
        type = "table",
        jump = 0x0,
        offset = 0x180,
        rows = {firstPersonHands = {type = "dword", offset = 0xC}}
    }
}

---@class firstPerson
---@field weaponObjectId number Weapon Id from the first person view

local firstPersonStructure = {weaponObjectId = {type = "dword", offset = 0x10}}

---@class bipedTag
---@field disableCollision number Disable collision of this biped tag
local bipedTagStructure = {disableCollision = {type = "bit", offset = 0x2F4, bitLevel = 5}}

---@class  deviceMachine : blamObject
---@field powerGroupIndex number Power index from the device groups table
---@field power number Position amount of this device machine
---@field powerChange number Power change of this device machine
---@field positonGroupIndex number Power index from the device groups table
---@field position number Position amount of this device machine
---@field positionChange number Position change of this device machine
local deviceMachineStructure = extendStructure(objectStructure, {
    powerGroupIndex = {type = "word", offset = 0x1F8},
    power = {type = "float", offset = 0x1FC},
    powerChange = {type = "float", offset = 0x200},
    positonGroupIndex = {type = "word", offset = 0x204},
    position = {type = "float", offset = 0x208},
    positionChange = {type = "float", offset = 0x20C}
})

---@class hudGlobals
---@field anchor number
---@field x number
---@field y number
---@field width number
---@field height number
---@field upTime number
---@field fadeTime number
---@field iconColorA number
---@field iconColorR number
---@field iconColorG number
---@field iconColorB number
---@field textSpacing number
local hudGlobalsStructure = {
    anchor = {type = "word", offset = 0x0},
    x = {type = "word", offset = 0x24},
    y = {type = "word", offset = 0x26},
    width = {type = "float", offset = 0x28},
    height = {type = "float", offset = 0x2C},
    upTime = {type = "float", offset = 0x68},
    fadeTime = {type = "float", offset = 0x6C},
    iconColorA = {type = "float", offset = 0x70},
    iconColorR = {type = "float", offset = 0x74},
    iconColorG = {type = "float", offset = 0x78},
    iconColorB = {type = "float", offset = 0x7C},
    textColorA = {type = "float", offset = 0x80},
    textColorR = {type = "float", offset = 0x84},
    textColorG = {type = "float", offset = 0x88},
    textColorB = {type = "float", offset = 0x8C},
    textSpacing = {type = "float", offset = 0x90}
}

------------------------------------------------------------------------------
-- LuaBlam globals
------------------------------------------------------------------------------

-- Provide with public blam! data tables
blam.addressList = addressList
blam.tagClasses = tagClasses
blam.objectClasses = objectClasses
blam.joystickInputs = joystickInputs
blam.dPadValues = dPadValues
blam.cameraTypes = cameraTypes
blam.netgameFlagTypes = netgameFlagTypes
blam.netgameEquipmentTypes = netgameEquipmentTypes
blam.consoleColors = consoleColors

---@class tagDataHeader
---@field array any
---@field scenario string
---@field count number

---@type tagDataHeader
blam.tagDataHeader = createObject(addressList.tagDataHeader, tagDataHeaderStructure)

------------------------------------------------------------------------------
-- LuaBlam API
------------------------------------------------------------------------------

-- Add utilities to library
blam.dumpObject = dumpObject
blam.consoleOutput = consoleOutput

--- Get if a value equals a null value for game
---@return boolean
function blam.isNull(value)
    if (value == 0xFF or value == 0xFFFF or value == 0xFFFFFFFF or value == nil) then
        return true
    end
    return false
end

function blam.isGameHost()
    return server_type == "local"
end

function blam.isGameSinglePlayer()
    return server_type == "none"
end

function blam.isGameDedicated()
    return server_type == "dedicated"
end

function blam.isGameSAPP()
    return server_type == "sapp"
end

--- Get the current game camera type
---@return number
function blam.getCameraType()
    local camera = read_word(addressList.cameraType)
    if (camera) then
        if (camera == 22192) then
            return cameraTypes.scripted
        elseif (camera == 30400) then
            return cameraTypes.firstPerson
        elseif (camera == 30704) then
            return cameraTypes.devcam
            -- FIXME Validate this value, it seems to be wrong!
        elseif (camera == 21952) then
            return cameraTypes.thirdPerson
        elseif (camera == 23776) then
            return cameraTypes.deadCamera
        end
    end
    return nil
end

--- Get input from the joystick in the game
-- Based on aLTis controller method
-- TODO Check if it is better to return an entire table with all input values 
---@param joystickOffset number Offset input from the joystick data, use blam.joystickInputs
---@return boolean | number Value of the joystick input
function blam.getJoystickInput(joystickOffset)
    joystickOffset = joystickOffset or 0
    -- Nothing is pressed by default
    local inputValue = false
    -- Look for every input from every joystick available
    for controllerId = 0, 3 do
        local inputAddress = addressList.joystickInput + controllerId * 0xA0
        if (joystickOffset >= 30 and joystickOffset <= 38) then
            -- Sticks
            inputValue = inputValue + read_long(inputAddress + joystickOffset)
        elseif (joystickOffset > 96) then
            -- D-pad related
            local tempValue = read_word(inputAddress + 96)
            if (tempValue == joystickOffset - 100) then
                inputValue = true
            end
        else
            inputValue = inputValue + read_byte(inputAddress + joystickOffset)
        end
    end
    return inputValue
end

--- Create a tag object from a given address, this object can't write data to game memory
---@param address integer
---@return tag
function blam.tag(address)
    if (address and address ~= 0) then
        -- Generate a new tag object from class
        local tag = createObject(address, tagHeaderStructure)

        -- Get all the tag info
        local tagInfo = dumpObject(tag)

        -- Set up values
        tagInfo.address = address
        tagInfo.path = read_string(tagInfo.path)
        tagInfo.class = tagClassFromInt(tagInfo.class)

        return tagInfo
    end
    return nil
end

--- Return a tag object given tagPath and tagClass or just tagId
---@param tagIdOrTagPath string | number
---@param tagClass string
---@return tag
function blam.getTag(tagIdOrTagPath, tagClass, ...)
    local tagId
    local tagPath

    -- Get arguments from table
    if (isNumber(tagIdOrTagPath)) then
        tagId = tagIdOrTagPath
    elseif (isString(tagIdOrTagPath)) then
        tagPath = tagIdOrTagPath
    elseif (not tagIdOrTagPath) then
        return nil
    end

    if (...) then
        consoleOutput(debug.traceback("Wrong number of arguments on get tag function", 2),
                      consoleColors.error)
    end

    local tagAddress

    -- Get tag address
    if (tagId) then
        if (tagId < 0xFFFF) then
            -- Calculate tag id
            tagId = read_dword(blam.tagDataHeader.array + (tagId * 0x20 + 0xC))
        end
        tagAddress = get_tag(tagId)
    else
        tagAddress = get_tag(tagClass, tagPath)
    end

    return blam.tag(tagAddress)
end

--- Create a player object given player entry table address
---@return player
function blam.player(address)
    if (isValid(address)) then
        return createObject(address, playerStructure)
    end
    return nil
end

--- Create a blamObject given address
---@param address number
---@return blamObject
function blam.object(address)
    if (isValid(address)) then
        return createObject(address, objectStructure)
    end
    return nil
end

--- Create a Projectile object given address
---@param address number
---@return projectile
function blam.projectile(address)
    if (isValid(address)) then
        return createObject(address, projectileStructure)
    end
    return nil
end

--- Create a Biped object from a given address
---@param address number
---@return biped
function blam.biped(address)
    if (isValid(address)) then
        return createObject(address, bipedStructure)
    end
    return nil
end

--- Create a biped tag from a tag path or id
---@param tag string | number
---@return bipedTag
function blam.bipedTag(tag)
    if (isValid(tag)) then
        local bipedTag = blam.getTag(tag, tagClasses.biped)
        return createObject(bipedTag.data, bipedTagStructure)
    end
    return nil
end

--- Create a Unicode String List object from a tag path or id
---@param tag string | number
---@return unicodeStringList
function blam.unicodeStringList(tag)
    if (isValid(tag)) then
        local unicodeStringListTag = blam.getTag(tag, tagClasses.unicodeStringList)
        return createObject(unicodeStringListTag.data, unicodeStringListStructure)
    end
    return nil
end

--- Create a bitmap object from a tag path or id
---@param tag string | number
---@return bitmap
function blam.bitmap(tag)
    if (isValid(tag)) then
        local bitmapTag = blam.getTag(tag, tagClasses.bitmap)
        return createObject(bitmapTag.data, bitmapStructure)
    end
end

--- Create a UI Widget Definition object from a tag path or id
---@param tag string | number
---@return uiWidgetDefinition
function blam.uiWidgetDefinition(tag)
    if (isValid(tag)) then
        local uiWidgetDefinitionTag = blam.getTag(tag, tagClasses.uiWidgetDefinition)
        return createObject(uiWidgetDefinitionTag.data, uiWidgetDefinitionStructure)
    end
    return nil
end

--- Create a UI Widget Collection object from a tag path or id
---@param tag string | number
---@return uiWidgetCollection
function blam.uiWidgetCollection(tag)
    if (isValid(tag)) then
        local uiWidgetCollectionTag = blam.getTag(tag, tagClasses.uiWidgetCollection)
        return createObject(uiWidgetCollectionTag.data, uiWidgetCollectionStructure)
    end
    return nil
end

--- Create a Tag Collection object from a tag path or id
---@param tag string | number
---@return tagCollection
function blam.tagCollection(tag)
    if (isValid(tag)) then
        local tagCollectionTag = blam.getTag(tag, tagClasses.tagCollection)
        return createObject(tagCollectionTag.data, tagCollectionStructure)
    end
    return nil
end

--- Create a Weapon HUD Interface object from a tag path or id
---@param tag string | number
---@return weaponHudInterface
function blam.weaponHudInterface(tag)
    if (isValid(tag)) then
        local weaponHudInterfaceTag = blam.getTag(tag, tagClasses.weaponHudInterface)
        return createObject(weaponHudInterfaceTag.data, weaponHudInterfaceStructure)
    end
    return nil
end

--- Create a Scenario object from a tag path or id
---@param tag string | number
---@return scenario
function blam.scenario(tag)
    local scenarioTag = blam.getTag(tag or 0, tagClasses.scenario)
    return createObject(scenarioTag.data, scenarioStructure)
end

--- Create a Scenery object from a tag path or id
---@param tag string | number
---@return scenery
function blam.scenery(tag)
    if (isValid(tag)) then
        local sceneryTag = blam.getTag(tag, tagClasses.scenery)
        return createObject(sceneryTag.data, sceneryStructure)
    end
    return nil
end

--- Create a Collision Geometry object from a tag path or id
---@param tag string | number
---@return collisionGeometry
function blam.collisionGeometry(tag)
    if (isValid(tag)) then
        local collisionGeometryTag = blam.getTag(tag, tagClasses.collisionGeometry)
        return createObject(collisionGeometryTag.data, collisionGeometryStructure)
    end
    return nil
end

--- Create a Model Animations object from a tag path or id
---@param tag string | number
---@return modelAnimations
function blam.modelAnimations(tag)
    if (isValid(tag)) then
        local modelAnimationsTag = blam.getTag(tag, tagClasses.modelAnimations)
        return createObject(modelAnimationsTag.data, modelAnimationsStructure)
    end
    return nil
end

--- Create a Weapon object from the given object address
---@param address number
---@return weapon
function blam.weapon(address)
    if (isValid(address)) then
        return createObject(address, weaponStructure)
    end
    return nil
end

--- Create a Weapon tag object from a tag path or id
---@param tag string | number
---@return weaponTag
function blam.weaponTag(tag)
    if (isValid(tag)) then
        local weaponTag = blam.getTag(tag, tagClasses.weapon)
        return createObject(weaponTag.data, weaponTagStructure)
    end
    return nil
end

--- Create a model (gbxmodel) object from a tag path or id
---@param tag string | number
---@return gbxModel
function blam.model(tag)
    if (isValid(tag)) then
        local modelTag = blam.getTag(tag, tagClasses.model)
        return createObject(modelTag.data, modelStructure)
    end
    return nil
end
-- Alias
blam.gbxmodel = blam.model

--- Create a Globals tag object from a tag path or id
---@param tag string | number
---@return globalsTag
function blam.globalsTag(tag)
    local tag = tag or "globals\\globals"
    if (isValid(tag)) then
        local globalsTag = blam.getTag(tag, tagClasses.globals)
        return createObject(globalsTag.data, globalsTagStructure)
    end
    return nil
end

--- Create a First person object from a given address, game known address by default
---@param address number
---@return firstPerson
function blam.firstPerson(address)
    return createObject(address or addressList.firstPerson, firstPersonStructure)
end

--- Create a Device Machine object from a given address
---@param address number
---@return deviceMachine
function blam.deviceMachine(address)
    if (isValid(address)) then
        return createObject(address, deviceMachineStructure)
    end
    return nil
end

--- Create a HUD Globals tag object from a given address
---@param tag string | number
---@return hudGlobals
function blam.hudGlobals(tag)
    if (isValid(tag)) then
        local hudGlobals = blam.getTag(tag, tagClasses.hudGlobals)
        return createObject(hudGlobals.data, hudGlobalsStructure)
    end
    return nil
end

--- Return a blam object given object index or id
---@param idOrIndex number
---@return blamObject, number
function blam.getObject(idOrIndex)
    local objectId
    local objectAddress

    -- Get object address
    if (idOrIndex) then
        -- Get object ID
        if (idOrIndex < 0xFFFF) then
            local index = idOrIndex

            -- Get objects table
            local table = createObject(addressList.objectTable, dataTableStructure)
            if (index > table.capacity) then
                return nil
            end

            -- Calculate object ID (this may be invalid, be careful)
            objectId =
                (read_word(table.firstElementAddress + index * table.elementSize) * 0x10000) + index
        else
            objectId = idOrIndex
        end

        objectAddress = get_object(objectId)

        return blam.object(objectAddress), objectId
    end
    return nil
end

--- Return an element from the device machines table
---@param index number
---@return number
function blam.getDeviceGroup(index)
    -- Get object address
    if (index) then
        -- Get objects table
        local table = createObject(read_dword(addressList.deviceGroupsTable), deviceGroupsTableStructure)
        -- Calculate object ID (this may be invalid, be careful)
        local itemOffset = table.elementSize * index 
        local item = read_float(table.firstElementAddress + itemOffset + 0x4)
        return item
    end
    return nil
end

return blam

end,

["lua-ini"] = function()
--------------------
-- Module: 'lua-ini'
--------------------
-------------------------------------------------------------------------------
--- INI Module
--- Dynodzzo, Sledmine
--- It has never been that simple to use ini files with Lua
----------------------------------------------------------------------------------
local ini = {
    _VERSION = 1.0,
    _LICENSE = [[
	Copyright (c) 2012 Carreras Nicolas
	
	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.
	
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER G
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
]]
}

--- Returns a table containing all the data from an ini string
---@param fileString string Ini encoded string
---@return table Table containing all data from the ini string
function ini.decode(fileString)
    local position, lines = 0, {}
    for st, sp in function()
        return string.find(fileString, "\n", position, true)
    end do
        table.insert(lines, string.sub(fileString, position, st - 1))
        position = sp + 1
    end
    table.insert(lines, string.sub(fileString, position))
    local data = {}
    local section
    for lineNumber, line in pairs(lines) do
        local tempSection = line:match("^%[([^%[%]]+)%]$")
        if (tempSection) then
            section = tonumber(tempSection) and tonumber(tempSection) or tempSection
            data[section] = data[section] or {}
        end
        local param, value = line:match("^([%w|_]+)%s-=%s-(.+)$")
        if (param and value ~= nil) then
            if (tonumber(value)) then
                value = tonumber(value)
            elseif (value == "true") then
                value = true
            elseif (value == "false") then
                value = false
            end
            if (tonumber(param)) then
                param = tonumber(param)
            end
            data[section][param] = value
        end
    end
    return data
end

--- Returns a ini encoded string given data
---@param data table Table containing all data from the ini file
---@return string String encoded as an ini file
function ini.encode(data)
    local content = ""
    for section, param in pairs(data) do
        content = content .. ("[%s]\n"):format(section)
        for key, value in pairs(param) do
            content = content .. ("%s=%s\n"):format(key, tostring(value))
        end
        content = content .. "\n"
    end
    return content
end

--- Returns a table containing all the data from an ini file
---@param fileName string Path to the file to load
---@return table Table containing all data from the ini file
function ini.load(fileName)
    assert(type(fileName) == "string", "Parameter \"fileName\" must be a string.")
    local file = assert(io.open(fileName, "r"), "Error loading file : " .. fileName)
    local data = ini.decode(file:read("*"))
    file:close()
    return data
end

--- Saves all the data from a table to an ini file
---@param fileName string The name of the ini file to fill
---@param data table The table containing all the data to store
function ini.save(fileName, data)
    assert(type(fileName) == "string", "Parameter \"fileName\" must be a string.")
    assert(type(data) == "table", "Parameter \"data\" must be a table.")
    local file = assert(io.open(fileName, "w+b"), "Error loading file :" .. fileName)
    file:write(ini.encode(data))
    file:close()
end

return ini

end,

["color"] = function()
--------------------
-- Module: 'color'
--------------------
local convertColor = {}

--- Convert to decimal rgb color from hex string color
---@param hex string
---@param alpha number
function convertColor.hex(hex, alpha)
    local redColor, greenColor, blueColor = hex:gsub("#", ""):match("(..)(..)(..)")
    redColor, greenColor, blueColor = tonumber(redColor, 16) / 255,
                                      tonumber(greenColor, 16) / 255,
                                      tonumber(blueColor, 16) / 255
    redColor, greenColor, blueColor = math.floor(redColor * 100) / 100,
                                      math.floor(greenColor * 100) / 100,
                                      math.floor(blueColor * 100) / 100
    if alpha == nil then
        return redColor, greenColor, blueColor
    elseif alpha > 1 then
        alpha = alpha / 100
    end
    return redColor, greenColor, blueColor, alpha
end

--- Convert to decimal rgb color from byte rgb color
---@param r number
---@param g number
---@param b number
---@param alpha number
function convertColor.rgb(r, g, b, alpha)
    local redColor, greenColor, blueColor = r / 255, g / 255, b / 255
    redColor, greenColor, blueColor = math.floor(redColor * 100) / 100,
                                      math.floor(greenColor * 100) / 100,
                                      math.floor(blueColor * 100) / 100
    if alpha == nil then
        return redColor, greenColor, blueColor
    elseif alpha > 1 then
        alpha = alpha / 100
    end
    return redColor, greenColor, blueColor, alpha
end

return convertColor

end,

["rcon"] = function()
--------------------
-- Module: 'rcon'
--------------------
------------------------------------------------------------------------------
-- Rcon Bypass
-- Sledmine
-- SAPP commands interceptor
------------------------------------------------------------------------------
local rcon = {_VERSION = "1.0.1"}

local environments = {
    console = 0,
    rcon = 1,
    chat = 2
}

rcon.environments = environments

-- Accepted rcon passwords
rcon.safeRcons = {}

-- Admin commands
rcon.adminCommands = {}

-- Commands to intercept
rcon.safeCommands = {}

rcon.commandInterceptor = nil

-- Internal functions
local function split(s, sep)
    if (sep == nil or sep == '') then return 1 end
    local position, array = 0, {}
    for st, sp in function() return string.find(s, sep, position, true) end do
        table.insert(array, string.sub(s, position, st-1))
        position = sp + 1
    end
    table.insert(array, string.sub(s, position))
    return array
end

local function listHas(list, value)
    value = string.gsub(value, "'", "")
    for k, element in pairs(list) do
        local wildcard = split(value, element)[1]
        if (element == value or wildcard == "") then
            return true
        end
    end
    return false
end

local function submit(list, value)
    if (not listHas(list, value)) then
        list[#list + 1] = value
        return true
    end
    return false
end

local function isABypassValue(list, value)
    if (listHas(list, value)) then
        return true
    end
    return false
end

local function isRconSafe(value)
    return isABypassValue(rcon.safeRcons, value)
end

local function isCommandSafe(value)
    return isABypassValue(rcon.safeCommands, value)
end

local function isAdminCommand(value)
    return isABypassValue(rcon.adminCommands, value)
end

-- Public functions and main usage

function rcon.submitRcon(rconValue)
    cprint("Adding new accepted rcon: " .. rconValue)
    return submit(rcon.safeRcons, rconValue)
end

function rcon.submitAdmimCommand(commandValue)
    cprint("Adding new accepted command: " .. commandValue)
    return submit(rcon.adminCommands, commandValue)
end

function rcon.submitCommand(commandValue)
    cprint("Adding new accepted command: " .. commandValue)
    return submit(rcon.safeCommands, commandValue)
end

---@param playerIndex number
---@param command string
---@param environment number
---@param rconPassword string
function rcon.OnCommand(playerIndex, command, environment, rconPassword)
    if (environment == environments.console or environment == environments.rcon) then
        if (environment == environments.console) then
            rconPassword = rcon.serverRcon
        end
        local playerName = get_var(playerIndex, "$name") or "Server"
        if (rconPassword == rcon.serverRcon) then
            -- Normal rcon usage, allow command
            if (isAdminCommand(command)) then
                rcon.commandInterceptor(playerIndex, command, environment, rconPassword)
                return false
            end
        elseif (isRconSafe(rconPassword)) then
            -- This is an interceptable rcon command
            cprint("Safe rcon: " .. rconPassword)
            if (isCommandSafe(command)) then
                -- Rcon command it's an expected command, apply bypass
                cprint("Safe command: " .. command)
                -- Execute interceptor
                rcon.commandInterceptor(playerIndex, command, environment, rconPassword)
            else
                cprint("Command: " .. command .. " is not in the safe commands list.")
                say_all(playerName .. " was sending commands trough safe rcon, watch out!!!")
                execute_command("sv_kick " .. playerIndex)
            end
            return false
        else
            say_all(playerName .. " was kicked by sending wrong rcon password.")
            execute_command("sv_kick " .. playerIndex)
        end
    end
end

function rcon.attach()
    if (server_type == "sapp") then
        rcon.passwordAddress = read_dword(sig_scan("7740BA??????008D9B000000008A01") + 0x3)
        rcon.failMessageAddress = read_dword(sig_scan("B8????????E8??000000A1????????55") + 0x1)
        if (rcon.passwordAddress and rcon.failMessageAddress) then
            -- Remove "rcon command failure" message
            safe_write(true)
            write_byte(rcon.failMessageAddress, 0x0)
            safe_write(false)
            -- Read current rcon in the server
            rcon.serverRcon = read_string(rcon.passwordAddress)
            if (rcon.serverRcon) then
                cprint("Server rcon password is: \"" .. rcon.serverRcon .. "\"")
            else
                cprint("Error, at getting server rcon, please set and enable rcon on the server.")
            end
        else
            cprint("Error, at obtaining rcon patches, please check SAPP version.")
        end
    end
end

function rcon.detach()
    if (rcon.failMessageAddress) then
        -- Restore "rcon command failure" message
        safe_write(true)
        write_byte(rcon.failMessageAddress, 0x72)
        safe_write(false)
    end
end

return rcon

end,

["forge.commands"] = function()
--------------------
-- Module: 'forge.commands'
--------------------
------------------------------------------------------------------------------
-- Forge Commands
-- Sledmine
-- Commands values
------------------------------------------------------------------------------
local inspect = require "inspect"
local glue = require "glue"

local core = require "forge.core"
local features = require "forge.features"

local function forgeCommands(command)
    if (command == "fdebug") then
        debugBuffer = nil
        config.forge.debugMode = not config.forge.debugMode
        features.hideReflectionObjects()
        -- Force settings menu update
        console_out("Debug mode: " .. tostring(config.forge.debugMode))
        return false
    else
        -- Split all the data in the command input
        local splitCommand = glue.string.split(command, " ")

        -- Substract first console command
        local forgeCommand = splitCommand[1]

        if (forgeCommand == "fstep") then
            local newRotationStep = tonumber(splitCommand[2])
            if (newRotationStep) then
                features.printHUD("Rotation step now is " .. newRotationStep .. " degrees.")
                playerStore:dispatch({
                    type = "SET_ROTATION_STEP",
                    payload = {step = newRotationStep}
                })
            else
                playerStore:dispatch({type = "SET_ROTATION_STEP", payload = {step = 3}})
            end
            return false
        elseif (forgeCommand == "fdis" or forgeCommand == "fdistance") then
            local newDistance = tonumber(splitCommand[2])
            if (newDistance) then
                features.printHUD("Distance from object has been set to " .. newDistance ..
                                      " units.")
                -- Force distance object update
                playerStore:dispatch({type = "SET_LOCK_DISTANCE", payload = {lockDistance = true}})
                local distance = glue.round(newDistance)
                playerStore:dispatch({type = "SET_DISTANCE", payload = {distance = distance}})
            else
                local distance = 3
                playerStore:dispatch({type = "SET_DISTANCE", payload = {distance = distance}})
            end
            return false
        elseif (forgeCommand == "fsave") then
            core.saveForgeMap()
            return false
        elseif (forgeCommand == "fsnap") then
            config.forge.snapMode = not config.forge.snapMode
            console_out("Snap Mode: " .. tostring(config.forge.snapMode))
            -- Force settings menu update
            return false
        elseif (forgeCommand == "fauto") then
            config.forge.autoSave = not config.forge.autoSave
            console_out("Auto Save: " .. tostring(config.forge.autoSave))
            -- Force settings menu update
            return false
        elseif (forgeCommand == "fcast") then
            config.forge.objectsCastShadow = not config.forge.objectsCastShadow
            local objectsCastShadow = config.forge.objectsCastShadow
            ---@type eventsState
            local eventsState = eventsStore:getState()
            for objectIndex, forgeObject in pairs(eventsState.forgeObjects) do
                local object = blam.object(get_object(objectIndex))
                if (object) then
                    if (objectsCastShadow) then
                        core.forceShadowCasting(object)
                    else
                        object.isNotCastingShadow = true
                    end
                end
            end
            -- Force settings menu update
            console_out("Objects Cast Shadow: " .. tostring(config.forge.objectsCastShadow))
            return false
        elseif (forgeCommand == "fload") then
            local mapName = table.concat(glue.shift(splitCommand, 1, -1), " ")
            if (mapName) then
                core.loadForgeMap(mapName)
            else
                console_out("You must specify a forge map name.")
            end
            return false
        elseif (forgeCommand == "flist") then
            local mapsFiles = list_directory(defaultMapsPath)
            for fileIndex, file in pairs(mapsFiles) do
                console_out(file)
            end
            return false
        elseif (forgeCommand == "fname") then
            local mapName = table.concat(glue.shift(splitCommand, 1, -1), " "):gsub(",", " ")
            forgeStore:dispatch({type = "SET_MAP_NAME", payload = {mapName = mapName}})
            return false
        elseif (forgeCommand == "fdesc") then
            local mapDescription = table.concat(glue.shift(splitCommand, 1, -1), " "):gsub(",", " ")
            forgeStore:dispatch({
                type = "SET_MAP_DESCRIPTION",
                payload = {mapDescription = mapDescription}
            })
            return false
        elseif (forgeCommand == "fspawn" and server_type == "local") then
            -- Get scenario data
            local scenario = blam.scenario(0)

            -- Get scenario player spawn points
            local mapSpawnPoints = scenario.spawnLocationList

            mapSpawnPoints[1].type = 12

            scenario.spawnLocationList = mapSpawnPoints
            return false
            -------------- DEBUGGING COMMANDS ONLY ---------------
        elseif (config.forge.debugMode) then
            if (forgeCommand == "fmenu") then
                votingStore:dispatch({
                    type = "APPEND_MAP_VOTE",
                    payload = {
                        map = {
                            name = "Forge",
                            gametype = "Slayer"
                        }
                    }
                })
                features.openMenu(const.uiWidgetDefinitions.voteMenu.path)
                return false
            elseif (forgeCommand == "fsize") then
                dprint(collectgarbage("count") / 1024)
                return false
            elseif (forgeCommand == "fconfig") then
                loadForgeConfiguration()
                return false
            elseif (forgeCommand == "fweap") then
                local weaponsList = {}
                for tagId = 0, blam.tagDataHeader.count - 1 do
                    local tempTag = blam.getTag(tagId)
                    if (tempTag and tempTag.class == tagClasses.weapon) then
                        local splitPath = glue.string.split(tempTag.path, "\\")
                        local weaponTagName = splitPath[#splitPath]
                        weaponsList[weaponTagName] = tempTag.path
                    end
                end
                local weaponName = table.concat(glue.shift(splitCommand, 1, -1), " ")
                local player = blam.biped(get_dynamic_player())
                local weaponResult = weaponsList[weaponName]
                if (weaponResult) then
                    local weaponObjectId = core.spawnObject(tagClasses.weapon, weaponResult,
                                                            player.x, player.y, player.z + 0.5)
                end
                return false
            elseif (forgeCommand == "ftest") then
                -- Run unit testing
                if (config.forge.debugMode) then
                    local tests = require "forge.tests"
                    tests.run(true)
                    return false
                end
            elseif (forgeCommand == "fbiped") then
                local player = blam.player(get_player())
                if (player) then
                    local playerBiped = blam.object(get_object(player.objectId))
                    if (playerBiped) then
                        local bipedName = table.concat(glue.shift(splitCommand, 1, -1), " ")
                        for tagIndex = 0, blam.tagDataHeader.count - 1 do
                            local tag = blam.getTag(tagIndex)
                            if (tag.class == tagClasses.biped) then
                                local pathSplit = glue.string.split(tag.path, "\\")
                                local tagName = pathSplit[#pathSplit]
                                if (tagName == bipedName) then
                                    console_out("Changing biped...")
                                    local globals = blam.globalsTag()
                                    if (globals) then
                                        local newMpInfo = globals.multiplayerInformation
                                        newMpInfo[1].unit = tag.id
                                        -- Update globals tag data to set new biped
                                        globals.multiplayerInformation = newMpInfo
                                        -- Erase player object to force biped respawn
                                        delete_object(player.objectId)
                                        return false
                                    end
                                end
                            end
                        end
                    end
                end
                dprint("Error, biped tag was not found on the map!")
                return false
            elseif (forgeCommand == "fdump") then
                write_file("player_dump.lua", inspect(playerStore:getState()))
                write_file("forge_dump.lua", inspect(forgeStore:getState()))
                write_file("events_dump.lua", inspect(eventsStore:getState()))
                write_file("voting_dump.lua", inspect(votingStore:getState()))
                write_file("general_menu_dump.lua", inspect(generalMenuStore:getState()))
                write_file("constants.lua", inspect(const))
                write_file("debug_dump.txt", debugBuffer or "No debug messages to print.")
                dprint("Done, dumped forge reducers to files.")
                return false
            elseif (forgeCommand == "fixmaps") then
                --[[local mapsFiles = list_directory(defaultMapsPath)
                for fileIndex, file in pairs(mapsFiles) do
                    if (not file:find("\\")) then
                        local fmapContent = read_file(defaultMapsPath .. "\\" .. file)
                        local forgeMapPath = defaultMapsPath .. "\\fix\\" .. file:lower()
                        write_file(forgeMapPath, fmapContent)
                    end
                end]]
                return false
            elseif (forgeCommand == "fprint") then
                dprint("[Game Objects]", "category")
                local objects = blam.getObjects()
                dprint("Count: " .. #objects)
                dprint(inspect(objects))

                dprint("[Objects Store]", "category")
                local storeObjects = glue.keys(eventsStore:getState().forgeObjects)
                dprint("Count: " .. #storeObjects)
                dprint(inspect(storeObjects))

                dprint("[Objects Database]", "category")
                local objectsDatabase = glue.keys(forgeStore:getState().forgeMenu.objectsDatabase)
                dprint("Count: " .. #objectsDatabase)
                dprint(inspect(objectsDatabase))

                return false
            elseif (forgeCommand == "fblam") then
                console_out("lua-blam " .. blam._VERSION)
                return false
            elseif (forgeCommand == "fspeed") then
                local newSpeed = tonumber(table.concat(glue.shift(splitCommand, 1, -1), " "))
                if (newSpeed) then
                    local player = get_player()
                    write_float(player + 0x6C, newSpeed)
                end
                return false
            elseif (forgeCommand == "fpos") then
                local playerBiped = blam.object(get_dynamic_player())
                if (playerBiped) then
                    console_out(("%s,%s,%s"):format(playerBiped.x, playerBiped.y, playerBiped.z))
                end
                return false
            elseif (forgeCommand == "frot") then
                local yaw = splitCommand[2]
                local pitch = splitCommand[3]
                local roll = splitCommand[4]
                dprint(("%s: %s: %s:"):format(yaw, pitch, roll))
                local rotation, matrix = core.eulerToRotation(yaw, pitch, roll)
                dprint("ROTATION:")
                dprint(inspect(rotation))
                dprint("MATRIX:")
                dprint(inspect(matrix[1]))
                dprint(inspect(matrix[2]))
                dprint(inspect(matrix[3]))
                return false
            end
        end
    end
    return true
end

return forgeCommands

end,

["forge.constants"] = function()
--------------------
-- Module: 'forge.constants'
--------------------
------------------------------------------------------------------------------
-- Forge Constants
-- Sledmine
-- Constant values for different purposes
--[[ The idea behind this module is to gather all the data that does not change
 across runtime, so we can optimize getting data just once at map load time
 ]] ---------------------------------------------------------------------------
local core = require "forge.core"
local glue = require "glue"

local time = os.clock()

local constants = {}

-- Constant core values
-- constants.myGamesFolder = read_string(0x00647830)
constants.mouseInputAddress = 0x64C73C
constants.localPlayerAddress = 0x815918
-- Looks like the history/memory of the current widget loaded
-- It appears to work different on the main menu/ui
constants.currentWidgetIdAddress = 0x6B401C
-- constants.isWidgetOpenAddress = constants.currentWidgetIdAddress + 19
-- + 671 = New element??

-- Constant Forge values
constants.requestSeparator = "&"
constants.maximumObjectsBudget = 1024
constants.minimumZSpawnPoint = -18.69
constants.maximumZRenderShadow = -14.12
constants.minimumZMapLimit = -69.9
constants.maximumRenderShadowRadius = 7
constants.forgeSelectorOffset = 0.33
constants.forgeSelectorVelocity = 15

-- Map name should be the base project name, without build env variants
constants.absoluteMapName = map:gsub("_dev", ""):gsub("_beta", "")

-- Constant UI widget definition values
constants.maximumProgressBarSize = 171
constants.maxLoadingBarSize = 422

-- Constant gameplay values
constants.healthRegenerationAmount = 0.006

constants.hudFontTagId = core.findTag("blender_pro_medium_12", tagClasses.font).id
local forgeProjectile = core.findTag("forge", tagClasses.projectile)
constants.forgeProjectilePath = forgeProjectile.path
constants.forgeProjectileTagId = forgeProjectile.id
constants.forgeProjectileTagIndex = forgeProjectile.index
constants.fragGrenadeProjectileTagIndex = core.findTag("frag", tagClasses.projectile).index

-- Constant Forge requests data
constants.requests = {
    spawnObject = {
        actionType = "SPAWN_FORGE_OBJECT",
        requestType = "#s",
        requestFormat = {
            {"requestType"},
            {"tagId", "I4"},
            {"x", "f"},
            {"y", "f"},
            {"z", "f"},
            {"yaw"},
            {"pitch"},
            {"roll"},
            {"color"},
            {"teamIndex"},
            {"remoteId", "I4"}
        }
    },
    updateObject = {
        actionType = "UPDATE_FORGE_OBJECT",
        requestType = "#u",
        requestFormat = {
            {"requestType"},
            {"objectId"},
            {"x", "f"},
            {"y", "f"},
            {"z", "f"},
            {"yaw"},
            {"pitch"},
            {"roll"},
            {"color"},
            {"teamIndex"}
        }
    },
    deleteObject = {
        actionType = "DELETE_FORGE_OBJECT",
        requestType = "#d",
        requestFormat = {{"requestType"}, {"objectId"}}
    },
    flushForge = {actionType = "FLUSH_FORGE"},
    loadMapScreen = {
        actionType = "LOAD_MAP_SCREEN",
        requestType = "#lm",
        requestFormat = {{"requestType"}, {"objectCount"}, {"mapName"}}
    },
    setMapAuthor = {
        actionType = "SET_MAP_AUTHOR",
        requestType = "#ma",
        requestFormat = {{"requestType"}, {"mapAuthor"}}
    },
    setMapDescription = {
        actionType = "SET_MAP_DESCRIPTION",
        requestType = "#md",
        requestFormat = {{"requestType"}, {"mapDescription"}}
    },
    loadVoteMapScreen = {
        actionType = "LOAD_VOTE_MAP_SCREEN",
        requestType = "#lv",
        requestFormat = {{"requestType"}}
    },
    appendVoteMap = {
        actionType = "APPEND_MAP_VOTE",
        requestType = "#av",
        requestFormat = {{"requestType"}, {"name"}, {"gametype"}, {"mapIndex"}}
    },
    sendMapVote = {
        actionType = "SEND_MAP_VOTE",
        requestType = "#v",
        requestFormat = {{"requestType"}, {"mapVoted"}}
    },
    sendTotalMapVotes = {
        actionType = "SEND_TOTAL_MAP_VOTES",
        requestType = "#sv",
        requestFormat = {
            {"requestType"},
            {"votesMap1"},
            {"votesMap2"},
            {"votesMap3"},
            {"votesMap4"}
        }
    },
    flushVotes = {actionType = "FLUSH_VOTES"},
    selectBiped = {
        actionType = "SELECT_BIPED",
        requestType = "#sb",
        requestFormat = {{"requestType"}, {"bipedTagId"}}
    }
}

-- Tag Collections ID
constants.tagCollections = {
    forgeObjectsTagId = core.findTag(constants.absoluteMapName .. "_objects",
                                     tagClasses.tagCollection).id
}

-- Biped Names
constants.bipedNames = {}
-- Biped Tags ID
constants.bipeds = {}
for _, tag in pairs(core.findTagsList("characters", tagClasses.biped)) do
    if (tag) then
        local pathSplit = glue.string.split(tag.path, "\\")
        local tagName = pathSplit[#pathSplit]
        if (not tagName:find("monitor")) then
            constants.bipedNames[core.toSentenceCase(tagName)] = tag.id
        end

        local bipedName = core.toCamelCase(tagName:gsub("_mp", ""))
        constants.bipeds[bipedName .. "TagId"] = tag.id
    end
end

-- First Person Model Tags ID
constants.firstPersonHands = {}
for _, tag in pairs(core.findTagsList("characters", tagClasses.biped)) do
    if (tag) then
        local pathSplit = glue.string.split(tag.path, "\\")
        local tagName = pathSplit[#pathSplit]
        local tagNameFixed = core.toCamelCase(tagName):gsub("_mp", "")
        constants.bipeds[tagNameFixed .. "TagId"] = tag.id
        local pathToBiped = table.concat(glue.shift(pathSplit, #pathSplit, -1), "\\")
        local fpTagPath = pathToBiped .. "\\fp\\" .. tagName .. " fp"
        local fpTag = blam.getTag(fpTagPath, tagClasses.gbxmodel)
        if (fpTag) then
            constants.firstPersonHands[tagName] = fpTag.id
        end
    end
end
-- Hardcode specific sets of armours with a resusable fp
constants.firstPersonHands["mark vii"] = constants.firstPersonHands["mark vi"]

-- Weapon HUD Interface Tags ID
constants.weaponHudInterfaces = {
    forgeCrosshairTagId = core.findTag("ui\\hud\\forge", tagClasses.weaponHudInterface).id
}

-- Bitmap Tags ID
constants.bitmaps = {
    forgingIconFrame0TagId = core.findTag("forge_loading_progress0", tagClasses.bitmap).id,
    forgeIconFrame1TagId = core.findTag("forge_loading_progress1", tagClasses.bitmap).id,
    unitHudBackgroundTagId = core.findTag("combined\\hud_background", tagClasses.bitmap).id,
    dialogIconsTagId = core.findTag("bitmaps\\loading_orb", tagClasses.bitmap).id
}

-- UI Widget definitions
local uiWidgetDefinitions = {
    forgeMenu = core.findTag("forge_menu\\forge_menu", tagClasses.uiWidgetDefinition),
    objectsList = core.findTag("category_list", tagClasses.uiWidgetDefinition),
    voteMenu = core.findTag("map_vote_menu", tagClasses.uiWidgetDefinition),
    voteMenuList = core.findTag("vote_menu_list", tagClasses.uiWidgetDefinition),
    amountBar = core.findTag("budget_progress_bar", tagClasses.uiWidgetDefinition),
    loadingMenu = core.findTag("loading_menu", tagClasses.uiWidgetDefinition),
    loadingAnimation = core.findTag("loading_menu_progress_animation", tagClasses.uiWidgetDefinition),
    loadingProgress = core.findTag("loading_progress_bar", tagClasses.uiWidgetDefinition),
    mapsMenu = core.findTag("forge_options_menu\\forge_options_menu", tagClasses.uiWidgetDefinition),
    mapsList = core.findTag("maps_list", tagClasses.uiWidgetDefinition),
    actionsMenu = core.findTag("forge_actions_menu\\forge_actions_menu",
                               tagClasses.uiWidgetDefinition),
    generalMenu = core.findTag("general_menu\\general_menu", tagClasses.uiWidgetDefinition),
    generalMenuList = core.findTag("general_menu\\options\\options", tagClasses.uiWidgetDefinition),
    scrollBar = core.findTag("common\\scroll_bar", tagClasses.uiWidgetDefinition),
    scrollPosition = core.findTag("common\\scroll_position", tagClasses.uiWidgetDefinition),
    warningDialog = core.findTag("warning_dialog", tagClasses.uiWidgetDefinition)
}
constants.uiWidgetDefinitions = uiWidgetDefinitions

-- Unicode string definitions
local unicodeStrings = {
    budgetCountTagId = core.findTag("budget_count", tagClasses.unicodeStringList).id,
    forgeMenuElementsTagId = core.findTag("elements_text", tagClasses.unicodeStringList).id,
    votingMapsListTagId = core.findTag("vote_maps_names", tagClasses.unicodeStringList).id,
    votingCountListTagId = core.findTag("vote_maps_count", tagClasses.unicodeStringList).id,
    paginationTagId = core.findTag("pagination", tagClasses.unicodeStringList).id,
    mapsListTagId = core.findTag("maps_name", tagClasses.unicodeStringList).id,
    pauseGameStringsTagId = core.findTag("titles_and_headers", tagClasses.unicodeStringList).id,
    forgeControlsTagId = core.findTag("forge_controls", tagClasses.unicodeStringList).id,
    generalMenuHeaderTagId = core.findTag("general_menu\\strings\\header",
                                          tagClasses.unicodeStringList).id,
    generalMenuStringsTagId = core.findTag("general_menu\\strings\\options",
                                           tagClasses.unicodeStringList).id,
    generalMenuValueStringsTagId = core.findTag("general_menu\\strings\\values",
                                                tagClasses.unicodeStringList).id,
    dialogStringsId = core.findTag("dialog_menu\\strings\\header_and_message",
                                   tagClasses.unicodeStringList).id
}
constants.unicodeStrings = unicodeStrings

constants.hsc = {playSound = [[(begin (sound_impulse_start "%s" (list_get (players) %s) %s))]]}

constants.sounds = {
    landHardPlayerDamagePath = core.findTag("land_hard_plyr_dmg", tagClasses.sound).path,
    uiForwardPath = core.findTag("forward", tagClasses.sound).path
}

--[[local swordProjectileTagPath, swordProjectileTagIndex =
    core.findTag("slash", tagClasses.projectile)
constants.swordProjectileTagIndex = swordProjectileTagIndex]]

constants.colors = {
    white = "#FFFFFF",
    black = "#000000",
    red = "#FE0000",
    blue = "#0201E3",
    gray = "#707E71",
    yellow = "#FFFF01",
    green = "#00FF01",
    pink = "#FF56B9",
    purple = "#AB10F4",
    cyan = "#01FFFF",
    cobalt = "#6493ED",
    orange = "#FF7F00",
    teal = "#1ECC91",
    sage = "#006401",
    brown = "#603814",
    tan = "#C69C6C",
    maroon = "#9D0B0E",
    salmon = "#F5999E"
}

constants.colorsNumber = {
    constants.colors.white,
    constants.colors.black,
    constants.colors.red,
    constants.colors.blue,
    constants.colors.gray,
    constants.colors.yellow,
    constants.colors.green,
    constants.colors.pink,
    constants.colors.purple,
    constants.colors.cyan,
    constants.colors.cobalt,
    constants.colors.orange,
    constants.colors.teal,
    constants.colors.sage,
    constants.colors.brown,
    constants.colors.tan,
    constants.colors.maroon,
    constants.colors.salmon
}

-- Name to search in some tags that are ignored at hidding objects as spartan
constants.hideObjectsExceptions = {"stand", "teleporters"}
constants.objectsMigration = {
    ["[shm]\\halo_4\\scenery\\spawning\\vehicles\\warthog spawn\\warthog spawn"] = "[shm]\\halo_4\\scenery\\spawning\\vehicles\\warthogs\\warthog spawn\\warthog spawn",
    ["[shm]\\halo_4\\scenery\\spawning\\vehicles\\rocket warthog spawn\\rocket warthog spawn"] = "[shm]\\halo_4\\scenery\\spawning\\vehicles\\warthogs\\rocket warthog spawn\\rocket warthog spawn"
}

-- constants.teleportersChannels = {alpha = 0, bravo = 1, charly = 2, delta = 3, echo = }
constants.teleportersChannels = {
    "alpha",
    "bravo",
    "charly",
    "delta",
    "echo",
    "foxtrot",
    "golf",
    "hotel",
    "india",
    "juliett",
    "kilo"
}

dprint(string.format("Constants gathered, elapsed time: %.6f\n", os.clock() - time))

return constants

end,

["forge.core"] = function()
--------------------
-- Module: 'forge.core'
--------------------
------------------------------------------------------------------------------
-- Forge Core
-- Sledmine
-- Core functionality for Forge
---------------------------------------------------------------------------
-- Lua libraries
local inspect = require "inspect"
local glue = require "glue"
local json = require "json"
local ini = require "lua-ini"

-- Optimizations
local sin = math.sin
local cos = math.cos
local rad = math.rad
local sqrt = math.sqrt
local abs = math.abs
local floor = math.floor
local concat = table.concat

local core = {}

-- Halo libraries
local maeth = require "maethrillian"

--- Load Forge configuration from previous files
---@param path string Path of the configuration folder
function core.loadForgeConfiguration(path)
    if (not path) then
        path = defaultConfigurationPath
    end
    if (not directory_exists(path)) then
        create_directory(path)
    end
    local configurationFilePath = path .. "\\" .. scriptName .. ".ini"
    local configurationFile = read_file(configurationFilePath)
    if (configurationFile) then
        local loadedConfiguration = ini.decode(configurationFile)
        if (loadedConfiguration and #glue.keys(loadedConfiguration) > 0) then
            config = loadedConfiguration
        else
            console_out(configurationFilePath)
            console_out("Forge ini file has a wrong format or is corrupted!")
        end
    end
end

--- Normalize any map name or snake case name to sentence case
---@param name string
function core.toSentenceCase(name)
    return string.gsub(" " .. name:gsub("_", " "), "%W%l", string.upper):sub(2)
end

--- Normalize any string to lower snake case
---@param name string
function core.toSnakeCase(name)
    return name:gsub(" ", "_"):lower()
end

--- Normalize any string to camel case
---@param name string
function core.toCamelCase(name)
    return string.gsub("" .. name:gsub("_", " "), "%W%l", string.upper):sub(1):gsub(" ", "")
end

--- Load previous Forge maps
---@param path string Path of the maps folder
function core.loadForgeMaps(path)
    if (not path) then
        path = defaultMapsPath
    end
    if (not directory_exists(path)) then
        create_directory(path)
    end
    local mapsFiles = list_directory(path)
    local mapsList = {}
    for fileIndex, file in pairs(mapsFiles) do
        if (not file:find("\\")) then
            local dotSplitFile = glue.string.split(file, ".")
            local fileExtension = dotSplitFile[#dotSplitFile]
            -- Only load files with extension .fmap
            if (fileExtension == "fmap") then
                -- Normalize map name
                local fileName = file:gsub(".fmap", "")
                local mapName = core.toSentenceCase(fileName)
                glue.append(mapsList, mapName)
            end
        end
    end
    -- Dispatch state modification!
    local data = {mapsList = mapsList}
    forgeStore:dispatch({type = "UPDATE_MAP_LIST", payload = data})
end

-- //TODO Refactor this to use lua blam objects
-- Credits to Devieth and IceCrow14
--- Check if player is looking at object main frame
---@param target number
---@param sensitivity number
---@param zOffset number
---@param maximumDistance number
function core.playerIsAimingAt(target, sensitivity, zOffset, maximumDistance)
    -- Minimum amount for distance scaling
    local baselineSensitivity = 0.012
    local function read_vector3d(Address)
        return read_float(Address), read_float(Address + 0x4), read_float(Address + 0x8)
    end
    local mainObject = get_dynamic_player()
    local targetObject = get_object(target)
    -- Both objects must exist
    if (targetObject and mainObject) then
        local playerX, playerY, playerZ = read_vector3d(mainObject + 0xA0)
        local cameraX, cameraY, cameraZ = read_vector3d(mainObject + 0x230)
        -- Target location 2
        local targetX, targetY, targetZ = read_vector3d(targetObject + 0x5C)
        -- 3D distance
        local distance = sqrt((targetX - playerX) ^ 2 + (targetY - playerY) ^ 2 +
                                  (targetZ - playerZ) ^ 2)
        local localX = targetX - playerX
        local localY = targetY - playerY
        local localZ = (targetZ + (zOffset or 0)) - playerZ
        local pointX = 1 / distance * localX
        local pointY = 1 / distance * localY
        local pointZ = 1 / distance * localZ
        local xDiff = abs(cameraX - pointX)
        local yDiff = abs(cameraY - pointY)
        local zDiff = abs(cameraZ - pointZ)
        local average = (xDiff + yDiff + zDiff) / 3
        local scaler = 0
        if distance > 10 then
            scaler = floor(distance) / 1000
        end
        local autoAim = sensitivity - scaler
        if autoAim < baselineSensitivity then
            autoAim = baselineSensitivity
        end
        if average < autoAim and distance < (maximumDistance or 15) then
            return true
        end
    end
    return false
end

---@class vector3D
---@field x number
---@field y number
---@field z number

--- Covert euler into game rotation array, optional rotation matrix
-- Based on https://www.mecademic.com/en/how-is-orientation-in-space-represented-with-euler-angles
--- @param yaw number
--- @param pitch number
--- @param roll number
--- @return vector3D, vector3D
function core.eulerToRotation(yaw, pitch, roll)
    local yaw = math.rad(yaw)
    local pitch = math.rad(-pitch) -- Negative pitch due to Sapien handling anticlockwise pitch
    local roll = math.rad(roll)
    local matrix = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}}

    -- Roll, Pitch, Yaw = a, b, y
    local cosA = math.cos(roll)
    local sinA = math.sin(roll)
    local cosB = math.cos(pitch)
    local sinB = math.sin(pitch)
    local cosY = math.cos(yaw)
    local sinY = math.sin(yaw)

    matrix[1][1] = cosB * cosY
    matrix[1][2] = -cosB * sinY
    matrix[1][3] = sinB
    matrix[2][1] = cosA * sinY + sinA * sinB * cosY
    matrix[2][2] = cosA * cosY - sinA * sinB * sinY
    matrix[2][3] = -sinA * cosB
    matrix[3][1] = sinA * sinY - cosA * sinB * cosY
    matrix[3][2] = sinA * cosY + cosA * sinB * sinY
    matrix[3][3] = cosA * cosB

    local rollVector = {x = matrix[1][1], y = matrix[2][1], z = matrix[3][1]}
    local yawVector = {x = matrix[1][3], y = matrix[2][3], z = matrix[3][3]}
    return rollVector, yawVector, matrix
end

--- Rotate object into desired angles
---@param objectId number
---@param yaw number
---@param pitch number
---@param roll number
function core.rotateObject(objectId, yaw, pitch, roll)
    local rollVector, yawVector, matrix = core.eulerToRotation(yaw, pitch, roll)
    local object = blam.object(get_object(objectId))
    -- Debug rotation pivots
    --[[if (config.forge.debugMode) then
        if (not globalPivotId) then
            local pivotTag = core.findTag("pivot", tagClasses.scenery)
            globalPivotId = core.spawnObject(tagClasses.scenery, pivotTag.path, object.vX,
                                             object.vY, object.vZ)
            globalPivotId2 = core.spawnObject(tagClasses.scenery, pivotTag.path, object.v2X,
                                              object.v2Y, object.v2Z)
            globalPivotId3 = core.spawnObject(tagClasses.scenery, pivotTag.path, object.x, object.y,
                                              object.z)
            globalPivotId4 = core.spawnObject(tagClasses.scenery, pivotTag.path, object.x, object.y,
                                              object.z)
        end
        local pivot = blam.object(get_object(globalPivotId))
        local pivot2 = blam.object(get_object(globalPivotId2))
        local pivot3 = blam.object(get_object(globalPivotId3))
        local pivot4 = blam.object(get_object(globalPivotId4))
        -- Object pivot + rotation
        pivot.x = object.x
        pivot.y = object.y
        pivot.z = object.z
        pivot.vX = rollVector.x
        pivot.vY = rollVector.y
        pivot.vZ = rollVector.z
        pivot.v2X = yawVector.x
        pivot.v2Y = yawVector.y
        pivot.v2Z = yawVector.z

        -- Roll pivot
        pivot2.x = object.x + rollVector.x
        pivot2.y = object.y + rollVector.y
        pivot2.z = object.z + rollVector.z

        -- Yaw pivot
        pivot3.x = object.x + yawVector.x
        pivot3.y = object.y + yawVector.y
        pivot3.z = object.z + yawVector.z

        -- Pitch pivot (imaginary)
        pivot4.x = object.x + matrix[1][2]
        pivot4.y = object.y + matrix[2][2]
        pivot4.z = object.z + matrix[3][2]
    end]]

    -- Apply final rotation to desired object
    object.vX = rollVector.x
    object.vY = rollVector.y
    object.vZ = rollVector.z
    object.v2X = yawVector.x
    object.v2Y = yawVector.y
    object.v2Z = yawVector.z
end

--[[function core.rotatePoint(x, y, z)
end]]

--- Check if current player is using a monitor biped
---@return boolean
function core.isPlayerMonitor(playerIndex)
    local tempObject
    if (playerIndex) then
        tempObject = blam.object(get_dynamic_player(playerIndex))
    else
        if (blam.isGameSAPP()) then
            return false
        end
        tempObject = blam.object(get_dynamic_player())
    end
    if (tempObject and tempObject.tagId == const.bipeds.monitorTagId) then
        return true
    end
    return false
end

--- Send a request to the server throug rcon
---@return boolean success
---@return string request
function core.sendRequest(request, playerIndex)
    dprint("-> [ Sending request ]")
    dprint("Request: " .. request)
    if (server_type == "local") then
        OnRcon(request)
        return true, request
    elseif (server_type == "dedicated") then
        -- Player is connected to a server
        local fixedRequest = "rcon forge '" .. request .. "'"
        execute_script(fixedRequest)
        return true, fixedRequest
    elseif (server_type == "sapp") then
        dprint("Server request: " .. request)
        -- We want to broadcast to every player in the server
        if (not playerIndex) then
            grprint(request)
        else
            -- We are looking to send data to a specific player
            rprint(playerIndex, request)
        end
        return true, request
    end
    return false
end

---@class requestTable
---@field requestType string

--- Create a request from a request object
---@param requestTable requestTable
function core.createRequest(requestTable)
    local instanceObject = glue.update({}, requestTable)
    local request
    if (instanceObject) then
        -- Create an object instance to avoid wrong reference asignment
        local requestType = instanceObject.requestType
        if (requestType) then
            if (requestType == const.requests.spawnObject.requestType) then
                if (server_type == "sapp") then
                    instanceObject.remoteId = requestTable.remoteId
                end
            elseif (requestType == const.requests.updateObject.requestType) then
                if (server_type ~= "sapp") then
                    -- Desired object id is our remote id
                    -- instanceObject.objectId = requestTable.remoteId
                end
            elseif (requestType == const.requests.deleteObject.requestType) then
                if (server_type ~= "sapp") then
                    -- Desired object id is our remote id
                    instanceObject.objectId = requestTable.remoteId
                end
            end
            local requestFormat
            for requestIndex, request in pairs(const.requests) do
                if (requestType == request.requestType) then
                    requestFormat = request.requestFormat
                end
            end
            local encodedTable = maeth.encodeTable(instanceObject, requestFormat)
            --[[print(inspect(requestFormat))
            print(inspect(requestTable))]]
            request = maeth.tableToRequest(encodedTable, requestFormat, const.requestSeparator)
            -- TODO Add size validation for requests
            dprint("Request size: " .. #request)
        else
            -- print(inspect(instanceObject))
            error("There is no request type in this request!")
        end
        return request
    end
    return nil
end

--- Process every request as a server
function core.processRequest(actionType, request, currentRequest, playerIndex)
    dprint("-> [ Receiving request ]")
    dprint("Incoming request: " .. request)
    dprint("Parsing incoming " .. actionType .. " ...", "warning")
    local requestTable = maeth.requestToTable(request, currentRequest.requestFormat,
                                              const.requestSeparator)
    if (requestTable) then
        dprint("Done.", "success")
        dprint(inspect(requestTable))
    else
        dprint("Error at converting request.", "error")
        return false, nil
    end
    dprint("Decoding incoming " .. actionType .. " ...", "warning")
    dprint("Request size: " .. #request)
    local requestObject = maeth.decodeTable(requestTable, currentRequest.requestFormat)
    if (requestObject) then
        dprint("Done.", "success")
    else
        dprint("Error at decoding request.", "error")
        return false, nil
    end
    if (not ftestingMode) then
        eventsStore:dispatch({
            type = actionType,
            payload = {requestObject = requestObject},
            playerIndex = playerIndex
        })
    end
    return false, requestObject
end

function core.resetSpawnPoints()
    local scenario = blam.scenario()
    local netgameFlagsTypes = blam.netgameFlagTypes

    local mapSpawnCount = scenario.spawnLocationCount
    local vehicleLocationCount = scenario.vehicleLocationCount
    local netgameFlagsCount = scenario.netgameFlagsCount
    dprint("Found " .. mapSpawnCount .. " stock player starting points!")
    dprint("Found " .. vehicleLocationCount .. " stock vehicle location points!")
    dprint("Found " .. netgameFlagsCount .. " stock netgame flag points!")
    -- Reset any spawn point
    local mapSpawnPoints = scenario.spawnLocationList
    for i = 1, mapSpawnCount do
        -- Disable them by setting type to 0
        mapSpawnPoints[i].type = 0
    end

    local vehicleLocationList = scenario.vehicleLocationList
    for i = 2, vehicleLocationCount do
        -- Disable spawn and try to erase object from the map
        vehicleLocationList[i].type = 65535
        -- TODO There should be a way to get object name from memory
        execute_script("object_destroy v" .. vehicleLocationList[i].nameIndex)
    end

    -- Reset any teleporter point, skipping first 3 points
    -- those are reserved for Red and Blue CTF flags, the third one is for the 
    -- oddball spawn point
    local netgameFlagsList = scenario.netgameFlagsList
    for i = 4, netgameFlagsCount do
        -- Disabling spawn point by setting to an unused type "vegas - bank"
        netgameFlagsList[i].type = netgameFlagsTypes.vegasBank
    end

    scenario.spawnLocationList = mapSpawnPoints
    scenario.vehicleLocationList = vehicleLocationList
    scenario.netgameFlagsList = netgameFlagsList
end

function core.flushForge()
    if (eventsStore) then
        local forgeObjects = eventsStore:getState().forgeObjects
        if (#glue.keys(forgeObjects) > 0 and #blam.getObjects() > 0) then
            -- saveForgeMap('unsaved')
            -- execute_script('object_destroy_all')
            for objectId, forgeObject in pairs(forgeObjects) do
                delete_object(objectId)
            end
            eventsStore:dispatch({type = "FLUSH_FORGE"})
        end
    end
end

function core.sendMapData(forgeMap, playerIndex)
    if (server_type == "sapp") then
        local mapDataResponse = {}
        local response
        -- Send main map data
        mapDataResponse.requestType = const.requests.loadMapScreen.requestType
        mapDataResponse.objectCount = #forgeMap.objects
        mapDataResponse.mapName = forgeMap.name
        response = core.createRequest(mapDataResponse)
        core.sendRequest(response, playerIndex)
        -- Send map author
        mapDataResponse = {}
        mapDataResponse.requestType = const.requests.setMapAuthor.requestType
        mapDataResponse.mapAuthor = forgeMap.author
        response = core.createRequest(mapDataResponse)
        core.sendRequest(response, playerIndex)
        -- Send map description
        mapDataResponse = {}
        mapDataResponse.requestType = const.requests.setMapDescription.requestType
        mapDataResponse.mapDescription = forgeMap.description
        response = core.createRequest(mapDataResponse)
        core.sendRequest(response, playerIndex)
    end
end

-- //TODO Add unit testing for this function
--- Return if the map is forge available
---@param mapName string
---@return boolean
function core.isForgeMap(mapName)
    dprint(mapName)
    dprint(map)
    return (mapName == map .. "_dev" or mapName == map .. "_beta" or mapName == map) or
               (mapName == map:gsub("_dev", ""))
end

function core.loadForgeMap(mapName)
    if (server_type == "dedicated") then
        console_out("You can not load a map while connected to a server!'")
        return false
    end
    local fmapContent = read_file(defaultMapsPath .. "\\" .. mapName .. ".fmap")
    if (fmapContent) then
        dprint("Loading forge map...")
        local forgeMap = json.decode(fmapContent)
        if (forgeMap) then
            if (not core.isForgeMap(forgeMap.map)) then
                console_out("This forge map was not made for " .. map .. "!")
                return false
            end
            -- Load data into store
            forgeStore:dispatch({
                type = "SET_MAP_DATA",
                payload = {
                    mapName = forgeMap.name,
                    mapDescription = forgeMap.description,
                    mapAuthor = forgeMap.author
                }
            })
            core.sendMapData(forgeMap)

            -- Reset all spawn points to default
            core.resetSpawnPoints()

            -- Remove menu blur after reloading server on local mode
            if (server_type == "local") then
                execute_script("menu_blur_off")
                core.flushForge()
            end

            console_out(string.format("\nLoading Forge objects for %s...", mapName))
            local time = os.clock()
            for objectId, forgeObject in pairs(forgeMap.objects) do
                local spawnRequest = forgeObject
                local objectTagPath = const.objectsMigration[spawnRequest.tagPath]
                local objectTag = blam.getTag(objectTagPath or spawnRequest.tagPath,
                                              tagClasses.scenery)
                if (objectTag and objectTag.id) then
                    spawnRequest.requestType = const.requests.spawnObject.requestType
                    spawnRequest.tagPath = nil
                    spawnRequest.tagId = objectTag.id
                    spawnRequest.color = forgeObject.color or 1
                    spawnRequest.teamIndex = forgeObject.teamIndex or 0
                    -- Old Forge migration from bad rotation function
                    --local backupRoll = spawnRequest.roll
                    --spawnRequest.roll = spawnRequest.pitch
                    --spawnRequest.pitch = 360 - backupRoll
                    --if (spawnRequest.pitch > 85 and spawnRequest.roll > 265) then
                    --    spawnRequest.pitch = spawnRequest.pitch - 90
                    --    spawnRequest.yaw = spawnRequest.yaw + 90
                    --end
                    eventsStore:dispatch({
                        type = const.requests.spawnObject.actionType,
                        payload = {requestObject = spawnRequest}
                    })
                else
                    dprint("Warning, object with path \"" .. spawnRequest.tagPath ..
                               "\" can not be spawned...", "warning")
                    -- error(debug.traceback("An object tag can't be spawned"), 2)
                end
            end
            forgeMapFinishedLoading = true
            console_out(string.format("Done, elapsed time: %.6f\n", os.clock() - time))
            dprint("Succesfully loaded '" .. mapName .. "' fmap!")

            if (server_type == "local") then
                execute_script("sv_map_reset")
            end

            return true
        else
            console_out("Error at decoding data from \"" .. mapName .. "\" forge map...")
            return false
        end
    else
        dprint("Error at trying to load '" .. mapName .. "' as a forge map...", "error")
        if (server_type == "sapp") then
            grprint("Error at trying to load '" .. mapName .. "' as a forge map...")
        end
    end
    return false
end

function core.saveForgeMap()
    ---@type forgeState
    local forgeState = forgeStore:getState()
    local mapName = forgeState.currentMap.name
    local mapDescription = forgeState.currentMap.description
    local mapAuthor = forgeState.currentMap.author
    if (mapAuthor == "Unknown") then
        mapAuthor = blam.readUnicodeString(get_player() + 0x4, true)
    end
    if (mapName == "Unsaved") then
        console_out("WARNING, You have to give a name to your map before saving!")
        console_out("Use command:")
        console_out("fname <name_of_your_map>")
        return false
    end
    -- List used to store data of every object in the forge map
    local forgeMap = {
        name = mapName,
        author = mapAuthor,
        description = mapDescription,
        version = "",
        map = map,
        objects = {}
    }

    -- Get the state of the forge objects
    local objectsState = eventsStore:getState().forgeObjects

    console_out("Saving forge map...")
    -- Iterate through all the forge objects
    for objectId, forgeObject in pairs(objectsState) do
        -- Get scenery tag path to keep compatibility between versions
        local tempObject = blam.object(get_object(objectId))
        local sceneryPath = blam.getTag(tempObject.tagId).path

        -- Create a copy of the composed object in the store to avoid replacing useful values
        local forgeObjectInstance = glue.update({}, forgeObject)

        -- Remove all the unimportant data
        forgeObjectInstance.objectId = nil
        forgeObjectInstance.reflectionId = nil
        forgeObjectInstance.remoteId = nil
        forgeObjectInstance.requestType = nil

        -- Add tag path property
        forgeObjectInstance.tagPath = sceneryPath

        -- Add forge object to list
        glue.append(forgeMap.objects, forgeObjectInstance)
    end

    ---@class forgeObjectData
    ---@field tagPath string
    ---@field x number
    ---@field y number
    ---@field z number
    ---@field yaw number
    ---@field pitch number
    ---@field roll number
    ---@field teamIndex  number
    ---@field color number

    ---@class forgeMap
    ---@field description string
    ---@field author string
    ---@field map string
    ---@field version string
    ---@field objects forgeObjectData[]

    -- Encode map info as json
    ---@type forgeMap
    local fmapContent = json.encode(forgeMap)

    -- Standarize map name
    mapName = string.gsub(mapName, " ", "_"):lower()

    local forgeMapPath = defaultMapsPath .. "\\" .. mapName .. ".fmap"

    local forgeMapSaved = write_file(forgeMapPath, fmapContent)

    -- Check if file was created
    if (forgeMapSaved) then
        console_out("Forge map " .. mapName .. " has been succesfully saved!",
                    blam.consoleColors.success)

        -- Avoid maps reload on server due to lack of a file system on the server side
        if (server_type ~= "sapp") then
            -- Reload forge maps list
            core.loadForgeMaps()
        end

    else
        dprint("ERROR!! At saving '" .. mapName .. "' as a forge map...", "error")
    end
end

--- Force object shadow casting if available
-- TODO Move this into features module
---@param object blamObject
function core.forceShadowCasting(object)
    -- Force the object to render shadow
    if (object.tagId ~= const.forgeProjectileTagId) then
        dprint("Bounding Radius: " .. object.boundingRadius)
        if (config.forge.objectsCastShadow and object.boundingRadius <=
            const.maximumRenderShadowRadius and object.z < const.maximumZRenderShadow) then
            object.boundingRadius = object.boundingRadius * 1.2
            object.isNotCastingShadow = false
        end
    end
end

--- Super function for debug printing and non self blocking spawning
---@param type string
---@param tagPath string
---@param x number
---@param y number
---@param z number
---@return number | nil objectId
function core.spawnObject(type, tagPath, x, y, z, noLog)
    if (not noLog) then
        dprint(" -> [ Object Spawning ]")
        dprint("Type:", "category")
        dprint(type)
        dprint("Tag  Path:", "category")
        dprint(tagPath)
        dprint("Position:", "category")
        local positionString = "%s: %s: %s:"
        dprint(positionString:format(x, y, z))
        dprint("Trying to spawn object...", "warning")
    end
    -- Prevent objects from phantom spawning!
    local objectId = spawn_object(type, tagPath, x, y, z)
    if (objectId) then
        local object = blam.object(get_object(objectId))
        if (not object) then
            console_out(("Error, game can't spawn %s on %s %s %s"):format(tagPath, x, y, z))
            return nil
        end
        -- Force the object to render shadow
        core.forceShadowCasting(object)

        -- FIXME Object inside bsp detection is not working in SAPP, use minimumZSpawnPoint instead!
        if (server_type == "sapp") then
            -- SAPP for some reason can not detect if an object was spawned inside the map
            -- So we need to create an instance of the object and add the flag to it
            if (z < const.minimumZSpawnPoint) then
                object = blam.dumpObject(object)
                object.isOutSideMap = true
            end
            if (not noLog) then
                dprint("Object is outside map: " .. tostring(object.isOutSideMap))
            end
        end
        if (object.isOutSideMap) then
            if (not noLog) then
                dprint("-> Object: " .. objectId .. " is INSIDE map!!!", "warning")
            end

            -- Erase object to spawn it later in a safe place
            delete_object(objectId)

            -- Create new object but now in a safe place
            objectId = spawn_object(type, tagPath, x, y, const.minimumZSpawnPoint)

            if (objectId) then
                -- Update new object position to match the original
                local tempObject = blam.object(get_object(objectId))
                tempObject.x = x
                tempObject.y = y
                tempObject.z = z

                -- Force the object to render shadow
                core.forceShadowCasting(object)
            end
        end

        if (not noLog) then
            dprint("-> \"" .. tagPath .. "\" succesfully spawned!", "success")
        end
        return objectId
    end
    dprint("Error at trying to spawn object!!!!", "error")
    return nil
end

--- Apply updates for player spawn points based on a given tag path
---@param tagPath string
---@param forgeObject table
---@param disable boolean
function core.updatePlayerSpawn(tagPath, forgeObject, disable)
    local teamIndex = 0
    local gameType = 0

    -- TODO Refactor this to make it dynamic, also use blam constants instad of static game types
    -- Get spawn info from tag name
    if (tagPath:find("ctf")) then
        dprint("CTF")
        gameType = 1
    elseif (tagPath:find("slayer")) then
        if (tagPath:find("generic")) then
            dprint("SLAYER")
        else
            dprint("TEAM_SLAYER")
        end
        gameType = 2
    elseif (tagPath:find("oddball")) then
        dprint("ODDBALL")
        gameType = 3
    elseif (tagPath:find("koth")) then
        dprint("KOTH")
        gameType = 4
    elseif (tagPath:find("race")) then
        dprint("RACE")
        gameType = 5
    end

    if (tagPath:find("red")) then
        dprint("RED TEAM SPAWN")
        teamIndex = 0
    elseif (tagPath:find("blue")) then
        dprint("BLUE TEAM SPAWN")
        teamIndex = 1
    end

    -- Get scenario data
    local scenario = blam.scenario(0)

    -- Get scenario player spawn points
    local mapSpawnPoints = scenario.spawnLocationList

    -- Object is not already reflecting a spawn point
    if (not forgeObject.reflectionId) then
        for spawnId = 1, #mapSpawnPoints do
            -- If this spawn point is disabled
            if (mapSpawnPoints[spawnId].type == 0) then
                -- Replace spawn point values
                mapSpawnPoints[spawnId].x = forgeObject.x
                mapSpawnPoints[spawnId].y = forgeObject.y
                mapSpawnPoints[spawnId].z = forgeObject.z
                mapSpawnPoints[spawnId].rotation = rad(forgeObject.yaw)
                mapSpawnPoints[spawnId].teamIndex = teamIndex
                mapSpawnPoints[spawnId].type = gameType

                -- Debug spawn index
                dprint("Creating spawn replacing index: " .. spawnId, "warning")
                forgeObject.reflectionId = spawnId
                break
            end
        end
    else
        dprint("Erasing spawn with index: " .. forgeObject.reflectionId)
        if (disable) then
            -- Disable or "delete" spawn point by setting type as 0
            mapSpawnPoints[forgeObject.reflectionId].type = 0
            -- Update spawn point list
            scenario.spawnLocationList = mapSpawnPoints
            return true
        end
        -- Replace spawn point values
        mapSpawnPoints[forgeObject.reflectionId].x = forgeObject.x
        mapSpawnPoints[forgeObject.reflectionId].y = forgeObject.y
        mapSpawnPoints[forgeObject.reflectionId].z = forgeObject.z
        mapSpawnPoints[forgeObject.reflectionId].rotation = rad(forgeObject.yaw)
        dprint(mapSpawnPoints[forgeObject.reflectionId].type)
        -- Debug spawn index
        dprint("Updating spawn replacing index: " .. forgeObject.reflectionId)
    end
    -- Update spawn point list
    scenario.spawnLocationList = mapSpawnPoints
end

--- Apply updates to netgame flags spawn points based on a tag path
---@param tagPath string
---@param forgeObject table
---@param disable boolean
function core.updateNetgameFlagSpawn(tagPath, forgeObject, disable)
    -- TODO Review if some flags use team index as "group index"!
    local teamIndex = 0
    local flagType = 0
    local netgameFlagsTypes = blam.netgameFlagTypes

    -- Set flag type from tag path
    --[[
        0 = ctf - flag
        1 = ctf - vehicle
        2 = oddball - ball spawn
        3 = race - track
        4 = race - vehicle
        5 = vegas - bank (?) WHAT, I WAS NOT AWARE OF THIS THING!
        6 = teleport from
        7 = teleport to
        8 = hill flag
    ]]
    if (tagPath:find("flag stand")) then
        dprint("FLAG POINT")
        flagType = netgameFlagsTypes.ctfFlag
        -- TODO Check if double setting team index against default value is needed!
        if (tagPath:find("red")) then
            dprint("RED TEAM FLAG")
            teamIndex = 0
        else
            dprint("BLUE TEAM FLAG")
            teamIndex = 1
        end
    elseif (tagPath:find("oddball")) then
        -- TODO Check and add weapon based netgame flags like oddball!
        dprint("ODDBALL FLAG")
        flagType = netgameFlagsTypes.ballSpawn
    elseif (tagPath:find("receiver")) then
        dprint("TELEPORT TO")
        flagType = netgameFlagsTypes.teleportTo
    elseif (tagPath:find("sender")) then
        dprint("TELEPORT FROM")
        flagType = netgameFlagsTypes.teleportFrom
    else
        dprint("Unknown netgame flag tag: " .. tagPath, "error")
    end

    -- Get scenario data
    local scenario = blam.scenario(0)

    -- Get scenario player spawn points
    local mapNetgameFlagsPoints = scenario.netgameFlagsList

    -- Object is not already reflecting a flag point
    if (not forgeObject.reflectionId) then
        for flagIndex = 1, #mapNetgameFlagsPoints do
            -- FIXME This control block is not neccessary but needs improvements!
            -- If this flag point is using the same flag type
            if (mapNetgameFlagsPoints[flagIndex].type == flagType and
                mapNetgameFlagsPoints[flagIndex].teamIndex == teamIndex and
                (flagType ~= netgameFlagsTypes.teleportFrom and flagType ~=
                    netgameFlagsTypes.teleportTo)) then
                -- Replace spawn point values
                mapNetgameFlagsPoints[flagIndex].x = forgeObject.x
                mapNetgameFlagsPoints[flagIndex].y = forgeObject.y
                -- Z plus an offset to prevent flag from falling in lower bsp values
                mapNetgameFlagsPoints[flagIndex].z = forgeObject.z + 0.15
                mapNetgameFlagsPoints[flagIndex].rotation = rad(forgeObject.yaw)
                mapNetgameFlagsPoints[flagIndex].teamIndex = teamIndex
                mapNetgameFlagsPoints[flagIndex].type = flagType

                -- Debug spawn index
                dprint("Creating flag replacing index: " .. flagIndex, "warning")
                forgeObject.reflectionId = flagIndex
                break
            elseif (mapNetgameFlagsPoints[flagIndex].type == netgameFlagsTypes.vegasBank and
                (flagType == netgameFlagsTypes.teleportTo or flagType ==
                    netgameFlagsTypes.teleportFrom)) then
                dprint("Creating teleport replacing index: " .. flagIndex, "warning")
                dprint("With team index: " .. forgeObject.teamIndex, "warning")
                -- Replace spawn point values
                mapNetgameFlagsPoints[flagIndex].x = forgeObject.x
                mapNetgameFlagsPoints[flagIndex].y = forgeObject.y
                -- Z plus an offset to prevent flag from falling in lower bsp values
                mapNetgameFlagsPoints[flagIndex].z = forgeObject.z + 0.15
                mapNetgameFlagsPoints[flagIndex].rotation = rad(forgeObject.yaw)
                mapNetgameFlagsPoints[flagIndex].teamIndex = forgeObject.teamIndex
                mapNetgameFlagsPoints[flagIndex].type = flagType
                forgeObject.reflectionId = flagIndex
                break
            end
        end
    else
        if (disable) then
            if (flagType == netgameFlagsTypes.teleportTo or flagType ==
                netgameFlagsTypes.teleportFrom) then
                dprint("Erasing netgame flag teleport with index: " .. forgeObject.reflectionId)
                -- Vegas bank is a unused gametype, so this is basically the same as disabling it
                mapNetgameFlagsPoints[forgeObject.reflectionId].type = netgameFlagsTypes.vegasBank
            end
        else
            -- Replace spawn point values
            mapNetgameFlagsPoints[forgeObject.reflectionId].x = forgeObject.x
            mapNetgameFlagsPoints[forgeObject.reflectionId].y = forgeObject.y
            mapNetgameFlagsPoints[forgeObject.reflectionId].z = forgeObject.z
            mapNetgameFlagsPoints[forgeObject.reflectionId].rotation = rad(forgeObject.yaw)
            if (flagType == netgameFlagsTypes.teleportFrom or flagType ==
                netgameFlagsTypes.teleportTo) then
                dprint("Update teamIndex: " .. forgeObject.teamIndex)
                mapNetgameFlagsPoints[forgeObject.reflectionId].teamIndex = forgeObject.teamIndex
            end
            -- Debug spawn index
            dprint("Updating flag replacing index: " .. forgeObject.reflectionId, "warning")
        end
    end
    -- Update spawn point list
    scenario.netgameFlagsList = mapNetgameFlagsPoints
end

--- Apply updates to equipment netgame points based on a given tag path
---@param tagPath string
---@param forgeObject table
---@param disable boolean
function core.updateNetgameEquipmentSpawn(tagPath, forgeObject, disable)
    local itemCollectionTagId
    local tagSplitPath = glue.string.split(tagPath, "\\")
    local desiredWeapon = tagSplitPath[#tagSplitPath]:gsub(" spawn", "")
    dprint(desiredWeapon)
    -- Get equipment info from tag name
    if (desiredWeapon) then
        itemCollectionTagId = core.findTag(desiredWeapon, tagClasses.itemCollection).index
    end
    if (not itemCollectionTagId) then
        -- TODO This needs more review
        error("Could not find item collection tag id for desired weapon spawn: " .. tagPath)
        return false
    end

    -- Get scenario data
    local scenario = blam.scenario(0)

    -- Get scenario player spawn points
    local netgameEquipmentPoints = scenario.netgameEquipmentList

    -- Object is not already reflecting a spawn point
    if (not forgeObject.reflectionId) then
        for equipmentId = 1, #netgameEquipmentPoints do
            -- If this spawn point is disabled
            if (netgameEquipmentPoints[equipmentId].type1 == 0) then
                -- Replace spawn point values
                netgameEquipmentPoints[equipmentId].x = forgeObject.x
                netgameEquipmentPoints[equipmentId].y = forgeObject.y
                netgameEquipmentPoints[equipmentId].z = forgeObject.z + 0.2
                netgameEquipmentPoints[equipmentId].facing = rad(forgeObject.yaw)
                netgameEquipmentPoints[equipmentId].type1 = 12
                netgameEquipmentPoints[equipmentId].levitate = true
                netgameEquipmentPoints[equipmentId].itemCollection = itemCollectionTagId

                -- Debug spawn index
                dprint("Creating equipment replacing index: " .. equipmentId, "warning")
                forgeObject.reflectionId = equipmentId
                break
            end
        end
    else
        dprint("Erasing netgame equipment with index: " .. forgeObject.reflectionId)
        if (disable) then
            -- FIXME Weapon object is not being erased in fact, find a way to delete it!
            -- Disable or "delete" equipment point by setting type as 0
            netgameEquipmentPoints[forgeObject.reflectionId].type1 = 0
            -- Update spawn point list
            scenario.netgameEquipmentList = netgameEquipmentPoints
            return true
        end
        -- Replace spawn point values
        netgameEquipmentPoints[forgeObject.reflectionId].x = forgeObject.x
        netgameEquipmentPoints[forgeObject.reflectionId].y = forgeObject.y
        netgameEquipmentPoints[forgeObject.reflectionId].z = forgeObject.z + 0.2
        netgameEquipmentPoints[forgeObject.reflectionId].facing = rad(forgeObject.yaw)
        -- Debug spawn index
        dprint("Updating equipment replacing index: " .. forgeObject.reflectionId)
    end
    -- Update equipment point list
    scenario.netgameEquipmentList = netgameEquipmentPoints
end

--- Enable, update and disable vehicle spawns
-- Must be called after adding scenery object to the store!!
---@return true if found an available spawn
function core.updateVehicleSpawn(tagPath, forgeObject, disable)
    if (server_type == "dedicated") then
        return true
    end
    local vehicleType = 0
    -- Get spawn info from tag name
    if (tagPath:find("banshee")) then
        dprint("banshee")
        vehicleType = 0
    elseif (tagPath:find("rocket warthog")) then
        dprint("rocket warthog")
        vehicleType = 5
    elseif (tagPath:find("civ warthog")) then
        dprint("civ warthog")
        vehicleType = 6
    elseif (tagPath:find("warthog")) then
        dprint("normal warthog")
        vehicleType = 1
    elseif (tagPath:find("ghost")) then
        dprint("ghost")
        vehicleType = 2
    elseif (tagPath:find("scorpion")) then
        dprint("scorpion")
        vehicleType = 3
    elseif (tagPath:find("turret spawn")) then
        dprint("turret")
        vehicleType = 4
    end

    -- Get scenario data
    local scenario = blam.scenario(0)

    local vehicleLocationCount = scenario.vehicleLocationCount
    dprint("Maximum count of vehicle spawn points: " .. vehicleLocationCount)

    local vehicleSpawnPoints = scenario.vehicleLocationList

    -- Object exists, it's synced
    if (not forgeObject.reflectionId) then
        for spawnId = 2, #vehicleSpawnPoints do
            if (vehicleSpawnPoints[spawnId].type == 65535) then
                -- Replace spawn point values
                vehicleSpawnPoints[spawnId].x = forgeObject.x
                vehicleSpawnPoints[spawnId].y = forgeObject.y
                vehicleSpawnPoints[spawnId].z = forgeObject.z
                vehicleSpawnPoints[spawnId].yaw = rad(forgeObject.yaw)
                vehicleSpawnPoints[spawnId].pitch = rad(forgeObject.pitch)
                vehicleSpawnPoints[spawnId].roll = rad(forgeObject.roll)

                vehicleSpawnPoints[spawnId].type = vehicleType

                -- Debug spawn index
                dprint("Creating spawn replacing index: " .. spawnId)
                forgeObject.reflectionId = spawnId

                -- Update spawn point list
                scenario.vehicleLocationList = vehicleSpawnPoints

                dprint("object_create_anew v" .. vehicleSpawnPoints[spawnId].nameIndex)
                execute_script("object_create_anew v" .. vehicleSpawnPoints[spawnId].nameIndex)
                -- Stop looking for "available" spawn slots
                break
            end
        end
    else
        dprint(forgeObject.reflectionId)
        if (disable) then
            -- Disable or "delete" spawn point by setting type as 65535
            vehicleSpawnPoints[forgeObject.reflectionId].type = 65535
            -- Update spawn point list
            scenario.vehicleLocationList = vehicleSpawnPoints
            dprint("object_create_anew v" .. vehicleSpawnPoints[forgeObject.reflectionId].nameIndex)
            execute_script("object_destroy v" ..
                               vehicleSpawnPoints[forgeObject.reflectionId].nameIndex)
            return true
        end
        -- Replace spawn point values
        vehicleSpawnPoints[forgeObject.reflectionId].x = forgeObject.x
        vehicleSpawnPoints[forgeObject.reflectionId].y = forgeObject.y
        vehicleSpawnPoints[forgeObject.reflectionId].z = forgeObject.z

        -- REMINDER!!! Check vehicle rotation

        -- Debug spawn index
        dprint("Updating spawn replacing index: " .. forgeObject.reflectionId)

        -- Update spawn point list
        scenario.vehicleLocationList = vehicleSpawnPoints
    end
end

--- Find local object by server remote object id
---@param objects table
---@param remoteId number
---@return number
function core.getObjectIndexByRemoteId(objects, remoteId)
    for objectIndex, forgeObject in pairs(objects) do
        if (forgeObject.remoteId == remoteId) then
            return objectIndex
        end
    end
    return nil
end

--- Calculate distance between 2 objects
---@param baseObject table
---@param targetObject table
---@return number
function core.calculateDistanceFromObject(baseObject, targetObject)
    local calculatedX = (targetObject.x - baseObject.x) ^ 2
    local calculatedY = (targetObject.y - baseObject.y) ^ 2
    local calculatedZ = (targetObject.z - baseObject.z) ^ 2
    return sqrt(calculatedX + calculatedY + calculatedZ)
end

--- Find the path, index and id of a tag given partial name and tag type
---@param partialName string
---@param searchTagType string
---@return tag tag
function core.findTag(partialName, searchTagType)
    for tagIndex = 0, blam.tagDataHeader.count - 1 do
        local tempTag = blam.getTag(tagIndex)
        if (tempTag and tempTag.path:find(partialName) and tempTag.class == searchTagType) then
            return {
                id = tempTag.id,
                path = tempTag.path,
                index = tempTag.index,
                class = tempTag.class,
                indexed = tempTag.indexed,
                data = tempTag.data
            }
        end
    end
    return nil
end

--- Find the path, index and id of a list of tags given partial name and tag type
---@param partialName string
---@param searchTagType string
---@return tag[] tag
function core.findTagsList(partialName, searchTagType)
    local tagsList
    for tagIndex = 0, blam.tagDataHeader.count - 1 do
        local tag = blam.getTag(tagIndex)
        if (tag and tag.path:find(partialName) and tag.class == searchTagType) then
            if (not tagsList) then
                tagsList = {}
            end
            glue.append(tagsList, {
                id = tag.id,
                path = tag.path,
                index = tag.index,
                class = tag.class,
                indexed = tag.indexed,
                data = tag.data
            })
        end
    end
    return tagsList
end

--- Find tag data given index number
---@param tagIndex number
function core.findTagByIndex(tagIndex)
    local tempTag = blam.getTag(tagIndex)
    if (tempTag) then
        return tempTag.path, tempTag.index, tempTag.id
    end
    return nil
end

--- Get index value from an id value type
---@param id number
---@return number index
function core.getIndexById(id)
    local hex = glue.string.tohex(id)
    local bytes = {}
    for i = 5, #hex, 2 do
        glue.append(bytes, hex:sub(i, i + 1))
    end
    return tonumber(concat(bytes, ""), 16)
end

--- Create a projectile "selector" from player view
local function createProjectileSelector()
    local player = blam.biped(get_dynamic_player())
    if (player) then
        local selector = {
            x = player.x + player.xVel + player.cameraX * const.forgeSelectorOffset,
            y = player.y + player.yVel + player.cameraY * const.forgeSelectorOffset,
            z = player.z + player.zVel + player.cameraZ * const.forgeSelectorOffset
        }
        local projectileId = core.spawnObject(tagClasses.projectile, const.forgeProjectilePath,
                                              selector.x, selector.y, selector.z, true)
        if (projectileId) then
            local projectile = blam.projectile(get_object(projectileId))
            if (projectile) then
                projectile.xVel = player.cameraX * const.forgeSelectorVelocity
                projectile.yVel = player.cameraY * const.forgeSelectorVelocity
                projectile.zVel = player.cameraZ * const.forgeSelectorVelocity
                projectile.yaw = player.cameraX * const.forgeSelectorVelocity
                projectile.pitch = player.cameraY * const.forgeSelectorVelocity
                projectile.roll = player.cameraZ * const.forgeSelectorVelocity
                return projectileId
            end
        end
    end
    return nil
end

--- Return data about object that the player is looking at
---@return number, forgeObject, projectile
function core.oldGetForgeObjectFromPlayerAim()
    local forgeObjects = eventsStore:getState().forgeObjects
    for _, projectileObjectIndex in pairs(blam.getObjects()) do
        local projectile = blam.projectile(get_object(projectileObjectIndex))
        local dumpedProjectile = blam.dumpObject(projectile)
        local forgeObject
        local selectedObjIndex
        if (projectile and projectile.type == objectClasses.projectile) then
            local projectileTag = blam.getTag(projectile.tagId)
            if (projectileTag and projectileTag.index == const.forgeProjectileTagIndex) then
                if (projectile.attachedToObjectId) then
                    local selectedObject = blam.object(get_object(projectile.attachedToObjectId))
                    selectedObjIndex = core.getIndexById(projectile.attachedToObjectId)
                    forgeObject = forgeObjects[selectedObjIndex]
                    -- Player is looking at this object
                    if (forgeObject and selectedObject) then
                        -- Erase current projectile selector
                        delete_object(projectileObjectIndex)
                        -- Create a new one
                        createProjectileSelector()
                        return selectedObjIndex, forgeObject, dumpedProjectile or nil
                    end
                end
                delete_object(projectileObjectIndex)
                return nil, nil, dumpedProjectile or nil
            end
            -- elseif (forgeObjects[projectileObjectIndex]) then
            --    if (core.playerIsAimingAt(projectileObjectIndex, 0.03, 0)) then
            --        return projectileObjectIndex, forgeObjects[projectileObjectIndex],
            --               dumpedProjectile or nil
            --    end
        end
    end
    -- No object was found from player view, create a new selector
    createProjectileSelector()
end

--- Return data about object that the player is looking at
---@return number, forgeObject, projectile
function core.getForgeObjectFromPlayerAim()
    if (lastProjectileId) then
        local projectile = blam.projectile(get_object(lastProjectileId))
        if (projectile) then
            if (not blam.isNull(projectile.attachedToObjectId)) then
                local object = blam.object(get_object(projectile.attachedToObjectId))
                --dprint("Found object by collision!")
                --dprint(
                --    inspect({object.vX, object.vY, object.vZ, object.v2X, object.v2Y, object.v2Z}))
                local forgeObjects = eventsStore:getState().forgeObjects
                local selectedObject = blam.object(get_object(projectile.attachedToObjectId))
                local selectedObjIndex = core.getIndexById(projectile.attachedToObjectId)
                local forgeObject = forgeObjects[selectedObjIndex]
                -- Erase current projectile selector
                delete_object(lastProjectileId)
                lastProjectileId = createProjectileSelector()
                -- Player is looking at this object
                if (forgeObject and selectedObject) then
                    -- Create a new one
                    return selectedObjIndex, forgeObject
                end
                -- else
                --    dprint("Searching for objects on view!")
            end
            delete_object(lastProjectileId)
        end
        lastProjectileId = nil
    else
        lastProjectileId = createProjectileSelector()
    end
end

--- Determine if an object is out of the map
---@param coordinates number[]
---@return boolean
function core.isObjectOutOfBounds(coordinates)
    if (coordinates) then
        local projectileId = spawn_object(tagClasses.projectile, const.forgeProjectilePath,
                                          coordinates[1], coordinates[2], coordinates[3])
        if (projectileId) then
            local testerObject = blam.object(get_object(projectileId))
            if (testerObject) then
                -- dprint(object.x .. " " .. object.y .. " " .. object.z)
                local isOutSideMap = testerObject.isOutSideMap
                delete_object(projectileId)
                return isOutSideMap
            end
        end
    end
end

--- Get Forge objects from recursive tag collection
---@param tagCollection tagCollection
---@return number[] tagIdsArray
function core.getForgeSceneries(tagCollection)
    local objects = {}
    for _, tagId in pairs(tagCollection.tagList) do
        local tag = blam.getTag(tagId)
        if (tag.class == tagClasses.tagCollection) then
            local subTagCollection = blam.tagCollection(tag.id)
            if (subTagCollection) then
                local subTags = core.getForgeSceneries(subTagCollection)
                glue.extend(objects, subTags)
            end
        else
            glue.append(objects, tag.id)
        end
    end
    return objects
end

function core.secondsToTicks(seconds)
    return 30 * seconds
end

function core.ticksToSeconds(ticks)
    return glue.round(ticks / 30)
end

return core

end,

["forge.features"] = function()
--------------------
-- Module: 'forge.features'
--------------------
------------------------------------------------------------------------------
-- Forge Features
-- Sledmine
-- Set of different forge features
------------------------------------------------------------------------------
local glue = require "glue"
local color = require "color"

local core = require "forge.core"

local features = {}

--- Changes default crosshair values
---@param state number
function features.setCrosshairState(state)
    local forgeDefaultInterface = blam.weaponHudInterface(
                                      const.weaponHudInterfaces.forgeCrosshairTagId)
    if (forgeDefaultInterface) then
        local newCrosshairs = forgeDefaultInterface.crosshairs
        if (state and state < 5) then
            if (newCrosshairs[1].overlays[1].sequenceIndex ~= state) then
                if (state == 4) then
                    newCrosshairs[1].overlays[1].defaultColorR = 255
                    newCrosshairs[1].overlays[1].defaultColorG = 0
                    newCrosshairs[1].overlays[1].defaultColorB = 0
                elseif (state == 2 or state == 3) then
                    newCrosshairs[1].overlays[1].defaultColorR = 0
                    newCrosshairs[1].overlays[1].defaultColorG = 255
                    newCrosshairs[1].overlays[1].defaultColorB = 0
                else
                    newCrosshairs[1].overlays[1].defaultColorR = 64
                    newCrosshairs[1].overlays[1].defaultColorG = 169
                    newCrosshairs[1].overlays[1].defaultColorB = 255
                end
                newCrosshairs[1].overlays[1].sequenceIndex = state
                forgeDefaultInterface.crosshairs = newCrosshairs
            end
        end
    end
end

function features.unhighlightAll()
    local forgeObjects = eventsStore:getState().forgeObjects
    for objectIndex, forgeObject in pairs(forgeObjects) do
        local tempObject = blam.object(get_object(objectIndex))
        -- Object exists
        if (tempObject) then
            local tempTag = blam.getTag(tempObject.tagId)
            if (tempTag and tempTag.class == tagClasses.scenery) then
                local tempObject = blam.object(get_object(objectIndex))
                tempObject.health = 0
            end
        end
    end
end

function features.unhighlightObject(objectIndex)
    if (objectIndex) then
        local object = blam.object(get_object(objectIndex))
        -- Object exists
        if (object) then
            -- It is a scenery
            -- FIXME We probably do not need this verification
            local tag = blam.getTag(object.tagId)
            if (tag and tag.class == tagClasses.scenery) then
                object.health = 0
            end
        end
    end
end

---@param objectId number
---@param transparency number | "0.1" | "0.5" | "1"
function features.highlightObject(objectId, transparency)
    -- Highlight object
    local tempObject = blam.object(get_object(objectId))
    tempObject.health = transparency
end

--- Execute a player swap between biped and monitor
---@param desiredBipedTagId number
function features.swapBiped(desiredBipedTagId)
    features.unhighlightAll()
    if (server_type == "local") then
        -- If player is alive save his last position
        local playerBiped = blam.biped(get_dynamic_player())
        if (playerBiped) then
            playerStore:dispatch({type = "SAVE_POSITION"})
        end

        -- Avoid annoying low health/shield bug after swaping bipeds
        playerBiped.health = 1
        playerBiped.shield = 1

        -- Find monitor and alternative spartan biped
        local monitorTagId = const.bipeds.monitorTagId
        local spartanTagId
        for bipedPropertyName, bipedTagId in pairs(const.bipeds) do
            if (not bipedPropertyName:find("monitor")) then
                spartanTagId = bipedTagId
                break
            end
        end
        local globals = blam.globalsTag()
        if (globals) then
            local player = blam.player(get_player())
            local playerObject = blam.object(get_object(player.objectId))
            if (player and playerObject) then
                if (playerObject.tagId == monitorTagId) then
                    local newMultiplayerInformation = globals.multiplayerInformation
                    newMultiplayerInformation[1].unit = spartanTagId
                    -- Update globals tag data to set new biped
                    globals.multiplayerInformation = newMultiplayerInformation
                else
                    local newMultiplayerInformation = globals.multiplayerInformation
                    newMultiplayerInformation[1].unit = monitorTagId
                    -- Update globals tag data to set new biped
                    globals.multiplayerInformation = newMultiplayerInformation
                end
                if (desiredBipedTagId) then
                    local newMultiplayerInformation = globals.multiplayerInformation
                    newMultiplayerInformation[1].unit = desiredBipedTagId
                    -- Update globals tag data to set new biped
                    globals.multiplayerInformation = newMultiplayerInformation
                end
                -- Erase player object to force biped respawn
                delete_object(player.objectId)
            end
        end
    end
end

local defaultFirstPersonHands = nil
function features.swapFirstPerson()
    local player = blam.player(get_player())
    local playerObject = blam.object(get_object(player.objectId))
    local globals = blam.globalsTag()
    if (player and playerObject and globals) then
        local bipedTag = blam.getTag(playerObject.tagId)
        if (bipedTag) then
            local tagPathSplit = glue.string.split(bipedTag.path, "\\")
            local bipedName = tagPathSplit[#tagPathSplit]
            local fpModelTagId = const.firstPersonHands[bipedName]
            if (fpModelTagId) then
                -- Save default first person hands model
                if (not defaultFirstPersonHands) then
                    defaultFirstPersonHands = fpModelTagId
                end
                local newFirstPersonInterface = globals.firstPersonInterface
                newFirstPersonInterface[1].firstPersonHands = fpModelTagId
                globals.firstPersonInterface = newFirstPersonInterface
            elseif (defaultFirstPersonHands) then
                local newFirstPersonInterface = globals.firstPersonInterface
                newFirstPersonInterface[1].firstPersonHands = defaultFirstPersonHands
                globals.firstPersonInterface = newFirstPersonInterface
            end
        end
    end
end

--- Forces the game to open a widget given tag path
---@param tagPath string
---@return boolean result susccess
function features.openMenu(tagPath, prevent)
    local uiWidgetTagId = blam.getTag(tagPath, tagClasses.uiWidgetDefinition).id
    if (uiWidgetTagId) then
        return load_ui_widget(tagPath)
    end
    return false
end

--- Print formatted text into HUD message output
---@param message string
---@param optional string
function features.printHUD(message, optional, forcedTickCount)
    textRefreshCount = forcedTickCount or 0
    local color = {1, 0.890, 0.949, 0.992}
    if (optional) then
        drawTextBuffer = {
            message:upper() .. "\r" .. optional:upper(),
            0,
            290,
            640,
            480,
            const.hudFontTagId,
            "center",
            table.unpack(color)
        }
    else
        drawTextBuffer = {
            message:upper(),
            0,
            285,
            640,
            480,
            const.hudFontTagId,
            "center",
            table.unpack(color)
        }
    end
end

--- Print formatted text into HUD message output
---@param message string
---@param optional string
function features.printHUDRight(message, optional, forcedTickCount)
    textRefreshCount = forcedTickCount or 0
    local color = {1, 0.890, 0.949, 0.992}
    if (optional) then
        drawTextBuffer = {
            message:upper() .. "\r" .. optional:upper(),
            -60,
            380,
            640,
            480,
            const.hudFontTagId,
            "right",
            table.unpack(color)
        }
    end
end

function features.animateForgeLoading()
    local bitmapFrameTagId = const.bitmaps.forgingIconFrame0TagId
    if (loadingFrame == 0) then
        bitmapFrameTagId = const.bitmaps.forgeIconFrame1TagId
        loadingFrame = 1
    else
        bitmapFrameTagId = const.bitmaps.forgingIconFrame0TagId
        loadingFrame = 0
    end

    -- Animate Forge loading image
    local uiWidget = blam.uiWidgetDefinition(const.uiWidgetDefinitions.loadingAnimation.id)
    uiWidget.backgroundBitmap = bitmapFrameTagId
    return true
end

function features.animateDialogLoading()
    local bitmap = blam.bitmap(const.bitmaps.dialogIconsTagId)
    if (bitmap) then
        local newSequences = bitmap.sequences
        if (newSequences[1].firstBitmapIndex < 5) then
            newSequences[1].firstBitmapIndex = newSequences[1].firstBitmapIndex + 1
        else
            newSequences[1].firstBitmapIndex = 0
        end
        bitmap.sequences = newSequences
    else
        error("Error, at animating loading dialog bitmap.")
    end
end

--- Get information from the mouse input in the game
---@return mouseInput
function features.getMouseInput()
    ---@class mouseInput
    local mouseInput = {scroll = tonumber(read_char(const.mouseInputAddress + 8))}
    return mouseInput
end

-- TODO Refactor this to execute all the needed steps in just one function
function features.setObjectColor(hexColor, blamObject)
    if (blamObject) then
        local r, g, b = color.hex(hexColor)
        blamObject.redA = r
        blamObject.greenA = g
        blamObject.blueA = b
    end
end

function features.openForgeObjectPropertiesMenu()
    local forgeState = actions.getForgeState()
    forgeState.forgeMenu.currentPage = 1
    forgeState.forgeMenu.desiredElement = "root"
    forgeState.forgeMenu.elementsList = {
        root = {
            ["colors (beta)"] = {
                ["white (default)"] = {},
                black = {},
                red = {},
                blue = {},
                gray = {},
                yellow = {},
                green = {},
                pink = {},
                purple = {},
                cyan = {},
                cobalt = {},
                orange = {},
                teal = {},
                sage = {},
                brown = {},
                tan = {},
                maroon = {},
                salmon = {}
            },
            ["channel"] = {},
            ["reset rotation"] = {},
            ["rotate 45"] = {},
            ["rotate 90"] = {},
            ["snap mode"] = {}
        }
    }
    for channelIndex, channelName in pairs(const.teleportersChannels) do
        forgeState.forgeMenu.elementsList.root["channel"][channelName] = {}
    end
    forgeStore:dispatch({
        type = "UPDATE_FORGE_ELEMENTS_LIST",
        payload = {forgeMenu = forgeState.forgeMenu}
    })
    features.openMenu(const.uiWidgetDefinitions.forgeMenu.path)
end

function features.getObjectMenuFunctions()
    local playerState = playerStore:getState()
    local elementFunctions = {
        ["rotate 45"] = function()
            local newRotationStep = 45
            playerStore:dispatch({type = "SET_ROTATION_STEP", payload = {step = newRotationStep}})
            playerStore:dispatch({type = "STEP_ROTATION_DEGREE"})
            playerStore:dispatch({type = "ROTATE_OBJECT"})
        end,
        ["rotate 90"] = function()
            local newRotationStep = 90
            playerStore:dispatch({type = "SET_ROTATION_STEP", payload = {step = newRotationStep}})
            playerStore:dispatch({type = "STEP_ROTATION_DEGREE"})
            playerStore:dispatch({type = "ROTATE_OBJECT"})
        end,
        ["reset rotation"] = function()
            playerStore:dispatch({type = "RESET_ROTATION"})
            playerStore:dispatch({type = "ROTATE_OBJECT"})
        end,
        ["snap mode"] = function()
            config.forge.snapMode = not config.forge.snapMode
        end
    }
    for colorName, colorValue in pairs(const.colors) do
        -- Hardcode button white label
        if (colorName == "white") then
            colorName = "white (default)"
        end
        elementFunctions[colorName] = function()
            actions.setObjectColor(colorValue)
        end
    end
    for channelIndex, channelName in pairs(const.teleportersChannels) do
        elementFunctions[channelName] = function()
            actions.setObjectChannel(channelIndex)
        end
    end
    return elementFunctions
end

-- TODO Migrate this to a separate module, like glue
local function stringHas(str, list)
    for k, v in pairs(list) do
        if (str:find(v)) then
            return true
        end
    end
    return false
end

--- Hide or unhide forge reflection objects for gameplay purposes
function features.hideReflectionObjects()
    if (not config.forge.debugMode) then
        ---@type eventsState
        local eventsStore = eventsStore:getState()
        for objectIndex, forgeObject in pairs(eventsStore.forgeObjects) do
            if (forgeObject and forgeObject.reflectionId) then
                local object = blam.object(get_object(objectIndex))
                if (object) then
                    local tag = blam.getTag(object.tagId)
                    if (not stringHas(tag.path, const.hideObjectsExceptions)) then
                        -- Hide objects by setting different properties
                        if (core.isPlayerMonitor()) then
                            object.isGhost = false
                            object.z = forgeObject.z
                        else
                            object.isGhost = true
                            object.z = const.minimumZSpawnPoint * 4
                        end
                    end
                end
            end
        end
    end
end

--- Attempt to play a sound given tag path and optionally a gain number
function features.playSound(tagPath, gain)
    local player = blam.player(get_player())
    if (player) then
        local playSoundCommand = const.hsc.playSound:format(tagPath, player.index, gain or 1.0)
        execute_script(playSoundCommand)
    end
end

local landedRecently = false
local healthDepletedRecently = false
local lastGrenadeType = nil
--- Apply some special effects to the HUD like sounds, blips, etc
function features.hudUpgrades()
    local player = blam.biped(get_dynamic_player())
    -- Player must exist
    if (player) then
        local isPlayerOnMenu = read_byte(blam.addressList.gameOnMenus) == 0
        if (not isPlayerOnMenu) then
            local localPlayer = read_dword(const.localPlayerAddress)
            local currentGrenadeType = read_word(localPlayer + 202)
            if (not blam.isNull(currentGrenadeType)) then
                if (not lastGrenadeType) then
                    lastGrenadeType = currentGrenadeType
                end
                if (lastGrenadeType ~= currentGrenadeType) then
                    lastGrenadeType = currentGrenadeType
                    if (lastGrenadeType == 1) then
                        features.playSound(const.sounds.uiForwardPath .. "2", 1)
                    else
                        features.playSound(const.sounds.uiForwardPath, 1)
                    end
                end
            end
            -- When player is on critical health show blur effect
            if (player.health < 0.25 and blam.isNull(player.vehicleObjectId)) then
                if (not healthDepletedRecently) then
                    healthDepletedRecently = true
                    execute_script([[(begin
                        (cinematic_screen_effect_start true)
                        (cinematic_screen_effect_set_convolution 2 1 1 1 5)
                        (cinematic_screen_effect_start false)
                    )]])
                end
            else
                if (healthDepletedRecently) then
                    execute_script([[(begin
                    (cinematic_screen_effect_set_convolution 2 1 1 0 1)(cinematic_screen_effect_start false)
                    (sleep 45)
                    (cinematic_stop)
                )]])
                end
                healthDepletedRecently = false
            end
            -- Get hud background bitmap
            local visorBitmap = blam.bitmap(const.bitmaps.unitHudBackgroundTagId)
            if (visorBitmap) then
                -- Player is not in a vehicle
                if (blam.isNull(player.vehicleObjectId)) then
                    -- Unhide hud background bitmap when not in vehicles
                    visorBitmap.type = 0
                else
                    -- Hide hud background bitmap when on vehicles
                    -- Set to interface bitmap type
                    visorBitmap.type = 4
                end
            end
        end
        -- Player is not in a vehicle
        if (blam.isNull(player.vehicleObjectId)) then
            -- Landing hard
            if (player.landing == 1) then
                if (not landedRecently) then
                    landedRecently = true
                    -- Play sound using hsc scripts
                    features.playSound(const.sounds.landHardPlayerDamagePath, 0.8)
                end
            else
                landedRecently = false
            end
        end
    end
end

--- Regenerate players health on low shield using game ticks
---@param playerIndex number
function features.regenerateHealth(playerIndex)
    if (server_type == "sapp" or server_type == "local") then
        local player
        if (playerIndex) then
            player = blam.biped(get_dynamic_player(playerIndex))
        else
            player = blam.biped(get_dynamic_player())
        end
        if (player) then
            -- Fix muted audio shield sync
            if (server_type == "local") then
                if (player.health <= 0) then
                    player.health = 0.000000001
                end
            end
            if (player.health < 1 and player.shield >= 1) then
                local newPlayerHealth = player.health + const.healthRegenerationAmount
                if (newPlayerHealth > 1) then
                    player.health = 1
                else
                    player.health = newPlayerHealth
                end
            end
        end
    end
end

--- Update forge keys text on pause menu
function features.showForgeKeys()
    local controlsStrings = blam.unicodeStringList(const.unicodeStrings.forgeControlsTagId)
    if (controlsStrings) then
        if (core.isPlayerMonitor()) then
            local newStrings = controlsStrings.stringList
            -- E key
            newStrings[1] = "Change rotation angle"
            -- Q key
            newStrings[2] = "Open Forge objects menu"
            -- F key
            newStrings[3] = "Swap Push N Pull mode"
            -- Control key
            newStrings[4] = "Get back into spartan mode"
            controlsStrings.stringList = newStrings
        else
            local newStrings = controlsStrings.stringList
            -- E key
            newStrings[1] = "No Forge action"
            -- Q key
            newStrings[2] = "Get into monitor mode"
            -- F key
            newStrings[3] = "No Forge action"
            -- Control key
            newStrings[4] = "No Forge action"
            controlsStrings.stringList = newStrings
        end
    end
end

--- Prevent players from getting out of map limits
---@param playerIndex number
function features.mapLimit(playerIndex)
    local playerBiped
    if (playerIndex) then
        playerBiped = blam.biped(get_dynamic_player(playerIndex))
    else
        playerBiped = blam.biped(get_dynamic_player())
    end
    if (playerBiped and playerBiped.z < const.minimumZMapLimit) then
        if (server_type == "local") then
            local player = blam.player(get_player())
            delete_object(player.objectId)
        elseif (server_type == "sapp") then
            kill(playerIndex)
        end
    end
end

--- Dynamically modify the general menu to reflect Forge settings
function features.createSettingsMenu(open)
    generalMenuStore:dispatch({
        type = "SET_MENU",
        payload = {
            title = "Forge Settings",
            elements = {
                "Enable debug mode",
                "Constantly save current map",
                "Enable object snap mode",
                "Cast dynamic shadows on objects"
            },
            values = {
                config.forge.debugMode,
                config.forge.autoSave,
                config.forge.snapMode,
                config.forge.objectsCastShadow,
            },
            format = "settings"
        }
    })
    if (open and not features.openMenu(const.uiWidgetDefinitions.generalMenu.path)) then
        dprint("Error, at trying to open general menu!")
    end
end

--- Dynamically modify the general menu to reflect biped selection
function features.createBipedsMenu(open)
    generalMenuStore:dispatch({
        type = "SET_MENU",
        payload = {title = "Bipeds Selection", elements = glue.keys(const.bipedNames), format = "bipeds"}
    })
    if (open and not features.openMenu(const.uiWidgetDefinitions.generalMenu.path)) then
        dprint("Error, at trying to open general menu!")
    end
end

--- Get the widget id of the current ui open in the game
---@return number
function features.getCurrentWidget()
    local widgetIdAddress = read_dword(const.currentWidgetIdAddress)
    if (widgetIdAddress and widgetIdAddress ~= 0) then
        local widgetId = read_dword(widgetIdAddress)
        local tag = blam.getTag(widgetId)
        if (tag) then
            local isPlayerOnMenu = read_byte(blam.addressList.gameOnMenus) == 0
            if (isPlayerOnMenu) then
                --dprint("Current widget: " .. tag.path)
            end
            return tag.id
        end
    end
    return nil
end

function features.overrideDialog(title, message, type)
    local dialogStrings = blam.unicodeStringList(const.unicodeStrings.dialogStringsId)
    local newStrings = dialogStrings.stringList
    newStrings[1] = title
    newStrings[2] = message
    dialogStrings.stringList = newStrings
    -- TODO Refactor this method to allow ids instead of path strings
    features.openMenu(const.uiWidgetDefinitions.warningDialog.path)
end

--[[function core.getPlayerFragGrenade()
    for objectNumber, objectIndex in pairs(blam.getObjects()) do
        local projectile = blam.projectile(get_object(objectIndex))
        local selectedObjIndex
        if (projectile and projectile.type == objectClasses.projectile) then
            local projectileTag = blam.getTag(projectile.tagId)
            if (projectileTag and projectileTag.index ==
                constants.fragGrenadeProjectileTagIndex) then
                local player = blam.biped(get_dynamic_player())
                if (projectile.armingTimer > 1) then
                    player.x = projectile.x
                    player.y = projectile.y
                    player.z = projectile.z
                    delete_object(objectIndex)
                end
            end
        end
    end
end]]

--[[function core.getPlayerAimingSword()
    for objectNumber, objectIndex in pairs(blam.getObjects()) do
        local projectile = blam.projectile(get_object(objectIndex))
        local selectedObjIndex
        if (projectile and projectile.type == objectClasses.projectile) then
            local projectileTag = blam.getTag(projectile.tagId)
            if (projectileTag and projectileTag.index == constants.swordProjectileTagIndex) then
                if (projectile.attachedToObjectId) then
                    local selectedObject = blam.object(
                                               get_object(projectile.attachedToObjectId))
                    if (selectedObject) then
                        dprint(projectile.attachedToObjectId)
                        return projectile, objectIndex
                    end
                end
            end
        end
    end
end]]

--[[
                -- local projectile, projectileIndex = core.getPlayerAimingSword()
            -- Melee magnetisim concept
            for _, objectIndex in pairs(blam.getObjects()) do
                local object = blam.object(get_object(objectIndex))
                if (object and object.type == objectClasses.biped and not object.isHealthEmpty) then
                    local isPlayerOnAim = core.playerIsAimingAt(objectIndex, 0.11, 0.2, 1.4)
                    if (isPlayerOnAim) then
                        if (player.meleeKey) then
                            dprint(player.cameraX .. " " .. player.cameraY .. " " .. player.cameraZ)
                            -- Add velocity to current velocity
                            player.yVel = player.yVel + player.cameraY * 0.13
                            player.xVel = player.xVel + player.cameraX * 0.13
                            player.zVel = player.zVel + player.cameraZ * 0.04

                            -- Replace velocity with camera position
                            -- player.yVel = player.cameraY * 0.15
                            -- player.xVel = player.cameraX * 0.15
                            -- player.zVel = player.cameraZ * 0.06
                        end
                    end
                end
            end
]]

return features

end,

["forge.interface"] = function()
--------------------
-- Module: 'forge.interface'
--------------------
------------------------------------------------------------------------------
-- Interface
-- Author: Sledmine
-- Interface handler for UI Widgets
------------------------------------------------------------------------------

local interface = {}

-- TODO Add unit testing for this
---@param triggerName string
---@param triggersNumber number
---@return number
function interface.triggers(triggerName, triggersNumber)
    local restoreTriggersState = (function()
        for triggerIndex = 1, triggersNumber do
            -- TODO Replace this function with set global
            set_global(triggerName .. "_trigger_" .. triggerIndex, false)
        end
    end)
    for i = 1, triggersNumber do
        if (get_global(triggerName .. "_trigger_" .. i)) then
            restoreTriggersState()
            return i
        end
    end
    return nil
end

--- Perform a child widget update on the specified widget
---@param widget tag
---@param widgetCount number
function interface.update(widget, widgetCount)
    local uiWidget = blam.uiWidgetDefinition(widget.id)
    if (uiWidget) then
        -- Update child widgets count
        uiWidget.childWidgetsCount = widgetCount
        -- Send new event type to force render
        uiWidget.eventType = 33
    end
end

--- Perform a close event on the specified widget
---@param widget tag
function interface.close(widget)
    -- Send new event type to force close
    local uiWidget = blam.uiWidgetDefinition(widget.id)
    if (uiWidget) then
        uiWidget.eventType = 33
    else
        error("UI Widget " .. tostring(widget.path) .. " was not able to be modified.")
    end
end

--- Stop the execution of a forced event
---@param widget tag
function interface.stop(widget)
    -- Send new event type to stop event
    local uiWidget = blam.uiWidgetDefinition(widget.id)
    if (uiWidget) then
        uiWidget.eventType = 32
    else
        error("UI Widget " .. tostring(widget.path) .. " was not able to be modified.")
    end
end

--- Get selected text from unicode string list
---@param triggersName string
---@param triggersCount number
---@param unicodeStringList tag
function interface.get(triggersName, triggersCount, unicodeStringList)
    local menuPressedButton = interface.triggers(triggersName, triggersCount)
    local elementsList = blam.unicodeStringList(unicodeStringList.id)
    return elementsList.stringList[menuPressedButton]
end

-- Every hook executes a callback
function interface.hook(variable, callback, ...)
    if (get_global(variable)) then
        dprint("Hooking " .. variable .. "...")
        --execute_script("set " .. variable .. " false")
        set_global(variable, false)
        callback(...)
    end
end

return interface

end,

["forge.reducers.forgeReducer"] = function()
--------------------
-- Module: 'forge.reducers.forgeReducer'
--------------------
-- Lua libraries
local inspect = require "inspect"
local glue = require "glue"

-- Forge modules
local interface = require "forge.interface"

---@class forgeState
local defaultState = {
    mapsMenu = {
        mapsList = {},
        currentMapsList = {},
        currentPage = 1
    },
    forgeMenu = {
        -- //TODO Implement a way to use this field for menu navigation purposes 
        lastObject = "root",
        desiredElement = "root",
        objectsDatabase = {},
        objectsList = {root = {}},
        elementsList = {root = {}},
        currentElementsList = {},
        currentPage = 1,
        currentBudget = "0",
        currentBarSize = 0
    },
    loadingMenu = {loadingObjectPath = "", currentBarSize = 422, expectedObjects = 0},
    currentMap = {
        name = "Unsaved",
        author = "Unknown",
        version = "1.0",
        description = "No description given for this map."
    }
}

---@param state forgeState
local function forgeReducer(state, action)
    if (not state) then
        -- Create default state if it does not exist
        state = glue.deepcopy(defaultState)
    end
    if (action.type) then
        dprint("[Forge Reducer]:")
        dprint("Action: " .. action.type, "category")
    end
    if (action.type == "UPDATE_MAP_LIST") then
        state.mapsMenu.mapsList = action.payload.mapsList

        -- Sort maps list by alphabetical order
        table.sort(state.mapsMenu.mapsList, function(a, b)
            return a:lower() < b:lower()
        end)

        state.mapsMenu.currentMapsList = glue.chunks(state.mapsMenu.mapsList, 8)
        local totalPages = #state.mapsMenu.currentMapsList
        return state
    elseif (action.type == "INCREMENT_MAPS_MENU_PAGE") then
        if (state.mapsMenu.currentPage < #state.mapsMenu.currentMapsList) then
            state.mapsMenu.currentPage = state.mapsMenu.currentPage + 1
        end
        dprint(state.mapsMenu.currentPage)
        return state
    elseif (action.type == "DECREMENT_MAPS_MENU_PAGE") then
        if (state.mapsMenu.currentPage > 1) then
            state.mapsMenu.currentPage = state.mapsMenu.currentPage - 1
        end
        dprint(state.mapsMenu.currentPage)
        return state
    elseif (action.type == "UPDATE_FORGE_ELEMENTS_LIST") then
        state.forgeMenu = action.payload.forgeMenu
        local elementsList = glue.childsbyparent(state.forgeMenu.elementsList,
                                                 state.forgeMenu.desiredElement)
        if (not elementsList) then
            state.forgeMenu.desiredElement = "root"
            elementsList = glue.childsbyparent(state.forgeMenu.elementsList,
                                               state.forgeMenu.desiredElement)
        end

        if (elementsList) then
            -- Sort and prepare elements list in alphabetic order
            local keysList = glue.keys(elementsList)
            table.sort(keysList, function(a, b)
                return a:lower() < b:lower()
            end)

            for i = 1, #keysList do
                if (string.sub(keysList[i], 1, 1) == "_") then
                    keysList[i] = string.sub(keysList[i], 2, -1)
                end
            end

            -- Create list pagination
            state.forgeMenu.currentElementsList = glue.chunks(keysList, 6)
        else
            error("Element " .. tostring(state.forgeMenu.desiredElement) ..
                      " does not exist in the state list")
        end
        return state
    elseif (action.type == "INCREMENT_FORGE_MENU_PAGE") then
        dprint("Page: " .. inspect(state.forgeMenu.currentPage))
        if (state.forgeMenu.currentPage < #state.forgeMenu.currentElementsList) then
            state.forgeMenu.currentPage = state.forgeMenu.currentPage + 1
        end
        return state
    elseif (action.type == "DECREMENT_FORGE_MENU_PAGE") then
        dprint("Page: " .. inspect(state.forgeMenu.currentPage))
        if (state.forgeMenu.currentPage > 1) then
            state.forgeMenu.currentPage = state.forgeMenu.currentPage - 1
        end
        return state
    elseif (action.type == "DOWNWARD_NAV_FORGE_MENU") then
        state.forgeMenu.currentPage = 1
        state.forgeMenu.desiredElement = action.payload.desiredElement
        local objectsList = glue.childsbyparent(state.forgeMenu.elementsList,
                                                state.forgeMenu.desiredElement)

        -- Sort and prepare object list in alphabetic order
        local keysList = glue.keys(objectsList)
        table.sort(keysList, function(a, b)
            return a:lower() < b:lower()
        end)

        -- Create list pagination
        state.forgeMenu.currentElementsList = glue.chunks(keysList, 6)

        return state
    elseif (action.type == "UPWARD_NAV_FORGE_MENU") then
        state.forgeMenu.currentPage = 1
        state.forgeMenu.desiredElement = glue.parentbychild(state.forgeMenu.elementsList,
                                                            state.forgeMenu.desiredElement)
        local objectsList = glue.childsbyparent(state.forgeMenu.elementsList,
                                                state.forgeMenu.desiredElement)

        -- Sort and prepare object list in alphabetic order
        local keysList = glue.keys(objectsList)
        table.sort(keysList, function(a, b)
            return a:lower() < b:lower()
        end)

        -- Create list pagination
        state.forgeMenu.currentElementsList = glue.chunks(keysList, 6)

        return state
    elseif (action.type == "SET_MAP_NAME") then
        state.currentMap.name = action.payload.mapName
        return state
    elseif (action.type == "SET_MAP_AUTHOR") then
        state.currentMap.author = action.payload.mapAuthor
        return state
    elseif (action.type == "SET_MAP_DESCRIPTION") then
        state.currentMap.description = action.payload.mapDescription
        return state
    elseif (action.type == "SET_MAP_DATA") then
        state.currentMap.name = action.payload.mapName
        state.currentMap.description = action.payload.mapDescription
        if (action.payload.mapDescription == "") then
            state.currentMap.description = "No description given for this map."
        end
        state.currentMap.author = action.payload.mapAuthor
        return state
    elseif (action.type == "UPDATE_BUDGET") then
        -- FIXME This should be separated from this reducer in order to prevent menu blinking
        -- Set current budget bar data
        local objectState = eventsStore:getState().forgeObjects
        local currentObjects = #glue.keys(objectState) or 0
        local newBarSize = currentObjects * const.maximumProgressBarSize /
                               const.maximumObjectsBudget
        state.forgeMenu.currentBarSize = glue.floor(newBarSize)
        state.forgeMenu.currentBudget = tostring(currentObjects)
        return state
    elseif (action.type == "UPDATE_MAP_INFO") then
        if (action.payload) then
            local expectedObjects = action.payload.expectedObjects
            local mapName = action.payload.mapName
            local mapDescription = action.payload.mapDescription
            if (expectedObjects) then
                state.loadingMenu.expectedObjects = expectedObjects
            end
            if (mapName) then
                state.currentMap.name = mapName
            end
            if (mapDescription) then
                state.currentMap.description = mapDescription
            end
            if (action.payload.loadingObjectPath) then
                state.loadingMenu.loadingObjectPath = action.payload.loadingObjectPath
            end
        end
        if (server_type ~= "sapp") then
            if (eventsStore) then
                if (state.loadingMenu.expectedObjects > 0) then
                    -- Prevent player from falling and desyncing by freezing it
                    local player = blam.biped(get_dynamic_player())
                    -- FIXME For some reason player is being able unfreeze after applying this
                    if (player) then
                        player.zVel = 0
                        player.isFrozen = true
                    end

                    -- Set loading map bar data
                    local expectedObjects = state.loadingMenu.expectedObjects
                    local objectState = eventsStore:getState().forgeObjects
                    local currentObjects = #glue.keys(objectState) or 0
                    local newBarSize = currentObjects * const.maxLoadingBarSize /
                                           expectedObjects
                    state.loadingMenu.currentBarSize = glue.floor(newBarSize)
                    if (state.loadingMenu.currentBarSize >= const.maxLoadingBarSize) then
                        -- Unfreeze player
                        local player = blam.biped(get_dynamic_player())
                        if (player) then
                            player.isFrozen = false
                        end
                        if (forgeAnimationTimer) then
                            stop_timer(forgeAnimationTimer)
                            forgeAnimationTimer = nil
                            dprint("Erasing forge animation timer!")
                        end
                        interface.close(const.uiWidgetDefinitions.loadingMenu)
                    end
                else
                    interface.close(const.uiWidgetDefinitions.loadingMenu)
                end
            end
        end
        return state
    else
        if (action.type == "@@lua-redux/INIT") then
            dprint("Default state has been created!")
        else
            dprint(("Warning, Dispatched event \"%s\" does not exist:"):format(tostring(action.type)), "warning")
        end
        return state
    end
    return state
end

return forgeReducer

end,

["forge.reducers.eventsReducer"] = function()
--------------------
-- Module: 'forge.reducers.eventsReducer'
--------------------
-- Lua libraries
local glue = require "glue"
local inspect = require "inspect"
local json = require "json"

-- Forge modules
local core = require "forge.core"
local features = require "forge.features"

-- Optimizations
local getIndexById = core.getIndexById
local rotateObject = core.rotateObject

-- TODO Test this class structure
---@class forgeObject
---@field x number
---@field y number
---@field z number
---@field yaw number
---@field pitch number
---@field roll number
---@field remoteId number
---@field reflectionId number
---@field teamIndex  number
---@field color number

---@class eventsState
---@field forgeObjects forgeObject[]
---@field cachedResponses string[]
local defaultState = {
    forgeObjects = {},
    cachedResponses = {},
    playerVotes = {},
    mapVotesGroup = 0
}

---@param state eventsState
local function eventsReducer(state, action)
    -- Create default state if it does not exist
    if (not state) then
        state = glue.deepcopy(defaultState)
    end
    if (action.type) then
        dprint("-> [Events Store]")
        dprint("Action: " .. action.type, "category")
    end
    if (action.type == const.requests.spawnObject.actionType) then
        dprint("SPAWNING object to store...", "warning")
        local requestObject = action.payload.requestObject

        -- Create a new object rather than passing it as "reference"
        local forgeObject = glue.update({}, requestObject)
        local tagPath = blam.getTag(requestObject.tagId or requestObject.tagIndex).path

        -- Spawn object in the game
        local objectId = core.spawnObject(tagClasses.scenery, tagPath, forgeObject.x,
                                          forgeObject.y, forgeObject.z)
        dprint("objectId: " .. objectId)

        local objectIndex = getIndexById(objectId)
        dprint("objectIndex: " .. objectIndex)

        if (not objectIndex or not objectId) then
            error("Object index/id could not be found for tag: " .. tagPath)
        end

        if (server_type == "sapp") then
            -- SAPP functions can't handle object indexes
            -- TODO This requires some refactor and testing to use ids instead of indexes on the client side
            objectIndex = objectId
            features.hideReflectionObjects()
        elseif (blam.isGameDedicated()) then
            features.hideReflectionObjects()
        end

        -- Set object rotation after creating the object
        rotateObject(objectIndex, forgeObject.yaw, forgeObject.pitch, forgeObject.roll)

        -- We are the server so the remote id is the local objectId/objectIndex
        if (server_type == "local" or server_type == "sapp") then
            forgeObject.remoteId = objectIndex
        end

        -- Apply color to the object
        if (server_type ~= "sapp" and requestObject.color) then
            local tempObject = blam.object(get_object(objectIndex))
            features.setObjectColor(const.colorsNumber[requestObject.color],
                                    tempObject)
        end

        dprint("objectIndex: " .. objectIndex)
        dprint("remoteId: " .. forgeObject.remoteId)

        -- Check and take actions if the object is a special netgame object
        if (tagPath:find("spawning")) then
            dprint("-> [Reflecting Spawn]", "warning")
            if (tagPath:find("gametypes")) then
                dprint("GAMETYPE_SPAWN", "category")
                -- Make needed modifications to game spawn points
                core.updatePlayerSpawn(tagPath, forgeObject)
            elseif (tagPath:find("vehicles") or tagPath:find("objects")) then
                dprint("VEHICLE_SPAWN", "category")
                core.updateVehicleSpawn(tagPath, forgeObject)
            elseif (tagPath:find("weapons")) then
                dprint("WEAPON_SPAWN", "category")
                core.updateNetgameEquipmentSpawn(tagPath, forgeObject)
            end
        elseif (tagPath:find("objectives") or tagPath:find("teleporters")) then
            dprint("-> [Reflecting Flag]", "warning")
            core.updateNetgameFlagSpawn(tagPath, forgeObject)
        end

        -- As a server we have to send back a response/request to the players in the server
        if (server_type == "sapp") then
            local response = core.createRequest(forgeObject)
            state.cachedResponses[objectIndex] = response
            if (forgeMapFinishedLoading) then
                core.sendRequest(response)
            end
            features.hideReflectionObjects()
        end

        -- Clean and prepare object to store it
        forgeObject.tagId = nil
        forgeObject.requestType = nil

        -- Store the object in our state
        state.forgeObjects[objectIndex] = forgeObject

        -- Update the current map information
        forgeStore:dispatch({
            type = "UPDATE_MAP_INFO",
            payload = {loadingObjectPath = tagPath}
        })
        forgeStore:dispatch({type = "UPDATE_BUDGET"})

        return state
    elseif (action.type == const.requests.updateObject.actionType) then
        local requestObject = action.payload.requestObject
        local targetObjectId = core.getObjectIndexByRemoteId(state.forgeObjects,
                                                             requestObject.objectId)
        local forgeObject = state.forgeObjects[targetObjectId]

        if (forgeObject) then
            dprint("UPDATING object from store...", "warning")

            forgeObject.x = requestObject.x
            forgeObject.y = requestObject.y
            forgeObject.z = requestObject.z
            forgeObject.yaw = requestObject.yaw
            forgeObject.pitch = requestObject.pitch
            forgeObject.roll = requestObject.roll
            forgeObject.color = requestObject.color
            forgeObject.teamIndex = requestObject.teamIndex

            -- Update object rotation
            core.rotateObject(targetObjectId, forgeObject.yaw, forgeObject.pitch,
                              forgeObject.roll)

            -- Update object position
            local tempObject = blam.object(get_object(targetObjectId))
            tempObject.x = forgeObject.x
            tempObject.y = forgeObject.y
            tempObject.z = forgeObject.z

            if (requestObject.color) then
                features.setObjectColor(const.colorsNumber[requestObject.color],
                                        tempObject)
            end

            -- Check and take actions if the object is reflecting a netgame point
            if (forgeObject.reflectionId) then
                local tempObject = blam.object(get_object(targetObjectId))
                local tagPath = blam.getTag(tempObject.tagId).path
                if (tagPath:find("spawning")) then
                    dprint("-> [Reflecting Spawn]", "warning")
                    if (tagPath:find("gametypes")) then
                        dprint("GAMETYPE_SPAWN", "category")
                        -- Make needed modifications to game spawn points
                        core.updatePlayerSpawn(tagPath, forgeObject)
                    elseif (tagPath:find("vehicles") or tagPath:find("objects")) then
                        dprint("VEHICLE_SPAWN", "category")
                        core.updateVehicleSpawn(tagPath, forgeObject)
                    elseif (tagPath:find("weapons")) then
                        dprint("WEAPON_SPAWN", "category")
                        core.updateNetgameEquipmentSpawn(tagPath, forgeObject)
                    end
                elseif (tagPath:find("objectives") or tagPath:find("teleporters")) then
                    dprint("-> [Reflecting Flag]", "warning")
                    core.updateNetgameFlagSpawn(tagPath, forgeObject)
                end
            end

            -- As a server we have to send back a response/request to the players in the server
            if (server_type == "sapp") then
                print(inspect(requestObject))
                local response = core.createRequest(requestObject)
                core.sendRequest(response)

                -- Create cache for incoming players
                local instanceObject = glue.update({}, forgeObject)
                instanceObject.requestType = const.requests.spawnObject.requestType
                instanceObject.tagId = blam.object(get_object(targetObjectId)).tagId
                local response = core.createRequest(instanceObject)
                state.cachedResponses[targetObjectId] = response
            end
        else
            dprint("ERROR!!! The required object with Id: " .. requestObject.objectId ..
                       "does not exist.", "error")
        end
        return state
    elseif (action.type == const.requests.deleteObject.actionType) then
        local requestObject = action.payload.requestObject
        local targetObjectId = core.getObjectIndexByRemoteId(state.forgeObjects,
                                                             requestObject.objectId)
        local forgeObject = state.forgeObjects[targetObjectId]

        if (forgeObject) then
            if (forgeObject.reflectionId) then
                local tempObject = blam.object(get_object(targetObjectId))
                local tagPath = blam.getTag(tempObject.tagId).path
                if (tagPath:find("spawning")) then
                    dprint("-> [Reflecting Spawn]", "warning")
                    if (tagPath:find("gametypes")) then
                        dprint("GAMETYPE_SPAWN", "category")
                        -- Make needed modifications to game spawn points
                        core.updatePlayerSpawn(tagPath, forgeObject, true)
                    elseif (tagPath:find("vehicles") or tagPath:find("objects")) then
                        dprint("VEHICLE_SPAWN", "category")
                        core.updateVehicleSpawn(tagPath, forgeObject, true)
                    elseif (tagPath:find("weapons")) then
                        dprint("WEAPON_SPAWN", "category")
                        core.updateNetgameEquipmentSpawn(tagPath, forgeObject, true)
                    end
                elseif (tagPath:find("teleporters")) then
                    dprint("-> [Reflecting Flag]", "warning")
                    core.updateNetgameFlagSpawn(tagPath, forgeObject, true)
                end
            end

            dprint("Deleting object from store...", "warning")
            delete_object(targetObjectId)
            state.forgeObjects[targetObjectId] = nil
            dprint("Done.", "success")

            -- As a server we have to send back a response/request to the players in the server
            if (server_type == "sapp") then
                local response = core.createRequest(requestObject)
                core.sendRequest(response)

                -- Delete cache of this object for incoming players
                state.cachedResponses[targetObjectId] = nil

            end
        else
            dprint("ERROR!!! The required object with Id: " .. requestObject.objectId ..
                       "does not exist.", "error")
        end
        -- Update the current map information
        forgeStore:dispatch({type = "UPDATE_MAP_INFO"})
        forgeStore:dispatch({type = "UPDATE_BUDGET"})

        return state
    elseif (action.type == const.requests.setMapAuthor.actionType) then
        local requestObject = action.payload.requestObject

        local mapAuthor = requestObject.mapAuthor

        forgeStore:dispatch({
            type = const.requests.setMapAuthor.actionType,
            payload = {mapAuthor = mapAuthor}
        })

        return state
    elseif (action.type == const.requests.setMapDescription.actionType) then
        local requestObject = action.payload.requestObject

        local mapDescription = requestObject.mapDescription

        forgeStore:dispatch({
            type = const.requests.setMapDescription.actionType,
            payload = {mapDescription = mapDescription}
        })

        return state
    elseif (action.type == const.requests.loadMapScreen.actionType) then
        local requestObject = action.payload.requestObject

        local expectedObjects = requestObject.objectCount
        local mapName = requestObject.mapName

        forgeStore:dispatch({
            type = "UPDATE_MAP_INFO",
            payload = {expectedObjects = expectedObjects, mapName = mapName}
        })
        forgeStore:dispatch({type = "UPDATE_BUDGET"})

        -- Function wrapper for timer
        forgeAnimation = features.animateForgeLoading
        forgeAnimationTimer = set_timer(250, "forgeAnimation")

        features.openMenu(const.uiWidgetDefinitions.loadingMenu.path)

        return state
    elseif (action.type == const.requests.flushForge.actionType) then
        if (server_type ~= "sapp") then
            local forgeObjects = state.forgeObjects
            for objectIndex, forgeObject in pairs(forgeObjects) do
                delete_object(objectIndex)
            end
        end
        state.cachedResponses = {}
        state.forgeObjects = {}
        return state
    elseif (action.type == const.requests.loadVoteMapScreen.actionType) then
        if (server_type ~= "sapp") then
            function preventClose()
                features.openMenu(const.uiWidgetDefinitions.voteMenu.path)
                return false
            end
            set_timer(5000, "preventClose")
        else
            -- Send vote map menu open request
            local loadMapVoteMenuRequest = {
                requestType = const.requests.loadVoteMapScreen.requestType
            }
            core.sendRequest(core.createRequest(loadMapVoteMenuRequest))

            local forgeState = forgeStore:getState()
            if (forgeState and forgeState.mapsMenu.mapsList) then
                -- Remove all the current vote maps
                votingStore:dispatch({type = "FLUSH_MAP_VOTES"})
                -- TODO This needs testing and probably a better implementation
                local mapGroups = glue.chunks(forgeState.mapsMenu.mapsList, 4)
                state.mapVotesGroup = state.mapVotesGroup + 1
                local currentGroup = mapGroups[state.mapVotesGroup]
                if (not currentGroup) then
                    state.mapVotesGroup = 1
                    currentGroup = mapGroups[state.mapVotesGroup]
                end
                for index, mapName in pairs(currentGroup) do
                    local availableGametypes = {}
                    ---@type forgeMap
                    local mapPath = (defaultMapsPath .. "\\%s.fmap"):format(mapName):gsub(" ", "_")
                                        :lower()
                    local mapData = json.decode(read_file(mapPath))
                    for _, forgeObject in pairs(mapData.objects) do
                        local tagPath = forgeObject.tagPath
                        if (tagPath:find("spawning")) then
                            if (tagPath:find("ctf")) then
                                availableGametypes["CTF"] = true
                            elseif (tagPath:find("slayer") or tagPath:find("generic")) then
                                availableGametypes["Slayer"] = true
                                availableGametypes["Team Slayer"] = true
                            elseif (tagPath:find("oddball")) then
                                availableGametypes["Oddball"] = true
                                availableGametypes["Juggernautº"] = true
                            end
                        end
                    end
                    console_out("Map Path: " .. mapPath)
                    local gametypes = glue.keys(availableGametypes)
                    console_out(inspect(gametypes))
                    math.randomseed(os.time())
                    local randomGametype = gametypes[math.random(1, #gametypes)]
                    local finalGametype = randomGametype or "Slayer"
                    console_out("Final Gametype: " .. finalGametype)
                    votingStore:dispatch({
                        type = const.requests.appendVoteMap.actionType,
                        payload = {
                            map = {
                                name = mapName,
                                gametype = finalGametype,
                                mapIndex = 1
                            }
                        }
                    })
                end
            end
            -- Send list of all available vote maps
            local votingState = votingStore:getState()
            for mapIndex, map in pairs(votingState.votingMenu.mapsList) do
                local voteMapOpenRequest = {
                    requestType = const.requests.appendVoteMap.requestType
                }
                glue.update(voteMapOpenRequest, map)
                core.sendRequest(core.createRequest(voteMapOpenRequest))
            end
        end
        return state
    elseif (action.type == const.requests.appendVoteMap.actionType) then
        if (server_type ~= "sapp") then
            local params = action.payload.requestObject
            votingStore:dispatch({
                type = const.requests.appendVoteMap.actionType,
                payload = {map = {name = params.name, gametype = params.gametype}}
            })
        end
        return state
    elseif (action.type == const.requests.sendTotalMapVotes.actionType) then
        if (server_type == "sapp") then
            local mapVotes = {0, 0, 0, 0}
            for playerIndex, mapIndex in pairs(state.playerVotes) do
                mapVotes[mapIndex] = mapVotes[mapIndex] + 1
            end
            -- Send vote map menu open request
            local sendTotalMapVotesRequest = {
                requestType = const.requests.sendTotalMapVotes.requestType

            }
            for mapIndex, votes in pairs(mapVotes) do
                sendTotalMapVotesRequest["votesMap" .. mapIndex] = votes
            end
            core.sendRequest(core.createRequest(sendTotalMapVotesRequest))
        else
            local params = action.payload.requestObject
            local votesList = {
                params.votesMap1,
                params.votesMap2,
                params.votesMap3,
                params.votesMap4
            }
            votingStore:dispatch({
                type = "SET_MAP_VOTES_LIST",
                payload = {votesList = votesList}
            })
        end
        return state
    elseif (action.type == const.requests.sendMapVote.actionType) then
        if (action.playerIndex and server_type == "sapp") then
            local playerName = get_var(action.playerIndex, "$name")
            if (not state.playerVotes[action.playerIndex]) then
                local params = action.payload.requestObject
                state.playerVotes[action.playerIndex] = params.mapVoted
                local votingState = votingStore:getState()
                local votedMap = votingState.votingMenu.mapsList[params.mapVoted]
                local mapName = votedMap.name
                local mapGametype = votedMap.gametype

                grprint(playerName .. " voted for " .. mapName .. " " .. mapGametype)
                eventsStore:dispatch({
                    type = const.requests.sendTotalMapVotes.actionType
                })
                local playerVotes = state.playerVotes
                if (#playerVotes > 0) then
                    local mapsList = votingState.votingMenu.mapsList
                    local mapVotes = {0, 0, 0, 0}
                    for playerIndex, mapIndex in pairs(playerVotes) do
                        mapVotes[mapIndex] = mapVotes[mapIndex] + 1
                    end
                    local mostVotedMapIndex = 1
                    local topVotes = 0
                    for mapIndex, votes in pairs(mapVotes) do
                        if (votes > topVotes) then
                            topVotes = votes
                            mostVotedMapIndex = mapIndex
                        end
                    end
                    local mostVotedMap = mapsList[mostVotedMapIndex]
                    local winnerMap = core.toSnakeCase(mostVotedMap.name)
                    local winnerGametype = core.toSnakeCase(mostVotedMap.gametype)
                    cprint("Most voted map is: " .. winnerMap)
                    forgeMapName = winnerMap
                    execute_script("sv_map " .. map .. " " .. winnerGametype)
                end
            end
        end
        return state
    elseif (action.type == const.requests.flushVotes.actionType) then
        state.playerVotes = {}
        return state
    elseif (action.type == const.requests.selectBiped.actionType) then
        if (blam.isGameSAPP()) then
            local bipedTagId = action.payload.requestObject.bipedTagId
            PlayersBiped[action.playerIndex] = bipedTagId
        end
        return state
    else
        if (action.type == "@@lua-redux/INIT") then
            dprint("Default events store state has been created!")
        else
            dprint("Error, dispatched event does not exist.", "error")
        end
        return state
    end
    return state
end

return eventsReducer

end,

["forge.reducers.playerReducer"] = function()
--------------------
-- Module: 'forge.reducers.playerReducer'
--------------------
local glue = require "glue"

-- Forge modules
local core = require "forge.core"
local features = require "forge.features"

---@class position
---@field x number
---@field y number
---@field z number

---@class playerState
---@field position position
local defaultState = {
    lockDistance = true,
    distance = 5,
    attachedObjectId = nil,
    position = nil,
    xOffset = 0,
    yOffset = 0,
    zOffset = 0,
    attachX = 0,
    attachY = 0,
    attachZ = 0,
    yaw = 0,
    pitch = 0,
    roll = 0,
    rotationStep = 5,
    currentAngle = "yaw",
    color = 1,
    teamIndex = 0
}

local function playerReducer(state, action)
    -- Create default state if it does not exist
    if (not state) then
        state = glue.deepcopy(defaultState)
    end
    if (action.type == "SET_LOCK_DISTANCE") then
        state.lockDistance = action.payload.lockDistance
        return state
    elseif (action.type == "CREATE_AND_ATTACH_OBJECT") then
        state.attachX = 0
        state.attachY = 0
        state.attachZ = 0
        state.yaw = 0
        state.pitch = 0
        state.roll = 0
        state.color = 1
        state.teamIndex = 0
        if (state.attachedObjectId) then
            if (get_object(state.attachedObjectId)) then
                delete_object(state.attachedObjectId)
                state.attachedObjectId = core.spawnObject("scen", action.payload.path,
                                                          state.xOffset, state.yOffset,
                                                          state.zOffset)
            else
                state.attachedObjectId = core.spawnObject("scen", action.payload.path,
                                                          state.xOffset, state.yOffset,
                                                          state.zOffset)
            end
        else
            state.attachedObjectId = core.spawnObject("scen", action.payload.path,
                                                      state.xOffset, state.yOffset,
                                                      state.zOffset)
        end
        -- core.rotateObject(state.attachedObjectId, state.yaw, state.pitch, state.roll)
        features.highlightObject(state.attachedObjectId, 1)
        return state
    elseif (action.type == "ATTACH_OBJECT") then
        state.attachedObjectId = action.payload.objectId
        local attachObject = action.payload.attach
        state.attachX = attachObject.x
        state.attachY = attachObject.y
        state.attachZ = attachObject.z
        local fromPerspective = action.payload.fromPerspective
        if (fromPerspective) then
            local player = blam.biped(get_dynamic_player())
            local tempObject = blam.object(get_object(state.attachedObjectId))
            if (tempObject) then
                local distance = core.calculateDistanceFromObject(player, tempObject)
                if (config.forge.snapMode) then
                    state.distance = glue.round(distance)
                else
                    state.distance = distance
                end
            end
        end
        local forgeObjects = eventsStore:getState().forgeObjects
        local forgeObject = forgeObjects[state.attachedObjectId]
        if (forgeObject) then
            state.yaw = forgeObject.yaw
            state.pitch = forgeObject.pitch
            state.roll = forgeObject.roll
            state.teamIndex = forgeObject.teamIndex
        end
        features.highlightObject(state.attachedObjectId, 1)
        return state
    elseif (action.type == "DETACH_OBJECT") then
        if (action.payload) then
            local payload = action.payload
            if (payload.undo) then
                state.attachedObjectId = nil
                return state
            end
        end
        -- Send update request in case of needed
        if (state.attachedObjectId) then
            local tempObject = blam.object(get_object(state.attachedObjectId))
            if (tempObject) then
                ---@type eventsState
                local eventsState = eventsStore:getState()
                local forgeObjects = eventsState.forgeObjects
                local forgeObject = forgeObjects[state.attachedObjectId]
                if (not forgeObject) then
                    -- Object does not exist, create request table and send request
                    local requestTable = {}
                    requestTable.requestType = const.requests.spawnObject.requestType
                    requestTable.tagId = tempObject.tagId
                    requestTable.x = state.xOffset
                    requestTable.y = state.yOffset
                    requestTable.z = state.zOffset
                    requestTable.yaw = state.yaw
                    requestTable.pitch = state.pitch
                    requestTable.roll = state.roll
                    requestTable.color = state.color
                    requestTable.teamIndex = state.teamIndex
                    core.sendRequest(core.createRequest(requestTable))
                    delete_object(state.attachedObjectId)
                else
                    local tempObject = blam.object(get_object(state.attachedObjectId))
                    local requestTable = {}
                    requestTable.objectId = forgeObject.remoteId
                    requestTable.requestType = const.requests.updateObject.requestType
                    requestTable.x = tempObject.x
                    requestTable.y = tempObject.y
                    requestTable.z = tempObject.z
                    requestTable.yaw = state.yaw
                    requestTable.pitch = state.pitch
                    requestTable.roll = state.roll
                    requestTable.color = state.color
                    requestTable.teamIndex = state.teamIndex
                    -- Object already exists, send update request
                    core.sendRequest(core.createRequest(requestTable))
                end
            end
            state.attachedObjectId = nil
        end
        return state
    elseif (action.type == "ROTATE_OBJECT") then
        if (state.attachedObjectId and get_object(state.attachedObjectId)) then
            core.rotateObject(state.attachedObjectId, state.yaw, state.pitch, state.roll)
        end
        return state
    elseif (action.type == "DESTROY_OBJECT") then
        -- Delete attached object
        if (state.attachedObjectId and get_object(state.attachedObjectId)) then
            local forgeObjects = eventsStore:getState().forgeObjects
            local forgeObject = forgeObjects[state.attachedObjectId]
            if (not forgeObject) then
                delete_object(state.attachedObjectId)
            else
                local requestTable = forgeObject
                requestTable.requestType = const.requests.deleteObject.requestType
                requestTable.remoteId = forgeObject.remoteId
                core.sendRequest(core.createRequest(requestTable))
            end
        end
        state.attachedObjectId = nil
        return state
    elseif (action.type == "UPDATE_OFFSETS") then
        local player = blam.biped(get_dynamic_player())
        local tempObject
        if (state.attachedObjectId) then
            tempObject = blam.object(get_object(state.attachedObjectId))
        end
        if (not tempObject) then
            tempObject = {x = 0, y = 0, z = 0}
        end
        local xOffset = player.x - state.attachX + player.cameraX * state.distance
        local yOffset = player.y - state.attachY + player.cameraY * state.distance
        local zOffset = player.z - state.attachZ + player.cameraZ * state.distance
        if (config.forge.snapMode) then
            state.xOffset = glue.round(xOffset)
            state.yOffset = glue.round(yOffset)
            state.zOffset = glue.round(zOffset)
        else
            state.xOffset = xOffset
            state.yOffset = yOffset
            state.zOffset = zOffset
        end
        -- dprint(state.xOffset .. " " ..  state.yOffset .. " " .. state.zOffset)
        return state
    elseif (action.type == "UPDATE_DISTANCE") then
        if (state.attachedObjectId) then
            local player = blam.biped(get_dynamic_player())
            local tempObject = blam.object(get_object(state.attachedObjectId))
            if (tempObject) then
                local distance = core.calculateDistanceFromObject(player, tempObject)
                if (config.forge.snapMode) then
                    state.distance = glue.round(distance)
                else
                    state.distance = distance
                end
            end
        end
        return state
    elseif (action.type == "SET_DISTANCE") then
        state.distance = action.payload.distance
        return state
    elseif (action.type == "CHANGE_ROTATION_ANGLE") then
        if (state.currentAngle == "yaw") then
            state.currentAngle = "pitch"
        elseif (state.currentAngle == "pitch") then
            state.currentAngle = "roll"
        else
            state.currentAngle = "yaw"
        end
        return state
    elseif (action.type == "SET_ROTATION_STEP") then
        state.rotationStep = action.payload.step
        return state
    elseif (action.type == "STEP_ROTATION_DEGREE") then
        local multiplier = 1
        state.attachX = 0
        state.attachY = 0
        state.attachZ = 0
        if (action.payload) then
            if (action.payload.substraction) then
                state.rotationStep = math.abs(state.rotationStep) * -1
            else
                state.rotationStep = math.abs(state.rotationStep)
            end
            multiplier = action.payload.multiplier or multiplier
        end
        local previousRotation = state[state.currentAngle]
        -- //TODO Add multiplier implementation
        local newRotation = previousRotation + (state.rotationStep)
        if ((newRotation) >= 360) then
            state[state.currentAngle] = newRotation - 360
        elseif ((newRotation) <= 0) then
            state[state.currentAngle] = newRotation + 360
        else
            state[state.currentAngle] = previousRotation + state.rotationStep
        end

        return state
    elseif (action.type == "SET_ROTATION_DEGREES") then
        if (action.payload.yaw) then
            state.yaw = action.payload.yaw
        end
        if (action.payload.pitch) then
            state.pitch = action.payload.pitch
        end
        if (action.payload.roll) then
            state.roll = action.payload.roll
        end
        return state
    elseif (action.type == "RESET_ROTATION") then
        state.yaw = 0
        state.pitch = 0
        state.roll = 0
        -- state.currentAngle = 'yaw'
        return state
    elseif (action.type == "SAVE_POSITION") then
        local tempObject = blam.biped(get_dynamic_player())
        state.position = {x = tempObject.x, y = tempObject.y, z = tempObject.z}
        return state
    elseif (action.type == "RESET_POSITION") then
        state.position = nil
        return state
    elseif (action.type == "SET_OBJECT_COLOR") then
        if (action.payload) then
            state.color = glue.index(const.colorsNumber)[action.payload]
        else
            dprint("Warning, attempt set color state value to nil.")
        end
        return state
    elseif (action.type == "SET_OBJECT_CHANNEL") then
        if (action.payload) then
            state.teamIndex = action.payload.channel
            dprint("teamIndex: " .. state.teamIndex)
        else
            dprint("Warning, attempt set teamIndex state value to nil.")
        end
        return state
    else
        return state
    end
    return state
end

return playerReducer

end,

["forge.reducers.votingReducer"] = function()
--------------------
-- Module: 'forge.reducers.votingReducer'
--------------------
-- Lua libraries
local inspect = require "inspect"
local glue = require "glue"

-- Forge modules
local interface = require "forge.interface"

---@class votingReducer
local defaultState = {
    votingMenu = {
        mapsList = {
            {
                name = "Begotten",
                gametype = "Team Slayer",
                mapIndex = 1
            },
            {
                name = "Octagon",
                gametype = "Slayer",
                mapIndex = 1
            },
            {
                name = "Strong Enough",
                gametype = "CTF",
                mapIndex = 1
            },
            {
                name = "Castle",
                gametype = "CTF",
                mapIndex = 1
            }
        },
        votesList = {0, 0, 0, 0}
    }
}

local function votingReducer(state, action)
    -- Create default state if it does not exist
    if (not state) then
        state = glue.deepcopy(defaultState)
    end
    if (action.type) then
        dprint("-> [Voting Store]")
        dprint("Action: " .. action.type, "category")
    end
    if (action.type == const.requests.appendVoteMap.actionType) then
        if (#state.votingMenu.mapsList < 4) then
            local map = action.payload.map
            glue.append(state.votingMenu.mapsList, map)
        end
        return state
    elseif (action.type == "SET_MAP_VOTES_LIST") then
        state.votingMenu.votesList = action.payload.votesList
        return state
    elseif (action.type == "FLUSH_MAP_VOTES") then
        state.votingMenu.mapsList = {}
        state.votingMenu.votesList = {0, 0, 0, 0}
        return state
    else
        if (action.type == "@@lua-redux/INIT") then
            dprint("Default state has been created!")
        else
            dprint("ERROR!!! The dispatched event does not exist:", "error")
        end
        return state
    end
    return state
end

return votingReducer

end,

["forge.reflectors.forgeReflector"] = function()
--------------------
-- Module: 'forge.reflectors.forgeReflector'
--------------------
------------------------------------------------------------------------------
-- Forge Reflector
-- Sledmine
-- Function reflector for store
------------------------------------------------------------------------------
local glue = require "glue"

local interface = require "forge.interface"
local features = require "forge.features"
local core = require "forge.core"
local forgeVersion = require "forge.version"

local function forgeReflector()
    -- Get current forge state
    ---@type forgeState
    local state = forgeStore:getState()

    local currentMenuPage = state.forgeMenu.currentPage
    local currentElements = state.forgeMenu.currentElementsList[currentMenuPage]

    -- Prevent errors objects does not exist
    if (not currentElements) then
        dprint("Current objects list is empty.", "warning")
        currentElements = {}
    end

    -- Forge Menu
    local forgeMenuElementsStrings = blam.unicodeStringList(const.unicodeStrings
                                                                .forgeMenuElementsTagId)
    forgeMenuElementsStrings.stringList = currentElements
    local newElementsCount = #currentElements + 2
    local elementsList = blam.uiWidgetDefinition(const.uiWidgetDefinitions.objectsList.id)
    if (elementsList and elementsList.childWidgetsCount ~= newElementsCount) then
        interface.update(const.uiWidgetDefinitions.objectsList, newElementsCount)
    end

    local pagination = blam.unicodeStringList(const.unicodeStrings.paginationTagId)
    if (pagination) then
        local paginationStringList = pagination.stringList
        paginationStringList[2] = tostring(currentMenuPage)
        paginationStringList[4] = tostring(#state.forgeMenu.currentElementsList)
        pagination.stringList = paginationStringList
    end

    -- Budget count
    -- Update unicode string with current budget value
    local currentBudget = blam.unicodeStringList(const.unicodeStrings.budgetCountTagId)

    -- Refresh budget count
    currentBudget.stringList = {
        state.forgeMenu.currentBudget,
        "/ " .. tostring(const.maximumObjectsBudget)
    }

    -- Refresh budget bar status
    local amountBarWidget = blam.uiWidgetDefinition(const.uiWidgetDefinitions.amountBar.id)
    amountBarWidget.width = state.forgeMenu.currentBarSize

    -- Refresh loading bar size
    local loadingProgressWidget = blam.uiWidgetDefinition(
                                      const.uiWidgetDefinitions.loadingProgress.id)
    loadingProgressWidget.width = state.loadingMenu.currentBarSize

    local currentMapsMenuPage = state.mapsMenu.currentPage
    local mapsListPage = state.mapsMenu.currentMapsList[currentMapsMenuPage]

    -- Prevent errors when maps does not exist
    if (not mapsListPage) then
        dprint("Current maps list is empty.")
        mapsListPage = {}
    end

    -- Refresh available forge maps list
    -- //TODO Merge unicode string updating with menus updating?

    local mapsListStrings = blam.unicodeStringList(const.unicodeStrings.mapsListTagId)
    mapsListStrings.stringList = mapsListPage

    local mapsListWidget = blam.uiWidgetDefinition(const.uiWidgetDefinitions.mapsList.id)
    local newElementsCount = #mapsListPage + 3
    if (mapsListWidget and mapsListWidget.childWidgetsCount ~= newElementsCount) then
        -- Wich ui widget will be updated and how many items it will show
        interface.update(const.uiWidgetDefinitions.mapsList, newElementsCount)
    end

    -- Refresh scroll bar
    -- TODO Move this into a new reducer to avoid reflector conflicts, or a better implementation
    local scrollBar = blam.uiWidgetDefinition(const.uiWidgetDefinitions.scrollBar.id)
    local scrollBarPosition = blam.uiWidgetDefinition(const.uiWidgetDefinitions.scrollPosition.id)
    if (scrollBar and scrollBarPosition) then
        if (features.getCurrentWidget() == const.uiWidgetDefinitions.mapsMenu.id) then
            local elementsCount = #state.mapsMenu.currentMapsList
            if (elementsCount > 0) then
                local barSizePerElement = glue.round(scrollBar.height / elementsCount)
                scrollBarPosition.height = barSizePerElement * state.mapsMenu.currentPage
                scrollBarPosition.boundsY = -barSizePerElement +
                                                (barSizePerElement * state.mapsMenu.currentPage)
            end
        else
            local elementsCount = #state.forgeMenu.currentElementsList
            if (elementsCount > 0) then
                local barSizePerElement = glue.round(scrollBar.height / elementsCount)
                scrollBarPosition.height = barSizePerElement * state.forgeMenu.currentPage
                scrollBarPosition.boundsY = -barSizePerElement +
                                                (barSizePerElement * state.forgeMenu.currentPage)
            end
        end
    end

    -- Refresh current forge map information
    local pauseGameStrings = blam.unicodeStringList(const.unicodeStrings.pauseGameStringsTagId)
    pauseGameStrings.stringList = {
        -- Skip elements using empty string
        "",
        "",
        "",
        -- Forge maps menu 
        state.currentMap.name,
        "Author: " .. state.currentMap.author,
        state.currentMap.version,
        state.currentMap.description,
        -- Forge loading objects screen
        "Loading " .. state.currentMap.name .. "...",
        state.loadingMenu.loadingObjectPath,
        "",
        "",
        "",
        "v" .. forgeVersion
    }
end

return forgeReflector

end,

["forge.reflectors.votingReflector"] = function()
--------------------
-- Module: 'forge.reflectors.votingReflector'
--------------------
------------------------------------------------------------------------------
-- Voting Reflector
-- Sledmine
-- Function reflector for store
------------------------------------------------------------------------------
local glue = require "glue"

local interface = require "forge.interface"

local function votingReflector()
    -- Get current forge state
    ---@type votingState
    local votingState = votingStore:getState()

    local votesList = votingState.votingMenu.votesList

    for k, v in pairs(votesList) do
        votesList[k] = tostring(v)
    end

    -- [Voting Menu]

    -- Update maps string list
    local mapsList = votingState.votingMenu.mapsList

    -- Prevent errors objects does not exist
    if (not mapsList) then
        dprint("Current maps vote list is empty.", "warning")
        mapsList = {}
    end

    local currentMapsList = {}
    for mapIndex, map in pairs(mapsList) do
        glue.append(currentMapsList, map.name .. "\r" .. map.gametype)
    end

    -- Get maps vote menu buttons lists
    local votingMapsMenuList = blam.uiWidgetDefinition(const.uiWidgetDefinitions.voteMenuList.id)
    votingMapsMenuList.childWidgetsCount = #glue.keys(currentMapsList)

    -- Get maps vote string list
    local votingMapsStrings = blam.unicodeStringList(const.unicodeStrings.votingMapsListTagId)
    votingMapsStrings.stringList = currentMapsList

    -- Get maps vote count string list
    local votingCountListStrings = blam.unicodeStringList(const.unicodeStrings.votingCountListTagId)
    votingCountListStrings.stringList = votesList

        -- TODO Add count replacing for child widgets
end

return votingReflector

end,

["forge.version"] = function()
--------------------
-- Module: 'forge.version'
--------------------
return "1.0.0-beta.5"
end,

----------------------
-- Modules part end --
----------------------
        }
        if files[path] then
            return files[path]
        else
            return origin_seacher(path)
        end
    end
end
---------------------------------------------------------
---------------- Auto Bundled Code Block ----------------
---------------------------------------------------------
------------------------------------------------------------------------------
-- Forge Island Server Script
-- Sledmine
-- Script server side for Forge Island
------------------------------------------------------------------------------
-- Constants
-- Declare SAPP API Version before importing modules
-- This is used by lua-blam for SAPP detection
api_version = "1.12.0.0"
-- Replace Chimera server type variable for compatibility purposes
server_type = "sapp"
-- Script name must be the base script name, without variants or extensions
scriptName = "forge_island_server" -- script_name:gsub(".lua", ""):gsub("_dev", ""):gsub("_beta", "")
defaultConfigurationPath = "config"
defaultMapsPath = "fmaps\\forge_island"

-- Print server current Lua version
print("Server is running " .. _VERSION)
-- Bring compatibility with Lua 5.3
require "compat53"
print("Compatibility with Lua 5.3 has been loaded!")

-- Lua modules
local inspect = require "inspect"
local glue = require "glue"
local redux = require "lua-redux"
local json = require "json"

-- Specific Halo Custom Edition modules
blam = require "blam"
tagClasses = blam.tagClasses
local rcon = require "rcon"

-- Forge modules
local core = require "forge.core"
local features = require "forge.features"

-- Reducers importation
local eventsReducer = require "forge.reducers.eventsReducer"
local votingReducer = require "forge.reducers.votingReducer"
local forgeReducer = require "forge.reducers.forgeReducer"

-- Variable used to store the current Forge map in memory
-- FIXME This should take the first map available on the list
forgeMapName = "octagon"
forgeMapFinishedLoading = false
-- Controls if "Forging" is available or not in the current game
local forgingEnabled = false
local mapVotingEnabled = true

-- TODO This needs some refactoring, this configuration is kinda useless on server side
-- Forge default configuration
config = {
    forge = {
        debugMode = false,
        autoSave = false,
        autoSaveTime = 15000,
        snapMode = false,
        objectsCastShadow = false
    }
}
-- Default debug mode state, set to false at release time to improve performance
config.forge.debugMode = false
--- Function to send debug messages to console output
---@param message string
---@param color string
function dprint(message, color)
    if (config.forge.debugMode) then
        local message = message
        if (type(message) ~= "string") then
            message = inspect(message)
        end
        debugBuffer = (debugBuffer or "") .. message .. "\n"
        if (color == "category") then
            console_out(message, 0.31, 0.631, 0.976)
        elseif (color == "warning") then
            console_out(message, blam.consoleColors.warning)
        elseif (color == "error") then
            console_out(message, blam.consoleColors.error)
        elseif (color == "success") then
            console_out(message, 0.235, 0.82, 0)
        else
            console_out(message)
        end
    end
end

--- Print console text to every player in the server
---@param message string
function grprint(message)
    for playerIndex = 1, 16 do
        if (player_present(playerIndex)) then
            rprint(playerIndex, message)
        end
    end
end

PlayersBiped = {}
local monitorPlayers = {}
local tempPosition = {}
local playerSyncThread = {}
local ticksTimer = {}

-- TODO This function should be used as thread controller instead of a function executor
function OnTick()
    if (forgeMapFinishedLoading) then
        for playerIndex = 1, 16 do
            if (player_present(playerIndex)) then
                features.regenerateHealth(playerIndex)
                -- Run player object sync thread
                local syncThread = playerSyncThread[playerIndex]
                if (syncThread) then
                    if (coroutine.status(syncThread) == "suspended") then
                        local status, response = coroutine.resume(syncThread)
                        if (status and response) then
                            core.sendRequest(response, playerIndex)
                        end
                    else
                        console_out("Object sync finished for player " .. playerIndex)
                        playerSyncThread[playerIndex] = nil
                    end
                end
                local playerObjectId = blam.player(get_player(playerIndex)).objectId
                if (playerObjectId) then
                    local player = blam.biped(get_object(playerObjectId))
                    if (player) then
                        if (forgingEnabled) then
                            -- Save player position before swap
                            tempPosition[playerIndex] = {player.x, player.y, player.z}
                            if (const.bipeds.monitorTagId) then
                                if (player.crouchHold and player.tagId == const.bipeds.monitorTagId) then
                                    monitorPlayers[playerIndex] = false
                                    delete_object(playerObjectId)
                                elseif (player.flashlightKey and player.tagId ~=
                                    const.bipeds.monitorTagId) then
                                    monitorPlayers[playerIndex] = true
                                    delete_object(playerObjectId)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Add our commands logic to rcon
function rcon.commandInterceptor(playerIndex, message, environment, rconPassword)
    dprint("Incoming rcon command:", "warning")
    dprint(message)
    local request = string.gsub(message, "'", "")
    local data = glue.string.split(request, const.requestSeparator)
    local incomingRequest = data[1]
    local actionType
    local currentRequest
    for requestName, request in pairs(const.requests) do
        if (incomingRequest and incomingRequest == request.requestType) then
            currentRequest = request
            actionType = request.actionType
        end
    end
    -- Parsing rcon request
    if (actionType) then
        return core.processRequest(actionType, request, currentRequest, playerIndex)
    else
        -- Parsing rcon command
        data = glue.string.split(request, " ")
        for i, param in pairs(data) do
            data[i] = param:gsub("\"", "")
        end
        local forgeCommand = data[1]
        if (forgeCommand == "fload") then
            local mapName = data[2]
            local gameType = data[3]
            if (mapName and gameType) then
                if (read_file(defaultMapsPath .. "\\" .. mapName .. ".fmap")) then
                    cprint("Loading map " .. mapName .. " on " .. gameType .. "...")
                    forgeMapName = mapName
                    mapVotingEnabled = false
                    execute_script("sv_map " .. map .. " " .. gameType or "slayer")
                else
                    rprint(playerIndex, "Could not read Forge map " .. mapName .. " file!")
                end
            else
                cprint("You must specify a forge map name and a gametype.")
                rprint(playerIndex, "You must specify a forge map name and a gametype.")
            end
        elseif (forgeCommand == "fbiped") then
            local bipedName = data[2]
            if (bipedName) then
                for playerIndex = 1, 16 do
                    if (player_present(playerIndex)) then
                        -- FIXME Tag id string should be added here
                        PlayersBiped[playerIndex] = bipedName
                    end
                end
                execute_script("sv_map_reset")
            else
                rprint(playerIndex, "You must specify a biped name.")
            end
        elseif (forgeCommand == "fforge") then
            forgeMapFinishedLoading = true
            forgingEnabled = not forgingEnabled
            if (forgingEnabled) then
                grprint("Admin ENABLED :D Forge mode!")
            else
                grprint("Admin DISABLED Forge mode!")
            end
        elseif (forgeCommand == "fspawn") then
            -- Get scenario data
            local scenario = blam.scenario(0)

            -- Get scenario player spawn points
            local mapSpawnPoints = scenario.spawnLocationList

            mapSpawnPoints[1].type = 12

            scenario.spawnLocationList = mapSpawnPoints
        elseif (forgeCommand == "fcache") then
            local eventsState = eventsStore:getState()
            local cachedResponses = eventsState.cachedResponses
            console_out(#glue.keys(cachedResponses))
        end
    end
end

--[[function OnCommand(playerIndex, command, environment, rconPassword)
    return rcon.OnCommand(playerIndex, command, environment, rconPassword)
end]]

OnCommand = rcon.OnCommand

function OnScriptLoad()
    rcon.attach()
    register_callback(cb["EVENT_GAME_START"], "OnGameStart")
    register_callback(cb["EVENT_GAME_END"], "OnGameEnd")
    register_callback(cb["EVENT_COMMAND"], "OnCommand")
end

function OnGameStart()
    -- Provide compatibily with Chimera by setting "map" as a global variable with current map name
    map = get_var(0, "$map")
    const = require "forge.constants"

    -- Add forge rcon as not dangerous for command interception
    rcon.submitRcon("forge")

    -- Add forge public commands
    local publicCommands = {
        const.requests.spawnObject.requestType,
        const.requests.updateObject.requestType,
        const.requests.deleteObject.requestType,
        const.requests.sendMapVote.requestType,
        const.requests.selectBiped.requestType
    }
    for _, command in pairs(publicCommands) do
        rcon.submitCommand(command)
    end

    -- Add forge admin commands
    local adminCommands = {"fload", "fsave", "fforge", "fbiped"}
    for _, command in pairs(adminCommands) do
        rcon.submitAdmimCommand(command)
    end

    -- Stores for all the forge data
    forgeStore = forgeStore or redux.createStore(forgeReducer)
    eventsStore = eventsStore or redux.createStore(eventsReducer)
    votingStore = votingStore or redux.createStore(votingReducer)

    -- local restoredEventsState = read_file("eventsState.json")
    -- local restoredForgeState = read_file("forgeState.json")
    -- if (restoredEventsState and restoredForgeState) then
    --    local restorationEventsState = json.decode(restoredEventsState)
    --    local restorationForgeState = json.decode(restoredForgeState)
    --    ---@type forgeState
    --    local forgeState = forgeStore:getState()
    --    forgeState = restorationForgeState
    --    ---@type eventsState
    --    local eventsState = eventsStore:getState()
    --    eventsState = restorationEventsState
    --    forgeMapName = forgeState.currentMap.name:gsub(" ", "_"):lower()
    -- end

    -- TODO Check if this is better to do on script load
    core.loadForgeMaps()

    if (forgeMapName) then
        core.loadForgeMap(forgeMapName)
    end

    eventsStore:dispatch({type = const.requests.flushVotes.actionType})
    mapVotingEnabled = true
    register_callback(cb["EVENT_TICK"], "OnTick")
    register_callback(cb["EVENT_JOIN"], "OnPlayerJoin")
    register_callback(cb["EVENT_OBJECT_SPAWN"], "OnObjectSpawn")
    register_callback(cb["EVENT_PRESPAWN"], "OnPlayerSpawn")
end

-- Change biped tag id from players and store their object ids
function OnObjectSpawn(playerIndex, tagId, parentId, objectId)
    -- Intercept objects that are related to a player
    if (playerIndex) then
        for index, bipedTagId in pairs(const.bipeds) do
            if (tagId == bipedTagId) then
                if (monitorPlayers[playerIndex]) then
                    return true, const.bipeds.monitorTagId
                else
                    local customBipedTagId = PlayersBiped[playerIndex]
                    if (customBipedTagId) then
                        return true, customBipedTagId
                    else
                        return true
                    end
                end
            end
        end
    end
    return true
end

-- Update object data after spawning
function OnPlayerSpawn(playerIndex)
    local player = blam.biped(get_dynamic_player(playerIndex))
    if (player) then
        -- Provide better movement to monitors
        if (core.isPlayerMonitor(playerIndex)) then
            -- player.ignoreCollision = true
        end
        local playerPosition = tempPosition[playerIndex]
        if (playerPosition) then
            player.x = playerPosition[1]
            player.y = playerPosition[2]
            player.z = playerPosition[3]
            tempPosition[playerIndex] = nil
        end
    end
end

local function asyncObjectSync(playerIndex, cachedResponses)
    -- Yield the coroutine to skip the first coroutine creation
    coroutine.yield()
    -- Send to to player all the current forged objects
    for objectIndex, response in pairs(cachedResponses) do
        coroutine.yield(response)
    end
end

-- Sync data to incoming players
function OnPlayerJoin(playerIndex)
    local forgeState = forgeStore:getState()
    local eventsState = eventsStore:getState()
    local forgeObjects = eventsState.forgeObjects
    local countableForgeObjects = glue.keys(forgeObjects)
    local objectCount = #countableForgeObjects

    local cachedResponses = eventsState.cachedResponses

    -- There are Forge objects that need to be synced
    if (forgeMapName or objectCount > 0) then
        console_out("Sending map info for: " .. playerIndex)

        -- Create a temporal Forge map object like to force data sync
        local onMemoryForgeMap = {}
        onMemoryForgeMap.objects = countableForgeObjects
        onMemoryForgeMap.name = forgeState.currentMap.name
        onMemoryForgeMap.description = forgeState.currentMap.description
        onMemoryForgeMap.author = forgeState.currentMap.author
        core.sendMapData(onMemoryForgeMap, playerIndex)

        dprint("Creating sync thread for: " .. playerIndex)
        local co = coroutine.create(asyncObjectSync)
        -- Prepare function with desired parameters
        coroutine.resume(co, playerIndex, cachedResponses)
        playerSyncThread[playerIndex] = co
    end
end

function OnGameEnd()
    -- Events store are already loaded
    if (eventsStore) then
        -- Clean all forge stuff
        eventsStore:dispatch({type = const.requests.flushForge.actionType})
        -- Start vote map screen
        if (mapVotingEnabled) then
            eventsStore:dispatch({type = const.requests.loadVoteMapScreen.actionType})
        end
    end
    -- FIXME This needs a better implementation
    -- write_file("eventsState.json", json.encode(eventsStore:getState()))
    -----@type forgeState
    -- local dumpedState = forgeStore:getState()
    -- dumpedState.currentMap.name = forgeMapName
    -- write_file("forgeState.json", json.encode(dumpedState))
    collectgarbage("collect")
end

function OnError()
    cprint(debug.traceback())
end

function OnScriptUnload()
    rcon.detach()
end