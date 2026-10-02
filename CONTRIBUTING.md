# Contributing

Issues and pull requests are welcome.

## Development

```sh
npm install
npm run build        # bundle the extension and webviews
npm run typecheck
npm test             # unit tests (vitest)
npm run test:integration  # runs inside a VS Code instance
```

Press F5 in VS Code to launch an Extension Development Host with your changes.

## Pull requests

- Keep changes focused; one feature or fix per PR.
- Make sure `npm run typecheck` and `npm test` pass.
- Add or update tests under `test/` when you change behaviour.

By contributing, you agree that your contributions are licensed under the
Apache License 2.0 (see [LICENSE](LICENSE)).
