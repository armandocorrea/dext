# Dext Framework Installation and Setup

This guide outlines the steps required to compile the framework and configure Delphi to use Dext.

## 1. Source Compilation

The Dext Framework is designed so that its compiled binaries (`.dcu`, `.bpl`, `.dcp`) are generated in a centralized output folder, simplifying configuration.

1.  Open the main project group:
    *   `Sources\DextFramework.groupproj`
2.  In the Project Manager, right-click on the root node (**ProjectGroup**) and select **Build All**.
3.  Wait for all packages to compile.

The compiled files will be automatically generated in the folder:
*   `Output\$(Platform)\$(Config)`
*   *Example:* `Output\Win32\Debug`

## 2. Library Path Configuration (DCUs)

For the IDE to locate the framework's compiled files:

1.  In Delphi, go to **Tools** > **Options** > **Language** > **Delphi** > **Library**.
2.  Select the desired **Platform** (e.g., Windows 32-bit).
3.  In the **Library Path** field, add the absolute path to the output folder generated in the previous step.
    *   Example: `C:\dev\Dext\DextRepository\Output\Win32\Debug`

> **Note:** If you switch between Debug and Release configurations or Platforms (Win32/Win64), remember to adjust this path or add both.

## 3. Browsing Path Configuration (Source Files)

To allow source code navigation (Ctrl+Click) and detailed debugging, add the following directories to your IDE's **Browsing Path**.

> [!IMPORTANT]
> **Do NOT add these Source folders to the Library Path!**  
> The Library Path should only contain the compiled `.dcu` files (the `Output` folder from Step 2).  
> Adding Source folders to the Library Path will cause compilation conflicts (see [Troubleshooting](#troubleshooting) below).

1.  In Delphi, go to **Tools** > **Options** > **Language** > **Delphi** > **Library**.
2.  Select the desired **Platform** (e.g., Windows 32-bit).
3.  In the **Browsing Path** field, add the Source directories listed below.

Replace `[Root]` with the path where you cloned the repository (e.g., `C:\dev\Dext\DextRepository\`).

```text
[Root]\Sources\Core
[Root]\Sources\Core\Base
[Root]\Sources\Core\Json
[Root]\Sources\Data
[Root]\Sources\Hosting\CLI
[Root]\Sources\Hosting\CLI\Commands
[Root]\Sources\Web
[Root]\Sources\Web\Caching
[Root]\Sources\Web\Hosting
[Root]\Sources\Web\Indy
[Root]\Sources\Web\Middleware
[Root]\Sources\Web\Mvc
```

### Ready-to-Copy List (Example Based on `C:\dev\Dext\DextRepository`)

```text
C:\dev\Dext\DextRepository\Sources\Core
C:\dev\Dext\DextRepository\Sources\Core\Base
C:\dev\Dext\DextRepository\Sources\Core\Json
C:\dev\Dext\DextRepository\Sources\Data
C:\dev\Dext\DextRepository\Sources\Hosting\CLI
C:\dev\Dext\DextRepository\Sources\Hosting\CLI\Commands
C:\dev\Dext\DextRepository\Sources\Web
C:\dev\Dext\DextRepository\Sources\Web\Caching
C:\dev\Dext\DextRepository\Sources\Web\Hosting
C:\dev\Dext\DextRepository\Sources\Web\Indy
C:\dev\Dext\DextRepository\Sources\Web\Middleware
C:\dev\Dext\DextRepository\Sources\Web\Mvc
```

*Note: Folders like `Http` and `Expressions` mentioned in previous versions have been renamed or reorganized into `Web` and other modules.*

## 4. Verification

To confirm the installation is correct:

1.  Close the framework project group.
2.  Open the examples group:
    *   `Examples\DextExamples.groupproj`
3.  Execute **Build All**.
4.  If all projects compile successfully, the environment is correctly configured.

---

## Troubleshooting

### F2051: Unit was compiled with a different version

**Error Example:**
```
[dcc32 Fatal Error] Dext.WebHost.pas(35): F2051 Unit Dext.Web.HandlerInvoker was compiled with a different version of Dext.Json.TDextSerializer.Serialize
```

**Cause:**  
This error occurs when the Delphi compiler finds a conflict between pre-compiled `.dcu` files and raw `.pas` source files. Typically, this happens when Source folders are incorrectly added to the **Library Path** instead of the **Browsing Path**.

**Solution:**

1.  Go to **Tools** > **Options** > **Language** > **Delphi** > **Library**.
2.  Select the correct **Platform** (e.g., Windows 32-bit).
3.  Check your **Library Path**:
    *   ✅ It should contain **only** the `Output` folder with compiled DCUs (e.g., `C:\dev\Dext\DextRepository\Output\Win32\Debug`).
    *   ❌ Remove any `Sources\*` folders from the Library Path.
4.  Check your **Browsing Path**:
    *   ✅ It should contain the `Sources\*` folders (as listed in Step 3 above).
5.  Clean and rebuild:
    *   Delete any `.dcu` files from your project's output folder.
    *   Rebuild the Dext framework (`Sources\DextFramework.groupproj` > **Build All**).
    *   Rebuild your project.

### Compilation fails with "File not found" errors

**Cause:**  
The Library Path is missing the compiled DCU folder, or the framework was not compiled for the target platform/configuration.

**Solution:**

1.  Ensure you have compiled the Dext framework for the correct platform (Win32/Win64) and configuration (Debug/Release).
2.  Verify that the Library Path points to the correct `Output\$(Platform)\$(Config)` folder.
3.  If switching between Debug and Release, update the Library Path accordingly or add both paths.

### Debug stepping doesn't work / Cannot navigate to source

**Cause:**  
The Source folders are not in the Browsing Path.

**Solution:**

1.  Add all `Sources\*` folders to the **Browsing Path** (not the Library Path).
2.  Ensure "Use debug DCUs" is enabled in your project options if you want to step into RTL/VCL code as well.

### Quick Reference: Path Configuration Summary

| Path Type       | What to Add                                      | Purpose                          |
|-----------------|--------------------------------------------------|----------------------------------|
| **Library Path**    | `Output\Win32\Debug` (or your target config) | Locate compiled `.dcu` files     |
| **Browsing Path**   | All `Sources\*` folders                      | Source navigation & debugging    |
