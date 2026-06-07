| Register | Value (Hex) | Value (Decimal) | Source Operation                       |
| :------- | :---------- | :-------------- | :------------------------------------- |
| **x1**   | 0x80000000  | -2147483648     | Last test input rs1 (Min Signed)       |
| **x2**   | 0xFFFFFFFF  | -1              | Last test input rs2 (-1)               |
| **x4**   | 0xFFFFFFC4  | -60             | mul result                             |
| **x5**   | 0x00000001  | 1               | mulh result                            |
| **x6**   | 0xFFFFFFFF  | -1              | mulhu result                           |
| **x7**   | 0xFFFFFFFF  | -1              | mulhsu result                          |
| **x8**   | 0xFFFFFFFA  | -6              | div result                             |
| **x9**   | 0x7FFFFFFD  | 2147483645      | divu result                            |
| **x10**  | 0xFFFFFFFE  | -2              | rem result                             |
| **x11**  | 0x00000002  | 2               | remu result                            |
| **x12**  | 0xFFFFFFFF  | -1              | div by zero default                    |
| **x13**  | 0x00000007  | 7               | rem by zero default                    |
| **x14**  | 0x80000000  | -2147483648     | div overflow default                   |
| **x15**  | 0x00000000  | 0               | rem overflow default                   |
| **x20**  | 0xFFFFFFC4  | -60             | Golden value for x4                    |
| **x21**  | 0x00000001  | 1               | Golden value for x5                    |
| **x22**  | 0xFFFFFFFF  | -1              | Golden value for x6                    |
| **x23**  | 0xFFFFFFFF  | -1              | Golden value for x7                    |
| **x24**  | 0xFFFFFFFA  | -6              | Golden value for x8                    |
| **x25**  | 0x7FFFFFFD  | 2147483645      | Golden value for x9                    |
| **x26**  | 0xFFFFFFFE  | -2              | Golden value for x10                   |
| **x27**  | 0x00000002  | 2               | Golden value for x11                   |
| **x28**  | 0xFFFFFFFF  | -1              | Golden value for x12                   |
| **x29**  | 0x00000007  | 7               | Golden value for x13                   |
| **x30**  | 0x80000000  | -2147483648     | Golden value for x14                   |
| **x31**  | 0x00000001  | 1               | Test suite execution status (1 = Pass) |
