# Dext Entity ORM - Migrations Design Document

## Overview
Migrations allow the database schema to evolve over time alongside the application's data model. Instead of manually running SQL scripts, the ORM generates and manages these changes.

## Core Components

### 1. Migration Metadata (`IMigration`)
An interface representing a single migration step.
```pascal
type
  IMigration = interface
    ['{...}']
    function GetId: string; // Timestamp_Name (e.g., '20231027100000_InitialCreate')
    procedure Up(Builder: TSchemaBuilder);
    procedure Down(Builder: TSchemaBuilder);
  end;
```

### 2. Schema Builder (`TSchemaBuilder`)
A fluent API to define schema changes abstractly, which the Dialect translates to SQL.
```pascal
Builder.CreateTable('Users')
  .Column('Id', TColumnType.Integer).NotNull.PrimaryKey.Identity
  .Column('Name', TColumnType.String, 100).NotNull
  .ForeignKey('GroupId', 'Groups', 'Id');
```

### 3. Model Snapshot (`TModelSnapshot`)
To detect changes, we need to compare the *current* code model against the *last applied* model.
- **Approach A (Code-based)**: Generate a snapshot file (JSON/Pascal) after every migration.
- **Approach B (Database-based)**: Compare current model directly with database schema (Diff). *Harder to get right across dialects.*
- **Selected Approach**: **Snapshot**. When adding a migration, we compare the `DbContext` model with the `LastKnownSnapshot`. The difference generates the `Up`/`Down` methods.

### 4. Migration History Table
A table in the database (e.g., `__DextMigrations`) tracking applied migrations.
- `MigrationId` (PK, String)
- `AppliedOn` (DateTime)
- `ProductVersion` (String)

## Workflow (CLI / Tooling)

1.  **`dext migrations add <Name>`**
    - Compiles/Loads the project.
    - Builds the current `TModel` from `DbContext`.
    - Loads the `LastSnapshot` (from file).
    - Calculates Diff (Model vs Snapshot).
    - Generates a new Pascal unit `Migrations\YYYYMMDDHHMMSS_Name.pas`.
    - Updates `LastSnapshot` file.

2.  **`dext database update`**
    - Compiles/Loads the project.
    - Checks `__DextMigrations` in the DB.
    - Identifies pending migrations from the code.
    - Executes `Up()` for each pending migration in a transaction.
    - Inserts record into `__DextMigrations`.

## Implementation Steps

### Phase 1: Schema Builder & Operations (The "What")
- Define `TOperation` classes: `TCreateTableOperation`, `TAddColumnOperation`, `TDropTableOperation`, etc.
- Implement `TSchemaBuilder` to construct these operations.
- Implement `ISQLGenerator.Generate(TOperation)` in Dialects to produce SQL.

### Phase 2: Model Diffing (The "Why")
- Implement `TModelDiffer`.
- Input: `SourceModel`, `TargetModel`.
- Output: `List<TOperation>`.
- Logic:
  - Table exists in Target but not Source -> `CreateTable`.
  - Column exists in Target but not Source -> `AddColumn`.
  - Column changed -> `AlterColumn` (Complex! Type mapping changes).

### Phase 3: Migration Runner (The "How")
- `TMigrator` class.
- Methods: `Migrate(TargetMigration: string)`, `GetPendingMigrations()`.
- Interaction with `__DextMigrations` table.

### Phase 4: Tooling Integration
- Since Delphi is compiled, "loading the project" to get the model is tricky for an external CLI.
- **Solution**: The user's project acts as the tool.
  - `MyApp.exe --migrate` or a separate console app `Migrator.exe` that uses the `DbContext`.

## Proposed Folder Structure
```
ProjectRoot/
  src/
    Migrations/
      202310010000_Initial.pas
      202310050000_AddEmail.pas
      ModelSnapshot.pas (or .json)
```
