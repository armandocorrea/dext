# Dext Framework API Reference

This document provides a quick reference for all units in the Dext Framework. For the full interactive documentation, visit the [HTML Documentation Portal](html/index.html).

## Units Overview (191 total)

### Dext

---

### Dext.Assertions

**Classes:** [EAssertionFailed](#eassertionfailed)

**Records:** Assert, ShouldDateTime, ShouldString, ShouldInteger, ShouldBoolean, ShouldAction, ShouldDouble, ShouldInt64, ShouldGuid, ShouldUUID, ShouldVariant, ShouldObject, ShouldProperty, ShouldObjectHelper, ShouldInterface, ShouldList

---

### Dext.Auth.Attributes

**Classes:** [AuthorizeAttribute](#authorizeattribute), [AllowAnonymousAttribute](#allowanonymousattribute)

---

### Dext.Auth.BasicAuth

**Classes:** [TBasicAuthMiddleware](#tbasicauthmiddleware), [TApplicationBuilderBasicAuthExtensions](#tapplicationbuilderbasicauthextensions)

**Records:** TBasicAuthOptions

---

### Dext.Auth.Identity

**Classes:** [TClaimsIdentity](#tclaimsidentity), [TClaimsPrincipal](#tclaimsprincipal), [TClaimTypes](#tclaimtypes), [TClaimsBuilder](#tclaimsbuilder)

**Interfaces:** IIdentity, IClaimsPrincipal, IClaimsBuilder

---

### Dext.Auth.JWT

**Classes:** [TJwtOptionsBuilder](#tjwtoptionsbuilder), [TJwtTokenHandler](#tjwttokenhandler)

**Interfaces:** IJwtTokenHandler

**Records:** TClaim, TJwtValidationResult, TJwtOptions, TJwtOptionsHelper

---

### Dext.Auth.Middleware

**Classes:** [TJwtAuthenticationMiddleware](#tjwtauthenticationmiddleware), [TApplicationBuilderJwtExtensions](#tapplicationbuilderjwtextensions)

---

### Dext.Caching

**Classes:** [TMemoryCacheStore](#tmemorycachestore), [TResponseCaptureWrapper](#tresponsecapturewrapper), [TResponseCacheMiddleware](#tresponsecachemiddleware), [TResponseCacheBuilder](#tresponsecachebuilder), [TApplicationBuilderCacheExtensions](#tapplicationbuildercacheextensions)

**Interfaces:** ICacheStore

**Records:** TCacheEntry, TResponseCacheOptions, TResponseCacheOptionsHelper

---

### Dext.Caching.Redis

**Classes:** [TRedisCacheStore](#trediscachestore)

---

### Dext.Collections

**Classes:** [TSmartEnumerator](#tsmartenumerator), [TSmartList](#tsmartlist), [TCollections](#tcollections)

**Interfaces:** IEnumerator, IEnumerable, IList

---

### Dext.Collections.Extensions

**Classes:** [TListExtensions](#tlistextensions)

---

### Dext.Configuration.Binder

**Classes:** [TConfigurationBinder](#tconfigurationbinder)

---

### Dext.Configuration.Core

**Classes:** [TConfigurationProvider](#tconfigurationprovider), [TConfigurationSection](#tconfigurationsection), [TConfigurationRoot](#tconfigurationroot), [TConfigurationBuilder](#tconfigurationbuilder), [TConfigurationPath](#tconfigurationpath)

---

### Dext.Configuration.EnvironmentVariables

**Classes:** [TEnvironmentVariablesConfigurationProvider](#tenvironmentvariablesconfigurationprovider), [TEnvironmentVariablesConfigurationSource](#tenvironmentvariablesconfigurationsource)

---

### Dext.Configuration.Interfaces

**Classes:** [EConfigurationException](#econfigurationexception)

**Interfaces:** IConfiguration, IConfigurationSection, IConfigurationRoot, IConfigurationProvider, IConfigurationSource, IConfigurationBuilder

---

### Dext.Configuration.Json

**Classes:** [TJsonConfigurationProvider](#tjsonconfigurationprovider), [TJsonConfigurationSource](#tjsonconfigurationsource)

---

### Dext.Configuration.Yaml

**Classes:** [TYamlConfigurationProvider](#tyamlconfigurationprovider), [TYamlConfigurationSource](#tyamlconfigurationsource)

---

### Dext.Core.Activator

**Classes:** [TActivator](#tactivator)

---

### Dext.Core.CancellationToken

**Classes:** [TCancellationToken](#tcancellationtoken), [TCancellationTokenSource](#tcancellationtokensource)

**Interfaces:** ICancellationToken

---

### Dext.Core.DateUtils

---

### Dext.Core.Extensions

**Classes:** [TDextServiceCollectionExtensions](#tdextservicecollectionextensions)

---

### Dext.Core.Memory

**Classes:** [TLifetime](#tlifetime), [TDeferredAction](#tdeferredaction)

**Interfaces:** ILifetime, IDeferred

---

### Dext.Core.SmartTypes

**Classes:** [TPropInfo](#tpropinfo)

**Interfaces:** IPropInfo

**Records:** BooleanExpression, Prop

---

### Dext.Core.Span

**Records:** TSpan, TByteSpan

---

### Dext.Core.ValueConverters

**Classes:** [TValueConverterRegistry](#tvalueconverterregistry), [TValueConverter](#tvalueconverter), [TBaseConverter](#tbaseconverter), [TVariantToIntegerConverter](#tvarianttointegerconverter), [TVariantToStringConverter](#tvarianttostringconverter), [TVariantToBooleanConverter](#tvarianttobooleanconverter), [TVariantToFloatConverter](#tvarianttofloatconverter), [TVariantToDateTimeConverter](#tvarianttodatetimeconverter), [TVariantToDateConverter](#tvarianttodateconverter), [TVariantToTimeConverter](#tvarianttotimeconverter), [TVariantToEnumConverter](#tvarianttoenumconverter), [TVariantToGuidConverter](#tvarianttoguidconverter), [TVariantToClassConverter](#tvarianttoclassconverter), [TIntegerToEnumConverter](#tintegertoenumconverter), [TStringToGuidConverter](#tstringtoguidconverter), [TVariantToBytesConverter](#tvarianttobytesconverter), [TStringToBytesConverter](#tstringtobytesconverter), [TClassToClassConverter](#tclasstoclassconverter)

**Interfaces:** IValueConverter

---

### Dext.DI.Attributes

**Classes:** [ServiceConstructorAttribute](#serviceconstructorattribute)

---

### Dext.DI.Comparers

**Classes:** [TServiceTypeComparer](#tservicetypecomparer)

---

### Dext.DI.Core

**Classes:** [TServiceDescriptor](#tservicedescriptor), [TDextServiceProvider](#tdextserviceprovider), [TDextServiceScope](#tdextservicescope), [TDextServiceCollection](#tdextservicecollection)

---

### Dext.DI.Extensions

**Classes:** [TServiceCollectionExtensions](#tservicecollectionextensions), [TServiceProviderExtensions](#tserviceproviderextensions)

---

### Dext.DI.Interfaces

**Classes:** [EDextDIException](#edextdiexception), [TDextDIFactory](#tdextdifactory)

**Interfaces:** IServiceScope, IServiceCollection, IServiceProvider

**Records:** TServiceType, TDextServices

---

### Dext.DI.Middleware

**Classes:** [TServiceScopeMiddleware](#tservicescopemiddleware), [TApplicationBuilderScopeExtensions](#tapplicationbuilderscopeextensions)

---

### Dext.Entity

---

### Dext.Entity.Attributes

---

### Dext.Entity.Cache

**Classes:** [TSQLCache](#tsqlcache)

---

### Dext.Entity.Context

**Classes:** [TChangeTracker](#tchangetracker), [TCollectionEntry](#tcollectionentry), [TReferenceEntry](#treferenceentry), [TEntityEntry](#tentityentry), [TDbContext](#tdbcontext)

---

### Dext.Entity.Core

**Classes:** [EOptimisticConcurrencyException](#eoptimisticconcurrencyexception)

**Interfaces:** IChangeTracker, IDbSet, IDbSet, ICollectionEntry, IReferenceEntry, IEntityEntry, IDbContext

---

### Dext.Entity.DbSet

**Classes:** [TDbSet](#tdbset)

---

### Dext.Entity.Dialects

**Classes:** [TDialectFactory](#tdialectfactory), [TBaseDialect](#tbasedialect), [TSQLiteDialect](#tsqlitedialect), [TPostgreSQLDialect](#tpostgresqldialect), [TFirebirdDialect](#tfirebirddialect), [TSQLServerDialect](#tsqlserverdialect), [TMySQLDialect](#tmysqldialect), [TOracleDialect](#toracledialect), [TInterBaseDialect](#tinterbasedialect)

**Interfaces:** ISQLDialect

---

### Dext.Entity.Drivers.FireDAC

**Classes:** [TFireDACTransaction](#tfiredactransaction), [TFireDACReader](#tfiredacreader), [TFireDACCommand](#tfiredaccommand), [TFireDACConnection](#tfiredacconnection)

---

### Dext.Entity.Drivers.FireDAC.Manager

---

### Dext.Entity.Drivers.FireDAC.Phys

**Classes:** [TFireDACPhysTransaction](#tfiredacphystransaction), [TFireDACPhysReader](#tfiredacphysreader), [TFireDACPhysCommand](#tfiredacphyscommand), [TFireDACPhysConnection](#tfiredacphysconnection)

---

### Dext.Entity.Drivers.Interfaces

**Interfaces:** IDbConnection, IDbTransaction, IDbCommand, IDbReader

---

### Dext.Entity.Grouping

**Classes:** [TGrouping](#tgrouping), [TGroupByIterator](#tgroupbyiterator), [TQuery](#tquery)

**Interfaces:** IGrouping

---

### Dext.Entity.Joining

**Classes:** [TJoinIterator](#tjoiniterator), [TJoining](#tjoining)

---

### Dext.Entity.LazyLoading

**Classes:** [TLazyInjector](#tlazyinjector), [TLazyLoader](#tlazyloader)

---

### Dext.Entity.Mapping

**Classes:** [TPropertyMap](#tpropertymap), [TEntityMap](#tentitymap), [TEntityTypeBuilder](#tentitytypebuilder), [TPropertyBuilder](#tpropertybuilder), [TEntityTypeConfiguration](#tentitytypeconfiguration), [TModelBuilder](#tmodelbuilder)

**Interfaces:** IEntityTypeBuilder, IPropertyBuilder, IEntityTypeConfiguration

**Records:** TEntityBuilder

---

### Dext.Entity.Migrations

**Classes:** [TMigrationRegistry](#tmigrationregistry)

**Interfaces:** IMigration

---

### Dext.Entity.Migrations.Builder

**Classes:** [TColumnBuilder](#tcolumnbuilder), [TTableBuilder](#ttablebuilder), [TSchemaBuilder](#tschemabuilder)

**Interfaces:** IColumnBuilder

---

### Dext.Entity.Migrations.Differ

**Classes:** [TModelDiffer](#tmodeldiffer)

---

### Dext.Entity.Migrations.Extractor

**Classes:** [TDbContextModelExtractor](#tdbcontextmodelextractor)

---

### Dext.Entity.Migrations.Generator

**Classes:** [TMigrationGenerator](#tmigrationgenerator)

---

### Dext.Entity.Migrations.Json

**Classes:** [TJsonMigration](#tjsonmigration), [TJsonMigrationLoader](#tjsonmigrationloader)

---

### Dext.Entity.Migrations.Model

**Classes:** [TSnapshotColumn](#tsnapshotcolumn), [TSnapshotForeignKey](#tsnapshotforeignkey), [TSnapshotTable](#tsnapshottable), [TSnapshotModel](#tsnapshotmodel)

---

### Dext.Entity.Migrations.Operations

**Classes:** [TMigrationOperation](#tmigrationoperation), [TColumnDefinition](#tcolumndefinition), [TCreateTableOperation](#tcreatetableoperation), [TDropTableOperation](#tdroptableoperation), [TAddColumnOperation](#taddcolumnoperation), [TDropColumnOperation](#tdropcolumnoperation), [TAlterColumnOperation](#taltercolumnoperation), [TAddForeignKeyOperation](#taddforeignkeyoperation), [TDropForeignKeyOperation](#tdropforeignkeyoperation), [TCreateIndexOperation](#tcreateindexoperation), [TDropIndexOperation](#tdropindexoperation), [TSqlOperation](#tsqloperation)

---

### Dext.Entity.Migrations.Runner

**Classes:** [TMigrator](#tmigrator)

---

### Dext.Entity.Migrations.Serializers.Json

**Classes:** [TMigrationJsonSerializer](#tmigrationjsonserializer)

---

### Dext.Entity.Naming

**Classes:** [TDefaultNamingStrategy](#tdefaultnamingstrategy), [TSnakeCaseNamingStrategy](#tsnakecasenamingstrategy), [TLowerCaseNamingStrategy](#tlowercasenamingstrategy), [TUppercaseNamingStrategy](#tuppercasenamingstrategy)

**Interfaces:** INamingStrategy

---

### Dext.Entity.Prototype

**Classes:** [Prototype](#prototype)

---

### Dext.Entity.Query

**Classes:** [TPagedResult](#tpagedresult), [TQueryIterator](#tqueryiterator), [TSpecificationQueryIterator](#tspecificationqueryiterator), [TProjectingIterator](#tprojectingiterator), [TFilteringIterator](#tfilteringiterator), [TSkipIterator](#tskipiterator), [TTakeIterator](#ttakeiterator), [TDistinctIterator](#tdistinctiterator), [TEmptyIterator](#temptyiterator)

**Interfaces:** IPagedResult

**Records:** TFluentQuery

---

### Dext.Entity.Scaffolding

**Classes:** [TFireDACSchemaProvider](#tfiredacschemaprovider), [TDelphiEntityGenerator](#tdelphientitygenerator)

**Interfaces:** ISchemaProvider, IEntityGenerator

**Records:** TMetaColumn, TMetaForeignKey, TMetaTable

---

### Dext.Entity.Setup

**Classes:** [TDbContextOptions](#tdbcontextoptions), [TDbContextOptionsBuilder](#tdbcontextoptionsbuilder)

---

### Dext.Entity.Tenancy

**Classes:** [TTenantEntity](#ttenantentity)

**Interfaces:** ITenantAware

---

### Dext.Entity.TypeConverters

**Classes:** [EnumAsStringAttribute](#enumasstringattribute), [ArrayColumnAttribute](#arraycolumnattribute), [ColumnTypeAttribute](#columntypeattribute), [TTypeConverterBase](#ttypeconverterbase), [TGuidConverter](#tguidconverter), [TUuidConverter](#tuuidconverter), [TEnumConverter](#tenumconverter), [TJsonConverter](#tjsonconverter), [TArrayConverter](#tarrayconverter), [TDateTimeConverter](#tdatetimeconverter), [TDateConverter](#tdateconverter), [TTimeConverter](#ttimeconverter), [TBytesConverter](#tbytesconverter), [TPropConverter](#tpropconverter), [TStringsConverter](#tstringsconverter), [TTypeConverterRegistry](#ttypeconverterregistry)

**Interfaces:** ITypeConverter

---

### Dext.Entity.TypeSystem

**Classes:** [TPropertyInfo](#tpropertyinfo), [TEntityBuilder](#tentitybuilder), [TEntityType](#tentitytype)

**Interfaces:** IEntityBuilder

**Records:** TProp

---

### Dext.Filters

**Classes:** [ActionFilterAttribute](#actionfilterattribute), [TActionExecutingContext](#tactionexecutingcontext), [TActionExecutedContext](#tactionexecutedcontext)

**Interfaces:** IActionExecutingContext, IActionExecutedContext, IActionFilter

**Records:** TActionDescriptor

---

### Dext.Filters.BuiltIn

**Classes:** [LogActionAttribute](#logactionattribute), [RequireHeaderAttribute](#requireheaderattribute), [ResponseCacheAttribute](#responsecacheattribute), [ValidateModelAttribute](#validatemodelattribute), [AddHeaderAttribute](#addheaderattribute)

---

### Dext.HealthChecks

**Classes:** [THealthCheckService](#thealthcheckservice), [THealthCheckMiddleware](#thealthcheckmiddleware), [THealthCheckBuilder](#thealthcheckbuilder)

**Interfaces:** IHealthCheck, IHealthCheckService

**Records:** THealthCheckResult

---

### Dext.Hosting.ApplicationLifetime

**Classes:** [THostApplicationLifetime](#thostapplicationlifetime)

**Interfaces:** IHostApplicationLifetime

---

### Dext.Hosting.AppState

**Classes:** [TApplicationStateManager](#tapplicationstatemanager)

**Interfaces:** IAppStateObserver, IAppStateControl

---

### Dext.Hosting.BackgroundService

**Classes:** [TBackgroundServiceThread](#tbackgroundservicethread), [TBackgroundService](#tbackgroundservice), [THostedServiceManager](#thostedservicemanager), [TBackgroundServiceBuilder](#tbackgroundservicebuilder)

**Interfaces:** IHostedService, IHostedServiceManager

---

### Dext.Hosting.CLI

**Classes:** [TDextCLI](#tdextcli)

---

### Dext.Hosting.CLI.Args

**Classes:** [TCommandLineArgs](#tcommandlineargs)

**Interfaces:** IConsoleCommand

---

### Dext.Hosting.CLI.Commands.Configuration

**Classes:** [TConfigInitCommand](#tconfiginitcommand), [TEnvScanCommand](#tenvscancommand)

---

### Dext.Hosting.CLI.Commands.MigrateDown

**Classes:** [TMigrateDownCommand](#tmigratedowncommand)

---

### Dext.Hosting.CLI.Commands.MigrateGenerate

**Classes:** [TMigrateGenerateCommand](#tmigrategeneratecommand)

---

### Dext.Hosting.CLI.Commands.MigrateList

**Classes:** [TMigrateListCommand](#tmigratelistcommand)

---

### Dext.Hosting.CLI.Commands.MigrateUp

**Classes:** [TMigrateUpCommand](#tmigrateupcommand)

---

### Dext.Hosting.CLI.Commands.Scaffold

**Classes:** [TScaffoldCommand](#tscaffoldcommand)

---

### Dext.Hosting.CLI.Commands.Test

**Classes:** [TTestCommand](#ttestcommand)

---

### Dext.Hosting.CLI.Commands.UI

**Classes:** [TUICommand](#tuicommand)

---

### Dext.Hosting.CLI.Config

**Classes:** [TDextConfig](#tdextconfig), [TDextGlobalConfig](#tdextglobalconfig)

**Records:** TDextTestConfig, TDextEnvironment

---

### Dext.Hosting.CLI.Hubs.Dashboard

**Classes:** [TDashboardHub](#tdashboardhub)

---

### Dext.Hosting.CLI.Logger

**Classes:** [TConsoleHubLogger](#tconsolehublogger), [TConsoleHubLoggerProvider](#tconsolehubloggerprovider)

---

### Dext.Hosting.CLI.Registry

**Classes:** [TProjectRegistry](#tprojectregistry)

**Records:** TProjectInfo

---

### Dext.Hosting.CLI.Tools.CodeCoverage

**Classes:** [TCodeCoverageTool](#tcodecoveragetool)

---

### Dext.Hosting.CLI.Tools.Sonar

**Classes:** [TSonarConverter](#tsonarconverter)

---

### Dext.Interception

**Classes:** [EInterceptionException](#einterceptionexception)

**Interfaces:** IInvocation, IInterceptor, IProxyTargetAccessor

**Records:** TProxy

---

### Dext.Interception.ClassProxy

**Classes:** [TClassProxy](#tclassproxy)

---

### Dext.Interception.Proxy

**Classes:** [TInvocation](#tinvocation), [TInterfaceProxy](#tinterfaceproxy)

---

### Dext.Json

**Classes:** [EDextJsonException](#edextjsonexception), [DextJsonAttribute](#dextjsonattribute), [JsonNameAttribute](#jsonnameattribute), [JsonIgnoreAttribute](#jsonignoreattribute), [JsonFormatAttribute](#jsonformatattribute), [JsonStringAttribute](#jsonstringattribute), [JsonNumberAttribute](#jsonnumberattribute), [JsonBooleanAttribute](#jsonbooleanattribute), [TDextJson](#tdextjson), [TDextSerializer](#tdextserializer), [TJsonBuilder](#tjsonbuilder)

**Records:** TJsonUtils, TDextSettings

---

### Dext.Json.Driver.DextJsonDataObjects

**Classes:** [TJsonDataObjectWrapper](#tjsondataobjectwrapper), [TJsonDataObjectAdapter](#tjsondataobjectadapter), [TJsonDataArrayAdapter](#tjsondataarrayadapter), [TJsonPrimitiveAdapter](#tjsonprimitiveadapter), [TJsonDataObjectsProvider](#tjsondataobjectsprovider)

---

### Dext.Json.Driver.SystemJson

**Classes:** [TSystemJsonWrapper](#tsystemjsonwrapper), [TSystemJsonObjectAdapter](#tsystemjsonobjectadapter), [TSystemJsonArrayAdapter](#tsystemjsonarrayadapter), [TSystemJsonPrimitiveAdapter](#tsystemjsonprimitiveadapter), [TSystemJsonProvider](#tsystemjsonprovider)

---

### Dext.Json.Types

**Interfaces:** IDextJsonNode, IDextJsonObject, IDextJsonArray, IDextJsonProvider

---

### Dext.Json.Utf8

**Classes:** [EJsonException](#ejsonexception)

**Records:** TUtf8JsonReader

---

### Dext.Json.Utf8.Serializer

**Classes:** [EUtf8SerializationException](#eutf8serializationexception)

**Records:** TUtf8JsonSerializer

---

### Dext.Logging

**Classes:** [TAbstractLogger](#tabstractlogger), [TAggregateLogger](#taggregatelogger), [TLoggerFactory](#tloggerfactory)

**Interfaces:** ILogger, ILoggerProvider, ILoggerFactory

---

### Dext.Logging.Console

**Classes:** [TConsoleLogger](#tconsolelogger), [TConsoleLoggerProvider](#tconsoleloggerprovider)

---

### Dext.Logging.Extensions

**Classes:** [TServiceCollectionLoggingExtensions](#tservicecollectionloggingextensions)

**Interfaces:** ILoggingBuilder

---

### Dext.Mapper

**Classes:** [TMemberMapping](#tmembermapping), [TTypeMapConfigBase](#ttypemapconfigbase), [TTypeMapConfig](#ttypemapconfig), [TMapper](#tmapper)

---

### Dext.MM

---

### Dext.Mocks

**Classes:** [EMockException](#emockexception)

**Interfaces:** IMock, IMock, ISetup, IWhen

**Records:** Times, Mock

---

### Dext.Mocks.Auto

**Classes:** [TAutoMocker](#tautomocker)

---

### Dext.Mocks.Interceptor

**Classes:** [TMethodSetup](#tmethodsetup), [TMethodCall](#tmethodcall), [TMockInterceptor](#tmockinterceptor), [TSetup](#tsetup), [TWhen](#twhen), [TMock](#tmock)

---

### Dext.Mocks.Matching

**Classes:** [TMatcherFactory](#tmatcherfactory)

**Records:** Arg

---

### Dext.MultiTenancy

**Classes:** [TTenant](#ttenant), [TTenantProvider](#ttenantprovider)

**Interfaces:** ITenant, ITenantProvider

---

### Dext.OpenAPI.Attributes

**Classes:** [SwaggerIgnoreAttribute](#swaggerignoreattribute), [SwaggerOperationAttribute](#swaggeroperationattribute), [SwaggerResponseAttribute](#swaggerresponseattribute), [SwaggerSchemaAttribute](#swaggerschemaattribute), [SwaggerIgnorePropertyAttribute](#swaggerignorepropertyattribute), [SwaggerPropertyAttribute](#swaggerpropertyattribute), [SwaggerRequiredAttribute](#swaggerrequiredattribute), [SwaggerExampleAttribute](#swaggerexampleattribute), [SwaggerFormatAttribute](#swaggerformatattribute), [SwaggerTagAttribute](#swaggertagattribute), [SwaggerParamAttribute](#swaggerparamattribute), [AuthorizeAttribute](#authorizeattribute)

---

### Dext.OpenAPI.Extensions

**Classes:** [TEndpointMetadataExtensions](#tendpointmetadataextensions)

---

### Dext.OpenAPI.Fluent

**Records:** TEndpointBuilder, SwaggerEndpoint

---

### Dext.OpenAPI.Generator

**Classes:** [TOpenAPIGenerator](#topenapigenerator)

**Records:** TOpenAPIOptions

---

### Dext.OpenAPI.Types

**Classes:** [TOpenAPISchema](#topenapischema), [TOpenAPIParameter](#topenapiparameter), [TOpenAPIRequestBody](#topenapirequestbody), [TOpenAPIResponse](#topenapiresponse), [TOpenAPIOperation](#topenapioperation), [TOpenAPIPathItem](#topenapipathitem), [TOpenAPIContact](#topenapicontact), [TOpenAPILicense](#topenapilicense), [TOpenAPIInfo](#topenapiinfo), [TOpenAPISecurityScheme](#topenapisecurityscheme), [TOpenAPIDocument](#topenapidocument)

**Records:** TOpenAPIServer

---

### Dext.Options

**Classes:** [TOptions](#toptions), [TOptionsFactory](#toptionsfactory)

**Interfaces:** IOptions

---

### Dext.Options.Extensions

**Classes:** [TOptionsServiceCollectionExtensions](#toptionsservicecollectionextensions)

---

### Dext.RateLimiting

**Classes:** [TRateLimitMiddleware](#tratelimitmiddleware), [TApplicationBuilderRateLimitExtensions](#tapplicationbuilderratelimitextensions)

---

### Dext.RateLimiting.Core

**Classes:** [TRateLimitConfig](#tratelimitconfig)

**Interfaces:** IRateLimiter

**Records:** TRateLimitResult

---

### Dext.RateLimiting.Limiters

**Classes:** [TFixedWindowLimiter](#tfixedwindowlimiter), [TSlidingWindowLimiter](#tslidingwindowlimiter), [TTokenBucketLimiter](#ttokenbucketlimiter), [TConcurrencyLimiter](#tconcurrencylimiter)

---

### Dext.RateLimiting.Policy

**Classes:** [TRateLimitPolicy](#tratelimitpolicy)

---

### Dext.Specifications.Base

---

### Dext.Specifications.Evaluator

**Classes:** [TExpressionEvaluator](#texpressionevaluator)

---

### Dext.Specifications.Fluent

**Records:** TSpecificationBuilder, Specification

---

### Dext.Specifications.Interfaces

**Interfaces:** IExpression, IOrderBy, IJoin, ISpecification, IExpressionVisitor

---

### Dext.Specifications.OrderBy

**Classes:** [TOrderBy](#torderby)

---

### Dext.Specifications.SQL.Generator

**Classes:** [TSQLWhereGenerator](#tsqlwheregenerator), [TSQLColumnMapper](#tsqlcolumnmapper), [TSQLGeneratorHelper](#tsqlgeneratorhelper), [TSQLGenerator](#tsqlgenerator), [TSQLParamCollector](#tsqlparamcollector)

**Interfaces:** ISQLColumnMapper

---

### Dext.Specifications.Types

**Classes:** [TAbstractExpression](#tabstractexpression), [TBinaryExpression](#tbinaryexpression), [TArithmeticExpression](#tarithmeticexpression), [TPropertyExpression](#tpropertyexpression), [TLiteralExpression](#tliteralexpression), [TLogicalExpression](#tlogicalexpression), [TUnaryExpression](#tunaryexpression), [TConstantExpression](#tconstantexpression)

**Records:** TFluentExpression, TPropExpression

---

### Dext.Swagger.Middleware

**Classes:** [TSwaggerMiddleware](#tswaggermiddleware), [TSwaggerExtensions](#tswaggerextensions)

---

### Dext.Testing

---

### Dext.Testing.Attributes

**Classes:** [TestFixtureAttribute](#testfixtureattribute), [TestClassAttribute](#testclassattribute), [TestAttribute](#testattribute), [FactAttribute](#factattribute), [SetupAttribute](#setupattribute), [TearDownAttribute](#teardownattribute), [BeforeAllAttribute](#beforeallattribute), [ClassInitializeAttribute](#classinitializeattribute), [AfterAllAttribute](#afterallattribute), [ClassCleanupAttribute](#classcleanupattribute), [AssemblyInitializeAttribute](#assemblyinitializeattribute), [OneTimeSetUpAttribute](#onetimesetupattribute), [AssemblyCleanupAttribute](#assemblycleanupattribute), [OneTimeTearDownAttribute](#onetimeteardownattribute), [TestCaseAttribute](#testcaseattribute), [TestCaseSourceAttribute](#testcasesourceattribute), [IgnoreAttribute](#ignoreattribute), [SkipAttribute](#skipattribute), [TimeoutAttribute](#timeoutattribute), [RepeatAttribute](#repeatattribute), [MaxTimeAttribute](#maxtimeattribute), [ExplicitAttribute](#explicitattribute), [CategoryAttribute](#categoryattribute), [TraitAttribute](#traitattribute), [DescriptionAttribute](#descriptionattribute), [PriorityAttribute](#priorityattribute), [PlatformAttribute](#platformattribute), [ValuesAttribute](#valuesattribute), [RangeAttribute](#rangeattribute), [RandomAttribute](#randomattribute), [CombinatorialAttribute](#combinatorialattribute)

---

### Dext.Testing.Console

**Classes:** [TTestRunner](#ttestrunner)

---

### Dext.Testing.Dashboard

**Classes:** [TDashboardListener](#tdashboardlistener)

---

### Dext.Testing.DI

**Classes:** [TTestServiceProvider](#ttestserviceprovider)

---

### Dext.Testing.Fluent

**Records:** TTestConfigurator, TTest

---

### Dext.Testing.History

**Classes:** [TTestHistoryManager](#ttesthistorymanager)

---

### Dext.Testing.Report

**Classes:** [TJUnitReporter](#tjunitreporter), [TJsonReporter](#tjsonreporter), [TSonarQubeReporter](#tsonarqubereporter), [TXUnitReporter](#txunitreporter), [TTRXReporter](#ttrxreporter), [THTMLReporter](#thtmlreporter)

**Records:** TTestCaseReport, TTestSuiteReport

---

### Dext.Testing.Runner

**Classes:** [TTestFixtureInfo](#ttestfixtureinfo), [TTestContext](#ttestcontext), [TTestRunner](#ttestrunner), [TTestConsole](#ttestconsole)

**Interfaces:** ITestListener, ITestContext

**Records:** TTestInfo, TTestSummary, TTestFilter

---

### Dext.Threading.Async

**Classes:** [TAsyncTask](#tasynctask)

**Interfaces:** IAsyncTask

**Records:** TAsyncBuilder, TAsyncTask

---

### Dext.Types.Lazy

**Classes:** [TLazy](#tlazy), [TValueLazy](#tvaluelazy)

**Interfaces:** ILazy, ILazy

---

### Dext.Types.Nullable

**Records:** Nullable, TNullableHelper

---

### Dext.Types.UUID

**Records:** TUUID

---

### Dext.Utils

---

### Dext.Validation

**Classes:** [TValidationResult](#tvalidationresult), [ValidationAttribute](#validationattribute), [RequiredAttribute](#requiredattribute), [StringLengthAttribute](#stringlengthattribute), [EmailAddressAttribute](#emailaddressattribute), [RangeAttribute](#rangeattribute), [TValidator](#tvalidator), [TValidator](#tvalidator)

**Interfaces:** IValidator

**Records:** TValidationError

---

### Dext.Web

---

### Dext.Web.ApplicationBuilder.Extensions

**Classes:** [TApplicationBuilderExtensions](#tapplicationbuilderextensions)

**Records:** TDextAppBuilderHelper

---

### Dext.Web.Controllers

**Classes:** [TController](#tcontroller)

**Interfaces:** IHttpHandler

---

### Dext.Web.ControllerScanner

**Classes:** [TControllerScanner](#tcontrollerscanner)

**Interfaces:** IControllerScanner

**Records:** TControllerMethod, TControllerInfo, TCachedMethod

---

### Dext.Web.Core

**Classes:** [TAnonymousMiddleware](#tanonymousmiddleware), [TApplicationBuilder](#tapplicationbuilder), [TMiddleware](#tmiddleware)

**Records:** TMiddlewareRegistration

---

### Dext.Web.Cors

**Classes:** [TCorsMiddleware](#tcorsmiddleware), [TCorsBuilder](#tcorsbuilder), [TApplicationBuilderCorsExtensions](#tapplicationbuildercorsextensions)

**Records:** TCorsOptions, TStringArrayHelper, TCorsOptionsHelper

---

### Dext.Web.DataApi

---

### Dext.Web.Extensions

**Classes:** [TWebDIHelpers](#twebdihelpers), [TWebRouteHelpers](#twebroutehelpers), [TDextServiceCollectionExtensions](#tdextservicecollectionextensions), [TOutputFormatterRegistry](#toutputformatterregistry)

---

### Dext.Web.Formatters.Interfaces

**Interfaces:** IOutputFormatterContext, IOutputFormatter, IOutputFormatterSelector, IOutputFormatterRegistry

---

### Dext.Web.Formatters.Json

**Classes:** [TJsonOutputFormatter](#tjsonoutputformatter)

---

### Dext.Web.Formatters.Selector

**Classes:** [TDefaultOutputFormatterSelector](#tdefaultoutputformatterselector)

**Records:** TMediaTypeHeaderValue

---

### Dext.Web.HandlerInvoker

**Classes:** [THandlerInvoker](#thandlerinvoker)

---

### Dext.Web.Hubs

---

### Dext.Web.Hubs.Clients

**Classes:** [TClientProxy](#tclientproxy), [TAllClientsProxy](#tallclientsproxy), [TGroupClientsProxy](#tgroupclientsproxy), [TUserClientsProxy](#tuserclientsproxy), [THubClients](#thubclients)

---

### Dext.Web.Hubs.Connections

**Classes:** [THubConnection](#thubconnection), [TConnectionManager](#tconnectionmanager), [TGroupManager](#tgroupmanager)

---

### Dext.Web.Hubs.Context

**Classes:** [THubContext](#thubcontext), [THubCallerContext](#thubcallercontext)

---

### Dext.Web.Hubs.Extensions

**Classes:** [THubExtensions](#thubextensions)

---

### Dext.Web.Hubs.Hub

**Classes:** [THub](#thub)

---

### Dext.Web.Hubs.Interfaces

**Interfaces:** IClientProxy, IHubClients, IGroupManager, IHubCallerContext, IHubContext, IHubConnection, IConnectionManager, IHubProtocol, IHubTransport, IHubLifecycle

**Records:** THubMessage

---

### Dext.Web.Hubs.Middleware

**Classes:** [THubDispatcher](#thubdispatcher), [THubMiddleware](#thubmiddleware)

**Records:** THubEndpoint

---

### Dext.Web.Hubs.Protocol.Json

**Classes:** [TJsonHubProtocol](#tjsonhubprotocol)

---

### Dext.Web.Hubs.Transport.SSE

**Classes:** [TSSEConnection](#tsseconnection), [TSSETransport](#tssetransport), [TSSEWriter](#tssewriter)

---

### Dext.Web.Hubs.Types

**Classes:** [EHubException](#ehubexception), [EConnectionNotFoundException](#econnectionnotfoundexception), [EHubMethodNotFoundException](#ehubmethodnotfoundexception), [EHubInvocationException](#ehubinvocationexception)

**Records:** TTransportInfo, TNegotiateResponse, TInvocationRequest, TInvocationResult, THubOptions

---

### Dext.Web.Indy

**Classes:** [TIndyHttpResponse](#tindyhttpresponse), [TIndyHttpRequest](#tindyhttprequest), [TIndyHttpContext](#tindyhttpcontext)

---

### Dext.Web.Indy.Server

**Classes:** [TIndyWebServer](#tindywebserver)

---

### Dext.Web.Indy.SSL.Interfaces

**Interfaces:** IIndySSLHandler

---

### Dext.Web.Indy.SSL.OpenSSL

**Classes:** [TIndyOpenSSLHandler](#tindyopensslhandler)

---

### Dext.Web.Indy.SSL.Taurus

**Classes:** [TIndyTaurusSSLHandler](#tindytaurussslhandler)

---

### Dext.Web.Indy.Types

**Classes:** [TIndyFormFile](#tindyformfile)

---

### Dext.Web.Injection

**Classes:** [THandlerInjector](#thandlerinjector)

---

### Dext.Web.Interfaces

**Classes:** [TDextWebHost](#tdextwebhost), [TFormFileCollection](#tformfilecollection)

**Interfaces:** IFormFileCollection, IFormFile, IResult, IHttpRequest, IHttpResponse, IHttpContext, IMiddleware, IApplicationBuilder, IWebHost, IWebHostBuilder, IStartup, IWebApplication

**Records:** TOpenAPIResponseMetadata, TEndpointMetadata, TCookieOptions, TDextAppBuilder

---

### Dext.Web.Middleware

**Classes:** [EHttpException](#ehttpexception), [ENotFoundException](#enotfoundexception), [EUnauthorizedException](#eunauthorizedexception), [EForbiddenException](#eforbiddenexception), [EValidationException](#evalidationexception), [TExceptionHandlerMiddleware](#texceptionhandlermiddleware), [THttpLoggingMiddleware](#thttploggingmiddleware)

**Records:** TExceptionHandlerOptions, TProblemDetails, THttpLoggingOptions

---

### Dext.Web.Middleware.Compression

**Classes:** [TCompressionMiddleware](#tcompressionmiddleware)

---

### Dext.Web.Middleware.Extensions

**Classes:** [TApplicationBuilderMiddlewareExtensions](#tapplicationbuildermiddlewareextensions)

---

### Dext.Web.Middleware.Logging

**Classes:** [TRequestLoggingMiddleware](#trequestloggingmiddleware)

---

### Dext.Web.Middleware.StartupLock

**Classes:** [TStartupLockMiddleware](#tstartuplockmiddleware)

---

### Dext.Web.ModelBinding

**Classes:** [EBindingException](#ebindingexception), [BindingAttribute](#bindingattribute), [FromBodyAttribute](#frombodyattribute), [FromQueryAttribute](#fromqueryattribute), [FromRouteAttribute](#fromrouteattribute), [FromHeaderAttribute](#fromheaderattribute), [FromServicesAttribute](#fromservicesattribute), [TModelBinder](#tmodelbinder), [TModelBinderHelper](#tmodelbinderhelper), [TBindingSourceProvider](#tbindingsourceprovider)

**Interfaces:** IModelBinder, IBindingSourceProvider

---

### Dext.Web.ModelBinding.Extensions

**Classes:** [TApplicationBuilderWithModelBinding](#tapplicationbuilderwithmodelbinding), [TApplicationBuilderModelBindingExtensions](#tapplicationbuildermodelbindingextensions)

**Interfaces:** IApplicationBuilderWithModelBinding

---

### Dext.Web.MultiTenancy

**Classes:** [TMultiTenancyMiddleware](#tmultitenancymiddleware)

**Interfaces:** ITenantResolutionStrategy, ITenantStore

---

### Dext.Web.Pipeline

**Classes:** [TDextPipeline](#tdextpipeline)

**Interfaces:** IDextPipeline

---

### Dext.Web.ResponseHelper

---

### Dext.Web.Results

**Classes:** [TResult](#tresult), [TOutputFormatterContext](#toutputformattercontext), [TJsonResult](#tjsonresult), [TStatusCodeResult](#tstatuscoderesult), [TContentResult](#tcontentresult), [TObjectResult](#tobjectresult), [TStreamResult](#tstreamresult), [Results](#results)

---

### Dext.Web.Routing

**Classes:** [TRoutePattern](#troutepattern), [TRouteDefinition](#troutedefinition), [TRouteMatcher](#troutematcher), [ERouteException](#erouteexception)

**Interfaces:** IRouteMatcher

---

### Dext.Web.Routing.Attributes

**Classes:** [DextRouteAttribute](#dextrouteattribute), [DextGetAttribute](#dextgetattribute), [DextPostAttribute](#dextpostattribute), [DextPutAttribute](#dextputattribute), [DextDeleteAttribute](#dextdeleteattribute), [DextPatchAttribute](#dextpatchattribute), [DextHeadAttribute](#dextheadattribute), [DextOptionsAttribute](#dextoptionsattribute), [DextControllerAttribute](#dextcontrollerattribute), [EDextHttpException](#edexthttpexception)

---

### Dext.Web.RoutingMiddleware

**Classes:** [TRoutingMiddleware](#troutingmiddleware)

---

### Dext.Web.StaticFiles

**Classes:** [TContentTypeProvider](#tcontenttypeprovider), [TStaticFileMiddleware](#tstaticfilemiddleware), [TApplicationBuilderStaticFilesExtensions](#tapplicationbuilderstaticfilesextensions)

**Records:** TStaticFileOptions

---

### Dext.Web.StatusCodes

**Classes:** [HttpStatus](#httpstatus)

---

### Dext.Web.Versioning

**Classes:** [TQueryStringApiVersionReader](#tquerystringapiversionreader), [THeaderApiVersionReader](#theaderapiversionreader), [TCompositeApiVersionReader](#tcompositeapiversionreader)

**Interfaces:** IApiVersionReader

---

### Dext.Web.WebApplication

**Classes:** [TDextApplication](#tdextapplication)

---

### Dext.WebHost

**Classes:** [TWebHostBuilder](#twebhostbuilder)

---

### Dext.Yaml

**Classes:** [EYamlException](#eyamlexception), [TYamlNode](#tyamlnode), [TYamlScalar](#tyamlscalar), [TYamlMapping](#tyamlmapping), [TYamlSequence](#tyamlsequence), [TYamlDocument](#tyamldocument), [TYamlParser](#tyamlparser)

---

### DextJsonDataObjects

**Classes:** [EJsonException](#ejsonexception), [EJsonCastException](#ejsoncastexception), [EJsonPathException](#ejsonpathexception), [EJsonParserException](#ejsonparserexception), [TJsonBaseObject](#tjsonbaseobject), [TJsonPrimitiveValue](#tjsonprimitivevalue), [TJsonArray](#tjsonarray), [TJsonObject](#tjsonobject)

**Records:** TJsonSerializationConfig, TJsonReaderProgressRec, TJsonOutputWriter, TJsonDataValue, TJsonDataValueHelper, TJsonArrayEnumerator, TJsonNameValuePair, TJsonObjectEnumerator

---


*Generated automatically via DextDoc and DelphiAST.*
