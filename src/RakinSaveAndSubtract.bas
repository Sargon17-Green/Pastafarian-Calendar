Attribute VB_Name = "RakinSaveAndSubtract"
Option Explicit

' One digit per displayed cell. Exact decimal string arithmetic only.
' Stage 1: neither this module nor the existing one computes F(c,t).
Private Const MODULUS As String = "170141183460469231731687303715884105727"
Private Const MAX_DIGITS As Long = 256
Private Const BOARD_WIDTH As Long = 16

Private Function Clean(ByVal x As String) As String
    Do While Len(x) > 1 And Left$(x, 1) = "0"
        x = Mid$(x, 2)
    Loop
    Clean = x
End Function

Private Function AllDigits(ByVal x As String) As Boolean
    Dim i As Long, n As Long
    If Len(x) < 1 Or Len(x) > MAX_DIGITS Then Exit Function
    For i = 1 To Len(x)
        n = Asc(Mid$(x, i, 1))
        If n < 48 Or n > 57 Then Exit Function
    Next i
    AllDigits = True
End Function

Private Function CompareU(ByVal a As String, ByVal b As String) As Long
    a = Clean(a): b = Clean(b)
    If Len(a) > Len(b) Then CompareU = 1: Exit Function
    If Len(a) < Len(b) Then CompareU = -1: Exit Function
    CompareU = Sgn(StrComp(a, b, vbBinaryCompare))
End Function

Private Function SubU(ByVal a As String, ByVal b As String) As String
    ' Requires a>=b, both unsigned decimal strings.
    Dim i As Long, x As Long, y As Long, t As Long
    Dim borrow As Long, answer As String
    If CompareU(a, b) < 0 Then Err.Raise vbObjectError + 821, , "Unsigned underflow"
    a = Clean(a): b = Clean(b)
    For i = 1 To Len(a)
        x = Asc(Mid$(a, Len(a) - i + 1, 1)) - 48
        y = 0
        If i <= Len(b) Then y = Asc(Mid$(b, Len(b) - i + 1, 1)) - 48
        t = x - y - borrow
        borrow = 0
        If t < 0 Then t = t + 10: borrow = 1
        answer = CStr(t) & answer
    Next i
    If borrow <> 0 Then Err.Raise vbObjectError + 822, , "Unexpected final borrow"
    SubU = Clean(answer)
End Function

Public Function RakinSignedDifference(ByVal a As String, ByVal b As String) As String
    If Not AllDigits(a) Or Not AllDigits(b) Then
        Err.Raise vbObjectError + 823, , "Operands require 1..256 ASCII digits each"
    End If
    a = Clean(a): b = Clean(b)
    Select Case CompareU(a, b)
        Case 0: RakinSignedDifference = "0"
        Case 1: RakinSignedDifference = SubU(a, b)
        Case Else: RakinSignedDifference = "-" & SubU(b, a)
    End Select
End Function

Private Function ModU(ByVal decimalDigits As String) As String
    ' At each digit d, t=10*r+d<10*MODULUS whenever 0<=r<MODULUS.
    ' Thus at most nine elementary subtractions are sufficient.
    Dim i As Long, t As String, r As String, quotientDigit As Long
    r = "0"
    For i = 1 To Len(decimalDigits)
        t = Clean(r & Mid$(decimalDigits, i, 1))
        quotientDigit = 0
        Do While CompareU(t, MODULUS) >= 0
            t = SubU(t, MODULUS)
            quotientDigit = quotientDigit + 1
            If quotientDigit > 9 Then Err.Raise vbObjectError + 824, , "Long division invariant"
        Loop
        r = t
    Next i
    ModU = r
End Function

Public Function RakinSaveExact(ByVal signedInput As String) As String
    ' SAVE(x)=1+((x-1) mod M), Euclidean remainder.
    ' Equivalently use x mod M, replacing zero residue with M.
    Dim negative As Boolean, magnitude As String, remainder As String
    signedInput = Trim$(signedInput)
    negative = Left$(signedInput, 1) = "-"
    magnitude = signedInput
    If negative Or Left$(signedInput, 1) = "+" Then magnitude = Mid$(signedInput, 2)
    If Not AllDigits(magnitude) Then
        Err.Raise vbObjectError + 825, , "Expected signed decimal of up to 256 digits"
    End If
    remainder = ModU(Clean(magnitude))
    If negative And remainder <> "0" Then remainder = SubU(MODULUS, remainder)
    If remainder = "0" Then remainder = MODULUS
    RakinSaveExact = remainder
End Function

Private Sub WriteLabel(ByVal doc As Document, ByVal label As String)
    Dim p As Range
    Set p = doc.Range(doc.Content.End - 1, doc.Content.End - 1)
    p.InsertAfter label & vbCr
End Sub

Private Sub DrawDigitGrid(ByVal doc As Document, ByVal signedValue As String, ByVal backgroundColor As Long)
    Dim digits As String, pos As Long, padding As Long, i As Long
    Dim r As Long, c As Long, nRows As Long
    Dim tableRef As Table, p As Range
    digits = signedValue
    If Left$(digits, 1) = "-" Then
        WriteLabel doc, "SIGN: −"
        digits = Mid$(digits, 2)
    End If
    nRows = (Len(digits) + BOARD_WIDTH - 1) \ BOARD_WIDTH
    padding = nRows * BOARD_WIDTH - Len(digits)
    Set p = doc.Range(doc.Content.End - 1, doc.Content.End - 1)
    Set tableRef = doc.Tables.Add(p, nRows, BOARD_WIDTH)
    tableRef.Borders.Enable = True
    tableRef.Range.Font.Name = "Consolas"
    tableRef.Range.Font.Size = 10
    tableRef.Range.ParagraphFormat.Alignment = wdAlignParagraphCenter
    For i = 1 To nRows * BOARD_WIDTH
        r = 1 + (i - 1) \ BOARD_WIDTH
        c = 1 + (i - 1) Mod BOARD_WIDTH
        pos = i - padding
        If pos > 0 Then
            tableRef.Cell(r, c).Range.Text = Mid$(digits, pos, 1)
            tableRef.Cell(r, c).Shading.BackgroundPatternColor = backgroundColor
        Else
            tableRef.Cell(r, c).Range.Text = ""
            tableRef.Cell(r, c).Shading.BackgroundPatternColor = RGB(242, 246, 250)
        End If
    Next i
    Set p = doc.Range(doc.Content.End - 1, doc.Content.End - 1)
    p.InsertParagraphAfter
End Sub

Public Sub RakinSignedAndSaveReport()
    Dim a As String, b As String, doc As Document, note As Range
    a = Trim$(InputBox("Rakin: unsigned A (1..256 decimal digits)", "Rakin / A"))
    If a = "" Then Exit Sub
    b = Trim$(InputBox("Rakin: unsigned B (1..256 decimal digits)", "Rakin / B"))
    If b = "" Then Exit Sub
    If Not AllDigits(a) Or Not AllDigits(b) Then
        MsgBox "Use only decimal digits 0..9, at most 256.", vbExclamation
        Exit Sub
    End If
    If Documents.Count = 0 Then Documents.Add
    Set doc = ActiveDocument
    On Error GoTo Failed
    Application.ScreenUpdating = False
    WriteLabel doc, "Rakin / signed subtraction and SAVE — Stage 1 arithmetic"
    WriteLabel doc, "A − B"
    DrawDigitGrid doc, RakinSignedDifference(a, b), RGB(221, 243, 229)
    WriteLabel doc, "SAVE(A) modulo 2^127 − 1"
    DrawDigitGrid doc, RakinSaveExact(a), RGB(234, 227, 246)
    WriteLabel doc, "SAVE(B) modulo 2^127 − 1"
    DrawDigitGrid doc, RakinSaveExact(b), RGB(234, 227, 246)
    Set note = doc.Range(doc.Content.End - 1, doc.Content.End - 1)
    note.InsertAfter "PROOF: Phi(d)=sum(d_i*10^i), 0<=d_i<=9. Uniqueness by mod-10 induction." & vbCr & _
        "Subtraction: a_i-b_i-borrow_i=digit_i-10*borrow_(i+1); " & _
        "sum weighted columns to cancel internal borrows." & vbCr & _
        "Long division: t=10*r+d<10*M, therefore at most nine subtractions per input digit." & vbCr & _
        "SAVE(x) is x modulo M in 1..M, with zero residue replaced by M. " & _
        "Negative x uses M-(abs(x) mod M) unless residue zero." & vbCr & _
        "This arithmetic does not calculate canonical F(c,t)." & vbCr
    Application.ScreenUpdating = True
    MsgBox "Exact subtraction and SAVE inserted in digit tables.", vbInformation
    Exit Sub
Failed:
    Application.ScreenUpdating = True
    MsgBox "Rakin: " & Err.Description, vbCritical
End Sub

Public Sub RakinModularSelfTest()
    Dim ok As Boolean
    ok = (RakinSignedDifference("1000", "1") = "999") _
        And (RakinSignedDifference("1", "1000") = "-999") _
        And (RakinSignedDifference("1", "1") = "0") _
        And (RakinSaveExact("0") = MODULUS) _
        And (RakinSaveExact(MODULUS) = MODULUS) _
        And (RakinSaveExact("170141183460469231731687303715884105728") = "1") _
        And (RakinSaveExact("-1") = "170141183460469231731687303715884105726") _
        And (RakinSaveExact("-170141183460469231731687303715884105727") = MODULUS)
    If Not ok Then Err.Raise vbObjectError + 826, , "Modular self-test FAILED"
    MsgBox "Eight local VBA assertions passed.", vbInformation
End Sub
