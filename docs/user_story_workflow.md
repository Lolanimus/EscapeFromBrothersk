# How to Build One User Story with TDD

The short version:

1. Pick one ticket.
2. Read the intent, specification, and ticket.
3. Agree on how the feature will be tested.
4. Write one failing test.
5. Write enough code to pass it.
6. Repeat until every requirement in the ticket works.
7. Run all relevant tests and review the finished feature.
8. Mark the ticket done only after everything passes.

## 1. Pick a ticket that is ready

Choose one issue from:

```text
intent/demo-level/issues/
```

Check its **Blocked by** section. Do not start it if a required earlier ticket is unfinished.

Only work on one user story at a time.

## 2. Read these three files

Before touching code, read:

| File | What it tells you |
| --- | --- |
| `intent/demo-level/intent.md` | Why the game feature exists and what is out of scope |
| `intent/demo-level/spec.md` | The detailed rules shared by the whole demo |
| `intent/demo-level/issues/NN-*.md` | What this specific ticket must deliver |

Think of them like this:

```text
Intent: Why are we building this?
Spec:   How should the whole system behave?
Issue:  What small piece are we building right now?
```

If they contradict each other, stop and fix the documents before coding. Do not make up a new rule inside the code.

## 3. Ask Codex to use TDD

You do not have to write the tests or feature code yourself first. The AI can create both of them by reading these three documents:

```text
intent.md + spec.md + issue.md
             ↓
AI writes a failing test
             ↓
AI implements the feature until the test passes
```

The documents tell the AI what to build:

- The **intent** explains the goal and boundaries.
- The **spec** explains the expected game behavior.
- The **issue** explains the exact user story and acceptance criteria to implement now.

You only need to point the AI to those files, ask it to use `$tdd`, and confirm the public test seam. The AI should then write and run each test, implement the code needed to pass it, and continue until the whole issue is complete.

For example:

```text
Use $tdd for ticket 02.

Read:
- intent/demo-level/intent.md
- intent/demo-level/spec.md
- intent/demo-level/issues/02-acquire-and-fire-pistol.md

Work one red-green cycle at a time and stop after each cycle.
```

Codex should first explain what the ticket includes, what it does not include, and which public test seam it proposes. After you confirm the seam, Codex can perform the test and implementation work itself.

## 4. Agree on the test seam

A **test seam** is simply the public place where the test uses the feature and checks the result.

For this Godot game, the seam will usually be the real gameplay scene:

```text
Start the gameplay scene
        ↓
Press buttons or move characters
        ↓
Check what happened in the game
```

Example:

```text
Seam: the complete gameplay scene.

The test presses E near a pistol and checks that the player is now holding it.
This proves the input, scene wiring, pickup, and player state work together.
```

Confirm the seam before any tests are written. The test should check behavior a player can see, not private functions hidden inside a script.

## 5. Do one red-green cycle

One cycle builds one small behavior.

### Red: write a failing test

Write one test describing what the player should be able to do.

Example:

```text
The player can press E near a pistol and acquire it.
```

Run the test:

```sh
godot --headless --path . --script tests/test_pistol.gd
```

It must fail because the behavior is missing. A syntax error or broken test does not count as a useful failure.

### Green: make that test pass

Write only enough game code to make the new behavior work. Do not build later tickets or features that no test currently needs.

Run the same test again. It must pass.

Then run any existing tests that your change could have broken.

That is one cycle:

```text
One behavior → failing test → small implementation → passing test
```

Stop, show the result, and choose the next behavior.

## 6. Repeat for the rest of the ticket

Do not write every test first. Complete one small behavior before starting the next one.

Ticket 02 might become these cycles:

1. Pressing `E` near a pistol picks it up.
2. Left click fires toward the mouse.
3. A player bullet kills a policeman in one hit.
4. A wall stops the bullet.
5. Projectile speed and firing speed are configurable and tested.

The exact later cycles can change after you learn something from the current cycle. That is normal.

After every cycle, report:

```text
What now works
How the test failed before the fix
How it passes after the fix
Which files changed
What remains in the ticket
```

## 7. What makes a good test?

A good test checks something the player or another public caller cares about.

Good:

```text
Pressing E near a pistol equips the pistol.
```

Bad:

```text
The pickup script called the inventory script exactly once.
```

The bad version tests internal code. It could break during a harmless refactor even though the game still works.

Also avoid:

- Testing private methods directly
- Copying the production calculation into the test
- Mocking your own game scripts
- Writing all tests before implementing any behavior
- Adding features from later tickets

Mocks are mainly for things outside the project, such as an external API, time, or randomness.

## 8. Check the whole user story

When every red-green cycle is complete:

1. Read the intent, specification, and ticket again.
2. Check every acceptance criterion against real evidence.
3. Run every relevant test suite.
4. Play the feature manually if visuals or game feel matter.
5. Review the complete diff for unrelated or speculative code.
6. Refactor only while keeping all tests green.

Useful checks:

```sh
godot --headless --path . --script tests/test_demo_level_navigation.gd
godot --headless --path . --script tests/test_enemy.gd
godot --headless --path . --script tests/test_main_menu.gd
git diff --check
git status --short
```

Only run the Godot suites relevant to the feature, plus the final regressions it could affect.

## 9. Mark it done

A user story is done when:

- Every required subtask is done.
- Every acceptance criterion works.
- Tests prove the behavior.
- Relevant older tests still pass.
- The complete feature has been reviewed.
- The documentation matches the final behavior.
- No required work remains.

Only then:

1. Change each completed checkbox to `[x]` in the issue file.
2. Change the issue status to `done`.
3. Commit and push the finished story.
4. Put the Jira key in the branch, commit, and pull-request names.

The Jira workflow will copy the updated status and subtasks from the repository into Jira.

## Copy-and-paste checklist

```text
[ ] Pick one unblocked ticket
[ ] Read intent.md, spec.md, and the ticket
[ ] Agree on the public test seam
[ ] Write one failing behavior test
[ ] Make the smallest change that passes it
[ ] Run relevant regression tests
[ ] Repeat one behavior at a time
[ ] Check every acceptance criterion
[ ] Review and manually verify the complete feature
[ ] Mark the issue done
[ ] Commit and push
```
