unit BigInt;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$ENDIF}

interface

uses
  SysUtils;

const
  BIG_BASE: UInt64 = 1000000000;
  BIG_BASE_DIGITS = 9;

type
  TBigDigits = array of UInt32;

  TBigInt = record
    Sign: ShortInt;
    Digits: TBigDigits;
  end;

function BigZero: TBigInt;
function BigOne: TBigInt;
function BigFromInt64(Value: Int64): TBigInt;
function BigFromUInt64(Value: UInt64): TBigInt;
function BigFromDecimal(const S: string): TBigInt;
function BigToDecimal(const A: TBigInt): string;
function BigClone(const A: TBigInt): TBigInt;
function BigIsZero(const A: TBigInt): Boolean;
function BigCompareAbs(const A, B: TBigInt): Integer;
function BigCompare(const A, B: TBigInt): Integer;
function BigNegate(const A: TBigInt): TBigInt;
function BigAbs(const A: TBigInt): TBigInt;
function BigAdd(const A, B: TBigInt): TBigInt;
function BigSubtract(const A, B: TBigInt): TBigInt;
function BigMultiply(const A, B: TBigInt): TBigInt;
function BigMultiplyUInt32(const A: TBigInt; B: UInt32): TBigInt;
function BigMultiplyInt64(const A: TBigInt; B: Int64): TBigInt;
function BigSquare(const A: TBigInt): TBigInt;
procedure BigDivModPositive(const A, B: TBigInt; out Q, R: TBigInt);
function BigFloorDivPositive(const A, B: TBigInt): TBigInt;
function BigRegularModPositive(const A, D: TBigInt): TBigInt;
function BigAddInt64(const A: TBigInt; B: Int64): TBigInt;
function BigSubtractInt64(const A: TBigInt; B: Int64): TBigInt;
function BigToUInt32Exact(const A: TBigInt): UInt32;
function BigToInt64Exact(const A: TBigInt): Int64;
function BigMin(const A, B: TBigInt): TBigInt;
function BigMax(const A, B: TBigInt): TBigInt;

implementation

procedure Normalize(var A: TBigInt);
var
  N: Integer;
begin
  N := Length(A.Digits);
  while (N > 0) and (A.Digits[N - 1] = 0) do
    Dec(N);
  SetLength(A.Digits, N);
  if N = 0 then
    A.Sign := 0
  else if A.Sign = 0 then
    A.Sign := 1;
end;

function BigZero: TBigInt;
begin
  Result.Sign := 0;
  SetLength(Result.Digits, 0);
end;

function BigOne: TBigInt;
begin
  Result.Sign := 1;
  SetLength(Result.Digits, 1);
  Result.Digits[0] := 1;
end;

function BigClone(const A: TBigInt): TBigInt;
var
  I: Integer;
begin
  Result.Sign := A.Sign;
  SetLength(Result.Digits, Length(A.Digits));
  for I := 0 to High(A.Digits) do
    Result.Digits[I] := A.Digits[I];
end;

function BigFromUInt64(Value: UInt64): TBigInt;
var
  N: Integer;
begin
  if Value = 0 then
    Exit(BigZero);
  Result.Sign := 1;
  SetLength(Result.Digits, 3);
  N := 0;
  while Value <> 0 do
  begin
    Result.Digits[N] := UInt32(Value mod BIG_BASE);
    Value := Value div BIG_BASE;
    Inc(N);
  end;
  SetLength(Result.Digits, N);
end;

function BigFromInt64(Value: Int64): TBigInt;
var
  Mag: UInt64;
begin
  if Value = 0 then
    Exit(BigZero);
  if Value > 0 then
    Exit(BigFromUInt64(UInt64(Value)));
  Mag := UInt64(-(Value + 1)) + 1;
  Result := BigFromUInt64(Mag);
  Result.Sign := -1;
end;

function BigFromDecimal(const S: string): TBigInt;
var
  I, StartAt: Integer;
  Negative: Boolean;
  Digit: Integer;
begin
  if S = '' then
    raise EConvertError.Create('Número decimal vazio.');
  Negative := S[1] = '-';
  if Negative then
    StartAt := 2
  else
    StartAt := 1;
  if StartAt > Length(S) then
    raise EConvertError.Create('Número decimal inválido.');
  Result := BigZero;
  for I := StartAt to Length(S) do
  begin
    if not (S[I] in ['0'..'9']) then
      raise EConvertError.Create('Número decimal inválido.');
    Digit := Ord(S[I]) - Ord('0');
    Result := BigMultiplyUInt32(Result, 10);
    Result := BigAdd(Result, BigFromInt64(Digit));
  end;
  if Negative and not BigIsZero(Result) then
    Result.Sign := -1;
end;

function BigToDecimal(const A: TBigInt): string;
var
  I: Integer;
  Part: string;
begin
  if BigIsZero(A) then
    Exit('0');
  Result := IntToStr(A.Digits[High(A.Digits)]);
  for I := High(A.Digits) - 1 downto 0 do
  begin
    Part := IntToStr(A.Digits[I]);
    while Length(Part) < BIG_BASE_DIGITS do
      Part := '0' + Part;
    Result := Result + Part;
  end;
  if A.Sign < 0 then
    Result := '-' + Result;
end;

function BigIsZero(const A: TBigInt): Boolean;
begin
  Result := (A.Sign = 0) or (Length(A.Digits) = 0);
end;

function BigCompareAbs(const A, B: TBigInt): Integer;
var
  I: Integer;
begin
  if Length(A.Digits) < Length(B.Digits) then Exit(-1);
  if Length(A.Digits) > Length(B.Digits) then Exit(1);
  for I := High(A.Digits) downto 0 do
  begin
    if A.Digits[I] < B.Digits[I] then Exit(-1);
    if A.Digits[I] > B.Digits[I] then Exit(1);
  end;
  Result := 0;
end;

function BigCompare(const A, B: TBigInt): Integer;
begin
  if A.Sign < B.Sign then Exit(-1);
  if A.Sign > B.Sign then Exit(1);
  if A.Sign = 0 then Exit(0);
  Result := BigCompareAbs(A, B);
  if A.Sign < 0 then
    Result := -Result;
end;

function BigNegate(const A: TBigInt): TBigInt;
begin
  Result := BigClone(A);
  Result.Sign := -Result.Sign;
end;

function BigAbs(const A: TBigInt): TBigInt;
begin
  Result := BigClone(A);
  if Result.Sign < 0 then
    Result.Sign := 1;
end;

function AddAbs(const A, B: TBigInt): TBigInt;
var
  I, N: Integer;
  Carry, Cur: UInt64;
begin
  if Length(A.Digits) > Length(B.Digits) then
    N := Length(A.Digits)
  else
    N := Length(B.Digits);
  SetLength(Result.Digits, N + 1);
  Result.Sign := 1;
  Carry := 0;
  for I := 0 to N - 1 do
  begin
    Cur := Carry;
    if I < Length(A.Digits) then Cur := Cur + A.Digits[I];
    if I < Length(B.Digits) then Cur := Cur + B.Digits[I];
    Result.Digits[I] := UInt32(Cur mod BIG_BASE);
    Carry := Cur div BIG_BASE;
  end;
  if Carry <> 0 then
    Result.Digits[N] := UInt32(Carry)
  else
    SetLength(Result.Digits, N);
  Normalize(Result);
end;

function SubAbs(const A, B: TBigInt): TBigInt;
var
  I: Integer;
  Cur: Int64;
  Borrow: Int64;
begin
  if BigCompareAbs(A, B) < 0 then
    raise ERangeError.Create('Subtração absoluta fora da pré-condição.');
  SetLength(Result.Digits, Length(A.Digits));
  Result.Sign := 1;
  Borrow := 0;
  for I := 0 to High(A.Digits) do
  begin
    Cur := Int64(A.Digits[I]) - Borrow;
    if I < Length(B.Digits) then
      Cur := Cur - Int64(B.Digits[I]);
    if Cur < 0 then
    begin
      Cur := Cur + Int64(BIG_BASE);
      Borrow := 1;
    end
    else
      Borrow := 0;
    Result.Digits[I] := UInt32(Cur);
  end;
  Normalize(Result);
end;

function BigAdd(const A, B: TBigInt): TBigInt;
var
  C: Integer;
begin
  if BigIsZero(A) then Exit(BigClone(B));
  if BigIsZero(B) then Exit(BigClone(A));
  if A.Sign = B.Sign then
  begin
    Result := AddAbs(A, B);
    Result.Sign := A.Sign;
    Exit;
  end;
  C := BigCompareAbs(A, B);
  if C = 0 then Exit(BigZero);
  if C > 0 then
  begin
    Result := SubAbs(A, B);
    Result.Sign := A.Sign;
  end
  else
  begin
    Result := SubAbs(B, A);
    Result.Sign := B.Sign;
  end;
end;

function BigSubtract(const A, B: TBigInt): TBigInt;
begin
  Result := BigAdd(A, BigNegate(B));
end;

function BigMultiplyUInt32(const A: TBigInt; B: UInt32): TBigInt;
var
  I: Integer;
  Carry, Cur: UInt64;
begin
  if BigIsZero(A) or (B = 0) then Exit(BigZero);
  SetLength(Result.Digits, Length(A.Digits) + 1);
  Result.Sign := A.Sign;
  Carry := 0;
  for I := 0 to High(A.Digits) do
  begin
    Cur := UInt64(A.Digits[I]) * UInt64(B) + Carry;
    Result.Digits[I] := UInt32(Cur mod BIG_BASE);
    Carry := Cur div BIG_BASE;
  end;
  if Carry <> 0 then
    Result.Digits[Length(A.Digits)] := UInt32(Carry)
  else
    SetLength(Result.Digits, Length(A.Digits));
  Normalize(Result);
end;

function BigMultiplyInt64(const A: TBigInt; B: Int64): TBigInt;
var
  Mag: UInt64;
  X, Y: TBigInt;
begin
  if B = 0 then Exit(BigZero);
  if B > 0 then
  begin
    Y := BigFromInt64(B);
    Exit(BigMultiply(A, Y));
  end;
  Mag := UInt64(-(B + 1)) + 1;
  X := BigFromUInt64(Mag);
  Result := BigMultiply(A, X);
  Result.Sign := -Result.Sign;
end;

function BigMultiply(const A, B: TBigInt): TBigInt;
var
  I, J: Integer;
  Cur, Carry: UInt64;
begin
  if BigIsZero(A) or BigIsZero(B) then Exit(BigZero);
  SetLength(Result.Digits, Length(A.Digits) + Length(B.Digits));
  for I := 0 to High(Result.Digits) do Result.Digits[I] := 0;
  Result.Sign := A.Sign * B.Sign;
  for I := 0 to High(A.Digits) do
  begin
    Carry := 0;
    for J := 0 to High(B.Digits) do
    begin
      Cur := UInt64(Result.Digits[I + J]) +
             UInt64(A.Digits[I]) * UInt64(B.Digits[J]) + Carry;
      Result.Digits[I + J] := UInt32(Cur mod BIG_BASE);
      Carry := Cur div BIG_BASE;
    end;
    J := Length(B.Digits);
    while Carry <> 0 do
    begin
      Cur := UInt64(Result.Digits[I + J]) + Carry;
      Result.Digits[I + J] := UInt32(Cur mod BIG_BASE);
      Carry := Cur div BIG_BASE;
      Inc(J);
    end;
  end;
  Normalize(Result);
end;

function BigSquare(const A: TBigInt): TBigInt;
begin
  Result := BigMultiply(A, A);
end;

function ShiftBaseAdd(const A: TBigInt; Digit: UInt32): TBigInt;
var
  I: Integer;
begin
  if BigIsZero(A) and (Digit = 0) then Exit(BigZero);
  Result.Sign := 1;
  SetLength(Result.Digits, Length(A.Digits) + 1);
  Result.Digits[0] := Digit;
  for I := 0 to High(A.Digits) do
    Result.Digits[I + 1] := A.Digits[I];
  Normalize(Result);
end;

procedure BigDivModPositive(const A, B: TBigInt; out Q, R: TBigInt);
var
  I: Integer;
  Low, High, Mid, Best: UInt32;
  Probe: TBigInt;
begin
  if (B.Sign <= 0) or BigIsZero(B) then
    raise EDivByZero.Create('Divisor não positivo.');
  if A.Sign < 0 then
    raise ERangeError.Create('Divisão positiva recebeu dividendo negativo.');
  if BigCompareAbs(A, B) < 0 then
  begin
    Q := BigZero;
    R := BigClone(A);
    Exit;
  end;
  Q.Sign := 1;
  SetLength(Q.Digits, Length(A.Digits));
  for I := 0 to High(Q.Digits) do Q.Digits[I] := 0;
  R := BigZero;
  for I := High(A.Digits) downto 0 do
  begin
    R := ShiftBaseAdd(R, A.Digits[I]);
    Low := 0;
    High := UInt32(BIG_BASE - 1);
    Best := 0;
    while Low <= High do
    begin
      Mid := Low + (High - Low) div 2;
      Probe := BigMultiplyUInt32(B, Mid);
      if BigCompareAbs(Probe, R) <= 0 then
      begin
        Best := Mid;
        if Mid = UInt32(BIG_BASE - 1) then Break;
        Low := Mid + 1;
      end
      else
      begin
        if Mid = 0 then Break;
        High := Mid - 1;
      end;
    end;
    Q.Digits[I] := Best;
    if Best <> 0 then
      R := SubAbs(R, BigMultiplyUInt32(B, Best));
  end;
  Normalize(Q);
  Normalize(R);
end;

function BigFloorDivPositive(const A, B: TBigInt): TBigInt;
var
  R: TBigInt;
begin
  BigDivModPositive(A, B, Result, R);
end;

function BigRegularModPositive(const A, D: TBigInt): TBigInt;
var
  Q, R, AbsA: TBigInt;
begin
  if (D.Sign <= 0) or BigIsZero(D) then
    raise EDivByZero.Create('Módulo com divisor não positivo.');
  if A.Sign >= 0 then
  begin
    BigDivModPositive(A, D, Q, R);
    Exit(R);
  end;
  AbsA := BigAbs(A);
  BigDivModPositive(AbsA, D, Q, R);
  if BigIsZero(R) then
    Exit(BigZero);
  Result := BigSubtract(D, R);
end;

function BigAddInt64(const A: TBigInt; B: Int64): TBigInt;
begin
  Result := BigAdd(A, BigFromInt64(B));
end;

function BigSubtractInt64(const A: TBigInt; B: Int64): TBigInt;
begin
  Result := BigSubtract(A, BigFromInt64(B));
end;

function BigToUInt32Exact(const A: TBigInt): UInt32;
var
  V: UInt64;
begin
  if A.Sign < 0 then
    raise ERangeError.Create('Valor negativo não cabe em UInt32.');
  if BigIsZero(A) then Exit(0);
  if Length(A.Digits) > 2 then
    raise ERangeError.Create('Valor não cabe em UInt32.');
  V := A.Digits[0];
  if Length(A.Digits) = 2 then
    V := V + UInt64(A.Digits[1]) * BIG_BASE;
  if V > High(UInt32) then
    raise ERangeError.Create('Valor não cabe em UInt32.');
  Result := UInt32(V);
end;

function BigToInt64Exact(const A: TBigInt): Int64;
var
  I: Integer;
  V: UInt64;
begin
  V := 0;
  for I := High(A.Digits) downto 0 do
  begin
    if V > (High(UInt64) - A.Digits[I]) div BIG_BASE then
      raise ERangeError.Create('Valor não cabe em Int64.');
    V := V * BIG_BASE + A.Digits[I];
  end;
  if A.Sign >= 0 then
  begin
    if V > UInt64(High(Int64)) then
      raise ERangeError.Create('Valor não cabe em Int64.');
    Result := Int64(V);
  end
  else
  begin
    if V > UInt64(High(Int64)) + 1 then
      raise ERangeError.Create('Valor não cabe em Int64.');
    if V = UInt64(High(Int64)) + 1 then
      Result := Low(Int64)
    else
      Result := -Int64(V);
  end;
end;

function BigMin(const A, B: TBigInt): TBigInt;
begin
  if BigCompare(A, B) <= 0 then Result := BigClone(A) else Result := BigClone(B);
end;

function BigMax(const A, B: TBigInt): TBigInt;
begin
  if BigCompare(A, B) >= 0 then Result := BigClone(A) else Result := BigClone(B);
end;

end.
