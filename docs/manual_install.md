# Installation Guide

SaladUI provides automated installation tasks that handle most of the configuration for you. **We strongly recommend using these tasks.**

## Recommended: Automated Installation

### Method 1: Quick Setup (Library Mode)
Best if you want to use SaladUI as a library and don't need to customize the component source code.

```bash
mix salad.setup
```

### Method 2: Local Installation (Custom Mode)
Best if you want to own the component code and customize it. This copies everything into your project.

```bash
mix salad.install --prefix MyAppWeb.Components.UI
```

---

## Manual Installation (Legacy/Advanced)

If you prefer to configure everything manually (e.g., for Tailwind v4), follow these steps.

### 1. Tailwind v4 Setup
SaladUI v1 is designed for Tailwind v4 which uses CSS variables for theme configuration.

Create `assets/css/salad_ui.css`:
```css
@import "tailwindcss";

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
    /* ... other color variables ... */
  }
}
```

### 2. TwMerge Configuration
Add `TwMerge.Cache` to your application supervision tree in `lib/my_app/application.ex`:

```elixir
def start(_type, _args) do
  children = [
    # ...
    TwMerge.Cache,
    # ...
  ]
  # ...
end
```

### 3. JavaScript Setup
SaladUI uses a custom hook for all interactive components.

In `assets/js/app.js`:
```javascript
import SaladUI from "salad_ui"; // or local path if copied
import "salad_ui/components/dialog";
// ... import other needed components

let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: {
    SaladUI: SaladUI.SaladUIHook,
    // ... other hooks
  }
});
```

### 4. Component Usage
Import components into your LiveView or Component modules:

```elixir
defmodule MyAppWeb.MyLive do
  use MyAppWeb, :live_view
  import SaladUI.Button

  def render(assigns) do
    ~H\"\"\"
    <.button>Click me</.button>
    \"\"\"
  end
end
```
