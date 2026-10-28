Attribute VB_Name = "PastafarianWord"
Option Explicit

' Word-VBA / Mapudungun branch, Stage 1 only.
' This command inserts a provided exact five-component tuple.
' It is NOT the independent canonical F(calculationDay, targetDay) engine.

Public Sub InsertPastafarianDate()
    Dim labels(1 To 5) As String, fields(1 To 5) As String
    Dim i As Long, promptText As String, rendered As String
    labels(1) = "year"
    labels(2) = "cutletName"
    labels(3) = "dayInCutlet"
    labels(4) = "monthName"
    labels(5) = "dayInMonth"

    For i = 1 To 5
        promptText = "Enter externally verified canonical value (" & _
            CStr(i) & "/5): " & labels(i) & vbCrLf & _
            "This macro only inserts five provided components; it does not calculate dates."
        fields(i) = Trim$(InputBox(promptText, "Pastafarian Date - Stage 1"))
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

    rendered = fields(1) & " | " & fields(2) & " " & fields(3) & _
        " | " & fields(4) & " " & fields(5)
    If Documents.Count = 0 Then Documents.Add
    Selection.TypeText Text:=rendered
End Sub

Public Sub CalculatePastafarianDateInWord()
    Err.Raise vbObjectError + 513, "PastafarianWord", _
        "CANONICAL ENGINE NOT IMPLEMENTED. Do not use Stage 1 as a date converter."
End Sub

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
