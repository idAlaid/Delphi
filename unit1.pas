unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, StdCtrls,
  ExtCtrls, Types;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Label1: TLabel;
    Label2: TLabel;
    LabeledEdit1: TLabeledEdit;
    LabeledEdit2: TLabeledEdit;
    StringGrid1: TStringGrid;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure LabeledEdit1KeyPress(Sender: TObject; var Key: char);
    procedure LabeledEdit2KeyPress(Sender: TObject; var Key: char);
    procedure StringGrid1DrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure StringGrid1KeyPress(Sender: TObject; var Key: char);
  private

  public

  end;

  TPossibleNumbers = Record {запись с элементам [0-(n-1)] с пометкой возможности использования в данной ячейке}
      Number: Byte;
      IsPos: Boolean;
    end;

    TElements = array of TPossibleNumbers;{маасив возможных элеметов для каждой ячейки}
    TSudoku = array of array of Byte;{массив с судоку}
    TPosSudoku = array of TElements;{судоку с возможныыми элеметами}

  var
    Form1: TForm1;
    OK: Boolean = False;{переменная, разрешающая отрисовку StringGrid'a по правилу(см. конец проги)}
    Sudoku, Sudoku1{для выхода из демнострции решения и для того, что бы хранить ячейки, заполненные пользователем}: TSudoku;{массив с судоку}
    ArrOfSudoku: array of TSudoku;{массив судоку(массив решений)}
    l{номер отображаемого судоку}: Integer;
    n: Integer = 9;{порядок судоку}
    PosSudoku: array of TPosSudoku;{судоку, в ячейках которой запись, в которой отображаются возможные элементы ячейки}

implementation

{$R *.lfm}

procedure CopyMasToMas(var A, B: TSudoku);{копирование одного массива в другой}
var
  i,j: Integer;
begin
  for i := 0 to Length(A)-1 do
    for j := 0 to Length(A)-1 do
      A[i,j]:= B[i,j];
end;

function CheckSudoku(var strngrd1: TStringGrid): Boolean;{проверка есть ли повторяющиеся эл-ты в строках/столбцах, если успешно, то TRUE}
var
  j,k,z: Integer;
begin
  for j := 0 to n-1 do
    for k := 0 to n-1 do
      if (strngrd1.Cells[k,j] <> '') and (StrToInt(strngrd1.Cells[k,j]) > n) then
      begin{проверка, что б юзер не ввел в StringGrid число более n-1}
        strngrd1.Col:= k;
        strngrd1.Row:= j;
        Result:= False;
        ShowMessage('Данные в этой ячейке введены не корректно!');
        Exit;
      end;
  {проверка по сторокам}
  for z := 0 to n-1 do{строка, в которой сравниваемый элемент}
   for k := 0 to n-1 do{столбец, в котором сравниваемы элмент}
      for j := k+1 to n-1 do {столбец, для пробега по строке(пробег по
остальным элементам строки)}
        if (strngrd1.Cells[k,z] <> '') and (strngrd1.Cells[k,z] = strngrd1.Cells[j,z]) then begin{если ячейки равный то, выводим ошибку}
          Result:= False;
          ShowMessage('Данные введены не корректно!');
          Exit;
        end;
  {проверка по столбцам}
  for z := 0 to n-1 do{столбец, в котором сравниваемы элемент}
    for k := 0 to n-1 do{строка, в которой сравниваемый элемент}
      for j := k+1 to n-1 do {строка для пробега по столбцу(пробег по
остальным элементам столбца)}
        if (strngrd1.Cells[z,k] <> '') and (strngrd1.Cells[z,k] = strngrd1.Cells[z,j]) then begin{если ячейки равный то, выводим ошибку}
          Result:= False;
          ShowMessage('Данные введены не корректно!');
          Exit;
        end;
  Result:= True;
end;

procedure FillSudoku(strngrd1: TStringGrid);{заполнение судоку для начала поиска решений}
var
  i,j: Integer;
begin
  SetLength(Sudoku,n,n);{установка размеров}
  SetLength(Sudoku1,n,n);
  for i := 0 to n-1 do begin
    for j := 0 to n-1 do
      if strngrd1.Cells[j,i] = '' then{если пользователь не написал число в судоку, то}
        Sudoku[i,j]:= 100{заполняем сотнями}
      else Sudoku[i,j]:= StrToInt(strngrd1.Cells[j,i])-1;
  end;
  CopyMasToMas(Sudoku1, Sudoku);{создание копии начального судоку(хранение введенных юзером элементов)}
end;

procedure SudokuToStrngGrd(const A: TSudoku; var strngrd1: TStringGrid);{вывод Судоку в StrngGrid}
var
  i,j: Integer;
begin
  strngrd1.ColCount:= n;{кол-во столбцов}
  strngrd1.RowCount:= n;{кол-во строк}
  for i := 0 to n-1 do
    for j := 0 to n-1 do begin
      strngrd1.Cells[j,i]:= IntToStr(A[i,j]+1);{копирование ячеек}
    end;
end;

procedure FillPosSudoku();{Начальное заполнение PosSudoku}
var
  i,j,k: Integer;
begin
  for i := 0 to n-1 do
    for j := 0 to n-1 do
      for k := 0 to n-1 do begin
        PosSudoku[i,j,k].IsPos:= True;{изначально все элементы доступны}
        PosSudoku[i,j,k].Number:= k;{заполнение возможных элементов}
      end;
end;

procedure UpdatePosSudoku(ii{строка}, jj{столбец}: Integer);{исключение значений, которые нельзя добавить в ячейку [ii,jj]}
var
 i,j,a,b,k: Integer;
begin
  {------------------------------------------------------------------------------------}

  {------------------------------------------------------------------------------------}
  if ii = jj then  {если на главной диагонали}
    for k:= 0 to ii-1 do
      PosSudoku[ii, jj, Sudoku[k, k]].IsPos:= False;
  if ii = n-1-jj then {если на побочной диагонали}
    for k:= 0 to ii-1 do
      PosSudoku[ii, jj, Sudoku[k, n-1-k]].IsPos:= False;
  {------------------------------------------------------------------------------------}

  {------------------------------------------------------------------------------------}
  {пробег по строке}
  for i:= 0 to n-1 do
    if Sudoku[ii, i] <> 100 then
      PosSudoku[ii, jj, Sudoku[ii, i]].IsPos:= False;
  {пробег по столбцам}
  for i:= 0 to n-1 do
    if Sudoku[i, jj] <> 100 then
      PosSudoku[ii, jj, Sudoku[i, jj]].IsPos:= False;
  if n = sqr(Trunc(sqrt(n))) then
  begin{если поле делится на подполя, то пробегаем по ячейкам, которые входят в подполе}
a:= ii div Trunc(sqrt(n));
b:= jj div Trunc(sqrt(n));
for i := a*Trunc(sqrt(n)) to (a+1)*Trunc(sqrt(n)-1) do
for j := b*Trunc(sqrt(n)) to (b+1)*Trunc(sqrt(n)-1) do
if Sudoku[i, j] <> 100 then
PosSudoku[ii, jj, Sudoku[i, j]].IsPos:= False;
end;
end;
procedure SearchTDS(ii, jj: integer; Rect: TRect);
var
 i,j:integer;
 begin
    begin
      //for i := 0 to n-1 do
      //    for j := i+1 to n-1 do
      //        if (StringGrid1.Cells[0,i] = StringGrid1.Cells[ii,jj+1]) then
      //        StringGrid1.Canvas.Brush.Color:=clRed
      //
    end;
 end;

{Поиск осуществляется с 0-ой строчки, и идет построчно([0,0], [0,1],...), заполняя каждую ячейкку,
  за каждую ячейку отвечает один шаг рекурсии}
procedure Search(ii, jj: Byte);{поиск возможных заполнений судоку(РЕКУРСИЯ)}
var
  i: Integer;
begin
  if Sudoku[ii, jj] <> 100 then
  begin
    if (jj = n-1) and (ii = n-1) then begin{если это полседняя ячейка судоку}
        SetLength(ArrOfSudoku, Length(ArrOfSudoku)+1, n, n);
        CopyMasToMas(ArrOfSudoku[Length(ArrOfSudoku)-1], Sudoku);{добавляем это решение в список решений}
    end
    else
      if jj = n-1 then{если это последняя ячейка строки}
        Search(ii+1, 0){начинаем заполнение следующей ячейки(она в новой строке)}
      else
        Search(ii, jj+1);{если это не последняя ячейка в строке или в самой судоку}
    Exit;
  end;
  UpdatePosSudoku(ii,jj);{обновление возможных элементов для [ii,jj] ячейки судоку}
  for i := 0 to n-1 do begin{пробег по возможным элементам [0..n-1]}
    if PosSudoku[ii,jj,i].IsPos = True then begin{если элементом можно заполнить ячейку}
      Sudoku[ii, jj]:= PosSudoku[ii,jj,i].Number;{заполняем}
      PosSudoku[ii,jj,i].IsPos:= False;{помечаем, что его нельзя уже использовать}
      if (jj = n-1) and (ii = n-1) then begin{если это полседняя ячейка судоку, то}
        SetLength(ArrOfSudoku, Length(ArrOfSudoku)+1, n, n);
        CopyMasToMas(ArrOfSudoku[Length(ArrOfSudoku)-1], Sudoku);{добавляем это решение в список решений}
      end
      else
        if jj = n-1 then{если это последняя ячейка строки}
          Search(ii+1, 0){начинаем заполнение следующей ячейки(она в новой строке)}
        else
          Search(ii, jj+1);{если это не последняя ячейка а строке или в самой судоку}
    end;
  end;
  {код ниже для того, чтобы подчистить следы после выхода из этой процедуры, т.к после выхода рекурсия преходит на ячейку назад и в ней меняет значение}
  for i := 0 to n-1 do
    PosSudoku[ii,jj,i].IsPos:= True;{помечаем, что все элементы данной ячеки возможны}
  if Sudoku1[ii, jj] = 100 then {если этот элемент не задавал пользователь, то}
    Sudoku[ii,jj]:= 100;{помечаем, что этого элемента нет}
end;

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);{Кнопка поиск}
begin
  {наводим красоту на форме}
  OK:= False;
  Button3.Visible:= False;
  Label2.Caption:= '';
  {решение и подготовка к нему}
  n:= StrToInt(LabeledEdit1.Text);{берем порядок судоку}
  if not (CheckSudoku(StringGrid1)) then Exit;{проверка корректности введенных пользователем данных}
  SetLength(ArrOfSudoku,0,0,0);{затираем решения}
  FillSudoku(StringGrid1);{заполняем судоку для начала поиска}
  SetLength(PosSudoku, n, n, n);{устанавливаем длину массива с возможными элементами судоку}
  FillPosSudoku();{Начальное заполнение PosSudoku}
  Search(0,0);{Запуск поика решений судоку}
  ShowMessage('Найдено '+IntToStr(Length(ArrOfSudoku))+'!');{выводим кол-во решений}
  if Length(ArrOfSudoku) > 0 then begin{если нашли решения, наводим красоту на форме}
    Button2.Caption:= 'Показать Судоку';
    Button2.Visible:= True;
    Button4.Visible:= True;
    Label2.Visible:= True;
    l:= 1;
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);{Показать решения}
begin
  {наводим красоту формы}
  if l > Length(ArrOfSudoku) then l:= 1;
  OK:= True;
  Button3.Visible:= True;
  LabeledEdit2.Visible:= True;
  Button1.Enabled:= False;
  LabeledEdit1.Enabled:= False;
  StringGrid1.Enabled := False;
  Label2.Caption:= IntToStr(l) + '/' + IntToStr(Length(ArrOfSudoku));
  {вывод судоку}
  SudokuToStrngGrd(ArrOfSudoku[l-1], StringGrid1);{вывод судоку в стринггрид}
  Button2.Caption:= 'Следующая Судоку';
  Inc(l);
  if l > Length(ArrOfSudoku) then l:= 1;
end;

procedure TForm1.Button3Click(Sender: TObject);{завершить демонстрацию решений}
var
  i,j: Integer;
begin
  {отключаем элементы, прячем кнопки}
  Button1.Enabled:= True;
  LabeledEdit1.Enabled:= True;
  StringGrid1.Enabled := True;
  Button2.Visible:= False;
  Button4.Visible:= False;
  LabeledEdit2.Visible:= False;
  OK:= False;
  {возвращаем то, что ввел пользователь}
  for i := 0 to n-1 do
    for j := 0 to n-1 do
      if Sudoku1[i,j] = 100 then
        StringGrid1.Cells[j,i]:= ''
      else
        StringGrid1.Cells[j,i]:= IntToStr(Sudoku1[i,j]);
  {прячем эту кнопку}
  Label2.Visible:= False;
  Button3.Visible:= False;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin

end;

procedure TForm1.LabeledEdit1KeyPress(Sender: TObject; var Key: char);
begin
  if not(Key in ['1'..'9', #8{backspace}, #13{enter}])then Key:=#0{ничкакой символ}
  else if (Key in ['1'..'9']) then begin
    StringGrid1.ColCount:= StrToInt(Key);{меняем размер СтрингГрида}
    StringGrid1.RowCount:= StringGrid1.ColCount;
    {красота формы}
    LabeledEdit1.Text:= '';
    Button2.Visible:= False;
    Button4.Visible:= False;
    Label2.Caption:= '';
    n:= StrToInt(Key);
  end;
end;

procedure TForm1.LabeledEdit2KeyPress(Sender: TObject; var Key: char);
begin
  if not(Key in ['1'..'9', #8{backspace}, #13{enter}])then Key:=#0;{никакой символ}
  if Key = #13 then {если нажали enter}
    if (StrToInt(LabeledEdit2.Text) > Length(ArrOfSudoku)) then begin{если ввели число больше кол-ва решений}
      ShowMessage('Всего ' + IntTOStr(Length(ArrOfSudoku)) + '!');
      Exit;
    end
    else begin
      l:= StrToInt(LabeledEdit2.Text);{меняем номер отображаемого решения}
      Label2.Caption:= IntToStr(l) + '/' + IntToStr(Length(ArrOfSudoku));
      SudokuToStrngGrd(ArrOfSudoku[l-1], StringGrid1);{перевод судоку в стринггрид}
      Button2.Caption:= 'Следующая Судоку';
      Inc(l);
    end;
end;

procedure TForm1.StringGrid1DrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
var
  i,j: Integer;
begin
  if OK then{если мы нашли решения, то ОК становится ТРУ и поэтому выделяем яейки, введенные пользователем}
    if Length(Sudoku1) <> 0 then begin {если длина Sudoku1 не = 0(без нее сыпятся ошибки при запуске проги)}
      StringGrid1.Canvas.Brush.Color:= clLime;{цвет}
      for i := 0 to n-1 do
        for j := 0 to n-1 do
          if Sudoku1[i,j] <> 100 then{если эта ячейка, которую ввел юзер}
            if ((ACol = j)and( ARow = i)) then begin{если она совпала с данной ячейкой StringGrid'a(то есть при перерисовке стринггрида перерисовывается каждая ячейка, а номер перерисовываемой ACol(столбец) ARow(строка))}
              StringGrid1.Canvas.FillRect(aRect);{красим прямоугольником}
              StringGrid1.Canvas.TextOut(aRect.Left + 1, aRect.Top + 8 , StringGrid1.Cells[ACol, ARow]);{выводим текст поверх прямоугольника}
            end;
    end;
end;

procedure TForm1.StringGrid1KeyPress(Sender: TObject; var Key: char);
begin
if not(Key in ['1'..'9', #8{backspace}, #13{enter}])then Key:=#0{никакой символ} {Если цифра, то пропускаем ее}
  else if (Key in ['1'..'9']) then StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row]:= '';{удаляем текст из ячейки стринггрида, т.к. после звершения этой процедуры в ячейку добавится значение Key}
end;

end.

