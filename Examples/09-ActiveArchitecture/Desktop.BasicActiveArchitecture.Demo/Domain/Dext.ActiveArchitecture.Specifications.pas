unit Dext.ActiveArchitecture.Specifications;

interface

uses
  Dext.Specifications.Base,
  Dext.Specifications.Types,
  Dext.ActiveArchitecture.Entities;

type
  // 1. Especificação: Pedidos do Brasil
  TBrazilOrdersSpec = class(TSpecification<TOrders>)
  public
    constructor Create; reintroduce;
  end;

  // 2. Especificação: Pedidos com Frete Alto (> MinFreight)
  TExpensiveFreightSpec = class(TSpecification<TOrders>)
  public
    constructor Create(MinFreight: Double); reintroduce;
  end;

  // 3. Especificação Combinada: Pedidos do Brasil com Frete Alto (> MinFreight)
  TBrazilHeavyFreightSpec = class(TSpecification<TOrders>)
  public
    constructor Create(MinFreight: Double); reintroduce;
  end;

implementation

{ TBrazilOrdersSpec }

constructor TBrazilOrdersSpec.Create;
begin
  inherited Create;
  Where(Prop('ShipCountry') = 'Brazil');
end;

{ TExpensiveFreightSpec }

constructor TExpensiveFreightSpec.Create(MinFreight: Double);
begin
  inherited Create;
  Where(Prop('Freight') > MinFreight);
end;

{ TBrazilHeavyFreightSpec }

constructor TBrazilHeavyFreightSpec.Create(MinFreight: Double);
begin
  inherited Create;
  Where((Prop('ShipCountry') = 'Brazil') and (Prop('Freight') > MinFreight));
end;

end.
