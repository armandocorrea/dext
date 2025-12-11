# 🚀 Dext Admin Starter Kit

A professional, full-stack "SaaS Admin" template built with **Delphi (Dext)** and **Modern Web Technologies**.

> **Use Case:** Perfect for developers migrating from VCL/IntraWeb who want a modern look without the complexity of Node.js/Webpack build chains.

## ✨ Features

*   **Logic in Delphi**: Backend API, Database, and Routing all handled by Dext.
*   **Modern Frontend**: Uses **Tailwind CSS** for styling and **HTMX** for dynamic interactions.
*   **Zero Build Tools**: No `npm install`, no `webpack`. Just plain HTML files served by Delphi.
*   **Authentication**: Complete Login flow with Cookie-based auth.
*   **Dashboard**: Interactive charts (Chart.js) and real-time stats.
*   **CRUD**: Complete Customer management example.

## 🛠️ Technology Stack

*   **Backend**: Dext Framework (Minimal APIs + Dext.Entity)
*   **Database**: SQLite (Zero config file `dext_admin.db`)
*   **Frontend**: 
    *   **HTMX**: For SPA-like navigation without writing JavaScript.
    *   **Tailwind CSS**: For utility-first styling (via CDN).
    *   **Alpine.js**: For minimal client-side interactivity (Sidebar toggle).
    *   **Chart.js**: For data visualization.

## 🏃 Gettings Started

1.  **Open Project**: Open `Dext.Starter.Admin.dpr` in Delphi.
2.  **Build**: Compile the project (Console Application).
3.  **Run**: Execute the binary. It will start a web server at `http://localhost:8080`.
    *   *Note*: The first run will automatically create the SQLite database and seed it with demo data.
4.  **Login**:
    *   **Username**: `admin`
    *   **Password**: `admin`

## 📂 Project Structure

*   `Domain/`: Database Entities (`User`, `Customer`) and Context.
*   `Features/`: Vertical slices of functionality (Endpoints + Services).
    *   `Auth/`: Login logic.
    *   `Dashboard/`: Stats and Charts.
*   `wwwroot/`: Static files (HTML, CSS).
    *   `views/`: HTML Templates.

## ⚠️ Production Note (CDN)

This starter kit uses Tailwind CSS via CDN script for rapid prototyping and ease of use ("No Build"). For high-traffic production applications, we recommend setting up a proper CSS build pipeline to generate an optimized CSS file.

---

## 🚶 Walkthrough & Features

### 1. Running the Application

1.  Open `Dext.Starter.Admin.dpr` in Delphi.
2.  Compile and Run (F9).
3.  The console will show: `🚀 Dext Admin Starter running at http://localhost:8080`.

### 2. Exploring the Features

#### Login Screen
*   Navigate to `http://localhost:8080`. You will be redirected to the Login page.
*   **Visuals**: Split screen layout (Image + Form) styled with Tailwind.
*   **Under the Hood**: Uses `hx-post="/auth/login"`. The server validates credentials and sets a cookie.
*   **Credentials**: User: `admin`, Pass: `admin`.

#### Dashboard
*   After login, you see the Dashboard.
*   **Sidebar**: Collapsible (Alpine.js).
*   **Stats Cards**: Loaded asynchronously via `hx-trigger="load"`. This shows how to load data without blocking the initial page render.
*   **Chart**: Renders using Chart.js with data fetched from `/dashboard/chart`.

#### Customers Management
*   Click "Customers" in the sidebar.
*   **HTMX Navigation**: The content area updates *without* a full page reload. The URL changes to `/customers` (if pushState was enabled, simplified here).
*   **Server-Side Rendering**: The server returns a fully formed HTML Table.
*   **Interactivity**: "Delete" buttons use `hx-delete` to remove rows directly from the DOM and Database.

### 3. Code Highlights

#### Minimal API with HTMX
See `Features/Customers/Customer.Endpoints.pas`:
```delphi
Group.MapGet<TAppDbContext, IResult>('/',
  function(Db: TAppDbContext): IResult
  begin
    // ... logic to fetch customers ...
    // Returns HTML string directly!
    Result := Results.Content(Html.ToString, 'text/html');
  end);
```

#### Zero-Build Frontend
Open `wwwroot/views/dashboard.html`. You'll see standard `<script>` tags for Tailwind and HTMX. No `node_modules`, no `webpack.config.js`.

```html
<script src="https://cdn.tailwindcss.com"></script>
<script src="https://unpkg.com/htmx.org@1.9.10"></script>
```
