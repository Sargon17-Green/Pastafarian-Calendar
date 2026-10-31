Attribute VB_Name = "VisibleArithmeticFormulas"
Option Explicit

' One decimal digit per cell, BASE=10, not the former base-10000 demo.
' Phi(d) = Sum_i d_i*10^i, 0<=d_i<=9.
' Uniqueness: reduce mod 10, subtract the units, divide by 10, induct.
' Addition: a_i+b_i+c_i=r_i+10*c_(i+1); summing with weights 10^i
' telescopes, proving Phi(a)+Phi(b) = Phi(r) including the final carry.
' Multiplication: distributivity gives coefficient sum_(i+j=k)a_i*b_j,
' then the same carry identity proves Phi(a)*Phi(b)=Phi(product digits).
' At 128 input digits, diagonal<=128*81=10368 and carry<=1152;
' every intermediate <=11520<2^53, hence exactly represented by Excel.
' This arithmetic utility does NOT compute canonical calendar F(c,t).

Private Function FindByPrefix(ByVal prefix As String) As Worksheet
    Dim sh As Worksheet
    For Each sh In ThisWorkbook.Worksheets
        If Left$(sh.Name, 3) = prefix & "_" Then
            Set FindByPrefix = sh
            Exit Function
        End If
    Next sh
    Err.Raise vbObjectError + 710, , "Missing digit sheet " & prefix
End Function

Private Function ColName(ByVal colNumber As Long) As String
    Dim a As String
    a = ThisWorkbook.Worksheets(1).Cells(1, colNumber).Address(False, False)
    ColName = Left$(a, Len(a) - 1)
End Function

Private Function SQ(ByVal sh As Worksheet) As String
    SQ = "'" & Replace(sh.Name, "'", "''") & "'!"
End Function

Private Sub CheckDigitBoard(ByVal sh As Worksheet, ByVal firstRow As Long)
    Dim rr As Long, cc As Long, x As Variant
    For rr = firstRow To firstRow + 7
        For cc = 4 To 19
            x = sh.Cells(rr, cc).Value2
            If Not IsNumeric(x) Or VarType(x) = vbString Then
                Err.Raise vbObjectError + 711, , "Non-numeric digit in " & sh.Cells(rr, cc).Address
            End If
            If x < 0 Or x > 9 Or x <> Fix(CDbl(x)) Then
                Err.Raise vbObjectError + 712, , "Digit must be integer 0..9: " & sh.Cells(rr, cc).Address
            End If
        Next cc
    Next rr
End Sub

Public Sub RebuildVisibleArithmetic()
    Const N As Long = 128
    Dim inp As Worksheet, add As Worksheet, mult As Worksheet, diag As Worksheet
    Dim i As Long, j As Long, k As Long, r As Long, srcIndex As Long
    Dim srcA As String, srcB As String, refs As String, batch As String, groups As String
    Dim batchCount As Long, oldCalc As XlCalculation, oldScreen As Boolean
    Dim stateSaved As Boolean, errText As String

    On Error GoTo Failed
    Set inp = FindByPrefix("01")
    Set add = FindByPrefix("02")
    Set mult = FindByPrefix("03")
    Set diag = FindByPrefix("04")
    CheckDigitBoard inp, 8
    CheckDigitBoard inp, 20

    oldCalc = Application.Calculation
    oldScreen = Application.ScreenUpdating
    stateSaved = True
    Application.Calculation = xlCalculationManual
    Application.ScreenUpdating = False

    For i = 0 To N - 1
        r = 8 + i
        srcIndex = N - 1 - i
        srcA = SQ(inp) & ColName(4 + srcIndex Mod 16) & CStr(8 + srcIndex \ 16)
        srcB = SQ(inp) & ColName(4 + srcIndex Mod 16) & CStr(20 + srcIndex \ 16)
        add.Cells(r, 1).Value2 = i
        add.Cells(r, 2).Formula = "=" & srcA
        add.Cells(r, 3).Formula = "=" & srcB
        mult.Cells(r, 1).Value2 = i
        mult.Cells(r, 2).Formula = "=" & srcA
        mult.Cells(6, 4 + i).Value2 = i
        mult.Cells(7, 4 + i).Formula = "=" & srcB
        If i = 0 Then
            add.Cells(r, 4).Formula = "=0"
        Else
            add.Cells(r, 4).Formula = "=G" & CStr(r - 1)
        End If
        add.Cells(r, 5).Formula = "=B" & r & "+C" & r & "+D" & r
        add.Cells(r, 6).Formula = "=MOD(E" & r & ",10)"
        add.Cells(r, 7).Formula = "=INT(E" & r & "/10)"
        add.Cells(r, 8).Formula = "=E" & r & "-F" & r & "-10*G" & r
    Next i

    For i = 0 To N - 1
        For j = 0 To N - 1
            r = 8 + i
            mult.Cells(r, 4 + j).Formula = "=$B" & r & "*" & ColName(4 + j) & "$7"
        Next j
    Next i

    r = 8 + N
    add.Cells(r, 1).Value2 = N
    add.Cells(r, 2).Formula = "=0"
    add.Cells(r, 3).Formula = "=0"
    add.Cells(r, 4).Formula = "=G" & (r - 1)
    add.Cells(r, 5).Formula = "=D" & r
    add.Cells(r, 6).Formula = "=MOD(E" & r & ",10)"
    add.Cells(r, 7).Formula = "=INT(E" & r & "/10)"
    add.Cells(r, 8).Formula = "=E" & r & "-F" & r & "-10*G" & r

    For k = 0 To 2 * N - 1
        r = 8 + k
        batch = ""
        groups = ""
        batchCount = 0
        For i = 0 To N - 1
            j = k - i
            If j >= 0 And j < N Then
                If Len(batch) > 0 Then batch = batch & ","
                batch = batch & SQ(mult) & ColName(4 + j) & CStr(8 + i)
                batchCount = batchCount + 1
                If batchCount >= 90 Then
                    If Len(groups) > 0 Then groups = groups & ","
                    groups = groups & "SUM(" & batch & ")"
                    batch = ""
                    batchCount = 0
                End If
            End If
        Next i
        If Len(batch) > 0 Then
            If Len(groups) > 0 Then groups = groups & ","
            groups = groups & "SUM(" & batch & ")"
        End If
        diag.Cells(r, 1).Value2 = k
        If Len(groups) = 0 Then
            diag.Cells(r, 2).Formula = "=0"
        Else
            diag.Cells(r, 2).Formula = "=SUM(" & groups & ")"
        End If
        If k = 0 Then
            diag.Cells(r, 3).Formula = "=0"
        Else
            diag.Cells(r, 3).Formula = "=F" & (r - 1)
        End If
        diag.Cells(r, 4).Formula = "=B" & r & "+C" & r
        diag.Cells(r, 5).Formula = "=MOD(D" & r & ",10)"
        diag.Cells(r, 6).Formula = "=INT(D" & r & "/10)"
        diag.Cells(r, 7).Formula = "=D" & r & "-E" & r & "-10*F" & r
    Next k

    Application.Calculation = oldCalc
    Application.ScreenUpdating = oldScreen
    MsgBox "Base-10 formulas rebuilt (one digit per cell). No canonical calendar conversion.", vbInformation
    Exit Sub
Failed:
    errText = Err.Description
    On Error Resume Next
    If stateSaved Then
        Application.Calculation = oldCalc
        Application.ScreenUpdating = oldScreen
    End If
    MsgBox "Cannot rebuild formulas: " & errText, vbCritical
End Sub
