class CatalogEntry
  let canonical_index: USize
  let text: String

  new create(canonical_index': USize, text': String) =>
    canonical_index = canonical_index'
    text = text'

primitive SourceLanguageCatalog
  fun version(): USize => 1

  fun cutlets(): Array[CatalogEntry] =>
    [
      CatalogEntry(1, "สัมฤทธิ์")
      CatalogEntry(2, "สุนัขจิ้งจอก")
      CatalogEntry(3, "ไต")
      CatalogEntry(4, "ลากาช")
      CatalogEntry(5, "ความคิด")
      CatalogEntry(6, "สี่ส่วนเก้า")
      CatalogEntry(7, "พัลกูรัช")
      CatalogEntry(8, "ต้นกก")
      CatalogEntry(9, "พวง")
      CatalogEntry(10, "แมงป่อง")
      CatalogEntry(11, "เถ้า")
      CatalogEntry(12, "ข้าวสาลี")
      CatalogEntry(13, "แม่น้ำ")
      CatalogEntry(14, "เสียงหัวเราะ")
      CatalogEntry(15, "อัคคัด")
      CatalogEntry(16, "เขา")
      CatalogEntry(17, "เหยือกเปล่า")
    ]

  fun months(): Array[CatalogEntry] =>
    [
      CatalogEntry(1, "ดินเหนียว")
      CatalogEntry(2, "ทับทิม")
      CatalogEntry(3, "ข้อศอก")
      CatalogEntry(4, "ความอิจฉา")
      CatalogEntry(5, "เอริดู")
      CatalogEntry(6, "ยาสีฟัน")
      CatalogEntry(7, "สามส่วนห้า")
      CatalogEntry(8, "คาร์ชูมาฟ")
      CatalogEntry(9, "เสือ")
      CatalogEntry(10, "ดีบุก")
      CatalogEntry(11, "หมอก")
      CatalogEntry(12, "กำยาน")
      CatalogEntry(13, "แกนปั่นด้าย")
      CatalogEntry(14, "ซี่โครง")
      CatalogEntry(15, "คารอบ")
      CatalogEntry(16, "อูรุก")
      CatalogEntry(17, "ความละอาย")
      CatalogEntry(18, "อูฐ")
      CatalogEntry(19, "ทองแดง")
      CatalogEntry(20, "บ่อน้ำ")
      CatalogEntry(21, "ไข่แดง")
      CatalogEntry(22, "ดาว")
      CatalogEntry(23, "น้ำผึ้ง")
      CatalogEntry(24, "ม้าม")
      CatalogEntry(25, "หินปูน")
      CatalogEntry(26, "ความยินดี")
      CatalogEntry(27, "มะเดื่อ")
      CatalogEntry(28, "นีนะเวห์")
      CatalogEntry(29, "กบ")
      CatalogEntry(30, "น้ำมันดิน")
      CatalogEntry(31, "เทียน")
      CatalogEntry(32, "ประตูที่ปิดอยู่")
      CatalogEntry(33, "งา")
      CatalogEntry(34, "ท้ายทอย")
      CatalogEntry(35, "เงิน")
      CatalogEntry(36, "ดอกลิลลี่")
      CatalogEntry(37, "พายุ")
      CatalogEntry(38, "ลา")
      CatalogEntry(39, "แป้ง")
      CatalogEntry(40, "ความเสียใจ")
      CatalogEntry(41, "บาบิโลน")
      CatalogEntry(42, "ลิ้น")
      CatalogEntry(43, "ป่านลินิน")
      CatalogEntry(44, "เกลือ")
      CatalogEntry(45, "ลูกแพร์")
      CatalogEntry(46, "คันธนู")
      CatalogEntry(47, "ทราย")
    ]

  fun cutlet_text(index: USize): String ? =>
    if (index < 1) or (index > 17) then error end
    cutlets()(index - 1)?.text

  fun month_text(index: USize): String ? =>
    if (index < 1) or (index > 47) then error end
    months()(index - 1)?.text
