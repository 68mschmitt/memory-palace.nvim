-- lua/note_town_mvp.lua
-- Minimal, dependency‑free Neovim module implementing two commands:
--   :NewNote      → capture text and create a new note in the inbox (or pick destination)
--   :PromoteNote  → move current note from inbox to chosen Island/Camp/Tent and update frontmatter
--
-- Drop this file into ~/.config/nvim/lua/note_town_mvp.lua and add to your config:
--   require('note_town_mvp').setup({
--     base_dir  = '~/notes',
--     inbox_dir = '~/notes/TutorialIsland/tutorial-pen',
--   })
--
-- MVP design notes:
-- - Capture order: heading section under cursor → visual selection → whole buffer
-- - Inbox filenames: YYYY-MM-DD_HH-MM-SS--slug.md
-- - Minimal frontmatter written on NewNote; PromoteNote just updates taxonomy + updated timestamp

local M = {}

-- ============================= Config ======================================
M.config = {
    base_dir       = vim.fn.expand('~/notes'),
    inbox_dir      = vim.fn.expand('~/notes/TutorialIsland/tutorial-pen'),
    status_default = 'seed',
}

-- ============================= Utils =======================================
local function ensure_dir(dir)
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, 'p')
    end
end

local function join(a, b)
    if a:sub(-1) == '/' then return a .. b end
    return a .. '/' .. b
end

local function now_iso()
    -- UTC ISO8601
    return os.date('!%Y-%m-%dT%H:%M:%SZ')
end

local function now_stamp()
    return os.date('%Y-%m-%d_%H-%M-%S')
end

local function slugify(s)
    s = s or 'note'
    s = s:gsub('[\t\n\r]', ' '):gsub('^%s+', ''):gsub('%s+$', ''):lower()
    s = s:gsub("[^a-z0-9%-%s]", ''):gsub('%s+', '-')
    if s == '' then s = 'note' end
    return s
end

local function split_lines(s)
    local t = {}
    for line in (s .. '\n'):gmatch('(.-)\n') do table.insert(t, line) end
    return t
end

local function read_buf_lines()
    return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

local function write_file(path, content)
    ensure_dir(vim.fn.fnamemodify(path, ':h'))
    vim.fn.writefile(split_lines(content), path)
end

local function file_exists(path)
    return vim.fn.filereadable(path) == 1
end

local function unique_path(dir, base)
    local candidate = join(dir, base)
    if not file_exists(candidate) then return candidate end
    local i = 2
    local name = base:gsub('%.md$', '')
    while true do
        local p = join(dir, string.format('%s--%d.md', name, i))
        if not file_exists(p) then return p end
        i = i + 1
    end
end

-- ======================= Capture (heading/visual/buffer) ====================
local function parse_heading_section(lines, cur)
    local line = lines[cur]
    if not line then return nil end
    local head = line:match('^(#+)%s')
    if not head then
        for i = cur, 1, -1 do
            local h = lines[i]:match('^(#+)%s')
            if h then
                cur = i; head = h; break
            end
        end
        if not head then return nil end
    end
    local level = #head
    local s = cur
    local e = #lines
    for i = cur + 1, #lines do
        local h = lines[i]:match('^(#+)%s')
        if h and #h <= level then
            e = i - 1; break
        end
    end
    return s, e
end

local function get_visual_selection()
    local srow, scol = unpack(vim.api.nvim_buf_get_mark(0, '<'))
    local erow, ecol = unpack(vim.api.nvim_buf_get_mark(0, '>'))
    if srow == 0 then return nil end
    local lines = vim.api.nvim_buf_get_lines(0, srow - 1, erow, false)
    if #lines == 0 then return nil end
    lines[#lines] = string.sub(lines[#lines], 1, ecol)
    lines[1] = string.sub(lines[1], scol + 1)
    return table.concat(lines, '\n')
end

local function capture_text()
    local lines = read_buf_lines()
    -- heading under cursor
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local s, e = parse_heading_section(lines, row)
    if s then
        local section_lines = vim.list_slice(lines, s, e)
        local section = table.concat(section_lines, '\n')
        local title = (section_lines[1] or ''):gsub('^#+%s*', ''):gsub('%s*$', '')
        return section, title
    end
    -- visual selection
    local sel = get_visual_selection()
    if sel and #sel > 0 then
        local first = sel:match('^([^\n]+)') or 'New Note'
        return sel, first
    end
    -- buffer fallback
    local buftext = table.concat(lines, '\n')
    local first = (lines[1] or 'New Note')
    return buftext, first
end

-- ============================= Frontmatter ==================================
local function render_frontmatter(meta)
    local function arr(a)
        local t = {}
        for _, v in ipairs(a or {}) do table.insert(t, '- ' .. v) end
        return table.concat(t, '\n')
    end
    local out = {
        '---',
        'id: ' .. meta.id,
        'title: ' .. string.format('%q', meta.title or ''),
        'slug: ' .. meta.slug,
        'created: ' .. meta.created,
        'updated: ' .. meta.updated,
        'domain: ' .. (meta.domain or 'tutorial-island'),
        'category: ' .. (meta.category or 'tutorial-pen'),
        'topic: ' .. (meta.topic or 'unsorted'),
        'status: ' .. (meta.status or M.config.status_default),
        'tags:', arr(meta.tags or { 'unsorted', 'newbie' }),
        'links:', arr(meta.links or {}),
        'refs:', arr(meta.refs or {}),
        '---',
        ''
    }
    return table.concat(out, '\n')
end

local function parse_frontmatter(lines)
    if lines[1] ~= '---' then return nil end
    local e
    for i = 2, #lines do
        if lines[i] == '---' then
            e = i; break
        end
    end
    if not e then return nil end
    return 1, e
end

local function update_taxonomy_in_buffer(domain, category, topic)
    local bufnr = 0
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local s, e = parse_frontmatter(lines)
    if not s then return false end
    for i = s, e do
        if lines[i]:match('^domain:%s') then lines[i] = 'domain: ' .. domain end
        if lines[i]:match('^category:%s') then lines[i] = 'category: ' .. category end
        if lines[i]:match('^topic:%s') then lines[i] = 'topic: ' .. topic end
        if lines[i]:match('^updated:%s') then lines[i] = 'updated: ' .. now_iso() end
        if lines[i]:match('^tags:%s*$') then
            -- replace following list with the new trio
            local j = i + 1
            while j <= e and lines[j]:match('^%- ') do
                table.remove(lines, j); e = e - 1
            end
            table.insert(lines, i + 1, '- ' .. domain)
            table.insert(lines, i + 2, '- ' .. category)
            table.insert(lines, i + 3, '- ' .. topic)
        end
    end
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    return true
end

-- ============================= UI Helpers ===================================
local function ui_select(prompt, items, cb)
    vim.ui.select(items, { prompt = prompt .. ': ' }, cb)
end

local function ui_input(prompt, default, cb)
    vim.ui.input({ prompt = prompt .. ': ', default = default }, cb)
end

-- ============================= Core: NewNote ================================
local function infer_title(raw_title)
    local t = raw_title or 'New Note'
    t = t:gsub('^#+%s*', '')
    if t == '' then t = 'New Note' end
    return t
end

function M.new_note()
    ensure_dir(M.config.inbox_dir)

    local body, raw_title = capture_text()
    local title = infer_title(raw_title)
    local slug = slugify(title)

    local main_menu = {
        'Drop in Inbox',
        'Choose Island',
        'Create new Island',
    }

    ui_select('NewNote', main_menu, function(choice)
        if not choice then return end

        local function write_note_at(dir, domain, category, topic)
            ensure_dir(dir)
            local fname = string.format('%s--%s.md', now_stamp(), slug)
            local path = unique_path(dir, fname)
            local meta = {
                id = string.format('NT-%s-%06d', os.date('%y%m%d%H%M%S'), math.random(0, 999999)),
                title = title,
                slug = slug,
                created = now_iso(),
                updated = now_iso(),
                domain = domain,
                category = category,
                topic = topic,
                status = M.config.status_default,
                tags = { (domain or 'tutorial-island'), (category or 'tutorial-pen'), (topic or 'unsorted') },
                links = {},
                refs = {},
            }
            local content = render_frontmatter(meta) .. body .. '\n'
            write_file(path, content)
            vim.cmd.edit(path)
            vim.notify('NewNote → ' .. path, vim.log.levels.INFO)
        end

        if choice == 'Drop in Inbox' then
            write_note_at(M.config.inbox_dir, 'tutorial-island', 'tutorial-pen', 'unsorted')
            return
        end

        local function continue_with_island(island)
            if not island or island == '' then return end
            ui_input('Camp', '', function(camp)
                if not camp or camp == '' then return end
                ui_input('Tent', slug, function(tent)
                    if not tent or tent == '' then return end
                    write_note_at(join(M.config.base_dir, island .. '/' .. camp .. '/' .. tent), island, camp, tent)
                end)
            end)
        end

        if choice == 'Choose Island' then
            ui_input('Island', '', function(island) continue_with_island(island) end)
            return
        end

        if choice == 'Create new Island' then
            ui_input('New Island name', '', function(island) continue_with_island(island) end)
            return
        end
    end)
end

-- =========================== Core: PromoteNote ==============================
function M.promote_note()
    local cur = vim.api.nvim_buf_get_name(0)
    if cur == '' or not cur:match('%.md$') then
        vim.notify('PromoteNote: current buffer is not a markdown file', vim.log.levels.WARN)
        return
    end

    ui_input('Island', '', function(island)
        if not island or island == '' then return end
        ui_input('Camp', '', function(camp)
            if not camp or camp == '' then return end
            local default_tent = vim.fn.fnamemodify(cur, ':t:r'):gsub('^%d%d%d%d%-%d%d%-%d%d_%d%d%-%d%d%-%d%d%-%-', '')
            ui_input('Tent', default_tent, function(tent)
                if not tent or tent == '' then return end

                local dest_dir = join(M.config.base_dir, island .. '/' .. camp .. '/' .. tent)
                ensure_dir(dest_dir)

                local fname = vim.fn.fnamemodify(cur, ':t')
                local dest = unique_path(dest_dir, fname)

                -- Update taxonomy & updated timestamp in buffer first
                update_taxonomy_in_buffer(island, camp, tent)
                vim.cmd.write() -- save changes

                -- Move file and reload buffer
                vim.fn.rename(cur, dest)
                vim.cmd.edit(dest)
                vim.notify(string.format('Promoted → %s/%s/%s', island, camp, tent), vim.log.levels.INFO)
            end)
        end)
    end)
end

-- ============================== Setup =======================================
function M.setup(opts)
    M.config = vim.tbl_deep_extend('force', M.config, opts or {})
    ensure_dir(M.config.inbox_dir)

    vim.api.nvim_create_user_command('NewNote', function() M.new_note() end,
        { desc = 'Create a new note (inbox or pick destination)' })
    vim.api.nvim_create_user_command('PromoteNote', function() M.promote_note() end,
        { desc = 'Promote current note from inbox to Island/Camp/Tent' })

    -- Sensible defaults; override in your config
    vim.keymap.set('n', '<leader>nn', M.new_note, { desc = 'NewNote (Note‑Town MVP)' })
    vim.keymap.set('n', '<leader>np', M.promote_note, { desc = 'PromoteNote (Note‑Town MVP)' })
end

return M
