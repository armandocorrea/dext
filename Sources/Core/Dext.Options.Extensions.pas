unit Dext.Options.Extensions;

interface

uses
  System.SysUtils,
  System.TypInfo,
  Dext.DI.Interfaces,
  Dext.Configuration.Interfaces,
  Dext.Options;

type
  TOptionsServiceCollectionExtensions = class
  public
    class procedure AddOptions(Services: IServiceCollection);
    class procedure Configure<T: class, constructor>(Services: IServiceCollection; Configuration: IConfiguration); overload;
    class procedure Configure<T: class, constructor>(Services: IServiceCollection; Section: IConfigurationSection); overload;
  end;

implementation

{ TOptionsServiceCollectionExtensions }

class procedure TOptionsServiceCollectionExtensions.AddOptions(Services: IServiceCollection);
begin
  // Register generic IOptions<> factory is tricky in Delphi without true generics in DI container resolution logic
  // usually we register specific types.
  // But Dext DI might not support open generics yet.
  // So Configure<T> will register IOptions<T> specifically.
end;

class procedure TOptionsServiceCollectionExtensions.Configure<T>(Services: IServiceCollection; Configuration: IConfiguration);
begin
  Services.AddSingleton(
    TServiceType.FromInterface(GetTypeData(TypeInfo(IOptions<T>))^.Guid),
    TClass(TOptions<T>),
    function(Provider: IServiceProvider): TObject
    begin
      // We capture Configuration here. 
      // Ideally we should resolve IConfiguration from Provider, but passing it is easier for now if available.
      // Or better:
      // Result := TOptionsFactory.Create<T>(Provider.GetService<IConfiguration>());
      
      // Since we passed Configuration explicitly:
      Result := TOptionsFactory.Create<T>(Configuration) as TObject;
    end
  );
end;

class procedure TOptionsServiceCollectionExtensions.Configure<T>(Services: IServiceCollection; Section: IConfigurationSection);
begin
  Services.AddSingleton(
    TServiceType.FromInterface(GetTypeData(TypeInfo(IOptions<T>))^.Guid),
    TClass(TOptions<T>),
    function(Provider: IServiceProvider): TObject
    begin
      Result := TOptionsFactory.Create<T>(Section) as TObject;
    end
  );
end;

end.
