# Branch Control Component Documentation

The **Branch Control** component is a top-level macro-module that encapsulates the pipeline's conditional and unconditional execution analysis. It acts as a structural wrapper around an internal Two's Complement Adder, the `WordLevelComparator`, and the `BranchSelector` modules. It combines raw arithmetic processing with instruction verification to determine if the program counter should branch or jump (`TakeBranch = 1`) or proceed sequentially (`TakeBranch = 0`).

---

### Interface Specification

#### Input Signals

| Pin Name         | Bit Width | Direction | Functional Description                                                                                                                                                                                                                      |
| :--------------- | :-------: | :-------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `rs1_data[31:0]` |    32     |   Input   | The data word read from Register File Port 1 (Operand A).                                                                                                                                                                                   |
| `rs2_data[31:0]` |    32     |   Input   | The data word read from Register File Port 2 (Operand B).                                                                                                                                                                                   |
| `BrSel[4:0]`     |     5     |   Input   | **Composite Selection Bus:**<br>• `BrSel[2:0]`: Maps to `funct3` (`Instruction[14:12]`) <br>• `BrSel[3]`: Maps to `Is_Branch` verification from Main Controller.<br>• `BrSel[4]`: Maps to `Is_Jump` status (asserted high for JAL or JALR). |

#### Output Signals

| Pin Name     | Bit Width | Direction | Functional Description                                                                                                       |
| :----------- | :-------: | :-------: | :--------------------------------------------------------------------------------------------------------------------------- |
| `TakeBranch` |     1     |  Output   | Final jump signal sent to execution steering logic (`1` = valid branch/jump condition met, `0` = safe sequential execution). |

---

### Submodule Processing Flow

Execution within the component flows through four sequential abstraction layers:

#### 1. Two's Complement Arithmetic Execution

The module takes `rs1_data` and `rs2_data` and actively calculates subtraction by executing an addition of the inverted second operand plus one ($A + \text{NOT}(B) + 1$). This internal generation yields the explicit intermediate flags (the result bus, underflow bit, and overflow state) required for clean evaluation.

#### 2. Flag Translation (`WordLevelComparator`)

The arithmetic results are evaluated by the companion comparator layer. This block interprets the sum, explicit underflow bit, and signed overflow conditions to extract true logical comparisons, exposing three condition indicators:

- `EQ`: Active high if rs1 == rs2.
- `LTS`: Active high if rs1 < rs2 under signed Two's Complement rules.
- `LTU`: Active high if rs1 < rs2 under unsigned magnitude rules.

#### 3. Filtering and Selection (`BranchSelector`)

The raw status bits (`EQ`, `LTS`, `LTU`) pass into the internal `BranchSelector` submodule.
The top three bits of the selection bus (`BrSel[4:2]`), which represent the `funct3` field from the instruction, are wired directly to the selector's `Branch_Op` port to filter the active flag state:
ConditionMet = BranchSelector(EQ, LTS, LTU, BrSel[4:2])

#### 4. Operation Gating and Validation

To accurately isolate true branch instructions and unconditional jumps, execution paths are gated independently before merging:

- **Conditional Branch Line:** The `ConditionMet` flag evaluated by the companion selector is logically ANDed with the `BrSel[3]` verification line (`Is_Branch`). This guarantees that matching arithmetic configurations in non-branching ops cannot trigger a PC update.
- **Unconditional Jump Override:** The `BrSel[4]` bit captures whether a `JAL` or `JALR` instruction is in flight. Because jumps skip the comparator check entirely, this control flag bypasses the branch gating entirely via a final OR validation gate.

---

### Final Control Verification Formula

```text
TakeBranch = (ConditionMet AND Branch) OR (JAL OR JALR)
```
