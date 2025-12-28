local BASE = "https://raw.githubusercontent.com/Guilhermewash/Cust/tree/main/Custom_Broly/"
local HTTP = modules.corelib.HTTP

if not HTTP or not HTTP.get then
  warn("[Custom] HTTP não disponível")
  return
end

-- baixa o loader principal
HTTP.get(BASE .. "loader.lua", function(code, err)
  if err or not code then
    warn("[Custom] Falha ao baixar loader")
    return
  end

  local fn, loadErr = loadstring(code)
  if not fn then
    warn("[Custom] Erro no loader: " .. tostring(loadErr))
    return
  end

  fn()
end)