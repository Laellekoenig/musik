# AGENTS.md

## Use shadcn/ui components

Build the desktop UI from [shadcn/ui](https://ui.shadcn.com) components (`apps/desktop/src/renderer/src/components/ui`). Before writing a custom control, check whether shadcn has one, and add it from `apps/desktop`:

```sh
bunx --bun shadcn@latest add <component>
```

- Only hand-roll what shadcn doesn't offer, and build it from shadcn components and Tailwind classes.
- Style with the theme's tokens (`bg-primary`, `text-muted-foreground`, …), not new CSS or hard-coded colors. The pink accent is `--primary` in `styles.css`.
- Clickable things show a pointer cursor. shadcn's components default to the arrow, so give the interactive parts of a component you add `cursor-pointer` (like `button.tsx`, `toggle.tsx`, `command.tsx` and `slider.tsx`), and again if you overwrite one.
- The components are built on Base UI, not Radix: compose with the `render` prop, not `asChild`.
