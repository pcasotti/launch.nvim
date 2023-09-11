------------------------------------------- LAUNCH.NVIM --------------------------------------------

local config = require 'launch.config'
local core = require 'launch.core'
local task = require 'launch.task'
local util = require 'launch.util'

local M = {}

---plugin setup function
---@param opts? PluginConfig
function M.setup(opts)
  config.apply(opts)

  -- checking for debugger support via nvim-dap
  if config.user.debug.disable then
    vim.api.nvim_del_user_command 'LaunchDebugger'
  else
    util.try_require('dap', true)
  end

  core.load_config_file()
end

---displays available tasks to the user and launches the selected task
---@param show_all_fts boolean whether to display all tasks or only based on current filetype
function M.task(show_all_fts)
  local run = config.user.task.runner or task.runner
  core.start('task', show_all_fts, task.list, run)
end

---displays available debug configurations to the user and launches the selected config
---@param show_all_fts boolean whether to display all configs or only based on current filetype
function M.debugger(show_all_fts)
  if config.user.debug.disable then
    util.notify('E', 'Debugger support has been manually disabled by the user')
    return
  end

  local dap = util.try_require('dap', true)
  if not dap then return end

  local run = config.user.debug.runner or dap.run
  core.start('debug', show_all_fts, dap.configurations, run)
end

return M
