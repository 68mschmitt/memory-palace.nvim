local M = {}

function M.substitute_variables(template, variables)
    local result = template

    for key, value in pairs(variables) do
        local pattern = "{{" .. key .. "}}"
        result = result:gsub(vim.pesc(pattern), value)
    end

    return result
end

function M.get_template_variables(label, timestamp)
    local title = label or "Note"
    local date = os.date("%Y-%m-%d")
    local datetime = os.date("%Y-%m-%d %H:%M:%S")

    return {
        title = title,
        date = date,
        datetime = datetime,
        timestamp = timestamp or os.date("%Y-%m-%d_%H-%M-%S"),
    }
end

return M
