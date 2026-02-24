# Test Output

This directory contains the generated Mermaid diagrams from the test suite.

## Files

- **diagram.html** - Interactive HTML (recommended - just open in browser!)
- **diagram.mmd** - Mermaid class diagram syntax
- **diagram.json** - JSON with diagram code (copy the "code" field value)

## Visualizing the Diagram

### Option 1: HTML (Easiest) ⭐

Simply double-click or open `diagram.html` in your browser. The diagram will render with full interactivity.

### Option 2: Copy MMD to Mermaid Live

1. Open https://mermaid.live
2. Copy the entire content of `diagram.mmd`
3. Paste into the editor
4. The diagram will render automatically

### Option 3: Copy JSON code to Mermaid Live

1. Open https://mermaid.live
2. Open `diagram.json` and copy only the value between the quotes after `"code":`
3. Paste into Mermaid Live editor
4. The diagram will render automatically

## Generated After Tests

These files are automatically generated when you run:

```bash
dart test
```

or via Melos:

```bash
melos test
```

The test creates these files to verify that the diagram generation works correctly.

## Diagram Contents

The diagram shows all the classes from the test fixtures with their relationships:

- **Classes**: Animal, Dog, Shape, Circle, Rect, Status, and more
- **Relationships**:
  - extends (solid arrow) - inheritance
  - implements (dashed arrow) - interface implementation
  - with (dashed arrow) - mixin usage
  - uses (composition arrow) - class usage via fields
- **Annotations**:
  - `<<abstract>>` - abstract classes
  - `<<interface>>` - interface classes
  - `<<sealed>>` - sealed classes
  - `<<mixin>>` - mixins
  - `<<enumeration>>` - enums
