--!strict
-- https://doc.rust-lang.org/std/result/enum.Result.html
-- Services
-- Packages
local Error = require("@pkg/@nightcycle/error")
-- Modules
-- Types
type State = "E" | "O"
type ResultImpl<V, E> = {
	__index: ResultImpl<V, E>,
	__tostring: (self: any) -> string,
	__eq: (self: any, other: Result<V, E>) -> boolean,
	isOk: (self: any) -> boolean,
	isErr: (self: any) -> boolean,
	inspect: (self: any, fn: (ok: V) -> ()) -> Result<V, E>,
	inspectErr: (self: any, fn: (err: E) -> ()) -> Result<V, E>,
	match: <O>(self: any, ok: (ok: V) -> O, err: (err: E) -> O) -> O,
	--type swapping with map stuff is technically okay, but I can't get the type engine to recognize that
	map: (self: any, fn: (ok: V) -> V) -> Result<V, E>,
	mapErr: (self: any, fn: (err: E) -> E) -> Result<V, E>,
	unwrap: (self: any) -> V,
	unwrapErr: (self: any) -> E,
	unwrapOr: (self: any, alt: V) -> V,
	unwrapOrElse: (self: any, fn: () -> V) -> V,
	asNullable: (self: any) -> V?,
	expect: (self: any, msg: string) -> V,
}
type ResultStruct<V, E> = {
	_state: string, --State, --replaced for performance reasons
	_ok: V?,
	_err: E?,
}
export type Result<V, E> = ResultImpl<V, E>

-- Constants
local STATE_OK: State = "O"
local STATE_ERR: State = "E"
-- Variables
-- References
-- Private Functions

-- Class
local Result = {} :: ResultImpl<unknown, unknown>
Result.__index = Result

-- non-construct interface methods
local isResult = function<V, E>(value: unknown?): boolean
	if typeof(value) == "table" then
		return getmetatable(value :: any) == Result
	end
	return false
end

-- Constructors
local fromOk = function<V, E>(ok: V): Result<V, any>
	local self: any = setmetatable({
		_state = STATE_OK :: string,
		_ok = ok,
		_err = nil,
	}, Result :: ResultImpl<any, any>)
	table.freeze(self)
	return self
end
local fromErr = function<V, E>(err: E): Result<any, E>
	local self: any = setmetatable({
		_state = STATE_ERR :: string,
		_ok = nil,
		_err = err,
	}, Result :: ResultImpl<any, any>)
	table.freeze(self)
	return self
end

local try = function<V, string>(fn: () -> V): Result<V, string>
	local out: V
	local errMessage: string?
	xpcall(function()
		out = fn()
	end, function(msg)
		errMessage = msg
	end)
	if errMessage then
		return fromErr(errMessage)
	else
		return fromOk(out)
	end
end

-- methods
function Result:__tostring(): string
	if Result.isOk(self) then
		if typeof(self._ok) == "table" then
			return `Ok<{Error.displayAsJson(self._ok)}>`
		end
		return `Ok<{self._ok}>`
	end
	if typeof(self._err) == "table" then
		if Error.isErr(self._err) then
			return `Err<{self._err:display("Full")}>`
		end
		return `Ok<{Error.displayAsJson(self._err)}>`
	end
	return `Err<{self._err}>`
end

function Result:__eq(other: Result<unknown, unknown>): boolean
	local ot: any = other
	if Result.isOk(self) and Result.isOk(other) then
		return self._ok == ot._ok
	elseif Result.isErr(self) and Result.isErr(other) then
		return self._err == ot._err
	end
	return false
end

function Result:isOk(): boolean
	return self._state == STATE_OK
end

-- Returns true if the result is Err.
function Result:isErr(): boolean
	return self._state == STATE_ERR
end

function Result:asNullable(): unknown?
	if Result.isOk(self) then
		return self._ok
	end
	return nil
end

function Result:inspect(fn: (ok: unknown) -> ())
	if Result.isOk(self) then
		fn(self._ok)
	end
	return self
end

function Result:inspectErr(fn: (err: unknown) -> ())
	if Result.isErr(self) then
		fn(self._err)
	end
	return self
end

function Result:match<O>(ok: (ok: unknown) -> O, err: (err: unknown) -> O): O
	if Result.isOk(self) then
		return ok(self._ok)
	else
		return err(self._err)
	end
end

function Result:map(fn: (ok: unknown) -> unknown): Result<unknown, unknown>
	return Result.match(self, function(ok)
		return fromOk(fn(self._ok))
	end, function(err)
		return fromErr(self._err)
	end)
end

function Result:mapErr(fn: (err: unknown) -> unknown): Result<unknown, unknown>
	return Result.match(self, function(ok)
		return fromOk(self._ok)
	end, function(err)
		return fromErr(fn(self._err))
	end)
end

function Result:unwrap()
	if Result.isOk(self) then
		return self._ok
	end
	error(
		`{if Error.isErr(self._err)
			then self._err:display("Full")
			elseif typeof(self._err) == "table" then Error.displayAsJson(self._err)
			else self._err}`
	)
end

function Result:unwrapErr()
	if Result.isErr(self) then
		return self._err
	end
	error(`result is not error`)
end

function Result:unwrapOr(alt: unknown)
	return Result.match(self, function(ok)
		return ok
	end, function(err)
		return alt
	end)
end

function Result:unwrapOrElse(fn: () -> unknown)
	return Result.match(self, function(ok)
		return ok
	end, function(err)
		return fn()
	end)
end

function Result:expect(msg: string)
	if Result.isOk(self) then
		return self._ok
	end
	error(msg)
end

local DeprecatedResult = Result :: any

function DeprecatedResult:mapOr(mapFn: (ok: unknown) -> unknown, alt: unknown): Result<unknown, unknown>
	if Result.isOk(self) then
		return fromOk(mapFn(self._ok))
	end
	return fromOk(alt)
end

function DeprecatedResult:mapOrElse(
	mapFn: (ok: unknown) -> unknown,
	elseFn: () -> unknown
): Result<unknown, unknown>
	if Result.isOk(self) then
		return fromOk(mapFn(self._ok))
	end
	return fromOk(elseFn())
end

return {
	ok = fromOk,
	err = fromErr,
	try = try,
	map = function<VI, VO, E>(result: Result<VI, E>, fn: (ok: VI) -> VO): Result<VO, E>
		return result:map(fn :: any) :: any
	end,
	mapErr = function<V, EI, EO>(result: Result<V, EI>, fn: (err: EI) -> EO): Result<V, EO>
		return result:mapErr(fn :: any) :: any
	end,
	-- constructs a runtime type-checker with the same format as osyrisrblx/t
	type = function<V, E>(
		okType: (value: V) -> (boolean, string?),
		errType: (value: E) -> (boolean, string?)
	): (value: unknown?) -> (boolean, string?)
		return function(value: unknown?): (boolean, string?)
			if typeof(value) == "table" then
				local mt = getmetatable(value :: any)
				if mt == Result then
					local valRes: Result<V, E> = value :: Result<V, E>
					return valRes:match(function(ok)
						return okType(ok)
					end, function(err)
						return errType(err)
					end)
				end
			end
			return false, "Value is not a result"
		end
	end,
	-- because the syntax of local result = (function() return Result.ok(1) end)() is not ideal
	from = function<V, E>(callback: () -> Result<V, E>): Result<V, E>
		return callback()
	end,
	-- if you're already using a pcall and want to wrap it in a result, use this
	catch = function(success: boolean, message: string?): Result<true, string>
		if success then
			return fromOk(true :: true) :: any
		else
			assert(
				typeof(message) == "string",
				`message must be a string when success = false, got "{typeof(message)}"`
			)
			return fromErr(message)
		end
	end,
	isResult = isResult,
}
