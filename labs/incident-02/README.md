# Incident 02 — Access Denied

**Optional exercise.** A previously working Shop request fails. The book provides the investigation; this page provides only the controls and safe exit.

**Requires:** Working shared Shop practice environment. Run from the repository root.

```bash
# Check the application before injecting a fault.
scripts/validate-baseline.sh
# Allow lab-only AWS changes.
export CONFIRM_LAB_CHANGES=YES
# Prepare, trigger, and inspect the initial incident state.
scripts/incident.sh 02 setup
scripts/incident.sh 02 inject
scripts/incident.sh 02 status
```

**Stop and investigate:** Use Incident 02 in the book. You can reset safely without completing the investigation.

**Reset and verify:**

```bash
# Remove this incident's controlled change.
scripts/incident.sh 02 reset
# Confirm the Shop works again.
scripts/validate-baseline.sh
```

