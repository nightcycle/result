# result

A safer alternative to pcall / error handling.

## usage

It's a pretty lightweight package.

### construction

You can create a new result via a few methods

```luau
local okResult: Result<number, any> = Result.ok(1)
local errResult: Result<any, string> = Result.err("an error occured!")

-- basically the same as a pcall
local result: Result<number, string> = Result.try(function()
    if RunServer:IsStudio() == false then
        return 1
    else
        error("this value can only be retrieved in a live game")
    end
end)

-- a basic callback where you return a result using other methods
-- it's more readable + typesafe than `local result = (function() return Result.ok(1) end)()`
result = Result.from(function()
    if RunServer:IsStudio() == false then
        return Result.ok(1)
    else
        return Result.err("this value can only be retrieved in a live game")
    end
end)

-- handy function for migrating non-value returning pcalls into results
result: Result<number, string> = Result.catch(pcall(function()
    riskyFunction()
    return 1
end))
```

### helper functions

The package interface has a few handy methods.

```luau

-- map functions that support type changing
local resultV3: Result<Vector3, string> = Option.map(result, function(v: number): Vector3
    return v*Vector3.one
end)
local errorBuffer: Result<number, buffer> = Option.mapErr(result, function(str: string): buffer
    return buffer.fromString(str)
end)

-- isResult checks whether an unknown value is a result or not
assert(Result.isResult(result), `value is not a result`)

-- supports `osyrisrblx/t` standard runtime type refinement
local isAnIntStrResult = Result.type(t.integer, t.string)
local success, message = isAnIntStrResult(result)
```

### methods

For checking the state of the result:

```luau
if result:isOk() then
    print("result is ok!")
end

if result:isErr() then
    print("result is err!")
end

-- only runs when ok, otherwise it's passed over
result:inspect(function(ok)
    print(`ok result is "{ok}"!`)
end)

-- only runs when ok, otherwise it's passed over
result:inspectErr(function(e)
    print(`err result is "{e}"!`)
end)
```

For extracting the state of the result:

```luau
-- if the result is err, the thread panics
local okValue = result:unwrap()
okValue = result:expect(`name is none()`) -- same as unwrap, but custom error message

-- both functions need to return the same type, used for flattening the result
local value = result:match(function(v: number)
    return v
end, function(e: string)
    return -1
end)

-- if you don't need to process the ok() / err() value, unwrapOr is a handy alternative
value = result:unwrapOr(-1)

-- only calls the function if there's an err value - good for performance if getting the value is process heavy
value = result:unwrapOrElse(function()
    return -1
end)

local maybeValue: number? = result:asNullable() -- most of the ecosystem uses null values, it's silly to pretend otherwise

-- returns a new result with the modified ok value
local doubleValue: Result<number, string> = name:map(function(ok)
    return ok * 2
end)

-- returns a new result with the modified err value
local shoutedError: Result<number, string> = name:mapErr(function(e)
    return e:upper()
end)
```

## bloxidize

If you like this, check out my suite of rust inspired packages: [bloxidize](https://github.com/nightcycle/bloxidize)