unit Dext.Core.Extensions;

interface

uses
  Dext.DI.Interfaces,
  Dext.HealthChecks,
  Dext.Hosting.BackgroundService;

type
  TDextServiceCollectionExtensions = class
  public
    class function AddHealthChecks(Services: IServiceCollection): THealthCheckBuilder;
    class function AddBackgroundServices(Services: IServiceCollection): TBackgroundServiceBuilder;
  end;

implementation

{ TDextServiceCollectionExtensions }

class function TDextServiceCollectionExtensions.AddHealthChecks(Services: IServiceCollection): THealthCheckBuilder;
begin
  Result := THealthCheckBuilder.Create(Services);
end;

class function TDextServiceCollectionExtensions.AddBackgroundServices(Services: IServiceCollection): TBackgroundServiceBuilder;
begin
  Result := TBackgroundServiceBuilder.Create(Services);
end;

end.
