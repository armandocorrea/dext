unit Dext.Core.Controllers;

interface

uses
  Dext.DI.Interfaces,
  Dext.Http.Interfaces;

type
  IHttpHandler = interface
    ['{DBE15360-AD39-42F4-853E-6DCED75B256A}']
    procedure HandleRequest(AContext: IHttpContext);
  end;

  // Para Approach 1: Records estáticos
  TStaticHandler = reference to procedure(AContext: IHttpContext);

  // Para Approach 2: Classes com DI
  TControllerClass = class of TController;

  TController = class abstract(TInterfacedObject, IHttpHandler)
  public
    procedure HandleRequest(AContext: IHttpContext); virtual; abstract;
  end;

implementation

end.
