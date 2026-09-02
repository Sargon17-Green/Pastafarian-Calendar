use "../../src"
use "../../oracle"

actor Main
  new create(env: Env) =>
    try
      let f = NormativeConstants.foundation_day()
      let r = NormativeSauce(f, f)?
      env.out.print("จุดตรึง=" + f.string())
      var i: USize = 0
      while i < r.bowls.size() do
        env.out.print("ชาม" + (i + 1).string() + "=" + r.bowls(i)?.string())
        i = i + 1
      end
      let order = String
      i = 0
      while i < r.order_at_drop_46.size() do
        if i > 0 then order.push(44) end
        order.append(r.order_at_drop_46(i)?.string())
        i = i + 1
      end
      env.out.print("ลำดับหยด46=" + order)
    else
      env.err.print("การสร้างฟิกซ์เจอร์ล้มเหลว")
      env.exitcode(1)
    end
