// Dext.DI.Spring4D.pas
unit Dext.DI.Spring4D;

interface

uses
  Dext.DI.Interfaces,
  Spring.Container;

type
  TSpring4DServiceProvider = class(TInterfacedObject, IServiceProvider)
  private
    FContainer: TContainer;
  public
    constructor Create(AContainer: TContainer);
    function GetService(const AServiceType: TClass): TObject;
    function GetService<T: class>: T;
    function GetRequiredService(const AServiceType: TClass): TObject;
    function GetRequiredService<T: class>: T;
  end;

  TSpring4DServiceCollection = class(TInterfacedObject, IServiceCollection)
  private
    FContainer: TContainer;
  public
    constructor Create(AContainer: TContainer = nil);
    destructor Destroy; override;

    function AddSingleton(const AServiceType: TClass;
                         const AImplementationType: TClass = nil;
                         const AFactory: TFunc<IServiceProvider, TObject> = nil): IServiceCollection; overload;
    // ... implementar outros métodos

    function BuildServiceProvider: IServiceProvider;
  end;
