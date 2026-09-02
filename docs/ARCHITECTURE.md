# 第 1 階段架構

生產樹目前只有中立骨架。`BaseContext` 擁有單次呼叫的輸入與尚未形成的語意狀態；`BaseDispatcher` 只提供階段分派能力；`BaseValidator` 只做不帶未來修補知識的基本驗證；`BaseErrorBoundary` 統一包住失敗；`BaseMetrics` 只保存不可回讀到曆法決策的觀測計數。

規範參考位於 `t/lib`，只供測試使用。生產模組不得載入它。第 1 階段不建立任何未來 legacy 路徑，也不建立對 01–26 號修補的預留旗標。
