# Reading appearance — first pancake

Experimental, reflowable-document-only reading sheet. Find **Reading appearance
(experimental)** in the reader's typography tab. It does not replace any existing
menu or change global defaults.

- Font picker, font-size stepper, and line-spacing stepper.
- Bottom-aligned sheet with the book visible above it.
- Adjustments preview in the renderer only; the committed ReaderFont and
  Configurable values remain unchanged until Apply.
- Apply updates this book's in-memory settings, persisted by KOReader's normal
  document-save lifecycle. Cancel, outside tap, Back, suspend, and document close
  discard the draft.
- No profile inheritance, global editing, settings migrations, or menu-framework
  changes. Publisher CSS and user style tweaks still participate in rendering;
  this sheet does not override them or edit CSS.

## Try it

Build/run this branch normally, or install only this plugin into an existing
emulator's isolated profile:

```sh
mkdir -p "$HOME/Library/Application Support/koreader-appearance-test/plugins"
ln -s /absolute/path/to/this/worktree/plugins/readingappearance.koplugin \
  "$HOME/Library/Application Support/koreader-appearance-test/plugins/readingappearance.koplugin"
KO_HOME="$HOME/Library/Application Support/koreader-appearance-test" ./kodev run
```

Open an EPUB before looking for the menu entry. Restart after changing plugin
code. Disable/remove the plugin to remove the experiment.

## Tests

`spec/unit/readingappearance_spec.lua` covers preview isolation, Apply, dismissal,
explicit Cancel, suspend, document close, bounds, and paginated-document exclusion.
Run it with the normal frontend test runner. When reusing another checkout's
compiled emulator, set `APPEARANCE_PLUGIN_DIR` to this plugin's absolute path and
pass the absolute spec path to that emulator's `spec/runtests --busted front`.

Manual checks: open an EPUB, change all three controls, Cancel, reopen, Apply,
reopen, and close/reopen the book. Check outside-tap/Back cancellation and that
other books/defaults are unaffected. The first version deliberately uses stock
button/picker widgets; visual refinement and accessibility need further testing
on an actual e-ink device.
