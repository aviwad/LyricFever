# Contribute to This Project

This `CONTRIBUTING.md` file references moby's Contributing Guide at https://github.com/moby/moby/blob/master/CONTRIBUTING.md and GitHub Docs at https://docs.github.com/en/contributing/writing-for-github-docs/annotating-code-examples.

## Code Stylings

This project follows a specific code stylings guide. Following this guide helps keep the codebase clean.

### Commit Messages

This project follows Conventional Commits styling. Commit messages must start with a prefix (see Conventional Commits section below) and short summary written in the imperative, followed by an optional, more detailed explanatory text which is separated from the summary by an empty line. For instance, `docs: add Commit Messages guide`.

If you squash a series of commits, don't just submit that. Re-write the commit message, as if the series of commits was a single stroke of brilliance.

### Conventional Commits

- feat: A new feature introduced for the user.
- fix: A bug fix.
- docs: Documentation only changes.
- refactor: Code changes that neither fix a bug nor add a feature.
- perf: A code change that improves performance.
- test: Adding missing tests or correcting existing tests.
- chore: Changes to the build process or auxiliary tools (e.g., updating dependencies).

### Guide on Annotations

Introduce the overall purpose of a code example with an introduction before the code block and use annotations to explain what specific lines of code do and why they do it.

Prioritize clarity in code annotations while trying to keep them as short as possible. People use code samples as a foundation for their own work, so annotations should help people understand the sample as it is written and how they might adapt the sample for other uses.

Consider your audience when writing code annotations and do not assume people will know why an example is written a certain way.

Annotations can be used to show the expected outcomes for the code that they annotate, but the results for the entire code example should be in whichever way best serves the audience: either the introduction for the code example or discussed after the example.

If a code example is changed, check that all annotations are still valid.
