--!strict
-- Services
-- Packages
-- Modules
-- Types
type State = "E" | "O"
type ResultImpl<V, E> = {
	__index: ResultImpl<V, E>,
	isOk: (self: Result<V, E>) -> boolean,
	isErr: (self: Result<V, E>) -> boolean,
	onOk: (self: Result<V, E>, fn: (ok: V) -> ()) -> (),
	onErr: (self: Result<V, E>, fn: (err: E) -> ()) -> (),
	match: <O>(self: Result<V, E>, ok: (ok: V) -> O, err: (err: E) -> O) -> O,
	unwrap: (self: Result<V, E>) -> V,
	unwrapErr: (self: Result<V, E>) -> E,
	expect: (self: Result<V, E>, msg: string) -> V,
}

export type Result<V, E> = typeof(setmetatable(
	{} :: {
		_state: State,
		_ok: V,
		_err: nil,
	} | {
		_state: State,
		_ok: nil,
		_err: E,
	},
	{} :: ResultImpl<V, E>
))

-- Constants
local STATE_OK: State = "O"
local STATE_ERR: State = "E"
-- Variables
-- References
-- Private Functions
-- Class
local Result = {} :: ResultImpl<unknown, unknown>
Result.__index = Result

function Result:isOk(): boolean
	return self._state == STATE_OK
end

function Result:isErr(): boolean
	return self._state == STATE_ERR
end

function Result:onOk(fn: (ok: unknown) -> ())
	if self:isOk() then
		fn(self._ok)
	end
end

function Result:onErr(fn: (err: unknown) -> ())
	if self:isErr() then
		fn(self._err)
	end
end

function Result:match<O>(ok: (ok: unknown) -> O, err: (err: unknown) -> O): O
	if self:isErr() then
		return err(self._err)
	else
		assert(self:isOk())
		return ok(self._ok)
	end
end

function Result:unwrap()
	if self:isOk() then
		return self._ok
	end
	error(`{self._err}`)
end

function Result:unwrapErr()
	if self:isErr() then
		return self._err
	end
	error(`result is not error`)
end

function Result:expect(msg: string)
	if self:isOk() then
		return self._ok
	end
	error(msg)
end

local fromOk = function<V, E>(ok: V): Result<V, E>
	local self: Result<V, E> = setmetatable({
		_state = STATE_OK,
		_ok = ok,
		_err = nil,
	}, Result :: ResultImpl<any, any>)
	table.freeze(self)
	return self
end
local fromErr = function<V, E>(err: E): Result<V, E>
	local self: Result<V, E> = setmetatable({
		_state = STATE_ERR,
		_ok = nil,
		_err = err,
	}, Result :: ResultImpl<any, any>)
	table.freeze(self)
	return self
end
local try = function<V, string>(fn: () -> V): Result<V, string>
	local out: V
	local success, msg = pcall(function()
		out = fn()
	end)
	if success then
		return fromOk(out)
	else
		return fromErr(msg)
	end
end

return {
	ok = fromOk,
	err = fromErr,
	try = try,
}
