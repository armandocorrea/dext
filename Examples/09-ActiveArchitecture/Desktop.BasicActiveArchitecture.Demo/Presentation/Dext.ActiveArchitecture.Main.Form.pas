unit Dext.ActiveArchitecture.Main.Form;

interface

uses
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Comp.DataSet,
  FireDAC.DApt,
  FireDAC.DApt.Intf,
  FireDAC.DatS,
  FireDAC.Phys,
  FireDAC.Phys.Intf,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Phys.SQLiteWrapper.Stat,
  FireDAC.Stan.Async,
  FireDAC.Stan.Def,
  FireDAC.Stan.Error,
  FireDAC.Stan.ExprFuncs,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param,
  FireDAC.Stan.Pool,
  FireDAC.UI.Intf,
  FireDAC.VCLUI.Wait,
  System.Classes,
  System.SysUtils,
  Vcl.Controls,
  Vcl.DBGrids,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.Grids,
  Vcl.StdCtrls,
  Dext.Collections,
  Dext.Entity,
  Dext.Entity.DataProvider,
  Dext.Entity.DataSet,
  Dext.Entity.Drivers.Interfaces,
  Dext.ActiveArchitecture.Domain,
  Dext.ActiveArchitecture.Entities,
  Dext.ActiveArchitecture.ViewModels;

type
  TMainForm = class(TForm)
    EntityDataProvider: TEntityDataProvider;
    LogsMemo: TMemo;
    OrderDataSource: TDataSource;
    OrderDetailsDataSource: TDataSource;
    OrderDetailsEntityDataSet: TEntityDataSet;
    OrderDetailsGrid: TDBGrid;
    OrderEntityDataSet: TEntityDataSet;
    OrderGrid: TDBGrid;
    SqliteDemoConnection: TFDConnection;
    OrderDetailsEntityDataSetOrderId: TIntegerField;
    OrderDetailsEntityDataSetProductId: TIntegerField;
    OrderDetailsEntityDataSetUnitPrice: TCurrencyField;
    OrderDetailsEntityDataSetQuantity: TIntegerField;
    OrderDetailsEntityDataSetDiscount: TFloatField;
    OrderEntityDataSetOrderId: TIntegerField;
    OrderEntityDataSetCustomerId: TStringField;
    OrderEntityDataSetEmployeeId: TIntegerField;
    OrderEntityDataSetOrderDate: TDateTimeField;
    OrderEntityDataSetRequiredDate: TDateTimeField;
    OrderEntityDataSetShippedDate: TDateTimeField;
    OrderEntityDataSetShipVia: TIntegerField;
    OrderEntityDataSetFreight: TCurrencyField;
    OrderEntityDataSetShipName: TStringField;
    OrderEntityDataSetShipAddress: TStringField;
    OrderEntityDataSetShipCity: TStringField;
    OrderEntityDataSetShipRegion: TStringField;
    OrderEntityDataSetShipPostalCode: TStringField;
    OrderEntityDataSetShipCountry: TStringField;
  private
    FDbConnection: IDbConnection;
    FDbContext: TDbContext;
    FOrderDetails: IList<TOrderDetails>;
    FOrders: IList<TOrders>;
    FViewModel: TOrderViewModel;

    procedure CreateControls;
    procedure DoDiscountGetText(Sender: TField; var Text: string; DisplayText: Boolean);
    procedure DoFilterComboChange(Sender: TObject);
    procedure DoFormDestroy(Sender: TObject);
    procedure DoOrderDataSourceDataChange(Sender: TObject; Field: TField);
    procedure DoQuantityChange(Sender: TField);
    procedure LoadData;
  public
    procedure InjectDependencies(AViewModel: TOrderViewModel);
  end;

var
  MainForm: TMainForm;

implementation

uses
  System.Rtti,
  Dext.Entity.Drivers.FireDAC,
  Dext.Entity.Dialects,
  Dext.Specifications.Interfaces,
  Dext.Specifications.Base,
  Dext.Specifications.Types,
  Dext.ActiveArchitecture.Specifications,
  Dext.Logging,
  Dext.Logging.Global,
  Dext.Logging.Sinks.VCL,
  Dext.Logging.Tracing;

{$R *.dfm}

procedure TMainForm.CreateControls;
var
  FilterPanel: TPanel;
  FilterLabel: TLabel;
  FilterCombo: TComboBox;
begin
  // Criação dinâmica do Painel de Filtros (DDD Specifications Showcase)
  FilterPanel := TPanel.Create(Self);
  FilterPanel.Parent := Self;
  FilterPanel.Align := alTop;
  FilterPanel.Height := 45;
  FilterPanel.BevelOuter := bvNone;
  FilterPanel.BringToFront;

  FilterLabel := TLabel.Create(Self);
  FilterLabel.Parent := FilterPanel;
  FilterLabel.Left := 15;
  FilterLabel.Top := 15;
  FilterLabel.Caption := 'Filtrar por Especificação (DDD/Specification):';
  FilterLabel.Font.Name := 'Segoe UI';
  FilterLabel.Font.Style := [fsBold];

  FilterCombo := TComboBox.Create(Self);
  FilterCombo.Parent := FilterPanel;
  FilterCombo.Left := 280;
  FilterCombo.Top := 11;
  FilterCombo.Width := 480;
  FilterCombo.Style := csDropDownList;
  FilterCombo.Items.Add('Sem Filtro (Mostrar Todos os Pedidos)');
  FilterCombo.Items.Add('Especificação 1: Pedidos com Destino ao Brasil');
  FilterCombo.Items.Add('Especificação 2: Pedidos com Frete de Alto Valor (> R$ 50,00)');
  FilterCombo.Items.Add('Especificação 3: Pedidos do Brasil combinados com Frete Alto (> R$ 30,00)');
  FilterCombo.ItemIndex := 0;
  FilterCombo.OnChange := DoFilterComboChange;
end;

{ TMainForm }

procedure TMainForm.InjectDependencies(AViewModel: TOrderViewModel);
var
  InitSpan: TSpan;
begin
  FViewModel := AViewModel;

  // Vincula os eventos em runtime de forma segura para não corromper o arquivo DFM da IDE
  OnDestroy := DoFormDestroy;
  OrderDataSource.OnDataChange := DoOrderDataSourceDataChange;
  OrderDetailsEntityDataSetQuantity.OnChange := DoQuantityChange;
  OrderDetailsEntityDataSetDiscount.OnGetText := DoDiscountGetText;

  // Inicialização que antes ficava no FormCreate
  Self.Caption := 'Dext - Active Architecture';
  CreateControls;

  SqliteDemoConnection.ConnectionDefName := 'SQLite_Demo';
  SqliteDemoConnection.Connected := True;

  // 1. Inicializa o Dext Logger com o Memo Sink
  Log.AddSink(TMemoLogSink.Create(LogsMemo, 500));
  Log.Info('Dext Logging inicializado com TMemoLogSink!');

  // Inicializa o rastreamento da carga de dados
  InitSpan := TTracer.BeginSpan('MainForm.LoadData', 'Startup');
  try
    // 2. Criação do DbContext e conexão Dext
    FDbConnection := TFireDACConnection.Create(SqliteDemoConnection, False); // False = Não é dono da conexão, que é gerida pelo DFM/Form
    FDbContext := TDbContext.Create(FDbConnection, TSQLiteDialect.Create);

    // 2.1 Ativa o log da geração de SQL no DbContext
    FDbContext.OnLog :=
      procedure(ASql: string)
      begin
        Log.Info('SQL: ' + ASql);
      end;

    // Registrar entidades no contexto
    FDbContext.Entities<TOrders>;
    FDbContext.Entities<TOrderDetails>;

    LoadData;

    InitSpan.SetStatus('Success');
  except on E: Exception do
    begin
      InitSpan.SetStatus('Error', E.Message);
      raise;
    end;
  end;
  InitSpan.Finish;
end;

procedure TMainForm.DoFormDestroy(Sender: TObject);
begin
  OrderDetailsEntityDataSet.Close;
  OrderEntityDataSet.Close;

  FOrders := nil;
  FOrderDetails := nil;

  if Assigned(FDbContext) then
  begin
    FDbContext.Free;
    FDbContext := nil;
  end;

  FDbConnection := nil;

  if Assigned(FViewModel) then
    FViewModel.Free;
end;

procedure TMainForm.DoOrderDataSourceDataChange(Sender: TObject; Field: TField);
var
  Order: TOrders;
begin
  // Evita reentrada se a ViewModel já estiver calculando ou se não houver registros
  if not Assigned(FViewModel) or FViewModel.IsCalculating then
    Exit;

  Order := TOrders(OrderEntityDataSet.GetCurrentObject);
  if Assigned(Order) then
  begin
    // Se o frete já foi calculado (ou seja, não é zero), pulamos para economizar chamadas HTTP
    if Order.Freight.Value > 0.0 then
      Exit;

    FViewModel.Load(Order);

    // Atualiza o título da janela indicando o cálculo assíncrono em background (Zero UI Blocking!)
    Self.Caption := 'Calculando cotação de frete para ' + Order.ShipCountry.Value + ' (Assíncrono)...';

    FViewModel.CalcularFreteExterno(
      procedure
      begin
        // Callback executado na Main Thread de forma automática e segura pelo Dext!
        Self.Caption := 'Dext Framework - Delphi Connect Portugal - Clean Architecture VCL';
        // Recarrega a Grid para exibir o frete recém calculado e atualizado no domínio rico
        OrderEntityDataSet.RefreshRecord;
      end);
  end;
end;

procedure TMainForm.DoFilterComboChange(Sender: TObject);
var
  Spec: ISpecification<TOrders>;
  Span: TSpan;
  FilterName: string;
begin
  case TComboBox(Sender).ItemIndex of
    1: FilterName := 'TBrazilOrdersSpec';
    2: FilterName := 'TExpensiveFreightSpec(50.00)';
    3: FilterName := 'TBrazilHeavyFreightSpec(30.00)';
  else
    FilterName := 'Sem Filtro';
  end;

  Span := TTracer.BeginSpan('MainForm.ApplyFilter', 'UI');
  Span.SetAttribute('specification.name', FilterName);
  try
    case TComboBox(Sender).ItemIndex of
         // Pedidos do Brasil
      1: Spec := TBrazilOrdersSpec.Create;
         // Pedidos com Frete Alto (> R$ 50)
      2: Spec := TExpensiveFreightSpec.Create(50.00);
         // Brasil + Frete Alto (> R$ 30)
      3: Spec := TBrazilHeavyFreightSpec.Create(30.00);
    else
      // Sem Filtro
      Spec := nil;
    end;

    if Assigned(Spec) then
    begin
      OrderEntityDataSet.FilterExpression := Spec.GetExpression;
      Span.SetAttribute('filter.expression', OrderEntityDataSet.Filter);
    end
    else
    begin
      OrderEntityDataSet.FilterExpression := nil;
      Span.SetAttribute('filter.expression', '');
    end;

    Log.Info('Especificação aplicada! Filtro Ativo: "' + OrderEntityDataSet.Filter + '"');
    Span.SetStatus('Success');
  except on E: Exception do
    begin
      OrderEntityDataSet.FilterExpression := nil;
      Log.Error(E.ClassName + ' - ' + E.Message);
      Span.SetStatus('Error', E.Message);
    end;
  end;
  Span.Finish;
end;

procedure TMainForm.DoQuantityChange(Sender: TField);
var
  Detail: TOrderDetails;
  Span: TSpan;
begin
  Detail := TOrderDetails(OrderDetailsEntityDataSet.GetCurrentObject);
  if Assigned(Detail) then
  begin
    Span := TTracer.BeginSpan('MainForm.QuantityChange', 'UI');
    Span.SetAttribute('order.id', Detail.OrderId.Value);
    Span.SetAttribute('product.id', Detail.ProductId.Value);
    Span.SetAttribute('quantity.old', Detail.Quantity.Value);
    Span.SetAttribute('quantity.new', Sender.AsInteger);
    try
      // Sincroniza a quantidade com o objeto de domínio
      Detail.Quantity := Sender.AsInteger;
      
      // Roda a regra rica na própria entidade de domínio
      Detail.CalcularDescontoProgressivo;
      
      Span.SetAttribute('discount.value', FloatToStr(Detail.Discount.Value));
      
      // Atualiza o DataSet com o novo desconto para renderizar a Grid VCL instantaneamente
      OrderDetailsEntityDataSetDiscount.Value := Detail.Discount.Value;
      Span.SetStatus('Success');
    except on E: Exception do
      begin
        Span.SetStatus('Error', E.Message);
        raise;
      end;
    end;
    Span.Finish;
  end;
end;

procedure TMainForm.DoDiscountGetText(Sender: TField; var Text: string; DisplayText: Boolean);
begin
  if (not Sender.IsNull) and (Sender.AsFloat > 0.00) then
    Text := FormatFloat('0.0', Sender.AsFloat * 100.0) + ' %'
  else
    Text := '';
end;

procedure TMainForm.LoadData;
begin
  // 3. Carregar os dados na lista
  FOrders := FDbContext.Entities<TOrders>.ToList;
  FOrderDetails := FDbContext.Entities<TOrderDetails>.ToList;

  // 4. Configurar e popular o dataset mestre (TOrders)
  OrderEntityDataSet.Load<TOrders>(FOrders);
  OrderEntityDataSet.Open;
  OrderDataSource.DataSet := OrderEntityDataSet;

  // 5. Configurar e popular o dataset detalhe (TOrderDetails) mestre/detalhe
  OrderDetailsEntityDataSet.Load<TOrderDetails>(FOrderDetails);
  OrderDetailsEntityDataSet.MasterSource := OrderDataSource;
  OrderDetailsEntityDataSet.MasterFields := 'OrderId';
  OrderDetailsEntityDataSet.IndexFieldNames := 'OrderId';
  OrderDetailsEntityDataSet.Open;
  OrderDetailsDataSource.DataSet := OrderDetailsEntityDataSet;
end;

end.
