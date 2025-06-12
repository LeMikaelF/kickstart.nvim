-- visit in this order: errors → warnings → info → hints
local order = {
  vim.diagnostic.severity.ERROR,
  vim.diagnostic.severity.WARN,
  vim.diagnostic.severity.INFO,
  vim.diagnostic.severity.HINT,
}

---@param dir (-1|1)      -- +1 = next, ‑1 = prev
local function cycle(dir)
  -- first sweep: look in the chosen direction, *no* wrap‑around yet
  for _, sev in ipairs(order) do
    local ok = vim.diagnostic.jump {
      count = dir, -- +1 or -1 step
      severity = sev, -- this severity only
      wrap = false, -- stay inside the file’s forward/backward span
      float = { focus = false },
    }
    if ok then
      return
    end -- stopped on the first hit of that severity
  end

  -- nothing left in this direction → restart at the top (errors) with wrapping
  vim.diagnostic.jump {
    count = dir,
    severity = order[1], -- ERROR
    wrap = true, -- allow wrap‑around once
    float = { focus = false },
  }
end

vim.keymap.set('n', '<leader>n', function()
  cycle(1)
end, { desc = 'Next diagnostic (errors → warnings → info)' })

vim.keymap.set('n', '<leader>p', function()
  cycle(-1)
end, { desc = 'Prev diagnostic (errors → warnings → info)' })

vim.keymap.set('n', '<Leader>N', function()
  vim.diagnostic.jump { count = 1, float = true }
end, { desc = 'Next diagnostic' })

vim.keymap.set('n', '<Leader>P', function()
  vim.diagnostic.jump { count = 1, float = true }
end, { desc = 'Prev diagnostic' })

return {}
