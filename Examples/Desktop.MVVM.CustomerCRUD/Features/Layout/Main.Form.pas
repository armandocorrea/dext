unit Main.Form;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.UITypes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Dext,
  Dext.Collections,
  Customer.Entity,
  Customer.Service,
  Customer.Controller,
  Customer.ViewModel,
  Customer.List,
  Customer.Edit;

type
  TMainForm = class(TForm, ICustomerView)
    MainPanel: TPanel;
    SidePanel: TPanel;
    ContentPanel: TPanel;
    LogoLabel: TLabel;
    BtnCustomers: TButton;
    BtnAbout: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnCustomersClick(Sender: TObject);
    procedure BtnAboutClick(Sender: TObject);
  private
    FController: ICustomerController;
    FListFrame: TCustomerListFrame;
    FEditFrame: TCustomerEditFrame;
    
    // ICustomerView Implementation
    procedure RefreshList(const Customers: IList<TCustomer>);
    procedure ShowEditView(ViewModel: TCustomerViewModel);
    procedure ShowListView;
    procedure ShowMessage(const Msg: string);
    
    // Frame Event Delegations (Bridges to Controller)
    procedure DoNewCustomer;
    procedure DoEditCustomer(Customer: TCustomer);
    procedure DoDeleteCustomer(Customer: TCustomer);
    procedure DoRefreshList;
    procedure DoSaveCustomer(ViewModel: TCustomerViewModel);
    procedure DoCancelEdit;
  public
    procedure InjectDependencies(AController: ICustomerController);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FListFrame := TCustomerListFrame.Create(ContentPanel);
  FListFrame.Parent := ContentPanel;
  FListFrame.Align := alClient;
  
  FEditFrame := TCustomerEditFrame.Create(ContentPanel);
  FEditFrame.Parent := ContentPanel;
  FEditFrame.Align := alClient;
  FEditFrame.Visible := False;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  if Assigned(FController) then
  begin
    FController.View := nil;
    FController := nil;
  end;
    
  FListFrame.Free;
  FEditFrame.Free;
end;

procedure TMainForm.InjectDependencies(AController: ICustomerController);
begin
  FController := AController;
  FController.View := Self;

  // Wire UI Events using stable method pointers
  FListFrame.OnNewCustomer := DoNewCustomer;
  FListFrame.OnCustomerSelected := DoEditCustomer;
  FListFrame.OnDeleteCustomer := DoDeleteCustomer;
  FListFrame.OnRefresh := DoRefreshList;
  
  FEditFrame.OnSave := DoSaveCustomer;
  FEditFrame.OnCancel := DoCancelEdit;

  // Initial load
  FController.LoadCustomers;
  ShowListView;
end;

{ ICustomerView Implementation }

procedure TMainForm.ShowListView;
begin
  FEditFrame.Visible := False;
  FListFrame.Visible := True;
  Caption := 'Desktop Modern - Customer Management';
end;

procedure TMainForm.ShowEditView(ViewModel: TCustomerViewModel);
begin
  FListFrame.Visible := False;
  FEditFrame.LoadCustomer(ViewModel);
  FEditFrame.Visible := True;
  FEditFrame.EdtName.SetFocus;
  Caption := 'Desktop Modern - Edit Customer';
end;

procedure TMainForm.RefreshList(const Customers: IList<TCustomer>);
begin
  FListFrame.LoadCustomers(Customers);
end;

procedure TMainForm.ShowMessage(const Msg: string);
begin
  Vcl.Dialogs.ShowMessage(Msg);
end;

{ Frame Event Delegations }

procedure TMainForm.DoNewCustomer;
begin
  FController.CreateNewCustomer;
end;

procedure TMainForm.DoEditCustomer(Customer: TCustomer);
begin
  FController.EditCustomer(Customer);
end;

procedure TMainForm.DoDeleteCustomer(Customer: TCustomer);
begin
  if MessageDlg(Format('Delete customer "%s"?', [Customer.Name.Value]),
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    FController.DeleteCustomer(Customer);
  end;
end;

procedure TMainForm.DoRefreshList;
begin
  FController.LoadCustomers;
end;

procedure TMainForm.DoSaveCustomer(ViewModel: TCustomerViewModel);
begin
  FController.SaveCustomer(ViewModel);
end;

procedure TMainForm.DoCancelEdit;
begin
  FController.CancelEdit;
end;

{ UI Actions }

procedure TMainForm.BtnCustomersClick(Sender: TObject);
begin
  FController.LoadCustomers;
  ShowListView;
end;

procedure TMainForm.BtnAboutClick(Sender: TObject);
begin
  Vcl.Dialogs.ShowMessage('Desktop Modern Customer CRUD' + sLineBreak + 
              'Dext Framework Example - Refactored' + sLineBreak + sLineBreak +
              'Demonstrates:' + sLineBreak +
              '- Controller & Interface Pattern' + sLineBreak +
              '- Magic Binding (Attributes)' + sLineBreak +
              '- Decoupled UI Logic');
end;

end.
