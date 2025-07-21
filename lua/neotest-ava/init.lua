local lib  = require("neotest.lib")
local Path = require("plenary.path")
local Tree = require("neotest.types").Tree

---@type neotest.Adapter
local M = { name = "neotest-ava" }

-- 1. Project root = first dir with package.json / AVA config
M.root = lib.files.match_root_pattern(
  "package.json",
  "ava.config.*",
  ".git"
)

-- 2. Mark test files – *.spec.mjs|js, *.test.mjs|js or anything in __tests__
function M.is_test_file(file)
  return file:match("__tests?/")           -- folders
      or file:match("[_.]spec%.mjs?$")     -- foo.spec.mjs / js
      or file:match("[_.]test%.mjs?$")     -- foo.test.mjs / js
end

-- 3. Return a tree with a single “file-level” position
---@async
function M.discover_positions(path)
  local lines = lib.files.read_lines(path)
  if #lines == 0 then return end

  local file_node = {
    id    = path,
    type  = "file",
    name  = Path:new(path):make_relative(M.root(vim.fn.fnamemodify(path, ":p"))),
    path  = path,
    range = { 0, 0, #lines, 0 },
  }

  -- Treat the whole file as one logical test
  local test_node = vim.tbl_extend("force", file_node, {
    id   = path .. "::all",
    type = "test",
    name = "[file] " .. Path:new(path):make_relative(),
  })

  return Tree.from_list({ file_node, test_node }, function(pos) return pos.id end)
end

-- 4. Build the shell command
---@async
function M.build_spec(args)
  local pos = args.tree:data()
  local rel = pos.path
  if M.root(rel) then
    rel = Path:new(pos.path):make_relative(M.root(pos.path))
  end
  return {
    command = "npx ava " .. rel, -- trust local dev-dependency per AVA ≥ 4 recommendations
    context = { pos_id = pos.id },
  }
end

-- 5. A zero exit code = success
---@async
function M.results(spec, result)
  return {
    [spec.context.pos_id] = {
      status = result.code == 0 and "passed" or "failed",
      output = result.output,
    },
  }
end

-- Allow `require("neotest-ava")({})`
setmetatable(M, {
  __call = function(_, opts) return M end,
})

return M

