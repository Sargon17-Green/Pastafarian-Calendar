unit SourceLanguageCatalog;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}

interface

uses
  SysUtils;

const
  SOURCE_LANGUAGE_CATALOG_VERSION = 'pt-PT-1.0.0';
  CUTLET_NAME_COUNT = 17;
  MONTH_NAME_COUNT = 47;

function CutletNameByCanonicalIndex(Index: Integer): UnicodeString;
function MonthNameByCanonicalIndex(Index: Integer): UnicodeString;
function SourceLanguageCatalogIsFrozen: Boolean;
function SourceLanguageCatalogSelfCheck: Boolean;

implementation

var
  CutletNames: array[1..CUTLET_NAME_COUNT] of UnicodeString;
  MonthNames: array[1..MONTH_NAME_COUNT] of UnicodeString;
  Frozen: Boolean = False;

procedure InitializeCatalog;
begin
  { O índice canónico é a única ordem normativa. O texto nunca participa em rank, unrank ou chaves semânticas. }
  CutletNames[1] := 'bronze';
  CutletNames[2] := 'raposa';
  CutletNames[3] := 'rim';
  CutletNames[4] := 'lárix';
  CutletNames[5] := 'pensamento';
  CutletNames[6] := 'quatro partes de nove';
  CutletNames[7] := 'Palgurash';
  CutletNames[8] := 'junco';
  CutletNames[9] := 'cacho';
  CutletNames[10] := 'escorpião';
  CutletNames[11] := 'cinza';
  CutletNames[12] := 'trigo';
  CutletNames[13] := 'rio';
  CutletNames[14] := 'riso';
  CutletNames[15] := 'Acade';
  CutletNames[16] := 'chifre';
  CutletNames[17] := 'o jarro vazio';

  MonthNames[1] := 'barro';
  MonthNames[2] := 'romã';
  MonthNames[3] := 'cotovelo';
  MonthNames[4] := 'inveja';
  MonthNames[5] := 'Eridu';
  MonthNames[6] := 'pasta de dentes';
  MonthNames[7] := 'três partes de cinco';
  MonthNames[8] := 'Karshumav';
  MonthNames[9] := 'leopardo';
  MonthNames[10] := 'estanho';
  MonthNames[11] := 'nevoeiro';
  MonthNames[12] := 'olíbano';
  MonthNames[13] := 'fuso';
  MonthNames[14] := 'costela';
  MonthNames[15] := 'alfarroba';
  MonthNames[16] := 'Uruk';
  MonthNames[17] := 'vergonha';
  MonthNames[18] := 'camelo';
  MonthNames[19] := 'cobre';
  MonthNames[20] := 'poço';
  MonthNames[21] := 'gema';
  MonthNames[22] := 'estrela';
  MonthNames[23] := 'mel';
  MonthNames[24] := 'baço';
  MonthNames[25] := 'calcário';
  MonthNames[26] := 'alegria';
  MonthNames[27] := 'figo';
  MonthNames[28] := 'Nínive';
  MonthNames[29] := 'rã';
  MonthNames[30] := 'piche';
  MonthNames[31] := 'vela';
  MonthNames[32] := 'a porta fechada';
  MonthNames[33] := 'gergelim';
  MonthNames[34] := 'nuca';
  MonthNames[35] := 'prata';
  MonthNames[36] := 'lírio';
  MonthNames[37] := 'tempestade';
  MonthNames[38] := 'burro';
  MonthNames[39] := 'farinha';
  MonthNames[40] := 'arrependimento';
  MonthNames[41] := 'Babilónia';
  MonthNames[42] := 'língua';
  MonthNames[43] := 'linho';
  MonthNames[44] := 'sal';
  MonthNames[45] := 'pera';
  MonthNames[46] := 'arco';
  MonthNames[47] := 'areia';

  Frozen := True;
end;

function CutletNameByCanonicalIndex(Index: Integer): UnicodeString;
begin
  if (Index < 1) or (Index > CUTLET_NAME_COUNT) then
    raise ERangeError.Create('Índice canónico de costeleta fora do intervalo.');
  Result := CutletNames[Index];
end;

function MonthNameByCanonicalIndex(Index: Integer): UnicodeString;
begin
  if (Index < 1) or (Index > MONTH_NAME_COUNT) then
    raise ERangeError.Create('Índice canónico de mês fora do intervalo.');
  Result := MonthNames[Index];
end;

function SourceLanguageCatalogIsFrozen: Boolean;
begin
  Result := Frozen;
end;

function SourceLanguageCatalogSelfCheck: Boolean;
var
  I, J: Integer;
begin
  Result := Frozen;
  if not Result then Exit;
  for I := 1 to CUTLET_NAME_COUNT do
  begin
    if CutletNames[I] = '' then Exit(False);
    for J := I + 1 to CUTLET_NAME_COUNT do
      if CutletNames[I] = CutletNames[J] then Exit(False);
  end;
  for I := 1 to MONTH_NAME_COUNT do
  begin
    if MonthNames[I] = '' then Exit(False);
    for J := I + 1 to MONTH_NAME_COUNT do
      if MonthNames[I] = MonthNames[J] then Exit(False);
  end;
  Result := True;
end;

initialization
  InitializeCatalog;

end.
