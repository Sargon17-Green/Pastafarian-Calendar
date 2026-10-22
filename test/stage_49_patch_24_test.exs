defmodule PastafariCalendarElixirVietnamese.Stage49Patch24Test do
  use ExUnit.Case, async: true
  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager, AscendingMonthCountPatch, MonthCountManager,
    LegacyDescendingMonthCount, CutletMaterializationManager
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref
  @foundation -15_055_671

  defp reference(c,t) do
    {year,_state}=Ref.find_target_year(c,t)
    Ref.choose_month_count(Ref.sauce(c,year.open_gate_day+1),year)
  end

  test "số tháng chuẩn khớp oracle quanh ngày nền" do
    for delta <- [-3,-1,0,1,3] do c=@foundation+delta; assert Calendar.month_count_spaghetti(c,c)==reference(c,c) end
  end

  test "số tháng đúng trong quá khứ" do
    for delta <- [-721,-539,-417,-101,-17] do c=@foundation+delta; assert Calendar.month_count_spaghetti(c,c)==reference(c,c) end
  end

  test "số tháng đúng trong tương lai" do
    for delta <- [17,71,101,417,721,1031] do c=@foundation+delta; assert Calendar.month_count_spaghetti(c,c)==reference(c,c) end
  end

  test "số tháng ở ngày cổng đóng" do
    for delta <- [-539,0,1,417] do c=@foundation+delta; t=Calendar.year5000_spaghetti(c).close_gate_day; assert Calendar.month_count_spaghetti(c,t)==reference(c,t) end
  end

  test "di sản thật vẫn trả thứ tự đảo" do
    r=MonthCountManager.diagnose(@foundation,@foundation); assert r.historical_order==LegacyDescendingMonthCount.sort(r.candidates)
  end

  test "bản vá chuyển về thứ tự tăng" do
    r=MonthCountManager.diagnose(@foundation,@foundation); assert r.corrected_order==Enum.sort(r.candidates)
  end

  test "bản vá ghi nhận lựa chọn lịch sử" do
    r=MonthCountManager.diagnose(@foundation,@foundation); assert r.historical_month_count==Enum.at(r.historical_order,r.rank-1)
  end

  test "rank không thay đổi với bản vá" do
    r=MonthCountManager.diagnose(@foundation,@foundation); stream=Calendar.answer_stream_spaghetti(@foundation,r.structure_source_day,3,30); assert r.rank==AnswerStreamManager.choose_rank(stream,r.candidate_count)
  end

  test "đầu ra chuẩn sử dụng đúng rank" do
    r=MonthCountManager.diagnose(@foundation,@foundation); assert r.month_count==Enum.at(r.corrected_order,r.rank-1)
  end

  test "miền một ứng viên không thay" do
    r=AscendingMonthCountPatch.diagnose([47],1); assert r.corrected_count==47 and r.historical_count==47
  end

  test "các ứng viên không bị mất" do
    r=MonthCountManager.diagnose(@foundation,@foundation); assert Enum.sort(r.historical_order)==r.corrected_order
  end

  test "số tháng có thể chia được ngày năm" do
    r=MonthCountManager.diagnose(@foundation,@foundation); assert r.month_count*4<=r.year_length; assert r.month_count*123>=r.year_length
  end

  test "năm mục tiêu vẫn chính xác" do
    r=MonthCountManager.diagnose(@foundation,@foundation); assert r.year==Calendar.find_target_year_spaghetti(@foundation,@foundation)
  end

  test "cốt-lết không bị thay đổi" do
    c=@foundation+21; r=MonthCountManager.diagnose(c,c); parent=CutletMaterializationManager.diagnose(c,c); assert r.cutlets==parent.cutlets
  end

  test "nguồn ngày không bị thay đổi" do
    r=MonthCountManager.diagnose(@foundation,@foundation); assert r.structure_source_day==r.year.open_gate_day+1
  end

  test "đầu vào rank không hợp lệ bị từ chối" do
    for rank <- [0,-1,5] do assert_raise ArgumentError, fn -> AscendingMonthCountPatch.diagnose([3,4],rank) end end
  end

  test "đầu vào danh sách không hợp lệ bị từ chối" do
    assert_raise ArgumentError, fn -> AscendingMonthCountPatch.diagnose(nil,1) end
  end

  test "truy vấn lặp không khác" do
    c=@foundation+29; assert MonthCountManager.diagnose(c,c)==MonthCountManager.diagnose(c,c)
  end

  test "truy vấn đảo thứ tự ngày vẫn ổn định" do
    days=Enum.map(-3..3,&(@foundation+&1*17)); front=Enum.map(days,&Calendar.month_count_spaghetti(&1,&1)); back=Enum.reverse(days)|>Enum.map(&Calendar.month_count_spaghetti(&1,&1))|>Enum.reverse(); assert front==back
  end

  test "kiểm toán mã nguồn giữ oracle ngoài production" do
    root=Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster",__DIR__); patch=File.read!(Path.join(root,"ascending_month_count_patch.ex")); manager=File.read!(Path.join(root,"month_count_manager.ex")); assert patch=~"LegacyDescendingMonthCount.sort(candidates)"; assert manager=~"AscendingMonthCountPatch.diagnose(candidates, rank)"; refute patch=~"NormativeReference"; refute manager=~"NormativeReference"
  end
end
