Attribute VB_Name = "RakinDigitArithmetic"
Option Explicit

' Independent Word VBA Stage-1 arithmetic utility (Mapudungun / rakin).
' Every visible table cell contains one decimal digit (or is empty padding).
' Mathematical proof of equivalence:
'   Phi(d) = Sum(i=0..n-1) d(i)*10^i, where 0<=d(i)<=9.
'   Uniqueness follows by taking Phi mod 10 and inducting on (Phi-d0)/10.
'   Addition: t(i)=a(i)+b(i)+c(i), r(i)=t(i) Mod 10,
'     c(i+1)=t(i)\10. Since a(i)+b(i)+c(i)=r(i)+10*c(i+1),
'     summing times 10^i cancels all interior carries.
'   Multiplication: Phi(a)*Phi(b)
'       = Sum(k) (Sum(i+j=k) a(i)*b(j))*10^k by distributivity;
'     carry normalization gives exactly the conventional product.
'   For max 256 digits per factor, each column sum <= 256*81=20736,
'     and each carry <= 2304, so all intermediates <=23040.
'   Long arithmetic is exact, no floating point or foreign engine.
' Canonical calendar F(calculationDay, requestedDay) is NOT implemented.

Private Const DIGITS_PER_ROW As Long = 16
Private Const MAX_DIGITS As Long = 256

Public Sub RakinVisibleArithmetic()
    Dim a As String, b As String, s As String, p As String
    Dim doc As Document
    a = PromptExactUnsignedOperand("A")
    If Len(a) = 0 Then Exit Sub
    b = PromptExactUnsignedOperand("B")
    If Len(b) = 0 Then Exit Sub
    If Not IsDecimalDigits(a) Or Not IsDecimalDigits(b) Then
        MsgBox "Enter digits 0-9 only (maximum 256 per operand).", vbExclamation
        Exit Sub
    End If
    a = NormalizeDigits(a)
    b = NormalizeDigits(b)
    s = AddDigits(a, b)
    p = MultiplyDigits(a, b)
    If Documents.Count = 0 Then Documents.Add
    Set doc = ActiveDocument

    On Error GoTo Restore
    Application.ScreenUpdating = False
    AppendHeading doc, "Rakin | exact decimal operations"
    AppendHeading doc, "A  /  rakin"
    InsertDigitGrid doc, a, RGB(221, 240, 252)
    AppendHeading doc, "B  /  rakin"
    InsertDigitGrid doc, b, RGB(221, 240, 252)
    AppendHeading doc, "A + B  /  trapom rakin"
    InsertDigitGrid doc, s, RGB(221, 243, 229)
    AppendHeading doc, "A x B  /  ye" & ChrW(241) & "pramen"
    InsertDigitGrid doc, p, RGB(234, 227, 246)
    AppendProof doc
    Application.ScreenUpdating = True
    MsgBox "Rakin: exact addition and multiplication inserted; not a calendar conversion.", vbInformation
    Exit Sub

Restore:
    Application.ScreenUpdating = True
    MsgBox "Rakin error: " & Err.Description, vbCritical
End Sub

Public Function AddDigits(ByVal a As String, ByVal b As String) As String
    Dim i As Long, u As Long, v As Long, carry As Long, digit As Long
    Dim out As String, n As Long
    If Not IsDecimalDigits(a) Or Not IsDecimalDigits(b) Then
        Err.Raise vbObjectError + 701, , "Invalid decimal operand"
    End If
    a = NormalizeDigits(a): b = NormalizeDigits(b)
    n = Len(a)
    If Len(b) > n Then n = Len(b)
    For i = 1 To n
        u = DigitFromRight(a, i)
        v = DigitFromRight(b, i)
        digit = u + v + carry
        carry = digit \ 10
        out = CStr(digit Mod 10) & out
    Next i
    If carry <> 0 Then out = CStr(carry) & out
    AddDigits = NormalizeDigits(out)
End Function

Public Function MultiplyDigits(ByVal a As String, ByVal b As String) As String
    Dim i As Long, j As Long, k As Long, x As Long, carry As Long
    Dim nd As Long, pieces() As Long, out As String
    If Not IsDecimalDigits(a) Or Not IsDecimalDigits(b) Then
        Err.Raise vbObjectError + 702, , "Invalid decimal operand"
    End If
    a = NormalizeDigits(a): b = NormalizeDigits(b)
    nd = Len(a) + Len(b)
    ReDim pieces(0 To nd - 1)
    For i = 0 To Len(a) - 1
        For j = 0 To Len(b) - 1
            pieces(i + j) = pieces(i + j) + _
                DigitFromRight(a, i + 1) * DigitFromRight(b, j + 1)
        Next j
    Next i
    For k = 0 To nd - 1
        x = pieces(k) + carry
        out = CStr(x Mod 10) & out
        carry = x \ 10
    Next k
    If carry <> 0 Then
        Err.Raise vbObjectError + 703, , "Unexpected final carry"
    End If
    MultiplyDigits = NormalizeDigits(out)
End Function

' VBA InputBox returns at most 254 characters (Microsoft Learn).
' Demand an explicit total length and use <=128 characters per prompt.
' A canceled or shortened chunk aborts; no silent loss of high digits.
' https://learn.microsoft.com/en-us/office/vba/language/reference/user-interface-help/inputbox-function
Private Function PromptExactUnsignedOperand(ByVal operandLabel As String) As String
    Dim rawLength As String, firstPart As String, secondPart As String
    Dim digitsWanted As Long, firstCount As Long
    rawLength = Trim$(InputBox("How many ASCII decimal digits in " & operandLabel & _
        " (1..256)? Cancel to stop.", "Rakin / " & operandLabel & " / length"))
    If rawLength = "" Then Exit Function
    If Len(rawLength) > 3 Or Not IsDecimalDigits(rawLength) Then
        MsgBox "Length must be an integer from 1 to 256.", vbExclamation
        Exit Function
    End If
    digitsWanted = CLng(rawLength)
    If digitsWanted < 1 Or digitsWanted > MAX_DIGITS Then
        MsgBox "Length must be an integer from 1 to 256.", vbExclamation
        Exit Function
    End If
    firstCount = digitsWanted
    If firstCount > 128 Then firstCount = 128
    firstPart = Trim$(InputBox("Enter the FIRST " & CStr(firstCount) & _
        " digits of " & operandLabel & " (exactly this many).", _
        "Rakin / " & operandLabel & " / first chunk"))
    If Len(firstPart) <> firstCount Or Not IsDecimalDigits(firstPart) Then
        MsgBox "First chunk is not the required length or has non-ASCII digits.", vbExclamation
        Exit Function
    End If
    If digitsWanted > 128 Then
        secondPart = Trim$(InputBox("Enter the FINAL " & CStr(digitsWanted - 128) & _
            " digits of " & operandLabel & " (exactly this many).", _
            "Rakin / " & operandLabel & " / final chunk"))
        If Len(secondPart) <> digitsWanted - 128 Or Not IsDecimalDigits(secondPart) Then
            MsgBox "Final chunk is missing, shortened or has non-ASCII digits.", vbExclamation
            Exit Function
        End If
    End If
    PromptExactUnsignedOperand = firstPart & secondPart
End Function

Private Function DigitFromRight(ByVal a As String, ByVal pos As Long) As Long
    If pos > Len(a) Then
        DigitFromRight = 0
    Else
        DigitFromRight = Asc(Mid$(a, Len(a) - pos + 1, 1)) - 48
    End If
End Function

Private Function IsDecimalDigits(ByVal x As String) As Boolean
    Dim i As Long, k As Long
    If Len(x) < 1 Or Len(x) > MAX_DIGITS Then Exit Function
    For i = 1 To Len(x)
        k = Asc(Mid$(x, i, 1))
        If k < 48 Or k > 57 Then Exit Function
    Next i
    IsDecimalDigits = True
End Function

Private Function NormalizeDigits(ByVal x As String) As String
    Do While Len(x) > 1 And Left$(x, 1) = "0"
        x = Mid$(x, 2)
    Loop
    NormalizeDigits = x
End Function

Private Sub AppendHeading(ByVal doc As Document, ByVal txt As String)
    Dim r As Range
    Set r = doc.Range(doc.Content.End - 1, doc.Content.End - 1)
    r.InsertAfter txt & vbCr
    Set r = doc.Range(doc.Content.End - Len(txt) - 2, doc.Content.End - 2)
    r.Font.Name = "Aptos"
    r.Font.Bold = True
    r.Font.Size = 13
    r.Font.Color = RGB(22, 49, 77)
End Sub

Private Sub InsertDigitGrid(ByVal doc As Document, ByVal digits As String, ByVal rgbFill As Long)
    Dim nRows As Long, leftPad As Long, i As Long, r As Long, c As Long
    Dim t As Table, anchor As Range, letter As String, position As Long
    nRows = (Len(digits) + DIGITS_PER_ROW - 1) \ DIGITS_PER_ROW
    leftPad = nRows * DIGITS_PER_ROW - Len(digits)
    Set anchor = doc.Range(doc.Content.End - 1, doc.Content.End - 1)
    Set t = doc.Tables.Add(Range:=anchor, NumRows:=nRows, NumColumns:=DIGITS_PER_ROW)
    With t
        .Borders.Enable = True
        .Range.Font.Name = "Consolas"
        .Range.Font.Size = 10
        .Range.ParagraphFormat.Alignment = wdAlignParagraphCenter
        .Rows.Alignment = wdAlignRowCenter
    End With
    For i = 1 To nRows * DIGITS_PER_ROW
        r = (i - 1) \ DIGITS_PER_ROW + 1
        c = (i - 1) Mod DIGITS_PER_ROW + 1
        position = i - leftPad
        If position >= 1 And position <= Len(digits) Then
            letter = Mid$(digits, position, 1)
            t.Cell(r, c).Range.Text = letter
            t.Cell(r, c).Shading.BackgroundPatternColor = rgbFill
        Else
            t.Cell(r, c).Range.Text = ""
            t.Cell(r, c).Shading.BackgroundPatternColor = RGB(242, 246, 250)
        End If
    Next i
    Set anchor = doc.Range(doc.Content.End - 1, doc.Content.End - 1)
    anchor.InsertParagraphAfter
End Sub

Private Sub AppendProof(ByVal doc As Document)
    Dim r As Range
    Set r = doc.Range(doc.Content.End - 1, doc.Content.End - 1)
    r.InsertAfter "MATHEMATICAL NOTE: Phi(d) = sum of d(i)*10^i, digits 0..9." & vbCr & _
        "Uniqueness: compare modulo 10, subtract equal units digits, divide by 10 and induct." & vbCr & _
        "Addition: a(i)+b(i)+carry(i) = digit(i)+10*carry(i+1). " & _
        "Multiply by 10^i and sum: interior carries cancel." & vbCr & _
        "Multiplication: distribute to sum of a(i)*b(j)*10^(i+j), " & _
        "then normalize each diagonal with the same carry identity." & vbCr & _
        "Maximum partial product 81; max diagonal 20736; carry <=2304. Exact integer arithmetic." & vbCr & _
        "Stage 1: these operations do NOT compute the five canonical calendar fields." & vbCr
End Sub

Public Sub RakinArithmeticSelfTest()
    Dim check As Boolean
    check = (AddDigits("0008", "0007") = "15") _
        And (AddDigits("999", "1") = "1000") _
        And (MultiplyDigits("123", "456") = "56088") _
        And (MultiplyDigits("999", "999") = "998001") _
        And (MultiplyDigits("0", "99999999") = "0")
    If Not check Then Err.Raise vbObjectError + 704, , "Rakin self-test failed."
    MsgBox "5 exact arithmetic tests passed; Office-native execution remains to be recorded.", vbInformation
End Sub
