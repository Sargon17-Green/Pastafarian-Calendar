Attribute VB_Name = "PastafarianExcel"
Option Explicit

' Excel-VBA / Inuktitut branch. This Stage 1 host does NOT compute F(c,t).
' B11:B15 are externally verified canonical values, not computed outputs.
' No other implementation, service, network access or unsafe evaluation is used.

Private Const CalendarSheet As String = "Calendar"

Public Sub InitializePastafarianSheet()
    Dim sh As Worksheet
    On Error Resume Next
    Set sh = ThisWorkbook.Worksheets(CalendarSheet)
    On Error GoTo 0
    If sh Is Nothing Then
        Set sh = ThisWorkbook.Worksheets.Add(After:=ThisWorkbook.Sheets(ThisWorkbook.Sheets.Count))
        sh.Name = CalendarSheet
    End If

    With sh
        .Range("A1").Value2 = "PASTAFARIAN CALENDAR | Stage 1 input/display"
        .Range("A2").Value2 = "NOT A DATE CONVERTER: canonical computation not implemented."
        .Range("A5").Value2 = "Calculation day count (signed decimal text)"
        .Range("A6").Value2 = "Target day count (signed decimal text)"
        .Range("A10").Value2 = "Five externally computed canonical components:"
        .Range("A11").Value2 = "year"
        .Range("A12").Value2 = "cutletName"
        .Range("A13").Value2 = "dayInCutlet"
        .Range("A14").Value2 = "monthName"
        .Range("A15").Value2 = "dayInMonth"
        .Range("D5").Value2 = "Display only (not calculated)"
        .Range("B5:B6").NumberFormat = "@"
        .Range("B11:B15").NumberFormat = "@"
        .Range("E5").NumberFormat = "@"
        .Columns("A").ColumnWidth = 44
        .Columns("B").ColumnWidth = 34
        .Columns("D").ColumnWidth = 30
        .Columns("E").ColumnWidth = 52
        .Range("A1:E1").Font.Bold = True
        .Range("A10:B10").Font.Bold = True
        .Range("A11:A15").Font.Bold = True
    End With
End Sub

Public Sub RenderPastafarianDate()
    Dim sh As Worksheet
    Set sh = ThisWorkbook.Worksheets(CalendarSheet)

    Dim y As String, cutlet As String, dayCutlet As String
    Dim month As String, dayMonth As String
    y = ExactCellString(sh.Range("B11"))
    cutlet = Trim$(ExactCellString(sh.Range("B12")))
    dayCutlet = ExactCellString(sh.Range("B13"))
    month = Trim$(ExactCellString(sh.Range("B14")))
    dayMonth = ExactCellString(sh.Range("B15"))

    If Not ValidDecimal(y, False) Then Err.Raise vbObjectError + 514, , "Invalid year: exact decimal TEXT is required."
    If Len(cutlet) = 0 Then Err.Raise vbObjectError + 515, , "cutletName is empty."
    If Not ValidDecimal(dayCutlet, True) Then Err.Raise vbObjectError + 516, , "Invalid dayInCutlet."
    If Len(month) = 0 Then Err.Raise vbObjectError + 517, , "monthName is empty."
    If Not ValidDecimal(dayMonth, True) Then Err.Raise vbObjectError + 518, , "Invalid dayInMonth."

    ' Presentation only. The five source values are not recalculated or renamed.
    sh.Range("E5").NumberFormat = "@"
    sh.Range("E5").Value2 = y & " | " & cutlet & " " & dayCutlet & " | " & month & " " & dayMonth
End Sub

Public Sub CalculatePastafarianDate()
    Err.Raise vbObjectError + 513, "PastafarianExcel", _
        "CANONICAL ENGINE NOT IMPLEMENTED. Do not use Stage 1 as a converter."
End Sub

Private Function ExactCellString(ByVal cell As Range) As String
    If VarType(cell.Value2) <> vbString Then
        Err.Raise vbObjectError + 519, , _
            "Input " & cell.Address(False, False) & " must be stored as TEXT to avoid Excel precision loss."
    End If
    ExactCellString = Trim$(CStr(cell.Value2))
End Function

Private Function ValidDecimal(ByVal raw As String, ByVal positive As Boolean) As Boolean
    Dim i As Long, firstDigit As Long, ch As String, hasNonzero As Boolean
    raw = Trim$(raw)
    firstDigit = 1
    If Len(raw) = 0 Then Exit Function
    If Left$(raw, 1) = "-" Then
        If positive Or Len(raw) = 1 Then Exit Function
        firstDigit = 2
    End If
    For i = firstDigit To Len(raw)
        ch = Mid$(raw, i, 1)
        If ch < "0" Or ch > "9" Then Exit Function
        If ch <> "0" Then hasNonzero = True
    Next i
    If positive And Not hasNonzero Then Exit Function
    ValidDecimal = True
End Function
