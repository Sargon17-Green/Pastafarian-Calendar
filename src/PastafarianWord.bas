Attribute VB_Name = "PastafarianWord"
Option Explicit

' Word-VBA / Mapudungun branch, Stage 1 only.
' This command inserts a provided exact five-component tuple.
' It is NOT the independent canonical F(calculationDay, targetDay) engine.

Public Sub InsertPastafarianDate()
    Dim labels(1 To 5) As String, fields(1 To 5) As String
    Dim i As Long, promptText As String, rendered As String, rawPrompt As String
    labels(1) = "year"
    labels(2) = "cutletName"
    labels(3) = "dayInCutlet"
    labels(4) = "monthName"
    labels(5) = "dayInMonth"

    For i = 1 To 5
        promptText = "Enter externally verified canonical value (" & _
            CStr(i) & "/5): " & labels(i) & vbCrLf & _
            "This macro only inserts five provided components; it does not calculate dates."
        rawPrompt = InputBox(promptText, "Pastafarian Date - Stage 1")
        ' VBA InputBox truncates long text to 254 characters. Never accept
        ' that ambiguous boundary, even when the original value was 254.
        ' Use InsertPastafarianDateFromSelection for arbitrary-length fields.
        If Len(rawPrompt) >= 254 Then
            MsgBox "InputBox may have truncated this field. Use the five-line " & _
                "document selection command instead.", vbExclamation
            Exit Sub
        End If
        fields(i) = rawPrompt
        If Len(fields(i)) = 0 Then Exit Sub
        If i = 1 Then
            If Not ValidDecimal(fields(i), False) Then
                MsgBox "Invalid signed decimal year.", vbExclamation
                Exit Sub
            End If
        ElseIf i = 3 Or i = 5 Then
            If Not ValidDecimal(fields(i), True) Then
                MsgBox "Invalid positive decimal day field.", vbExclamation
                Exit Sub
            End If
        End If
    Next i

    rendered = RenderExternalTuple(fields)
    If Documents.Count = 0 Then Documents.Add
    Selection.TypeText Text:=rendered
End Sub

' Lossless transport within Word: the user selects exactly five
' paragraphs, each with an explicit canonical *field identifier* and "=".
' This is NOT a proof that any supplied value is canonically correct.
' The selection is not replaced. The display result is appended afterwards.
Public Sub InsertPastafarianDateFromSelection()
    Dim fields(1 To 5) As String, failureReason As String
    Dim rawSelection As String, insertion As Range
    If Documents.Count = 0 Then
        MsgBox "Open a document and select five labeled paragraphs.", vbExclamation
        Exit Sub
    End If
    rawSelection = Selection.Range.Text
    If Not ParseExternalFiveTuple(rawSelection, fields, failureReason) Then
        MsgBox "Invalid external tuple: " & failureReason, vbExclamation
        Exit Sub
    End If
    Set insertion = Selection.Range.Duplicate
    insertion.Collapse Direction:=wdCollapseEnd
    insertion.InsertAfter vbCr & "EXTERNAL FIVE VALUES (NOT CALCULATED OR VERIFIED BY WORD): " & _
        RenderExternalTuple(fields) & vbCr
    MsgBox "External five-field tuple inserted. Source, indices and NFC " & _
        "still require independent verification.", vbInformation
End Sub

Private Function RenderExternalTuple(ByRef fields() As String) As String
    RenderExternalTuple = fields(1) & " | " & fields(2) & " " & fields(3) & _
        " | " & fields(4) & " " & fields(5)
End Function

' This parser interprets precisely five Word paragraphs, not CSV/TSV.
' No trimming, numeric conversion, Unicode normalization or case-folding.
Private Function ParseExternalFiveTuple(ByVal block As String, _
        ByRef fields() As String, ByRef failureReason As String) As Boolean
    Dim keys(1 To 5) As String, lines() As String
    Dim i As Long, prefix As String, fieldValue As String
    keys(1) = "year"
    keys(2) = "cutletName"
    keys(3) = "dayInCutlet"
    keys(4) = "monthName"
    keys(5) = "dayInMonth"
    failureReason = ""
    If Len(block) = 0 Then
        failureReason = "No selected text."
        Exit Function
    End If
    If InStr(1, block, vbLf, vbBinaryCompare) <> 0 Or _
            InStr(1, block, Chr$(7), vbBinaryCompare) <> 0 Or _
            InStr(1, block, Chr$(11), vbBinaryCompare) <> 0 Then
        failureReason = "Use plain Word paragraphs, not tables or line breaks."
        Exit Function
    End If
    ' Word includes the last paragraph mark when whole paragraphs are selected.
    If Right$(block, 1) = vbCr Then block = Left$(block, Len(block) - 1)
    lines = Split(block, vbCr)
    If UBound(lines) <> 4 Then
        failureReason = "Exactly five ordered labeled paragraphs are required."
        Exit Function
    End If
    For i = 1 To 5
        prefix = keys(i) & "="
        If Left$(lines(i - 1), Len(prefix)) <> prefix Then
            failureReason = "Expected labeled field: " & keys(i)
            Exit Function
        End If
        fieldValue = Mid$(lines(i - 1), Len(prefix) + 1)
        If Len(fieldValue) = 0 Then
            failureReason = "Empty field: " & keys(i)
            Exit Function
        End If
        If i = 1 Then
            If Not ValidDecimal(fieldValue, False) Then
                failureReason = "Year must be an exact signed ASCII decimal."
                Exit Function
            End If
        ElseIf i = 3 Or i = 5 Then
            If Not ValidDecimal(fieldValue, True) Then
                failureReason = "Day fields require positive ASCII decimals."
                Exit Function
            End If
        Else
            If Len(Trim$(fieldValue)) = 0 Then
                failureReason = "Name must contain nonspace characters."
                Exit Function
            End If
        End If
        fields(i) = fieldValue
    Next i
    ParseExternalFiveTuple = True
End Function

' These are local VBA assertions to run in Word, not a native PASS record.
Public Sub PastafarianInputContractSelfTest()
    Dim fields(1 To 5) As String, why As String
    Dim bigYear As String, validBlock As String
    bigYear = String$(1024, "9")
    validBlock = "year=" & bigYear & vbCr & _
        "cutletName=Mapu" & ChrW$(241) & "du" & vbCr & _
        "dayInCutlet=12" & vbCr & "monthName=K" & ChrW$(252) & _
        "me" & vbCr & "dayInMonth=3" & vbCr
    If Not ParseExternalFiveTuple(validBlock, fields, why) Then _
        Err.Raise vbObjectError + 531, , "Expected valid tuple: " & why
    If fields(1) <> bigYear Or fields(2) <> "Mapu" & ChrW$(241) & "du" Then _
        Err.Raise vbObjectError + 532, , "Lossless field roundtrip failed"
    If Not ParseExternalFiveTuple("year=-1" & vbCr & _
        "cutletName=A" & vbCr & "dayInCutlet=1" & vbCr & _
        "monthName=B" & vbCr & "dayInMonth=2", fields, why) Then _
        Err.Raise vbObjectError + 533, , "Negative year should parse"
    If ParseExternalFiveTuple("year=1" & vbCr & "cutletName=A" & vbCr & _
        "dayInCutlet=0" & vbCr & "monthName=B" & vbCr & _
        "dayInMonth=2", fields, why) Then _
        Err.Raise vbObjectError + 534, , "Zero day wrongly accepted"
    If ParseExternalFiveTuple("year=1" & vbCr & "monthName=B" & vbCr & _
        "dayInCutlet=1" & vbCr & "cutletName=A" & vbCr & _
        "dayInMonth=2", fields, why) Then _
        Err.Raise vbObjectError + 535, , "Reordered fields accepted"
    If ParseExternalFiveTuple("year=1" & vbCr & "cutletName=A" & vbCr & _
        "dayInCutlet=1" & vbCr & "monthName=B" & vbCr & _
        "dayInMonth=2" & vbCr & "extra=3", fields, why) Then _
        Err.Raise vbObjectError + 536, , "Extra field accepted"
    MsgBox "Stage 1 external-input parser self-test passed (Word Native).", vbInformation
End Sub

Public Sub CalculatePastafarianDateInWord()
    Err.Raise vbObjectError + 513, "PastafarianWord", _
        "CANONICAL ENGINE NOT IMPLEMENTED. Do not use Stage 1 as a date converter."
End Sub

Private Function ValidDecimal(ByVal raw As String, ByVal positive As Boolean) As Boolean
    Dim i As Long, firstDigit As Long, ch As String, hasNonzero As Boolean, code As Long
    If raw <> Trim$(raw) Then Exit Function
    firstDigit = 1
    If Len(raw) = 0 Then Exit Function
    If Left$(raw, 1) = "-" Then
        If positive Or Len(raw) = 1 Then Exit Function
        firstDigit = 2
    End If
    For i = firstDigit To Len(raw)
        ch = Mid$(raw, i, 1)
        code = AscW(ch)
        If code < 48 Or code > 57 Then Exit Function
        If ch <> "0" Then hasNonzero = True
    Next i
    If positive And Not hasNonzero Then Exit Function
    ValidDecimal = True
End Function
