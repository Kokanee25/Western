# The blast that throws a man takes his hat (fix 4)

**Before:** a blast that threw a man down left his hat on his head. All three hatted men, in the
check (a stick 1 m off) and in `dynamite_1m`, had `hat_in_blast: stays on`.

**The fix:** `HumanBody.take_blast` knocks his hat off whenever it throws him down. The hat flies
at 1.5 times his speed plus a little lift: a light thing with a wide brim.

**Measured:**
- The rancher's check now reads `hat_in_blast: off`, and so does his `dynamite_1m`.
- A man the blast doesn't throw keeps it (6 m: `test_hat.gd`,
  `test_a_blast_that_throws_him_takes_his_hat`).
- None of the shot or blast numbers change.
