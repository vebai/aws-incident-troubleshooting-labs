# Incident 03 — The Service That Stopped

**Optional exercise.** The application becomes unavailable even though its server exists. The book provides the investigation; this page provides only the controls and safe exit.

**Requires:** Working shared Shop practice environment. Run from the repository root.

```bash
# Check the application before injecting a fault.
scripts/validate-baseline.sh
# Allow lab-only AWS changes.
export CONFIRM_LAB_CHANGES=YES
# Prepare, trigger, and inspect the initial incident state.
scripts/incident.sh 03 setup
scripts/incident.sh 03 inject
scripts/incident.sh 03 status
```

**Stop and investigate:** Use Incident 03 in the book. You can reset safely without completing the investigation.

**Reset and verify:**

```bash
# Remove this incident's controlled change.
scripts/incident.sh 03 reset
# Confirm the Shop works again.
scripts/validate-baseline.sh
```

The `status` and `reset` controls can return an SSM command ID. Check its result using `aws ssm get-command-invocation` before concluding it succeeded.

