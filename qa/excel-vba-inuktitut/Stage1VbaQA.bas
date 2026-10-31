Attribute VB_Name = "Stage1VbaQA"
Option Explicit

' Stage 1: display-host acceptance tests only. This does NOT compute a date.
' Import this module AND PastafarianExcel.bas into a TEMPORARY .xlsm copy.
' Run Debug > Compile VBAProject before calling this macro.
' Output is written to the Stage1_VBA_QA worksheet in the temporary copy.

Public Sub RunStage1VbaSelfTest()
    Dim sh As Worksheet, report As Worksheet
    Dim cases As Variant, caseId As Variant
    Dim i As Long, passed As Long, failed As Long
    Dim failureDetails As String, success As Boolean

    On Error GoTo FatalSetup
    InitializePastafarianSheet
    Set sh = ThisWorkbook.Worksheets("Calendar")
    Set report = GetOrCreateReport()
    report.Cells.Clear
    report.Range("A1").Value2 = "Stage 1 Excel-VBA host self-test (temporary workbook only)"
    report.Range("A2").Value2 = "Result"
    report.Range("A3").Value2 = "Canonical date engine"
    report.Range("B3").Value2 = "NOT IMPLEMENTED (intentional Stage 1 guard)"
    report.Range("A5").Value2 = "Test"
    report.Range("B5").Value2 = "Status"
    report.Range("C5").Value2 = "Detail"

    cases = Array( _
        "initialize", "render_regular", "render_1024_digit_year", _
        "render_unicode_names", "render_negative_year", "render_zero_year", _
        "preserve_input_cells", "reject_numeric_year", _
        "reject_plus_sign_year", "reject_non_ascii_digit_year", "reject_blank_year", _
        "reject_blank_cutlet", "reject_blank_month", _
        "reject_zero_day_in_cutlet", "reject_negative_day_in_cutlet", _
        "reject_nondecimal_day_in_cutlet", "reject_zero_day_in_month", "reject_empty_year_cell", _
        "reject_empty_cutlet_cell", "reject_empty_month_cell", _
        "reject_empty_day_in_cutlet_cell", "reject_empty_day_in_month_cell", _
        "reject_numeric_day_in_cutlet", "reject_numeric_day_in_month", _
        "reject_negative_day_in_month", "reject_nondecimal_day_in_month", _
        "reject_numeric_cutlet_name", "reject_numeric_month_name", _
        "reject_formula_year", "reject_formula_cutlet", _
        "reject_formula_day_cutlet", "reject_formula_month", _
        "reject_formula_day_month", "clear_stale_after_invalid_input", _
        "canonical_engine_guard")

    passed = 0
    failed = 0
    For i = LBound(cases) To UBound(cases)
        caseId = cases(i)
        failureDetails = vbNullString
        success = RunCaseAndCapture(CStr(caseId), sh, failureDetails)
        report.Cells(i + 6, 1).Value2 = CStr(caseId)
        If success Then
            report.Cells(i + 6, 2).Value2 = "PASS"
            passed = passed + 1
        Else
            report.Cells(i + 6, 2).Value2 = "FAIL"
            report.Cells(i + 6, 3).Value2 = failureDetails
            failed = failed + 1
        End If
    Next i

    report.Range("B2").Value2 = "PASS=" & CStr(passed) & "/" & CStr(UBound(cases) + 1) & "; FAIL=" & CStr(failed)
    report.Range("A1:C1").Font.Bold = True
    report.Range("A5:C5").Font.Bold = True
    report.Columns("A").ColumnWidth = 38
    report.Columns("B").ColumnWidth = 23
    report.Columns("C").ColumnWidth = 95
    report.Columns("C").WrapText = True
    report.Activate
    Debug.Print "Stage1VbaSelfTest: PASS=" & CStr(passed) & "/" & CStr(UBound(cases) + 1) & " FAIL=" & CStr(failed)
    MsgBox "VBA Stage 1: " & report.Range("B2").Value2 & vbCrLf & _
           "Review Stage1_VBA_QA sheet. Canonical engine remains NOT IMPLEMENTED.", _
           vbInformation, "Stage 1 VBA QA"
    Exit Sub
FatalSetup:
    MsgBox "Cannot run Stage 1 VBA QA. Error " & CStr(Err.Number) & ": " & Err.Description, vbCritical
End Sub

Private Function GetOrCreateReport() As Worksheet
    Dim ws As Worksheet
    On Error Resume Next
    Set ws = ThisWorkbook.Worksheets("Stage1_VBA_QA")
    On Error GoTo 0
    If ws Is Nothing Then
        Set ws = ThisWorkbook.Worksheets.Add(After:=ThisWorkbook.Sheets(ThisWorkbook.Sheets.Count))
        ws.Name = "Stage1_VBA_QA"
    End If
    Set GetOrCreateReport = ws
End Function

Private Function RunCaseAndCapture(ByVal testName As String, _
                                    ByVal sh As Worksheet, _
                                    ByRef why As String) As Boolean
    On Error GoTo Failed
    ExecuteCase testName, sh
    RunCaseAndCapture = True
    Exit Function
Failed:
    why = "VBA error " & CStr(Err.Number) & ": " & Err.Description
    RunCaseAndCapture = False
End Function

Private Sub PrepareValidInputs(ByVal sh As Worksheet)
    sh.Range("B11:B15").NumberFormat = "@"
    sh.Range("B11").Value2 = "2026"
    sh.Range("B12").Value2 = "cutlet"
    sh.Range("B13").Value2 = "3"
    sh.Range("B14").Value2 = "month"
    sh.Range("B15").Value2 = "5"
End Sub

Private Sub AssertExact(ByVal actual As String, ByVal expected As String, _
                        ByVal testName As String)
    If StrComp(actual, expected, vbBinaryCompare) <> 0 Then
        Err.Raise vbObjectError + 920, "Stage1VbaQA", _
            testName & ": expected_length=" & CStr(Len(expected)) & _
            "; actual_length=" & CStr(Len(actual)) & _
            "; data mismatch"
    End If
End Sub

Private Sub ExpectRenderError(ByVal expectedCode As Long, ByVal caseName As String)
    Dim observed As Long
    Err.Clear
    On Error Resume Next
    RenderPastafarianDate
    observed = Err.Number
    Err.Clear
    On Error GoTo 0
    If observed <> expectedCode Then
        Err.Raise vbObjectError + 921, "Stage1VbaQA", _
           caseName & ": expected error=" & CStr(expectedCode) & _
           "; actual error=" & CStr(observed)
    End If
End Sub

Private Sub ExpectCanonicalGuard()
    Dim observed As Long
    Err.Clear
    On Error Resume Next
    CalculatePastafarianDate
    observed = Err.Number
    Err.Clear
    On Error GoTo 0
    If observed <> vbObjectError + 513 Then
        Err.Raise vbObjectError + 922, "Stage1VbaQA", _
           "Canonical converter must reject: expected=" & _
           CStr(vbObjectError + 513) & "; observed=" & CStr(observed)
    End If
End Sub

Private Sub ExpectRejectTextFormula(ByVal sh As Worksheet, _
                                    ByVal address As String, _
                                    ByVal textValue As String, _
                                    ByVal caseName As String)
    Dim target As Range
    Set target = sh.Range(address)
    target.NumberFormat = "General"
    target.Formula = "=" & Chr$(34) & textValue & Chr$(34)
    If Not target.HasFormula Then
        Err.Raise vbObjectError + 925, "Stage1VbaQA", _
            caseName & ": unable to install text-returning formula"
    End If
    ExpectRenderError vbObjectError + 519, caseName
End Sub

Private Sub ExecuteCase(ByVal testName As String, ByVal sh As Worksheet)
    Dim longYear As String, cutletUnicode As String, monthUnicode As String
    Dim savedValues(1 To 5) As String, j As Long
    Dim expected As String
    PrepareValidInputs sh

    Select Case testName
        Case "initialize"
            AssertExact CStr(sh.Range("A2").Value2), _
                "NOT A DATE CONVERTER: canonical computation not implemented.", testName
            If sh.Range("B11:B15").NumberFormat <> "@" Then
                Err.Raise vbObjectError + 923, "Stage1VbaQA", "Expected text cells"
            End If
        Case "render_regular"
            RenderPastafarianDate
            AssertExact CStr(sh.Range("E5").Value2), _
                "2026 | cutlet 3 | month 5", testName
        Case "render_1024_digit_year"
            longYear = String$(1024, "9")
            sh.Range("B11").Value2 = longYear
            RenderPastafarianDate
            AssertExact CStr(sh.Range("E5").Value2), _
                longYear & " | cutlet 3 | month 5", testName
        Case "render_unicode_names"
            cutletUnicode = ChrW$(&H1403) & ChrW$(&H14C4) & ChrW$(&H1450)
            monthUnicode = ChrW$(&H146D) & ChrW$(&H14C2) & ChrW$(&H1455)
            sh.Range("B12").Value2 = cutletUnicode
            sh.Range("B14").Value2 = monthUnicode
            RenderPastafarianDate
            AssertExact CStr(sh.Range("E5").Value2), _
                "2026 | " & cutletUnicode & " 3 | " & monthUnicode & " 5", testName
        Case "render_negative_year"
            sh.Range("B11").Value2 = "-123"
            RenderPastafarianDate
            AssertExact CStr(sh.Range("E5").Value2), "-123 | cutlet 3 | month 5", testName
        Case "render_zero_year"
            sh.Range("B11").Value2 = "0"
            RenderPastafarianDate
            AssertExact CStr(sh.Range("E5").Value2), "0 | cutlet 3 | month 5", testName
        Case "preserve_input_cells"
            For j = 1 To 5
                savedValues(j) = CStr(sh.Cells(10 + j, 2).Value2)
            Next j
            RenderPastafarianDate
            For j = 1 To 5
                AssertExact CStr(sh.Cells(10 + j, 2).Value2), savedValues(j), testName
            Next j
        Case "reject_numeric_year"
            sh.Range("B11").NumberFormat = "General"
            sh.Range("B11").Value2 = CDbl(123)
            ExpectRenderError vbObjectError + 519, testName
        Case "reject_plus_sign_year"
            sh.Range("B11").Value2 = "+15"
            ExpectRenderError vbObjectError + 514, testName
        Case "reject_non_ascii_digit_year"
            sh.Range("B11").Value2 = ChrW$(&H0661)
            ExpectRenderError vbObjectError + 514, testName
        Case "reject_blank_year"
            sh.Range("B11").Value2 = " "
            ExpectRenderError vbObjectError + 514, testName
        Case "reject_blank_cutlet"
            sh.Range("B12").Value2 = " "
            ExpectRenderError vbObjectError + 515, testName
        Case "reject_blank_month"
            sh.Range("B14").Value2 = " "
            ExpectRenderError vbObjectError + 517, testName
        Case "reject_zero_day_in_cutlet"
            sh.Range("B13").Value2 = "0"
            ExpectRenderError vbObjectError + 516, testName
        Case "reject_negative_day_in_cutlet"
            sh.Range("B13").Value2 = "-1"
            ExpectRenderError vbObjectError + 516, testName
        Case "reject_nondecimal_day_in_cutlet"
            sh.Range("B13").Value2 = "1x"
            ExpectRenderError vbObjectError + 516, testName
        Case "reject_zero_day_in_month"
            sh.Range("B15").Value2 = "0"
            ExpectRenderError vbObjectError + 518, testName
        Case "reject_empty_year_cell"
            sh.Range("B11").ClearContents
            ExpectRenderError vbObjectError + 514, testName
        Case "reject_empty_cutlet_cell"
            sh.Range("B12").ClearContents
            ExpectRenderError vbObjectError + 515, testName
        Case "reject_empty_month_cell"
            sh.Range("B14").ClearContents
            ExpectRenderError vbObjectError + 517, testName
        Case "reject_empty_day_in_cutlet_cell"
            sh.Range("B13").ClearContents
            ExpectRenderError vbObjectError + 516, testName
        Case "reject_empty_day_in_month_cell"
            sh.Range("B15").ClearContents
            ExpectRenderError vbObjectError + 518, testName
        Case "reject_numeric_day_in_cutlet"
            sh.Range("B13").NumberFormat = "General"
            sh.Range("B13").Value2 = CDbl(3)
            ExpectRenderError vbObjectError + 519, testName
        Case "reject_numeric_day_in_month"
            sh.Range("B15").NumberFormat = "General"
            sh.Range("B15").Value2 = CDbl(5)
            ExpectRenderError vbObjectError + 519, testName
        Case "reject_negative_day_in_month"
            sh.Range("B15").Value2 = "-1"
            ExpectRenderError vbObjectError + 518, testName
        Case "reject_nondecimal_day_in_month"
            sh.Range("B15").Value2 = "5.0"
            ExpectRenderError vbObjectError + 518, testName
        Case "reject_numeric_cutlet_name"
            sh.Range("B12").NumberFormat = "General"
            sh.Range("B12").Value2 = CDbl(12)
            ExpectRenderError vbObjectError + 519, testName
        Case "reject_numeric_month_name"
            sh.Range("B14").NumberFormat = "General"
            sh.Range("B14").Value2 = CDbl(8)
            ExpectRenderError vbObjectError + 519, testName
        Case "reject_formula_year"
            ExpectRejectTextFormula sh, "B11", "2026", testName
        Case "reject_formula_cutlet"
            ExpectRejectTextFormula sh, "B12", "cutlet", testName
        Case "reject_formula_day_cutlet"
            ExpectRejectTextFormula sh, "B13", "3", testName
        Case "reject_formula_month"
            ExpectRejectTextFormula sh, "B14", "month", testName
        Case "reject_formula_day_month"
            ExpectRejectTextFormula sh, "B15", "5", testName
        Case "clear_stale_after_invalid_input"
            RenderPastafarianDate
            AssertExact CStr(sh.Range("E5").Value2), _
                "2026 | cutlet 3 | month 5", testName
            sh.Range("B13").Value2 = "0"
            ExpectRenderError vbObjectError + 516, testName
            AssertExact CStr(sh.Range("E5").Value2), vbNullString, testName
        Case "canonical_engine_guard"
            ExpectCanonicalGuard
        Case Else
            Err.Raise vbObjectError + 924, "Stage1VbaQA", "Unknown test: " & testName
    End Select
End Sub