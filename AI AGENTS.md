# AI AGENTS.md

This file provides guidance to AI agents (Claude, Copilot etc) when working with code in this repository.

## About the codebase

- This is a Rails application called landgrab. Its purpose is to represent individual "tiles" of land (powered by What3Words), grouped into "plots", where each tile can be "subscribed" by a user (via Stripe) - either for themselves or as a gift. Admins can create "posts" to provide updates about individual tiles/plots/projects.

## Commands

- Test all: `bundle exec rspec`
- Lint: `bundle exec rubocop`
- Lint (with autocorrect, preferred): `bundle exec rubocop -A`

## Tech stack

- Uses Rails, PostgreSQL with PostGIS, Stripe Payments, Cloudinary (via ActiveStorage), LeafletJS Maps, What3Words API.
- Testing: Use Rspec with spec files suffixed with `_spec.rb`.

## Code Style Guidelines

- Naming: snake_case for variables/methods, CamelCase for classes/modules, ALL_CAPS for constants
- Dependencies: Prefer existing gems in the Gemfile before adding new ones
- Define class methods inside `class << self; end` declarations.
- Don't ever test private methods directly. Specs should test behavior, not implementation.
- Do not write test-specific code in production code.

## Architecture Guidelines

- **Maintain proper separation of concerns**: Don't mix unrelated concepts in the same class or module
  - Example: Conditional execution (if/unless) should NOT be mixed with iteration execution (each/repeat)
- **Use appropriate inheritance**: Only inherit from a base class if the child truly "is-a" type of the parent
  - Don't inherit just to reuse some methods - use composition instead
- **Follow Single Responsibility Principle**: Each class should have one reason to change

## Guidance and Expectations

- Do not decide unilaterally to leave code for the sake of "backwards compatibility"... always run those decisions by me first.

## Git Workflow Practices

1. **Amending Commits**:
   - Use `git commit --amend --no-edit` to add staged changes to the last commit without changing the commit message
   - This is useful for incorporating small fixes or changes that belong with the previous commit
   - Be careful when amending commits that have already been pushed, as it will require a force push

2. **Force Pushing Safety**:
   - Always use `git push --force-with-lease` rather than `git push --force` when pushing amended commits
   - This prevents accidentally overwriting remote changes made by others that you haven't pulled yet
   - It's a safer alternative that respects collaborative work environments

4. **PR Management**:
   - Pay attention to linting results before pushing to avoid CI failures

## PR Review Best Practices
1. **Always provide your honest opinion about the PR** - be candid about both strengths and concerns
2. Give a clear assessment of risks, architectural implications, and potential future issues
3. Don't be afraid to point out potential problems even in otherwise good PRs
4. When reviewing feature flag removal PRs, carefully inspect control flow changes, not just code branch removals
5. Pay special attention to control flow modifiers like `next`, `return`, and `break` which affect iteration behavior
6. Look for variable scope issues, especially for variables that persist across loop iterations
7. Analyze how code behavior changes in all cases, not just how code structure changes
8. Be skeptical of seemingly simple changes that simply remove conditional branches
9. When CI checks fail, look for subtle logic inversions or control flow changes
10. Examine every file changed in a PR with local code for context, focusing on both what's removed and what remains
11. Verify variable initialization, modification, and usage patterns remain consistent after refactoring
12. **Never try to directly check out PR branches** - instead, compare PR changes against the existing local codebase
13. Understand the broader system architecture to identify potential impacts beyond the changed files
14. Look at both the "before" and "after" state of the code when evaluating changes, not just the diff itself
15. Consider how the changes will interact with other components that depend on the modified code
16. Run searches or examine related files even if they're not directly modified by the PR
17. Look for optimization opportunities, especially in frequently-called methods:
    - Unnecessary object creation in loops 
    - Redundant collection transformations
    - Inefficient filtering methods that create temporary collections
18. Prioritize code readability while encouraging performance optimizations:
    - Avoid premature optimization outside of hot paths
    - Consider the tradeoff between readability and performance
    - Suggest optimizations that improve both clarity and performance
