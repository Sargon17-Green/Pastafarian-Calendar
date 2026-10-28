Attribute VB_Name = "VisibleArithmeticFormulas"
Option Explicit

' Worksheet formula arithmetic in base 10000: no BigInt coercion, no new engine.
' Rebuilds formulas in the graphical 64-block Excel template, not the entire
' normative five-component Pastafarian calendar F(c,t).

Private Function StageSheet(ByVal prefix As String) As Worksheet
    Dim sh As Worksheet
    For Each sh In ThisWorkbook.Worksheets
        If Left$(sh.Name, 3) = prefix & "_" Then
            Set StageSheet = sh
            Exit Function
        End If
    Next sh
    Err.Raise vbObjectError + 700, , "Missing sheet prefix " & prefix & ". Use the supplied workbook."
End Function

Private Function QuotedSheet(ByVal sh As Worksheet) As String
    QuotedSheet = "'" & Replace(sh.Name, "'", "''") & "'"
End Function

Private Function ColLetters(ByVal columnNumber As Long) As String
    Dim ref As String
    ref = ThisWorkbook.Worksheets(1).Cells(1, columnNumber).Address(False, False)
    ColLetters = Left$(ref, Len(ref) - 1)
End Function

Public Sub RebuildVisibleArithmetic()
    Const N As Long = 64
    Const RADIX As Long = 10000
    Dim inp As Worksheet, add As Worksheet, p As Worksheet, d As Worksheet
    Dim i As Long, j As Long, k As Long, r As Long, c As Long
    Dim terms As String, qi As String, qp As String, message As String, zeroTile As String
    Dim calcMode As XlCalculation, screenWasOn As Boolean, stateSaved As Boolean
    On Error GoTo Failed

    Set inp = StageSheet("08")
    Set add = StageSheet("09")
    Set p = StageSheet("10")
    Set d = StageSheet("11")
    qi = QuotedSheet(inp)
    qp = QuotedSheet(p)
    calcMode = Application.Calculation
    screenWasOn = Application.ScreenUpdating
    stateSaved = True
    Application.Calculation = xlCalculationManual
    Application.ScreenUpdating = False

    inp.Range("C5").Value2 = RADIX
    inp.Range("F5").Value2 = N
    add.Range("B5").Formula = "=" & qi & "!$C$5"
    d.Range("B5").Formula = "=" & qi & "!$C$5"

    For i = 0 To N - 1
        r = 8 + i
        inp.Cells(r, 5).Formula = "=TEXT(C" & r & ",""0000"")"
        inp.Cells(r, 6).Formula = "=TEXT(D" & r & ",""0000"")"
        If i = N - 1 Then
            zeroTile = """0000"""
        Else
            zeroTile = """"""
        End If
        inp.Cells(r, 7).Formula = "=IF(SUM($C$" & (71 - i) & ":$C$71)=0," & zeroTile & ",TEXT(C" & (71 - i) & ",""0000""))"
        inp.Cells(r, 8).Formula = "=IF(SUM($D$" & (71 - i) & ":$D$71)=0," & zeroTile & ",TEXT(D" & (71 - i) & ",""0000""))"

        add.Cells(r, 1).Formula = "=" & i
        add.Cells(r, 2).Formula = "=" & qi & "!C" & r
        add.Cells(r, 3).Formula = "=" & qi & "!D" & r
        If i = 0 Then
            add.Cells(r, 4).Formula = "=0"
        Else
            add.Cells(r, 4).Formula = "=G" & r - 1
        End If
        add.Cells(r, 5).Formula = "=B" & r & "+C" & r & "+D" & r
        add.Cells(r, 6).Formula = "=MOD(E" & r & ",$B$5)"
        add.Cells(r, 7).Formula = "=QUOTIENT(E" & r & ",$B$5)"
        add.Cells(r, 8).Formula = "=TEXT(F" & r & ",""0000"")"

        p.Cells(8, 5 + i).Formula = "=" & qi & "!D" & r
        p.Cells(9 + i, 2).Value2 = i
        p.Cells(9 + i, 4).Formula = "=" & qi & "!C" & r
    Next i

    For i = 0 To N - 1
        For j = 0 To N - 1
            r = 9 + i
            c = 5 + j
            p.Cells(r, c).Formula = "=$D" & r & "*" & ColLetters(c) & "$8"
        Next j
    Next i

    r = 8 + N
    add.Cells(r, 1).Formula = "=" & N
    add.Cells(r, 2).Formula = "=0"
    add.Cells(r, 3).Formula = "=0"
    add.Cells(r, 4).Formula = "=G" & r - 1
    add.Cells(r, 5).Formula = "=D" & r
    add.Cells(r, 6).Formula = "=MOD(E" & r & ",$B$5)"
    add.Cells(r, 7).Formula = "=QUOTIENT(E" & r & ",$B$5)"
    add.Cells(r, 8).Formula = "=TEXT(F" & r & ",""0000"")"

    For k = 0 To 2 * N - 1
        r = 8 + k
        d.Cells(r, 1).Formula = "=" & k
        terms = ""
        For i = 0 To N - 1
            j = k - i
            If j >= 0 And j < N Then
                If Len(terms) > 0 Then terms = terms & ","
                terms = terms & qp & "!" & ColLetters(5 + j) & (9 + i)
            End If
        Next i
        If Len(terms) = 0 Then
            d.Cells(r, 2).Formula = "=0"
        Else
            d.Cells(r, 2).Formula = "=SUM(" & terms & ")"
        End If
        If k = 0 Then
            d.Cells(r, 3).Formula = "=0"
        Else
            d.Cells(r, 3).Formula = "=F" & r - 1
        End If
        d.Cells(r, 4).Formula = "=B" & r & "+C" & r
        d.Cells(r, 5).Formula = "=MOD(D" & r & ",$B$5)"
        d.Cells(r, 6).Formula = "=QUOTIENT(D" & r & ",$B$5)"
        d.Cells(r, 7).Formula = "=TEXT(E" & r & ",""0000"")"
        d.Cells(r, 8).Formula = "=INDEX($G$8:$G$135," & 2 * N & "-A" & r & ")"
    Next k

    Application.Calculation = calcMode
    Application.ScreenUpdating = screenWasOn
    MsgBox "Visible worksheet formulas restored. 256 digits per nonnegative operand; F(c,t) is NOT implemented.", vbInformation
    Exit Sub

Failed:
    message = Err.Description
    On Error Resume Next
    If stateSaved Then
        Application.Calculation = calcMode
        Application.ScreenUpdating = screenWasOn
    End If
    MsgBox "RebuildVisibleArithmetic: " & message, vbCritical
End Sub
