-- lua/cpp_hover.lua
local M = {}

local api, fn, util = vim.api, vim.fn, vim.lsp.util

M.config = {
  border = 'rounded',
  cppman_max_lines = 200,        -- clip long pages in K (use gK for full)
  header_clangd = '### clangd',
  header_cppman = '### cppreference (cppman)',
}

M._state = { win = nil, buf = nil } -- last hover float for refocus

-- ---------- helpers --------------------------------------------------------

local function encoding_for(buf)
  local clients = vim.lsp.get_clients({ bufnr = buf })
  for _, c in ipairs(clients) do
    if c.name == 'clangd' and c.offset_encoding then
      return c.offset_encoding
    end
  end
  return (clients[1] and clients[1].offset_encoding) or 'utf-16'
end

local function under_cursor()
  return (fn.expand('<cword>'):gsub('<.*>', ''))
end

-- trim without deprecated util.trim_empty_lines
local function trim_empty(lines)
  if not lines or #lines == 0 then return {} end
  local i, j = 1, #lines
  while i <= j and lines[i]:match('^%s*$') do i = i + 1 end
  while j >= i and lines[j]:match('^%s*$') do j = j - 1 end
  local out = {}
  for k = i, j do out[#out+1] = lines[k] end
  return out
end

local function convert_hover(result)
  if not result or not result.contents then return {} end
  return trim_empty(util.convert_input_to_markdown_lines(result.contents) or {})
end

local function derive_cpp_key(clangd_md)
  for _, line in ipairs(clangd_md) do
    line = line:gsub('`', '')
    local member = line:match('(std::[%w_:%-]+::[%w_]+)') -- std::vector::push_back
    if member then return member end
    local type_ = line:match('(std::[%w_]+)')            -- std::bitset
    if type_ then return type_ end
  end
  return nil
end

local function canonicalize(sym)
  if not sym or sym == '' then return sym end
  if not sym:find('^std::') then sym = 'std::' .. sym end
  sym = sym:gsub('^std::__[%w_]+::', 'std::') -- drop ABI ns (__1, __cxx11)
  sym = sym:gsub('^std::basic_string$', 'std::string')
  sym = sym:gsub('^std::basic_string_view$', 'std::string_view')
  sym = sym:gsub('^std::basic_ostream$', 'std::ostream')
  sym = sym:gsub('^std::basic_istream$', 'std::istream')
  return sym
end

local function looks_like_cppman_menu(out)
  if not out or #out == 0 then return false end
  for _, l in ipairs(out) do
    if l:find('Please enter the selection:') then return true end
  end
  if out[#out] and out[#out]:match('EOF when reading a line') then return true end
  return false
end

local function cppman_run_raw(key)
  -- modern cppman (no pager)
  return fn.systemlist({ 'cppman', '-c', '--raw', key })
end

local function cppman_run_cat(key)
  -- older cppman; disable pager
  return fn.systemlist({ 'env', 'PAGER=cat', 'MANWIDTH=120', 'cppman', key })
end

local function cppman_run_pick_first(key)
  -- force-select the first candidate from an interactive menu
  local cmd = string.format("printf '1\n' | PAGER=cat MANWIDTH=120 cppman %q", key)
  return fn.systemlist({ 'sh', '-c', cmd })
end

local function cppman_fetch_one(key)
  local out = cppman_run_raw(key)
  if vim.v.shell_error == 0 and out and #out > 0 and not out[1]:match('^No manual entry') then
    if looks_like_cppman_menu(out) then
      out = cppman_run_pick_first(key)
    end
    return out
  end
  out = cppman_run_cat(key)
  if vim.v.shell_error == 0 and out and #out > 0 and not out[1]:match('^No manual entry') then
    if looks_like_cppman_menu(out) then
      out = cppman_run_pick_first(key)
    end
    return out
  end
  return {}
end

local function cppman_fetch(sym, max_lines)
  if fn.executable('cppman') ~= 1 then return {} end
  if not sym or sym == '' then return {} end

  local cand = {}
  sym = canonicalize(sym)
  cand[#cand+1] = sym

  local base = sym:match('^(std::[%w_]+)::[%w_]+$')
  if base then cand[#cand+1] = base end

  for _, key in ipairs(cand) do
    local out = cppman_fetch_one(key)
    if #out > 0 then
      if max_lines and #out > max_lines then
        local clip = {}
        for i = 1, max_lines do clip[i] = out[i] end
        clip[#clip+1] = ''
        clip[#clip+1] = ('… clipped (%d more lines). Press gK for full page.'):format(#out - max_lines)
        return clip
      end
      return out
    end
  end
  return {}
end

local function combine_markdown(clangd_md, cpp_md, sym)
  local lines = {}
  if #clangd_md > 0 then
    lines[#lines+1] = M.config.header_clangd
    lines[#lines+1] = ''
    vim.list_extend(lines, clangd_md)
    lines[#lines+1] = ''
  end
  if cpp_md and #cpp_md > 0 then
    lines[#lines+1] = M.config.header_cppman .. (sym and (' — ' .. sym) or '')
    lines[#lines+1] = ''
    lines[#lines+1] = '```'
    vim.list_extend(lines, cpp_md)
    lines[#lines+1] = '```'
  end
  if #lines == 0 then lines = { '_no hover content_' } end
  return trim_empty(lines)
end

local function open_focusable(lines)
  if M._state.win and api.nvim_win_is_valid(M._state.win) then
    api.nvim_set_current_win(M._state.win)
    return M._state.buf, M._state.win
  end
  local buf, win = util.open_floating_preview(lines, 'markdown', { border = M.config.border })
  M._state.buf, M._state.win = buf, win
  api.nvim_create_autocmd('WinClosed', {
    once = true,
    callback = function(ev)
      local w = tonumber(ev.match)
      if w == win then M._state.win, M._state.buf = nil, nil end
    end,
  })
  return buf, win
end

-- ---------- public API -----------------------------------------------------

function M.hover_combined(posenc)
  local enc = posenc or encoding_for(0)
  local params = util.make_position_params(0, enc)
  local sym = under_cursor()

  vim.lsp.buf_request(0, 'textDocument/hover', params, function(_, result)
    local clangd_md = convert_hover(result)
    local key = canonicalize(derive_cpp_key(clangd_md) or sym)
    local cpp_md = cppman_fetch(key, M.config.cppman_max_lines)
    open_focusable(combine_markdown(clangd_md, cpp_md, key))
  end)
end

function M.cppman_only()
  local key = canonicalize(under_cursor())
  local out = cppman_fetch(key, nil)
  if #out == 0 then return end
  open_focusable({ M.config.header_cppman .. ' — ' .. key, '', '```', unpack(out), '```' })
end

function M.attach(client, bufnr)
  local enc = client.offset_encoding or encoding_for(bufnr)
  local map = function(lhs, rhs) vim.keymap.set('n', lhs, rhs, { buffer = bufnr, silent = true }) end
  map('K', function() M.hover_combined(enc) end) -- clangd + cppman; K refocuses
  map('gK', M.cppman_only)                       -- full cppman page
end

return M

