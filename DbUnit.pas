{
������ ���������� ���� ������.

!! � TDbItem ������ �������� ������ ������������

}
unit DbUnit;

interface
uses SysUtils, Classes, Contnrs;

type
  TDbTableInfo = class;

  { TDbFieldInfo }
  TDbFieldInfo = class(TInterfacedObject)
  public
    // Name
    FieldName: string;
    // Type
    FieldType: string;
    // Descriptin
    FieldDescription: string;
    // Field belongs to this table info
    TableInfo: TDbTableInfo;
    // Field contain ID for MasterTable element
    MasterTable: TDbTableInfo;
  end;


  { TDbTableInfo }
  // ���������� � ������� ��
  // - �������� � �������� � ����� ������ � ��������
  // - �������� �������
  TDbTableInfo = class(TInterfacedObject)
  private
    FFields: TObjectList;
    function GetField(Index: integer): TDbFieldInfo;
    function GetFieldName(Index: integer): string;
    function GetFieldType(Index: integer): string;
    function GetFieldsCount(): integer;
  public
    DBName: string; // ��� ���� ������
    TableName: string; // ��� �������
    TableDescription: string; // �������� �������
    KeyFieldName: string; // ��� ��������� ���� (ID)
    // �������, ����, ��� ������� ������������� ������ ������� � ���� ������
    Valid: boolean;
    constructor Create();
    destructor Destroy(); override;
    // ������ ����� �������
    property Fields[Index: integer]: TDbFieldInfo read GetField;
    // ������ ���� ����� �������
    property Names[Index: integer]: string read GetFieldName;
    // ������ ����� ����� �������
    property Types[Index: integer]: string read GetFieldType;
    // ���������� �����
    property FieldsCount: integer read GetFieldsCount;
    // ������� ���� � �������� ������ � �����
    function AddField(const FieldName, FieldType: string): TDbFieldInfo;
    // �������� ���� � �������� ��������, ������ ����� ��� � ���
    procedure ModifyField(const Index: Integer; const FieldName, FieldType: string);
    // Remove field from table
    procedure DeleteField(const FieldName: string);
    // ���������� ����� ���� �� ��� �����
    function FieldIndex(AName: string): Integer;
  end;

  // ������� ������� ��, ���� ��� �������
  TDbItem = class(TInterfacedObject)
  private
    // ������ �������� (�����) ��������
    FValues: array of string;
    // �������������� ������ ��������, ��������� �� ������� ����������
    procedure InitValues();
  protected
    procedure GetLocal();
    procedure SetLocal();
    procedure GetGlobal();
    procedure SetGlobal();
  public
    ID: integer;  // ������������� ��������
    Name: string; // ��������� ������������� ��������
    Actual: boolean; // ������� ������������ ������ �������� � ��
    TimeStamp: TDateTime; // ���� ���������� ���������
    DbTableInfo: TDbTableInfo; // ���������� � �������
    // ���������� �������� �� ����� �������
    // ����� ���� �������������� � ��������
    function GetValue(const FName: string): string; virtual;
    // ���������� DBItem �� ����� �������
    // ������ ���� �������������� � ��������
    //function GetDBItem(FName: string): TDBItem; virtual;
    // ������������� �������� �� ����� �������
    // ����� ���� �������������� � ��������
    procedure SetValue(const FName, FValue: string); virtual;
    // ������ � �������� ���� �� ��� �����
    property Values[const FName: string]: string read GetValue write SetValue; default;
    //
    function GetInteger(const FName: string): integer;
    procedure SetInteger(const FName: string; Value: integer);
  end;

  TDbDriver = class;

  // ������ ���������� ��������� ���� ������
  // ����� ������ - �������
  TDbItemList = class(TObjectList)
  protected
    ALastID: integer;
  public
    DbDriver: TDbDriver;
    DbTableInfo: TDbTableInfo;
    constructor Create(ADbTableInfo: TDbTableInfo); virtual;
    function AddItem(AItem: TDbItem; SetNewID: boolean = false): integer;
    function GetItemByID(ItemID: integer): TDbItem;
    function GetItemByName(ItemName: string; Wildcard: Boolean = false): TDbItem;
    function GetItemIDByName(ItemName: string; Wildcard: Boolean = false): Integer;
    function GetItemNameByID(ItemID: integer): string;
    function NewItem(): TDbItem; virtual;
    procedure LoadLocal();
    procedure SaveLocal();
  end;

  // ������� ���� ������ - ��� ������� � ��������� ������
  // ��� ������� �����, ������ ���� �������������� ��� ���������� ����� ��
  TDbDriver = class(TInterfacedObject)
  private
    FOnDebugSQL: TGetStrProc;
  public
    DbName: string;
    // ������ �������� ������ TDbTableInfo
    TablesList: TObjectList;
    constructor Create();
    destructor Destroy(); override;
    // ��������� ��������� ���� ������
    function Open(ADbName: string): boolean; virtual; abstract;
    // ��������� ��������� ���� ������
    function Close(): boolean; virtual; abstract;
    // ���������� �������� ������� �� �� �����
    function GetDbTableInfo(TableName: String): TDbTableInfo;
    // ��������� ��������� ������� ���������� �� ���� ������, �� ��������� �������
    // ������ � ���� comma-delimited string ��� ����=��������
    function GetTable(AItemList: TDbItemList; Filter: string=''): boolean; virtual; abstract;
    // ��������� ���� ������ ���������� �� ��������� �������, �� ��������� �������
    function SetTable(AItemList: TDbItemList; Filter: string=''): boolean; virtual; abstract;
    // ���������� DBItem �� �������� ���� Table_name~id
    // ������ ���� �������������� � ��������
    function GetDBItem(FValue: string): TDBItem; virtual; abstract;
    function SetDBItem(FItem: TDBItem): boolean; virtual; abstract;
    // Triggers before SQL statement executed, return SQL text
    property OnDebugSQL: TGetStrProc read FOnDebugSQL write FOnDebugSQL;
  end;

  TDbDriverCSV = class(TDbDriver)
  private
    dbPath: string;
    procedure CheckTable(TableInfo: TDbTableInfo);
  public
    function Open(ADbName: string): boolean; override;
    function Close(): boolean; override;
    function GetTable(AItemList: TDbItemList; Filter: string=''): boolean; override;
    function SetTable(AItemList: TDbItemList; Filter: string=''): boolean; override;
    function GetDBItem(FValue: string): TDBItem; override;
    function SetDBItem(FItem: TDBItem): boolean; override;
  end;

implementation

// === TDbTableInfo ===
function TDbTableInfo.GetField(Index: integer): TDbFieldInfo;
begin
  Result:=nil;
  if (Index >= FieldsCount) or (Index < 0) then Exit;
  Result:=(FFields[Index] as TDbFieldInfo);
end;

function TDbTableInfo.GetFieldName(Index: integer): string;
begin
  Result:='';
  if (Index >= FieldsCount) or (Index < 0) then Exit;
  Result:=(FFields[Index] as TDbFieldInfo).FieldName;
end;

function TDbTableInfo.GetFieldType(Index: integer): string;
begin
  Result:='';
  if (Index >= FieldsCount) or (Index < 0) then Exit;
  Result:=(FFields[Index] as TDbFieldInfo).FieldType;
end;

function TDbTableInfo.GetFieldsCount(): integer;
begin
  Result:=Self.FFields.Count;
end;

function TDbTableInfo.AddField(const FieldName, FieldType: string): TDbFieldInfo;
var
  i: Integer;
begin
  for i:=0 to FFields.Count-1 do
  begin
    Result:=(FFields[i] as TDbFieldInfo);
    if Result.FieldName = FieldName then Exit;
  end;

  Result:=TDbFieldInfo.Create();
  Result.FieldName:=FieldName;
  Result.FieldType:=FieldType;
  Result.TableInfo:=Self;
  FFields.Add(Result);
end;

procedure TDbTableInfo.ModifyField(const Index: Integer; const FieldName,
  FieldType: string);
var
  s: string;
  TmpField: TDbFieldInfo;
begin
  if (Index >= FFields.Count) or (Index < 0) then Exit;
  TmpField:=(FFields[Index] as TDbFieldInfo);
  TmpField.FieldName:=FieldName;
  s:=FieldType;
  if Length(s) < 1 then s:='S';
  TmpField.FieldType:=s;
end;

procedure TDbTableInfo.DeleteField(const FieldName: string);
var
  i: Integer;
begin
  i:=FieldIndex(FieldName);
  if i <> -1 then Self.FFields.Delete(i);
end;

function TDbTableInfo.FieldIndex(AName: string): Integer;
var
  i: Integer;
begin
  Result:=-1;
  for i:=0 to FFields.Count do
  begin
    if GetFieldName(i) = AName then
    begin
      Result:=i;
      Exit;
    end;
  end;
end;

constructor TDbTableInfo.Create();
begin
  inherited Create();
  Self.FFields:=TObjectList.Create(False);
  Self.Valid:=False;
  AddField('id','I');
  AddField('name','S');
  AddField('timestamp','D');
end;

destructor TDbTableInfo.Destroy();
begin
  FreeAndNil(Self.FFields);
  inherited Destroy();
end;

// === TDbItem ===
procedure TDbItem.GetLocal();
begin
end;

procedure TDbItem.SetLocal();
begin
end;

procedure TDbItem.GetGlobal();
begin
end;

procedure TDbItem.SetGlobal();
begin
end;

procedure TDbItem.InitValues();
var i: Integer;
begin
  SetLength(Self.FValues, Self.DbTableInfo.FieldsCount);
  for i:=0 to Self.DbTableInfo.FieldsCount-1 do Self.FValues[i]:='';
end;

function TDbItem.GetValue(const FName: string): string;
var i: Integer;
begin
  if FName='id' then
    Result:=IntToStr(self.ID)
  else if FName='timestamp' then
    Result:=DateTimeToStr(self.Timestamp)
  else if FName='name' then
    Result:=self.Name
  else
  begin
    if Length(Self.FValues)=0 then InitValues();
    i:=Self.DbTableInfo.FieldIndex(FName);
    if i<0 then Result:='' else Result:=Self.FValues[i];
  end;
end;

//function TDbItem.GetDBItem(FName: string): TDBItem;
//begin
//  result:=nil;
//  if FName='id' then result:=self;
//end;

procedure TDbItem.SetValue(const FName, FValue: string);
var i: Integer;
begin
  if FName='id' then
    self.ID:=StrToIntDef(FValue, 0)
  else if FName='timestamp' then
    self.Timestamp:=StrToDateTimeDef(FValue, self.Timestamp)
  else if FName='name' then
    self.Name:=FValue
  else
  begin
    if Length(Self.FValues)=0 then InitValues();
    i:=Self.DbTableInfo.FieldIndex(FName);
    if i>=0 then Self.FValues[i]:=FValue;
  end;
end;

function TDbItem.GetInteger(const FName: string): integer;
begin
  result:=StrToIntDef(self.GetValue(FName), 0);
end;

procedure TDbItem.SetInteger(const FName: string; Value: integer);
begin
  self.SetValue(FName, IntToStr(Value));
end;

// === TDbItemList ===
constructor TDbItemList.Create(ADbTableInfo: TDbTableInfo);
begin
  Self.DbDriver:=nil;
  Self.DbTableInfo:=ADbTableInfo;
end;

procedure TDbItemList.LoadLocal();
begin
  if Assigned(DbDriver) then DbDriver.GetTable(self);
end;

procedure TDbItemList.SaveLocal();
begin
  if Assigned(DbDriver) then DbDriver.SetTable(self);
end;

function TDbItemList.AddItem(AItem: TDbItem; SetNewID: boolean = false): integer;
begin
  if SetNewID then
  begin
    Inc(self.ALastID);
    AItem.ID:=self.ALastID;
  end
  else
  begin
    if self.ALastID < AItem.ID then self.ALastID := AItem.ID;
  end;
  AItem.DbTableInfo:=self.DbTableInfo;
  result:=self.Add(AItem);
end;

function TDbItemList.GetItemByID(ItemID: integer): TDbItem;
var
  i: integer;
begin
  for i:=0 to self.Count-1 do
  begin
    if (self.Items[i] as TDbItem).ID = ItemID then
    begin
      result := (self.Items[i] as TDbItem);
      Exit;
    end;
  end;
  result := nil;
end;

function TDbItemList.GetItemByName(ItemName: string; Wildcard: Boolean = false): TDbItem;
var
  i: integer;
begin
  if Wildcard then
  begin
    for i:=0 to self.Count-1 do
    begin
      if Pos(ItemName, (self.Items[i] as TDbItem).Name) > 0 then
      begin
        result := (self.Items[i] as TDbItem);
        Exit;
      end;
    end;
  end

  else
  begin
    for i:=0 to self.Count-1 do
    begin
      if (self.Items[i] as TDbItem).Name = ItemName then
      begin
        result := (self.Items[i] as TDbItem);
        Exit;
      end;
    end;
  end;
  result := nil;
end;

function TDbItemList.GetItemIDByName(ItemName: string; Wildcard: Boolean = false): Integer;
var
  Item: TDbItem;
begin
  Result:=-1;
  Item:=Self.GetItemByName(ItemName, Wildcard);
  if Assigned(Item) then Result:=Item.ID;
end;

function TDbItemList.GetItemNameByID(ItemID: integer): string;
var
  Item: TDbItem;
begin
  Result:='';
  Item:=Self.GetItemByID(ItemID);
  if Assigned(Item) then Result:=Item.Name;
end;

function TDbItemList.NewItem(): TDbItem;
begin
  Result:=TDbItem.Create();
  self.AddItem(Result, True);
end;

// === TDbDriver ===
constructor TDbDriver.Create();
begin
  self.TablesList:=TObjectList.Create(false);
end;

destructor TDbDriver.Destroy();
begin
  self.Close();
  self.TablesList.Free();
end;

function TDbDriver.GetDbTableInfo(TableName: String): TDbTableInfo;
var
  i: integer;
begin
  Result:=nil;
  for i:=0 to Self.TablesList.Count-1 do
  begin
    if (Self.TablesList[i] as TDbTableInfo).TableName = TableName then
    begin
      Result:=(Self.TablesList[i] as TDbTableInfo);
      Exit;
    end;
  end;
end;

// === TDbDriverCSV ===
function TDbDriverCSV.Open(ADbName: string): boolean;
begin
  self.DbName:=ADbName;
  self.dbPath:=ExtractFileDir(ParamStr(0))+'\Data\';
  result:=true;
end;

function TDbDriverCSV.Close(): boolean;
begin
  result:=true;
end;

procedure TDbDriverCSV.CheckTable(TableInfo: TDbTableInfo);
begin
  if TableInfo.Valid then Exit;
  if Self.TablesList.IndexOf(TableInfo)>=0 then Exit;

  TableInfo.Valid:=true;
  Self.TablesList.Add(TableInfo);
end;

function TDbDriverCSV.GetTable(AItemList: TDbItemList; Filter: string=''): boolean;
var
  sl, vl, fl: TStringList;
  i, n, m, id: integer;
  Item: TDbItem;
  fn: string;
  FilterOk: boolean;
begin
  result:=false;
  if not Assigned(AItemList) then Exit;
  CheckTable(AItemList.DbTableInfo);
  fn:=self.dbPath+'\'+AItemList.DbTableInfo.TableName+'.lst';
  if not FileExists(fn) then Exit;
  sl:=TStringList.Create();
  try
    sl.LoadFromFile(fn);
  except
    sl.Free();
    Exit;
  end;

  vl:=TStringList.Create(); // row values
  fl:=TStringList.Create(); // filters
  fl.CommaText:=Filter;

  // ������ ������ - ������ �������!
  for i:=1 to sl.Count-1 do
  begin
    vl.Clear();
    vl.CommaText:=StringReplace(sl[i], '~>', #13+#10, [rfReplaceAll]);
    if vl.Count=0 then Continue;
    if vl.Count < AItemList.DbTableInfo.FieldsCount then Continue; //!!

    // check filters
    FilterOk:=true;
    if fl.Count>0 then
    begin
      for n:=0 to AItemList.DbTableInfo.FieldsCount-1 do
      begin
        fn:=AItemList.DbTableInfo.GetFieldName(n);
        for m:=0 to fl.Count-1 do
        begin
          if fl.Names[m]=fn then
          begin
            if fl.ValueFromIndex[m]<>vl[n] then FilterOk:=false;
            Break;
          end;
        end;
      end;
    end;

    if not FilterOk then Continue;
    // Create new item
    id:=StrToInt(vl[0]);
    Item := AItemList.GetItemByID(id);
    if not Assigned(Item) then Item:=AItemList.NewItem();

    // fill item values
    for n:=0 to AItemList.DbTableInfo.FieldsCount-1 do
    begin
      fn:=AItemList.DbTableInfo.GetFieldName(n);
      Item.SetValue(fn, vl[n]);
    end;
  end;
  fl.Free();
  vl.Free();
  sl.Free();
  result:=true;
end;

function TDbDriverCSV.SetTable(AItemList: TDbItemList; Filter: string=''): boolean;
var
  sl, vl: TStringList;
  i, n: integer;
  Item: TDbItem;
  fn: string;
begin
  result:=false;
  if not Assigned(AItemList) then Exit;
  CheckTable(AItemList.DbTableInfo);

  sl:=TStringList.Create();
  vl:=TStringList.Create();

  // columns headers
  for n:=0 to AItemList.DbTableInfo.FieldsCount-1 do
  begin
    fn:=AItemList.DbTableInfo.GetFieldName(n);
    vl.Add(fn);
  end;
  sl.Add(vl.CommaText);

  // rows
  for i:=0 to AItemList.Count-1 do
  begin
    vl.Clear();
    Item:=(AItemList[i] as TDbItem);
    for n:=0 to AItemList.DbTableInfo.FieldsCount-1 do
    begin
      fn:=AItemList.DbTableInfo.GetFieldName(n);
      vl.Add(Item.GetValue(fn));
    end;
    sl.Add(StringReplace(vl.CommaText, #13+#10, '~>', [rfReplaceAll]));
  end;

  vl.Free();
  try
    sl.SaveToFile(self.dbPath+'\'+AItemList.DbTableInfo.TableName+'.lst');
  finally
    sl.Free();
  end;

end;

function TDbDriverCSV.GetDBItem(FValue: String): TDbItem;
var
  sTableName, sItemID, fn, sql: string;
  i: Integer;
  TableInfo: TDbTableInfo;
  ItemList: TDbItemList;
  Filter: string;
begin
  Result:=nil;
  i:=Pos('~', FValue);
  sTableName:=Copy(FValue, 1, i-1);
  sItemID:=Copy(FValue, i+1, MaxInt);
  TableInfo:=Self.GetDbTableInfo(sTableName);
  if not Assigned(TableInfo) then Exit;

  ItemList:=TDbItemList.Create(TableInfo);
  Filter:='id='+sItemID;

  if not GetTable(ItemList, Filter) then Exit;
  if ItemList.Count=0 then Exit;
  result:=(ItemList[0] as TDbItem);
end;

function TDbDriverCSV.SetDBItem(FItem: TDBItem): boolean;
var
  AItemList: TDbItemList;
  AItem: TDbItem;
  i: Integer;
  fn: string;
begin
  Result:=False;
  AItemList:=TDbItemList.Create(FItem.DbTableInfo);
  Self.GetTable(AItemList);
  AItem:=AItemList.GetItemByID(FItem.ID);
  if not Assigned(AItem) then
  begin
    FreeAndNil(AItemList);
    Exit;
  end;
  for i:=0 to FItem.DbTableInfo.FieldsCount-1 do
  begin
    fn:=FItem.DbTableInfo.GetFieldName(i);
    AItem.Values[fn]:=FItem.Values[fn];
  end;
  Self.SetTable(AItemList);
  FreeAndNil(AItemList);
  result:=true;
end;

end.
