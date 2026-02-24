# Test Output

This directory contains the generated Mermaid diagrams from the test suite.

## Files

- **diagram.mmd** - Mermaid class diagram syntax
- **diagram.json** - JSON format compatible with Mermaid Live Editor

## Visualizing the Diagram

1. Open https://mermaid.live
2. Paste the content of `diagram.json` into the editor
3. The diagram will render automatically

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
