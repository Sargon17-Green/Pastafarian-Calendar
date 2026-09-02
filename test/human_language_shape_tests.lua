local root=arg[1] or "."
local proseFiles={
  "README.md","SOURCE_LANGUAGE_CATALOG.md","SPAGHETTI_DEVELOPMENT_HISTORY.md","HANDOFF_STAGE_01.md","DEVELOPMENT_STAGE.md"
}
local function hasHebrew(text)
  for _,cp in utf8.codes(text) do
    if cp>=0x0590 and cp<=0x05FF then return true end
  end
  return false
end
for _,name in ipairs(proseFiles) do
  local f=assert(io.open(root.."/"..name,"r")); local text=f:read("*a"); f:close()
  if name=="DEVELOPMENT_STAGE.md" then
    text=text:gsub("NATURAL_LANGUAGE=קריאולית האיטית","NATURAL_LANGUAGE=KREYOL_AYISYEN_MACHINE_LABEL")
  end
  assert(not hasHebrew(text),"Gen tèks ebre ki pa etikèt machin obligatwa nan "..name)
end
print("PASS fòm lang tèks imen")
