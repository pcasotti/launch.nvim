---------------------------------------- USER INPUT HANDLER ----------------------------------------

local util = require 'launch.util'

local M = {}

---@type table<string, UserVariable> mapping of user-defined variable names to their specifications
M.variables = {}

---callback function for global substitution of an argument
---@param name string matched `${input:...}` variable
---@return string? # replacement string
---@nodiscard
---*[POSSIBLY THROWS ERROR]*
local function gsub_callback(name, cb)
  vim.api.nvim_command 'redraw' -- clean up previous substitution
  local var = M.variables[name]
  if not var then util.throw_notify('E', 'User variable "%s" not defined', name) end

  var:get_user_choice(function(choice)
    if not choice then
      -- if user does not enter or select anything, stop substitution
      vim.api.nvim_command 'redraw'
      util.throw_notify('W', 'Task runner launch cancelled')
    end
    cb(choice)
  end)
end

---substitution of argument strings with user input
---@param args string[] list of argument strings to substitute
---@return boolean # whether substitution was successful or not
---@nodiscard
function M.substitute_variables(args, cb)
  local indices = {}
  local j = 1
  for i = 1, #args do
    if args[i] ~= string.gsub(args[i], '{@([_%a][_%w]*)}', function(name) return name end) then
      indices[j] = i
      j = j+1
    end
  end

  local func = function(f, i, size)
    if i > size then
      cb(args)
      return
    end
    pcall(string.gsub, args[indices[i]], '{@([_%a][_%w]*)}', function(name)
      gsub_callback(name, function(choice)
        args[indices[i]] = choice
        f(f, i+1, size)
      end)
    end)
  end

  func(func, 1, table.getn(indices))

  -- pcall(string.gsub, args[indices[1]], '{@([_%a][_%w]*)}', function(name)
  --   gsub_callback(name, function(choice)
  --     args[indices[1]] = choice
  --     pcall(string.gsub, args[indices[2]], '{@([_%a][_%w]*)}', function(name)
  --       gsub_callback(name, function(choice)
  --         args[indices[2]] = choice
  --         pcall(string.gsub, args[indices[2]], '{@([_%a][_%w]*)}', function(name)
  --           gsub_callback(name, function(choice)
  --             args[indices[2]] = choice
  --             cb(args)
  --           end)
  --         end)
  --       end)
  --     end)
  --   end)
  -- end)

  -- local ok
  -- for i = 1, #args do
  --   ok, args[i] = pcall(string.gsub, args[i], '{@([_%a][_%w]*)}', gsub_callback)
  --   if not ok then return false end
  -- end
  --
  -- return true
end

return M
