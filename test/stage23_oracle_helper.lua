-- Oracle tès ki kalkile 1..46 gout san manyen kontra 46-gout normatif la.
-- Referans la sèvi ak O.SAVE ak O.bowlOrderFromDrop, pa kòd production.
local B=require("bigint")
local O=require("normative_oracle")
local Helper={}
local names={"w","b","s","m","r","w"}
local keys={w=1,b=2,s=3,m=4,r=5}
local factors={3,5,7}
local function stone(row,name)
    assert(type(row)=="table","Ranje wòch manke")
    return B.from(assert(row[name] or row[keys[name]],"Wòch manke"))
end
function Helper.apply(initial,drops,rows)
    assert(type(drops)=="table" and #drops>=1 and #drops<=46)
    local current={}
    for id=1,6 do current[id]=B.from(assert(initial[id],"Bòl manke")) end
    for i=1,#drops do
        local drop=B.from(assert(drops[i],"Gout manke"))
        local old={}
        for id=1,6 do old[id]=B.from(current[id]) end
        local order=O.bowlOrderFromDrop(drop)
        local pours={}
        for p=1,3 do
            pours[p]=O.SAVE(drop*drop+stone(rows[i],names[p])*old[order[p]]+B.from(i*factors[p]))
        end
        local nextBowls={}
        for p=1,6 do
            local id=order[p]
            local prev=order[(p+4)%6+1]
            local nxt=order[p%6+1]
            local sum=old[id]+B.from(2)*old[prev]+B.from(3)*old[nxt]
                +(p<=3 and pours[p] or B.from(0))+drop+stone(rows[i],names[p])
            nextBowls[id]=O.SAVE(sum*sum+B.from(5)*old[prev]*old[nxt]+B.from(i*p))
        end
        current=nextBowls
    end
    return current
end
return Helper
