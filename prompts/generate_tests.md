ok, now we need to create docs for how to make and run tests. please make docs in markdown format and enclose the codeblock with 4 ```` ticks.

the docs must include the following:

- folder structure for tests.
- how to generate hex code if needed. ./compile-logisim path/to/asm.s
- use the test harness template to load ROM with generated hex
- if using custom hex values then manual generate hex values in raw logisim ROM format
- add the final address of the last instruction in ROM, in the constant value in the test harness
- currently only CPU test harness is setup. to extract final x31 regiter value, that means the asm should write -1 or 1 to x31 as the final result
- the test harness will halt once final instruction is reached plus 8 to allow pipeline to complete
- run tests with test runner with examples
